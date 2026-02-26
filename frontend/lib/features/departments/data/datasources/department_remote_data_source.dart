import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/department_model.dart';

abstract class DepartmentRemoteDataSource {
  Future<List<DepartmentModel>> getDepartments();
  Future<DepartmentModel> createDepartment(String name);
  Future<DepartmentModel> updateDepartment(int id, String name);
  Future<void> deleteDepartment(int id);
}

class DepartmentRemoteDataSourceImpl implements DepartmentRemoteDataSource {
  final ApiClient client;

  DepartmentRemoteDataSourceImpl({required this.client});

  @override
  Future<List<DepartmentModel>> getDepartments() async {
    final response = await client.get(ApiConstants.departments);
    final List data = response.data['data'] ?? [];
    return data
        .map((json) => DepartmentModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<DepartmentModel> createDepartment(String name) async {
    final response = await client.post(
      ApiConstants.departments,
      data: {'name': name},
    );
    return DepartmentModel.fromJson(
      (response.data['data'] ?? response.data) as Map<String, dynamic>,
    );
  }

  @override
  Future<DepartmentModel> updateDepartment(int id, String name) async {
    final response = await client.patch(
      '${ApiConstants.departments}$id',
      data: {'name': name},
    );
    return DepartmentModel.fromJson(
      (response.data['data'] ?? response.data) as Map<String, dynamic>,
    );
  }

  @override
  Future<void> deleteDepartment(int id) async {
    await client.delete('${ApiConstants.departments}$id');
  }
}
