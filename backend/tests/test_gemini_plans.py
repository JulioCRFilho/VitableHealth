import unittest
from unittest.mock import MagicMock, patch
import sys
import os

# Add backend to path to import infrastructure and application
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# Mock Django settings before importing GeminiService
from django.conf import settings
if not settings.configured:
    settings.configure(GEMINI_API_KEY="mock_key")

from application.gemini_service import GeminiService
from infrastructure.firestore_helper import FirestoreHelper

class TestGeminiPlans(unittest.TestCase):
    @patch('infrastructure.firestore_helper.FirestoreHelper.list_collection')
    def test_get_available_plans_success(self, mock_list):
        mock_list.return_value = [
            {"id": "plan1", "name": "Basic Plan", "price": 0, "features": ["Feature A"]},
            {"id": "plan2", "name": "Pro Plan", "price": 19.99, "features": ["Feature A", "Feature B"]}
        ]
        
        service = GeminiService()
        result = service.get_available_plans()
        
        self.assertIn("Available Health Plans", result)
        self.assertIn("Basic Plan", result)
        self.assertIn("Free", result)
        self.assertIn("Pro Plan", result)
        self.assertIn("$19.99", result)
        self.assertIn("Feature B", result)

    @patch('infrastructure.firestore_helper.FirestoreHelper.list_collection')
    def test_get_available_plans_empty(self, mock_list):
        mock_list.return_value = []
        
        service = GeminiService()
        result = service.get_available_plans()
        
        self.assertIn("currently unavailable", result)

    @patch('infrastructure.firestore_helper.FirestoreHelper.get_document')
    def test_get_health_plan_with_plan_id(self, mock_get):
        service = GeminiService(user_id="user123")
        
        # First call: get user
        # Second call: get plan
        mock_get.side_effect = [
            {"id": "user123", "name": "John Doe", "plan_id": "pro123"}, # user doc
            {"id": "pro123", "name": "Ultimate Plan", "features": ["Unlimited Access"], "status": "Active"} # plan doc
        ]
        
        result = service.get_health_plan()
        
        self.assertIn("Your active plan: **Ultimate Plan**", result)
        self.assertIn("Unlimited Access", result)

    @patch('infrastructure.firestore_helper.FirestoreHelper.get_document')
    @patch('infrastructure.firestore_helper.FirestoreHelper.list_subcollection')
    def test_get_health_plan_fallback_legacy(self, mock_list_sub, mock_get_doc):
        service = GeminiService(user_id="user123")
        
        # User doesn't have plan_id
        mock_get_doc.return_value = {"id": "user123", "name": "John Doe"}
        
        # Fallback to legacy subcollection
        mock_list_sub.return_value = [{"name": "Legacy Plan", "status": "Old"}]
        
        result = service.get_health_plan()
        
        self.assertIn("Your active plan: **Legacy Plan**", result)

    @patch('infrastructure.firestore_helper.FirestoreHelper.get_document')
    @patch('infrastructure.firestore_helper.FirestoreHelper.list_subcollection')
    def test_get_health_plan_none(self, mock_list_sub, mock_get_doc):
        service = GeminiService(user_id="user123")
        
        # User doesn't have plan_id
        mock_get_doc.return_value = {"id": "user123", "name": "John Doe"}
        
        # No legacy plan either
        mock_list_sub.return_value = []
        
        result = service.get_health_plan()
        
        self.assertIn("don't have an active health plan", result)

if __name__ == '__main__':
    unittest.main()
