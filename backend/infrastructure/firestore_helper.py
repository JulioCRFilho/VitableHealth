import firebase_admin
from firebase_admin import credentials, firestore
import logging

try:
    if not firebase_admin._apps:
        # Use application default credentials
        firebase_admin.initialize_app()
    db = firestore.client(database_id='vitablehealth')
except Exception as e:
    logging.warning(f"Firebase not initialized properly. Make sure credentials are set: {e}")
    db = None

class FirestoreHelper:
    """
    Helper methods for Firestore Read/Write operations.
    Enforces the flattened structure: UID > CID or UID > CID-CID
    Example Paths:
    - users/{uid}
    - users/{uid}/plans/{plan_id}
    """

    @staticmethod
    def get_document(collection: str, doc_id: str) -> dict:
        if not db: return None
        doc_ref = db.collection(collection).document(doc_id)
        doc = doc_ref.get()
        return {"id": doc.id, **doc.to_dict()} if doc.exists else None

    @staticmethod
    def get_subcollection_document(parent_col: str, parent_id: str, sub_col: str, doc_id: str) -> dict:
        if not db: return None
        doc_ref = db.collection(parent_col).document(parent_id).collection(sub_col).document(doc_id)
        doc = doc_ref.get()
        return {"id": doc.id, **doc.to_dict()} if doc.exists else None

    @staticmethod
    def write_document(collection: str, doc_id: str, data: dict, merge: bool = True):
        if not db: return False
        
        # Security/Compliance: Protect immutable fields in users collection
        if collection == 'users':
            protected_fields = ['document']
            doc_ref = db.collection(collection).document(doc_id)
            doc = doc_ref.get()
            if doc.exists:
                existing_data = doc.to_dict()
                for field in protected_fields:
                    if field in data and field in existing_data and data[field] != existing_data[field]:
                        logging.warning(f"Attempted to update immutable field '{field}' for user {doc_id}. Update rejected.")
                        del data[field] # Remove the field from the update data
        
        doc_ref = db.collection(collection).document(doc_id)
        doc_ref.set(data, merge=merge)
        return True

    @staticmethod
    def create_document(collection: str, data: dict) -> str:
        if not db: return None
        _, doc_ref = db.collection(collection).add(data)
        return doc_ref.id

    @staticmethod
    def write_subcollection_document(parent_col: str, parent_id: str, sub_col: str, doc_id: str, data: dict, merge: bool = True):
        if not db: return False
        doc_ref = db.collection(parent_col).document(parent_id).collection(sub_col).document(doc_id)
        doc_ref.set(data, merge=merge)
        return True

    @staticmethod
    def create_subcollection_document(parent_col: str, parent_id: str, sub_col: str, data: dict) -> str:
        if not db: return None
        _, doc_ref = db.collection(parent_col).document(parent_id).collection(sub_col).add(data)
        return doc_ref.id

    @staticmethod
    def list_collection(collection: str, limit: int = 100) -> list:
        if not db: return []
        docs = db.collection(collection).limit(limit).stream()
        return [{"id": d.id, **d.to_dict()} for d in docs]

    @staticmethod
    def list_subcollection(parent_col: str, parent_id: str, sub_col: str, limit: int = 100) -> list:
        if not db: return []
        docs = db.collection(parent_col).document(parent_id).collection(sub_col).limit(limit).stream()
        return [{"id": d.id, **d.to_dict()} for d in docs]
    
    @staticmethod
    def delete_document(collection: str, doc_id: str):
        if not db: return False
        db.collection(collection).document(doc_id).delete()
        return True
