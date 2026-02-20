import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../data/datasources/hr_config_remote_data_source.dart';

abstract class HrConfigRepository {
  Future<Either<Failure, HrConfigData>> loadAll();

  // ── Award Types ──────────────────────────────────────────────────
  Future<Either<Failure, void>> createAwardType(Map<String, dynamic> data);
  Future<Either<Failure, void>> updateAwardType(
      int id, Map<String, dynamic> data);
  Future<Either<Failure, void>> toggleAwardType(int id, bool newActive);

  // ── Badges ───────────────────────────────────────────────────────
  Future<Either<Failure, void>> createBadge(Map<String, dynamic> data);
  Future<Either<Failure, void>> updateBadge(int id, Map<String, dynamic> data);
  Future<Either<Failure, void>> toggleBadge(int id, bool newActive);

  // ── Rewards Catalog ──────────────────────────────────────────────
  Future<Either<Failure, void>> createReward(Map<String, dynamic> data);
  Future<Either<Failure, void>> updateReward(int id, Map<String, dynamic> data);
  Future<Either<Failure, void>> toggleReward(int id, bool newActive);

  // ── Points Policy Rules ──────────────────────────────────────────
  Future<Either<Failure, void>> createPolicyRule(Map<String, dynamic> data);
  Future<Either<Failure, void>> updatePolicyRule(
      int id, Map<String, dynamic> data);

  // ── System Config ────────────────────────────────────────────────
  Future<Either<Failure, void>> updateConfigSetting(String key, String value);
}
