import '../../../core/api/api_client.dart';
import '../models/amenity.dart';

class AmenityService {
  Future<List<Amenity>> list() async {
    final r = await ApiClient.dio.get('/amenities');
    return (r.data as List).map((e) => Amenity.fromJson(Map<String,dynamic>.from(e))).toList();
  }
  Future<void> create({
    required String name,
    required String type,
    String? description,
    String? location,
    int? capacity,
  }) async {
    await ApiClient.dio.post('/amenities', data: {
      'name': name,
      'amenity_type': type,
      'description': description,
      'location': location,
      'capacity': capacity,
      'booking_required': true,
      'approval_required': true,
    });
  }

  Future<void> book(int amenityId, DateTime start, DateTime end, String purpose) async {
    await ApiClient.dio.post('/amenities/bookings', data: {
      'amenity_id': amenityId,
      'start_at': start.toUtc().toIso8601String(),
      'end_at': end.toUtc().toIso8601String(),
      'purpose': purpose,
    });
  }
}
