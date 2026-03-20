from google import genai
from django.conf import settings
import os
import django

# Set up Django environment
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

def list_models():
    api_key = settings.GEMINI_API_KEY
    client = genai.Client(api_key=api_key)
    print("Listing available models:")
    try:
        for model in client.models.list():
            print(f"- {model}")
    except Exception as e:
        print(f"Error listing models: {e}")

if __name__ == "__main__":
    list_models()
