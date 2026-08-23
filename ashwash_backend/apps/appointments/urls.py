from django.urls import path
from .views import SpecialistListView, SpecialistDetailView, AppointmentListCreateView, AppointmentDetailView, BookedSlotsView

urlpatterns = [
    path('specialists/', SpecialistListView.as_view(), name='specialists_list'),
    path('specialists/<int:pk>/', SpecialistDetailView.as_view(), name='specialist_detail'),
    path('bookings/', AppointmentListCreateView.as_view(), name='appointment_bookings'),
    path('bookings/<int:pk>/', AppointmentDetailView.as_view(), name='appointment_detail'),
    path('booked-slots/', BookedSlotsView.as_view(), name='booked_slots'),
]
