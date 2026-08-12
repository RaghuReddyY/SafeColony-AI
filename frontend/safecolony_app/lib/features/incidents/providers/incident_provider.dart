import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/incident.dart';
import '../services/incident_service.dart';

final incidentServiceProvider = Provider((ref) => IncidentService());
final incidentsProvider = FutureProvider<List<Incident>>(
  (ref) => ref.read(incidentServiceProvider).list(),
);
