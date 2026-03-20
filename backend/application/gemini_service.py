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
            contents = []
            if history:
                for item in history:
                    role = item.get('role')
                    # Map 'assistant' to 'model' if necessary, though common to use 'model'
                    if role == 'assistant':
                        role = 'model'
                    
                    text = item.get('parts', [{}])[0].get('text') if 'parts' in item else item.get('text')
                    
                    if role and text:
                        contents.append({'role': role, 'parts': [{'text': text}]})
            
            # Add the current message
            contents.append({'role': 'user', 'parts': [{'text': message}]})

            response = self.client.models.generate_content(
                model=self.model_name,
                contents=contents,
                config={
                    'system_instruction': self.system_instruction,
                }
            )
            return response.text
        except Exception as e:
            logger.error(f"Error calling Gemini API: {e}")
            return f"Error connecting to AI Assistant: {str(e)}"
