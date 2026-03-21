import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/telemedicine/presentation/telemedicine_screen.dart';
import 'package:mobile/features/identity/domain/auth_state.dart';
import 'package:mobile/features/identity/application/auth_notifier.dart';
import 'package:mobile/features/telemedicine/application/appointment_providers.dart';
import 'telemedicine_fake_repo.dart';
import 'i_am_on_the_profile_screen.dart'; // For MockAuthNotifier

/// Usage: I am on the Telemedicine screen
Future<void> iAmOnTheTelemedicineScreen(WidgetTester tester) async {
  fakeAppointmentRepository.networkFails = false; // Reset state

  final dummyAuth = AuthState(
    status: AuthStatus.authenticated,
    token: 'dummy-token',
    firstName: 'Test',
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authProvider.overrideWith(() => MockAuthNotifier(dummyAuth)),
        appointmentRepositoryProvider.overrideWithValue(fakeAppointmentRepository),
      ],
      child: const MaterialApp(
        home: Scaffold(body: TelemedicineScreen()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
