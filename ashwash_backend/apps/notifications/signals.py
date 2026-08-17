import logging
from django.db.models.signals import post_save, pre_save
from django.dispatch import receiver
from django.contrib.auth import get_user_model
from django.db.models import Q
from apps.courses.models import Course, Lesson, Assignment, UserCourseProgress, UserLessonProgress
from apps.appointments.models import Appointment
from apps.community.models import Post, Comment, Like, Report
from apps.knowledge_hub.models import Resource
from apps.mood_tracker.models import MoodLog
from apps.authentication.models import SpecialistProfile
from apps.payments.models import PaymentTransaction
from .services import NotificationManager

logger = logging.getLogger(__name__)
User = get_user_model()

# Track previous state for detecting status/field changes
_pre_save_appointment_status = {}
_pre_save_appointment_datetime = {}
_pre_save_specialist_verified = {}

@receiver(pre_save, sender=Appointment)
def track_appointment_pre_save(sender, instance, **kwargs):
    if instance.id:
        try:
            old = Appointment.objects.get(id=instance.id)
            _pre_save_appointment_status[instance.id] = old.status
            _pre_save_appointment_datetime[instance.id] = (str(old.appointment_date), str(old.time_slot))
        except Appointment.DoesNotExist:
            pass

@receiver(pre_save, sender=SpecialistProfile)
def track_specialist_pre_save(sender, instance, **kwargs):
    if instance.id:
        try:
            old = SpecialistProfile.objects.get(id=instance.id)
            _pre_save_specialist_verified[instance.id] = old.is_profile_complete
        except SpecialistProfile.DoesNotExist:
            pass

# 1. AUTHENTICATION NOTIFICATIONS
@receiver(post_save, sender=User)
def notify_user_events(sender, instance, created, **kwargs):
    try:
        if created:
            if instance.role in [User.Role.SPECIALIST, 'DOCTOR', 'Specialist', 'Doctor']:
                # 1b. Specialist registered
                NotificationManager.send_notification(
                    receiver=instance,
                    title="Application Received 🩺",
                    body="Thank you for applying as a Specialist! Your profile is currently pending Administrator review.",
                    notif_type="SYSTEM",
                    related_object_id=instance.id,
                    related_object_type="User"
                )
                # Notify admins
                for admin in User.objects.filter(Q(role=User.Role.ADMIN) | Q(is_superuser=True) | Q(is_staff=True)).distinct():
                    NotificationManager.send_notification(
                        receiver=admin,
                        sender=instance,
                        title="New Specialist Registration 🩺",
                        body=f"Specialist {instance.get_full_name() or instance.username} has registered and submitted credentials for review.",
                        notif_type="SYSTEM",
                        related_object_id=instance.id,
                        related_object_type="User"
                    )
            else:
                # 1a. Patient registered
                NotificationManager.send_notification(
                    receiver=instance,
                    title="Welcome to Ashwash! 🌟",
                    body="Your account has been successfully created. Explore mental wellness resources and connect with specialists.",
                    notif_type="SYSTEM",
                    related_object_id=instance.id,
                    related_object_type="User"
                )
                # Notify admins
                for admin in User.objects.filter(Q(role=User.Role.ADMIN) | Q(is_superuser=True) | Q(is_staff=True)).distinct():
                    NotificationManager.send_notification(
                        receiver=admin,
                        sender=instance,
                        title="New Patient Registration 👤",
                        body=f"New patient ({instance.username} - {instance.email}) joined the Ashwash platform.",
                        notif_type="SYSTEM",
                        related_object_id=instance.id,
                        related_object_type="User"
                    )
    except Exception as e:
        logger.error(f"Error in notify_user_events signal: {e}")

# 1c & 1d. SPECIALIST APPROVED / REJECTED
@receiver(post_save, sender=SpecialistProfile)
def notify_specialist_profile_status(sender, instance, created, **kwargs):
    try:
        old_verified = _pre_save_specialist_verified.pop(instance.id, None)
        if not created and instance.user:
            if old_verified is False and instance.is_profile_complete is True:
                # Specialist approved
                NotificationManager.send_notification(
                    receiver=instance.user,
                    title="Specialist Profile Approved! 🎉",
                    body="Congratulations! Your specialist application has been verified and approved. You can now accept patient bookings and publish courses.",
                    notif_type="PROFILE",
                    related_object_id=instance.id,
                    related_object_type="SpecialistProfile"
                )
    except Exception as e:
        logger.error(f"Error in notify_specialist_profile_status signal: {e}")

# 2. COURSE NOTIFICATIONS
@receiver(post_save, sender=Course)
def notify_course_events(sender, instance, created, **kwargs):
    try:
        if created:
            # Notify admins of newly created course
            for admin in User.objects.filter(Q(role=User.Role.ADMIN) | Q(is_superuser=True) | Q(is_staff=True)).distinct():
                NotificationManager.send_notification(
                    receiver=admin,
                    sender=instance.instructor,
                    title="New Course Submitted 📚",
                    body=f"Course '{instance.title_en}' was submitted for approval by {instance.instructor.username if instance.instructor else 'Instructor'}.",
                    notif_type="COURSE",
                    related_object_id=instance.id,
                    related_object_type="Course"
                )
        elif instance.is_approved:
            # 2a. Admin published/approved course -> Notify instructor & all patients
            if instance.instructor:
                NotificationManager.send_notification(
                    receiver=instance.instructor,
                    title="Course Approved & Live! 🎉",
                    body=f"Your course '{instance.title_en}' has been approved and is now live for all patients.",
                    notif_type="COURSE",
                    related_object_id=instance.id,
                    related_object_type="Course"
                )
            
            # Notify all patients
            patients = User.objects.filter(Q(role=User.Role.PATIENT) | Q(role='PATIENT') | Q(is_staff=False)).distinct()
            for patient in patients[:150]:
                if patient != instance.instructor:
                    NotificationManager.send_notification(
                        receiver=patient,
                        sender=instance.instructor,
                        title="New Course Published 🎓",
                        body=f"New course '{instance.title_en}' is now available. Start learning and expanding your wellness skills!",
                        notif_type="COURSE",
                        related_object_id=instance.id,
                        related_object_type="Course"
                    )
    except Exception as e:
        logger.error(f"Error in notify_course_events signal: {e}")

# 2b, 2c, 2d. COURSE ENROLLED, COMPLETED, CERTIFICATE
@receiver(post_save, sender=UserCourseProgress)
def notify_course_progress(sender, instance, created, **kwargs):
    try:
        if created:
            # 2b. Patient enrolled -> Patient + Specialist notification
            NotificationManager.send_notification(
                receiver=instance.user,
                title="Enrolled in Course 🎓",
                body=f"You have enrolled in '{instance.course.title_en}'. Start your first lesson today!",
                notif_type="COURSE",
                related_object_id=instance.course.id,
                related_object_type="Course"
            )
            if instance.course.instructor and instance.course.instructor != instance.user:
                patient_name = instance.user.get_full_name() or instance.user.username
                NotificationManager.send_notification(
                    receiver=instance.course.instructor,
                    sender=instance.user,
                    title="New Student Enrolled 🎓",
                    body=f"Student {patient_name} enrolled in your course '{instance.course.title_en}'.",
                    notif_type="COURSE",
                    related_object_id=instance.course.id,
                    related_object_type="Course"
                )
        elif instance.is_completed:
            # 2c. Course completed
            NotificationManager.send_notification(
                receiver=instance.user,
                title="Course Completed! 🎓",
                body=f"Congratulations! You completed '{instance.course.title_en}'. Your certificate is ready to view.",
                notif_type="COURSE",
                related_object_id=instance.course.id,
                related_object_type="Course"
            )
            # 2d. Certificate generated
            NotificationManager.send_notification(
                receiver=instance.user,
                title="Certificate Generated 📜",
                body=f"Your verified certificate of completion for '{instance.course.title_en}' is now ready in your Profile.",
                notif_type="COURSE",
                related_object_id=instance.course.id,
                related_object_type="Certificate"
            )
    except Exception as e:
        logger.error(f"Error in notify_course_progress signal: {e}")

# 3. ASSIGNMENT & HOMEWORK NOTIFICATIONS
@receiver(post_save, sender=UserLessonProgress)
def notify_lesson_and_assignment_progress(sender, instance, created, **kwargs):
    try:
        if instance.is_completed:
            lesson = instance.lesson
            course = lesson.module.course
            
            # 3a. Assignment unlocked for patient
            next_lesson = Lesson.objects.filter(
                module__course=course,
                order__gt=lesson.order
            ).order_by('order').first()

            if next_lesson and hasattr(next_lesson, 'assignments') and next_lesson.assignments.exists():
                NotificationManager.send_notification(
                    receiver=instance.user,
                    title="New Assignment Unlocked 📝",
                    body=f"You unlocked a new assignment in '{next_lesson.title_en}' for '{course.title_en}'.",
                    notif_type="COURSE",
                    related_object_id=course.id,
                    related_object_type="Assignment"
                )

            # 3b. Patient submits homework -> Specialist notification
            if course.instructor and course.instructor != instance.user:
                patient_name = instance.user.get_full_name() or instance.user.username
                NotificationManager.send_notification(
                    receiver=course.instructor,
                    sender=instance.user,
                    title="Homework Task Submitted 📝",
                    body=f"Patient {patient_name} completed and submitted homework for '{lesson.title_en}' in '{course.title_en}'.",
                    notif_type="COURSE",
                    related_object_id=course.id,
                    related_object_type="Homework"
                )
    except Exception as e:
        logger.error(f"Error in notify_lesson_and_assignment_progress signal: {e}")

# Helper to find specialist user account
def get_specialist_user_for_appointment(appointment):
    if not appointment.specialist:
        return None
    # appointment.specialist is now a SpecialistProfile which has a .user ForeignKey
    if appointment.specialist.user:
        return appointment.specialist.user
    
    # Fallback search in User model if somehow user is missing (should not happen)
    spec_name = appointment.specialist.full_name
    spec_user = User.objects.filter(
        Q(role__in=[User.Role.SPECIALIST, 'DOCTOR', 'Specialist', 'Doctor']) &
        (Q(first_name__icontains=spec_name.split()[0] if spec_name else '') | Q(username__icontains=spec_name.split()[0] if spec_name else ''))
    ).first()
    if spec_user:
        return spec_user
    return User.objects.filter(role__in=[User.Role.SPECIALIST, 'DOCTOR', 'Specialist', 'Doctor']).first()

# 4. APPOINTMENT / SESSION NOTIFICATIONS
@receiver(post_save, sender=Appointment)
def notify_appointment_changes(sender, instance, created, **kwargs):
    try:
        patient_user = instance.user
        specialist_name = instance.specialist.full_name if instance.specialist else "Specialist Doctor"
        specialist_user = get_specialist_user_for_appointment(instance)

        app_date = getattr(instance, 'appointment_date', getattr(instance, 'date', 'Scheduled Date'))
        app_time = getattr(instance, 'time_slot', getattr(instance, 'time', 'Scheduled Time'))
        patient_name = patient_user.get_full_name() or patient_user.username if patient_user else "Patient"

        if created:
            # 4a. Patient books session -> Patient, Specialist, Admin notification
            if patient_user:
                NotificationManager.send_notification(
                    receiver=patient_user,
                    sender=specialist_user,
                    title="Session Booked 🩺",
                    body=f"Your appointment with {specialist_name} on {app_date} ({app_time}) has been requested.",
                    notif_type="APPOINTMENT",
                    related_object_id=instance.id,
                    related_object_type="Appointment"
                )
            if specialist_user:
                NotificationManager.send_notification(
                    receiver=specialist_user,
                    sender=patient_user,
                    title="New Session Booking 🩺",
                    body=f"New appointment booked by {patient_name} for {app_date} ({app_time}).",
                    notif_type="APPOINTMENT",
                    related_object_id=instance.id,
                    related_object_type="Appointment"
                )
            for admin in User.objects.filter(Q(role=User.Role.ADMIN) | Q(is_superuser=True) | Q(is_staff=True)).distinct():
                NotificationManager.send_notification(
                    receiver=admin,
                    sender=patient_user,
                    title="New Appointment Scheduled",
                    body=f"Session booked between {patient_name} and {specialist_name} on {app_date}.",
                    notif_type="APPOINTMENT",
                    related_object_id=instance.id,
                    related_object_type="Appointment"
                )
        else:
            old_status = _pre_save_appointment_status.pop(instance.id, None)
            old_dt = _pre_save_appointment_datetime.pop(instance.id, None)

            # Check if rescheduled (date/time changed)
            current_dt = (str(instance.appointment_date), str(instance.time_slot))
            if old_dt and old_dt != current_dt and instance.status != 'cancelled':
                # 4d. Session rescheduled -> Both notification
                if patient_user:
                    NotificationManager.send_notification(
                        receiver=patient_user,
                        sender=specialist_user,
                        title="Appointment Rescheduled 📅",
                        body=f"Your session with {specialist_name} has been rescheduled to {app_date} ({app_time}).",
                        notif_type="APPOINTMENT",
                        related_object_id=instance.id,
                        related_object_type="Appointment"
                    )
                if specialist_user:
                    NotificationManager.send_notification(
                        receiver=specialist_user,
                        sender=patient_user,
                        title="Appointment Rescheduled 📅",
                        body=f"Session with {patient_name} has been rescheduled to {app_date} ({app_time}).",
                        notif_type="APPOINTMENT",
                        related_object_id=instance.id,
                        related_object_type="Appointment"
                    )

            # Check status change
            if instance.status == 'confirmed' and old_status != 'confirmed':
                # 4b. Specialist confirms session -> Patient notification
                if patient_user:
                    NotificationManager.send_notification(
                        receiver=patient_user,
                        sender=specialist_user,
                        title="Session Confirmed! 🩺",
                        body=f"Dr. {specialist_name} confirmed your appointment for {app_date} at {app_time}. Meeting link is available in your appointments.",
                        notif_type="APPOINTMENT",
                        related_object_id=instance.id,
                        related_object_type="Appointment"
                    )
            elif instance.status == 'cancelled' and old_status != 'cancelled':
                # 4c. Session cancelled -> Both notification
                if patient_user:
                    NotificationManager.send_notification(
                        receiver=patient_user,
                        sender=specialist_user,
                        title="Appointment Cancelled ⚠️",
                        body=f"Your session scheduled for {app_date} with {specialist_name} has been cancelled.",
                        notif_type="APPOINTMENT",
                        related_object_id=instance.id,
                        related_object_type="Appointment"
                    )
                if specialist_user:
                    NotificationManager.send_notification(
                        receiver=specialist_user,
                        sender=patient_user,
                        title="Appointment Cancelled ⚠️",
                        body=f"Session on {app_date} with {patient_name} has been cancelled.",
                        notif_type="APPOINTMENT",
                        related_object_id=instance.id,
                        related_object_type="Appointment"
                    )
            elif instance.status == 'completed' and old_status != 'completed':
                # 4e. Session completed -> Both notification
                if patient_user:
                    NotificationManager.send_notification(
                        receiver=patient_user,
                        sender=specialist_user,
                        title="Session Completed 🩺",
                        body=f"Your consultation with {specialist_name} is complete. Please rate your experience and view session notes!",
                        notif_type="APPOINTMENT",
                        related_object_id=instance.id,
                        related_object_type="Appointment"
                    )
                if specialist_user:
                    NotificationManager.send_notification(
                        receiver=specialist_user,
                        sender=patient_user,
                        title="Session Marked Completed 🩺",
                        body=f"Consultation with {patient_name} on {app_date} has been marked as completed.",
                        notif_type="APPOINTMENT",
                        related_object_id=instance.id,
                        related_object_type="Appointment"
                    )

            # 4f. Prescription uploaded
            if instance.notes and 'prescription' in instance.notes.lower() and patient_user:
                NotificationManager.send_notification(
                    receiver=patient_user,
                    sender=specialist_user,
                    title="Prescription Uploaded 📋",
                    body=f"Dr. {specialist_name} added prescription notes for your consultation on {app_date}. View your appointment details.",
                    notif_type="APPOINTMENT",
                    related_object_id=instance.id,
                    related_object_type="Prescription"
                )

    except Exception as e:
        logger.error(f"Error in notify_appointment_changes signal: {e}")

# 5. KNOWLEDGE HUB NOTIFICATIONS
@receiver(post_save, sender=Resource)
def notify_knowledge_hub_resource(sender, instance, created, **kwargs):
    try:
        if created:
            r_type = instance.resource_type.upper()
            icon = "📚" if r_type == "ARTICLE" else ("🎥" if r_type == "VIDEO" else ("🎧" if r_type == "AUDIO" else "📄"))
            
            title_text = f"New {instance.resource_type.capitalize()} in Knowledge Hub {icon}"
            body_text = f"'{instance.title_en}' ({instance.duration_minutes} min read/listen) has been added to the Knowledge Hub."

            target_patients = User.objects.filter(Q(role=User.Role.PATIENT) | Q(role='PATIENT') | Q(is_staff=False)).distinct()
            for patient in target_patients[:150]:
                NotificationManager.send_notification(
                    receiver=patient,
                    title=title_text,
                    body=body_text,
                    notif_type="KNOWLEDGE_HUB",
                    related_object_id=instance.id,
                    related_object_type="Resource"
                )
    except Exception as e:
        logger.error(f"Error in notify_knowledge_hub_resource signal: {e}")

# 6. COMMUNITY NOTIFICATIONS (KEPT EXACTLY INTACT)
@receiver(post_save, sender=Post)
def notify_community_post(sender, instance, created, **kwargs):
    try:
        if created:
            author_label = instance.author_alias or (instance.author.get_full_name() if instance.author else "A patient")
            snippet = instance.content[:75] + ("..." if len(instance.content) > 75 else "")
            
            # Query all specialists (role=SPECIALIST/DOCTOR or SpecialistProfile attached)
            specialists = User.objects.filter(
                Q(role__in=['SPECIALIST', 'DOCTOR', 'Specialist', 'Doctor']) |
                Q(specialist_profile__isnull=False)
            ).distinct()

            for spec in specialists:
                if spec != instance.author:
                    NotificationManager.send_notification(
                        receiver=spec,
                        sender=instance.author,
                        title="New Community Post Available 💬",
                        body=f"New community post available: '{snippet}'. Check it and reply.",
                        notif_type="COMMUNITY",
                        related_object_id=instance.id,
                        related_object_type="Post"
                    )

            # Query all administrators
            admins = User.objects.filter(
                Q(role__in=['ADMIN', 'Admin']) |
                Q(is_superuser=True) |
                Q(is_staff=True)
            ).distinct()

            for admin in admins:
                if admin != instance.author:
                    NotificationManager.send_notification(
                        receiver=admin,
                        sender=instance.author,
                        title="New Community Post 💬",
                        body=f"{author_label} created a new post in #{instance.tag}: '{snippet}'",
                        notif_type="COMMUNITY",
                        related_object_id=instance.id,
                        related_object_type="Post"
                    )
    except Exception as e:
        logger.error(f"Error in notify_community_post signal: {e}")

@receiver(post_save, sender=Comment)
def notify_community_comment(sender, instance, created, **kwargs):
    try:
        if created:
            post_author = instance.post.author
            # Specialist replies -> Patient notification
            if post_author and post_author != instance.author:
                doctor_name = instance.author_alias or (f"Dr. {instance.author.get_full_name()}" if instance.author else "A Specialist")
                comment_snippet = instance.content[:80] + ("..." if len(instance.content) > 80 else "")
                NotificationManager.send_notification(
                    receiver=post_author,
                    sender=instance.author,
                    title="Specialist Replied to Your Post 🩺💬",
                    body=f"{doctor_name} replied to your post: '{comment_snippet}'",
                    notif_type="COMMUNITY",
                    related_object_id=instance.post.id,
                    related_object_type="Post"
                )
            
            # Patient replies -> Specialist notification (if comment is on a thread where specialist commented)
            if instance.author and instance.author != post_author:
                spec_commenters = User.objects.filter(
                    comments__post=instance.post,
                    role__in=[User.Role.SPECIALIST, 'DOCTOR', 'Specialist', 'Doctor']
                ).exclude(id=instance.author.id).distinct()
                for spec in spec_commenters:
                    NotificationManager.send_notification(
                        receiver=spec,
                        sender=instance.author,
                        title="New Reply in Community Thread 💬",
                        body=f"New reply from {instance.author_alias or instance.author.username} on post #{instance.post.id}: '{instance.content[:75]}'",
                        notif_type="COMMUNITY",
                        related_object_id=instance.post.id,
                        related_object_type="Post"
                    )
    except Exception as e:
        logger.error(f"Error in notify_community_comment signal: {e}")

@receiver(post_save, sender=Like)
def notify_community_like(sender, instance, created, **kwargs):
    try:
        if created:
            post_author = instance.post.author
            if post_author and post_author != instance.user:
                sender_name = instance.user.get_full_name() or instance.user.username or "A member"
                post_snippet = instance.post.content[:60] + ("..." if len(instance.post.content) > 60 else "")
                NotificationManager.send_notification(
                    receiver=post_author,
                    sender=instance.user,
                    title="New Like on Your Post ❤️",
                    body=f"{sender_name} liked your community post: '{post_snippet}'",
                    notif_type="COMMUNITY",
                    related_object_id=instance.post.id,
                    related_object_type="Post"
                )
    except Exception as e:
        logger.error(f"Error in notify_community_like signal: {e}")

@receiver(post_save, sender=Report)
def notify_community_report(sender, instance, created, **kwargs):
    try:
        if created:
            reporter_name = instance.user.get_full_name() or instance.user.username or "A user"
            post_author_name = instance.post.author_alias or (instance.post.author.username if instance.post.author else "Unknown")
            reason_snippet = instance.reason[:80]
            
            admins = User.objects.filter(
                Q(role__in=['ADMIN', 'Admin']) |
                Q(is_superuser=True) |
                Q(is_staff=True)
            ).distinct()
            
            for admin in admins:
                NotificationManager.send_notification(
                    receiver=admin,
                    sender=instance.user,
                    title="Community Post Reported ⚠️",
                    body=f"Post #{instance.post.id} by {post_author_name} reported by {reporter_name} for: '{reason_snippet}'. Review and manage in Admin Portal.",
                    notif_type="COMMUNITY",
                    related_object_id=instance.post.id,
                    related_object_type="Post"
                )
    except Exception as e:
        logger.error(f"Error in notify_community_report signal: {e}")

# PAYMENT NOTIFICATIONS
@receiver(post_save, sender=PaymentTransaction)
def notify_payment_transaction(sender, instance, created, **kwargs):
    try:
        if created and instance.user:
            pmethod = getattr(instance, 'method', 'Online')
            # Notify user
            NotificationManager.send_notification(
                receiver=instance.user,
                title="Payment Confirmed 💳",
                body=f"Your payment of ৳{instance.amount} for {instance.purpose} via {pmethod} was successful! (TxID: {instance.transaction_id})",
                notif_type="PAYMENT",
                related_object_id=instance.id,
                related_object_type="PaymentTransaction"
            )
            # Notify admins
            for admin in User.objects.filter(Q(role=User.Role.ADMIN) | Q(is_superuser=True) | Q(is_staff=True)).distinct():
                NotificationManager.send_notification(
                    receiver=admin,
                    sender=instance.user,
                    title="Payment Received 💳",
                    body=f"৳{instance.amount} received from {instance.user.username} for {instance.purpose}.",
                    notif_type="PAYMENT",
                    related_object_id=instance.id,
                    related_object_type="PaymentTransaction"
                )
    except Exception as e:
        logger.error(f"Error in notify_payment_transaction signal: {e}")

# MOOD TRACKER NOTIFICATIONS
@receiver(post_save, sender=MoodLog)
def notify_mood_log(sender, instance, created, **kwargs):
    try:
        if created and instance.user:
            NotificationManager.send_notification(
                receiver=instance.user,
                title="Mood Tracker Updated 🌟",
                body=f"You logged your mood as '{instance.mood}'. Keep building your daily wellness habit!",
                notif_type="GENERAL",
                related_object_id=instance.id,
                related_object_type="MoodLog"
            )
    except Exception as e:
        logger.error(f"Error in notify_mood_log signal: {e}")
