import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/amenity.dart';
import '../services/amenity_service.dart';

final amenityServiceProvider = Provider((ref) => AmenityService());
final amenitiesProvider = FutureProvider<List<Amenity>>(
  (ref) => ref.read(amenityServiceProvider).list(),
);
