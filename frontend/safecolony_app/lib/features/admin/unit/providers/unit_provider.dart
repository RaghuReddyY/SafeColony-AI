import '../models/unit.dart';
import '../models/unit_request.dart';
import '../services/unit_service.dart';

class UnitProvider {
  final UnitService _service = UnitService();

  Future<List<Unit>> loadUnits() async {
    return await _service.loadUnits();
  }

  Future<Unit> getUnit(int unitId) async {
    return await _service.getUnit(unitId);
  }

  Future<List<Unit>> getUnitsByProperty(
    int propertyId,
  ) async {
    return await _service.getUnitsByProperty(propertyId);
  }

  Future<List<Unit>> getUnitsBySection(
    int sectionId,
  ) async {
    return await _service.getUnitsBySection(sectionId);
  }

  Future<Unit> createUnit(UnitRequest request) async {
    return await _service.createUnit(request);
  }

  Future<Unit> updateUnit(
    int unitId,
    UnitRequest request,
  ) async {
    return await _service.updateUnit(
      unitId,
      request,
    );
  }

  Future<void> deleteUnit(int unitId) async {
    await _service.deleteUnit(unitId);
  }
}