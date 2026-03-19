# Vitable Health Clone

A full-stack concept application reimagining the health plan management and telemedicine experience, inspired by Vitable Health. The platform centralizes identity, scheduling, and health plan queries entirely through an interactive Gemini AI conversational interface.

## 🚀 Key Features
- **Conversational UI/UX:** The primary mobile entry point is a Chat interface. Identity validation, plan management, and scheduling happen naturally via chat.
- **Premium Fluidity:** Implements a strict Light/Dark responsive design system honoring Vitable aesthetics with deep teals, clean surfaces, and dynamic typography.
- **Robust Security:** Pre-configured with RSA Handshake capabilities for payload encryption and asynchronous JWT generation on the backend.
- **Clean Architecture:** End-to-end decoupling of frameworks from business rules across both Python and Dart environments.

---

## 🏗 Architecture Choices & Justifications

### 1. Mobile (Flutter API)
- **Feature-Based Clean Architecture:** Allows engineers to scale individual features (Chatbot, Identity, Profile) without coupling global logic.
- **Riverpod (v3.0+) Notifiers:** We utilize modern `NotifierProvider` logic avoiding legacy `StateProvider` structures. It ensures predictable UI rebuilds mapped to deterministic state transitions.
- **GoRouter:** Guarantees deep-linking readiness and maintains strict URL-driven navigation trees natively connected to context.
- **Google Generative AI (Gemini):** Integrated centrally at the `ChatService` layer. The AI acts as a smart controller—parsing the user intent to manipulate their context behind the scenes without heavy form-filling interfaces.

### 2. Backend (Python Django)
- **Domain-Based Clean Architecture:** Broken down into `domain`, `application`, `infrastructure`, and `presentation` layers. This means our business models and validations live independent of Django's heavy ORM.
- **Firestore Centralization & Flattening:** Instead of deep nested sub-collections which severely impact query performance, we enforce a strict `UID > CID` hierarchy. All Read/Write actions happen exclusively through the static `FirestoreHelper` to prevent lazy data duplication.
- **Security Protocols:** A custom `SecurityHelper` handles RSA public/private key generation + PKCS1-OAEP decryption. This assures that the mobile client can send sensitive health data encrypted *before* it travels through the network, adding a layer of integrity beyond standard HTTPS.

---

## 🛠 How to Run Locally

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.x.x)
- Python (3.9+)
- GCP Service Account Key (for Firestore admin actions)

### Backend Setup
1. Navigate to the backend directory:
   ```bash
   cd backend
   ```
2. Activate a virtual environment:
   ```bash
   python3 -m venv venv
   source venv/bin/activate
   ```
3. Install dependencies:
   ```bash
   pip install django djangorestframework firebase-admin pycryptodome PyJWT google-genai
   ```
4. Set your GCP Credentials globally in your terminal:
   ```bash
   export GOOGLE_APPLICATION_CREDENTIALS="/path/to/your/firebase-adminsdk.json"
   ```
5. Populate the mock database with available Plans, Meds, and Slots:
   ```bash
   python scripts/mock_db.py
   ```

### Mobile Setup
1. Navigate to the mobile directory:
   ```bash
   cd mobile
   ```
2. Fetch Flutter packages:
   ```bash
   flutter pub get
   ```
3. Set your **Gemini API Key**: Open `lib/features/chatbot/application/chat_service.dart` and replace `YOUR_API_KEY_HERE` with your valid Gemini key.
4. Run the application:
   ```bash
   flutter run
   ```

---

## 🧪 Testing & Validation
All project work adheres to strict **Behavior-Driven Development (BDD)** acceptance criteria. When expanding upon this framework, log your conversation prompts inside the root `/prompts` directory and match feature executions against the `BDD_TEMPLATE.md` to ensure zero lazy technical debt.
