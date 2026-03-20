import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/models/user_profile.dart';
import '../domain/repositories/profile_repository.dart';
import '../infrastructure/repositories/profile_repository_impl.dart';

part 'profile_provider.g.dart';

@riverpod
IProfileRepository profileRepository(Ref ref) {
  return ProfileRepositoryImpl();
}

@riverpod
class ProfileNotifier extends _$ProfileNotifier {
  @override
  FutureOr<UserProfile> build() async {
    final repository = ref.watch(profileRepositoryProvider);
    // Hardcoded user ID for demo purposes, in a real app this would come from the auth state
    return repository.getProfile("user_1_id");
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
