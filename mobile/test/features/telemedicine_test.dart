// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import './step/i_am_on_the_telemedicine_screen.dart';
import './step/i_select_the_specialist.dart';
import './step/i_tap_text.dart';
import './step/i_see_text.dart';
import './step/the_network_fails.dart';

void main() {
  group('''Telemedicine Appointment Scheduling''', () {
    testWidgets('''Successful Appointment Booking''', (tester) async {
      await iAmOnTheTelemedicineScreen(tester);
      await iSelectTheSpecialist(tester, "Dr. Sarah Smith");
      await iTapText(tester, "09:00");
      await iTapText(tester, "Confirm Appointment");
      await iSeeText(tester, "Appointment booked successfully!");
    });
    testWidgets('''No Available Slots''', (tester) async {
      await iAmOnTheTelemedicineScreen(tester);
      await iSelectTheSpecialist(tester, "Dr. Busy");
      await iSeeText(tester, "No slots available for this date.");
    });
    testWidgets('''Conflicting Appointment''', (tester) async {
      await iAmOnTheTelemedicineScreen(tester);
      await iSelectTheSpecialist(tester, "Dr. Conflict");
      await iTapText(tester, "10:00");
      await iTapText(tester, "Confirm Appointment");
      await iSeeText(tester, "Failed to book: Conflict");
    });
    testWidgets('''Network Failure During Confirmation''', (tester) async {
      await iAmOnTheTelemedicineScreen(tester);
      await iSelectTheSpecialist(tester, "Dr. Sarah Smith");
      await iTapText(tester, "09:00");
      await theNetworkFails(tester);
      await iTapText(tester, "Confirm Appointment");
      await iSeeText(tester, "Failed to book: Network connection lost");
    });
  });
}
