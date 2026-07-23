
class LoginResponse {

  final String accessToken;

  final String tokenType;

  final String? residentStatus;


  LoginResponse({
    required this.accessToken,
    required this.tokenType,
    this.residentStatus,
  });


  factory LoginResponse.fromJson(
      Map<String, dynamic> json,
  ) {

    return LoginResponse(
      accessToken: json["access_token"],
      tokenType: json["token_type"],
      residentStatus: json["resident_status"],
    );
  }
}