import 'package:clubmates/data/chat_records.dart';
import 'package:clubmates/data/clubs.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('club plans round-trip through the message body', () {
    expect(puneClubs, hasLength(15));
    expect(puneClubs.map((c) => c.id).toSet(), hasLength(15));
    for (final club in puneClubs) {
      final body = clubMessage(club);
      expect(body.length, lessThanOrEqualTo(1000));
      expect(body, isNot(contains('http')));
      expect(clubFromMessage(body), same(club));
    }
    expect(clubFromMessage('Want to check out a club?'), isNull);
    expect(clubFromMessage('[club:unknown] Hi'), isNull);
  });

  test('club plans read well in the Mates list and on Maps', () {
    final plunge = puneClubs.firstWhere((c) => c.id == 'plunge');
    final thread = MateThread(lastBody: clubMessage(plunge), lastKind: 'text');
    expect(thread.preview, 'Club plan: Plunge, Koregaon Park');
    expect(plunge.mapsUrl.queryParameters['query'], startsWith('Plunge, 3rd'));
  });
}
