/// "Data model for Authentication, mapping backend JSON response to the entity."
import '../../domain/entities/auth_entity.dart';

class AuthModel extends AuthEntity {
  const AuthModel({
    required super.token,
    required super.userId,
  });

  /// Factory constructor to create an AuthModel from JSON.
  /// Maps 'access_token' from backend to 'token' field.
  factory AuthModel.fromJson(Map<String, dynamic> json) {
    return AuthModel(
      token: json['access_token'] ?? '',
      userId: json['user_id'] ?? 0,
    );
  }

  /// Converts the model back to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'access_token': token,
      'user_id': userId,
    };
  }
}
