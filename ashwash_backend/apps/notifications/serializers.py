from rest_framework import serializers
from .models import Notification, FCMDevice
from django.contrib.auth import get_user_model

User = get_user_model()

class NotificationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Notification
        fields = '__all__'
        read_only_fields = ('created_at', 'updated_at', 'receiver', 'sender', 'is_deleted')

class FCMDeviceSerializer(serializers.ModelSerializer):
    class Meta:
        model = FCMDevice
        fields = ('fcm_token', 'device_type', 'is_active')

    def create(self, validated_data):
        user = self.context['request'].user
        token = validated_data.get('fcm_token')
        device_type = validated_data.get('device_type', 'android')
        
        # Disable all other devices with the same token to prevent duplicates
        FCMDevice.objects.filter(fcm_token=token).exclude(user=user).update(is_active=False)
        
        device, created = FCMDevice.objects.update_or_create(
            user=user,
            fcm_token=token,
            defaults={'is_active': True, 'device_type': device_type}
        )
        return device
