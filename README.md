# MycoTrack - Skin Disease Detection System

MycoTrack is an intelligent skin disease detection and tracking application featuring a Flutter mobile client and an Express/Node.js backend service.

## 📁 Project Structure

```text
├── backend/              # Node.js / Express REST API and database services
├── frontend/             # Flutter mobile application
├── lib/                  # Flutter application source files
├── mobile_app_backend/   # Mobile-specific backend service
└── docs/                 # Documentation and architecture diagrams
```

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (>= 3.11.0)
- [Node.js](https://nodejs.org/) (>= 18.x)
- MySQL / MariaDB (or XAMPP)

---

### Backend Setup

1. Navigate to the backend directory:
   ```bash
   cd backend
   ```
2. Install dependencies:
   ```bash
   npm install
   ```
3. Configure environment variables:
   - Copy `.env.example` to `.env`
   - Update your database credentials and secret keys
4. Start the server:
   ```bash
   npm start
   ```

---

### Frontend Setup

1. Navigate to the frontend directory (or project root):
   ```bash
   cd frontend
   ```
2. Install Flutter packages:
   ```bash
   flutter pub get
   ```
3. Run the application:
   ```bash
   flutter run
   ```

---

## 🔒 Security Note
Ensure all `.env` files remain ignored and are never committed to public repositories.
