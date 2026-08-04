class Vacation {
  final int id;
  final String status;
 final DateTime startDate;
  final DateTime endDate;
  final String? reason;

  Vacation({
    required this.id,
    required this.status,
    required this.startDate,
    required this.endDate,
    this.reason,
  });

  factory Vacation.fromJson(Map<String, dynamic> json) {
    return Vacation(
      id: json["id"],
      status: json["status"],
      startDate: DateTime.parse(json["start_date"]),
      endDate: DateTime.parse(json["end_date"]),
      reason: json["reason"],
    );
  }
}