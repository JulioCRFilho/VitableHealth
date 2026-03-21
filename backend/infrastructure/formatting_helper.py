import re

class FormattingHelper:
    """Utilities for formatting and normalizing user inputs using Regex."""

    @staticmethod
    def format_phone(phone: str) -> str:
        """Formats phone numbers to (XXX) XXX-XXXX format."""
        # Remove non-digits
        digits = re.sub(r'\D', '', phone)
        if len(digits) == 10:
            return re.sub(r'(\d{3})(\d{3})(\d{4})', r'(\1) \2-\3', digits)
        elif len(digits) == 11:
            return re.sub(r'(\d{2})(\d{5})(\d{4})', r'(\1) \2-\3', digits)
        return phone # Return as is if format unknown

    @staticmethod
    def format_name(name: str) -> str:
        """Normalizes names to Title Case."""
        if not name: return name
        return name.strip().title()

    @staticmethod
    def format_email(email: str) -> str:
        """Normalizes emails to lowercase and removes whitespace."""
        if not email: return email
        return email.strip().lower()

    @staticmethod
    def format_document(doc: str) -> str:
        """Normalizes document numbers (removes non-alphanumeric and uppercases)."""
        if not doc: return doc
        # Remove common separators like . - /
        normalized = re.sub(r'[^a-zA-Z0-9]', '', doc)
        return normalized.upper()

    @staticmethod
    def mask_text(text: str, visible_chars: int = 4, mask_char: str = '*') -> str:
        """Masks a string, leaving only the last few characters visible."""
        if not text or len(text) <= visible_chars:
            return text
        mask_len = len(text) - visible_chars
        return (mask_char * mask_len) + text[-visible_chars:]
