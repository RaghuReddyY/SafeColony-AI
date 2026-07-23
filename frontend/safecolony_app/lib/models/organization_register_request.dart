class OrganizationRegisterRequest {
  final OrganizationInfo organization;
  final AdminInfo admin;

  OrganizationRegisterRequest({
    required this.organization,
    required this.admin,
  });

  Map<String, dynamic> toJson() {
    return {
      "organization": organization.toJson(),
      "admin": admin.toJson(),
    };
  }
}

class OrganizationInfo {
  final String name;
  final String organizationType;
  final String email;
  final String phone;
  final String address;
  final String city;
  final String state;
  final String country;
  final String pincode;

  OrganizationInfo({
    required this.name,
    required this.organizationType,
    required this.email,
    required this.phone,
    required this.address,
    required this.city,
    required this.state,
    required this.country,
    required this.pincode,
  });

  Map<String, dynamic> toJson() {
    return {
      "name": name,
      "organization_type": organizationType,
      "email": email,
      "phone": phone,
      "address": address,
      "city": city,
      "state": state,
      "country": country,
      "pincode": pincode,
    };
  }
}

class AdminInfo {
  final String fullName;
  final String email;
  final String phone;
  final String password;

  AdminInfo({
    required this.fullName,
    required this.email,
    required this.phone,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      "full_name": fullName,
      "email": email,
      "phone": phone,
      "password": password,
    };
  }
}