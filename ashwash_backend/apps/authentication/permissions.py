from rest_framework.permissions import BasePermission
from .models import UserRole

class IsPatient(BasePermission):
    """Allows access only to Patient users."""
    def has_permission(self, request, view):
        return bool(request.user and request.user.is_authenticated and request.user.role == UserRole.PATIENT)

class IsSpecialist(BasePermission):
    """Allows access only to Specialist / Psychologist users."""
    def has_permission(self, request, view):
        return bool(request.user and request.user.is_authenticated and request.user.role == UserRole.SPECIALIST)

class IsJuniorPanel(BasePermission):
    """Allows access only to Junior Panel members."""
    def has_permission(self, request, view):
        return bool(request.user and request.user.is_authenticated and request.user.role == UserRole.JUNIOR_PANEL)

class IsAdminUserRole(BasePermission):
    """Allows access only to Administrator users."""
    def has_permission(self, request, view):
        return bool(request.user and request.user.is_authenticated and (request.user.role == UserRole.ADMIN or request.user.is_superuser))
