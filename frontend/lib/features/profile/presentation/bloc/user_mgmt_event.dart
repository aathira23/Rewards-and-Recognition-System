import 'package:equatable/equatable.dart';

abstract class UserMgmtEvent extends Equatable {
  const UserMgmtEvent();
  @override
  List<Object?> get props => [];
}

class LoadUsers extends UserMgmtEvent {}

class CreateUserRequested extends UserMgmtEvent {
  final Map<String, dynamic> data;
  const CreateUserRequested({required this.data});
  @override
  List<Object?> get props => [data];
}

class UpdateUserRequested extends UserMgmtEvent {
  final int id;
  final Map<String, dynamic> data;
  const UpdateUserRequested({required this.id, required this.data});
  @override
  List<Object?> get props => [id, data];
}
