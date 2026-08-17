from django.contrib.auth.models import AbstractUser
from django.db import models
from django.conf import settings

class Category(models.Model):
    name = models.CharField(max_length=100)
    description = models.TextField(blank=True, null=True)

    def __str__(self):
        return self.name

class User(AbstractUser):
    class Role(models.TextChoices):
        PATIENT = 'PATIENT', 'Patient'
        SPECIALIST = 'SPECIALIST', 'Psychologist / Specialist'
        DOCTOR = 'DOCTOR', 'Doctor'
        ADMIN = 'ADMIN', 'Admin'

    role = models.CharField(
        max_length=20, 
        choices=Role.choices, 
        default=Role.PATIENT
    )
    phone_number = models.CharField(max_length=15, blank=True, null=True)
    profile_picture = models.ImageField(upload_to='profiles/', blank=True, null=True)
    selected_categories = models.ManyToManyField(Category, blank=True, related_name='users')
    preferences = models.JSONField(default=dict, blank=True)

    def __str__(self):
        return f"{self.username} ({self.role})"

class SpecialistProfile(models.Model):
    user = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='specialist_profile')
    full_name = models.CharField(max_length=150)
    gender = models.CharField(max_length=20, choices=[('male', 'Male'), ('female', 'Female'), ('other', 'Other')], default='female')
    phone_number = models.CharField(max_length=20)
    email = models.EmailField()
    specialization = models.CharField(max_length=150, default='Clinical Psychologist')
    hospital_clinic = models.CharField(max_length=200, default='Ashwash Mental Wellness Center')
    experience_years = models.IntegerField(default=5)
    qualification = models.CharField(max_length=200, default='MSc in Clinical Psychology, BSMMU')
    medical_license_number = models.CharField(max_length=100)
    medical_license_document = models.FileField(upload_to='licenses/', blank=True, null=True)
    languages = models.CharField(max_length=150, default='Bengali, English')
    consultation_fee_bdt = models.IntegerField(default=1500)
    available_days = models.JSONField(default=list) # e.g. ["Sunday", "Monday", "Wednesday"]
    available_time_slots = models.JSONField(default=list) # e.g. ["10:00 AM - 11:00 AM", "04:00 PM - 05:00 PM"]
    profile_banner = models.ImageField(upload_to='banners/', blank=True, null=True)
    is_profile_complete = models.BooleanField(default=False)
    rating = models.DecimalField(max_digits=3, decimal_places=1, default=4.9)
    total_reviews = models.IntegerField(default=48)
    bio = models.TextField(blank=True, default='Dedicated mental health specialist empowering mothers and individuals to build emotional resilience.')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"Specialist Profile: {self.full_name} ({self.specialization})"

class PatientProfile(models.Model):
    user = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='patient_profile')
    full_name = models.CharField(max_length=150)
    phone_number = models.CharField(max_length=20, blank=True, null=True)
    email = models.EmailField(blank=True, null=True)
    preferred_category = models.CharField(max_length=100, default='First Time Mother')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"Patient Profile: {self.full_name}"