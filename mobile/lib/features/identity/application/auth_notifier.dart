import 'dart:io';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../domain/auth_state.dart';

part 'auth_notifier.g.dart';

@Riverpod(keepAlive: true)
class AuthNotifier extends _$AuthNotifier {
  @override
  Future<AuthState> build() async {
    final secureStorage = ref.watch(secureStorageServiceProvider);

    // Read from storage concurrently
    final token = await secureStorage.getToken();

    if (token != null) {
      // Optimistic authentication: Extract data from claims first
      String? claimFirstName;
      try {
        final decoded = JwtDecoder.decode(token);
        if (decoded.containsKey('name')) {
          claimFirstName = (decoded['name'] as String).split(' ').first;
        }
      } catch (e) {
        print('DEBUG: AuthNotifier: Error decoding claims: $e');
      }

      // Check local expiry only
      if (JwtDecoder.isExpired(token)) {
        print('DEBUG: AuthNotifier: Token expired locally');
        await logout();
        return AuthState(status: AuthStatus.unauthenticated, language: _getDeviceLanguage());
      }

      if (claimFirstName == null) {
        // Fallback to locally saved name if JWT doesn't have it
        claimFirstName = await secureStorage.getFirstName();
        print('DEBUG: AuthNotifier: Using persistent fallback name: $claimFirstName');
      }

      final language = await secureStorage.getLanguage() ?? _getDeviceLanguage();

      final newState = AuthState(
        status: AuthStatus.authenticated,
        token: token,
        firstName: claimFirstName,
        language: language,
      );
      print('DEBUG: AuthNotifier.build() initialized: status=${newState.status}, name=${newState.firstName}, lang=${newState.language}');
      return newState;
    }

    print('DEBUG: AuthNotifier: No token found in storage');
    final deviceLanguage = _getDeviceLanguage();
    return AuthState(status: AuthStatus.unauthenticated, language: deviceLanguage);
  }

  String _getDeviceLanguage() {
    final locale = Platform.localeName.split('_').first.toLowerCase();
    return (locale == 'pt') ? 'pt' : 'en';
  }

  Future<void> login(String token) async {
    print('DEBUG: AuthNotifier.login() starting');
    state = const AsyncValue.loading();

    final secureStorage = ref.read(secureStorageServiceProvider);
    await secureStorage.saveToken(token);

    // Try to get first name from token for immediate use
    String? firstName;
    try {
      final decoded = JwtDecoder.decode(token);
      if (decoded.containsKey('name')) {
        firstName = (decoded['name'] as String).split(' ').first;
        await secureStorage.saveFirstName(firstName);
      }
    } catch (_) {}

    final language = await secureStorage.getLanguage() ?? _getDeviceLanguage();

    state = AsyncValue.data(
      AuthState(
        status: AuthStatus.authenticated,
        token: token,
        firstName: firstName,
        language: language,
      ),
    );
    print('DEBUG: AuthNotifier.login() complete');
  }

  Future<void> setUser(String token) async {
    final secureStorage = ref.read(secureStorageServiceProvider);
    await secureStorage.saveToken(token);

    String? firstName;
    try {
      final decoded = JwtDecoder.decode(token);
      if (decoded.containsKey('name')) {
        firstName = (decoded['name'] as String).split(' ').first;
        await secureStorage.saveFirstName(firstName);
      }
    } catch (_) {}

    final language = await secureStorage.getLanguage() ?? _getDeviceLanguage();

    final newState = AuthState(
      status: AuthStatus.authenticated,
      token: token,
      firstName: firstName ?? state.value?.firstName,
      language: language,
    );
    state = AsyncValue.data(newState);
    print('DEBUG: AuthNotifier.setUser() complete: status=${newState.status}, name=${newState.firstName}, lang=${newState.language}');
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    final secureStorage = ref.read(secureStorageServiceProvider);
    await secureStorage.deleteTokens();

    state = AsyncValue.data(
      AuthState(status: AuthStatus.unauthenticated, language: _getDeviceLanguage()),
    );
  }

  Future<void> handleSessionExpired() => logout();

  Future<void> updateFirstName(String name) async {
    if (state.hasValue) {
      final secureStorage = ref.read(secureStorageServiceProvider);
      await secureStorage.saveFirstName(name);
      final newState = state.value!.copyWith(firstName: name.split(' ').first);
      state = AsyncValue.data(newState);
    }
  }

  Future<void> updateLanguage(String language) async {
    if (state.hasValue) {
      final secureStorage = ref.read(secureStorageServiceProvider);
      await secureStorage.saveLanguage(language);
      final newState = state.value!.copyWith(language: language);
      state = AsyncValue.data(newState);
      print('DEBUG: AuthNotifier.updateLanguage() complete: lang=${newState.language}');
    }
  }
}
