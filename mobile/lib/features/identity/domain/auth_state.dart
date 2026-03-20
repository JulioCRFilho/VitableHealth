enum AuthStatus {
  initial,
  authenticated,
  unauthenticated,
  loading,
}

class AuthState {
  final AuthStatus status;
  final String? token;
  final String? firstName;

  const AuthState({
    this.status = AuthStatus.initial,
    this.token,
    this.firstName,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? token,
    String? firstName,
  }) {
    return AuthState(
      status: status ?? this.status,
      token: token ?? this.token,
      firstName: firstName ?? this.firstName,
    );
  }
}
