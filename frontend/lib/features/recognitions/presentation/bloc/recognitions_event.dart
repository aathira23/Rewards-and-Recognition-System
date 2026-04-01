import 'package:equatable/equatable.dart';

abstract class RecognitionsEvent extends Equatable {
  const RecognitionsEvent();

  @override
  List<Object?> get props => [];
}

class GetBadgesRequested extends RecognitionsEvent {}

class GetRecognitionFeedRequested extends RecognitionsEvent {}

class GetAppreciationStatsRequested extends RecognitionsEvent {}

class GetUsersRequested extends RecognitionsEvent {}

class SendRecognitionRequested extends RecognitionsEvent {
  final int receiverId;
  final int badgeId;
  final String? message;
  final String personaType;
  final String? personaLabel;

  const SendRecognitionRequested({
    required this.receiverId,
    required this.badgeId,
    required this.personaType,
    this.message,
    this.personaLabel,
  });

  @override
  List<Object?> get props =>
      [receiverId, badgeId, message, personaType, personaLabel];
}
