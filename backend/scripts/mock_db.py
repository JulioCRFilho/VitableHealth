import firebase_admin
from firebase_admin import credentials, firestore
import logging
import uuid
import sys
import os

# Add backend to path to import infrastructure
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from infrastructure.firestore_helper import FirestoreHelper

def run_mock():
    print("Populating database mocks with auto-generated Firestore UUIDs...")
    
    # 1. Global Plans (Root Collection)
    # Capture IDs to link with users
    plan_basic_id = FirestoreHelper.create_document('plans', {
        "name": "Basic Health Plan", 
        "price": 0, 
        "features": ["Telemedicine", "Prescription Upload"]
    })
    plan_complete_id = FirestoreHelper.create_document('plans', {
        "name": "Complete Health Plan", 
        "price": 49.99, 
        "features": ["Telemedicine", "Free Medications", "Priority Support"]
    })

    # 2. Global Medications (Root Collection)
    FirestoreHelper.create_document('medications', {
        "name": "Ibuprofen 400mg", 
        "stock": 500, 
        "free_on_complete": True
    })
    FirestoreHelper.create_document('medications', {
        "name": "Amoxicillin 500mg", 
        "stock": 200, 
        "free_on_complete": True
    })

    # 3. Global Telemedicine Slots (Root Collection)
    slot_id = FirestoreHelper.create_document('telemedicine_slots', {
        "time": "2026-03-25T10:00:00Z", 
        "doctor": "Dr. Sarah", 
        "available": True
    })

    # 4. Users (Root Collection)
    # Capture IDs for subcollection references
    user_1_id = FirestoreHelper.create_document('users', {
        "email": "john@example.com", 
        "name": "John Doe", 
        "plan_id": plan_complete_id, 
        "status": "active"
    })
    user_2_id = FirestoreHelper.create_document('users', {
        "email": "jane@example.com", 
        "name": "Jane Smith", 
        "plan_id": plan_basic_id, 
        "status": "active"
    })

    # 5. User-specific History/Vitals (Nested)
    # Pattern: history/{user-id}/history/{auto-id}
    FirestoreHelper.create_subcollection_document('history', user_1_id, 'history', {
        "type": "heart_rate", 
        "value": 72, 
        "unit": "bpm", 
        "timestamp": "2026-03-19T10:00:00Z"
    })
    FirestoreHelper.create_subcollection_document('history', user_1_id, 'history', {
        "type": "blood_pressure", 
        "value": "120/80", 
        "unit": "mmHg", 
        "timestamp": "2026-03-19T10:00:00Z"
    })
        
    # 6. User-specific Appointments (Nested)
    # Pattern: appointments/{user-id}/appointments/{auto-id}
    FirestoreHelper.create_subcollection_document('appointments', user_1_id, 'appointments', {
        "user_id": user_1_id, 
        "time": "2026-03-25T11:00:00Z", 
        "doctor": "Dr. Sarah", 
        "status": "scheduled",
        "slot_id": slot_id
    })
        
    print(f"Database mocked successfully for 'vitablehealth' using auto-generated IDs.")

if __name__ == "__main__":
    run_mock()
