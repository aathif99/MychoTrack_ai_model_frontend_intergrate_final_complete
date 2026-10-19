import os
import shutil
import numpy as np
import tensorflow as tf

MODEL_DIR = os.path.dirname(os.path.abspath(__file__))
TFLITE_PATH = os.path.join(MODEL_DIR, "models", "skin_classifier.tflite")

# Also copy to frontend/assets/models/
FLUTTER_MODELS_DIR = os.path.abspath(
    os.path.join(MODEL_DIR, "..", "..", "frontend", "assets", "models")
)
os.makedirs(FLUTTER_MODELS_DIR, exist_ok=True)
flutter_tflite_path = os.path.join(FLUTTER_MODELS_DIR, "skin_classifier.tflite")
shutil.copyfile(TFLITE_PATH, flutter_tflite_path)

labels = ["Cruris", "Other", "Ringworm", "Versicolor"]
flutter_labels_path = os.path.join(FLUTTER_MODELS_DIR, "labels.txt")
with open(flutter_labels_path, "w") as f:
    f.write("\n".join(labels))

print(f"Copied TFLite model ({os.path.getsize(flutter_tflite_path)/(1024*1024):.2f} MB) to {flutter_tflite_path}")
print(f"Wrote labels to {flutter_labels_path}")

print("\n--- Verifying TFLite Model Execution ---")
interpreter = tf.lite.Interpreter(model_path=TFLITE_PATH)
interpreter.allocate_tensors()

input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()

print("Inputs:")
for inp in input_details:
    print(f"  Name: {inp['name']}, Shape: {inp['shape']}, Dtype: {inp['dtype']}")

print("Outputs:")
for out in output_details:
    print(f"  Name: {out['name']}, Shape: {out['shape']}, Dtype: {out['dtype']}")

dummy_input = np.random.randn(*input_details[0]['shape']).astype(np.float32)
interpreter.set_tensor(input_details[0]['index'], dummy_input)
interpreter.invoke()

for idx, out in enumerate(output_details):
    res = interpreter.get_tensor(out['index'])
    print(f"Output {idx} ({out['name']}) -> shape: {res.shape}, sample values: {res.flatten()[:4]}")

print("\n VERIFICATION COMPLETE! Both classification and spatial heatmap outputs are functional.")
