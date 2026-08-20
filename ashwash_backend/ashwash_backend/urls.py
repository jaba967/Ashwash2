from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static
from django.views.generic import TemplateView

from apps.dashboard.web_views import (
    specialist_login_view, specialist_register_view, specialist_portal_view,
    admin_login_view, admin_portal_view, web_logout_view,
    WebSpecialistRegisterAPIView
)

urlpatterns = [
    path('admin/', admin.site.urls),
    path('specialist/login/', specialist_login_view, name='specialist_login'),
    path('specialist/register/', specialist_register_view, name='specialist_register'),
    path('specialist/', specialist_portal_view, name='specialist_portal'),
    path('admin-portal/login/', admin_login_view, name='admin_login'),
    path('admin-portal/', admin_portal_view, name='admin_portal'),
    path('web-logout/', web_logout_view, name='web_logout'),
    path('api/auth/specialist-register/', WebSpecialistRegisterAPIView.as_view(), name='api_specialist_register'),
    path('firebase-messaging-sw.js', TemplateView.as_view(template_name="firebase-messaging-sw.js", content_type='application/javascript')),

    path('api/auth/', include('apps.authentication.urls')),
    path('api/assessment/', include('apps.assessment.urls')),
    path('api/knowledge/', include('apps.knowledge_hub.urls')),
    path('api/courses/', include('apps.courses.urls')),
    path('api/appointments/', include('apps.appointments.urls')),
    path('api/community/', include('apps.community.urls')),
    path('api/payments/', include('apps.payments.urls')),
    path('api/dashboard/', include('apps.dashboard.urls')),
    path('api/notifications/', include('apps.notifications.urls')),
]

urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
