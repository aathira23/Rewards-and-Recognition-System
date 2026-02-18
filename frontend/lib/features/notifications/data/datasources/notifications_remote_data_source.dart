import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/notification_model.dart';

abstract class NotificationsRemoteDataSource {
  Future<List<NotificationModel>> getNotifications();
  Future<int> getUnreadCount();
  Future<void> markAsRead({int? notificationId});
}

class NotificationsRemoteDataSourceImpl
    implements NotificationsRemoteDataSource {
  final ApiClient client;
  NotificationsRemoteDataSourceImpl({required this.client});

  @override
  Future<List<NotificationModel>> getNotifications() async {
    final response = await client.get(ApiConstants.notifications);
    if (response.statusCode == 200) {
      final List data = response.data['data'] ?? [];
      return data.map((json) => NotificationModel.fromJson(json)).toList();
    }
    throw Exception('Failed to fetch notifications');
  }

  @override
  Future<int> getUnreadCount() async {
    final response = await client.get(ApiConstants.notificationsUnreadCount);
    if (response.statusCode == 200) {
      return response.data['data']?['unread_count'] ?? 0;
    }
    throw Exception('Failed to fetch unread count');
  }

  @override
  Future<void> markAsRead({int? notificationId}) async {
    if (notificationId != null) {
      // Mark single notification as read via query param
      await client.post(
        ApiConstants.notificationsMarkRead,
        queryParameters: {'notification_id': notificationId},
      );
    } else {
      // Mark all as read
      await client.post(
        ApiConstants.notificationsMarkRead,
        queryParameters: {'mark_all': true},
      );
    }
  }
}
