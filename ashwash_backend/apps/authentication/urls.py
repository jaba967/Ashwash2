from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView
from .views import (
    RegisterView, CustomTokenObtainPairView, SocialGoogleAuthView,
    ProfileView, CategoryListView, SelectCategoryView, UpdatePreferencesView,
    ChangePasswordView, PrivacySettingsView
)

urlpatterns = [
    path('register/', RegisterView.as_view(), name='register'),
    path('login/', CustomTokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('google/', SocialGoogleAuthView.as_view(), name='social_google_auth'),
    path('refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('profile/', ProfileView.as_view(), name='profile'),
    path('categories/', CategoryListView.as_view(), name='categories'),
    path('select-category/', SelectCategoryView.as_view(), name='select_category'),
    path('preferences/', UpdatePreferencesView.as_view(), name='update_preferences'),
    path('change-password/', ChangePasswordView.as_view(), name='change_password'),
    path('privacy-settings/', PrivacySettingsView.as_view(), name='privacy_settings'),
]
