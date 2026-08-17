from django.db import models
from django.conf import settings

class Notification(models.Model):
    NOTIFICATION_TYPES = (
        ('SYSTEM', 'System'),
        ('APPOINTMENT', 'Appointment'),
        ('COURSE', 'Course'),
        ('COMMUNITY', 'Community'),
        ('PROFILE', 'Profile'),
        ('KNOWLEDGE_HUB', 'Knowledge Hub'),
        ('MIND_GAME', 'Mind Game'),
        ('ASSESSMENT', 'Assessment'),
        ('PAYMENT', 'Payment'),
        ('SECURITY', 'Security'),
        ('GENERAL', 'General'),
    )

    receiver = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='notifications')
    sender = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name='sent_notifications')
    sender_role = models.CharField(max_length=50, null=True, blank=True)
    receiver_role = models.CharField(max_length=50, null=True, blank=True)
    
    notification_type = models.CharField(max_length=50, choices=NOTIFICATION_TYPES, default='GENERAL')
    title = models.CharField(max_length=255)
    body = models.TextField()
    
    related_object_id = models.CharField(max_length=255, null=True, blank=True)
    related_object_type = models.CharField(max_length=100, null=True, blank=True)
    
    is_read = models.BooleanField(default=False)
    is_deleted = models.BooleanField(default=False)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.title} - {self.receiver.username}"

class FCMDevice(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='fcm_devices')
    fcm_token = models.CharField(max_length=500, unique=True)
    device_type = models.CharField(max_length=50, default='android')
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.user.username} - {self.device_type}"
