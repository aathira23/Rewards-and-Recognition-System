import 'package:equatable/equatable.dart';

abstract class NominationsEvent extends Equatable {
  const NominationsEvent();
  @override
  List<Object?> get props => [];
}

class GetAwardTypesRequested extends NominationsEvent {}

class GetUsersRequested extends NominationsEvent {}

class GetNominationsRequested extends NominationsEvent {}

class CreateNominationRequested extends NominationsEvent {
  final int nomineeId;
  final int awardTypeId;
  final String citation;
  final String? personaType;
  final String? personaLabel;
  const CreateNominationRequested({
    required this.nomineeId,
    required this.awardTypeId,
    required this.citation,
    this.personaType,
    this.personaLabel,
  });
  @override
  List<Object?> get props => [nomineeId, awardTypeId, citation, personaType, personaLabel];
}

class ApproveNominationRequested extends NominationsEvent {
  final int nominationId;
  final String? comments;
  const ApproveNominationRequested({required this.nominationId, this.comments});
  @override
  List<Object?> get props => [nominationId, comments];
}

class RejectNominationRequested extends NominationsEvent {
  final int nominationId;
  final String? comments;
  const RejectNominationRequested({required this.nominationId, this.comments});
  @override
  List<Object?> get props => [nominationId, comments];
}

class GetApprovalHistoryRequested extends NominationsEvent {}
