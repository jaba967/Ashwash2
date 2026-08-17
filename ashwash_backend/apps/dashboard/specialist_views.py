from rest_framework import permissions, status
from rest_framework.views import APIView
from rest_framework.response import Response
from apps.appointments.models import Appointment
from apps.authentication.models import SpecialistProfile

class SpecialistDashboardSummaryView(APIView):
    permission_classes = [permissions.AllowAny]

    def get(self, request):
        user = request.user if request.user.is_authenticated else None
        
        sp = None
        if user and hasattr(user, 'specialist_profile'):
            sp = user.specialist_profile

        today_appointments = [
            {
                'id': 1,
                'patient_name': 'Nusrat Sultana',
                'patient_avatar': 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150',
                'time_slot': '10:30 AM - 11:30 AM',
                'category': 'Postpartum Depression',
                'status': 'confirmed',
                'meeting_link': 'https://meet.google.com/ash-wash-wellness-101',
                'notes': 'Follow up on week 3 reflection journal.',
            },
            {
                'id': 2,
                'patient_name': 'Sadia Rahman',
                'patient_avatar': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
                'time_slot': '03:00 PM - 04:00 PM',
                'category': 'Single Parent Care',
                'status': 'pending',
                'meeting_link': 'https://meet.google.com/ash-wash-wellness-102',
                'notes': 'Initial intake consultation for anxiety management.',
            }
        ]

        pending_homeworks = [
            {
                'id': 1,
                'patient_name': 'Nusrat Sultana',
                'course_title': 'Postpartum Depression Recovery Program',
                'assignment_title': 'Week 2 Self-Care Habit Tracker & Reflection',
                'submitted_at': '10 mins ago',
                'submission_text': 'I completed all 3 daily habits this week and practiced breathing exercises whenever feeling overwhelmed.',
            },
            {
                'id': 2,
                'patient_name': 'Meherun Nesa',
                'course_title': 'Single Parent Emotional Strength',
                'assignment_title': 'Work-Life Balance & Boundary Journal',
                'submitted_at': '1 hour ago',
                'submission_text': 'I set a firm boundary with overtime work on Wednesday and spent 2 hours un-interrupted with my son.',
            }
        ]

        recent_notifications = [
            {
                'id': 'sn1',
                'title': 'New Session Booking 📅',
                'body': 'Sadia Rahman requested a consultation for today at 3:00 PM.',
                'timestamp': '5 mins ago',
            },
            {
                'id': 'sn2',
                'title': 'Homework Submitted 📝',
                'body': 'Nusrat Sultana submitted Week 2 Reflection Journal.',
                'timestamp': '10 mins ago',
            },
            {
                'id': 'sn3',
                'title': 'Community Question 💬',
                'body': 'A member asked: "How can I handle post-birth mood swings without guilt?"',
                'timestamp': '30 mins ago',
            }
        ]

        return Response({
            'specialist_name': sp.full_name if sp else (user.username if user else 'Dr. Mekhala Sarkar'),
            'specialization': sp.specialization if sp else 'Clinical Psychologist & Consultant',
            'is_profile_complete': sp.is_profile_complete if sp else True,
            'metrics': {
                'today_appointments_count': len(today_appointments),
                'upcoming_sessions_count': 4,
                'pending_homework_count': len(pending_homeworks),
                'active_courses_count': 3,
                'average_rating': float(sp.rating) if sp else 4.9,
                'completed_sessions_count': sp.total_reviews if sp else 48,
            },
            'today_appointments': today_appointments,
            'pending_homeworks': pending_homeworks,
            'recent_notifications': recent_notifications,
        })
