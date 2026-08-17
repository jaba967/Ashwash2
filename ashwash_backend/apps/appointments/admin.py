from django.contrib import admin
from .models import Appointment

@admin.register(Appointment)
class AppointmentAdmin(admin.ModelAdmin):
    list_display = ('user', 'specialist', 'appointment_date', 'time_slot', 'status')
    list_filter = ('status', 'appointment_date')
    search_fields = ('user__username', 'user__email', 'specialist__full_name')
