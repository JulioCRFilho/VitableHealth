import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../domain/auth_state.dart';

part 'auth_notifier.g.dart';

@riverpod
class AuthNotifier extends _$AuthNotifier {
  late final SecureStorageService _secureStorage;

  @override
  Future<AuthState> build() async {
    _secureStorage = ref.watch(secureStorageServiceProvider);
    
    final token = await _secureStorage.getToken();
    if (token != null) {
      return AuthState(status: AuthStatus.authenticated, token: token);
    }
    
    return const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> login(String token) async {
    state = const AsyncValue.loading();
    await _secureStorage.saveToken(token);
    state = AsyncValue.data(AuthState(
      status: AuthStatus.authenticated,
      token: token,
    ));
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    await _secureStorage.deleteTokens();
    state = const AsyncValue.data(AuthState(status: AuthStatus.unauthenticated));
  }
}
