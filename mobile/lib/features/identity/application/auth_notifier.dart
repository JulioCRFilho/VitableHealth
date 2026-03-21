import 'dart:async';
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
        // Don't even return the authenticated state; clear storage and return unauthenticated
        await logout();
        return const AuthState(status: AuthStatus.unauthenticated);
      }

      if (claimFirstName == null) {
        // Fallback to locally saved name if JWT doesn't have it
        claimFirstName = await secureStorage.getFirstName();
        print('DEBUG: AuthNotifier: Using persistent fallback name: $claimFirstName');
      }

      final newState = AuthState(
        status: AuthStatus.authenticated,
        token: token,
        firstName: claimFirstName,
      );
      print('DEBUG: AuthNotifier.build() initialized: status=${newState.status}, name=${newState.firstName}');
      return newState;
    }

    print('DEBUG: AuthNotifier: No token found in storage');
    return const AuthState(status: AuthStatus.unauthenticated);
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

    state = AsyncValue.data(
      AuthState(
        status: AuthStatus.authenticated,
        token: token,
        firstName: firstName,
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
    } catch (_) {
      // name not found in token
    } 

    final newState = AuthState(
      status: AuthStatus.authenticated,
      token: token,
      firstName: firstName ?? state.value?.firstName,
    );
    state = AsyncValue.data(newState);
    print('DEBUG: AuthNotifier.setUser() complete: status=${newState.status}, name=${newState.firstName}');
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    final secureStorage = ref.read(secureStorageServiceProvider);
    await secureStorage.deleteTokens();

    state = const AsyncValue.data(
      AuthState(status: AuthStatus.unauthenticated),
    );
  }

  /// Called by other features when they hit a 401
  Future<void> handleSessionExpired() => logout();

  /// Helper to update the first name after a profile fetch somewhere else
  Future<void> updateFirstName(String name) async {
    if (state.hasValue) {
      final secureStorage = ref.read(secureStorageServiceProvider);
      await secureStorage.saveFirstName(name);
      final newState = state.value!.copyWith(firstName: name);
      state = AsyncValue.data(newState);
      print('DEBUG: AuthNotifier.updateFirstName() complete: name=${newState.firstName}');
    } else {
      print('DEBUG: AuthNotifier.updateFirstName() ignored: state has no value');
    }
  }
}
