import 'package:equatable/equatable.dart';

class UserMgmtState extends Equatable {
  final bool isLoading;
  final List<Map<String, dynamic>> users;
  final String? error;
  final String? successMessage;

  const UserMgmtState({
    this.isLoading = false,
    this.users = const [],
    this.error,
    this.successMessage,
  });

  UserMgmtState copyWith({
    bool? isLoading,
    List<Map<String, dynamic>>? users,
    String? error,
    String? successMessage,
  }) {
    return UserMgmtState(
      isLoading: isLoading ?? this.isLoading,
      users: users ?? this.users,
      error: error,
      successMessage: successMessage,
    );
  }

  @override
  List<Object?> get props => [isLoading, users, error, successMessage];
}
