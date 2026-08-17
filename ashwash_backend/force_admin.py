import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'ashwash_backend.settings')
django.setup()

from django.contrib.auth import get_user_model
User = get_user_model()

print("Forcing admin user activation...")
try:
    admin_user, created = User.objects.get_or_create(username="admin", defaults={"email": "admin@ashwash.com", "role": "ADMIN"})
    admin_user.is_active = True
    admin_user.is_staff = True
    admin_user.is_superuser = True
    admin_user.set_password("adminpassword123")
    admin_user.save()
    print("Admin user successfully forced to active with password adminpassword123!")
except Exception as e:
    print(f"Failed to force admin user: {e}")
