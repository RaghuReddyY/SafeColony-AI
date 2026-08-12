class Amenity {
  final int id;
  final String name;
  final String type;
  final String? description;
  final bool active;
  Amenity({required this.id, required this.name, required this.type, this.description, required this.active});
  factory Amenity.fromJson(Map<String,dynamic> j) => Amenity(
    id: j['id'], name: j['name'] ?? '', type: j['amenity_type'] ?? '',
    description: j['description'], active: j['is_active'] ?? true,
  );
}
