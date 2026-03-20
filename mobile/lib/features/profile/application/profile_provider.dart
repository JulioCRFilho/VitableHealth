import 'dart:async';

import 'package:mobile/core/storage/secure_storage_service.dart';
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

@Riverpod(keepAlive: true)
class ProfileNotifier extends _$ProfileNotifier {
  @override
  AsyncValue<UserProfile?> build() {
    final authStatus = ref.watch(authProvider).value?.status;
    final token = ref.watch(authProvider).value?.token;

    unawaited(() async {
      if (authStatus == AuthStatus.authenticated && token != null) {
        try {
          final profile = await ref
              .read(profileRepositoryProvider)
              .getProfile();
          final first = profile.name.trim().split(' ').first;
          final currentAuth = ref.read(authProvider).value;
          if (currentAuth?.firstName != first) {
            final secureStorage = ref.read(secureStorageServiceProvider);
            secureStorage.saveFirstName(first);
          }

          state = AsyncValue.data(profile);
        } catch (e) {
          // If profile fetch fails with 401/403, it's likely a session issue
          if (e.toString().contains('401') || e.toString().contains('403')) {
            ref.read(authProvider.notifier).handleSessionExpired();
          }
          rethrow;
        }
      }
    }());

    return AsyncValue.data(null);
  }

  Future<void> updateProfile(UserProfile profile) async {
    try {
      final repository = ref.read(profileRepositoryProvider);
      await repository.updateProfile(profile);
      state = AsyncValue.data(profile);

      // Update first name in Auth state too
      unawaited(ref.read(authProvider.notifier).updateFirstName(profile.name));
    } catch (e) {
      throw Exception(e);
    }
  }
}
