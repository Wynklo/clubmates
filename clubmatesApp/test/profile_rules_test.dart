import 'package:flutter_test/flutter_test.dart';

import 'package:clubmates/data/records.dart';

void main() {
  test('adult check uses the calendar date', () {
    final today = DateTime(2026, 10, 12);
    expect(isAtLeast18(DateTime(2008, 10, 12), today), isTrue);
    expect(isAtLeast18(DateTime(2008, 10, 13), today), isFalse);
  });

  test('invalid dates are rejected', () {
    expect(parseDob(31, 2, 2000), isNull);
    expect(parseDob(2, 1, 2000), DateTime(2000, 1, 2));
  });

  test('gender labels map to server codes', () {
    expect(genderCode('Woman'), 'WOMAN');
    expect(genderCode('Non-binary'), 'NON_BINARY');
    expect(genderLabels['MAN'], 'Man');
  });
}
