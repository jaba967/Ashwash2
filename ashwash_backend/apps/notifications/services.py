import os
from .models import Notification, FCMDevice
import logging

logger = logging.getLogger(__name__)

try:
    import firebase_admin
    from firebase_admin import credentials, messaging
    
    # Initialize Firebase if not already initialized
    if not firebase_admin._apps:
        # Check if service account key exists
        cred_path = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(__file__))), 'firebase_credentials.json')
        if os.path.exists(cred_path):
            cred = credentials.Certificate(cred_path)
            firebase_admin.initialize_app(cred)
            logger.info("Firebase Admin initialized successfully.")
        else:
            logger.warning(f"Firebase credentials not found at {cred_path}. Push notifications will not be sent.")
            
    FIREBASE_AVAILABLE = bool(firebase_admin._apps)
except ImportError:
    FIREBASE_AVAILABLE = False
    logger.warning("firebase-admin package is not installed. Push notifications will not be sent.")

class NotificationManager:
    @staticmethod
    def send_notification(receiver, title, body, notif_type='GENERAL', sender=None, related_object_id=None, related_object_type=None):
        """
        Creates a Notification record in the database and sends an FCM push notification to all active devices of the receiver.
        """
        if not receiver:
            return None

        # 0. Deduplication check: prevent identical notification within 5 seconds
        from django.utils import timezone
        from datetime import timedelta
        recent_duplicate = Notification.objects.filter(
            receiver=receiver,
            title=title,
            related_object_id=str(related_object_id) if related_object_id else None,
            created_at__gte=timezone.now() - timedelta(seconds=5)
        ).first()
        if recent_duplicate:
            logger.info(f"Duplicate notification skipped for {receiver.username}: {title}")
            return recent_duplicate

        # 1. Save to Database
        notification = Notification.objects.create(
            receiver=receiver,
            sender=sender,
            sender_role=getattr(sender, 'role', None) if sender else None,
            receiver_role=getattr(receiver, 'role', None) if receiver else None,
            notification_type=notif_type,
            title=title,
            body=body,
            related_object_id=str(related_object_id) if related_object_id else None,
            related_object_type=related_object_type
        )
        
        # 2. Send FCM Push Notification
        if not FIREBASE_AVAILABLE:
            logger.info(f"Notification saved to DB, but skipped FCM push because Firebase is not configured: {title}")
            return notification

        devices = FCMDevice.objects.filter(user=receiver, is_active=True)
        if not devices.exists():
            logger.info(f"No active FCM devices found for user {receiver.username}")
            return notification

        tokens = [device.fcm_token for device in devices]
        
        message = messaging.MulticastMessage(
            notification=messaging.Notification(
                title=title,
                body=body,
            ),
            data={
                'notification_id': str(notification.id),
                'type': notif_type,
                'related_object_id': str(related_object_id) if related_object_id else '',
                'related_object_type': related_object_type or '',
            },
            tokens=tokens,
        )
        
        try:
            response = messaging.send_each_for_multicast(message)
            logger.info(f"Successfully sent {response.success_count} messages; {response.failure_count} failed.")
            
            if response.failure_count > 0:
                for idx, res in enumerate(response.responses):
                    if not res.success:
                        logger.warning(f"Failed to send to token {tokens[idx]}: {res.exception}")
                        
        except Exception as e:
            logger.error(f"Error sending FCM notification: {e}")
            
        return notification

def send_notification(recipient=None, receiver=None, title=None, title_en=None, title_bn=None, 
                      body=None, message_en=None, message_bn=None, category='GENERAL', notif_type=None,
                      sender=None, related_object_id=None, related_object_type=None):
    """
    Universal helper function compatible with all calling styles across the codebase.
    """
    target_user = receiver or recipient
    if not target_user:
        return None

    final_title = title or title_en or title_bn or "Ashwash Notification"
    final_body = body or message_en or message_bn or ""
    final_type = notif_type or category or 'GENERAL'

    return NotificationManager.send_notification(
        receiver=target_user,
        title=final_title,
        body=final_body,
        notif_type=final_type,
        sender=sender,
        related_object_id=related_object_id,
        related_object_type=related_object_type
    )

