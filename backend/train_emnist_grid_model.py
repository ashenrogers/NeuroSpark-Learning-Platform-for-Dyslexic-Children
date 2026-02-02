# backend/train_emnist_grid_model.py

import os
import random
import numpy as np
import tensorflow as tf
import tensorflow_datasets as tfds
from tensorflow import keras
from tensorflow.keras import layers

import matplotlib.pyplot as plt
from sklearn.metrics import confusion_matrix, classification_report
import itertools

# ============================================================
# CONFIG & REPRODUCIBILITY
# ============================================================

SEED = 42
random.seed(SEED)
np.random.seed(SEED)
tf.random.set_seed(SEED)

# Save paths
MODEL_DIR = os.path.join(os.path.dirname(__file__), "model")
MODEL_PATH = os.path.join(MODEL_DIR, "emnist_resnet20_model.h5")

EMNIST_LABELS = [
    '0','1','2','3','4','5','6','7','8','9',
    'A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z',
    'a','b','d','e','f','g','h','n','q','r','t',
]

BATCH_SIZE = 256
EPOCHS = 30
VALIDATION_SPLIT = 0.1

# ============================================================
# LOAD EMNIST
# ============================================================

def load_emnist_balanced():
    print("Loading EMNIST Balanced dataset...")
    ds_train, ds_test = tfds.load(
        "emnist/balanced",
        split=["train", "test"],
        as_supervised=True,
    )

    def to_numpy(ds):
        imgs, labels = [], []
        for img, lbl in tfds.as_numpy(ds):
            imgs.append(img[..., 0])
            labels.append(lbl)
        return np.stack(imgs), np.array(labels)

    x_train, y_train = to_numpy(ds_train)
    x_test, y_test = to_numpy(ds_test)

    print("Train:", x_train.shape, y_train.shape)
    print("Test:", x_test.shape, y_test.shape)
    return (x_train, y_train), (x_test, y_test)

# ============================================================
# RESNET IMPLEMENTATION (ResNet-20 style)
# ============================================================

def resnet_block(x, filters, stride=1):
    shortcut = x

    x = layers.Conv2D(filters, (3, 3), strides=stride, padding="same",
                      use_bias=False)(x)
    x = layers.BatchNormalization()(x)
    x = layers.ReLU()(x)

    x = layers.Conv2D(filters, (3, 3), strides=1, padding="same",
                      use_bias=False)(x)
    x = layers.BatchNormalization()(x)

    if stride != 1 or shortcut.shape[-1] != filters:
        shortcut = layers.Conv2D(filters, (1, 1), strides=stride,
                                 padding="same", use_bias=False)(shortcut)
        shortcut = layers.BatchNormalization()(shortcut)

    x = layers.Add()([x, shortcut])
    return layers.ReLU()(x)


def build_resnet20(num_classes):
    inputs = keras.Input(shape=(28, 28, 1))

    # Light augmentation
    x = layers.RandomRotation(0.08)(inputs)
    x = layers.RandomTranslation(0.08, 0.08)(x)
    x = layers.RandomZoom(0.10)(x)

    # Initial conv
    x = layers.Conv2D(32, (3, 3), padding="same", use_bias=False)(x)
    x = layers.BatchNormalization()(x)
    x = layers.ReLU()(x)

    # Stage 1 (32 filters)
    x = resnet_block(x, 32)
    x = resnet_block(x, 32)
    x = resnet_block(x, 32)

    # Stage 2 (64 filters)
    x = resnet_block(x, 64, stride=2)
    x = resnet_block(x, 64)
    x = resnet_block(x, 64)

    # Stage 3 (128 filters)
    x = resnet_block(x, 128, stride=2)
    x = resnet_block(x, 128)
    x = resnet_block(x, 128)

    x = layers.GlobalAveragePooling2D()(x)
    x = layers.Dense(256, activation="relu")(x)
    x = layers.Dropout(0.5)(x)

    outputs = layers.Dense(num_classes, activation="softmax")(x)

    model = keras.Model(inputs, outputs, name="ResNet20_EMNIST")

    model.compile(
        optimizer=keras.optimizers.Adam(1e-3),
        loss="sparse_categorical_crossentropy",
        metrics=["accuracy"],
    )

    return model

# ============================================================
# PLOTTING
# ============================================================

def plot_training(history, prefix="resnet20"):
    # Accuracy
    plt.figure(figsize=(8, 4))
    plt.plot(history.history["accuracy"], label="train_acc")
    plt.plot(history.history["val_accuracy"], label="val_acc")
    plt.title("Accuracy")
    plt.xlabel("Epoch")
    plt.ylabel("Accuracy")
    plt.legend()
    plt.grid(True)
    plt.savefig(f"{prefix}_accuracy.png", dpi=150)
    plt.close()

    # Loss
    plt.figure(figsize=(8, 4))
    plt.plot(history.history["loss"], label="train_loss")
    plt.plot(history.history["val_loss"], label="val_loss")
    plt.title("Loss")
    plt.xlabel("Epoch")
    plt.ylabel("Loss")
    plt.legend()
    plt.grid(True)
    plt.savefig(f"{prefix}_loss.png", dpi=150)
    plt.close()


def plot_confusion(cm, classes, normalize, filename):
    if normalize:
        cm = cm.astype("float") / cm.sum(axis=1)[:, np.newaxis]

    plt.figure(figsize=(10, 8))
    plt.imshow(cm, cmap="Blues")
    plt.xticks(range(len(classes)), classes, rotation=90, fontsize=6)
    plt.yticks(range(len(classes)), classes, fontsize=6)
    plt.colorbar()

    thresh = cm.max() / 2
    fmt = ".2f" if normalize else "d"

    for i in range(cm.shape[0]):
        for j in range(cm.shape[1]):
            v = cm[i, j]
            if v == 0:
                continue
            plt.text(j, i, format(v, fmt),
                     ha="center",
                     color="white" if v > thresh else "black",
                     fontsize=5)

    plt.tight_layout()
    plt.savefig(filename, dpi=150)
    plt.close()

# ============================================================
# TRAINING PIPELINE
# ============================================================

def main():
    (x_train, y_train), (x_test, y_test) = load_emnist_balanced()

    x_train = x_train.astype("float32") / 255.0
    x_test = x_test.astype("float32") / 255.0

    x_train = np.expand_dims(x_train, -1)
    x_test = np.expand_dims(x_test, -1)

    num_classes = len(np.unique(y_train))

    model = build_resnet20(num_classes)
    model.summary()

    os.makedirs(MODEL_DIR, exist_ok=True)
    best_path = os.path.join(MODEL_DIR, "emnist_resnet20_best.h5")

    callbacks = [
        keras.callbacks.EarlyStopping(
            patience=5,
            restore_best_weights=True,
            monitor="val_loss",
            verbose=1,
        ),
        keras.callbacks.ModelCheckpoint(
            filepath=best_path,
            monitor="val_accuracy",
            save_best_only=True,
            verbose=1,
        ),
        keras.callbacks.ReduceLROnPlateau(
            monitor="val_loss",
            factor=0.5,
            patience=2,
            min_lr=1e-5,
            verbose=1,
        ),
    ]

    history = model.fit(
        x_train, y_train,
        epochs=EPOCHS,
        batch_size=BATCH_SIZE,
        validation_split=VALIDATION_SPLIT,
        callbacks=callbacks,
        verbose=2,
    )

    plot_training(history, prefix="emnist_resnet20")

    model.save(MODEL_PATH)
    print("Saved:", MODEL_PATH)
    print("Best model:", best_path)

    # Test accuracy
    loss, acc = model.evaluate(x_test, y_test, verbose=2)
    print("Test accuracy:", acc)

    # Classification report
    y_pred = np.argmax(model.predict(x_test), axis=1)
    print(classification_report(y_test, y_pred, target_names=EMNIST_LABELS))

    cm = confusion_matrix(y_test, y_pred)

    plot_confusion(cm, EMNIST_LABELS, False, "resnet20_confusion_counts.png")
    plot_confusion(cm, EMNIST_LABELS, True, "resnet20_confusion_normalized.png")


if __name__ == "__main__":
    main()
