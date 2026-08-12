import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/complaint.dart';
import '../services/complaint_service.dart';

final complaintServiceProvider = Provider((ref) => ComplaintService());
final complaintsProvider = FutureProvider<List<Complaint>>(
  (ref) => ref.read(complaintServiceProvider).list(),
);
