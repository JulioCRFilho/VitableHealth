from django.test import TestCase
from django.urls import reverse
from rest_framework.test import APIClient
from rest_framework import status
from infrastructure.security import SecurityHelper
from django.conf import settings
from unittest.mock import patch, MagicMock

class ProfileViewTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.user_id = "test_user_id"
        self.token = SecurityHelper.generate_jwt(self.user_id, settings.SECRET_KEY)
        self.auth_header = f'Bearer {self.token}'

    @patch('infrastructure.firestore_helper.FirestoreHelper.get_document')
    def test_get_profile_success(self, mock_get):
        mock_get.return_value = {
            'id': self.user_id,
            'name': 'Test User',
            'email': 'test@example.com',
            'planId': 'complete',
            'status': 'active'
        }
        
        response = self.client.get(reverse('profile'), HTTP_AUTHORIZATION=self.auth_header)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['name'], 'Test User')

    @patch('infrastructure.firestore_helper.FirestoreHelper.get_document')
    def test_get_profile_default(self, mock_get):
        mock_get.return_value = None
        
        response = self.client.get(reverse('profile'), HTTP_AUTHORIZATION=self.auth_header)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['name'], 'New User')

    @patch('infrastructure.firestore_helper.FirestoreHelper.write_document')
    @patch('infrastructure.firestore_helper.FirestoreHelper.get_document')
    def test_patch_profile_success(self, mock_get, mock_write):
        mock_write.return_value = True
        mock_get.return_value = {
            'id': self.user_id,
            'name': 'Updated Name',
            'email': 'updated@example.com'
        }
        
        data = {'name': 'Updated Name', 'email': 'updated@example.com'}
        response = self.client.patch(reverse('profile'), data, format='json', HTTP_AUTHORIZATION=self.auth_header)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['name'], 'Updated Name')
        mock_write.assert_called_once()

    def test_get_profile_no_auth(self):
        response = self.client.get(reverse('profile'))
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)
