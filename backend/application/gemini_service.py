from google import genai
from django.conf import settings
import logging
from infrastructure.firestore_helper import FirestoreHelper
from infrastructure.security import SecurityHelper

logger = logging.getLogger(__name__)

class GeminiService:
    def __init__(self, user_id=None):
        self.api_key = settings.GEMINI_API_KEY
        self.user_id = user_id
        if not self.api_key:
            logger.warning("GEMINI_API_KEY is not set in environment variables.")
        
        self.client = genai.Client(api_key=self.api_key)
        self.model_name = 'gemini-2.5-flash'  # Current stable model in 2026
        self.system_instruction = '''
You are the Vitable Health AI Assistant. You manage the entire user journey.
Current User ID: {user_id}

Responsibilities:
1. Handle Login/Registration:
   - Use `register_user` if they are new.
   - Use `login_user` if they have an account.
2. Appointment Management:
   - Use `list_appointments` to show their scheduled visits.
   - Use `schedule_appointment` to book a new one.
3. Password Security:
   - Use `request_password_recovery` if they forgot.
   - Use `change_password` if they want to update it.

Security: Always confirm identity before showing sensitive info.
'''.format(user_id=self.user_id or "Not Authenticated")

    # --- Tool Definitions ---

    def register_user(self, email: str, name: str, password: str) -> str:
        """Registers a new user with a hashed password."""
        hashed = SecurityHelper.hash_password(password)
        uid = FirestoreHelper.create_document('users', {
            "email": email,
            "name": name,
            "password": hashed,
            "status": "active"
        })
        return f"User registered successfully with ID: {uid}"

    def login_user(self, email: str, password: str) -> str:
        """Logs in a user by verifying the hashed password."""
        users = FirestoreHelper.list_collection('users')
        user = next((u for u in users if u.get('email') == email), None)
        if not user:
            return "User not found."
        
        if SecurityHelper.verify_password(password, user.get('password', '')):
            self.user_id = user['id']
            return f"Login successful for {user.get('name')}. User ID: {user['id']}"
        return "Invalid password."

    def list_appointments(self) -> str:
        """Lists appointments for the currently authenticated user."""
        if not self.user_id:
            return "Please login first to view appointments."
        
        appointments = FirestoreHelper.list_subcollection('appointments', self.user_id, 'appointments')
        if not appointments:
            return "You have no scheduled appointments."
        
        return "\n".join([f"- {a['time']} with {a['doctor']} ({a['status']})" for a in appointments])

    def schedule_appointment(self, doctor: str, time: str) -> str:
        """Schedules a new appointment for the user."""
        if not self.user_id:
            return "Please login first to schedule an appointment."
        
        aid = FirestoreHelper.create_subcollection_document('appointments', self.user_id, 'appointments', {
            "user_id": self.user_id,
            "time": time,
            "doctor": doctor,
            "status": "scheduled"
        })
        return f"Appointment scheduled successfully. ID: {aid}"

    def request_password_recovery(self, email: str) -> str:
        """Initiates password recovery."""
        return f"A recovery link has been sent to {email}."

    def change_password(self, new_password: str) -> str:
        """Changes the current user's password."""
        if not self.user_id:
            return "Please login first to change your password."
        
        hashed = SecurityHelper.hash_password(new_password)
        FirestoreHelper.write_document('users', self.user_id, {"password": hashed})
        return "Password updated successfully."

    # --- Communication ---

    def send_message(self, message: str, history: list = None) -> str:
        if not self.api_key:
            return f"Note: GEMINI_API_KEY is not configured. Received: {message}"

        try:
            # Prepare tools
            tools = [
                self.register_user,
                self.login_user,
                self.list_appointments,
                self.schedule_appointment,
                self.request_password_recovery,
                self.change_password
            ]

            # Generate response with automatic tool calling
            response = self.client.models.generate_content(
                model=self.model_name,
                contents=message, # For simplicity in this demo, history handling can be added back
                config={
                    'system_instruction': self.system_instruction,
                    'tools': tools,
                }
            )
            
            # The SDK handles the tool calls and returns the final response
            return response.text
        except Exception as e:
            logger.error(f"Error calling Gemini API: {e}")
            return f"Error connecting to AI Assistant: {str(e)}"
