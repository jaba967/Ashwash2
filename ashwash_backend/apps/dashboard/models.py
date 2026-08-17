from django.db import models
from django.contrib.auth import get_user_model

User = get_user_model()

class UserProgressMetric(models.Model):
    """
    Stores overview metrics for the patient's dashboard metrics cards:
    Overall course progress %, sessions attended, tasks completed, points earned.
    """
    user = models.OneToOneField(
        User,
        on_delete=models.CASCADE,
        related_name='progress_metric'
    )
    overall_course_progress = models.IntegerField(default=43) # Default sample progress %
    sessions_attended = models.IntegerField(default=5)
    tasks_completed = models.IntegerField(default=1)
    total_tasks = models.IntegerField(default=7)
    points_earned = models.IntegerField(default=450)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = 'User Progress Metric'
        verbose_name_plural = 'User Progress Metrics'

    def __str__(self):
        return f"Metrics for {self.user.email} - {self.overall_course_progress}%"

    @classmethod
    def get_or_create_for_user(cls, user):
        metric, created = cls.objects.get_or_create(
            user=user,
            defaults={
                'overall_course_progress': 43,
                'sessions_attended': 5,
                'tasks_completed': 1,
                'total_tasks': 7,
                'points_earned': 450,
            }
        )
        return metric
