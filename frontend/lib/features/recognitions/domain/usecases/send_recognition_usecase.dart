import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/recognition_entity.dart';
import '../repositories/recognitions_repository.dart';

class SendRecognitionUseCase
    implements UseCase<RecognitionEntity, SendRecognitionParams> {
  final RecognitionsRepository repository;

  SendRecognitionUseCase(this.repository);

  @override
  Future<Either<Failure, RecognitionEntity>> call(
      SendRecognitionParams params) async {
    return await repository.sendRecognition(
      receiverId: params.receiverId,
      badgeId: params.badgeId,
      message: params.message,
      personaType: params.personaType,
      personaLabel: params.personaLabel,
    );
  }
}

class SendRecognitionParams extends Equatable {
  final int receiverId;
  final int badgeId;
  final String? message;
  final String personaType;
  final String? personaLabel;

  const SendRecognitionParams({
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
