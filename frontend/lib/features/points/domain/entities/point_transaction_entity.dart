import 'package:equatable/equatable.dart';

class PointTransactionEntity extends Equatable {
  final dynamic
      id; // Using dynamic as backend returns mixed types (int or string likes 'batch-1')
  final String date;
  final String description;
  final String type; // Earned, Redeemed, Pending, Expired
  final String points; // Formatted string like "+100" or "-50"

  const PointTransactionEntity({
    required this.id,
    required this.date,
    required this.description,
    required this.type,
    required this.points,
  });

  @override
  List<Object?> get props => [id, date, description, type, points];
}
