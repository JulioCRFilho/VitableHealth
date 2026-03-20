import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/constants/api_constants.dart';
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
    final firstName = await _secureStorage.getFirstName();

    if (token != null) {
      // Optimistic authentication: Greet immediately if we have a token.
      // We trigger a background validation to ensure the session is still active.
      _validateAndRefresh(token);
      
      return AuthState(
        status: AuthStatus.authenticated, 
        token: token,
        firstName: firstName,
      );
    }
    
    return const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> _validateAndRefresh(String token) async {
    final baseUrl = ApiConstants.baseUrl;
    
    // 1. Check local expiration
    if (JwtDecoder.isExpired(token)) {
      await logout();
      return;
    }

    // 2. Validate with backend (Profile check)
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/profile/'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        // Session is valid. Update cached name if it changed.
        final data = jsonDecode(response.body);
        final name = data['name'] as String?;
        if (name != null) {
          final first = name.trim().split(' ').first;
          await _secureStorage.saveFirstName(first);
          if (state.value?.firstName != first) {
            final current = state.value;
            if (current != null) {
              state = AsyncValue.data(current.copyWith(firstName: first));
            }
          }
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        await logout();
      }
    } catch (e) {
    }
  }

  Future<void> login(String token) async {
    state = const AsyncValue.loading();
    await _secureStorage.saveToken(token);
    
    String? firstName;
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/api/profile/'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final name = data['name'] as String?;
        if (name != null) {
          firstName = name.trim().split(' ').first;
          await _secureStorage.saveFirstName(firstName);
        }
      }
    } catch (_) {}

    state = AsyncValue.data(AuthState(
      status: AuthStatus.authenticated,
      token: token,
      firstName: firstName,
    ));
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    await _secureStorage.deleteTokens();
    state = const AsyncValue.data(AuthState(status: AuthStatus.unauthenticated));
  }
}
