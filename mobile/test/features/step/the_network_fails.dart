import 'package:flutter_test/flutter_test.dart';
import 'telemedicine_fake_repo.dart';

/// Usage: the network fails
Future<void> theNetworkFails(WidgetTester tester) async {
  fakeAppointmentRepository.networkFails = true;
}
