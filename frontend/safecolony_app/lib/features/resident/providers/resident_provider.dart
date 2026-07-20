import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/resident_dropdown.dart';
import '../services/resident_service.dart';

final residentProvider =
    Provider<ResidentProvider>(
  (ref) => ResidentProvider(),
);

class ResidentProvider {
  final ResidentService _service =
      ResidentService();

  Future<List<ResidentDropdown>>
      loadResidents() {
    return _service.getResidents();
  }
}