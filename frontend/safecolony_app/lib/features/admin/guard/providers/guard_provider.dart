import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/guard.dart';
import '../services/guard_service.dart';

final guardProvider =
StateNotifierProvider<GuardNotifier, GuardState>(
      (ref) => GuardNotifier(),
);

class GuardState {

  final bool loading;

  final List<Guard> guards;

  final String? error;

  const GuardState({

    this.loading = false,

    this.guards = const [],

    this.error,
  });

  GuardState copyWith({

    bool? loading,

    List<Guard>? guards,

    String? error,
  }) {

    return GuardState(

      loading: loading ?? this.loading,

      guards: guards ?? this.guards,

      error: error,
    );
  }
}

class GuardNotifier
    extends StateNotifier<GuardState> {

  GuardNotifier()
      : super(const GuardState());

  final GuardService service =
      GuardService();

  Future<void> loadGuards() async {

    state = state.copyWith(
      loading: true,
      error: null,
    );

    try {

      final list =
          await service.getGuards();

      state = state.copyWith(
        loading: false,
        guards: list,
      );

    } catch (e) {

      state = state.copyWith(
        loading: false,
        error: e.toString(),
      );

    }

  }

  Future<void> updateGuard({
    required int userId,
    required String fullName,
    required String email,
    required String phone,
    String? password,
  }) async {
    await service.updateGuard(
      userId: userId,
      fullName: fullName,
      email: email,
      phone: phone,
      password: password,
    );
    await loadGuards();
  }

  Future<void> createGuard({

    required String fullName,

    required String email,

    required String phone,

    required String password,

  }) async {

    await service.createGuard(

      fullName: fullName,

      email: email,

      phone: phone,

      password: password,

    );

    await loadGuards();
  }
}