from django.urls import path
from .views import DashboardSummaryView, PatientHealthReportDataView
from .specialist_views import SpecialistDashboardSummaryView
from apps.dashboard.web_views import (
    AdminMetricsAPIView, AdminVerifySpecialistAPIView, AdminRejectSpecialistAPIView,
    AdminToggleUserStatusAPIView, AdminSpecialistsListAPIView, AdminUsersListAPIView,
    AdminUpdateProfileAPIView, SpecialistUpdateProfileAPIView, AdminApproveCourseAPIView,
    AdminPaymentsListAPIView
)

urlpatterns = [
    path('summary/', DashboardSummaryView.as_view(), name='dashboard_summary'),
    path('overview/', DashboardSummaryView.as_view(), name='dashboard_overview'),
    path('specialist-summary/', SpecialistDashboardSummaryView.as_view(), name='specialist_dashboard_summary'),
    path('admin-metrics/', AdminMetricsAPIView.as_view(), name='admin_metrics_api'),
    path('admin-specialists/', AdminSpecialistsListAPIView.as_view(), name='admin_specialists_api'),
    path('admin-users/', AdminUsersListAPIView.as_view(), name='admin_users_api'),
    path('admin-payments/', AdminPaymentsListAPIView.as_view(), name='admin_payments_api'),
    path('admin-update-profile/', AdminUpdateProfileAPIView.as_view(), name='admin_update_profile_api'),
    path('specialist-update-profile/', SpecialistUpdateProfileAPIView.as_view(), name='specialist_update_profile_api'),
    path('admin-verify-specialist/<int:pk>/', AdminVerifySpecialistAPIView.as_view(), name='admin_verify_specialist_api'),
    path('admin-reject-specialist/<int:pk>/', AdminRejectSpecialistAPIView.as_view(), name='admin_reject_specialist_api'),
    path('admin-approve-course/<int:pk>/', AdminApproveCourseAPIView.as_view(), name='admin_approve_course_api'),
    path('admin-toggle-user/<int:pk>/', AdminToggleUserStatusAPIView.as_view(), name='admin_toggle_user_api'),
    path('patient-health-report/', PatientHealthReportDataView.as_view(), name='patient_health_report_api'),
]
