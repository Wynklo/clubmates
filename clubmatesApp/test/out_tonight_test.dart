import 'package:flutter_test/flutter_test.dart';

import 'package:clubmates/state/app_model.dart';

void main() {
  test('end of night is the next 4 AM', () {
    expect(endOfNight(DateTime(2026, 10, 16, 22)), DateTime(2026, 10, 17, 4));
    expect(endOfNight(DateTime(2026, 10, 17, 1)), DateTime(2026, 10, 17, 4));
    expect(endOfNight(DateTime(2026, 10, 17, 4)), DateTime(2026, 10, 18, 4));
    expect(endOfNight(DateTime(2026, 10, 31, 23)), DateTime(2026, 11, 1, 4));
  });

  test('status shows only while the end time is ahead', () {
    final now = DateTime.now();
    expect(tonightStatus(now.add(const Duration(hours: 1))), 'Out tonight');
    expect(tonightStatus(now.subtract(const Duration(minutes: 1))), isNull);
    expect(tonightStatus(null), isNull);
  });
}
