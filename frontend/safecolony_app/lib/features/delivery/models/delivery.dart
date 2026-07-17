class Delivery {
  final int id;
  final int residentId;
  final String courierName;
  final String? trackingNumber;
  final String deliveryCategory;
  final String? packagePhoto;
  final String priority;
  final String status;
  final String? receivedBy;
  final String? otp;
  final DateTime createdAt;
  final DateTime? collectedAt;

  Delivery({
    required this.id,
    required this.residentId,
    required this.courierName,
    this.trackingNumber,
    required this.deliveryCategory,
    this.packagePhoto,
    required this.priority,
    required this.status,
    this.receivedBy,
    this.otp,
    required this.createdAt,
    this.collectedAt,
  });

  factory Delivery.fromJson(
    Map<String, dynamic> json,
  ) {
    return Delivery(
      id: json["id"],
      residentId: json["resident_id"],
      courierName: json["courier_name"],
      trackingNumber: json["tracking_number"],
      deliveryCategory: json["delivery_category"],
      packagePhoto: json["package_photo"],
      priority: json["priority"],
      status: json["status"],
      receivedBy: json["received_by"],
      otp: json["otp"],
      createdAt: DateTime.parse(
        json["created_at"],
      ),
      collectedAt:
          json["collected_at"] == null
              ? null
              : DateTime.parse(
                  json["collected_at"],
                ),
    );
  }
}