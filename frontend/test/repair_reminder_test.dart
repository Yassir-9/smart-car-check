import 'package:flutter_test/flutter_test.dart';
import 'package:car_ai_diagnosis/services/notification_service.dart';

void main() {
  test('reminder id is deterministic', () {
    expect(NotificationService.deterministicReminderId('r1'),
        NotificationService.deterministicReminderId('r1'));
  });
}
