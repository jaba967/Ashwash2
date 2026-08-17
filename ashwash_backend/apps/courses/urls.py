from django.urls import path
from .views import (
    CourseListView, CourseDetailView, CompleteLessonView, UserEnrolledCoursesView, EnrollCourseView,
    SubmitHomeworkView, PatientHomeworkView, SpecialistHomeworkSubmissionsView, SpecialistReviewHomeworkView,
    SubmitCourseReviewView, PatientSubmissionDetailView, CourseCertificateView, PendingCertificateReviewsView,
    SubmitCertificateRecommendationView
)

urlpatterns = [
    path('', CourseListView.as_view(), name='courses_list'),
    path('<int:pk>/', CourseDetailView.as_view(), name='course_detail'),
    path('<int:course_id>/enroll/', EnrollCourseView.as_view(), name='enroll_course'),
    path('lessons/<int:lesson_id>/complete/', CompleteLessonView.as_view(), name='complete_lesson'),
    path('enrolled/', UserEnrolledCoursesView.as_view(), name='enrolled_courses'),
    path('homework/submit/', SubmitHomeworkView.as_view(), name='submit_homework'),
    path('homework/mine/', PatientHomeworkView.as_view(), name='patient_homework'),
    path('homework/submissions/', SpecialistHomeworkSubmissionsView.as_view(), name='specialist_submissions'),
    path('homework/submissions/<int:pk>/review/', SpecialistReviewHomeworkView.as_view(), name='review_homework'),
    path('homework/submissions/<int:pk>/detail/', PatientSubmissionDetailView.as_view(), name='patient_submission_detail'),
    path('<int:course_id>/review/', SubmitCourseReviewView.as_view(), name='submit_course_review'),
    path('<int:course_id>/certificate/', CourseCertificateView.as_view(), name='course_certificate'),
    path('certificates/pending/', PendingCertificateReviewsView.as_view(), name='pending_certificates'),
    path('certificates/<int:cert_id>/recommendation/', SubmitCertificateRecommendationView.as_view(), name='submit_certificate_recommendation'),
]

