from django.db import models
from django.conf import settings

class MoodLog(models.Model):
    MOOD_CHOICES = [
        ('awesome', 'Awesome / 😃'),
        ('happy', 'Happy / 😊'),
        ('neutral', 'Neutral / 😐'),
        ('sad', 'Sad / 😔'),
        ('awful', 'Awful / 😢'),
    ]

    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='mood_logs')
    mood = models.CharField(max_length=20, choices=MOOD_CHOICES)
    note = models.TextField(blank=True, default='')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.user.username} - {self.mood} at {self.created_at.strftime('%Y-%m-%d %H:%M')}"
