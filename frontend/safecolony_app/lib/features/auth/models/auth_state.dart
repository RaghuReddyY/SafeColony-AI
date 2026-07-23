import 'user.dart';

class AuthState {
  final bool isLoading;
  final bool isLoggedIn;
  final String? token;
  final User? user;
  final String? error;

  // Added
  final String? residentStatus;

  const AuthState({
    this.isLoading = false,
    this.isLoggedIn = false,
    this.token,
    this.user,
    this.error,
    this.residentStatus,
  });


  AuthState copyWith({
    bool? isLoading,
    bool? isLoggedIn,
    String? token,
    User? user,
    String? error,
    String? residentStatus,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      token: token ?? this.token,
      user: user ?? this.user,
      error: error,
      residentStatus:
          residentStatus ?? this.residentStatus,
    );
  }
}