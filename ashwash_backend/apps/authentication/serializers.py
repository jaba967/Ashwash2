from rest_framework import serializers
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from django.contrib.auth import get_user_model
from django.db.models import Q
from .models import Category, SpecialistProfile, PatientProfile

User = get_user_model()

class CategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = Category
        fields = '__all__'

class SpecialistProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = SpecialistProfile
        fields = '__all__'
        read_only_fields = ('user', 'created_at', 'updated_at')

class CustomTokenObtainPairSerializer(TokenObtainPairSerializer):
    role = serializers.CharField(required=False, allow_blank=True)

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.fields['username'] = serializers.CharField(required=False, allow_blank=True)
        self.fields['email'] = serializers.CharField(required=False, allow_blank=True)
        self.fields['role'] = serializers.CharField(required=False, allow_blank=True)

    def validate(self, attrs):
        username_or_email = attrs.get('username') or attrs.get('email')
        password = attrs.get('password')
        expected_role = attrs.get('role', '').upper()

        if not username_or_email or not password:
            raise serializers.ValidationError({"detail": "Please provide email/username and password."})

        user = User.objects.filter(
            Q(username__iexact=username_or_email) | Q(email__iexact=username_or_email)
        ).first()

        if user:
            if not user.check_password(password):
                raise serializers.ValidationError({"detail": "Incorrect password."})
            if not user.is_active:
                raise serializers.ValidationError({"detail": "User account is disabled."})
            
            # Role validation if specified
            if expected_role:
                if expected_role in ['SPECIALIST', 'DOCTOR'] and user.role not in [User.Role.SPECIALIST, User.Role.DOCTOR]:
                    raise serializers.ValidationError({"detail": "Access Denied: This account is registered as a Patient."})
                elif expected_role == 'PATIENT' and user.role not in [User.Role.PATIENT]:
                    raise serializers.ValidationError({"detail": "Access Denied: This account is registered as a Specialist."})

            # Check pending approval for specialist accounts
            if user.role in [User.Role.SPECIALIST, User.Role.DOCTOR] and not (user.is_staff or user.is_superuser):
                sp = SpecialistProfile.objects.filter(user=user).first()
                if sp and not sp.is_profile_complete:
                    raise serializers.ValidationError({"detail": "Your Specialist Application is PENDING review and approval by the Administrator. Access will be granted once an Admin approves your account."})

            refresh = self.get_token(user)
            user_data = UserSerializer(user).data

            # Attach specialist profile data if user is specialist
            if user.role in [User.Role.SPECIALIST, User.Role.DOCTOR]:
                sp, _ = SpecialistProfile.objects.get_or_create(
                    user=user,
                    defaults={
                        'full_name': f"{user.first_name} {user.last_name}".strip() or user.username,
                        'email': user.email,
                        'phone_number': user.phone_number or '',
                    }
                )
                user_data['specialist_profile'] = SpecialistProfileSerializer(sp).data

            return {
                'refresh': str(refresh),
                'access': str(refresh.access_token),
                'user': user_data
            }
        else:
            raise serializers.ValidationError({"detail": "User not found."})

class UserRegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True)
    first_name = serializers.CharField(required=False, allow_blank=True, default='')
    last_name = serializers.CharField(required=False, allow_blank=True, default='')

    class Meta:
        model = User
        fields = ('id', 'username', 'email', 'password', 'role', 'phone_number', 'first_name', 'last_name')
        extra_kwargs = {'username': {'required': True}}

    def validate(self, attrs):
        email = attrs.get('email', '').strip()
        username = attrs.get('username', '').strip()

        if User.objects.filter(username__iexact=username).exists():
            raise serializers.ValidationError({"detail": "This username is already taken."})
        if User.objects.filter(email__iexact=email).exists():
            raise serializers.ValidationError({"detail": "An account with this email already exists."})
        return attrs

    def create(self, validated_data):
        role_val = validated_data.get('role', User.Role.PATIENT)
        if role_val in ['SPECIALIST', 'DOCTOR', 'Psychologist', 'Specialist']:
            role_val = User.Role.SPECIALIST

        user = User.objects.create_user(
            username=validated_data['username'],
            email=validated_data.get('email', ''),
            password=validated_data['password'],
            role=role_val,
            phone_number=validated_data.get('phone_number', ''),
            first_name=validated_data.get('first_name', ''),
            last_name=validated_data.get('last_name', '')
        )

        if role_val == User.Role.SPECIALIST:
            full_n = f"{user.first_name} {user.last_name}".strip() or user.username
            SpecialistProfile.objects.get_or_create(
                user=user,
                defaults={
                    'full_name': full_n,
                    'email': user.email,
                    'phone_number': user.phone_number or '',
                }
            )
            from apps.appointments.models import Specialist
            Specialist.objects.get_or_create(
                name=full_n,
                defaults={
                    'title_en': 'Clinical Psychologist',
                    'title_bn': 'ক্লিনিক্যাল সাইকোলজিস্ট',
                    'bio_en': f'{full_n} is a registered mental health specialist on Ashwash.',
                    'bio_bn': f'{full_n} আশ্বাস প্ল্যাটফর্মের একজন নিবন্ধিত মানসিক স্বাস্থ্য বিশেষজ্ঞ।',
                    'experience_years': 5,
                    'rating': 5.0,
                    'fee_bdt': 1000,
                    'location_type': 'local',
                    'is_available': True,
                    'is_online': True,
                }
            )
        else:
            full_n = f"{user.first_name} {user.last_name}".strip() or user.username
            PatientProfile.objects.get_or_create(
                user=user,
                defaults={
                    'full_name': full_n,
                    'email': user.email,
                    'phone_number': user.phone_number or '',
                }
            )

        return user

class UserSerializer(serializers.ModelSerializer):
    selected_categories = CategorySerializer(many=True, read_only=True)
    specialist_profile = serializers.SerializerMethodField(read_only=True, required=False)
    profile_picture = serializers.SerializerMethodField(read_only=True, required=False)

    class Meta:
        model = User
        fields = ('id', 'username', 'email', 'first_name', 'last_name', 'role', 'phone_number', 'profile_picture', 'selected_categories', 'preferences', 'specialist_profile')

    def get_profile_picture(self, obj):
        if obj.profile_picture:
            try:
                return obj.profile_picture.url
            except Exception:
                pass
        if isinstance(obj.preferences, dict) and obj.preferences.get('profile_picture_base64'):
            return obj.preferences['profile_picture_base64']
        return None

    def get_specialist_profile(self, obj):
        if hasattr(obj, 'specialist_profile'):
            return SpecialistProfileSerializer(obj.specialist_profile).data
        return None