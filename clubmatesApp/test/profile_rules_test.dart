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

  test('date fields require two, two, and four digits', () {
    final today = DateTime(2026, 10, 12);
    expect(
      dobIssue('1', '', '', today: today),
      'Date needs 2 digits, like 12.',
    );
    expect(
      dobIssue('', '4', '', today: today),
      'Month needs 2 digits, like 04.',
    );
    expect(
      dobIssue('', '', '199', today: today),
      'Year needs 4 digits, like 1998.',
    );
    expect(
      dobIssue('12', '13', '1998', today: today),
      'Month must be 01 to 12.',
    );
    expect(
      dobIssue('31', '02', '2000', today: today),
      'That date does not exist.',
    );
    expect(dobIssue('12', '04', '1998', today: today), isNull);
    expect(dobIsComplete('12', '04', '1998', today: today), isTrue);
    expect(dobIsComplete('12', '4', '1998', today: today), isFalse);
  });

  test('names, phones, cities, and height stay in a simple range', () {
    expect(nameIssue('Aanya'), isNull);
    expect(nameIssue('A1'), 'Use letters only.');
    expect(phoneIssue('999999999'), 'Enter a 10-digit mobile number.');
    expect(phoneIssue('9999999999'), isNull);
    expect(phoneIssue('1234567890'), 'Enter a valid Indian mobile number.');
    expect(cityIssue(''), isNull);
    expect(cityIssue('', required: true), 'Enter a city.');
    expect(heightIssue('172'), isNull);
    expect(heightIssue('90'), 'Height should be between 120 and 220 cm.');
    expect(feetLabel(172), "5'8\"");
    expect(bioIssue('x' * 501), 'Bio should be 500 characters or less.');
  });

  test('gender labels map to server codes', () {
    expect(genderCode('Woman'), 'WOMAN');
    expect(genderCode('Non-binary'), 'NON_BINARY');
    expect(genderLabels['MAN'], 'Man');
    expect(interestCode('Women'), 'WOMAN');
    expect(interestCode('Men'), 'MAN');
    expect(interestCode('Everyone'), 'EVERYONE');
    expect(interestLabels['NON_BINARY'], 'Non-binary');
  });
}
