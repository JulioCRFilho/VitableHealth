import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../domain/auth_state.dart';

part 'auth_notifier.g.dart';

@riverpod
class AuthNotifier extends _$AuthNotifier {
  @override
  Future<AuthState> build() async {
    print('DEBUG: AuthNotifier.build() starting');
    final secureStorage = ref.watch(secureStorageServiceProvider);

    // Read from storage concurrently
    final results = await Future.wait([
      secureStorage.getToken(),
      secureStorage.getFirstName(),
    ]);
    final token = results[0];
    final firstName = results[1];

    if (token != null) {
      // Optimistic authentication: Extract data from claims first
      String? claimFirstName = firstName;
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
        unawaited(logout());
        return const AuthState(status: AuthStatus.unauthenticated);
      }

      return AuthState(
        status: AuthStatus.authenticated,
        token: token,
        firstName: claimFirstName,
      );
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

  Future<void> logout() async {
    state = const AsyncValue.loading();
    final secureStorage = ref.read(secureStorageServiceProvider);
    await secureStorage.deleteTokens();

    state = const AsyncValue.data(
      AuthState(status: AuthStatus.unauthenticated),
    );
  }

  /// Called by other features when they hit a 401
  Future<void> handleSessionExpired() async {
    await logout();
  }

  /// Helper to update the first name after a profile fetch somewhere else
  Future<void> updateFirstName(String name) async {
    if (state.hasValue) {
      final secureStorage = ref.read(secureStorageServiceProvider);
      await secureStorage.saveFirstName(name);
      state = AsyncValue.data(state.value!.copyWith(firstName: name));
    }
  }
}
