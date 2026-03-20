from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from application.gemini_service import GeminiService
from infrastructure.security import SecurityHelper
from django.conf import settings

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
        
        return Response({
            'response': response_text,
            'user_id': service.user_id # Return potentially updated user_id (e.g. after login)
        })
