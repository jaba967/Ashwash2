from django.contrib import admin
from .models import Course, Module, Lesson, Assignment, UserCourseProgress

admin.site.register(Course)
admin.site.register(Module)
admin.site.register(Lesson)
admin.site.register(Assignment)
admin.site.register(UserCourseProgress)
