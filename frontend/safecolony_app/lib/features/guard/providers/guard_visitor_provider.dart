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

  final List<GuardVisitor> pendingVisitors;
  final List<GuardVisitor> approvedVisitors;
  final List<GuardVisitor> insideVisitors;

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
    List<GuardVisitor>? pendingVisitors,
    List<GuardVisitor>? approvedVisitors,
    List<GuardVisitor>? insideVisitors,
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

  Future<void> loadAll({
    bool showLoading = true,
  }) async {
    try {
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

      final rawPending =
          List<GuardVisitor>.from(results[0]);

      final rawApproved =
          List<GuardVisitor>.from(results[1]);

      final rawInside =
          List<GuardVisitor>.from(results[2]);

      // ==========================================================
      // INSIDE VISITORS
      // ==========================================================

      final insideIds = <int>{};
      final insideVisitors = <GuardVisitor>[];

      for (final visitor in rawInside) {
        if (insideIds.contains(visitor.id)) {
          continue;
        }

        insideIds.add(visitor.id);
        insideVisitors.add(visitor);
      }

      // ==========================================================
      // APPROVED VISITORS
      // ==========================================================

      final approvedIds = <int>{};
      final approvedVisitors = <GuardVisitor>[];

      for (final visitor in rawApproved) {
        // Already checked in.
        if (insideIds.contains(visitor.id)) {
          continue;
        }

        if (approvedIds.contains(visitor.id)) {
          continue;
        }

        final status =
            visitor.status.toUpperCase().trim();

        if (status != 'APPROVED') {
          continue;
        }

        approvedIds.add(visitor.id);
        approvedVisitors.add(visitor);
      }

      // ==========================================================
      // PENDING VISITORS
      // ==========================================================

      final pendingIds = <int>{};
      final pendingVisitors = <GuardVisitor>[];

      for (final visitor in rawPending) {
        // Don't show an already-approved visitor here.
        if (approvedIds.contains(visitor.id)) {
          continue;
        }

        // Don't show an inside visitor here.
        if (insideIds.contains(visitor.id)) {
          continue;
        }

        if (pendingIds.contains(visitor.id)) {
          continue;
        }

        final status =
            visitor.status.toUpperCase().trim();

        if (status != 'PENDING' &&
            status != 'WAITING' &&
            status != 'PENDING_APPROVAL' &&
            status != 'WAITING_FOR_APPROVAL') {
          continue;
        }

        pendingIds.add(visitor.id);
        pendingVisitors.add(visitor);
      }

      state = state.copyWith(
        loading: false,
        clearError: true,
        pendingVisitors: pendingVisitors,
        approvedVisitors: approvedVisitors,
        insideVisitors: insideVisitors,
      );
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: e.toString(),
      );
    }
  }

  // ============================================================
  // CHECK IN
  // ============================================================

  Future<void> checkIn(int visitorId) async {
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

      rethrow;
    }
  }

  // ============================================================
  // CHECK OUT
  // ============================================================

  Future<void> checkOut(int visitorId) async {
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

      rethrow;
    }
  }
}