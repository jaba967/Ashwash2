from django.shortcuts import render, redirect
from django.contrib.auth import authenticate, login, logout, get_user_model
from django.contrib.auth.decorators import login_required
from django.http import JsonResponse
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import permissions, status
from apps.authentication.models import SpecialistProfile
from apps.courses.models import Course, Lesson, UserCourseProgress
from apps.appointments.models import Appointment
from apps.community.models import Post, Comment, Report
from apps.payments.models import PaymentTransaction

User = get_user_model()

def specialist_login_view(request):
    if request.user.is_authenticated:
        if request.user.role in ['SPECIALIST', 'DOCTOR'] or request.user.is_staff:
            return redirect('specialist_portal')
    error = None
    if request.method == 'POST':
        u = request.POST.get('username', '').strip()
        p = request.POST.get('password', '').strip()
        user = authenticate(request, username=u, password=p)
        if not user:
            user = User.objects.filter(email__iexact=u).first()
            if user and user.check_password(p):
                pass
            else:
                user = None

        if user:
            if user.role in ['SPECIALIST', 'DOCTOR'] or user.is_staff or user.is_superuser:
                # Check pending approval status for specialists
                if user.role in ['SPECIALIST', 'DOCTOR'] and not (user.is_staff or user.is_superuser):
                    spec_profile = SpecialistProfile.objects.filter(user=user).first()
                    if spec_profile and not spec_profile.is_profile_complete:
                        error = 'Your Specialist Application is currently PENDING review and approval by the Administrator. Access will be granted once an Admin approves your account.'
                        return render(request, 'specialist/specialist_login.html', {'error': error})

                login(request, user)
                return redirect('specialist_portal')
            else:
                error = 'Access Denied: Account is not registered as a Specialist or Doctor.'
        else:
            error = 'Invalid username or password.'

    return render(request, 'specialist/specialist_login.html', {'error': error})

def specialist_register_view(request):
    success_msg = None
    error = None
    if request.method == 'POST':
        u = request.POST.get('username', '').strip()
        e = request.POST.get('email', '').strip()
        p = request.POST.get('password', '').strip()
        fn = request.POST.get('first_name', '').strip()
        ln = request.POST.get('last_name', '').strip()
        spec = request.POST.get('specialization', 'Clinical Psychologist').strip()
        lic = request.POST.get('medical_license_number', 'BMDC-PENDING').strip()
        qual = request.POST.get('qualification', 'MSc in Clinical Psychology').strip()

        if User.objects.filter(username__iexact=u).exists():
            error = 'Username already taken. Please choose another.'
        else:
            user = User.objects.create_user(
                username=u,
                email=e,
                password=p,
                first_name=fn,
                last_name=ln,
                role=User.Role.SPECIALIST
            )
            SpecialistProfile.objects.create(
                user=user,
                full_name=f"{fn} {ln}".strip() or u,
                email=e,
                specialization=spec,
                medical_license_number=lic,
                qualification=qual,
                is_profile_complete=False # PENDING APPROVAL!
            )
            success_msg = 'Specialist Application submitted successfully! Your account is pending Administrator review and approval.'

    return render(request, 'specialist/specialist_register.html', {'success_msg': success_msg, 'error': error})

@login_required(login_url='specialist_login')
def specialist_portal_view(request):
    if not (request.user.role in ['SPECIALIST', 'DOCTOR'] or request.user.is_staff or request.user.is_superuser):
        return redirect('specialist_login')
    
    spec_profile, _ = SpecialistProfile.objects.get_or_create(
        user=request.user,
        defaults={
            'full_name': request.user.full_name if hasattr(request.user, 'full_name') and request.user.full_name else f"Dr. {request.user.username}",
            'email': request.user.email or f"{request.user.username}@ashwash.com",
            'phone_number': getattr(request.user, 'phone_number', '01700000000') or '01700000000',
            'specialization': 'Clinical Psychologist',
            'qualification': 'MSc in Clinical Psychology',
        }
    )

    my_courses = Course.objects.filter(instructor=request.user)
    my_appointments = Appointment.objects.filter(specialist__name__icontains=request.user.first_name) if request.user.first_name else Appointment.objects.all()[:10]
    recent_posts = Post.objects.all().order_by('-created_at')[:10]

    context = {
        'spec_profile': spec_profile,
        'my_courses': my_courses,
        'my_appointments': my_appointments,
        'recent_posts': recent_posts,
        'total_courses': my_courses.count(),
        'total_appointments': my_appointments.count(),
    }
    return render(request, 'specialist/specialist_portal.html', context)

def admin_login_view(request):
    if request.user.is_authenticated and request.user.username == 'admin':
        return redirect('admin_portal')
    
    error = None
    if request.method == 'POST':
        u = request.POST.get('username', '').strip()
        p = request.POST.get('password', '').strip()
        
        user = authenticate(request, username=u, password=p)
        
        if user and user.username == 'admin':
            login(request, user)
            return redirect('admin_portal')
        else:
            error = 'Access Denied: Invalid admin credentials.'
            
    return render(request, 'admin/admin_login.html', {'error': error})

@login_required(login_url='admin_login')
def admin_portal_view(request):
    if request.user.username != 'admin':
        return redirect('admin_login')

    total_patients = User.objects.filter(role='PATIENT').count() or User.objects.filter(is_staff=False).count()
    total_specialists = SpecialistProfile.objects.count()
    total_courses = Course.objects.count()
    total_appointments = Appointment.objects.count()
    total_posts = Post.objects.count()

    specialists = SpecialistProfile.objects.select_related('user').all().order_by('id')
    all_users = User.objects.all().order_by('-date_joined')[:30]
    all_courses = Course.objects.all().order_by('-created_at')[:10]
    reports = Report.objects.select_related('post', 'user', 'post__author').all().order_by('-created_at')[:30]
    all_posts = Post.objects.select_related('author').all().order_by('-created_at')[:30]

    context = {
        'total_patients': total_patients,
        'total_specialists': total_specialists,
        'total_courses': total_courses,
        'total_appointments': total_appointments,
        'total_posts': total_posts,
        'total_reports': reports.count(),
        'specialists': specialists,
        'all_users': all_users,
        'all_courses': all_courses,
        'reports': reports,
        'all_posts': all_posts,
    }
    return render(request, 'admin/admin_portal.html', context)

def web_logout_view(request):
    logout(request)
    return redirect('specialist_login')

class AdminMetricsAPIView(APIView):
    permission_classes = [permissions.AllowAny]

    def get(self, request):
        from apps.payments.models import PaymentTransaction
        from django.db.models import Sum
        total_rev = PaymentTransaction.objects.filter(status='success').aggregate(Sum('amount'))['amount__sum'] or 0.00
        data = {
            'total_users': User.objects.count(),
            'total_patients': User.objects.filter(role='PATIENT').count(),
            'total_specialists': SpecialistProfile.objects.count(),
            'total_courses': Course.objects.count(),
            'total_appointments': Appointment.objects.count(),
            'total_posts': Post.objects.count(),
            'pending_verifications': SpecialistProfile.objects.filter(is_profile_complete=False).count(),
            'pending_courses': Course.objects.filter(is_approved=False).count(),
            'total_revenue': float(total_rev),
        }
        return Response(data)

class AdminPaymentsListAPIView(APIView):
    permission_classes = [permissions.AllowAny]

    def get(self, request):
        from apps.payments.models import PaymentTransaction
        txs = PaymentTransaction.objects.select_related('user').all().order_by('-created_at')
        data = []
        for t in txs:
            data.append({
                'id': t.id,
                'username': t.user.username if t.user else 'Patient',
                'email': t.user.email if t.user else '-',
                'method': t.method,
                'amount': float(t.amount),
                'purpose': t.purpose,
                'transaction_id': t.transaction_id,
                'status': t.status,
                'created_at': t.created_at.strftime('%Y-%m-%d %H:%M') if t.created_at else ''
            })
        return Response(data)

class AdminSpecialistsListAPIView(APIView):
    permission_classes = [permissions.AllowAny]

    def get(self, request):
        specialists = SpecialistProfile.objects.select_related('user').all().order_by('id')
        data = []
        for s in specialists:
            doc_name = s.full_name.strip() if s.full_name else ''
            if not doc_name and s.user:
                doc_name = s.user.get_full_name().strip() or s.user.username
            if not doc_name:
                doc_name = f"Dr. Specialist #{s.id}"
                
            # Filter out mock accounts requested by user
            if 'mekhala' in doc_name.lower() or 'admin' in doc_name.lower():
                continue

            pic_url = ''
            if s.user:
                if s.user.preferences and s.user.preferences.get('profile_picture_base64'):
                    pic_url = s.user.preferences.get('profile_picture_base64')
                elif s.user.profile_picture:
                    try:
                        pic_url = request.build_absolute_uri(s.user.profile_picture.url)
                    except Exception:
                        pic_url = str(s.user.profile_picture)
            if not pic_url:
                pic_url = 'https://corecdn.doctime.com.bd/persons/578875/profile_photos/Fe6ibomQLhBJuUQFq4cjQGkAnPeWDtUsO8AOMqIn.png'

            data.append({
                'id': s.id,
                'full_name': doc_name,
                'name': doc_name,
                'specialization': s.specialization or 'Counseling Specialist',
                'qualification': s.qualification or 'MSc in Clinical Psychology',
                'medical_license_number': s.medical_license_number or 'BMDC-REG-98234',
                'hospital_clinic': s.hospital_clinic or 'Ashwash Mental Wellness Center',
                'experience_years': s.experience_years or 5,
                'consultation_fee_bdt': s.consultation_fee_bdt or 1500,
                'fee_bdt': s.consultation_fee_bdt or 1500,
                'rating': float(s.rating) if s.rating else 4.9,
                'is_verified': s.is_profile_complete,
                'profile_picture': pic_url,
                'image_url': pic_url,
                'user_id': s.user.id if s.user else None,
                'user_username': s.user.username if s.user else '',
            })
        return Response(data)

class AdminVerifySpecialistAPIView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request, pk):
        try:
            profile = SpecialistProfile.objects.get(pk=pk)
            profile.is_profile_complete = True
            profile.save()

            if profile.user:
                profile.user.is_active = True
                profile.user.role = 'SPECIALIST'
                profile.user.save()
                
                from apps.notifications.services import NotificationManager
                NotificationManager.send_notification(
                    receiver=profile.user,
                    title="Specialist Profile Approved! 🎉",
                    body="Congratulations! Your specialist application has been verified and approved by the Administrator. You can now access all portal features.",
                    notif_type="PROFILE",
                    related_object_id=profile.id,
                    related_object_type="SpecialistProfile"
                )

            return Response({'message': f'Specialist {profile.full_name} verified & approved successfully!', 'is_verified': True})
        except SpecialistProfile.DoesNotExist:
            return Response({'error': 'Specialist profile not found'}, status=status.HTTP_404_NOT_FOUND)

class AdminRejectSpecialistAPIView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request, pk):
        try:
            profile = SpecialistProfile.objects.get(pk=pk)
            profile.is_profile_complete = False
            profile.save()

            if profile.user:
                from apps.notifications.services import NotificationManager
                NotificationManager.send_notification(
                    receiver=profile.user,
                    title="Specialist Application Update ⚠️",
                    body="Your specialist verification request could not be approved at this time. Please review your credentials or contact administrator.",
                    notif_type="PROFILE",
                    related_object_id=profile.id,
                    related_object_type="SpecialistProfile"
                )

            return Response({'message': f'Specialist {profile.full_name} application marked as rejected/pending.', 'is_verified': False})
        except SpecialistProfile.DoesNotExist:
            return Response({'error': 'Specialist profile not found'}, status=status.HTTP_404_NOT_FOUND)

class AdminToggleUserStatusAPIView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request, pk):
        try:
            user = User.objects.get(pk=pk)
            user.is_active = not user.is_active
            user.save()
            return Response({'message': f'User {user.username} is_active status set to {user.is_active}'})
        except User.DoesNotExist:
            return Response({'error': 'User not found'}, status=status.HTTP_404_NOT_FOUND)

class WebSpecialistRegisterAPIView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        u = request.data.get('username', '').strip()
        e = request.data.get('email', '').strip()
        p = request.data.get('password', '').strip()
        fn = request.data.get('first_name', '').strip()
        ln = request.data.get('last_name', '').strip()
        spec = request.data.get('specialization', 'Clinical Psychologist').strip()
        lic = request.data.get('medical_license_number', 'BMDC-PENDING').strip()
        qual = request.data.get('qualification', 'MSc in Clinical Psychology').strip()

        if not u or not p:
            return Response({'detail': 'Username and password are required.'}, status=status.HTTP_400_BAD_REQUEST)

        if User.objects.filter(username__iexact=u).exists():
            return Response({'detail': 'Username already taken.'}, status=status.HTTP_400_BAD_REQUEST)

        if lic and lic != 'BMDC-PENDING' and SpecialistProfile.objects.filter(medical_license_number__iexact=lic).exists():
            return Response({'detail': 'Medical license number already registered. Each specialist must have a unique license number.'}, status=status.HTTP_400_BAD_REQUEST)

        user = User.objects.create_user(
            username=u,
            email=e,
            password=p,
            first_name=fn,
            last_name=ln,
            role=User.Role.SPECIALIST
        )
        SpecialistProfile.objects.create(
            user=user,
            full_name=f"{fn} {ln}".strip() or u,
            email=e,
            specialization=spec,
            medical_license_number=lic,
            qualification=qual,
            is_profile_complete=False # PENDING APPROVAL!
        )
        return Response({'message': 'Specialist application submitted. Pending admin approval.'}, status=status.HTTP_201_CREATED)

class AdminUsersListAPIView(APIView):
    permission_classes = [permissions.AllowAny]

    def get(self, request):
        users = User.objects.all().order_by('-date_joined')
        data = []
        for u in users:
            if 'mekhala' in u.username.lower() or 'admin' in u.username.lower():
                continue
            data.append({
                'id': u.id,
                'username': u.username,
                'email': u.email or f"{u.username}@ashwash.com",
                'first_name': u.first_name,
                'last_name': u.last_name,
                'role': u.role,
                'is_active': u.is_active,
                'date_joined': u.date_joined.strftime('%Y-%m-%d %H:%M') if u.date_joined else 'Recently',
            })
        return Response(data)

class AdminUpdateProfileAPIView(APIView):
    permission_classes = [permissions.AllowAny]

    def get(self, request):
        token = request.headers.get('Authorization', '').replace('Bearer ', '').strip()
        user = None
        if request.user and request.user.is_authenticated:
            user = request.user
        elif token:
            try:
                from rest_framework_simplejwt.tokens import AccessToken
                validated_token = AccessToken(token)
                user_id = validated_token['user_id']
                user = User.objects.get(id=user_id)
            except Exception:
                pass

        if not user:
            user = User.objects.filter(role=User.Role.ADMIN).first() or User.objects.filter(is_superuser=True).first()

        if not user:
            return Response({'error': 'Admin user not found.'}, status=status.HTTP_404_NOT_FOUND)

        return Response({
            'user': {
                'id': user.id,
                'username': user.username,
                'email': user.email or f"{user.username}@ashwash.com",
                'first_name': user.first_name,
                'last_name': user.last_name,
                'role': user.role or 'ADMIN',
                'is_superuser': user.is_superuser,
                'date_joined': user.date_joined.strftime('%B %d, %Y') if user.date_joined else 'Recently'
            }
        })

    def post(self, request):
        token = request.headers.get('Authorization', '').replace('Bearer ', '').strip()
        user = None

        if request.user and request.user.is_authenticated:
            user = request.user
        elif token:
            try:
                from rest_framework_simplejwt.tokens import AccessToken
                validated_token = AccessToken(token)
                user_id = validated_token['user_id']
                user = User.objects.get(id=user_id)
            except Exception:
                pass

        if not user:
            user = User.objects.filter(role=User.Role.ADMIN).first() or User.objects.filter(is_superuser=True).first()

        if not user:
            return Response({'error': 'Admin user not found.'}, status=status.HTTP_404_NOT_FOUND)

        new_username = request.data.get('username', '').strip()
        new_email = request.data.get('email', '').strip()
        current_password = request.data.get('current_password', '').strip()
        new_password = request.data.get('new_password', '').strip()

        if new_password:
            if not current_password:
                return Response({'error': 'Previous (Current) password is required to set a new password.'}, status=status.HTTP_400_BAD_REQUEST)
            if not user.check_password(current_password):
                return Response({'error': 'Current password is incorrect. Please verify your previous password.'}, status=status.HTTP_400_BAD_REQUEST)
            user.set_password(new_password)

        if new_username and new_username != user.username:
            if User.objects.filter(username__iexact=new_username).exclude(id=user.id).exists():
                return Response({'error': 'Username is already taken by another account.'}, status=status.HTTP_400_BAD_REQUEST)
            user.username = new_username

        if new_email:
            user.email = new_email

        user.save()

        return Response({
            'message': 'Admin credentials updated successfully in database!',
            'user': {
                'id': user.id,
                'username': user.username,
                'email': user.email
            }
        })

class SpecialistUpdateProfileAPIView(APIView):
    permission_classes = [permissions.AllowAny]

    def get(self, request):
        token = request.headers.get('Authorization', '').replace('Bearer ', '').strip()
        user = None
        if request.user and request.user.is_authenticated:
            user = request.user
        elif token:
            try:
                from rest_framework_simplejwt.tokens import AccessToken
                validated_token = AccessToken(token)
                user_id = validated_token['user_id']
                user = User.objects.get(id=user_id)
            except Exception:
                pass

        if not user:
            user = User.objects.filter(role='SPECIALIST').first()

        if not user:
            return Response({'error': 'Specialist user not found.'}, status=status.HTTP_404_NOT_FOUND)

        profile = getattr(user, 'specialist_profile', None)

        pic_url = user.preferences.get('profile_picture_base64')
        if not pic_url and user.profile_picture:
            try:
                pic_url = request.build_absolute_uri(user.profile_picture.url)
            except Exception:
                pass

        return Response({
            'user': {
                'id': user.id,
                'username': user.username,
                'email': user.email or (profile.email if profile else ''),
                'full_name': profile.full_name if profile else (user.get_full_name() or user.username),
                'specialization': profile.specialization if profile else 'Clinical Psychologist',
                'qualification': profile.qualification if profile else 'MSc in Psychology',
                'medical_license_number': profile.medical_license_number if profile else 'BMDC-REG-98234',
                'profile_picture': pic_url,
                'role': user.role or 'SPECIALIST',
            }
        })

    def post(self, request):
        token = request.headers.get('Authorization', '').replace('Bearer ', '').strip()
        user = None

        if request.user and request.user.is_authenticated:
            user = request.user
        elif token:
            try:
                from rest_framework_simplejwt.tokens import AccessToken
                validated_token = AccessToken(token)
                user_id = validated_token['user_id']
                user = User.objects.get(id=user_id)
            except Exception:
                pass

        if not user:
            user = User.objects.filter(role='SPECIALIST').first()

        if not user:
            return Response({'error': 'Specialist user not found.'}, status=status.HTTP_404_NOT_FOUND)

        profile = getattr(user, 'specialist_profile', None)

        new_username = request.data.get('username', '').strip()
        new_email = request.data.get('email', '').strip()
        full_name = request.data.get('full_name', '').strip()
        specialization = request.data.get('specialization', '').strip()
        qualification = request.data.get('qualification', '').strip()
        current_password = request.data.get('current_password', '').strip()
        new_password = request.data.get('new_password', '').strip()
        profile_picture_base64 = request.data.get('profile_picture_base64', '')

        if 'profile_picture' in request.FILES:
            user.profile_picture = request.FILES['profile_picture']

        if profile_picture_base64:
            if not isinstance(user.preferences, dict):
                user.preferences = {}
            user.preferences['profile_picture_base64'] = profile_picture_base64

        if new_password:
            if not current_password:
                return Response({'error': 'Previous (Current) password is required to set a new password.'}, status=status.HTTP_400_BAD_REQUEST)
            if not user.check_password(current_password):
                return Response({'error': 'Current password is incorrect. Please verify your previous password.'}, status=status.HTTP_400_BAD_REQUEST)
            user.set_password(new_password)

        if new_username and new_username != user.username:
            if User.objects.filter(username__iexact=new_username).exclude(id=user.id).exists():
                return Response({'error': 'Username is already taken by another account.'}, status=status.HTTP_400_BAD_REQUEST)
            user.username = new_username

        if new_email:
            user.email = new_email
            if profile:
                profile.email = new_email

        if profile:
            if full_name:
                profile.full_name = full_name
            if specialization:
                profile.specialization = specialization
            if qualification:
                profile.qualification = qualification
            profile.save()

        user.save()

        pic_url = user.preferences.get('profile_picture_base64')
        if not pic_url and user.profile_picture:
            try:
                pic_url = request.build_absolute_uri(user.profile_picture.url)
            except Exception:
                pass

        return Response({
            'message': 'Specialist profile and credentials updated successfully in database!',
            'user': {
                'id': user.id,
                'username': user.username,
                'email': user.email,
                'full_name': profile.full_name if profile else user.username,
                'profile_picture': pic_url,
            }
        })

class AdminApproveCourseAPIView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request, pk):
        try:
            course = Course.objects.get(pk=pk)
            course.is_approved = True
            course.save()

            try:
                from apps.notifications.views import send_notification
                from django.contrib.auth import get_user_model
                User = get_user_model()
                spec_name = course.instructor.first_name if (course.instructor and hasattr(course.instructor, 'first_name') and course.instructor.first_name) else 'Specialist Doctor'
                patients = User.objects.filter(role='PATIENT') if hasattr(User, 'role') else User.objects.filter(is_staff=False)
                for p in patients:
                    send_notification(
                        recipient=p,
                        sender=course.instructor,
                        title_en=f"New Approved Course: {course.title_en} 📚",
                        title_bn=f"নতুন অনুমোদিত কোর্স: {course.title_bn} 📚",
                        message_en=f"Specialist {spec_name}'s course '{course.title_en}' is now approved and live!",
                        message_bn=f"বিশেষজ্ঞ {spec_name}-এর কোর্স '{course.title_bn}' এখন অনুমোদিত ও উন্মুক্ত!",
                        category='COURSE'
                    )
            except Exception:
                pass

            return Response({'message': f"Course '{course.title_en}' has been approved and published to patient portal!"})
        except Course.DoesNotExist:
            return Response({'error': 'Course not found'}, status=status.HTTP_404_NOT_FOUND)
