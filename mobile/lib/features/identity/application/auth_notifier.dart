import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../profile/domain/models/user_profile.dart';
import '../domain/auth_state.dart';

part 'auth_notifier.g.dart';

@riverpod
class AuthNotifier extends _$AuthNotifier {
  late final SecureStorageService _secureStorage;

  @override
  Future<AuthState> build() async {
    print('DEBUG: AuthNotifier.build() starting');
    _secureStorage = ref.watch(secureStorageServiceProvider);

    final token = await _secureStorage.getToken();
    final firstName = await _secureStorage.getFirstName();

    print(
      'DEBUG: AuthNotifier: token found: ${token != null}, firstName found: ${firstName != null}',
    );

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

      // Background validation and profile fetch
      Future.microtask(() => _validateAndRefresh(token));

      return AuthState(
        status: AuthStatus.authenticated,
        token: token,
        firstName: claimFirstName,
      );
    }

    print('DEBUG: AuthNotifier: No token found in storage');
    return const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> _validateAndRefresh(String token) async {
    print('DEBUG: AuthNotifier._validateAndRefresh() starting');
    final baseUrl = ApiConstants.baseUrl;

    if (JwtDecoder.isExpired(token)) {
      print('DEBUG: AuthNotifier: Token expired locally');
      await logout();
      return;
    }

    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/api/profile/'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final decodedToken = JwtDecoder.decode(token);
        // Try multiple sources for ID: response body, sub, uid, user_id
        final userId = data['id']?.toString() ?? 
                       decodedToken['sub']?.toString() ?? 
                       decodedToken['uid']?.toString() ?? 
                       decodedToken['user_id']?.toString() ?? 
                       '';
        final profile = UserProfile.fromMap(data, userId);

        final first = profile.name.trim().split(' ').first;
        await _secureStorage.saveFirstName(first);

        if (state.value != null) {
          state = AsyncValue.data(state.value!.copyWith(
            profile: profile,
            firstName: first,
          ));
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        await logout();
      }
    } catch (e) {
      print('DEBUG: AuthNotifier: Validation failed: $e');
    }
  }

  Future<void> login(String token) async {
    print('DEBUG: AuthNotifier.login() starting');
    state = const AsyncValue.loading();
    await _secureStorage.saveToken(token);

    try {
      final response = await http
          .get(
            Uri.parse('${ApiConstants.baseUrl}/api/profile/'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final decodedToken = JwtDecoder.decode(token);
        // Try multiple sources for ID
        final userId = data['id']?.toString() ?? 
                       decodedToken['sub']?.toString() ?? 
                       decodedToken['uid']?.toString() ?? 
                       decodedToken['user_id']?.toString() ?? 
                       '';
        final profile = UserProfile.fromMap(data, userId);
        final firstName = profile.name.trim().split(' ').first;

        await _secureStorage.saveFirstName(firstName);

        state = AsyncValue.data(
          AuthState(
            status: AuthStatus.authenticated,
            token: token,
            firstName: firstName,
            profile: profile,
          ),
        );
      } else {
        // Fallback if profile fetch fails but token is valid
        state = AsyncValue.data(
          AuthState(
            status: AuthStatus.authenticated,
            token: token,
          ),
        );
      }
    } catch (e) {
      print('DEBUG: AuthNotifier: Login profile fetch failed: $e');
      state = AsyncValue.data(
        AuthState(
          status: AuthStatus.authenticated,
          token: token,
        ),
      );
    }
    print('DEBUG: AuthNotifier.login() complete');
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    await _secureStorage.deleteTokens();
    state = const AsyncValue.data(
      AuthState(status: AuthStatus.unauthenticated),
    );
  }
}
