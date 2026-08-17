import 'package:flutter/material.dart';
import '../network/api_service.dart';
import '../network/api_endpoints.dart';

class NotificationModel {
  final int id;
  final String title;
  final String body;
  final String type;
  final bool isRead;
  final String createdAt;
  final String? relatedObjectId;
  final String? relatedObjectType;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.relatedObjectId,
    this.relatedObjectType,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? 'Ashwash Notification',
      body: json['body'] ?? '',
      type: json['notification_type'] ?? 'GENERAL',
      isRead: json['is_read'] ?? false,
      createdAt: json['created_at'] ?? DateTime.now().toIso8601String(),
      relatedObjectId: json['related_object_id']?.toString(),
      relatedObjectType: json['related_object_type']?.toString(),
    );
  }
}

class NotificationProvider extends ChangeNotifier {
  int _unreadCount = 0;
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;

  int get unreadCount => _unreadCount;
  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;

  Future<void> fetchUnreadCount() async {
    try {
      final response = await ApiService.get(ApiEndpoints.notificationsCount, requireAuth: true);
      _unreadCount = response['unread_count'] ?? 0;
      notifyListeners();
    } catch (e) {
      debugPrint("Failed to fetch unread count: $e");
    }
  }

  void addNotification({required String title, required String message, String type = 'ENROLLMENT'}) {
    final newNotif = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch,
      title: title,
      body: message,
      type: type,
      isRead: false,
      createdAt: 'Just now',
    );
    _notifications.insert(0, newNotif);
    _unreadCount = _notifications.where((n) => !n.isRead).length;
    notifyListeners();
  }

  Future<void> fetchNotifications() async {
    _isLoading = true;
    notifyListeners();
    try {
      final listData = await ApiService.getList(ApiEndpoints.notifications, requireAuth: true);
      _notifications = listData.map((e) => NotificationModel.fromJson(e as Map<String, dynamic>)).toList();
      _unreadCount = _notifications.where((n) => !n.isRead).length;
    } catch (e) {
      debugPrint("Failed to fetch notifications: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(int id) async {
    try {
      await ApiService.post('${ApiEndpoints.notifications}$id/read/', {}, requireAuth: true);
      final index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        final notif = _notifications[index];
        _notifications[index] = NotificationModel(
          id: notif.id,
          title: notif.title,
          body: notif.body,
          type: notif.type,
          isRead: true,
          createdAt: notif.createdAt,
          relatedObjectId: notif.relatedObjectId,
          relatedObjectType: notif.relatedObjectType,
        );
        _unreadCount = _notifications.where((n) => !n.isRead).length;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Failed to mark as read: $e");
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await ApiService.post(ApiEndpoints.notificationsReadAll, {}, requireAuth: true);
      for (var i = 0; i < _notifications.length; i++) {
        final notif = _notifications[i];
        _notifications[i] = NotificationModel(
          id: notif.id,
          title: notif.title,
          body: notif.body,
          type: notif.type,
          isRead: true,
          createdAt: notif.createdAt,
          relatedObjectId: notif.relatedObjectId,
          relatedObjectType: notif.relatedObjectType,
        );
      }
      _unreadCount = 0;
      notifyListeners();
    } catch (e) {
      debugPrint("Failed to mark all as read: $e");
    }
  }

  Future<void> deleteNotification(int id) async {
    try {
      await ApiService.delete('${ApiEndpoints.notifications}$id/delete/', requireAuth: true);
      _notifications.removeWhere((n) => n.id == id);
      _unreadCount = _notifications.where((n) => !n.isRead).length;
      notifyListeners();
    } catch (e) {
      debugPrint("Failed to delete notification: $e");
    }
  }

  Future<void> deleteAllNotifications() async {
    try {
      await ApiService.delete(ApiEndpoints.notificationsDeleteAll, requireAuth: true);
      _notifications.clear();
      _unreadCount = 0;
      notifyListeners();
    } catch (e) {
      debugPrint("Failed to delete all notifications: $e");
    }
  }
}

