from django.urls import path
from . import views

urlpatterns = [
    path('', views.NotificationListView.as_view(), name='notification-list'),
    path('unread/', views.UnreadNotificationListView.as_view(), name='notification-unread-list'),
    path('count/', views.NotificationCountView.as_view(), name='notification-count'),
    path('<int:pk>/read/', views.MarkNotificationReadView.as_view(), name='notification-mark-read'),
    path('read-all/', views.MarkAllNotificationsReadView.as_view(), name='notification-mark-all-read'),
    path('mark-all-read/', views.MarkAllNotificationsReadView.as_view(), name='notification-mark-all-read-alias'),
    path('<int:pk>/', views.DeleteNotificationView.as_view(), name='notification-delete'),
    path('<int:pk>/delete/', views.DeleteNotificationView.as_view(), name='notification-delete-alias'),
    path('delete-all/', views.DeleteAllNotificationsView.as_view(), name='notification-delete-all'),
    path('clear-all/', views.DeleteAllNotificationsView.as_view(), name='notification-clear-all-alias'),
    path('register-device/', views.RegisterFCMDeviceView.as_view(), name='register-fcm-device'),
    path('send-meeting-link/', views.SendMeetingLinkView.as_view(), name='send-meeting-link'),
]
