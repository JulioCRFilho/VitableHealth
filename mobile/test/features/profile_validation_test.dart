// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import './step/i_am_on_the_profile_screen.dart';
import './step/i_tap_the_button.dart';
import './step/i_enter_into_the_field.dart';
import './step/i_should_see_the_error_message.dart';
import './step/i_should_see_the_message.dart';

void main() {
  group('''Profile Validation''', () {
    testWidgets('''Name should be required''', (tester) async {
      await iAmOnTheProfileScreen(tester);
      await iTapTheButton(tester, "Edit Profile Details");
      await iEnterIntoTheField(tester, "", "Enter your full name");
      await iTapTheButton(tester, "Save");
      await iShouldSeeTheErrorMessage(tester, "Name is required");
    });
    testWidgets('''Email should be valid''', (tester) async {
      await iAmOnTheProfileScreen(tester);
      await iTapTheButton(tester, "Edit Profile Details");
      await iEnterIntoTheField(
          tester, "invalid-email", "Enter your email address");
      await iTapTheButton(tester, "Save");
      await iShouldSeeTheErrorMessage(tester, "Enter a valid email");
    });
    testWidgets('''Successful profile update''', (tester) async {
      await iAmOnTheProfileScreen(tester);
      await iTapTheButton(tester, "Edit Profile Details");
      await iEnterIntoTheField(tester, "John Doe", "Enter your full name");
      await iEnterIntoTheField(
          tester, "john@example.com", "Enter your email address");
      await iTapTheButton(tester, "Save");
      await iShouldSeeTheMessage(tester, "Profile updated!");
    });
  });
}
