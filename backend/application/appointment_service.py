import datetime
from infrastructure.firestore_helper import FirestoreHelper

class AppointmentService:
    @staticmethod
    def get_available_doctors():
        return [
            {"id": "doc_smith", "name": "Dr. Smith", "specialty": "General Practice"},
            {"id": "doc_johnson", "name": "Dr. Johnson", "specialty": "Pediatrics"},
            {"id": "doc_williams", "name": "Dr. Williams", "specialty": "Dermatology"}
        ]

    @staticmethod
    def get_available_slots(doctor_id, date_str):
        """
        Returns a list of available time slots for a given doctor on a given date.
        date_str format: 'YYYY-MM-DD'
        Assumes slots are 30 mins each, from 09:00 to 17:00.
        """
        try:
            target_date = datetime.datetime.strptime(date_str, "%Y-%m-%d").date()
        except ValueError:
            return {"error": "Invalid date format. Use YYYY-MM-DD."}
            
        if target_date.weekday() >= 5: # Saturday or Sunday
            return {"slots": []} # No weekend appointments
            
        if target_date < datetime.date.today():
             return {"slots": []} # No past appointments
             
        # Fetch existing appointments for the doctor on that date
        filters = [
            ("doctor_id", "==", doctor_id),
            ("date", "==", date_str)
        ]
        existing_appointments = FirestoreHelper.query_collection("appointments", filters)
        booked_times = [app.get("time") for app in existing_appointments if app.get("time")]
        
        # Generate all possible slots
        all_slots = []
        start_time = datetime.datetime.strptime("09:00", "%H:%M")
        end_time = datetime.datetime.strptime("17:00", "%H:%M")
        
        current_time = start_time
        while current_time < end_time:
            time_str = current_time.strftime("%H:%M")
            # If today, don't return past slots
            slot_datetime = datetime.datetime.combine(target_date, current_time.time())
            if slot_datetime > datetime.datetime.now():
                if time_str not in booked_times:
                    all_slots.append(time_str)
            current_time += datetime.timedelta(minutes=30)
            
        return {"slots": all_slots}

    @staticmethod
    def book_appointment(doctor_id, date_str, time_str, user_id, notes=""):
        # Validate date and time
        # (A real system might check if the slot is still available right before booking)
        
        # Check if already booked
        filters = [
            ("doctor_id", "==", doctor_id),
            ("date", "==", date_str),
            ("time", "==", time_str)
        ]
        existing = FirestoreHelper.query_collection("appointments", filters)
        if existing:
            return {"error": "This slot is already booked."}
            
        # Also check if the user already has an appointment bridging the same time to prevent double-booking
        user_filters = [
            ("user_id", "==", user_id),
            ("date", "==", date_str),
            ("time", "==", time_str)
        ]
        user_existing = FirestoreHelper.query_collection("appointments", user_filters)
        if user_existing:
            return {"error": "You already have an appointment at this time."}

        appointment_data = {
            "doctor_id": doctor_id,
            "date": date_str,
            "time": time_str,
            "user_id": user_id,
            "notes": notes,
            "status": "confirmed",
            "created_at": datetime.datetime.now().isoformat()
        }
        
        doc_id = FirestoreHelper.create_document("appointments", appointment_data)
        if doc_id:
            appointment_data["id"] = doc_id
            return {"appointment": appointment_data}
        else:
            return {"error": "Failed to create appointment."}
