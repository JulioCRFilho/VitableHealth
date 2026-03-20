from google import genai
from django.conf import settings
import logging

logger = logging.getLogger(__name__)

class GeminiService:
    def __init__(self):
        self.api_key = settings.GEMINI_API_KEY
        if not self.api_key:
            logger.warning("GEMINI_API_KEY is not set in environment variables.")
        
        self.client = genai.Client(api_key=self.api_key)
        self.model_name = 'gemini-flash-latest'
        self.system_instruction = '''
You are the Vitable Health AI Assistant. You manage the entire user journey.
Responsibilities:
1. Handle Login/Registration by asking for email. If new, ask for basic details.
2. Allow users to view and change their health plans (Basic Health Plan or Complete Health Plan).
3. Schedule telemedicine appointments with available doctors (Dr. Sarah, Dr. James).
4. Request free medications (e.g., Ibuprofen 400mg, Amoxicillin 500mg, Omeprazole 20mg).
Always be polite, concise, and professional. 
Never ask for real sensitive health info. Maintain state implicitly through the chat.
'''

    def send_message(self, message: str, history: list = None) -> str:
        """
        Sends a message to Gemini and returns the response.
        History should be a list of dicts with 'role' and 'parts'.
        """
        if not self.api_key:
            return f"I received your message: '{message}'. (Note: GEMINI_API_KEY is not configured on the backend)"

        try:
            # History is not fully implemented in this simple proxy yet, 
            # but the client supports it.
            response = self.client.models.generate_content(
                model=self.model_name,
                contents=message,
                config={
                    'system_instruction': self.system_instruction,
                }
            )
            return response.text
        except Exception as e:
            logger.error(f"Error calling Gemini API: {e}")
            return f"Error connecting to AI Assistant: {str(e)}"
