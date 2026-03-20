from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from application.gemini_service import GeminiService

class ChatView(APIView):
    """
    Endpoint to proxy chat messages to Gemini AI.
    """
    # In a real app, we'd use permissions here
    # permission_classes = [IsAuthenticated]

    def post(self, request):
        message = request.data.get('message')
        if not message:
            return Response({'error': 'Message is required'}, status=status.HTTP_400_BAD_REQUEST)
        
        service = GeminiService()
        response_text = service.send_message(message)
        
        return Response({'response': response_text})
