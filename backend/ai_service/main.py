import os
import io
import base64
import logging
import numpy as np
import cv2
from PIL import Image, ImageOps
import tensorflow as tf
from tensorflow.keras.layers import Layer
from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.responses import JSONResponse
import uvicorn

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger("ai_service")

# ------------------------------------------------------------------------------
# 1. Custom Attention Layers
# ------------------------------------------------------------------------------
@tf.keras.utils.register_keras_serializable()
class ChannelMean(Layer):
    def call(self, inputs):
        return tf.reduce_mean(inputs, axis=-1, keepdims=True)

@tf.keras.utils.register_keras_serializable()
class ChannelMax(Layer):
    def call(self, inputs):
        return tf.reduce_max(inputs, axis=-1, keepdims=True)

# ------------------------------------------------------------------------------
# 2. Model Initialization & Setup
# ------------------------------------------------------------------------------
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
MODELS_DIR = os.path.join(BASE_DIR, "models")

def resolve_model_path():
    env_path = os.getenv("MODEL_PATH")
    if env_path and os.path.exists(env_path):
        return env_path

    # Check common known filenames
    for filename in ["skin_classifier.keras", "SkinDisease.keras"]:
        candidate = os.path.join(MODELS_DIR, filename)
        if os.path.exists(candidate):
            return candidate

    # Search for any .keras or .h5 file in models directory
    if os.path.exists(MODELS_DIR):
        for file in os.listdir(MODELS_DIR):
            if file.endswith(".keras") or file.endswith(".h5"):
                return os.path.join(MODELS_DIR, file)

    return os.path.join(MODELS_DIR, "skin_classifier.keras")

MODEL_PATH = resolve_model_path()

model = None
TARGET_LAYER = None

def load_ai_model():
    global model, TARGET_LAYER, MODEL_PATH
    if model is not None:
        return True
    MODEL_PATH = resolve_model_path()
    if not os.path.exists(MODEL_PATH):
        logger.warning(
            f"Model file not found at: {MODEL_PATH}\n"
            f"Please ensure your '.keras' model file is placed in '{MODELS_DIR}'."
        )
        return False

    logger.info(f"Loading Keras model from {MODEL_PATH}...")
    try:
        model = tf.keras.models.load_model(
            MODEL_PATH,
            custom_objects={"ChannelMean": ChannelMean, "ChannelMax": ChannelMax},
            compile=False,
            safe_mode=False
        )
        logger.info("Model loaded successfully!")

        TARGET_LAYER = find_target_layer(model)
        logger.info(f"Target GradCAM layer: '{TARGET_LAYER.name}' ready!")

        # Model warmup
        dummy_input = np.zeros((1, 300, 300, 3), dtype=np.float32)
        model.predict(dummy_input, verbose=0)
        logger.info("Model warmup complete!")
        return True
    except Exception as e:
        logger.error(f"Failed to load model: {e}", exc_info=True)
        return False

# Class Mappings
CLASS_NAMES = ["Cruris", "Other", "Ringworm", "Versicolor"]
MODEL_TO_DISEASE = {
    0: {"model_class": "Cruris",     "disease_id": 2, "disease_name": "Tinea Cruris"},
    1: {"model_class": "Other",      "disease_id": 0, "disease_name": "Other"},
    2: {"model_class": "Ringworm",   "disease_id": 1, "disease_name": "Tinea Corporis"},
    3: {"model_class": "Versicolor", "disease_id": 3, "disease_name": "Tinea Versicolor"}
}

def find_target_layer(keras_model):
    """Identifies the backbone submodel or last convolutional layer for Grad-CAM."""
    for layer in keras_model.layers:
        if hasattr(layer, 'layers') and len(layer.layers) > 0:
            return layer
    for layer in reversed(keras_model.layers):
        if 'conv' in layer.__class__.__name__.lower() or 'conv' in layer.name.lower():
            return layer
    return keras_model.layers[1]

def preprocess_image(image_bgr):
    img_rgb = cv2.cvtColor(image_bgr, cv2.COLOR_BGR2RGB)
    img_resized = cv2.resize(img_rgb, (300, 300))
    img_float = img_resized.astype(np.float32)
    img_array = tf.keras.applications.efficientnet_v2.preprocess_input(img_float)
    return np.expand_dims(img_array, axis=0)

def generate_gradcam_overlay(keras_model, target_layer, preprocessed_img, original_bgr, pred_index):
    if target_layer is None or keras_model is None:
        return None

    captured = []
    orig_call = target_layer.call

    def hooked_call(*args, **kwargs):
        res = orig_call(*args, **kwargs)
        captured.append(res)
        return res

    target_layer.call = hooked_call

    try:
        img_tensor = tf.cast(preprocessed_img, tf.float32)
        with tf.GradientTape() as tape:
            preds = keras_model(img_tensor, training=False)
            score = preds[:, pred_index]
            log_score = tf.math.log(tf.clip_by_value(score, 1e-7, 1.0))
    finally:
        target_layer.call = orig_call

    try:
        if not captured:
            logger.warning("[GradCAM] No intermediate feature activations captured.")
            return None

        conv_outputs = captured[-1]
        grads = tape.gradient(log_score, conv_outputs)

        if grads is not None:
            pooled_grads = tf.reduce_mean(grads, axis=(0, 1, 2))
            conv_feat = conv_outputs[0]
            heatmap = conv_feat @ pooled_grads[..., tf.newaxis]
            heatmap = tf.squeeze(heatmap)
            heatmap = tf.maximum(heatmap, 0).numpy()
        else:
            heatmap = np.zeros(conv_outputs.shape[1:3], dtype=np.float32)

        h_min, h_max = float(heatmap.min()), float(heatmap.max())
        if (h_max - h_min) < 1e-8:
            conv_feat = np.abs(conv_outputs[0].numpy())
            heatmap = np.mean(conv_feat, axis=-1)
            h_min, h_max = float(heatmap.min()), float(heatmap.max())

        if (h_max - h_min) > 1e-8:
            heatmap = (heatmap - h_min) / (h_max - h_min)
        else:
            heatmap = np.ones_like(heatmap, dtype=np.float32) * 0.5

        orig_h, orig_w = original_bgr.shape[:2]
        heatmap_resized = cv2.resize(heatmap.astype(np.float32), (orig_w, orig_h), interpolation=cv2.INTER_CUBIC)
        heatmap_blurred = cv2.GaussianBlur(heatmap_resized, (21, 21), 0)
        heatmap_blurred = np.clip(heatmap_blurred, 0, 1)

        heatmap_uint8 = np.uint8(255 * heatmap_blurred)
        jet_map = cv2.applyColorMap(heatmap_uint8, cv2.COLORMAP_JET)
        overlay = cv2.addWeighted(original_bgr, 0.6, jet_map, 0.4, 0)
        return overlay
    except Exception as e:
        logger.error(f"[GradCAM Error]: {e}", exc_info=True)
        return None

# Load the model on application startup
load_ai_model()

# ------------------------------------------------------------------------------
# 3. FastAPI Endpoints
# ------------------------------------------------------------------------------
app = FastAPI(title="Skin Disease AI Microservice", version="1.0.0")

@app.get("/")
def home():
    is_model_ready = model is not None
    return {
        "status": "online",
        "service": "Skin Disease AI Microservice",
        "model_loaded": is_model_ready,
        "model_path": MODEL_PATH
    }

@app.get("/health")
def health():
    return {"status": "healthy", "model_ready": model is not None}

@app.post("/predict")
async def predict(file: UploadFile = File(...)):
    global model, TARGET_LAYER
    if model is None:
        # Try loading in case the file was placed after server started
        if not load_ai_model():
            raise HTTPException(
                status_code=503,
                detail=f"Model not loaded. Ensure 'SkinDisease.keras' exists at {MODEL_PATH}"
            )

    try:
        contents = await file.read()
        image = Image.open(io.BytesIO(contents)).convert("RGB")
        image = ImageOps.exif_transpose(image)

        open_cv_image = np.array(image)[:, :, ::-1].copy()
        preprocessed = preprocess_image(open_cv_image)

        prediction = model.predict(preprocessed, verbose=0)
        predicted_index = int(np.argmax(prediction[0]))
        confidence = float(prediction[0][predicted_index])

        disease_info = MODEL_TO_DISEASE.get(
            predicted_index,
            {"model_class": "Other", "disease_id": 0, "disease_name": "Other"}
        )

        heatmap_base64 = ""
        try:
            heatmap_img = generate_gradcam_overlay(
                model, TARGET_LAYER, preprocessed, open_cv_image, predicted_index
            )
            if heatmap_img is not None:
                _, buffer = cv2.imencode(".jpg", heatmap_img)
                heatmap_base64 = "data:image/jpeg;base64," + base64.b64encode(buffer).decode("utf-8")
        except Exception as ex:
            logger.error(f"[Heatmap Generation Error]: {ex}")

        all_probabilities = {
            CLASS_NAMES[i]: float(round(float(prediction[0][i]) * 100, 2))
            for i in range(len(CLASS_NAMES))
        }

        logger.info(f"Prediction: {disease_info['disease_name']} ({round(confidence * 100, 2)}%)")

        return JSONResponse(content={
            "model_class_index": predicted_index,
            "model_class": disease_info["model_class"],
            "disease_name": disease_info["disease_name"],
            "disease_id": disease_info["disease_id"],
            "confidence_score": round(confidence * 100, 2),
            "heatmap_base64": heatmap_base64,
            "all_probabilities": all_probabilities
        })
    except Exception as err:
        logger.error(f"[Prediction Error]: {err}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(err))

if __name__ == "__main__":
    port = int(os.getenv("PORT", 8000))
    host = os.getenv("HOST", "0.0.0.0")
    uvicorn.run("main:app", host=host, port=port, reload=False)
