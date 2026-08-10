import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/guard_visitor.dart';
import '../services/guard_visitor_service.dart';

final guardVisitorProvider =
    StateNotifierProvider<GuardVisitorNotifier, GuardVisitorState>(
  (ref) => GuardVisitorNotifier(),
);

class GuardVisitorState {
  final bool loading;
  final String? error;

  final List pendingVisitors;
  final List approvedVisitors;
  final List insideVisitors;

  const GuardVisitorState({
    this.loading = false,
    this.error,
    this.pendingVisitors = const [],
    this.approvedVisitors = const [],
    this.insideVisitors = const [],
  });

  GuardVisitorState copyWith({
    bool? loading,
    String? error,
    bool clearError = false,
    List? pendingVisitors,
    List? approvedVisitors,
    List? insideVisitors,
  }) {
    return GuardVisitorState(
      loading: loading ?? this.loading,
      error: clearError ? null : error ?? this.error,
      pendingVisitors:
          pendingVisitors ?? this.pendingVisitors,
      approvedVisitors:
          approvedVisitors ?? this.approvedVisitors,
      insideVisitors:
          insideVisitors ?? this.insideVisitors,
    );
  }
}

class GuardVisitorNotifier
    extends StateNotifier<GuardVisitorState> {

  GuardVisitorNotifier()
      : super(const GuardVisitorState());

  final GuardVisitorService _service =
      GuardVisitorService();

  // --------------------------------------------------
  // Load all visitors
  // --------------------------------------------------

  Future<void> loadAll({
    bool showLoading = true,
  }) async {

    try {

      // Only show loading spinner for initial/manual load.
      // Do NOT show it during 30-second background refresh.
      if (showLoading) {
        state = state.copyWith(
          loading: true,
          clearError: true,
        );
      }

      final results = await Future.wait([
        _service.loadPendingVisitors(),
        _service.loadApprovedVisitors(),
        _service.loadInsideVisitors(),
      ]);

      state = state.copyWith(
        loading: false,
        clearError: true,
        pendingVisitors: results[0],
        approvedVisitors: results[1],
        insideVisitors: results[2],
      );

    } catch (e) {

      state = state.copyWith(
        loading: false,
        error: e.toString(),
      );
    }
  }

  // --------------------------------------------------
  // Check In
  // --------------------------------------------------

  Future<void> checkIn(
    int visitorId,
  ) async {

    state = state.copyWith(
      loading: true,
      clearError: true,
    );

    try {

      await _service.checkIn(visitorId);

      await loadAll(
        showLoading: false,
      );

    } catch (e) {

      state = state.copyWith(
        loading: false,
        error: e.toString(),
      );
    }
  }

  // --------------------------------------------------
  // Check Out
  // --------------------------------------------------

  Future<void> checkOut(
    int visitorId,
  ) async {

    state = state.copyWith(
      loading: true,
      clearError: true,
    );

    try {

      await _service.checkOut(visitorId);

      await loadAll(
        showLoading: false,
      );

    } catch (e) {

      state = state.copyWith(
        loading: false,
        error: e.toString(),
      );
    }
  }
}