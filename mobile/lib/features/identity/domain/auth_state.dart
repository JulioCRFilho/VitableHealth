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
  final String? language;

  const AuthState({
    this.status = AuthStatus.initial,
    this.token,
    this.firstName,
    this.language,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? token,
    String? firstName,
    String? language,
  }) {
    return AuthState(
      status: status ?? this.status,
      token: token ?? this.token,
      firstName: firstName ?? this.firstName,
      language: language ?? this.language,
    );
  }
}
