import '../../profile/domain/models/user_profile.dart';

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
  final UserProfile? profile;

  const AuthState({
    this.status = AuthStatus.initial,
    this.token,
    this.firstName,
    this.profile,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? token,
    String? firstName,
    UserProfile? profile,
  }) {
    return AuthState(
      status: status ?? this.status,
      token: token ?? this.token,
      firstName: firstName ?? this.firstName,
      profile: profile ?? this.profile,
    );
  }
}
