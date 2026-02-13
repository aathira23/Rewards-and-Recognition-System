/// "Centralized storage for all API endpoints and network-related configuration constants."
class ApiConstants {
  static const String baseUrl =
      'http://localhost:8000/api'; // Update for production

  // Auth
  static const String login = '$baseUrl/auth/login';
  static const String register = '$baseUrl/auth/register';
  static const String profile = '$baseUrl/users/profile';

  // Recognitions
  static const String recognitions = '$baseUrl/recognitions';
  static const String badges = '$baseUrl/recognitions/badges';

  // Awards
  static const String awards = '$baseUrl/awards';
  static const String nominations = '$baseUrl/awards/nominations';

  // Points & Wallets
  static const String wallets = '$baseUrl/wallets';
  static const String redemptions = '$baseUrl/store/redemptions';

  // TODO: Add other endpoints as needed
}
