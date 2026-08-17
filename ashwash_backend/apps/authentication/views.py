from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.views import TokenObtainPairView
from rest_framework_simplejwt.tokens import RefreshToken
from django.contrib.auth import get_user_model
import uuid
from .models import Category
from .serializers import (
    UserRegisterSerializer, UserSerializer, CategorySerializer, CustomTokenObtainPairSerializer
)

User = get_user_model()

class CustomTokenObtainPairView(TokenObtainPairView):
    serializer_class = CustomTokenObtainPairSerializer

class RegisterView(generics.CreateAPIView):
    queryset = User.objects.all()
    permission_classes = (permissions.AllowAny,)
    serializer_class = UserRegisterSerializer

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()

        refresh = RefreshToken.for_user(user)
        return Response({
            'refresh': str(refresh),
            'access': str(refresh.access_token),
            'is_new_user': True,
            'user': UserSerializer(user).data
        }, status=status.HTTP_201_CREATED)

class SocialGoogleAuthView(APIView):
    permission_classes = (permissions.AllowAny,)

    def post(self, request):
        email = request.data.get('email')
        name = request.data.get('name', 'Google User')
        profile_picture = request.data.get('profile_picture', '')

        if not email:
            return Response({'detail': 'Email is required for Google Sign-In'}, status=status.HTTP_400_BAD_REQUEST)

        user = User.objects.filter(email__iexact=email).first()
        is_new_user = False
        if not user:
            is_new_user = True
            name_parts = name.split(' ', 1)
            first_name = name_parts[0] if name_parts else 'Google'
            last_name = name_parts[1] if len(name_parts) > 1 else 'User'
            username = f"google_{uuid.uuid4().hex[:8]}"

            user = User.objects.create_user(
                username=username,
                email=email,
                password=uuid.uuid4().hex,
                first_name=first_name,
                last_name=last_name,
                role=User.Role.PATIENT,
                profile_picture=profile_picture
            )

        refresh = RefreshToken.for_user(user)
        return Response({
            'refresh': str(refresh),
            'access': str(refresh.access_token),
            'is_new_user': is_new_user,
            'user': UserSerializer(user).data
        }, status=status.HTTP_200_OK)

class ProfileView(generics.RetrieveUpdateAPIView):
    permission_classes = (permissions.IsAuthenticated,)
    serializer_class = UserSerializer

    def get_object(self):
        return self.request.user

    def update(self, request, *args, **kwargs):
        user = self.request.user
        username = request.data.get('username')
        profile_picture = request.data.get('profile_picture') or request.data.get('profile_picture_base64')

        if username and username.strip() != user.username:
            new_username = username.strip()
            if User.objects.filter(username__iexact=new_username).exclude(id=user.id).exists():
                return Response({'detail': 'This username is already taken.'}, status=status.HTTP_400_BAD_REQUEST)
            user.username = new_username

        if profile_picture:
            if not (isinstance(profile_picture, str) and profile_picture.startswith('data:image')):
                try:
                    user.profile_picture = profile_picture
                except Exception:
                    pass
            preferences = user.preferences or {}
            preferences['profile_picture_base64'] = profile_picture
            user.preferences = preferences

        user.save()
        serializer = self.get_serializer(user)
        return Response(serializer.data, status=status.HTTP_200_OK)

class CategoryListView(generics.ListAPIView):
    queryset = Category.objects.all()
    permission_classes = (permissions.AllowAny,)
    serializer_class = CategorySerializer

class SelectCategoryView(APIView):
    permission_classes = (permissions.IsAuthenticated,)

    def post(self, request):
        category_ids = request.data.get('category_ids', [])
        if isinstance(category_ids, (str, int)):
            category_ids = [category_ids]

        user = request.user
        if hasattr(user, 'selected_categories'):
            try:
                user.selected_categories.set(category_ids)
            except Exception:
                pass
        user.save()
        return Response({'status': 'Categories updated successfully', 'selected_categories': category_ids}, status=status.HTTP_200_OK)

class UpdatePreferencesView(APIView):
    permission_classes = (permissions.IsAuthenticated,)

    def post(self, request):
        preferences = request.data.get('preferences', {})
        user = request.user
        user.preferences = preferences
        user.save()
        return Response({'status': 'Preferences updated successfully'}, status=status.HTTP_200_OK)

class ChangePasswordView(APIView):
    permission_classes = (permissions.IsAuthenticated,)

    def post(self, request):
        user = request.user
        old_password = request.data.get('old_password', '')
        new_password = request.data.get('new_password', '')
        confirm_password = request.data.get('confirm_password', '')

        if not old_password or not new_password:
            return Response({'detail': 'Both old password and new password are required.'}, status=status.HTTP_400_BAD_REQUEST)

        if not user.check_password(old_password):
            return Response({'detail': 'Incorrect current password.'}, status=status.HTTP_400_BAD_REQUEST)

        if len(new_password) < 6:
            return Response({'detail': 'New password must be at least 6 characters long.'}, status=status.HTTP_400_BAD_REQUEST)

        if confirm_password and new_password != confirm_password:
            return Response({'detail': 'New passwords do not match.'}, status=status.HTTP_400_BAD_REQUEST)

        user.set_password(new_password)
        user.save()
        return Response({'detail': 'Password changed successfully.'}, status=status.HTTP_200_OK)

class PrivacySettingsView(APIView):
    permission_classes = (permissions.IsAuthenticated,)

    def get(self, request):
        user = request.user
        preferences = user.preferences or {}
        privacy = preferences.get('privacy', {
            'allow_anonymous_posts': True,
            'share_progress_analytics': True,
            'data_usage_consent': True
        })
        return Response(privacy, status=status.HTTP_200_OK)

    def post(self, request):
        user = request.user
        privacy_data = request.data.get('privacy', request.data)
        preferences = user.preferences or {}
        preferences['privacy'] = {
            'allow_anonymous_posts': privacy_data.get('allow_anonymous_posts', True),
            'share_progress_analytics': privacy_data.get('share_progress_analytics', True),
            'data_usage_consent': privacy_data.get('data_usage_consent', True)
        }
        user.preferences = preferences
        user.save()
        return Response({'detail': 'Privacy settings updated successfully.', 'privacy': preferences['privacy']}, status=status.HTTP_200_OK)