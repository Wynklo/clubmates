import 'dart:math';
import 'dart:typed_data';

import 'records.dart';

enum SendState { sending, sent, failed }

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.mateId,
    required this.senderId,
    required this.createdAt,
    this.clientId,
    this.body,
    this.imagePath,
    this.readAt,
    this.deletedAt,
    this.state = SendState.sent,
    this.localPhoto,
  });

  factory ChatMessage.fromRow(Map<String, dynamic> row) {
    return ChatMessage(
      id: row['id'] as String,
      mateId: row['mate_id'] as String,
      senderId: row['sender_id'] as String,
      clientId: row['client_id'] as String?,
      body: row['body'] as String?,
      imagePath: row['image_path'] as String?,
      createdAt: parseTimestamp(row['created_at']) ?? DateTime.now(),
      readAt: parseTimestamp(row['read_at']),
      deletedAt: parseTimestamp(row['deleted_at']),
    );
  }

  final String id;
  final String mateId;
  final String senderId;
  final String? clientId;
  final String? body;
  final String? imagePath;
  final DateTime createdAt;
  final DateTime? readAt;
  final DateTime? deletedAt;
  final SendState state;

  /// The picked photo, shown while it uploads.
  final Uint8List? localPhoto;

  bool get removed => deletedAt != null;
  bool get hasPhoto => imagePath != null || localPhoto != null;

  ChatMessage copyWith({SendState? state, Uint8List? localPhoto}) {
    return ChatMessage(
      id: id,
      mateId: mateId,
      senderId: senderId,
      clientId: clientId,
      body: body,
      imagePath: imagePath,
      createdAt: createdAt,
      readAt: readAt,
      deletedAt: deletedAt,
      state: state ?? this.state,
      localPhoto: localPhoto ?? this.localPhoto,
    );
  }
}

/// The Mates list summary for one thread.
class MateThread {
  const MateThread({
    this.lastBody,
    this.lastKind,
    this.lastAt,
    this.lastMine = false,
    this.unread = 0,
  });

  factory MateThread.fromRow(Map<String, dynamic> row) {
    return MateThread(
      lastBody: row['last_body'] as String?,
      lastKind: row['last_kind'] as String?,
      lastAt: parseTimestamp(row['last_at']),
      lastMine: row['last_mine'] == true,
      unread: (row['unread'] as num?)?.toInt() ?? 0,
    );
  }

  final String? lastBody;

  /// text, photo, removed, or null when nobody has written yet.
  final String? lastKind;
  final DateTime? lastAt;
  final bool lastMine;
  final int unread;

  String? get preview {
    final text = switch (lastKind) {
      'photo' => 'Photo',
      'removed' => 'Message removed',
      'text' => lastBody?.replaceAll('\n', ' '),
      _ => null,
    };
    if (text == null) return null;
    return lastMine ? 'You: $text' : text;
  }
}

const reportReasons = {
  'HARASSMENT': 'Harassment or threats',
  'INAPPROPRIATE_CONTENT': 'Inappropriate messages or photos',
  'SPAM': 'Spam or selling something',
  'SCAM': 'Scam or asking for money',
  'FAKE_PROFILE': 'Fake profile',
  'UNDERAGE': 'May be under 18',
  'OTHER': 'Something else',
};

final _random = Random.secure();

String randomToken(int length) {
  const chars =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  return String.fromCharCodes(
    List.generate(
      length,
      (_) => chars.codeUnitAt(_random.nextInt(chars.length)),
    ),
  );
}

/// A random version 4 UUID, used to make message sends safe to retry.
String newClientId() {
  final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}
