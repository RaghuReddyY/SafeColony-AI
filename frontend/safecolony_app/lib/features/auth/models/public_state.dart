import 'organization_lookup.dart';
import 'section_lookup.dart';

class PublicState {
  final bool isLoading;

  final OrganizationLookup? organization;

  final List<SectionLookup> sections;

  final String? error;

  const PublicState({
    this.isLoading = false,
    this.organization,
    this.sections = const [],
    this.error,
  });

  PublicState copyWith({
    bool? isLoading,
    OrganizationLookup? organization,
    List<SectionLookup>? sections,
    String? error,
  }) {
    return PublicState(
      isLoading: isLoading ?? this.isLoading,
      organization: organization ?? this.organization,
      sections: sections ?? this.sections,
      error: error,
    );
  }
}