import 'dart:async';

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
    final authState = await ref.watch(authProvider.future);

    if (authState.status == AuthStatus.authenticated && authState.token != null) {
      final repository = ref.read(profileRepositoryProvider);
      return repository.getProfile();
    }

    throw Exception('Authentication required to view profile');
  }

  Future<void> updateProfile(UserProfile profile) async {
    try {
      final repository = ref.read(profileRepositoryProvider);
      await repository.updateProfile(profile);
      state = AsyncData(profile);
    } catch (e) {
      throw Exception(e);
    }
  }
}
