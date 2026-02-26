import 'package:equatable/equatable.dart';
import '../../domain/entities/nomination_entity.dart';
import '../../domain/entities/award_type_entity.dart';
import '../../../profile/domain/entities/user_entity.dart';

enum NominationsStatus { initial, loading, success, failure }

class NominationsState extends Equatable {
  final NominationsStatus status;
  final List<NominationEntity> nominations;
  final List<AwardTypeEntity> awardTypes;
  final List<UserEntity> users;
  final String? errorMessage;
  final String? successMessage;
  final List<Map<String, dynamic>> approvalHistory;
  final bool historyLoading;

  const NominationsState({
    this.status = NominationsStatus.initial,
    this.nominations = const [],
    this.awardTypes = const [],
    this.users = const [],
    this.errorMessage,
    this.successMessage,
    this.approvalHistory = const [],
    this.historyLoading = false,
  });

  NominationsState copyWith({
    NominationsStatus? status,
    List<NominationEntity>? nominations,
    List<AwardTypeEntity>? awardTypes,
    List<UserEntity>? users,
    String? errorMessage,
    String? successMessage,
    List<Map<String, dynamic>>? approvalHistory,
    bool? historyLoading,
  }) {
    return NominationsState(
      status: status ?? this.status,
      nominations: nominations ?? this.nominations,
      awardTypes: awardTypes ?? this.awardTypes,
      users: users ?? this.users,
      errorMessage: errorMessage,
      successMessage: successMessage,
      approvalHistory: approvalHistory ?? this.approvalHistory,
      historyLoading: historyLoading ?? this.historyLoading,
    );
  }

  @override
  List<Object?> get props => [
        status,
        nominations,
        awardTypes,
        users,
        errorMessage,
        successMessage,
        approvalHistory,
        historyLoading,
      ];
}
