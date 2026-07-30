import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/property.dart';
import '../models/property_request.dart';
import '../services/property_service.dart';

final propertyProvider =
    Provider<PropertyProvider>((ref) {
  return PropertyProvider();
});

class PropertyProvider {

  final PropertyService _service =
      PropertyService();

  Future<List<Property>> loadProperties() {
    return _service.getProperties();
  }

  Future<Property> loadProperty(
      int propertyId) {
    return _service.getProperty(
      propertyId,
    );
  }

  Future<Property> createProperty(
      PropertyRequest request) {

    return _service.createProperty(
      request,
    );
  }

  Future<Property> updateProperty(
      int propertyId,
      PropertyRequest request) {

    return _service.updateProperty(
      propertyId,
      request,
    );
  }

  Future<void> deleteProperty(
      int propertyId) {

    return _service.deleteProperty(
      propertyId,
    );
  }
  Future<Property> getProperty(int propertyId) async {
    return await _service.getProperty(propertyId);
  }
}
