import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/models/user_profile.dart';
import '../domain/repositories/profile_repository.dart';
import '../infrastructure/repositories/profile_repository_impl.dart';
import '../../identity/application/auth_notifier.dart';
import '../../identity/domain/auth_state.dart';

part 'profile_provider.g.dart';

@riverpod
IProfileRepository profileRepository(Ref ref) {
  final authState = ref.watch(authProvider).value;
  return ProfileRepositoryImpl(token: authState?.token);
}

@riverpod
class ProfileNotifier extends _$ProfileNotifier {
  @override
  FutureOr<UserProfile> build() async {
    final authState = await ref.watch(authProvider.future);
    
    if (authState.status == AuthStatus.authenticated && authState.token != null) {
      final repository = ref.watch(profileRepositoryProvider);
      return repository.getProfile();
    }
    
    throw Exception('Authentication required to view profile');
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
