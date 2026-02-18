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
    );
  }
}

class SendRecognitionParams extends Equatable {
  final int receiverId;
  final int badgeId;
  final String? message;

  const SendRecognitionParams({
    required this.receiverId,
    required this.badgeId,
    this.message,
  });

  @override
  List<Object?> get props => [receiverId, badgeId, message];
}
