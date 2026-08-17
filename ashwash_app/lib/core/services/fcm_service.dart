import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../network/api_service.dart';
import '../../features/profile/my_patient_sessions_screen.dart';

class FCMService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  static Future<void> initFCM(BuildContext context) async {
    // Request permissions for iOS and Web
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
      
      // Get the token
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        print("FCM Token: \$token");
        await _registerTokenWithBackend(token);
      }

      // Listen to token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        _registerTokenWithBackend(newToken);
      });

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('Got a message whilst in the foreground!');
        print('Message data: ${message.data}');

        if (message.notification != null) {
          print('Message also contained a notification: ${message.notification}');
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message.notification!.title ?? 'New Notification'),
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'View',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MyPatientSessionsScreen()),
                  );
                },
              ),
            ),
          );
        }
      });

      // Handle background message clicks
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('A new onMessageOpenedApp event was published!');
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MyPatientSessionsScreen()),
        );
      });

    } else {
      print('User declined or has not accepted permission');
    }
  }

  static Future<void> _registerTokenWithBackend(String token) async {
    try {
      final response = await ApiService.post(
        '/api/notifications/register-device/',
        {'fcm_token': token, 'device_type': 'android'},
      );
      print("Token registered with backend successfully");
    } catch (e) {
      print("Failed to register token with backend: \$e");
    }
  }
}
