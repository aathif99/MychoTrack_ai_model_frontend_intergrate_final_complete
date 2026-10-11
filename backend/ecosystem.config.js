const path = require('path');

module.exports = {
  apps: [
    {
      name: "node-backend",
      script: "app.js",
      cwd: __dirname,
      instances: 1,
      autorestart: true,
      watch: false,
      max_memory_restart: "400M",
      env: {
        NODE_ENV: "production",
        PORT: 3000
      }
    },
    {
      name: "fastapi-ai",
      script: path.join(__dirname, "ai_service", "venv", "bin", "uvicorn"),
      args: "main:app --host 127.0.0.1 --port 8000",
      cwd: path.join(__dirname, "ai_service"),
      instances: 1,
      autorestart: true,
      watch: false,
      max_memory_restart: "1500M",
      interpreter: "none"
    }
  ]
};
