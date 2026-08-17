from django.db import models
from django.conf import settings
from apps.authentication.models import Category

class Course(models.Model):
    instructor = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, null=True, blank=True, related_name='created_courses')
    category = models.ForeignKey(Category, on_delete=models.SET_NULL, null=True, blank=True, related_name='courses')
    title_en = models.CharField(max_length=255)
    title_bn = models.CharField(max_length=255)
    subtitle_en = models.CharField(max_length=255, blank=True, default='')
    subtitle_bn = models.CharField(max_length=255, blank=True, default='')
    description_en = models.TextField()
    description_bn = models.TextField()
    duration_weeks = models.IntegerField(default=4)
    total_tasks = models.IntegerField(default=10)
    type_label = models.CharField(max_length=50, default='Both') # e.g. Video, Audio, Both
    price = models.DecimalField(max_digits=10, decimal_places=2, default=0.00) # 0 for Free
    is_free = models.BooleanField(default=True)
    rating = models.DecimalField(max_digits=3, decimal_places=1, default=4.9)
    thumbnail_url = models.URLField(max_length=1000, blank=True, default='')
    media_file = models.FileField(upload_to='course_media/', blank=True, null=True)
    media_url = models.TextField(blank=True, default='')
    is_approved = models.BooleanField(default=False) # Requires Admin Approval before showing to Patients!
    created_at = models.DateTimeField(auto_now_add=True, null=True)
    updated_at = models.DateTimeField(auto_now=True, null=True)

    def __str__(self):
        return self.title_en

    @property
    def enrolled_count(self):
        return self.usercourseprogress_set.count()

    @property
    def average_rating(self):
        reviews = self.reviews.all()
        if not reviews.exists():
            return 0.0
        return round(sum([r.rating for r in reviews]) / reviews.count(), 1)

class CourseReview(models.Model):
    course = models.ForeignKey(Course, on_delete=models.CASCADE, related_name='reviews')
    patient = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='course_reviews')
    rating = models.IntegerField(default=5)
    review_text = models.TextField(blank=True, default='')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('course', 'patient')

    def __str__(self):
        return f"{self.patient.username}'s {self.rating}-star review for {self.course.title_en}"

class Module(models.Model):
    course = models.ForeignKey(Course, on_delete=models.CASCADE, related_name='modules')
    title_en = models.CharField(max_length=255)
    title_bn = models.CharField(max_length=255)
    order = models.IntegerField(default=1)

    class Meta:
        ordering = ['order']

    def __str__(self):
        return f"{self.course.title_en} - Mod {self.order}: {self.title_en}"

class Lesson(models.Model):
    module = models.ForeignKey(Module, on_delete=models.CASCADE, related_name='lessons')
    title_en = models.CharField(max_length=255)
    title_bn = models.CharField(max_length=255)
    content_en = models.TextField(blank=True)
    content_bn = models.TextField(blank=True)
    video_url = models.URLField(max_length=1000, blank=True, default='')
    duration_minutes = models.IntegerField(default=15)
    order = models.IntegerField(default=1)

    class Meta:
        ordering = ['order']

    def __str__(self):
        return f"{self.module.title_en} - Lesson {self.order}: {self.title_en}"

class Assignment(models.Model):
    lesson = models.ForeignKey(Lesson, on_delete=models.CASCADE, related_name='assignments')
    instruction_en = models.TextField()
    instruction_bn = models.TextField()

    def __str__(self):
        return f"Assignment for {self.lesson.title_en}"

class UserCourseProgress(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='course_progress')
    course = models.ForeignKey(Course, on_delete=models.CASCADE)
    completed_lessons_count = models.IntegerField(default=0)
    total_lessons_count = models.IntegerField(default=5)
    progress_percentage = models.IntegerField(default=0)
    is_completed = models.BooleanField(default=False)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        unique_together = ('user', 'course')

    def __str__(self):
        return f"{self.user.username} - {self.course.title_en}: {self.progress_percentage}%"

class UserLessonProgress(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    lesson = models.ForeignKey(Lesson, on_delete=models.CASCADE)
    is_completed = models.BooleanField(default=False)
    completed_at = models.DateTimeField(auto_now=True)

    class Meta:
        unique_together = ('user', 'lesson')

class HomeworkQuestion(models.Model):
    ANSWER_TYPES = [
        ('short', 'Short Answer'),
        ('long', 'Long Answer'),
        ('yes_no', 'Yes / No'),
        ('choice', 'Multiple Choice'),
        ('rating', 'Rating (1-5)'),
    ]
    lesson = models.ForeignKey(Lesson, on_delete=models.CASCADE, related_name='homework_questions')
    question_text = models.TextField()
    answer_type = models.CharField(max_length=20, choices=ANSWER_TYPES, default='short')
    options = models.JSONField(blank=True, null=True) # For multiple choice
    is_required = models.BooleanField(default=True)
    order = models.IntegerField(default=1)

    class Meta:
        ordering = ['order']

    def __str__(self):
        return f"{self.lesson.title_en} - Q{self.order}: {self.question_text[:30]}"

class HomeworkSubmission(models.Model):
    STATUS_CHOICES = [
        ('submitted', 'Submitted'),
        ('reviewed', 'Reviewed'),
    ]
    patient = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='homework_submissions')
    lesson = models.ForeignKey(Lesson, on_delete=models.CASCADE, related_name='homework_submissions')
    course = models.ForeignKey(Course, on_delete=models.CASCADE, related_name='homework_submissions')
    specialist = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='reviewed_homeworks')
    
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='submitted')
    specialist_feedback = models.TextField(blank=True, default='')
    
    submitted_at = models.DateTimeField(auto_now_add=True)
    reviewed_at = models.DateTimeField(blank=True, null=True)

    class Meta:
        unique_together = ('patient', 'lesson')
        ordering = ['-submitted_at']

    def __str__(self):
        return f"{self.patient.username} - {self.lesson.title_en} ({self.status})"

class HomeworkAnswer(models.Model):
    submission = models.ForeignKey(HomeworkSubmission, on_delete=models.CASCADE, related_name='answers')
    question = models.ForeignKey(HomeworkQuestion, on_delete=models.CASCADE, related_name='answers')
    answer_text = models.TextField(blank=True, default='')

    def __str__(self):
        return f"Answer to {self.question.id} by {self.submission.patient.username}"

import uuid

class CourseCertificate(models.Model):
    patient = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='certificates')
    course = models.ForeignKey(Course, on_delete=models.CASCADE, related_name='certificates')
    specialist = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name='issued_certificates')
    certificate_id = models.CharField(max_length=50, unique=True, blank=True)
    performance_ranking = models.CharField(max_length=100, blank=True, null=True)
    overall_progress = models.CharField(max_length=100, blank=True, null=True)
    specialist_recommendation = models.TextField(blank=True, default='')
    recommendation_status = models.CharField(max_length=20, choices=[('pending', 'Pending'), ('submitted', 'Submitted')], default='pending')
    recommendation_submitted_at = models.DateTimeField(null=True, blank=True)
    issued_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('patient', 'course')

    def save(self, *args, **kwargs):
        if not self.certificate_id:
            self.certificate_id = f"ASH-CERT-{uuid.uuid4().hex[:8].upper()}"
        super().save(*args, **kwargs)

    def __str__(self):
        return f"Certificate {self.certificate_id} for {self.patient.username}"
