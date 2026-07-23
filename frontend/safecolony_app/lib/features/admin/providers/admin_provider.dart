import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/pending_resident.dart';
import '../services/admin_service.dart';

final adminProvider =
    StateNotifierProvider<AdminNotifier, AdminState>(
  (ref) => AdminNotifier(),
);

class AdminState {
  final bool isLoading;
  final String? error;
  final List<PendingResident> residents;

  const AdminState({
    this.isLoading = false,
    this.error,
    this.residents = const [],
  });

  AdminState copyWith({
    bool? isLoading,
    String? error,
    List<PendingResident>? residents,
  }) {
    return AdminState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      residents: residents ?? this.residents,
    );
  }
}

class AdminNotifier extends StateNotifier<AdminState> {
  AdminNotifier() : super(const AdminState());

  final AdminService _service = AdminService();

  Future<void> loadPendingResidents() async {
    try {
      state = state.copyWith(
        isLoading: true,
        error: null,
      );

      final residents =
          await _service.getPendingResidents();

      state = state.copyWith(
        isLoading: false,
        residents: residents,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> approveResident(int id) async {
    await _service.approveResident(id);
    await loadPendingResidents();
  }

  Future<void> rejectResident(int id) async {
    await _service.rejectResident(id);
    await loadPendingResidents();
  }
}