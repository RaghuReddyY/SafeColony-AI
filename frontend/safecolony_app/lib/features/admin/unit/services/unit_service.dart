import '../../../../core/api/api_client.dart';
import '../models/unit.dart';
import '../models/unit_request.dart';

class UnitService {
  Future<List<Unit>> loadUnits() async {
    final response = await ApiClient.dio.get('/units');

    return (response.data as List)
        .map((e) => Unit.fromJson(e))
        .toList();
  }

  Future<Unit> getUnit(int unitId) async {
    final response = await ApiClient.dio.get('/units/$unitId');

    return Unit.fromJson(response.data);
  }

  Future<List<Unit>> getUnitsByProperty(int propertyId) async {
    final response = await ApiClient.dio.get(
      '/units/property/$propertyId',
    );

    return (response.data as List)
        .map((e) => Unit.fromJson(e))
        .toList();
  }

  Future<List<Unit>> getUnitsBySection(int sectionId) async {
    final response = await ApiClient.dio.get(
      '/units/section/$sectionId',
    );

    return (response.data as List)
        .map((e) => Unit.fromJson(e))
        .toList();
  }

  Future<Unit> createUnit(UnitRequest request) async {
    final response = await ApiClient.dio.post(
      '/units',
      data: request.toJson(),
    );

    return Unit.fromJson(response.data);
  }

  Future<Unit> updateUnit(
    int unitId,
    UnitRequest request,
  ) async {
    final response = await ApiClient.dio.put(
      '/units/$unitId',
      data: request.toJson(),
    );

    return Unit.fromJson(response.data);
  }

  Future<void> deleteUnit(int unitId) async {
    await ApiClient.dio.delete('/units/$unitId');
  }
}