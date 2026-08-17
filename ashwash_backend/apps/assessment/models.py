from django.db import models
from django.conf import settings

class Questionnaire(models.Model):
    title_en = models.CharField(max_length=200)
    title_bn = models.CharField(max_length=200)
    description_en = models.TextField(blank=True)
    description_bn = models.TextField(blank=True)
    category = models.CharField(max_length=100, default='General Wellness')

    def __str__(self):
        return self.title_en

class Question(models.Model):
    questionnaire = models.ForeignKey(Questionnaire, on_delete=models.CASCADE, related_name='questions')
    text_en = models.TextField()
    text_bn = models.TextField()
    order = models.IntegerField(default=0)

    class Meta:
        ordering = ['order']

    def __str__(self):
        return self.text_en

class Option(models.Model):
    question = models.ForeignKey(Question, on_delete=models.CASCADE, related_name='options')
    text_en = models.CharField(max_length=200)
    text_bn = models.CharField(max_length=200)
    score_value = models.IntegerField(default=0)

    def __str__(self):
        return f"{self.text_en} ({self.score_value})"

class AssessmentResult(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='assessment_results')
    questionnaire = models.ForeignKey(Questionnaire, on_delete=models.CASCADE)
    total_score = models.IntegerField()
    severity_level = models.CharField(max_length=50) # e.g. Mild, Moderate, Severe
    recommendations_en = models.TextField()
    recommendations_bn = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.user.username} - {self.total_score} ({self.severity_level})"
