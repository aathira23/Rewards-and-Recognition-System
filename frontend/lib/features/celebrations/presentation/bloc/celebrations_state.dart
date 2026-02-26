import 'package:equatable/equatable.dart';
import '../../domain/entities/celebration_entity.dart';

enum CelebrationsStatus { initial, loading, success, failure }

class CelebrationsState extends Equatable {
  final CelebrationsStatus status;
  final List<CelebrationEntity> upcoming;
  final List<CelebrationEntity> history;
  final String? errorMessage;

  const CelebrationsState({
    this.status = CelebrationsStatus.initial,
    this.upcoming = const [],
    this.history = const [],
    this.errorMessage,
  });

  CelebrationsState copyWith({
    CelebrationsStatus? status,
    List<CelebrationEntity>? upcoming,
    List<CelebrationEntity>? history,
    String? errorMessage,
  }) {
    return CelebrationsState(
      status: status ?? this.status,
      upcoming: upcoming ?? this.upcoming,
      history: history ?? this.history,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, upcoming, history, errorMessage];
}
