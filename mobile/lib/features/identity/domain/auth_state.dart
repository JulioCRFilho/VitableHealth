enum AuthStatus {
  initial,
  authenticated,
  unauthenticated,
  loading,
}

class AuthState {
  final AuthStatus status;
  final String? token;

  const AuthState({
    this.status = AuthStatus.initial,
    this.token,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? token,
  }) {
    return AuthState(
      status: status ?? this.status,
      token: token ?? this.token,
    );
  }
}
