import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/guard_dashboard.dart';
import '../services/guard_dashboard_service.dart';

final guardDashboardProvider =
    StateNotifierProvider<GuardDashboardNotifier, GuardDashboardState>(
  (ref) => GuardDashboardNotifier(),
);

class GuardDashboardState {
  final GuardDashboard? dashboard;
  final bool loading;
  final String? error;

  const GuardDashboardState({
    this.dashboard,
    this.loading = false,
    this.error,
  });

  GuardDashboardState copyWith({
    GuardDashboard? dashboard,
    bool? loading,
    String? error,
    bool clearError = false,
  }) {
    return GuardDashboardState(
      dashboard: dashboard ?? this.dashboard,
      loading: loading ?? this.loading,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class GuardDashboardNotifier
    extends StateNotifier<GuardDashboardState> {

  GuardDashboardNotifier()
      : super(const GuardDashboardState());

  final GuardDashboardService _service =
      GuardDashboardService();

  // ==================================================
  // Initial load
  // ==================================================

  Future<void> load() async {
    try {
      state = state.copyWith(
        loading: true,
        clearError: true,
      );

      final dashboard =
          await _service.loadDashboard();

      state = state.copyWith(
        dashboard: dashboard,
        loading: false,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: e.toString(),
      );
    }
  }

  // ==================================================
  // Background refresh
  // ==================================================

  Future<void> refresh() async {
    try {
      // IMPORTANT:
      // Do NOT set loading=true here.
      //
      // Existing dashboard remains visible while
      // fresh data is being fetched.

      final dashboard =
          await _service.loadDashboard();

      state = state.copyWith(
        dashboard: dashboard,
        loading: false,
        clearError: true,
      );
    } catch (e) {
      // Keep existing dashboard visible if
      // background refresh fails.

      state = state.copyWith(
        loading: false,
        error: e.toString(),
      );
    }
  }
}