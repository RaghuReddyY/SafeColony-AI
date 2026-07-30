import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/section.dart';
import '../models/section_request.dart';
import '../services/section_service.dart';

final sectionProvider = Provider<SectionProvider>((ref) {
  return SectionProvider();
});

class SectionProvider {
  final SectionService _service = SectionService();

  Future<List<Section>> loadSections() {
    return _service.getSections();
  }

  Future<List<Section>> loadSectionsByProperty(int propertyId) {
    return _service.getSectionsByProperty(propertyId);
  }

  Future<Section> loadSection(int sectionId) {
    return _service.getSection(sectionId);
  }

  Future<Section> createSection(SectionRequest request) {
    return _service.createSection(request);
  }

  Future<Section> updateSection(
    int sectionId,
    SectionRequest request,
  ) {
    return _service.updateSection(
      sectionId,
      request,
    );
  }

  Future<void> deleteSection(int sectionId) {
    return _service.deleteSection(sectionId);
  }

  Future<Section> getSection(int sectionId) {
    return _service.getSection(sectionId);
  }

  Future<List<Section>> getSectionsByProperty(int propertyId) {
    return _service.getSectionsByProperty(propertyId);
  }
}