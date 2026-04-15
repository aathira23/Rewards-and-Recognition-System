import 'package:equatable/equatable.dart';

abstract class HrApprovalsEvent extends Equatable {
  const HrApprovalsEvent();
  @override
  List<Object?> get props => [];
}

class LoadNominations extends HrApprovalsEvent {}

class ActionNomination extends HrApprovalsEvent {
  final int id;
  final bool isApprove;
  final String? comments;

  const ActionNomination({
    required this.id,
    required this.isApprove,
    this.comments,
  });

  @override
  List<Object?> get props => [id, isApprove, comments];
}

class LoadConversions extends HrApprovalsEvent {}

class ActionConversion extends HrApprovalsEvent {
  final int id;
  final String action; // 'APPROVE' or 'REJECT'

  const ActionConversion({required this.id, required this.action});

  @override
  List<Object?> get props => [id, action];
}

class LoadManagers extends HrApprovalsEvent {}

class AllocateBudgetToManager extends HrApprovalsEvent {
  final int managerId;
  final int points;

  const AllocateBudgetToManager({
    required this.managerId,
    required this.points,
  });

  @override
  List<Object?> get props => [managerId, points];
}

class BulkAllocateBudgets extends HrApprovalsEvent {
  final int points;
  final int? departmentId;
  final String? roleFilter;

  const BulkAllocateBudgets({
    required this.points,
    this.departmentId,
    this.roleFilter,
  });

  @override
  List<Object?> get props => [points, departmentId, roleFilter];
}

/// Load all employees for life-event selection.
class LoadEmployees extends HrApprovalsEvent {}

/// Trigger a BIRTH or MARRIAGE life-event celebration for an employee.
class TriggerLifeEvent extends HrApprovalsEvent {
  final int userId;
  final String celebrationType; // 'BIRTH' or 'MARRIAGE'

  const TriggerLifeEvent({required this.userId, required this.celebrationType});

  @override
  List<Object?> get props => [userId, celebrationType];
}
