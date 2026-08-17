from django.urls import path
from .views import ResourceListView, ResourceDetailView

urlpatterns = [
    path('resources/', ResourceListView.as_view(), name='resources_list'),
    path('resources/<int:pk>/', ResourceDetailView.as_view(), name='resource_detail'),
]
