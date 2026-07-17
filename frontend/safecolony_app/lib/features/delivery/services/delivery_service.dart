import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../models/delivery.dart';

class DeliveryService {
  // ------------------------------------
  // Get All Deliveries
  // ------------------------------------

  Future<List<Delivery>> getDeliveries() async {
    final Response response = await ApiClient.dio.get(
      "/deliveries",
    );

    return (response.data as List)
        .map(
          (e) => Delivery.fromJson(e),
        )
        .toList();
  }

  // ------------------------------------
  // Create Delivery
  // ------------------------------------

  Future<void> createDelivery({
    required int residentId,
    required String courierName,
    required String deliveryCategory,
    String? trackingNumber,
    String priority = "NORMAL",
    String? packagePhoto,
  }) async {
    await ApiClient.dio.post(
      "/deliveries",
      data: {
        "resident_id": residentId,
        "courier_name": courierName,
        "delivery_category": deliveryCategory,
        "tracking_number": trackingNumber,
        "priority": priority,
        "package_photo": packagePhoto,
      },
    );
  }

  // ------------------------------------
  // Resident Dropdown
  // ------------------------------------

  Future<List<dynamic>> getResidents() async {
    final Response response = await ApiClient.dio.get(
      "/residents/dropdown",
    );

    return response.data;
  }

  // ------------------------------------
  // Verify OTP
  // ------------------------------------

  Future<void> verifyOtp({
    required int deliveryId,
    required String otp,
  }) async {
    await ApiClient.dio.post(
      "/deliveries/$deliveryId/verify-otp",
      data: {
        "otp": otp,
      },
    );
  }
}