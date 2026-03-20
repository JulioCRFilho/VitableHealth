import jwt
from datetime import datetime, timedelta
from Crypto.PublicKey import RSA
from Crypto.Cipher import PKCS1_OAEP
import base64
import bcrypt

class SecurityHelper:
    """Security utilities for Handshake, RSA, and JWT."""
    
    @staticmethod
    def generate_rsa_keypair() -> tuple:
        """Generates a new RSA keypair. Returns (private_key_pem, public_key_pem)."""
        key = RSA.generate(2048)
        private_key = key.export_key()
        public_key = key.publickey().export_key()
        return private_key, public_key

    @staticmethod
    def decrypt_rsa_payload(private_key_pem: bytes, encrypted_payload_b64: str) -> str:
        """Decrypts a payload sent by the client encrypted with our public key."""
        private_key = RSA.import_key(private_key_pem)
        cipher_rsa = PKCS1_OAEP.new(private_key)
        encrypted_payload = base64.b64decode(encrypted_payload_b64)
        decrypted_payload = cipher_rsa.decrypt(encrypted_payload)
        return decrypted_payload.decode('utf-8')

    @staticmethod
    def generate_jwt(user_id: str, secret_key: str, expiration_minutes: int = 60) -> str:
        """Generates a JWT token for the user."""
        payload = {
            'user_id': user_id,
            'exp': datetime.utcnow() + timedelta(minutes=expiration_minutes),
            'iat': datetime.utcnow()
        }
        return jwt.encode(payload, secret_key, algorithm='HS256')

    @staticmethod
    def decode_jwt(token: str, secret_key: str) -> dict:
        """Decodes and validates a JWT token."""
        try:
            return jwt.decode(token, secret_key, algorithms=['HS256'])
        except jwt.ExpiredSignatureError:
            return {"error": "Token has expired"}
        except jwt.InvalidTokenError:
            return {"error": "Invalid token"}

    @staticmethod
    def hash_password(password: str) -> str:
        """Hashes a password using bcrypt."""
        salt = bcrypt.gensalt()
        hashed = bcrypt.hashpw(password.encode('utf-8'), salt)
        return hashed.decode('utf-8')

    @staticmethod
    def verify_password(password: str, hashed_password: str) -> bool:
        """Verifies a password against a bcrypt hash."""
        return bcrypt.checkpw(password.encode('utf-8'), hashed_password.encode('utf-8'))
