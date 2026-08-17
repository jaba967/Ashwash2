from rest_framework import serializers
from .models import Appointment
from apps.authentication.models import SpecialistProfile

class SpecialistSerializer(serializers.ModelSerializer):
    name = serializers.CharField(source='full_name')
    title_en = serializers.CharField(source='specialization')
    title_bn = serializers.CharField(default='বিশেষজ্ঞ')
    category_name = serializers.CharField(default='Psychologist')
    bio_en = serializers.CharField(source='bio')
    bio_bn = serializers.CharField(source='bio')
    fee_bdt = serializers.IntegerField(source='consultation_fee_bdt')
    location_type = serializers.CharField(default='local')
    is_available = serializers.SerializerMethodField()
    is_online = serializers.BooleanField(default=True)
    avatar_url = serializers.SerializerMethodField()

    class Meta:
        model = SpecialistProfile
        fields = [
            'id', 'name', 'title_en', 'title_bn', 'category_name',
            'bio_en', 'bio_bn', 'experience_years', 'rating', 'fee_bdt',
            'location_type', 'is_available', 'is_online', 'avatar_url'
        ]

    def get_is_available(self, obj):
        return obj.user.is_active if obj.user else True

    def get_avatar_url(self, obj):
        if obj.user and isinstance(obj.user.preferences, dict):
            base64_img = obj.user.preferences.get('profile_picture_base64')
            if base64_img:
                return base64_img
        if obj.user and obj.user.profile_picture:
            try:
                request = self.context.get('request')
                if request:
                    return request.build_absolute_uri(obj.user.profile_picture.url)
                return obj.user.profile_picture.url
            except Exception:
                pass
        return ''

class AppointmentSerializer(serializers.ModelSerializer):
    specialist = SpecialistSerializer(read_only=True)
    specialist_id = serializers.PrimaryKeyRelatedField(
        queryset=SpecialistProfile.objects.all(), source='specialist', write_only=True
    )
    patient_name = serializers.SerializerMethodField()

    class Meta:
        model = Appointment
        fields = [
            'id', 'user', 'patient_name', 'specialist', 'specialist_id', 'appointment_date',
            'time_slot', 'status', 'meeting_link', 'notes', 'created_at'
        ]
        read_only_fields = ['id', 'user', 'patient_name', 'meeting_link', 'created_at']

    def get_patient_name(self, obj):
        if obj.user:
            return obj.user.get_full_name() or obj.user.username
        return "Patient"
