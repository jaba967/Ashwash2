from django.db import models

class Resource(models.Model):
    RESOURCE_TYPES = [
        ('article', 'Article'),
        ('video', 'Video'),
        ('audio', 'Audio'),
        ('pdf', 'PDF Document'),
    ]

    title_en = models.CharField(max_length=255)
    title_bn = models.CharField(max_length=255)
    summary_en = models.TextField()
    summary_bn = models.TextField()
    content_en = models.TextField(blank=True, default='')
    content_bn = models.TextField(blank=True, default='')
    resource_type = models.CharField(max_length=20, choices=RESOURCE_TYPES)
    media_url = models.TextField(blank=True, default='')
    media_file = models.FileField(upload_to='resources/', blank=True, null=True)
    duration_minutes = models.IntegerField(default=10)
    is_premium = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"[{self.resource_type.upper()}] {self.title_en}"

