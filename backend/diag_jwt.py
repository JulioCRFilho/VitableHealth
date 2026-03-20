import os
import sys
import django
from django.conf import settings

# Setup Django environment
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from infrastructure.security import SecurityHelper

def test_token():
    user_id = "test-user-diag"
    secret = settings.SECRET_KEY
    print(f"Testing with SECRET_KEY: {secret}")
    
    token = SecurityHelper.generate_jwt(user_id, secret)
    print(f"Generated Token: {token}")
    
    decoded = SecurityHelper.decode_jwt(token, secret)
    print(f"Decoded: {decoded}")
    
    if decoded.get('user_id') == user_id:
        print("SUCCESS: Token generated and decoded correctly with settings.SECRET_KEY")
    else:
        print(f"FAILURE: {decoded.get('error', 'Unknown error')}")

if __name__ == "__main__":
    test_token()
