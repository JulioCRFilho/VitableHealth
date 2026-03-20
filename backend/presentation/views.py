from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from application.gemini_service import GeminiService
from infrastructure.security import SecurityHelper
from django.conf import settings

from infrastructure.firestore_helper import FirestoreHelper

class ChatView(APIView):
    """
    Endpoint to proxy chat messages to Gemini AI.
    """
    def post(self, request):
        message = request.data.get('message')
        history = request.data.get('history', [])
        
        if not message:
            return Response({'error': 'Message is required'}, status=status.HTTP_400_BAD_REQUEST)
        
        # Extract user_id from JWT if present
        user_id = None
        auth_header = request.headers.get('Authorization')
        if auth_header and auth_header.startswith('Bearer '):
            token = auth_header.split(' ')[1]
            decoded = SecurityHelper.decode_jwt(token, settings.SECRET_KEY)
            if 'user_id' in decoded:
                user_id = decoded['user_id']
        
        service = GeminiService(user_id=user_id)
        response_text = service.send_message(message, history=history)
        
        # If the service now has a user_id (e.g. after login), generate a token
        token = None
        if service.user_id:
            token = SecurityHelper.generate_jwt(service.user_id, settings.SECRET_KEY)
        
        return Response({
            'response': response_text,
            'user_id': service.user_id,
            'token': token
        })

class ProfileView(APIView):
    """
    Endpoint to get and update the user profile.
    """
    def get(self, request):
        auth_header = request.headers.get('Authorization')
        if not auth_header or not auth_header.startswith('Bearer '):
            return Response({'error': 'Authorization required'}, status=status.HTTP_401_UNAUTHORIZED)
        
        token = auth_header.split(' ')[1]
        decoded = SecurityHelper.decode_jwt(token, settings.SECRET_KEY)
        if 'error' in decoded:
            return Response({'error': decoded['error']}, status=status.HTTP_401_UNAUTHORIZED)
        
        user_id = decoded.get('user_id')
        if not user_id:
            return Response({'error': 'Invalid token payload'}, status=status.HTTP_401_UNAUTHORIZED)
        
        profile = FirestoreHelper.get_document('users', user_id)
        if not profile:
            # Return a default profile if it doesn't exist yet
            profile = {
                'id': user_id,
                'name': 'New User',
                'email': '',
                'planId': 'basic',
                'status': 'active',
                'profilePictureUrl': None
            }
        
        return Response(profile)

    def patch(self, request):
        auth_header = request.headers.get('Authorization')
        if not auth_header or not auth_header.startswith('Bearer '):
            return Response({'error': 'Authorization required'}, status=status.HTTP_401_UNAUTHORIZED)
        
        token = auth_header.split(' ')[1]
        decoded = SecurityHelper.decode_jwt(token, settings.SECRET_KEY)
        if 'error' in decoded:
            return Response({'error': decoded['error']}, status=status.HTTP_401_UNAUTHORIZED)
        
        user_id = decoded.get('user_id')
        if not user_id:
            return Response({'error': 'Invalid token payload'}, status=status.HTTP_401_UNAUTHORIZED)
        
        # Allowed fields for update
        allowed_fields = ['name', 'email', 'profilePictureUrl']
        update_data = {k: v for k, v in request.data.items() if k in allowed_fields}
        
        if not update_data:
            return Response({'error': 'No valid fields provided for update'}, status=status.HTTP_400_BAD_REQUEST)
        
        success = FirestoreHelper.write_document('users', user_id, update_data, merge=True)
        if not success:
            return Response({'error': 'Failed to update profile'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
        
        updated_profile = FirestoreHelper.get_document('users', user_id)
        return Response(updated_profile)
