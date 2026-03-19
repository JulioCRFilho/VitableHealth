import sys
import os
import django

sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "config.settings")
django.setup()

from infrastructure.firestore_helper import FirestoreHelper

def run_mock():
    print("Populating initial database mocks for Vitable Health...")
    
    # 1. Plans
    plans = [
        {"id": "basic_plan", "name": "Basic Health Plan", "price": 0, "features": ["Telemedicine", "Prescription Upload"]},
        {"id": "complete_plan", "name": "Complete Health Plan", "price": 49.99, "features": ["Telemedicine", "In-person priority", "Free Medications", "Exams"]}
    ]
    for p in plans:
        FirestoreHelper.write_document('plans', p['id'], p)
        
    # 2. Medications
    meds = [
        {"id": "med_1", "name": "Ibuprofen 400mg", "stock": 500, "free_on_complete": True},
        {"id": "med_2", "name": "Amoxicillin 500mg", "stock": 200, "free_on_complete": True},
        {"id": "med_3", "name": "Omeprazole 20mg", "stock": 300, "free_on_complete": False}
    ]
    for m in meds:
        FirestoreHelper.write_document('medications', m['id'], m)
        
    # 3. Telemedicine slots Mock
    slots = [
        {"id": "slot_1", "time": "2026-03-20T09:00:00Z", "doctor": "Dr. Sarah", "available": True},
        {"id": "slot_2", "time": "2026-03-20T10:00:00Z", "doctor": "Dr. Sarah", "available": True},
        {"id": "slot_3", "time": "2026-03-20T11:00:00Z", "doctor": "Dr. James", "available": True}
    ]
    for s in slots:
        FirestoreHelper.write_document('telemedicine_slots', s['id'], s)
        
    print("Database mocked successfully.")

if __name__ == "__main__":
    run_mock()
