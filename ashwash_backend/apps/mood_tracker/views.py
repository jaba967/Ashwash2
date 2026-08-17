from rest_framework import generics, permissions
from rest_framework.views import APIView
from rest_framework.response import Response
from django.db.models import Count
from .models import MoodLog
from .serializers import MoodLogSerializer

class MoodLogListCreateView(generics.ListCreateAPIView):
    serializer_class = MoodLogSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return MoodLog.objects.filter(user=self.request.user)

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)

class MoodAnalyticsView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        logs = MoodLog.objects.filter(user=request.user)
        total_logs = logs.count()
        mood_counts = logs.values('mood').annotate(count=Count('mood'))

        breakdown = {m[0]: 0 for m in MoodLog.MOOD_CHOICES}
        for item in mood_counts:
            breakdown[item['mood']] = item['count']

        recent_logs = MoodLogSerializer(logs[:7], many=True).data

        return Response({
            'total_logs': total_logs,
            'breakdown': breakdown,
            'recent_logs': recent_logs
        })
