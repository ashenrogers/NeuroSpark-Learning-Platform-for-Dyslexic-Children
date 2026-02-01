import torch
import torch.nn as nn
import torch.optim as optim
from torchvision import datasets, transforms, models
from torch.utils.data import DataLoader, random_split
from sklearn.metrics import classification_report, confusion_matrix
import matplotlib.pyplot as plt
import numpy as np

num_classes = 17
data_dir = 'correct_side_data' 
# Data Augmentation and Preprocessing
transform = transforms.Compose([
    transforms.Grayscale(num_output_channels=1), 
    transforms.RandomRotation(degrees=10),          
    transforms.ToTensor(),                       
    transforms.Normalize([0.5], [0.5])           
])


dataset = datasets.ImageFolder(root=data_dir, transform=transform)

train_size = int(0.8 * len(dataset))
test_size = len(dataset) - train_size
train_dataset, test_dataset = random_split(dataset, [train_size, test_size])

batch_size = 32
train_loader = DataLoader(train_dataset, batch_size=batch_size, shuffle=True)
test_loader = DataLoader(test_dataset, batch_size=batch_size, shuffle=True)

model = models.resnet18(weights='IMAGENET1K_V1')

model.conv1 = nn.Conv2d(1, 64, kernel_size=7, stride=2, padding=3, bias=False)

num_ftrs = model.fc.in_features
model.fc = nn.Linear(num_ftrs, num_classes) 

device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
model = model.to(device)

class_weights = torch.tensor([1.0] * num_classes, dtype=torch.float).to(device)  
criterion = nn.CrossEntropyLoss(weight=class_weights)
optimizer = optim.Adam(model.parameters(), lr=0.001)

num_epochs = 10
train_losses = []
test_losses = []

for epoch in range(num_epochs):
    model.train()
    running_loss = 0.0
    for inputs, labels in train_loader:
        inputs, labels = inputs.to(device), labels.to(device)

        optimizer.zero_grad()
        outputs = model(inputs)
        loss = criterion(outputs, labels)
        loss.backward()
        optimizer.step()

        running_loss += loss.item() * inputs.size(0)

    epoch_loss = running_loss / len(train_loader.dataset)
    train_losses.append(epoch_loss)

    model.eval()
    test_loss = 0.0
    correct = 0
    all_preds = []
    all_labels = []
    
    with torch.no_grad():
        for inputs, labels in test_loader:
            inputs, labels = inputs.to(device), labels.to(device)
            outputs = model(inputs)
            loss = criterion(outputs, labels)
            test_loss += loss.item() * inputs.size(0)

            # Calculate accuracy
            _, predicted = torch.max(outputs, 1)
            correct += (predicted == labels).sum().item()

            all_preds.extend(predicted.cpu().numpy())
            all_labels.extend(labels.cpu().numpy())

    test_loss /= len(test_loader.dataset)
    test_losses.append(test_loss)
    accuracy = correct / len(test_loader.dataset)

    print(f"Epoch [{epoch+1}/{num_epochs}] - "
          f"Train Loss: {epoch_loss:.4f}, Test Loss: {test_loss:.4f}, Accuracy: {accuracy:.4f}")

print("Classification Report:\n", classification_report(all_labels, all_preds, target_names=dataset.classes))
print("Confusion Matrix:\n", confusion_matrix(all_labels, all_preds))

print("Class indices and their corresponding labels:")
for index, class_name in enumerate(dataset.classes):
    print(f"{index}: {class_name}")


torch.save(model.state_dict(), 'digits_model.pth')
