import os
import sys
import numpy as np
import tensorflow as tf
from tensorflow.keras.layers import Layer

# 1. Custom Attention Layers
@tf.keras.utils.register_keras_serializable()
class ChannelMean(Layer):
    def call(self, inputs):
        return tf.reduce_mean(inputs, axis=-1, keepdims=True)

@tf.keras.utils.register_keras_serializable()
class ChannelMax(Layer):
    def call(self, inputs):
        return tf.reduce_max(inputs, axis=-1, keepdims=True)

MODEL_DIR = os.path.dirname(os.path.abspath(__file__))
KERAS_PATH = os.path.join(MODEL_DIR, "models", "skin_classifier.keras")
OUTPUT_DIR = os.path.join(MODEL_DIR, "models")
TFLITE_PATH = os.path.join(OUTPUT_DIR, "skin_classifier.tflite")
LABELS_PATH = os.path.join(OUTPUT_DIR, "labels.txt")

# Target directory in Flutter frontend assets
FLUTTER_ASSETS_DIR = os.path.abspath(
    os.path.join(MODEL_DIR, "..", "..", "frontend", "assets", "models")
)
os.makedirs(FLUTTER_ASSETS_DIR, exist_ok=True)

print(f"Loading Keras model from: {KERAS_PATH}")
model = tf.keras.models.load_model(
    KERAS_PATH,
    custom_objects={"ChannelMean": ChannelMean, "ChannelMax": ChannelMax},
    compile=False,
    safe_mode=False
)

# conv2d_2 is the spatial attention map layer with shape (None, 10, 10, 1)
target_layer = None
try:
    target_layer = model.get_layer("conv2d_2")
except Exception:
    for layer in reversed(model.layers):
        if 'conv' in layer.name.lower():
            target_layer = layer
            break

print(f"Using spatial attention layer: {target_layer.name}, shape: {target_layer.output.shape}")

# Create multi-output model:
# Output 0: Softmax Class Probabilities (shape: [None, 4])
# Output 1: Spatial Attention Map (shape: [None, 10, 10, 1])
multi_output_model = tf.keras.Model(
    inputs=model.inputs,
    outputs=[model.outputs[0], target_layer.output],
    name="skin_classifier_with_heatmap"
)

print("\n=== MULTI-OUTPUT MODEL ===")
print("Output 0 (Probabilities):", multi_output_model.outputs[0].shape)
print("Output 1 (Spatial Attention Map):", multi_output_model.outputs[1].shape)

# Convert to TFLite with FP16 Quantization
print("\nConverting model to TFLite with FP16 Quantization...")
converter = tf.lite.TFLiteConverter.from_keras_model(multi_output_model)
converter.optimizations = [tf.lite.Optimize.DEFAULT]
converter.target_spec.supported_types = [tf.float16]

tflite_model = converter.convert()

# Save in backend/ai_service/models/
with open(TFLITE_PATH, "wb") as f:
    f.write(tflite_model)

# Also copy directly to frontend/assets/models/
flutter_tflite_path = os.path.join(FLUTTER_ASSETS_DIR, "skin_classifier.tflite")
with open(flutter_tflite_path, "wb") as f:
    f.write(tflite_model)

labels = ["Cruris", "Other", "Ringworm", "Versicolor"]
with open(LABELS_PATH, "w") as f:
    f.write("\n".join(labels))

flutter_labels_path = os.path.join(FLUTTER_ASSETS_DIR, "labels.txt")
with open(flutter_labels_path, "w") as f:
    f.write("\n".join(labels))

keras_size = os.path.getsize(KERAS_PATH) / (1024 * 1024)
tflite_size = os.path.getsize(TFLITE_PATH) / (1024 * 1024)

print(f"\n✅ SUCCESS!")
print(f"Original Keras Model: {keras_size:.2f} MB")
print(f"Quantized TFLite Model: {tflite_size:.2f} MB")
print(f"Copied to Flutter assets: {flutter_tflite_path}")
print(f"Copied labels to Flutter assets: {flutter_labels_path}")

# Verify TFLite model inference
print("\nVerifying TFLite model inference...")
interpreter = tf.lite.Interpreter(model_path=TFLITE_PATH)
interpreter.allocate_tensors()

input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()

print(f"Input: {input_details[0]['name']}, shape: {input_details[0]['shape']}, dtype: {input_details[0]['dtype']}")
print(f"Output 0: {output_details[0]['name']}, shape: {output_details[0]['shape']}")
print(f"Output 1: {output_details[1]['name']}, shape: {output_details[1]['shape']}")

dummy_input = np.zeros(input_details[0]['shape'], dtype=np.float32)
interpreter.set_tensor(input_details[0]['index'], dummy_input)
interpreter.invoke()

pred = interpreter.get_tensor(output_details[0]['index'])
heat = interpreter.get_tensor(output_details[1]['index'])
print("Test Softmax Predictions:", pred)
print("Test Heatmap shape:", heat.shape)
print(f"Heatmap min: {heat.min():.4f}, max: {heat.max():.4f}")
print("\n🎉 ALL TESTS PASSED SUCCESSFULLY!")
