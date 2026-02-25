import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/notification_model.dart';

abstract class NotificationsRemoteDataSource {
  Future<(int, List<NotificationModel>)> getNotifications(
      {int page = 1, int perPage = 20});
  Future<int> getUnreadCount();
  Future<void> markAsRead({int? notificationId});
}

class NotificationsRemoteDataSourceImpl
    implements NotificationsRemoteDataSource {
  final ApiClient client;
  NotificationsRemoteDataSourceImpl({required this.client});

  @override
  Future<(int, List<NotificationModel>)> getNotifications(
      {int page = 1, int perPage = 20}) async {
    final response = await client.get(
      ApiConstants.notifications,
      queryParameters: {'page': page, 'per_page': perPage},
    );
    if (response.statusCode == 200) {
      final Map<String, dynamic> wrapper = response.data['data'];
      final List data = wrapper['items'] ?? [];
      final int total = (wrapper['total'] as num?)?.toInt() ?? data.length;
      final items =
          data.map((json) => NotificationModel.fromJson(json)).toList();
      return (total, items);
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
