from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from .models import User, Category, PatientProfile, SpecialistProfile

class CustomUserAdmin(UserAdmin):
    fieldsets = UserAdmin.fieldsets + (
        ('Extra Info', {'fields': ('role', 'phone_number', 'profile_picture', 'preferences', 'selected_categories')}),
    )
    list_display = ('username', 'email', 'first_name', 'last_name', 'role', 'is_staff')

admin.site.register(User, CustomUserAdmin)
admin.site.register(Category)
admin.site.register(PatientProfile)
admin.site.register(SpecialistProfile)
