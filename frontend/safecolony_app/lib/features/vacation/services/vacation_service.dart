import '../../../core/api/api_client.dart';
import '../models/vacation.dart';
import '../models/vacation_create_request.dart';

class VacationService {

  /// Get Vacation History
Future<List<Vacation>> getHistory() async {

  final response = await ApiClient.dio.get(
    "/vacation-mode/my-history",
  );

  return (response.data as List)
      .map((e) => Vacation.fromJson(e))
      .toList();
}

  /// Enable Vacation
  Future<void> enableVacation(
      VacationCreateRequest request) async {

    await ApiClient.dio.post(
      "/vacation-mode",
      data: request.toJson(),
    );
  }

  /// Cancel Vacation
  Future<void> cancel(int vacationId) async {

    await ApiClient.dio.put(
      "/vacation-mode/$vacationId/cancel",
    );
  }
}