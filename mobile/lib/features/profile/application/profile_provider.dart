import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/models/user_profile.dart';
import '../domain/repositories/profile_repository.dart';
import '../infrastructure/repositories/profile_repository_impl.dart';
import '../../identity/application/auth_notifier.dart';
import '../../identity/domain/auth_state.dart';

part 'profile_provider.g.dart';

@riverpod
IProfileRepository profileRepository(Ref ref) {
  final authState = ref.watch(authProvider).asData?.value;
  return ProfileRepositoryImpl(token: authState?.token);
}

@riverpod
class ProfileNotifier extends _$ProfileNotifier {
  @override
  FutureOr<UserProfile> build() async {
    print('DEBUG: ProfileNotifier.build() starting');
    final authStateValue = ref.watch(authProvider);
    
    return authStateValue.when(
      data: (auth) async {
        print('DEBUG: ProfileNotifier: AuthState status is ${auth.status}');
        if (auth.status == AuthStatus.authenticated && auth.token != null) {
          try {
            final repository = ref.read(profileRepositoryProvider);
            print('DEBUG: ProfileNotifier: Calling getProfile()');
            final result = await repository.getProfile();
            print('DEBUG: ProfileNotifier: getProfile() success');
            return result;
          } catch (e) {
            print('DEBUG: ProfileNotifier: Error: $e');
            if (e.toString().contains('401')) {
              print('DEBUG: ProfileNotifier: Triggering logout due to 401');
              Future.microtask(() => ref.read(authProvider.notifier).logout());
            }
            rethrow;
          }
        }
        print('DEBUG: ProfileNotifier: Not authenticated, throwing error');
        throw Exception('Authentication required');
      },
      loading: () {
        print('DEBUG: ProfileNotifier: AuthProvider is loading');
        // Return a future that waits if we are loading
        return ref.read(authProvider.future).then((_) => build());
      },
      error: (e, st) {
        print('DEBUG: ProfileNotifier: AuthProvider error: $e');
        throw e;
      },
    );
  }

  Future<void> updateProfile(UserProfile profile) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(profileRepositoryProvider);
      await repository.updateProfile(profile);
      state = AsyncValue.data(profile);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
