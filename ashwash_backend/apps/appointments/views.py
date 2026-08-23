from rest_framework import generics, permissions
from rest_framework.views import APIView
from rest_framework.response import Response
from .models import Appointment
from .serializers import SpecialistSerializer, AppointmentSerializer, parse_slot_end_datetime
from apps.authentication.models import SpecialistProfile
from django.db.models import Q
from django.utils import timezone

class SpecialistListView(generics.ListAPIView):
    serializer_class = SpecialistSerializer
    permission_classes = [permissions.AllowAny]

    def get_queryset(self):
        queryset = SpecialistProfile.objects.all()
        loc_type = self.request.query_params.get('type') # local, international
        category_id = self.request.query_params.get('category_id')
        search = self.request.query_params.get('search') or self.request.query_params.get('name') or self.request.query_params.get('q')

        if search:
            queryset = queryset.filter(
                Q(full_name__icontains=search) | 
                Q(specialization__icontains=search)
            )

        return queryset

class SpecialistDetailView(generics.RetrieveAPIView):
    queryset = SpecialistProfile.objects.all()
    serializer_class = SpecialistSerializer
    permission_classes = [permissions.AllowAny]

class AppointmentListCreateView(generics.ListCreateAPIView):
    serializer_class = AppointmentSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        if user.role in ['SPECIALIST', 'DOCTOR']:
            return Appointment.objects.filter(Q(specialist__user=user) | Q(user=user)).distinct()
        return Appointment.objects.filter(user=user)

    def perform_create(self, serializer):
        appointment = serializer.save(user=self.request.user)

        # Trigger 4: Notify patient & specialist on session booking request
        try:
            from apps.notifications.views import send_notification
            spec_name = appointment.specialist.full_name if appointment.specialist else 'Specialist'
            patient_name = self.request.user.get_full_name() or self.request.user.username
            app_date = getattr(appointment, 'appointment_date', getattr(appointment, 'date', 'Scheduled Date'))
            app_time = getattr(appointment, 'time_slot', getattr(appointment, 'time', 'Scheduled Time'))

            # 1. Patient notification
            send_notification(
                recipient=self.request.user,
                sender=None,
                title_en=f"Session Request Sent to {spec_name}",
                title_bn=f"{spec_name}-এর কাছে সেশন রিকোয়েস্ট পাঠানো হয়েছে",
                message_en=f"Your session request for {app_date} ({app_time}) has been sent. Please wait for confirmation.",
                message_bn=f"আপনার {app_date} ({app_time}) তারিখের সেশন রিকোয়েস্ট পাঠানো হয়েছে। কনফার্মেশনের জন্য অপেক্ষা করুন।",
                category='APPOINTMENT'
            )

            # 2. Specialist notification (directly from SpecialistProfile's user)
            spec_user = appointment.specialist.user if appointment.specialist else None

            if spec_user:
                send_notification(
                    recipient=spec_user,
                    sender=self.request.user,
                    title_en=f"New Session Request from {patient_name} 🩺",
                    title_bn=f"{patient_name}-এর কাছ থেকে সেশন বুকিং রিকোয়েস্ট 🩺",
                    message_en=f"Patient {patient_name} requested a session for {app_date} ({app_time}).",
                    message_bn=f"পেশেন্ট {patient_name} {app_date} ({app_time})-এর জন্য সেশন বুক করতে চেয়েছেন।",
                    category='APPOINTMENT'
                )
        except Exception as e:
            print("Error in create appointment notification:", e)

class AppointmentDetailView(generics.RetrieveUpdateDestroyAPIView):
    queryset = Appointment.objects.all()
    serializer_class = AppointmentSerializer
    permission_classes = [permissions.IsAuthenticated]

    def perform_update(self, serializer):
        old_status = self.get_object().status
        old_meeting_link = self.get_object().meeting_link
        appointment = serializer.save()

        try:
            from apps.notifications.views import send_notification
            spec_name = appointment.specialist.full_name if appointment.specialist else 'Specialist'
            app_date = getattr(appointment, 'appointment_date', getattr(appointment, 'date', 'Scheduled Date'))
            app_time = getattr(appointment, 'time_slot', getattr(appointment, 'time', 'Scheduled Time'))
            
            # Notify patient when specialist confirms session
            if old_status != 'confirmed' and appointment.status == 'confirmed':
                send_notification(
                    recipient=appointment.user,
                    sender=appointment.specialist.user if appointment.specialist else None,
                    title_en=f"Session Confirmed with {spec_name} ✅",
                    title_bn=f"{spec_name}-এর সাথে সেশন কনফার্ম করা হয়েছে ✅",
                    message_en=f"Your session on {app_date} ({app_time}) has been confirmed! Get ready.",
                    message_bn=f"আপনার {app_date} ({app_time})-এর সেশনটি কনফার্ম করা হয়েছে। প্রস্তুতি নিন।",
                    category='APPOINTMENT'
                )

            # Notify patient when meeting link is sent
            if appointment.meeting_link and (not old_meeting_link or old_meeting_link != appointment.meeting_link):
                send_notification(
                    recipient=appointment.user,
                    sender=appointment.specialist.user if appointment.specialist else None,
                    title_en="Meeting Link Sent 🔗",
                    title_bn="মিটিং লিংক পাঠানো হয়েছে 🔗",
                    message_en=f"Join your session with {spec_name}: {appointment.meeting_link}",
                    message_bn=f"{spec_name}-এর সাথে সেশনের ভিডিও লিংক: {appointment.meeting_link}",
                    category='APPOINTMENT',
                    related_object_id=appointment.meeting_link,
                    related_object_type='MEETING_LINK',
                    extra_data={'meeting_link': appointment.meeting_link}
                )

            # Notify patient when session is completed
            if old_status != 'completed' and appointment.status == 'completed':
                send_notification(
                    recipient=appointment.user,
                    sender=appointment.specialist.user if appointment.specialist else None,
                    title_en="Session Completed 🏁",
                    title_bn="সেশন সম্পন্ন হয়েছে 🏁",
                    message_en=f"Your session with {spec_name} is now complete. Thank you!",
                    message_bn=f"{spec_name}-এর সাথে আপনার সেশনটি শেষ হয়েছে। ধন্যবাদ!",
                    category='APPOINTMENT'
                )
                
            # Notify patient when session is declined/cancelled
            if old_status != 'cancelled' and appointment.status == 'cancelled':
                send_notification(
                    recipient=appointment.user,
                    sender=appointment.specialist.user if appointment.specialist else None,
                    title_en="Session Declined ❌",
                    title_bn="সেশন বাতিল করা হয়েছে ❌",
                    message_en=f"Your session with {spec_name} has been declined. Please book another slot.",
                    message_bn=f"{spec_name}-এর সাথে আপনার সেশনটি বাতিল করা হয়েছে। দয়া করে অন্য সময় বুক করুন।",
                    category='APPOINTMENT'
                )

        except Exception as e:
            print("Error in update appointment notification:", e)


class BookedSlotsView(APIView):
    """
    GET /api/appointments/booked-slots/?specialist_id=<id>&date=<YYYY-MM-DD>

    Returns the list of time slots that are currently booked (active/upcoming)
    for the given specialist on the given date.

    KEY RULE: If a slot's end time has already passed, it is NOT included in
    the response — meaning it automatically becomes available again for booking.
    """
    permission_classes = [permissions.AllowAny]

    def get(self, request):
        specialist_id = request.query_params.get('specialist_id')
        date_str = request.query_params.get('date')

        if not specialist_id or not date_str:
            return Response({'booked_slots': []})

        try:
            import datetime
            appointment_date = datetime.date.fromisoformat(date_str)
        except (ValueError, TypeError):
            return Response({'booked_slots': [], 'error': 'Invalid date format. Use YYYY-MM-DD.'})

        # Fetch all non-cancelled bookings for this specialist+date
        bookings = Appointment.objects.filter(
            specialist_id=specialist_id,
            appointment_date=appointment_date,
        ).exclude(status='cancelled')

        now = timezone.now()
        active_booked_slots = []

        for b in bookings:
            slot_end = parse_slot_end_datetime(b.appointment_date, b.time_slot)
            # Include only if slot window has NOT expired yet
            if slot_end is None or slot_end > now:
                if b.time_slot not in active_booked_slots:
                    active_booked_slots.append(b.time_slot)

        return Response({'booked_slots': active_booked_slots})
