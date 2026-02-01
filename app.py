import io
import torch
import torch.nn as nn
from PIL import Image
from flask import Flask, request, jsonify
from torchvision import transforms, models
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

CONF_THRESHOLD = 0.75

LETTERS = ["A","B","C","D","E","F","G","H","J","L","N","O","P","R","S","U","V"]
FLIPPABLE_LETTERS = ["B","C","D","E","F","G","J","L","P","R","S"]

device = torch.device("cuda" if torch.cuda.is_available() else "cpu")

transform = transforms.Compose([
    transforms.Grayscale(1),
    transforms.Resize((224,224)),
    transforms.ToTensor(),
    transforms.Normalize([0.5],[0.5])
])

def load_model(path, num_classes):
    model = models.resnet18(weights="IMAGENET1K_V1")
    model.conv1 = nn.Conv2d(1,64,7,2,3,bias=False)
    model.fc = nn.Linear(model.fc.in_features, num_classes)
    model.load_state_dict(torch.load(path, map_location=device))
    model.eval()
    return model.to(device)

correct_model = load_model("letters_model.pth", len(LETTERS))
flipped_model = load_model("fliped_letters_model.pth", len(FLIPPABLE_LETTERS))

def predict(model, image, classes):
    with torch.no_grad():
        out = model(image)
        probs = torch.softmax(out, dim=1)
        conf, idx = torch.max(probs, 1)
    return classes[idx.item()], conf.item()

@app.route("/predict", methods=["POST"])
def predict_letter():
    if "image" not in request.files:
        return jsonify({"error": "Image missing"}), 400

    expected_letter = request.form.get("expected_letter")
    if expected_letter not in LETTERS:
        return jsonify({"error": "Invalid expected letter"}), 400

    img = Image.open(io.BytesIO(request.files["image"].read())).convert("L")
    img = transform(img).unsqueeze(0).to(device)

    pred_letter, conf = predict(correct_model, img, LETTERS)

    if pred_letter == expected_letter and conf >= CONF_THRESHOLD:
        return jsonify({
            "expected": expected_letter,
            "predicted": pred_letter,
            "status": "correct",
            "orientation": "normal",
            "confidence": round(conf * 100, 2)
        })

    if expected_letter in FLIPPABLE_LETTERS:
        flip_pred, flip_conf = predict(flipped_model, img, FLIPPABLE_LETTERS)

        if flip_pred == expected_letter and flip_conf >= CONF_THRESHOLD:
            return jsonify({
                "expected": expected_letter,
                "predicted": flip_pred,
                "status": "correct but flipped",
                "orientation": "flipped",
                "confidence": round(flip_conf * 100, 2)
            })

    return jsonify({
        "expected": expected_letter,
        "predicted": pred_letter,
        "status": "incorrect – try again",
        "orientation": "unknown",
        "confidence": round(conf * 100, 2)
    })

if __name__ == "__main__":
    app.run(debug=True)
