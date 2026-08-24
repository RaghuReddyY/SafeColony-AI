import '../../../core/api/api_client.dart';
import '../models/super_app.dart';

class SuperAppService {
  Future<SuperAppOverview> overview() async {
    final r = await ApiClient.dio.get('/super-app/overview');
    return SuperAppOverview.fromJson(Map<String, dynamic>.from(r.data));
  }

  Future<List<ServiceProvider>> serviceProviders({String? category}) async {
    final r = await ApiClient.dio.get(
      '/super-app/service-providers',
      queryParameters: category == null ? null : {'category': category},
    );
    return (r.data as List)
        .map((x) => ServiceProvider.fromJson(Map<String, dynamic>.from(x)))
        .toList();
  }

  Future<List<ServiceRequest>> requests() async {
    final r = await ApiClient.dio.get('/super-app/service-requests');
    return (r.data as List)
        .map((x) => ServiceRequest.fromJson(Map<String, dynamic>.from(x)))
        .toList();
  }

  Future<ServiceRequest> createRequest({
    required String category,
    required String title,
    String? description,
    String? preferredSlot,
    int? providerId,
    int? vendorId,
  }) async {
    final r = await ApiClient.dio.post(
      '/super-app/service-requests',
      data: {
        'category': category,
        'title': title,
        'description': description,
        'preferred_slot': preferredSlot,
        'provider_id': providerId,
        'vendor_id': vendorId,
      },
    );
    return ServiceRequest.fromJson(Map<String, dynamic>.from(r.data));
  }

  Future<void> updateRequest(int id, String status) async {
    await ApiClient.dio.patch('/super-app/service-requests/$id', data: {'status': status});
  }

  Future<void> createRecurring({required String category, required String description, required String cadence, String? day, String? slot}) async {
    await ApiClient.dio.post('/super-app/recurring-orders', data: {
      'category': category,
      'description': description,
      'cadence': cadence,
      'preferred_day': day,
      'preferred_slot': slot,
    });
  }

  Future<List<Parcel>> parcels() async {
    final r = await ApiClient.dio.get('/super-app/delivery-hub');
    return (r.data as List)
        .map((x) => Parcel.fromJson(Map<String, dynamic>.from(x)))
        .toList();
  }

  Future<void> pickup(int id) async {
    await ApiClient.dio.post('/super-app/delivery-hub/$id/pickup');
  }

  Future<List<UtilityProvider>> utilityProviders() async {
    final r = await ApiClient.dio.get('/super-app/utility-providers');
    return (r.data as List)
        .map((x) => UtilityProvider.fromJson(Map<String, dynamic>.from(x)))
        .toList();
  }

  Future<UtilityProvider> createUtilityProvider({
    required String name,
    required String utilityType,
    required String integrationType,
    required String status,
    String? contactName,
    String? contactEmail,
    String? contactPhone,
    String? notes,
  }) async {
    final r = await ApiClient.dio.post('/super-app/utility-providers', data: {
      'name': name,
      'utility_type': utilityType,
      'integration_type': integrationType,
      'status': status,
      'contact_name': contactName,
      'contact_email': contactEmail,
      'contact_phone': contactPhone,
      'notes': notes,
    });
    return UtilityProvider.fromJson(Map<String, dynamic>.from(r.data));
  }

  Future<UtilityProvider> updateUtilityProvider(int id, Map<String, dynamic> data) async {
    final r = await ApiClient.dio.patch('/super-app/utility-providers/$id', data: data);
    return UtilityProvider.fromJson(Map<String, dynamic>.from(r.data));
  }

  Future<List<MapPoint>> mapPoints() async {
    final r = await ApiClient.dio.get('/super-app/map-points');
    return (r.data as List)
        .map((x) => MapPoint.fromJson(Map<String, dynamic>.from(x)))
        .toList();
  }

  Future<MapPoint> createMapPoint({
    required String pointType,
    required String name,
    String? description,
    String? address,
    required double latitude,
    required double longitude,
  }) async {
    final r = await ApiClient.dio.post('/super-app/map-points', data: {
      'point_type': pointType,
      'name': name,
      'description': description,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
    });
    return MapPoint.fromJson(Map<String, dynamic>.from(r.data));
  }

  Future<MapPoint> updateMapPoint(int id, Map<String, dynamic> data) async {
    final r = await ApiClient.dio.patch('/super-app/map-points/$id', data: data);
    return MapPoint.fromJson(Map<String, dynamic>.from(r.data));
  }
}
