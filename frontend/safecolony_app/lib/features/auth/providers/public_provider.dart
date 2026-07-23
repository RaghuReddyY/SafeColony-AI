import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/public_service.dart';

import '../models/organization_lookup.dart';
import '../models/public_state.dart';

final publicProvider =
    StateNotifierProvider<PublicNotifier, PublicState>(
  (ref) => PublicNotifier(),
);

class PublicNotifier extends StateNotifier<PublicState> {
  PublicNotifier() : super(const PublicState());

  final PublicService _service = PublicService();

  Future<bool> lookupOrganization(
    String organizationCode,
  ) async {
    try {
      state = state.copyWith(
        isLoading: true,
        error: null,
      );

      final OrganizationLookup organization =
          await _service.getOrganization(
        organizationCode.trim(),
      );

      state = state.copyWith(
        isLoading: false,
        organization: organization,
        sections: const [],
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        organization: null,
        sections: const [],
        error: e.toString(),
      );

      return false;
    }
  }

  Future<void> loadSections(
    int propertyId,
  ) async {
    try {
      state = state.copyWith(
        isLoading: true,
        error: null,
      );

      final sections =
          await _service.getSections(propertyId);

      state = state.copyWith(
        isLoading: false,
        sections: sections,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        sections: const [],
        error: e.toString(),
      );
    }
  }

  void clear() {
    state = const PublicState();
  }
}