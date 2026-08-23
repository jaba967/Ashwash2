from rest_framework import serializers
from .models import Appointment
from apps.authentication.models import SpecialistProfile
from django.utils import timezone
import datetime


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


def parse_slot_end_datetime(appointment_date, time_slot):
    """
    Parse a time_slot string like '10:00 AM - 11:00 AM' and combine with
    appointment_date to return a timezone-aware datetime for the slot END time.
    Returns None if parsing fails.
    """
    try:
        end_str = time_slot.split(' - ')[-1].strip()  # e.g. "11:00 AM"
        end_time = datetime.datetime.strptime(end_str, '%I:%M %p').time()
        slot_end = datetime.datetime.combine(appointment_date, end_time)
        return timezone.make_aware(slot_end, timezone.get_current_timezone())
    except Exception:
        return None


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
            'time_slot', 'status', 'meeting_link', 'is_link_shared', 'notes', 'created_at'
        ]
        read_only_fields = ['id', 'user', 'patient_name', 'created_at']

    def get_patient_name(self, obj):
        if obj.user:
            return obj.user.get_full_name() or obj.user.username
        return "Patient"

    def to_internal_value(self, data):
        # Gracefully handle specialist_id if passed ID does not exist in DB
        specialist_id = data.get('specialist_id') or data.get('specialist')
        if specialist_id:
            try:
                if not SpecialistProfile.objects.filter(pk=specialist_id).exists():
                    spec_name = data.get('specialist_name', '')
                    fallback_spec = None
                    if spec_name:
                        fallback_spec = SpecialistProfile.objects.filter(full_name__icontains=spec_name).first()
                    if not fallback_spec:
                        fallback_spec = SpecialistProfile.objects.first()
                    if fallback_spec:
                        data = dict(data)
                        data['specialist_id'] = fallback_spec.id
            except Exception:
                pass
        return super().to_internal_value(data)

    def validate(self, data):
        """
        Prevent double-booking the same specialist + date + time_slot.
        Key rule: if the slot's end time has already passed, the conflict is
        ignored — the slot becomes available again for new patients automatically.
        """
        specialist = data.get('specialist')
        appointment_date = data.get('appointment_date')
        time_slot = data.get('time_slot')

        if not (specialist and appointment_date and time_slot):
            return data

        # Fetch conflicting appointments (same specialist, date, slot, not cancelled)
        conflicts = Appointment.objects.filter(
            specialist=specialist,
            appointment_date=appointment_date,
            time_slot=time_slot,
        ).exclude(status='cancelled')

        # On update, exclude the current instance itself
        if self.instance:
            conflicts = conflicts.exclude(pk=self.instance.pk)

        now = timezone.now()
        for appt in conflicts:
            slot_end = parse_slot_end_datetime(appt.appointment_date, appt.time_slot)
            # Only block if the slot window has NOT expired yet
            if slot_end is None or slot_end > now:
                raise serializers.ValidationError(
                    "This time slot is already booked. Please select another available slot."
                )

        return data
