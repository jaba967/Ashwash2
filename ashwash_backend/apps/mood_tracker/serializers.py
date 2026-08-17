from rest_framework import serializers
from .models import MoodLog

class MoodLogSerializer(serializers.ModelSerializer):
    class Meta:
        model = MoodLog
        fields = ['id', 'user', 'mood', 'note', 'created_at']
        read_only_fields = ['id', 'user', 'created_at']
