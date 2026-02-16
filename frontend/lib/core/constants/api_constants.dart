/// "Centralized storage for all backend endpoint URLs and networking constants."
class ApiConstants {
  // Use http://localhost:8000/api/v1 for Chrome Web development
  // Use http://10.0.2.2:8000/api/v1 for Android Emulator
  static const String baseUrl = 'http://localhost:8080/';

  // Auth Endpoints
  static const String login = 'auth/login';
  static const String register = 'auth/register';

  // Recognition Endpoints
  static const String recognitionFeed = 'recognitions/feed';
  static const String sendRecognition = 'recognitions/';
  static const String badges = 'recognitions/badges';
  static const String leaderboard = 'recognitions/leaderboard';

  // Nominations Endpoints
  static const String nominations = 'nominations/';
  static const String awardTypes = 'nominations/types';

  // Points & Wallets
  static const String userPoints = 'points/aggregates';
  static const String pointsHistory = 'points/history';

  // Catalog
  static const String catalog = 'catalog/';

  // Profile
  static const String profile = 'profile/me';

  // Networking settings
  static const int connectTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000; // 30 seconds
}
