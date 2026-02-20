import 'package:equatable/equatable.dart';

class HrApprovalsState extends Equatable {
  final bool nomLoading;
  final List<Map<String, dynamic>> nominations;

  final bool convLoading;
  final List<Map<String, dynamic>> conversions;

  final bool mgLoading;
  final List<Map<String, dynamic>> managers;

  final String? error;
  final String? successMessage;

  const HrApprovalsState({
    this.nomLoading = false,
    this.nominations = const [],
    this.convLoading = false,
    this.conversions = const [],
    this.mgLoading = false,
    this.managers = const [],
    this.error,
    this.successMessage,
  });

  HrApprovalsState copyWith({
    bool? nomLoading,
    List<Map<String, dynamic>>? nominations,
    bool? convLoading,
    List<Map<String, dynamic>>? conversions,
    bool? mgLoading,
    List<Map<String, dynamic>>? managers,
    String? error,
    String? successMessage,
  }) {
    return HrApprovalsState(
      nomLoading: nomLoading ?? this.nomLoading,
      nominations: nominations ?? this.nominations,
      convLoading: convLoading ?? this.convLoading,
      conversions: conversions ?? this.conversions,
      mgLoading: mgLoading ?? this.mgLoading,
      managers: managers ?? this.managers,
      error: error,
      successMessage: successMessage,
    );
  }

  @override
  List<Object?> get props => [
        nomLoading,
        nominations,
        convLoading,
        conversions,
        mgLoading,
        managers,
        error,
        successMessage,
      ];
}
