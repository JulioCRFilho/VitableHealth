import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/main.dart';
import 'package:mobile/core/routing/app_router.dart';
import 'package:mobile/features/identity/domain/auth_state.dart';
import 'package:mobile/features/identity/application/auth_notifier.dart';
import 'package:mobile/features/profile/application/profile_provider.dart';
import 'package:mobile/features/profile/presentation/profile_screen.dart';
import 'package:mobile/features/profile/domain/models/user_profile.dart';

class MockAuthNotifier extends AuthNotifier {
  final AuthState initialState;
  MockAuthNotifier(this.initialState);
  @override
  Future<AuthState> build() async => initialState;
}

class MockProfileNotifier extends ProfileNotifier {
  final UserProfile? initialProfile;
  MockProfileNotifier(this.initialProfile);
  @override
  Future<UserProfile?> build() async => initialProfile;

  @override
  Future<void> updateProfile(UserProfile profile) async {
    // Decouple state update from the current build cycle
    Future.microtask(() {
      state = AsyncValue.data(profile);
    });
  }
}

Future<void> iAmOnTheProfileScreen(WidgetTester tester) async {
  final dummyProfile = UserProfile(
    id: 'test-id',
    name: 'Test User',
    email: 'test@example.com',
    planId: 'basic',
    status: 'active',
  );

  final dummyAuth = AuthState(
    status: AuthStatus.authenticated,
    token: 'dummy-token',
    firstName: 'Test',
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authProvider.overrideWith(() => MockAuthNotifier(dummyAuth)),
        profileProvider.overrideWith(() => MockProfileNotifier(dummyProfile)),
      ],
      child: const VitableHealthApp(),
    ),
  );
  await tester.pump();
  
  appRouter.go('/profile');
  
  // Wait for the route to change without fixed durations
  for (int i = 0; i < 20; i++) {
    await tester.pump();
    if (find.byType(ProfileScreen).evaluate().isNotEmpty) break;
  }
}
