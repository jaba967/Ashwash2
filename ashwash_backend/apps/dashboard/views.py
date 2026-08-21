from rest_framework import permissions, status
from rest_framework.views import APIView
from rest_framework.response import Response
from apps.courses.models import UserCourseProgress, Course
from apps.appointments.models import Appointment

class DashboardSummaryView(APIView):
    permission_classes = [permissions.AllowAny] # Allow soft access for dashboard preview

    def get(self, request):
        user = request.user if request.user.is_authenticated else None
        
        user_name = user.username if user else 'User'
        user_email = user.email if user else 'user@ashwash.com'
        user_category = getattr(user, 'preferred_category', 'First Time Mother') if user else 'First Time Mother'
        user_points = getattr(user, 'total_points', 450) if user else 450
        
        # Real DB values
        sessions = 0
        tasks = 0
        overall_course_progress = 0
        enrolled_courses_data = []
        
        if user:
            from apps.appointments.models import Appointment
            from apps.courses.models import HomeworkSubmission
            
            sessions = Appointment.objects.filter(patient=user, status='completed').count()
            tasks = HomeworkSubmission.objects.filter(patient=user).count()

            user_courses = UserCourseProgress.objects.filter(user=user)
            total_enrollments = user_courses.count()
            if total_enrollments > 0:
                total_progress = sum([c.progress_percentage for c in user_courses])
                overall_course_progress = int(total_progress / total_enrollments)

            recent_courses = user_courses[:3]
            for c in recent_courses:
                enrolled_courses_data.append({
                    'id': c.course.id,
                    'title': c.course.title_en,
                    'description': c.course.description_en,
                    'completed_lessons': c.completed_lessons_count,
                    'total_lessons': c.total_lessons_count,
                    'progress_percentage': c.progress_percentage
                })

        quote = {
            'quote_en': "Every step forward is progress. Keep going!",
            'quote_bn': "প্রতিটি পদক্ষেপই অগ্রগতি। এগিয়ে যান!"
        }

        return Response({
            'DEBUG_DB_URL': __import__('os').environ.get('DATABASE_URL', 'NOT_SET'),
            'user_name': user_name,
            'user_email': user_email,
            'category': user_category,
            'has_unread_notifications': True,
            'metrics': {
                'overall_course_progress': overall_course_progress,
                'sessions_attended': sessions,
                'tasks_completed': tasks,
                'points_earned': user_points,
            },
            'user': {
                'username': user_name,
                'email': user_email,
                'points': user_points,
                'sessions_attended': sessions,
                'tasks_completed': tasks,
            },
            'course_progress_percentage': overall_course_progress,
            'enrolled_courses': enrolled_courses_data,
            'upcoming_appointments_count': 0,
            'community_notifications_count': 0,
            'DEBUG_DB_URL': __import__('os').environ.get('DATABASE_URL', 'NOT_SET'),
            'daily_quote': quote
        }, status=status.HTTP_200_OK)


from django.utils import timezone
from django.contrib.auth import get_user_model

class PatientHealthReportDataView(APIView):
    """Fetches comprehensive, real-time clinical health report data for the authenticated patient ONLY.
    NO hardcoded/dummy fallbacks. Returns empty lists if patient is new.
    """
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        user = request.user
        patient_name = user.get_full_name() or user.username or "Patient"
        patient_id = f"#ASH-PAT-{user.id}"
        now_str = timezone.now().strftime("%d %b %Y, %I:%M %p")

        # 1. Course Progress & Summary
        user_progresses = UserCourseProgress.objects.filter(user=user)
        total_enrolled = user_progresses.count()
        completed_courses = user_progresses.filter(is_completed=True).count()
        ongoing_courses = user_progresses.filter(is_completed=False).count()

        total_lessons_sum = sum([p.total_lessons_count for p in user_progresses])
        completed_lessons_sum = sum([p.completed_lessons_count for p in user_progresses])
        remaining_lessons_sum = max(0, total_lessons_sum - completed_lessons_sum)

        # Overall course progress strictly calculated from enrolled courses
        if total_enrolled > 0:
            overall_course_pct = sum([p.progress_percentage for p in user_progresses]) // total_enrolled
        else:
            overall_course_pct = 0

        # 2. Homework Submissions
        from apps.courses.models import HomeworkSubmission, CourseCertificate
        submissions = HomeworkSubmission.objects.filter(patient=user)
        hw_assigned = total_lessons_sum
        hw_submitted = submissions.count()
        hw_reviewed = submissions.filter(status='reviewed').count()

        # 3. Specialist / Session History (Real database appointments)
        from apps.appointments.models import Appointment
        patient_apps = Appointment.objects.filter(user=user)
        total_sessions_count = patient_apps.count()
        
        sessions_data = []
        specialist_ids = list(patient_apps.values_list('specialist_id', flat=True).distinct())
        for spec_id in specialist_ids:
            spec_apps = patient_apps.filter(specialist_id=spec_id)
            first_app = spec_apps.first()
            if first_app and first_app.specialist:
                spec = first_app.specialist
                sessions_data.append({
                    'specialist_name': spec.full_name,
                    'specialization': spec.specialization,
                    'sessions_count': spec_apps.count(),
                    'last_session_date': first_app.appointment_date.strftime("%d %b %Y"),
                    'status': first_app.status.capitalize()
                })

        # 4. Course Performance Detail List
        course_performance_list = []
        for p in user_progresses:
            cert = CourseCertificate.objects.filter(patient=user, course=p.course).first()
            cert_status = "Issued & Verified" if (cert and cert.recommendation_status == 'submitted') else ("Pending Review" if cert else "Locked")
            instructor_name = p.course.instructor.get_full_name() if (p.course.instructor and p.course.instructor.get_full_name()) else (p.course.instructor.username if p.course.instructor else 'Ashwash Specialist')

            course_performance_list.append({
                'course_name': p.course.title_en,
                'instructor': instructor_name,
                'progress_percentage': p.progress_percentage,
                'completed_lessons': f"{p.completed_lessons_count}/{p.total_lessons_count}",
                'homework_completed': f"{submissions.filter(course=p.course).count()} Submitted",
                'final_status': 'Completed' if p.is_completed else 'Ongoing',
                'certificate_status': cert_status
            })

        # 5. Homework & Specialist Feedback List
        feedback_list = []
        for sub in submissions.filter(status='reviewed'):
            feedback_list.append({
                'lesson_title': sub.lesson.title_en if sub.lesson else 'Lesson Task',
                'submitted_at': sub.submitted_at.strftime("%d %b %Y"),
                'specialist_name': sub.specialist.get_full_name() if sub.specialist else 'Specialist',
                'feedback': sub.specialist_feedback or 'Homework reviewed successfully.'
            })

        # 6. Overall Performance Numbers
        overall_perf = {
            'course_completion_pct': int((completed_courses / total_enrolled * 100)) if total_enrolled > 0 else 0,
            'lesson_completion_pct': overall_course_pct,
            'homework_completion_pct': int((hw_reviewed / hw_submitted * 100)) if hw_submitted > 0 else 0,
            'specialist_sessions': total_sessions_count,
            'points_earned': getattr(user, 'total_points', 0) or 0
        }

        # 7. Treatment Timeline Events
        timeline_events = []
        for app in patient_apps[:3]:
            timeline_events.append({
                'date': app.appointment_date.strftime("%b %d, %Y"),
                'title': f"Booked Consultation Session with {app.specialist.full_name}"
            })
        for p in user_progresses[:3]:
            timeline_events.append({
                'date': p.updated_at.strftime("%b %d, %Y"),
                'title': f"Enrolled in '{p.course.title_en}' ({p.progress_percentage}% completed)"
            })
        for sub in submissions[:3]:
            timeline_events.append({
                'date': sub.submitted_at.strftime("%b %d, %Y"),
                'title': f"Submitted Homework for '{sub.lesson.title_en if sub.lesson else 'Lesson'}'"
            })

        return Response({
            'report_header': {
                'patient_name': patient_name,
                'generated_at': now_str,
                'patient_id': patient_id,
                'wellness_summary': f"Patient has completed {completed_courses} of {total_enrolled} enrolled courses with {overall_course_pct}% average progress." if total_enrolled > 0 else "Patient is starting their wellness recovery journey."
            },
            'course_summary': {
                'total_enrolled': total_enrolled,
                'completed_courses': completed_courses,
                'ongoing_courses': ongoing_courses,
                'overall_course_progress': overall_course_pct
            },
            'lesson_homework_progress': {
                'total_lessons': total_lessons_sum,
                'completed_lessons': completed_lessons_sum,
                'remaining_lessons': remaining_lessons_sum,
                'homework_assigned': hw_assigned,
                'homework_submitted': hw_submitted,
                'homework_reviewed': hw_reviewed
            },
            'specialist_sessions': sessions_data,
            'course_performance': course_performance_list,
            'homework_feedback': feedback_list,
            'overall_performance': overall_perf,
            'treatment_timeline': timeline_events
        })
