import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/guard_scan_result.dart';
import '../repositories/guard_repository.dart';

class GuardState {
  final bool isLoading;
  final GuardScanResult? visitor;
  final String? error;

  const GuardState({
    this.isLoading = false,
    this.visitor,
    this.error,
  });

  GuardState copyWith({
    bool? isLoading,
    GuardScanResult? visitor,
    String? error,
  }) {
    return GuardState(
      isLoading: isLoading ?? this.isLoading,
      visitor: visitor ?? this.visitor,
      error: error,
    );
  }
}

class GuardNotifier extends StateNotifier<GuardState> {
  GuardNotifier() : super(const GuardState());

  final GuardRepository _repository = GuardRepository();

String _parseError(Object e) {
  if (e is DioException) {
    return e.response?.data["detail"] ?? "Request failed";
  }
  return e.toString();
}
  /// Validate QR
  Future<void> validateQR(String qrToken) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
    );

    try {
      final result =
          await _repository.validateQR(qrToken);

      state = state.copyWith(
        isLoading: false,
        visitor: result,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _parseError(e),
      );
    }
  }

  /// Check In
  Future<void> checkIn() async {
    if (state.visitor == null) return;

    state = state.copyWith(
      isLoading: true,
      error: null,
    );

    try {
      final result =
          await _repository.checkIn(
        state.visitor!.id,
      );

      state = state.copyWith(
        isLoading: false,
        visitor: result,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _parseError(e),
      );
    }
  }

  /// Check Out
  Future<void> checkOut() async {
    if (state.visitor == null) return;

    state = state.copyWith(
      isLoading: true,
      error: null,
    );

    try {
      final result =
          await _repository.checkOut(
        state.visitor!.id,
      );

      state = state.copyWith(
        isLoading: false,
        visitor: result,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _parseError(e),
      );
    }
  }

  void clear() {
    state = const GuardState();
  }
}

final guardProvider =
    StateNotifierProvider<
        GuardNotifier,
        GuardState>(
  (ref) => GuardNotifier(),
);

