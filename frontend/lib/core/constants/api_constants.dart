/// "Centralized storage for all backend endpoint URLs and networking constants."
class ApiConstants {
  // Use http://localhost:8000/api/v1 for Chrome Web development
  // Use http://10.0.2.2:8000/api/v1 for Android Emulator
  static const String baseUrl = 'http://127.0.0.1:8000/';

  // Auth Endpoints
  static const String login = 'auth/login';
  static const String register = 'auth/register';

  // Recognition Endpoints
  static const String recognitionFeed = 'recognitions/feed';
  static const String sendRecognition = 'recognitions/';
  static const String badges = 'recognitions/badges';
  static const String leaderboard = 'recognitions/leaderboard';
  static const String recognitionOverview = 'recognitions/me/overview';

  // Awards / Nominations Endpoints
  static const String nominations = 'awards/nominations';
  static const String awardTypes = 'awards/';
  static const String nominationAction = 'awards/nominations'; // /{id}/action
  static const String nominationApprovalStatus =
      'awards/nominations'; // /{id}/approval-status

  // Points & Wallets
  static const String userPoints = 'points/balance';
  static const String pointsHistory = 'points/history';
  static const String pointsConvert = 'points/convert';
  static const String pointsConversions = 'points/conversions';
  static const String pointsPendingConversions = 'points/conversions/pending';
  static const String pointsRules = 'points/rules';

  // Budgets & Wallets
  static const String managerWallet = 'budgets/manager';
  static const String managerAllocate = 'budgets/manager/allocate';
  static const String managerReward = 'budgets/manager/reward';
  static const String managerBulkAllocate = 'budgets/manager/bulk-allocate';

  // Catalog
  static const String catalog = 'catalog/';
  static const String catalogItems = 'catalog/items';
  static const String catalogRedeem = 'catalog/redeem';
  static const String catalogHistory = 'catalog/history';

  // Celebrations
  static const String celebrationsUpcoming = 'celebrations/upcoming';
  static const String celebrationsHistory = 'celebrations/history';
  static const String celebrationsProcess = 'celebrations/process-today';

  // Notifications
  static const String notifications = 'inbox/';
  static const String notificationsUnreadCount = 'inbox/unread-count';
  static const String notificationsMarkRead = 'inbox/mark-read';
  static const String notificationsSendExpiry = 'inbox/send-expiry-reminders';

  // Analytics
  static const String analytics = 'analytics/';

  // Reports
  static const String reports = 'reports/';
  static const String reportsPayroll = 'reports/payroll';

  // System Config (HR only)
  static const String systemConfig = 'config/';

  // Department Management
  static const String departments = 'departments/';

  // Profile
  static const String profile = 'profile/me';
  // Backend exposes user listing under /profile/ (see backend router)
  static const String users = 'profile/';
  static const String userUpdate = 'profile/'; // /{user_id}

  // Networking settings
  static const int connectTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000; // 30 seconds
}
