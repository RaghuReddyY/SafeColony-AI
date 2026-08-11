import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../models/delivery.dart';

class DeliveryService {
  // ------------------------------------
  // Resident: Own Deliveries
  // ------------------------------------

  Future<List<Delivery>> getDeliveries() async {
    final Response response = await ApiClient.dio.get(
      "/deliveries/mine",
    );

    return (response.data as List)
        .map((e) => Delivery.fromJson(e))
        .toList();
  }

  // ------------------------------------
  // Resident: Own Profile Context
  // ------------------------------------

  Future<Map<String, dynamic>> getMyResidentProfile() async {
    final Response response = await ApiClient.dio.get(
      "/residents/profile",
    );

    return Map<String, dynamic>.from(response.data);
  }

  // ------------------------------------
  // Resident: Create Own Delivery
  // ------------------------------------
  // IMPORTANT:
  // Do not call /residents/dropdown here.
  // A resident creates a delivery for their own
  // resident profile. The backend resolves the
  // resident from the authenticated user.

  Future<Delivery> createDelivery({
    required String courierName,
    required String deliveryCategory,
    String? trackingNumber,
    String priority = "NORMAL",
    String? packagePhoto,
  }) async {
    final Response response = await ApiClient.dio.post(
      "/deliveries/resident",
      data: {
        "courier_name": courierName,
        "delivery_category": deliveryCategory,
        "tracking_number": trackingNumber,
        "priority": priority,
        "package_photo": packagePhoto,
      },
    );

    return Delivery.fromJson(response.data);
  }

  // ------------------------------------
  // Guard: Create Delivery
  // ------------------------------------

  Future<Delivery> createGuardDelivery({
    required int residentId,
    required String courierName,
    required String deliveryCategory,
    String? trackingNumber,
    String priority = "NORMAL",
    String? packagePhoto,
  }) async {
    final Response response = await ApiClient.dio.post(
      "/deliveries/guard",
      data: {
        "resident_id": residentId,
        "courier_name": courierName,
        "delivery_category": deliveryCategory,
        "tracking_number": trackingNumber,
        "priority": priority,
        "package_photo": packagePhoto,
      },
    );

    return Delivery.fromJson(response.data);
  }

  // ------------------------------------
  // Guard: Pending Deliveries
  // ------------------------------------

  Future<List<Delivery>> getGuardPendingDeliveries() async {
    final Response response = await ApiClient.dio.get(
      "/guard/pending-deliveries",
    );

    return (response.data as List)
        .map((e) => Delivery.fromJson(e))
        .toList();
  }

  // ------------------------------------
  // Guard: Verify OTP / Collect Package
  // ------------------------------------

  Future<Delivery> verifyOtp({
    required int deliveryId,
    required String otp,
  }) async {
    final Response response = await ApiClient.dio.post(
      "/guard/verify-delivery/$deliveryId",
      data: {
        "otp": otp,
      },
    );

    return Delivery.fromJson(response.data);
  }

  // ------------------------------------
  // Guard: Receive Delivery
  // ------------------------------------

  Future<Delivery> receiveDelivery({
    required int deliveryId,
    required String guardName,
  }) async {
    final Response response = await ApiClient.dio.post(
      "/guard/receive-delivery/$deliveryId",
      data: {
        "guard_name": guardName,
      },
    );

    return Delivery.fromJson(response.data);
  }

  // ------------------------------------
  // Legacy / Admin Resident Dropdown
  // ------------------------------------
  // Keep this method because other admin screens may use it.
  // Resident UI must NOT call it.

  Future<List<dynamic>> getResidents() async {
    final Response response = await ApiClient.dio.get(
      "/residents/dropdown",
    );

    return response.data;
  }
}
