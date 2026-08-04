import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/vacation.dart';
import '../models/vacation_create_request.dart';
import '../services/vacation_service.dart';

final vacationProvider = Provider<VacationService>((ref) {
  return VacationService();
});

final vacationHistoryProvider =
FutureProvider<List<Vacation>>((ref) {

  return ref.read(vacationProvider).getHistory();

});

final createVacationProvider =
    FutureProvider.family<void, VacationCreateRequest>(
        (ref, request) async {

  await ref
      .read(vacationProvider)
      .enableVacation(request);

});