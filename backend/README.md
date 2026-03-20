# Vitable Health Backend

This is the backend service for Vitable Health, built with Django and Firestore.

## Mock Data Population

To populate the Firestore database (`vitablehealth`) with mock data for development and testing:

1.  Ensure you have a virtual environment set up and dependencies installed:
    ```bash
    python3 -m venv venv
    source venv/bin/activate
    pip install -r requirements.txt
    ```

2.  Run the mock script:
    ```bash
    python3 scripts/mock_db.py
    ```

### Mock Categories:
- **Plans**: Basic, Complete, Enterprise.
- **Medications**: Common medications with stock and coverage.
- **Telemedicine Slots**: Upcoming slots for Dr. Sarah and Dr. James.
- **Users**: Test users (`user_1`, `user_2`, `user_3`).
- **Vitals**: Physiological data for `user_1` (heart rate, blood pressure, etc.).
- **Appointments**: Historical and upcoming appointments.
