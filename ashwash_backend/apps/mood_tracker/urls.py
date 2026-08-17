from django.urls import path
from .views import MoodLogListCreateView, MoodAnalyticsView

urlpatterns = [
    path('logs/', MoodLogListCreateView.as_view(), name='mood_logs'),
    path('analytics/', MoodAnalyticsView.as_view(), name='mood_analytics'),
]
