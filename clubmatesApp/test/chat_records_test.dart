import 'package:clubmates/data/chat_records.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('client ids are version 4 UUIDs the database accepts', () {
    final pattern = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    );
    final ids = {for (var i = 0; i < 200; i++) newClientId()};
    expect(ids.length, 200);
    expect(ids.every(pattern.hasMatch), isTrue);
  });

  test('photo file names match the server path rule', () {
    final name = randomToken(24);
    expect(RegExp(r'^[A-Za-z0-9_-]{8,64}$').hasMatch(name), isTrue);
  });

  test('thread previews never invent text', () {
    expect(const MateThread().preview, isNull);
    expect(
      const MateThread(lastKind: 'text', lastBody: 'Rooftop\nat 9?').preview,
      'Rooftop at 9?',
    );
    expect(
      const MateThread(lastKind: 'photo', lastMine: true).preview,
      'You: Photo',
    );
    expect(const MateThread(lastKind: 'removed').preview, 'Message removed');
  });

  test('message rows parse receipts and removal', () {
    final message = ChatMessage.fromRow({
      'id': 'a',
      'mate_id': 'm',
      'sender_id': 's',
      'client_id': null,
      'body': null,
      'image_path': null,
      'created_at': '2026-10-17T20:00:00Z',
      'read_at': '2026-10-17T20:01:00Z',
      'deleted_at': '2026-10-17T20:02:00Z',
    });
    expect(message.readAt, isNotNull);
    expect(message.removed, isTrue);
    expect(message.state, SendState.sent);
  });
}
