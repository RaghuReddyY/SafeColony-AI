class CommunityServiceEntry {
  final int id;
  final String name;
  final String category;
  final String phone;
  final String workDescription;
  final String? notes;
  final bool isActive;
  final String? createdByName;
  final String? updatedByName;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CommunityServiceEntry({
    required this.id,
    required this.name,
    required this.category,
    required this.phone,
    required this.workDescription,
    this.notes,
    required this.isActive,
    this.createdByName,
    this.updatedByName,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CommunityServiceEntry.fromJson(Map<String, dynamic> json) {
    return CommunityServiceEntry(
      id: (json['id'] as num).toInt(),
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      workDescription: json['work_description']?.toString() ?? '',
      notes: json['notes']?.toString(),
      isActive: json['is_active'] == true,
      createdByName: json['created_by_name']?.toString(),
      updatedByName: json['updated_by_name']?.toString(),
      createdAt: DateTime.parse(json['created_at'].toString()),
      updatedAt: DateTime.parse(json['updated_at'].toString()),
    );
  }
}
