import 'package:equatable/equatable.dart';

abstract class ConversionsMgmtEvent extends Equatable {
  const ConversionsMgmtEvent();
  @override
  List<Object?> get props => [];
}

class LoadPendingConversions extends ConversionsMgmtEvent {}

class ActionConversionRequested extends ConversionsMgmtEvent {
  final int id;
  final String action;
  const ActionConversionRequested({required this.id, required this.action});
  @override
  List<Object?> get props => [id, action];
}
