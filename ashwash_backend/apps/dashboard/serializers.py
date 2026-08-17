from rest_framework import serializers
from .models import UserProgressMetric

class UserProgressMetricSerializer(serializers.ModelSerializer):
    class Meta:
        model = UserProgressMetric
        fields = [
            'overall_course_progress',
            'sessions_attended',
            'tasks_completed',
            'total_tasks',
            'points_earned',
            'updated_at',
        ]

class DashboardOverviewSerializer(serializers.Serializer):
    user_name = serializers.CharField()
    user_email = serializers.CharField()
    user_role = serializers.CharField()
    category = serializers.CharField()
    metrics = UserProgressMetricSerializer()
    enrolled_courses = serializers.ListField(child=serializers.DictField())
    has_unread_notifications = serializers.BooleanField(default=True)
