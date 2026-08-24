class SuperAppOverview {
  final String role;
  final List<Map<String, dynamic>> services;
  final List<String> marketplaceCategories;
  final List<Map<String, dynamic>> communityDays;
  final Map<String, dynamic> hub;
  final List<Map<String, dynamic>> utilities;
  final List<UtilityProvider> supportedUtilityProviders;
  final List<MapPoint> mapPoints;

  SuperAppOverview({
    required this.role,
    required this.services,
    required this.marketplaceCategories,
    required this.communityDays,
    required this.hub,
    required this.utilities,
    required this.supportedUtilityProviders,
    required this.mapPoints,
  });

  factory SuperAppOverview.fromJson(Map<String, dynamic> j) => SuperAppOverview(
        role: j['role']?.toString() ?? '',
        services: List<Map<String, dynamic>>.from(
          (j['services'] ?? []).map((x) => Map<String, dynamic>.from(x)),
        ),
        marketplaceCategories: List<String>.from(j['marketplace_categories'] ?? []),
        communityDays: List<Map<String, dynamic>>.from(
          (j['upcoming_community_days'] ?? []).map((x) => Map<String, dynamic>.from(x)),
        ),
        hub: Map<String, dynamic>.from(j['hub'] ?? {}),
        utilities: List<Map<String, dynamic>>.from(
          (j['utilities'] ?? []).map((x) => Map<String, dynamic>.from(x)),
        ),
        supportedUtilityProviders: (j['supported_utility_providers'] as List? ?? const [])
            .map((x) => UtilityProvider.fromJson(Map<String, dynamic>.from(x)))
            .toList(),
        mapPoints: (j['map_points'] as List? ?? const [])
            .map((x) => MapPoint.fromJson(Map<String, dynamic>.from(x)))
            .toList(),
      );
}

class ServiceProvider {
  final int id;
  final String providerType;
  final String name;
  final String category;
  final String? phone;
  final String? description;
  final int? vendorId;
  final int? providerId;

  ServiceProvider({
    required this.id,
    required this.providerType,
    required this.name,
    required this.category,
    this.phone,
    this.description,
    this.vendorId,
    this.providerId,
  });

  factory ServiceProvider.fromJson(Map<String, dynamic> j) => ServiceProvider(
        id: (j['id'] as num).toInt(),
        providerType: j['provider_type']?.toString() ?? '',
        name: j['name']?.toString() ?? '',
        category: j['category']?.toString() ?? '',
        phone: j['phone']?.toString(),
        description: j['description']?.toString(),
        vendorId: (j['vendor_id'] as num?)?.toInt(),
        providerId: (j['provider_id'] as num?)?.toInt(),
      );
}

class ServiceRequest {
  final int id;
  final String category, title, status;
  final String? description, preferredSlot, providerName, vendorName;
  final double? quotedAmount;
  final int? providerId, vendorId;

  ServiceRequest({
    required this.id,
    required this.category,
    required this.title,
    required this.status,
    this.description,
    this.preferredSlot,
    this.providerName,
    this.vendorName,
    this.quotedAmount,
    this.providerId,
    this.vendorId,
  });

  factory ServiceRequest.fromJson(Map<String, dynamic> j) => ServiceRequest(
        id: (j['id'] as num).toInt(),
        category: j['category']?.toString() ?? '',
        title: j['title']?.toString() ?? '',
        status: j['status']?.toString() ?? '',
        description: j['description']?.toString(),
        preferredSlot: j['preferred_slot']?.toString(),
        providerName: j['provider_name']?.toString(),
        vendorName: j['vendor_name']?.toString(),
        quotedAmount: double.tryParse(j['quoted_amount']?.toString() ?? ''),
        providerId: (j['provider_id'] as num?)?.toInt(),
        vendorId: (j['vendor_id'] as num?)?.toInt(),
      );
}

class UtilityProvider {
  final int id;
  final String name, utilityType, integrationType, status;
  final String? contactName, contactEmail, contactPhone, notes;
  final bool isActive;

  UtilityProvider({
    required this.id,
    required this.name,
    required this.utilityType,
    required this.integrationType,
    required this.status,
    this.contactName,
    this.contactEmail,
    this.contactPhone,
    this.notes,
    required this.isActive,
  });

  factory UtilityProvider.fromJson(Map<String, dynamic> j) => UtilityProvider(
        id: (j['id'] as num).toInt(),
        name: j['name']?.toString() ?? '',
        utilityType: j['utility_type']?.toString() ?? '',
        integrationType: j['integration_type']?.toString() ?? 'MANUAL',
        status: j['status']?.toString() ?? 'ONBOARDING',
        contactName: j['contact_name']?.toString(),
        contactEmail: j['contact_email']?.toString(),
        contactPhone: j['contact_phone']?.toString(),
        notes: j['notes']?.toString(),
        isActive: j['is_active'] != false,
      );
}

class MapPoint {
  final int id;
  final String pointType, name;
  final String? description, address;
  final double latitude, longitude;
  final bool isActive;

  MapPoint({
    required this.id,
    required this.pointType,
    required this.name,
    this.description,
    this.address,
    required this.latitude,
    required this.longitude,
    required this.isActive,
  });

  factory MapPoint.fromJson(Map<String, dynamic> j) => MapPoint(
        id: (j['id'] as num).toInt(),
        pointType: j['point_type']?.toString() ?? '',
        name: j['name']?.toString() ?? '',
        description: j['description']?.toString(),
        address: j['address']?.toString(),
        latitude: double.tryParse(j['latitude']?.toString() ?? '') ?? 0,
        longitude: double.tryParse(j['longitude']?.toString() ?? '') ?? 0,
        isActive: j['is_active'] != false,
      );
}

class Parcel {
  final int id, orderId;
  final String apartmentLabel, hub, pickupCode, status;
  final DateTime? createdAt;

  Parcel({
    required this.id,
    required this.orderId,
    required this.apartmentLabel,
    required this.hub,
    required this.pickupCode,
    required this.status,
    this.createdAt,
  });

  factory Parcel.fromJson(Map<String, dynamic> j) => Parcel(
        id: (j['id'] as num).toInt(),
        orderId: (j['order_id'] as num).toInt(),
        apartmentLabel: j['apartment_label']?.toString() ?? '',
        hub: j['hub']?.toString() ?? '',
        pickupCode: j['pickup_code']?.toString() ?? '',
        status: j['status']?.toString() ?? '',
        createdAt: DateTime.tryParse(j['created_at']?.toString() ?? ''),
      );
}
