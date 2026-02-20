import 'package:equatable/equatable.dart';

class PointsSummaryEntity extends Equatable {
  final int balance;
  final int totalEarned;
  final int totalRedeemed;
  final int pendingCount;
  final int expiringToday;
  final int expiringThisMonth;

  const PointsSummaryEntity({
    required this.balance,
    required this.totalEarned,
    required this.totalRedeemed,
    required this.pendingCount,
    required this.expiringToday,
    required this.expiringThisMonth,
  });

  @override
  List<Object?> get props => [
        balance,
        totalEarned,
        totalRedeemed,
        pendingCount,
        expiringToday,
        expiringThisMonth
      ];
}
