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
1. Handle User Identity:
   - Use `register_user` for new accounts. Requirements: first_name, last_name, email, password, address, phone.
   - Use `login_user` to sign in. Requirements: email, password.
   - Use `request_password_recovery` if forgot. Requirement: email.
   - Use `change_password` if authenticated. Requirements: current_password, new_password.
2. Appointment Management:
   - Use `list_appointments` to show scheduled visits.
   - Use `schedule_appointment` to book new ones.
3. Health Services:
   - Use `get_health_plan` to consult coverage.

Guidelines:
- If a user triggers a tool but parameters are missing, proactively ask for them one by one.
- Always confirm identity before showing sensitive info.
- For `request_password_recovery`, provide a helpful mock message.
'''.format(user_id=self.user_id or "Not Authenticated")

    # --- Tool Definitions ---

    def register_user(self, first_name: str, last_name: str, email: str, password: str, address: str, phone: str) -> str:
        """Registers a new user with extended details and a hashed password."""
        hashed = SecurityHelper.hash_password(password)
        uid = FirestoreHelper.create_document('users', {
            "first_name": first_name,
            "last_name": last_name,
            "name": f"{first_name} {last_name}",
            "email": email,
            "password": hashed,
            "address": address,
            "phone": phone,
            "status": "active",
            "created_at": "2026-03-20T09:10:00Z" # Mock current time
        })
        return f"User registered successfully with ID: {uid}. Welcome {first_name}!"

    def login_user(self, email: str, password: str) -> str:
        """Logs in a user and returns a confirmation message."""
        users = FirestoreHelper.list_collection('users')
        user = next((u for u in users if u.get('email') == email), None)
        if not user:
            return "Login failed: User not found."
        
        if SecurityHelper.verify_password(password, user.get('password', '')):
            self.user_id = user['id']
            # Re-initialize system instruction with the new user Context
            self.system_instruction = self.system_instruction.replace("Not Authenticated", self.user_id)
            return f"Welcome back, {user.get('first_name', user.get('name'))}! You are now logged in (ID: {user['id']})."
        return "Login failed: Invalid password."

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

    def change_password(self, current_password: str, new_password: str) -> str:
        """Changes the password after verifying the current one."""
        if not self.user_id:
            return "Security error: You must be logged in to change your password."
        
        user = FirestoreHelper.get_document('users', self.user_id)
        if not user or not SecurityHelper.verify_password(current_password, user.get('password', '')):
            return "Verification failed: Current password is incorrect."
        
        hashed = SecurityHelper.hash_password(new_password)
        FirestoreHelper.write_document('users', self.user_id, {"password": hashed})
        return "Security update: Password changed successfully."

    def get_health_plan(self) -> str:
        """Retrieves health plan information for the current user."""
        if not self.user_id:
            return "Please login to view your health plan details."
        
        plans = FirestoreHelper.list_subcollection('users', self.user_id, 'plans')
        if not plans:
            return "No active health plan found for your account."
        
        plan = plans[0]
        return f"Your active plan: {plan.get('name', 'Basic Coverage')} (Status: {plan.get('status', 'Active')})."

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
                self.change_password,
                self.get_health_plan
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
