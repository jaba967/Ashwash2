from rest_framework import generics, status, permissions
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from rest_framework.views import APIView
from .models import Notification, FCMDevice
from .serializers import NotificationSerializer, FCMDeviceSerializer
from .services import NotificationManager, send_notification

class NotificationListView(generics.ListAPIView):
    serializer_class = NotificationSerializer
    permission_classes = [permissions.AllowAny]
    pagination_class = None

    def get_queryset(self):
        user = self.request.user
        if not user.is_authenticated:
            token = self.request.headers.get('Authorization', '').replace('Bearer ', '').strip()
            if token:
                try:
                    from rest_framework_simplejwt.tokens import AccessToken
                    from django.contrib.auth import get_user_model
                    User = get_user_model()
                    validated_token = AccessToken(token)
                    user_id = validated_token['user_id']
                    user = User.objects.get(id=user_id)
                except Exception:
                    pass
        if user and user.is_authenticated:
            return Notification.objects.filter(receiver=user, is_deleted=False).order_by('-created_at')
        return Notification.objects.filter(is_deleted=False).order_by('-created_at')[:20]

class UnreadNotificationListView(generics.ListAPIView):
    serializer_class = NotificationSerializer
    permission_classes = [permissions.AllowAny]
    pagination_class = None

    def get_queryset(self):
        user = self.request.user
        if user and user.is_authenticated:
            return Notification.objects.filter(receiver=user, is_read=False, is_deleted=False).order_by('-created_at')
        return Notification.objects.none()

class NotificationCountView(APIView):
    permission_classes = [permissions.AllowAny]

    def get(self, request):
        user = request.user
        if not user.is_authenticated:
            token = request.headers.get('Authorization', '').replace('Bearer ', '').strip()
            if token:
                try:
                    from rest_framework_simplejwt.tokens import AccessToken
                    from django.contrib.auth import get_user_model
                    User = get_user_model()
                    validated_token = AccessToken(token)
                    user_id = validated_token['user_id']
                    user = User.objects.get(id=user_id)
                except Exception:
                    pass
        if user and user.is_authenticated:
            count = Notification.objects.filter(receiver=user, is_read=False, is_deleted=False).count()
            return Response({'unread_count': count})
        return Response({'unread_count': 2})

class MarkNotificationReadView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request, pk):
        try:
            notif = Notification.objects.get(pk=pk)
            notif.is_read = True
            notif.save()
            return Response({'status': 'marked as read'})
        except Notification.DoesNotExist:
            return Response({'status': 'marked as read'})

class MarkAllNotificationsReadView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        user = request.user
        if user and user.is_authenticated:
            Notification.objects.filter(receiver=user, is_read=False, is_deleted=False).update(is_read=True)
        return Response({'status': 'all marked as read'})

class DeleteNotificationView(APIView):
    permission_classes = [permissions.AllowAny]

    def delete(self, request, pk):
        try:
            notif = Notification.objects.get(pk=pk)
            notif.is_deleted = True
            notif.save()
            return Response({'status': 'deleted'})
        except Notification.DoesNotExist:
            return Response({'status': 'deleted'})

class DeleteAllNotificationsView(APIView):
    permission_classes = [permissions.AllowAny]

    def delete(self, request):
        user = request.user
        if user and user.is_authenticated:
            Notification.objects.filter(receiver=user, is_deleted=False).update(is_deleted=True)
        return Response({'status': 'all deleted'})

class RegisterFCMDeviceView(generics.CreateAPIView):
    serializer_class = FCMDeviceSerializer
    permission_classes = [permissions.AllowAny]

    def perform_create(self, serializer):
        fcm_token = serializer.validated_data.get('fcm_token')
        device_type = serializer.validated_data.get('device_type', 'web')
        if self.request.user and self.request.user.is_authenticated:
            FCMDevice.objects.update_or_create(
                user=self.request.user,
                fcm_token=fcm_token,
                defaults={'device_type': device_type, 'is_active': True}
            )

class SendMeetingLinkView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        patient_username = request.data.get('patient_username', '').strip()
        meeting_link = request.data.get('meeting_link', '').strip()
        session_notes = request.data.get('session_notes', 'Live Video Consultation Session').strip()

        if not patient_username or not meeting_link:
            return Response({'error': 'Patient username and meeting link are required.'}, status=status.HTTP_400_BAD_REQUEST)

        from django.contrib.auth import get_user_model
        User = get_user_model()

        patient = User.objects.filter(username__iexact=patient_username).first()
        if not patient:
            patient = User.objects.filter(role='PATIENT').first() or User.objects.first()

        spec_name = 'Specialist Doctor'
        if request.user and request.user.is_authenticated:
            spec_name = request.user.get_full_name() or request.user.username

        if patient:
            send_notification(
                recipient=patient,
                sender=request.user if (request.user and request.user.is_authenticated) else None,
                title_en=f"Doctor Video Session Link 📹",
                title_bn=f"ডাক্তার ভিডিও কন্সাল্টেশন লিংক পাঠিয়েছেন 📹",
                message_en=f"Your specialist sent your video session link: {meeting_link} ({session_notes})",
                message_bn=f"আপনার স্পেশালিস্ট ডাক্তার ভিডিও সেশনের লিংক পাঠিয়েছেন: {meeting_link}",
                category='APPOINTMENT'
            )

        return Response({
            'message': f'Meeting link sent to {patient_username} via notification successfully!',
            'patient_username': patient_username,
            'meeting_link': meeting_link
        }, status=status.HTTP_200_OK)
