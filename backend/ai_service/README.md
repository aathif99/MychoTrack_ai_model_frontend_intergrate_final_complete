# Skin Disease AI Microservice (FastAPI + TensorFlow)

Production-ready prediction service converted from Google Colab notebook for AWS EC2 / Linux deployment.

## Directory Structure
```
ai_service/
├── main.py              # FastAPI application with Keras 3 & Grad-CAM
├── requirements.txt     # Python dependencies
├── models/
│   ├── README.md
│   └── SkinDisease.keras # Downloaded model file from Google Drive
└── README.md
```

## Running Locally

1. Create a Python virtual environment:
   ```bash
   python -m venv venv
   # Windows:
   .\venv\Scripts\activate
   # Linux / Mac:
   source venv/bin/activate
   ```

2. Install dependencies:
   ```bash
   pip install --upgrade pip
   pip install -r requirements.txt
   ```

3. Place `SkinDisease.keras` into the `models/` folder.

4. Start the service:
   ```bash
   python main.py
   ```
   The service will be live on `http://127.0.0.1:8000`.

## Endpoints

- `GET /` - Service status & model load verification
- `GET /health` - Health check
- `POST /predict` - Accepts `multipart/form-data` with `file`, returns predictions and Grad-CAM base64 heatmap.

## AWS Deployment (EC2 Ubuntu)

Run in background with PM2:
```bash
pm2 start "venv/bin/uvicorn main:app --host 127.0.0.1 --port 8000" --name "fastapi-ai"
pm2 save
```
