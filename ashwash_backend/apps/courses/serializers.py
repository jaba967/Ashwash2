from rest_framework import serializers
from .models import Course, Module, Lesson, Assignment, UserCourseProgress, UserLessonProgress, HomeworkQuestion, HomeworkSubmission, HomeworkAnswer

class AssignmentSerializer(serializers.ModelSerializer):
    class Meta:
        model = Assignment
        fields = ['id', 'instruction_en', 'instruction_bn']

class HomeworkQuestionSerializer(serializers.ModelSerializer):
    class Meta:
        model = HomeworkQuestion
        fields = ['id', 'question_text', 'answer_type', 'options', 'is_required', 'order']

class HomeworkAnswerSerializer(serializers.ModelSerializer):
    question_id = serializers.IntegerField(source='question.id', read_only=True)
    question_text = serializers.CharField(source='question.question_text', read_only=True)
    class Meta:
        model = HomeworkAnswer
        fields = ['id', 'question_id', 'question_text', 'answer_text']

class HomeworkSubmissionSerializer(serializers.ModelSerializer):
    answers = HomeworkAnswerSerializer(many=True, read_only=True)
    patient_name = serializers.CharField(source='patient.get_full_name', read_only=True)
    course_name = serializers.CharField(source='course.title_en', read_only=True)
    lesson_name = serializers.CharField(source='lesson.title_en', read_only=True)

    class Meta:
        model = HomeworkSubmission
        fields = ['id', 'status', 'specialist_feedback', 'submitted_at', 'reviewed_at', 'answers', 'patient_name', 'course_name', 'lesson_name', 'patient_id', 'course_id', 'lesson_id']

class LessonSerializer(serializers.ModelSerializer):
    assignments = AssignmentSerializer(many=True, read_only=True)
    homework_questions = HomeworkQuestionSerializer(many=True, read_only=True)
    type = serializers.SerializerMethodField()
    file = serializers.SerializerMethodField()

    class Meta:
        model = Lesson
        fields = ['id', 'title_en', 'title_bn', 'content_en', 'content_bn', 'video_url', 'file', 'type', 'duration_minutes', 'order', 'assignments', 'homework_questions']

    def get_type(self, obj):
        if obj.content_en and obj.content_en.lower() in ['video', 'audio', 'pdf', 'article', 'task']:
            return obj.content_en.lower()
        if obj.video_url:
            url_lower = obj.video_url.lower()
            if '.mp3' in url_lower or 'audio' in url_lower:
                return 'audio'
            if '.pdf' in url_lower or 'pdf' in url_lower:
                return 'pdf'
        if obj.assignments.exists() or obj.homework_questions.exists():
            return 'task'
        return 'video'

    def get_file(self, obj):
        return obj.video_url

class ModuleSerializer(serializers.ModelSerializer):
    lessons = LessonSerializer(many=True, read_only=True)

    class Meta:
        model = Module
        fields = ['id', 'title_en', 'title_bn', 'order', 'lessons']

class CourseSerializer(serializers.ModelSerializer):
    modules = ModuleSerializer(many=True, read_only=True)
    category_name = serializers.CharField(source='category.title_en', read_only=True, allow_null=True)
    instructor_id = serializers.IntegerField(source='instructor.id', read_only=True, allow_null=True)
    instructor_details = serializers.SerializerMethodField()
    enrolled_count = serializers.IntegerField(read_only=True)
    average_rating = serializers.FloatField(read_only=True)

    class Meta:
        model = Course
        fields = [
            'id', 'instructor', 'instructor_id', 'instructor_details',
            'category', 'category_name', 'title_en', 'title_bn', 'subtitle_en', 'subtitle_bn',
            'description_en', 'description_bn', 'duration_weeks', 'total_tasks',
            'type_label', 'price', 'is_free', 'rating', 'average_rating', 'enrolled_count', 'thumbnail_url', 'media_url', 'media_file', 'is_approved', 'created_at', 'updated_at', 'modules'
        ]

    def get_instructor_details(self, obj):
        if not obj.instructor:
            return None
        user = obj.instructor
        full_name = f"{user.first_name} {user.last_name}".strip() or user.username

        qual = "Mental Health Specialist"
        spec_title = "Clinical Psychologist"
        avatar = ""

        try:
            profile = getattr(user, 'specialist_profile', None)
            if profile:
                qual = getattr(profile, 'qualification', '') or qual
                spec_title = getattr(profile, 'specialization', '') or spec_title
                avatar = getattr(profile, 'avatar_url', '') or avatar
        except Exception:
            pass

        try:
            from apps.appointments.models import Specialist
            spec_obj = None
            if user.first_name:
                spec_obj = Specialist.objects.filter(name__icontains=user.first_name).first()
            if not spec_obj and user.username:
                spec_obj = Specialist.objects.filter(name__icontains=user.username).first()
            if spec_obj:
                if not avatar and spec_obj.avatar_url:
                    avatar = spec_obj.avatar_url
                qual = spec_obj.degree or qual
                spec_title = spec_obj.title_en or spec_title
        except Exception:
            spec_obj = None

        if not avatar or 'doctime.com' in avatar:
            name_lower = full_name.lower()
            if 'nihal' in name_lower or 'sarkar' in name_lower:
                avatar = 'https://images.unsplash.com/photo-1622253692010-333f2da6031d?w=200&auto=format&fit=crop&q=80'
            else:
                avatar = 'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?w=200&auto=format&fit=crop&q=80'

        return {
            'id': user.id,
            'name': full_name,
            'avatar_url': avatar,
            'qualification': qual,
            'specialization': spec_title,
            'experience_years': getattr(spec_obj, 'experience_years', 5) if spec_obj else 5,
            'rating': float(getattr(spec_obj, 'rating', 4.9)) if spec_obj else 4.9,
        }

class UserCourseProgressSerializer(serializers.ModelSerializer):
    course_title_en = serializers.CharField(source='course.title_en', read_only=True)
    course_title_bn = serializers.CharField(source='course.title_bn', read_only=True)
    course = CourseSerializer(read_only=True)

    class Meta:
        model = UserCourseProgress
        fields = [
            'id', 'course', 'course_title_en', 'course_title_bn',
            'completed_lessons_count', 'total_lessons_count', 'progress_percentage',
            'is_completed', 'updated_at'
        ]

from .models import CourseCertificate

class CourseCertificateSerializer(serializers.ModelSerializer):
    patient_name = serializers.SerializerMethodField()
    patient_email = serializers.SerializerMethodField()
    patient_phone = serializers.SerializerMethodField()
    course_title_en = serializers.SerializerMethodField()
    course_title_bn = serializers.SerializerMethodField()
    specialist_name = serializers.SerializerMethodField()
    specialist_title = serializers.SerializerMethodField()
    specialist_qualification = serializers.SerializerMethodField()
    specialist_clinic = serializers.SerializerMethodField()

    class Meta:
        model = CourseCertificate
        fields = [
            'id', 'certificate_id', 'course', 'course_title_en', 'course_title_bn',
            'patient', 'patient_name', 'patient_email', 'patient_phone',
            'specialist', 'specialist_name', 'specialist_title', 'specialist_qualification', 'specialist_clinic',
            'specialist_recommendation', 'recommendation_status', 'recommendation_submitted_at',
            'performance_ranking', 'overall_progress', 'issued_at'
        ]

    def get_course_title_en(self, obj):
        if not obj.course:
            return "Course Completion Certificate"
        return obj.course.title_en or obj.course.title_bn or "Course Completion Certificate"

    def get_course_title_bn(self, obj):
        if not obj.course:
            return "কোর্স সমাপ্তির সনদপত্র"
        return obj.course.title_bn or obj.course.title_en or "কোর্স সমাপ্তির সনদপত্র"

    def get_patient_email(self, obj):
        return getattr(obj.patient, 'email', '') or ""

    def get_patient_name(self, obj):
        if not obj.patient:
            return "Valued Patient"
        full_name = f"{getattr(obj.patient, 'first_name', '')} {getattr(obj.patient, 'last_name', '')}".strip()
        return full_name or getattr(obj.patient, 'username', 'Valued Patient')

    def get_patient_phone(self, obj):
        if not obj.patient:
            return ""
        return getattr(obj.patient, 'phone_number', '') or ""

    def get_specialist_name(self, obj):
        if obj.specialist:
            full_name = f"{getattr(obj.specialist, 'first_name', '')} {getattr(obj.specialist, 'last_name', '')}".strip()
            if full_name:
                return full_name
            return getattr(obj.specialist, 'username', 'Dr. Jaba Acharjee')
        if obj.course and obj.course.instructor:
            user = obj.course.instructor
            full_name = f"{getattr(user, 'first_name', '')} {getattr(user, 'last_name', '')}".strip()
            if full_name:
                return full_name
            return getattr(user, 'username', 'Dr. Jaba Acharjee')
        return "Dr. Jaba Acharjee"

    def get_specialist_title(self, obj):
        return "Senior Clinical Psychologist & Mental Wellness Expert"

    def get_specialist_qualification(self, obj):
        return "MSc in Clinical Psychology, BSMMU"

    def get_specialist_clinic(self, obj):
        return "Ashwash Mental Wellness Center, Dhaka"
