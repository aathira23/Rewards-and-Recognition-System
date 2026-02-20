import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/award_type_model.dart';
import '../models/nomination_model.dart';

abstract class NominationsRemoteDataSource {
  Future<List<AwardTypeModel>> getAwardTypes();
  Future<List<NominationModel>> getNominations();
  Future<NominationModel> createNomination({
    required int nomineeId,
    required int awardTypeId,
    required String justification,
  });
  Future<void> approveNomination(int nominationId, {String? comments});
  Future<void> rejectNomination(int nominationId, {String? comments});
  Future<AwardTypeModel> createAwardType(Map<String, dynamic> data);
  Future<AwardTypeModel> updateAwardType(int id, Map<String, dynamic> data);
  Future<List<Map<String, dynamic>>> fetchApprovalHistory();
}

class NominationsRemoteDataSourceImpl implements NominationsRemoteDataSource {
  final ApiClient client;
  NominationsRemoteDataSourceImpl({required this.client});

  @override
  Future<List<AwardTypeModel>> getAwardTypes() async {
    final response = await client.get(ApiConstants.awardTypes);
    if (response.statusCode == 200) {
      final List data = response.data['data'] ?? [];
      return data.map((json) => AwardTypeModel.fromJson(json)).toList();
    }
    throw Exception('Failed to fetch award types');
  }

  @override
  Future<List<NominationModel>> getNominations() async {
    final response = await client.get('${ApiConstants.nominations}?limit=200');
    if (response.statusCode == 200) {
      final List data = response.data['data'] ?? [];
      return data.map((json) => NominationModel.fromJson(json)).toList();
    }
    throw Exception('Failed to fetch nominations');
  }

  @override
  Future<NominationModel> createNomination({
    required int nomineeId,
    required int awardTypeId,
    required String justification,
  }) async {
    final response = await client.post(
      ApiConstants.nominations,
      data: {
        'nominee_id': nomineeId,
        'award_type_id': awardTypeId,
        'justification': justification,
      },
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return NominationModel.fromJson(response.data['data']);
    }
    throw Exception('Failed to create nomination');
  }

  @override
  Future<void> approveNomination(int nominationId, {String? comments}) async {
    await client.post(
      '${ApiConstants.nominations}/$nominationId/action',
      data: {'action': 'APPROVE', if (comments != null) 'comments': comments},
    );
  }

  @override
  Future<void> rejectNomination(int nominationId, {String? comments}) async {
    await client.post(
      '${ApiConstants.nominations}/$nominationId/action',
      data: {'action': 'REJECT', if (comments != null) 'comments': comments},
    );
  }

  @override
  Future<AwardTypeModel> createAwardType(Map<String, dynamic> data) async {
    final response = await client.post(ApiConstants.awardTypes, data: data);
    if (response.statusCode == 200 || response.statusCode == 201) {
      return AwardTypeModel.fromJson(response.data['data']);
    }
    throw Exception('Failed to create award type');
  }

  @override
  Future<AwardTypeModel> updateAwardType(
      int id, Map<String, dynamic> data) async {
    final response =
        await client.put('${ApiConstants.awardTypes}$id', data: data);
    if (response.statusCode == 200) {
      return AwardTypeModel.fromJson(response.data['data']);
    }
    throw Exception('Failed to update award type');
  }

  @override
  Future<List<Map<String, dynamic>>> fetchApprovalHistory() async {
    final response = await client.get(ApiConstants.myApprovalHistory);
    if (response.statusCode == 200) {
      final List data = response.data['data'] ?? [];
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to fetch approval history');
  }
}
