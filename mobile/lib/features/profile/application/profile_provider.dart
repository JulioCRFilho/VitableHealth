import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/models/user_profile.dart';
import '../domain/repositories/profile_repository.dart';
import '../infrastructure/repositories/profile_repository_impl.dart';
import '../../identity/application/auth_notifier.dart';

part 'profile_provider.g.dart';

@riverpod
IProfileRepository profileRepository(Ref ref) {
  final token = ref.watch(authProvider.select((e) => e.value?.token));
  return ProfileRepositoryImpl(token: token);
}

@Riverpod(keepAlive: true)
class ProfileNotifier extends _$ProfileNotifier {
  @override
  FutureOr<UserProfile?> build() async {
    final token = ref.watch(authProvider.select((e) => e.value?.token));

    if (token != null) {
      return await _fetchProfile();
    }

    return null;
  }

  Future<UserProfile?> _fetchProfile() async {
    try {
      final profile = await ref.read(profileRepositoryProvider).getProfile();
      unawaited(ref.read(authProvider.notifier).updateFirstName(profile.name));
      unawaited(ref.read(authProvider.notifier).updateLanguage(profile.language));
      return profile;
    } catch (e) {
      // If profile fetch fails with 401/403, it's likely a session issue
      if (e.toString().contains('401') || e.toString().contains('403')) {
        ref.read(authProvider.notifier).handleSessionExpired();
      }
      rethrow;
    }
  }

  Future<void> updateProfile(UserProfile profile) async {
    try {
      final repository = ref.read(profileRepositoryProvider);
      await repository.updateProfile(profile);
      state = AsyncValue.data(profile);

      // Update first name and language in Auth state too
      unawaited(ref.read(authProvider.notifier).updateFirstName(profile.name));
      unawaited(ref.read(authProvider.notifier).updateLanguage(profile.language));
    } catch (e) {
      throw Exception(e);
    }
  }
}
