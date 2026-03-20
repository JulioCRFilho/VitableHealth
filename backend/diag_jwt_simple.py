from infrastructure.security import SecurityHelper

def test_token():
    user_id = "test-user-diag"
    # Using the hardcoded secret from settings.py for testing
    secret = 'django-insecure-_^yo$v%i$39olpx$5&r)lj+o6tv5@j+9_s*5em^t9kkzt9)em#'
    print(f"Testing with SECRET: {secret}")
    
    token = SecurityHelper.generate_jwt(user_id, secret)
    print(f"Generated Token: {token}")
    
    decoded = SecurityHelper.decode_jwt(token, secret)
    print(f"Decoded: {decoded}")
    
    if decoded.get('user_id') == user_id:
        print("SUCCESS: Token generated and decoded correctly.")
    else:
        print(f"FAILURE: {decoded.get('error', 'Unknown error')}")

if __name__ == "__main__":
    test_token()
