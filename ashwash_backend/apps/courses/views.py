from rest_framework import generics, permissions, status
from rest_framework.views import APIView
from rest_framework.response import Response
from .models import Course, Lesson, UserCourseProgress, UserLessonProgress
from .serializers import CourseSerializer, UserCourseProgressSerializer, LessonSerializer

def save_lessons_for_course(course, modules_or_lessons_data):
    if not modules_or_lessons_data:
        return
    from .models import Module, Lesson, Assignment, HomeworkQuestion

    if isinstance(modules_or_lessons_data, list):
        updated_module_ids = []
        for mod_idx, item in enumerate(modules_or_lessons_data, 1):
            if isinstance(item, dict) and ('lessons' in item or 'module_title' in item):
                mod_title = item.get('module_title') or item.get('title') or f"Module {mod_idx}"
                module, _ = Module.objects.update_or_create(
                    course=course,
                    title_en=mod_title,
                    defaults={'title_bn': mod_title, 'order': mod_idx}
                )
                updated_module_ids.append(module.id)
                
                lessons = item.get('lessons', [])
                updated_lesson_ids = []
                for les_idx, l in enumerate(lessons, 1):
                    if isinstance(l, dict):
                        l_title = l.get('title') or l.get('title_en') or f'Lesson {les_idx}'
                        l_type = l.get('type') or 'video'
                        l_url = l.get('video_url') or l.get('file') or l.get('url') or ''
                        l_task = l.get('assignment_instruction') or l.get('task') or ''

                        lesson_obj, _ = Lesson.objects.update_or_create(
                            module=module,
                            title_en=l_title,
                            defaults={
                                'title_bn': l_title,
                                'content_en': l_type,
                                'content_bn': l_type,
                                'video_url': str(l_url),
                                'order': les_idx
                            }
                        )
                        updated_lesson_ids.append(lesson_obj.id)
                        
                        hw_questions = l.get('homework_questions')
                        updated_q_ids = []
                        if hw_questions and isinstance(hw_questions, list) and len(hw_questions) > 0:
                            for q_idx, q in enumerate(hw_questions, 1):
                                q_text = q.get('question_text', '')
                                q_obj, _ = HomeworkQuestion.objects.update_or_create(
                                    lesson=lesson_obj,
                                    question_text=q_text,
                                    defaults={
                                        'answer_type': q.get('answer_type', 'short'),
                                        'options': q.get('options', None),
                                        'is_required': q.get('is_required', True),
                                        'order': q_idx
                                    }
                                )
                                updated_q_ids.append(q_obj.id)
                        elif l_task:
                            # Backward compatibility
                            Assignment.objects.update_or_create(
                                lesson=lesson_obj,
                                defaults={'instruction_en': l_task, 'instruction_bn': l_task}
                            )
                            q_obj, _ = HomeworkQuestion.objects.update_or_create(
                                lesson=lesson_obj,
                                question_text=l_task,
                                defaults={'answer_type': 'long', 'is_required': True, 'order': 1}
                            )
                            updated_q_ids.append(q_obj.id)
                            
                        # Remove old questions that were deleted
                        HomeworkQuestion.objects.filter(lesson=lesson_obj).exclude(id__in=updated_q_ids).delete()
                        
                # Remove old lessons that were deleted
                Lesson.objects.filter(module=module).exclude(id__in=updated_lesson_ids).delete()
                
        # Remove old modules that were deleted
        if updated_module_ids:
            Module.objects.filter(course=course).exclude(id__in=updated_module_ids).delete()

class CourseListView(generics.ListCreateAPIView):
    serializer_class = CourseSerializer
    permission_classes = [permissions.AllowAny]

    def get_queryset(self):
        queryset = Course.objects.all()
        category_id = self.request.query_params.get('category_id')
        instructor_id = self.request.query_params.get('instructor_id') or self.request.query_params.get('instructor')
        search = self.request.query_params.get('search')
        show_all = self.request.query_params.get('show_all')

        token = self.request.headers.get('Authorization', '').replace('Bearer ', '').strip()
        user = self.request.user
        if not user.is_authenticated and token:
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
            if getattr(user, 'role', '') in ['SPECIALIST', 'DOCTOR']:
                queryset = queryset.filter(instructor=user)
            elif user.is_staff or getattr(user, 'role', '') == 'ADMIN':
                pass # Admin sees all
            else:
                queryset = queryset.filter(is_approved=True)
        else:
            if show_all == 'true':
                pass # Admin dashboard without token uses this
            else:
                queryset = queryset.filter(is_approved=True)

        if category_id:
            queryset = queryset.filter(category_id=category_id)
        if instructor_id:
            queryset = queryset.filter(instructor_id=instructor_id)
        if search:
            from django.db.models import Q
            queryset = queryset.filter(
                Q(title_en__icontains=search) | 
                Q(title_bn__icontains=search) | 
                Q(description_en__icontains=search) | 
                Q(description_bn__icontains=search)
            )

        return queryset

    def perform_create(self, serializer):
        token = self.request.headers.get('Authorization', '').replace('Bearer ', '').strip()
        user = self.request.user
        if not user.is_authenticated and token:
            try:
                from rest_framework_simplejwt.tokens import AccessToken
                from django.contrib.auth import get_user_model
                User = get_user_model()
                validated_token = AccessToken(token)
                user_id = validated_token['user_id']
                user = User.objects.get(id=user_id)
            except Exception:
                pass

        if not user or not user.is_authenticated:
            from django.contrib.auth import get_user_model
            User = get_user_model()
            user = User.objects.filter(role='SPECIALIST').first()

        media_file = self.request.FILES.get('media_file')
        media_url = self.request.data.get('media_url', '')

        is_appr = False
        if user and (user.is_staff or getattr(user, 'role', '') == 'ADMIN'):
            is_appr = True

        course = serializer.save(
            instructor=user,
            media_file=media_file,
            media_url=media_url,
            is_approved=is_appr
        )
        lessons_data = self.request.data.get('modules') or self.request.data.get('lessons', [])
        save_lessons_for_course(course, lessons_data)

class CourseDetailView(generics.RetrieveUpdateDestroyAPIView):
    queryset = Course.objects.all()
    serializer_class = CourseSerializer
    permission_classes = [permissions.AllowAny]

    def perform_update(self, serializer):
        media_file = self.request.FILES.get('media_file')
        media_url = self.request.data.get('media_url', '')

        extra_kwargs = {}
        if media_file:
            extra_kwargs['media_file'] = media_file
        if media_url:
            extra_kwargs['media_url'] = media_url

        course = serializer.save(**extra_kwargs)

        modules_data = self.request.data.get('modules') or self.request.data.get('lessons')
        if modules_data:
            from .models import Module
            save_lessons_for_course(course, modules_data)

        # Trigger notification to all patients about course curriculum update
        try:
            from apps.notifications.views import send_notification
            from django.contrib.auth import get_user_model
            User = get_user_model()
            spec_name = course.instructor.first_name if (course.instructor and hasattr(course.instructor, 'first_name') and course.instructor.first_name) else 'Specialist Doctor'
            patients = User.objects.filter(role='PATIENT') if hasattr(User, 'role') else User.objects.filter(is_staff=False)
            for p in patients:
                send_notification(
                    recipient=p,
                    sender=course.instructor,
                    title_en=f"Course Curriculum Updated: {course.title_en} 🔔",
                    title_bn=f"কোর্সের সিলেবাস আপডেট: {course.title_bn} 🔔",
                    message_en=f"New modules, tasks, and lessons were added to '{course.title_en}' by {spec_name}.",
                    message_bn=f"বিশেষজ্ঞ {spec_name} আপনার কোর্স '{course.title_bn}'-এ নতুন মডিউল ও লেসন যুক্ত করেছেন।",
                    category='COURSE'
                )
        except Exception:
            pass
            pass

class CompleteLessonView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, lesson_id):
        try:
            lesson = Lesson.objects.get(id=lesson_id)
        except Lesson.DoesNotExist:
            return Response({'error': 'Lesson not found'}, status=status.HTTP_404_NOT_FOUND)

        course = lesson.module.course
        progress = UserCourseProgress.objects.filter(user=request.user, course=course).first()
        if not progress:
            return Response({'error': 'You must enroll in this course before completing lessons.'}, status=status.HTTP_403_FORBIDDEN)

        UserLessonProgress.objects.get_or_create(user=request.user, lesson=lesson, defaults={'is_completed': True})

        all_lessons_count = Lesson.objects.filter(module__course=course).count() or 1
        completed_count = UserLessonProgress.objects.filter(
            user=request.user, lesson__module__course=course, is_completed=True
        ).count()

        pct = int((completed_count / all_lessons_count) * 100)
        progress.completed_lessons_count = completed_count
        progress.total_lessons_count = all_lessons_count
        progress.progress_percentage = pct
        progress.is_completed = (pct >= 100)
        progress.save()

        # If 100% completed, create pending certificate & notify instructor
        if progress.is_completed:
            try:
                from .models import CourseCertificate
                cert, cert_created = CourseCertificate.objects.get_or_create(
                    patient=request.user,
                    course=course,
                    defaults={
                        'specialist': course.instructor,
                        'overall_progress': '100% Completed',
                        'performance_ranking': 'Outstanding',
                        'recommendation_status': 'pending'
                    }
                )

                if course.instructor and course.instructor != request.user:
                    from apps.notifications.views import send_notification
                    patient_name = request.user.get_full_name() or request.user.username
                    send_notification(
                        recipient=course.instructor,
                        sender=request.user,
                        title_en=f"Patient completed course — Certificate can be issued 🎓",
                        title_bn=f"রোগী কোর্স ১০০% সম্পন্ন করেছেন — সার্টিফিকেট ইস্যু করতে পারেন 🎓",
                        message_en=f"Patient {patient_name} has completed 100% of '{course.title_en}'. You can now issue their certificate.",
                        message_bn=f"রোগী {patient_name} আপনার '{course.title_bn}' কোর্স ১০০% সম্পন্ন করেছেন। আপনি এখন তাদের সার্টিফিকেট মূল্যায়ন ও ইস্যু করতে পারেন।",
                        category='COURSE',
                        related_object_id=cert.id,
                        related_object_type='CERTIFICATE'
                    )
            except Exception:
                pass
        else:
            try:
                if course.instructor and course.instructor != request.user:
                    from apps.notifications.views import send_notification
                    patient_name = request.user.get_full_name() or request.user.username
                    send_notification(
                        recipient=course.instructor,
                        sender=request.user,
                        title_en=f"Homework Task Submitted by {patient_name} 📝",
                        title_bn=f"{patient_name} কোর্স টাস্ক জমা দিয়েছেন 📝",
                        message_en=f"Patient {patient_name} submitted homework task in '{course.title_en}'.",
                        message_bn=f"পেশেন্ট {patient_name} আপনার কোর্স '{course.title_bn}'-এর টাস্ক সাবমিট করেছেন।",
                        category='COURSE'
                    )
            except Exception:
                pass

        return Response(UserCourseProgressSerializer(progress).data)

class UserEnrolledCoursesView(generics.ListAPIView):
    serializer_class = UserCourseProgressSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return UserCourseProgress.objects.filter(user=self.request.user)

class EnrollCourseView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, course_id):
        try:
            course = Course.objects.get(id=course_id)
        except Course.DoesNotExist:
            return Response({'error': 'Course not found'}, status=status.HTTP_404_NOT_FOUND)

        progress, created = UserCourseProgress.objects.get_or_create(
            user=request.user,
            course=course,
            defaults={'total_lessons_count': Lesson.objects.filter(module__course=course).count() or 5}
        )
        
        if created:
            try:
                if course.instructor and course.instructor != request.user:
                    from apps.notifications.views import send_notification
                    patient_name = request.user.full_name if (hasattr(request.user, 'full_name') and request.user.full_name) else request.user.username
                    send_notification(
                        recipient=course.instructor,
                        sender=request.user,
                        title_en=f"New Patient Enrolled",
                        title_bn=f"নতুন পেশেন্ট এনরোল করেছেন",
                        message_en=f"{patient_name} has enrolled in your course '{course.title_en}'.",
                        message_bn=f"{patient_name} আপনার '{course.title_bn}' কোর্সে এনরোল করেছেন।",
                        category='COURSE'
                    )
            except Exception:
                pass

        return Response({
            'status': 'enrolled',
            'course_id': course.id,
            'title': course.title_en,
            'progress': UserCourseProgressSerializer(progress).data
        }, status=status.HTTP_201_CREATED if created else status.HTTP_200_OK)


from .models import HomeworkSubmission, HomeworkAnswer, HomeworkQuestion, CourseCertificate

class SubmitHomeworkView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        lesson_id = request.data.get('lesson')
        answers_data = request.data.get('answers', [])
        
        try:
            lesson = Lesson.objects.get(id=lesson_id)
        except Lesson.DoesNotExist:
            return Response({'error': 'Lesson not found'}, status=status.HTTP_404_NOT_FOUND)
            
        submission, _ = HomeworkSubmission.objects.get_or_create(
            patient=request.user,
            lesson=lesson,
            defaults={
                'course': lesson.module.course, 
                'specialist': lesson.module.course.instructor,
                'status': 'submitted'
            }
        )
        submission.status = 'submitted'
        submission.save()
        
        for ans in answers_data:
            q_id = ans.get('question')
            text = ans.get('answer_text', '')
            try:
                question = HomeworkQuestion.objects.get(id=q_id)
                HomeworkAnswer.objects.update_or_create(
                    submission=submission,
                    question=question,
                    defaults={'answer_text': text}
                )
            except HomeworkQuestion.DoesNotExist:
                pass
                
        try:
            if lesson.module.course.instructor:
                from apps.notifications.views import send_notification
                patient_name = request.user.full_name if (hasattr(request.user, 'full_name') and request.user.full_name) else request.user.username
                send_notification(
                    recipient=lesson.module.course.instructor,
                    sender=request.user,
                    title_en=f"Homework Submitted",
                    title_bn=f"হোমওয়ার্ক সাবমিট হয়েছে",
                    message_en=f"{patient_name} submitted homework for '{lesson.title_en}'.",
                    message_bn=f"{patient_name} আপনার '{lesson.title_bn}' লেসনের হোমওয়ার্ক সাবমিট করেছেন।",
                    category='COURSE'
                )
        except Exception:
            pass
            
        return Response({'id': submission.id, 'status': 'submitted'})

class PatientHomeworkView(generics.ListAPIView):
    permission_classes = [permissions.IsAuthenticated]
    from .serializers import HomeworkSubmissionSerializer
    serializer_class = HomeworkSubmissionSerializer

    def get_queryset(self):
        return HomeworkSubmission.objects.filter(patient=self.request.user)

class SpecialistHomeworkSubmissionsView(generics.ListAPIView):
    permission_classes = [permissions.IsAuthenticated]
    from .serializers import HomeworkSubmissionSerializer
    serializer_class = HomeworkSubmissionSerializer

    def get_queryset(self):
        if self.request.user.role in ['SPECIALIST', 'ADMIN', 'DOCTOR']:
            return HomeworkSubmission.objects.filter(course__instructor=self.request.user)
        return HomeworkSubmission.objects.none()

class SpecialistReviewHomeworkView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, pk):
        try:
            submission = HomeworkSubmission.objects.get(pk=pk)
            feedback = request.data.get('feedback', '')
            submission.specialist_feedback = feedback
            submission.status = 'reviewed'
            from django.utils import timezone
            submission.reviewed_at = timezone.now()
            submission.save()

            # Notify the patient with the feedback content and submission ID
            try:
                from apps.notifications.views import send_notification
                specialist_name = (
                    request.user.get_full_name() or request.user.username
                    if request.user and request.user.is_authenticated else 'Your Specialist'
                )
                short_feedback = (feedback[:120] + '…') if len(feedback) > 120 else feedback
                send_notification(
                    recipient=submission.patient,
                    sender=request.user,
                    title_en=f"Homework Feedback Received 📝",
                    title_bn=f"হোমওয়ার্ক ফিডব্যাক পেয়েছেন 📝",
                    message_en=(
                        f"{specialist_name} reviewed your homework for '"
                        f"{submission.lesson.title_en}'.\n\nFeedback: {short_feedback}"
                    ),
                    message_bn=(
                        f"{specialist_name} আপনার '{submission.lesson.title_bn}' লেসনের হোমওয়ার্ক রিভিউ করেছেন।\n\nফিডব্যাক: {short_feedback}"
                    ),
                    category='COURSE',
                    related_object_id=submission.id,
                    related_object_type='HOMEWORK_SUBMISSION',
                )
            except Exception:
                pass

            return Response({'status': 'reviewed'})
        except HomeworkSubmission.DoesNotExist:
            return Response({'error': 'Not found or not authorized'}, status=status.HTTP_404_NOT_FOUND)


class PatientSubmissionDetailView(APIView):
    """Patient fetches a specific homework submission by ID (used when tapping notification)."""
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, pk):
        try:
            submission = HomeworkSubmission.objects.get(pk=pk, patient=request.user)
        except HomeworkSubmission.DoesNotExist:
            return Response({'error': 'Submission not found.'}, status=status.HTTP_404_NOT_FOUND)

        from .serializers import HomeworkSubmissionSerializer
        return Response(HomeworkSubmissionSerializer(submission).data)

from .models import CourseReview

class SubmitCourseReviewView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, course_id):
        try:
            course = Course.objects.get(id=course_id)
        except Course.DoesNotExist:
            return Response({'error': 'Course not found'}, status=status.HTTP_404_NOT_FOUND)

        # Verify completion
        progress = UserCourseProgress.objects.filter(user=request.user, course=course, is_completed=True).first()
        if not progress:
            return Response({'error': 'You must complete the course before reviewing.'}, status=status.HTTP_403_FORBIDDEN)

        rating = request.data.get('rating')
        review_text = request.data.get('review_text', '')

        try:
            rating = int(rating)
            if rating < 1 or rating > 5:
                raise ValueError
        except (TypeError, ValueError):
            return Response({'error': 'Rating must be an integer between 1 and 5.'}, status=status.HTTP_400_BAD_REQUEST)

        # Check for existing review
        if CourseReview.objects.filter(course=course, patient=request.user).exists():
            return Response({'error': 'You have already reviewed this course.'}, status=status.HTTP_400_BAD_REQUEST)

        CourseReview.objects.create(
            course=course,
            patient=request.user,
            rating=rating,
            review_text=review_text
        )

        return Response({'status': 'Review submitted successfully'})


from .models import CourseCertificate
from .serializers import CourseCertificateSerializer
from apps.notifications.services import send_notification
from django.utils import timezone
from django.contrib.auth import get_user_model

User = get_user_model()

class CourseCertificateView(APIView):
    """Patient views or unlocks their course certificate when 100% completed."""
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, course_id):
        try:
            try:
                course = Course.objects.get(id=course_id)
            except (Course.DoesNotExist, ValueError):
                return Response({'error': 'Course not found'}, status=status.HTTP_404_NOT_FOUND)

            # Check if user is enrolled in this course
            progress = UserCourseProgress.objects.filter(user=request.user, course=course).first()
            if not progress:
                return Response({'error': 'You are not enrolled in this course.'}, status=status.HTTP_403_FORBIDDEN)

            # Check if course is 100% completed
            if not progress.is_completed and progress.progress_percentage < 100:
                return Response({'error': 'Course must be 100% completed to view certificate.'}, status=status.HTTP_403_FORBIDDEN)

            # Get or create certificate for completed course
            cert, created = CourseCertificate.objects.get_or_create(
                patient=request.user,
                course=course,
                defaults={
                    'specialist': course.instructor,
                    'overall_progress': '100% Completed',
                    'performance_ranking': 'Outstanding',
                    'recommendation_status': 'pending',
                }
            )

            # Notify Specialist & Admin safely if newly created
            try:
                if created:
                    patient_name = request.user.get_full_name() or request.user.username
                    recipients = []
                    if course.instructor:
                        recipients.append(course.instructor)
                    admins = User.objects.filter(role='ADMIN')
                    recipients.extend(list(admins))

                    for r in set(recipients):
                        send_notification(
                            recipient=r,
                            sender=request.user,
                            title_en="Patient completed course — Certificate can be issued 🎓",
                            title_bn="রোগী কোর্স ১০০% সম্পন্ন করেছেন — সার্টিফিকেট ইস্যু করতে পারেন 🎓",
                            message_en=f"Patient {patient_name} has completed 100% of course '{course.title_en}'. Please submit your performance recommendation.",
                            message_bn=f"রোগী {patient_name} '{course.title_bn}' কোর্সের ১০০% সম্পন্ন করেছেন।",
                            category='COURSE',
                            related_object_id=cert.id,
                            related_object_type='CERTIFICATE',
                        )
            except Exception:
                pass

            return Response(CourseCertificateSerializer(cert).data)
        except Exception as e:
            return Response({'error': f'Failed to fetch certificate: {str(e)}'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class PendingCertificateReviewsView(APIView):
    """Specialist or Admin lists all certificates for review."""
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        status_filter = request.query_params.get('status', None)
        user = request.user
        certs = CourseCertificate.objects.all().order_by('-issued_at')

        if status_filter:
            certs = certs.filter(recommendation_status=status_filter)

        # If logged in user is specialist, show certificates for their courses or assigned specialist
        if getattr(user, 'role', '') in ['SPECIALIST', 'DOCTOR']:
            from django.db.models import Q
            certs = certs.filter(Q(course__instructor=user) | Q(specialist=user))

        return Response(CourseCertificateSerializer(certs.distinct(), many=True).data)


class SubmitCertificateRecommendationView(APIView):
    """Specialist or Admin submits recommendation/review for a patient's certificate."""
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, cert_id):
        try:
            cert = CourseCertificate.objects.get(id=cert_id)
        except CourseCertificate.DoesNotExist:
            return Response({'error': 'Certificate not found'}, status=status.HTTP_404_NOT_FOUND)

        recommendation = request.data.get('recommendation', '').strip()
        ranking = request.data.get('performance_ranking', 'Outstanding')

        if not recommendation:
            return Response({'error': 'Recommendation text cannot be empty'}, status=status.HTTP_400_BAD_REQUEST)

        cert.specialist_recommendation = recommendation
        cert.recommendation_status = 'submitted'
        cert.recommendation_submitted_at = timezone.now()
        cert.performance_ranking = ranking
        cert.specialist = request.user
        cert.save()

        # Send Notification to Patient
        try:
            spec_name = request.user.get_full_name() or request.user.username or "Specialist"
            send_notification(
                recipient=cert.patient,
                sender=request.user,
                title_en=f"Specialist Certificate Review Added! 🎓",
                title_bn=f"সার্টিফিকেট রিভিউ যুক্ত করা হয়েছে! 🎓",
                message_en=f"{spec_name} has added a performance recommendation to your Course Certificate for '{cert.course.title_en}'. View your updated certificate now!",
                message_bn=f"{spec_name} আপনার '{cert.course.title_bn}' কোর্সের সার্টিফিকেটে মূল্যায়ন প্রদান করেছেন। আপনার সার্টিফিকেটটি এখনই দেখুন!",
                category='COURSE',
                related_object_id=cert.id,
                related_object_type='CERTIFICATE',
            )
        except Exception:
            pass

        return Response(CourseCertificateSerializer(cert).data)
