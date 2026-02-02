# backend/app.py
import os
import datetime
from flask import Flask, jsonify, request
from flask_cors import CORS
from database import get_db
from dotenv import load_dotenv
import bcrypt
import jwt
from functools import wraps
import base64
from io import BytesIO
import numpy as np
from PIL import Image
from tensorflow import keras

load_dotenv()

JWT_SECRET = os.getenv("JWT_SECRET") or "dev_secret"
JWT_ALGORITHM = os.getenv("JWT_ALGORITHM") or "HS256"
JWT_EXPIRE_SECONDS = int(os.getenv("JWT_EXPIRE_SECONDS") or 86400)

app = Flask(__name__)
CORS(app)


def create_token(user_doc):
  payload = {
      "user_id": str(user_doc["_id"]),
      "username": user_doc["username"],
      "exp": datetime.datetime.utcnow() + datetime.timedelta(seconds=JWT_EXPIRE_SECONDS)
  }
  token = jwt.encode(payload, JWT_SECRET, algorithm=JWT_ALGORITHM)
  if isinstance(token, bytes):  # pyjwt < 2
      token = token.decode()
  return token


def decode_token(token):
  try:
      payload = jwt.decode(token, JWT_SECRET, algorithms=[JWT_ALGORITHM])
      return payload
  except Exception:
      return None


def auth_required(func):
  @wraps(func)
  def wrapper(*args, **kwargs):
      auth = request.headers.get("Authorization", "")
      if not auth.startswith("Bearer "):
          return jsonify({"error": "Missing or invalid Authorization header"}), 401
      token = auth.split(" ", 1)[1]
      payload = decode_token(token)
      if not payload:
          return jsonify({"error": "Invalid or expired token"}), 401
      request.user = payload
      return func(*args, **kwargs)
  return wrapper



# ===== EMNIST MODEL FOR GRID MEMORY MATRIX =====

EMNIST_LABELS = [
    '0','1','2','3','4','5','6','7','8','9',
    'A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z',
    'a','b','d','e','f','g','h','n','q','r','t',
]

EMNIST_MODEL_PATH = os.path.join(
    os.path.dirname(__file__), "model", "emnist_resnet20_best.h5"
)
emnist_model = None


def load_emnist_model():
  global emnist_model
  if os.path.exists(EMNIST_MODEL_PATH):
      try:
          print("Loading EMNIST model from:", EMNIST_MODEL_PATH)
          emnist_model = keras.models.load_model(EMNIST_MODEL_PATH)
          print("Loaded EMNIST model.")
      except Exception as e:
          print("Error loading EMNIST model:", e)
          emnist_model = None
  else:
      print("EMNIST model file not found at", EMNIST_MODEL_PATH)
      emnist_model = None


load_emnist_model()

def preprocess_handwritten_image(image: Image.Image):
    """
    Convert a PIL image (from Flutter canvas) into EMNIST-style 28x28 tensor.

    Flutter canvas:
      - background: black
      - strokes: white
    """
    # 1) grayscale
    gray = image.convert("L")

    # 2) to numpy + normalize 0..1 (same as training: /255.0)
    arr = np.array(gray).astype("float32") / 255.0
    raw_min, raw_max, raw_mean = float(arr.min()), float(arr.max()), float(arr.mean())

    # ---- NEW: detect "no drawing" case ----
    # If the brightest pixel is very dark, assume the image is blank
    if raw_max < 0.1:
        print(f"Image looks blank. raw_max={raw_max}, raw_mean={raw_mean}")
        return None

    # 3) threshold to find strokes
    mask = arr > 0.2
    if np.any(mask):
        ys, xs = np.where(mask)
        y_min, y_max = ys.min(), ys.max()
        x_min, x_max = xs.min(), xs.max()
        arr_crop = arr[y_min:y_max + 1, x_min:x_max + 1]
    else:
        # no strong strokes; treat as blank
        print("No stroke pixels found above threshold.")
        return None

    # 4) resize cropped symbol to ~20x20, keep aspect, and paste onto 28x28 canvas
    h, w = arr_crop.shape
    if h == 0 or w == 0:
        print("Cropped region has zero size.")
        return None

    target = 20.0
    scale = target / max(h, w)
    new_w = max(1, int(round(w * scale)))
    new_h = max(1, int(round(h * scale)))

    crop_img = Image.fromarray((arr_crop * 255).astype("uint8"))
    crop_img = crop_img.resize((new_w, new_h), Image.BILINEAR)
    crop_resized = np.array(crop_img).astype("float32") / 255.0

    canvas = np.zeros((28, 28), dtype="float32")
    y_off = (28 - new_h) // 2
    x_off = (28 - new_w) // 2
    canvas[y_off:y_off + new_h, x_off:x_off + new_w] = crop_resized
    arr_crop_28 = canvas

    # 5) keep it consistent with training: just ensure range [0,1]
    arr_crop_28 = np.clip(arr_crop_28, 0.0, 1.0)

    print(
        f"preproc stats: min={arr_crop_28.min()} max={arr_crop_28.max()} "
        f"mean={arr_crop_28.mean()} (raw_min={raw_min} raw_max={raw_max} raw_mean={raw_mean})"
    )

    # 6) reshape for the model: (1, 28, 28, 1)
    arr_crop_28 = arr_crop_28.reshape(1, 28, 28, 1)
    return arr_crop_28



# ===== MNIST DIGIT MODEL (NEW GAME) =====

MNIST_MODEL_PATH = os.path.join(
    os.path.dirname(__file__), "model", "mnist_digit_best1.h5"
)

mnist_digit_model = None

def load_mnist_digit_model():
    global mnist_digit_model
    if os.path.exists(MNIST_MODEL_PATH):
        try:
            print("Loading MNIST digit model from:", MNIST_MODEL_PATH)
            mnist_digit_model = keras.models.load_model(MNIST_MODEL_PATH)
            print("Loaded MNIST digit model.")
        except Exception as e:
            print("Error loading MNIST digit model:", e)
            mnist_digit_model = None
    else:
        print("MNIST digit model file not found at", MNIST_MODEL_PATH)
        mnist_digit_model = None

load_mnist_digit_model() 

def preprocess_mnist_digit(image: Image.Image):
    gray = image.convert("L")
    arr = np.array(gray).astype("float32") / 255.0

    # detect strokes
    mask = arr > 0.2
    if not np.any(mask):
        return None

    ys, xs = np.where(mask)
    y_min, y_max = ys.min(), ys.max()
    x_min, x_max = xs.min(), xs.max()

    digit = arr[y_min:y_max+1, x_min:x_max+1]

    h, w = digit.shape
    scale = 20.0 / max(h, w)
    new_w = max(1, int(w * scale))
    new_h = max(1, int(h * scale))

    digit_img = Image.fromarray((digit * 255).astype("uint8"))
    digit_img = digit_img.resize((new_w, new_h), Image.BILINEAR)
    digit = np.array(digit_img).astype("float32") / 255.0

    canvas = np.zeros((28, 28), dtype="float32")
    y_off = (28 - new_h) // 2
    x_off = (28 - new_w) // 2
    canvas[y_off:y_off+new_h, x_off:x_off+new_w] = digit

    return canvas.reshape(1, 28, 28, 1)


# ===== ROUTES =====

@app.route("/")
def home():
  return jsonify({"message": "Adaptive Memory Trainer backend is running!"})


# ===== AUTH =====

@app.route("/api/signup", methods=["POST"])
def signup():
  data = request.json or {}
  username = data.get("username", "").strip()
  password = data.get("password", "")
  display_name = data.get("display_name", username)

  if not username or not password:
      return jsonify({"error": "username and password required"}), 400

  db = get_db()
  existing = db.users.find_one({"username": username})
  if existing:
      return jsonify({"error": "username already exists"}), 400

  salt = bcrypt.gensalt()
  hashed = bcrypt.hashpw(password.encode("utf-8"), salt)

  user_doc = {
      "username": username,
      "password_hash": hashed,
      "display_name": display_name,
      "created_at": datetime.datetime.utcnow()
  }

  res = db.users.insert_one(user_doc)
  user_doc["_id"] = res.inserted_id
  token = create_token(user_doc)

  return jsonify({
      "status": "ok",
      "token": token,
      "user": {
          "user_id": str(user_doc["_id"]),
          "username": username,
          "display_name": display_name
      }
  }), 201


@app.route("/api/login", methods=["POST"])
def login():
  data = request.json or {}
  username = data.get("username", "").strip()
  password = data.get("password", "")

  if not username or not password:
      return jsonify({"error": "username and password required"}), 400

  db = get_db()
  u = db.users.find_one({"username": username})
  if not u:
      return jsonify({"error": "invalid credentials"}), 401

  stored = u.get("password_hash")
  if isinstance(stored, str):
      stored = stored.encode("utf-8")

  if not bcrypt.checkpw(password.encode("utf-8"), stored):
      return jsonify({"error": "invalid credentials"}), 401

  token = create_token(u)
  return jsonify({
      "status": "ok",
      "token": token,
      "user": {
          "user_id": str(u["_id"]),
          "username": u["username"],
          "display_name": u.get("display_name", u["username"])
      }
  }), 200


@app.route('/api/logout', methods=['POST'])
def logout():
  # Stateless JWT — client just deletes token
  return jsonify({"status": "success", "message": "User logged out"}), 200


# ===== SCORES =====

@app.route('/api/save_score', methods=['POST'])
@auth_required
def save_score():
    data = request.json or {}
    db = get_db()

    game = data.get("game")
    score = data.get("score")
    if game is None or score is None:
        return jsonify({"error": "game and score required"}), 400

    total_time = data.get("total_time")
    level_durations = data.get("level_durations")
    level_reached = data.get("level_reached")

    # HR fields (optional)
    avg_bpm = data.get("avg_bpm")
    baseline_bpm = data.get("baseline_bpm")
    stress_level = data.get("stress_level")

    user_id = request.user["user_id"]
    username = request.user.get("username", "Unknown")

    new_doc = {
        "user_id": user_id,
        "player_name": username,
        "game": game,
        "score": int(score),
        "timestamp": datetime.datetime.utcnow()
    }

    if total_time is not None:
        try:
            new_doc["total_time"] = float(total_time)
        except Exception:
            pass

    if isinstance(level_durations, list):
        sanitized = []
        for v in level_durations:
            try:
                sanitized.append(float(v))
            except Exception:
                sanitized.append(0.0)
        new_doc["level_durations"] = sanitized

    if level_reached is not None:
        try:
            new_doc["level_reached"] = int(level_reached)
        except Exception:
            pass

    # ---- HR TELEMETRY ----
    if avg_bpm is not None:
        try:
            new_doc["avg_bpm"] = float(avg_bpm)
        except Exception:
            pass

    if baseline_bpm is not None:
        try:
            new_doc["baseline_bpm"] = float(baseline_bpm)
        except Exception:
            pass

    if isinstance(stress_level, str):
        new_doc["stress_level"] = stress_level

    res = db.scores.insert_one(new_doc)
    new_doc["_id"] = str(res.inserted_id)
    new_doc["timestamp"] = new_doc["timestamp"].isoformat()

    return jsonify(new_doc), 201


@app.route('/api/get_scores', methods=['GET'])
@auth_required
def get_scores():
  db = get_db()
  username = request.user["username"]
  cursor = db.scores.find({"player_name": username}).sort("timestamp", -1)
  out = []
  for s in cursor:
      s["_id"] = str(s["_id"])
      if "timestamp" in s and hasattr(s["timestamp"], "isoformat"):
          s["timestamp"] = s["timestamp"].isoformat()
      out.append(s)
  return jsonify(out), 200


@app.route('/api/user/scores', methods=['GET'])
@auth_required
def user_scores():
  db = get_db()
  user_id = request.user["user_id"]
  cursor = db.scores.find(
      {"user_id": user_id},
      {
          "_id": 1, "game": 1, "score": 1, "timestamp": 1,
          "total_time": 1, "level_reached": 1, "level_durations": 1
      }
  ).sort("timestamp", -1)
  out = []
  for s in cursor:
      s["_id"] = str(s["_id"])
      if "timestamp" in s and hasattr(s["timestamp"], "isoformat"):
          s["timestamp"] = s["timestamp"].isoformat()
      out.append(s)
  return jsonify(out), 200



@app.route("/api/digit_validate", methods=["POST"])
@auth_required
def digit_validate():
    if mnist_digit_model is None:
        return jsonify({"error": "model_not_loaded"}), 500

    data = request.json or {}
    img_b64 = data.get("image_base64")
    expected_digit = data.get("expected_digit")

    if img_b64 is None or expected_digit is None:
        return jsonify({"error": "image_base64 and expected_digit required"}), 400

    try:
        if "," in img_b64:
            img_b64 = img_b64.split(",", 1)[1]

        image = Image.open(BytesIO(base64.b64decode(img_b64)))
        x = preprocess_mnist_digit(image)

        if x is None:
            return jsonify({"status": "blank"})

        preds = mnist_digit_model.predict(x, verbose=0)[0]
        pred_digit = int(np.argmax(preds))
        confidence = float(np.max(preds))

        # ---- tolerance logic ----
        EXPECTED_CONF = 0.80

        if pred_digit == int(expected_digit) and confidence >= EXPECTED_CONF:
            decision = "accept"
        else:
            decision = "retry"

        return jsonify({
            "predicted_digit": pred_digit,
            "confidence": confidence,
            "decision": decision
        })

    except Exception as e:
        print("MNIST digit prediction error:", e)
        return jsonify({"error": "prediction_failed"}), 500



@app.route("/api/handwriting_predict", methods=["POST"])
@auth_required
def handwriting_predict():
  """
  Predict EMNIST class index from a base64-encoded image drawn by the child.
  We evaluate the image in TWO orientations (normal + rotated/flipped) and
  choose the one with higher confidence, to handle EMNIST orientation quirks.
  """
  if emnist_model is None:
      return jsonify({"error": "model_not_loaded"}), 500

  data = request.json or {}
  img_b64 = data.get("image_base64")

  if not img_b64:
      return jsonify({"error": "image_base64 required"}), 400

  try:
      if "," in img_b64:
          img_b64 = img_b64.split(",", 1)[1]

      img_bytes = base64.b64decode(img_b64)
      image = Image.open(BytesIO(img_bytes))

      # Preprocess to EMNIST-style 28x28 grayscale tensor
      x = preprocess_handwritten_image(image)   # (1, 28, 28, 1)

      # If your preprocess ever returns None for blank images, handle here
      if x is None:
          return jsonify({
              "error": "blank_image",
              "message": "No handwriting detected"
          }), 200

      # Single-orientation prediction (no rotation/flip)
      preds = emnist_model.predict(x, verbose=0)[0]
      class_idx = int(np.argmax(preds))
      confidence = float(np.max(preds))

      # Optional: low-confidence guard to signal "I can't read this"
      MIN_CONF = 0.5
      if confidence < MIN_CONF:
          print(f"Low confidence ({confidence:.3f}) – returning blank_image")
          return jsonify({
              "error": "blank_image",
              "confidence": confidence,
          }), 200

      label = EMNIST_LABELS[class_idx] if 0 <= class_idx < len(EMNIST_LABELS) else "?"

      print(f"EMNIST prediction (normal): {class_idx} ('{label}') conf: {confidence}")

      return jsonify({
          "class_index": class_idx,
          "confidence": confidence,
          "predicted_char": label,
      }), 200

  except Exception as e:
      print("Prediction error:", e)
      return jsonify({"error": "prediction_failed"}), 500


if __name__ == "__main__":
  app.run(debug=True, use_reloader=False, host="0.0.0.0", port=5000)