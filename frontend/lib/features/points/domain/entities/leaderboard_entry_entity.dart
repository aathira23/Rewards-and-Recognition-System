import 'package:equatable/equatable.dart';

class LeaderboardEntryEntity extends Equatable {
  final int userId;
  final String name;
  final int rank;
  final int score;

  const LeaderboardEntryEntity({
    required this.userId,
    required this.name,
    required this.rank,
    required this.score,
  });

  @override
  List<Object?> get props => [userId, name, rank, score];
}
