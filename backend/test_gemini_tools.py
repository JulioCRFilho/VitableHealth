import os
import django
from django.conf import settings

# Set up Django environment
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from application.gemini_service import GeminiService

def test_tools():
    service = GeminiService()
    print("Testing Tool Definitions...")
    
    # Test Register
    # Note: This will actually call Firestore if credentials are valid. 
    # For verification of signature, we can just inspect the class.
    print(f"Register signature: {service.register_user.__code__.co_varnames}")
    
    # Test Login
    print(f"Login signature: {service.login_user.__code__.co_varnames}")
    
    # Test Change Password
    print(f"Change Password signature: {service.change_password.__code__.co_varnames}")
    
    # Test health plan
    print(f"Health Plan signature: {service.get_health_plan.__code__.co_varnames}")

    print("\nSystem Instruction Preview:")
    print(service.system_instruction)

if __name__ == "__main__":
    test_tools()
