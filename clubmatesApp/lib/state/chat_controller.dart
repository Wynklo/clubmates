import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/chat_records.dart';
import '../data/clubmates_repository.dart';

/// One open mate thread: history, paging, sending, receipts and typing.
/// Without a repository it keeps messages on this phone only (sample mode).
class ChatController extends ChangeNotifier with WidgetsBindingObserver {
  ChatController({
    required ClubmatesRepository? api,
    required this.mateId,
    required this.myId,
    this.onActivity,
  }) : _api = api;

  static const pageSize = 30;

  final ClubmatesRepository? _api;
  final String mateId;
  final String myId;

  /// Called when the thread changes in a way the Mates list should reflect.
  final VoidCallback? onActivity;

  /// Newest first.
  final List<ChatMessage> messages = [];
  bool loading = true;
  bool loadingOlder = false;
  bool hasMore = true;
  bool otherTyping = false;
  String? error;

  final Map<String, ({Future<String> url, DateTime signedAt})> _photoUrls = {};
  RealtimeChannel? _changes;
  RealtimeChannel? _typing;
  Timer? _typingOff;
  Timer? _readSoon;
  DateTime _typingSentAt = DateTime(0);
  bool _disposed = false;

  bool get live => _api != null;

  Future<void> start() async {
    final api = _api;
    if (api == null) {
      loading = false;
      hasMore = false;
      _notify();
      return;
    }
    WidgetsBinding.instance.addObserver(this);
    _changes = api.messageChanges(
      'mate-messages:$mateId',
      mateId: mateId,
      onChange: _onChange,
    )..subscribe();
    _typing = api.typingChannel(mateId)
      ..onBroadcast(event: 'typing', callback: _onTyping)
      ..subscribe();
    await _loadLatest();
  }

  Future<void> _loadLatest() async {
    final api = _api;
    if (api == null) return;
    try {
      final page = await api.messages(mateId, limit: pageSize);
      final pending = messages.where((m) => m.state != SendState.sent);
      messages
        ..clear()
        ..addAll(pending)
        ..addAll(page);
      _sort();
      hasMore = page.length == pageSize;
      error = null;
      _scheduleRead();
    } catch (e) {
      debugPrint('Chat load failed: $e');
      error = 'Could not load messages. Check your connection.';
    }
    loading = false;
    _notify();
  }

  Future<void> loadOlder() async {
    final api = _api;
    if (api == null || loadingOlder || !hasMore || loading) return;
    final saved = messages.where((m) => m.state == SendState.sent);
    if (saved.isEmpty) return;
    final oldest = saved.last;
    loadingOlder = true;
    _notify();
    try {
      final page = await api.messages(mateId, before: oldest, limit: pageSize);
      final known = {for (final m in messages) m.id};
      messages.addAll(page.where((m) => !known.contains(m.id)));
      _sort();
      hasMore = page.length == pageSize;
    } catch (e) {
      debugPrint('Older messages failed: $e');
    }
    loadingOlder = false;
    _notify();
  }

  Future<void> send(String text) async {
    final body = text.trim();
    if (body.isEmpty) return;
    if (body.length > 1000) {
      error = 'Messages can be up to 1000 characters.';
      _notify();
      return;
    }
    await _deliver(_local(body: body));
  }

  Future<void> sendPhoto(Uint8List bytes) => _deliver(_local(photo: bytes));

  Future<void> retry(ChatMessage message) async {
    if (message.state != SendState.failed) return;
    await _deliver(message.copyWith(state: SendState.sending));
  }

  void discard(ChatMessage message) {
    messages.removeWhere((m) => m.id == message.id);
    _notify();
  }

  Future<void> unsend(ChatMessage message) async {
    if (message.senderId != myId) return;
    if (message.state != SendState.sent) {
      discard(message);
      return;
    }
    final api = _api;
    if (api == null) {
      _replace(
        ChatMessage(
          id: message.id,
          mateId: mateId,
          senderId: myId,
          createdAt: message.createdAt,
          deletedAt: DateTime.now(),
        ),
      );
      return;
    }
    try {
      _replace(await api.unsendMessage(message.id));
      onActivity?.call();
    } catch (e) {
      error = friendlyChatError(e);
      _notify();
    }
  }

  /// Lets the other mate know you are typing, at most every few seconds.
  void typing() {
    final channel = _typing;
    if (channel == null) return;
    final now = DateTime.now();
    if (now.difference(_typingSentAt) < const Duration(seconds: 3)) return;
    _typingSentAt = now;
    channel.sendBroadcastMessage(event: 'typing', payload: {'user': myId});
  }

  Future<String> photoUrl(String path) {
    final api = _api;
    if (api == null) return Future.value('');
    final cached = _photoUrls[path];
    final fresh =
        DateTime.now().difference(cached?.signedAt ?? DateTime(0)) <
        ClubmatesRepository.chatPhotoLinkLife - const Duration(minutes: 2);
    if (cached != null && fresh) return cached.url;
    final url = api.chatPhotoUrl(path);
    _photoUrls[path] = (url: url, signedAt: DateTime.now());
    url.catchError((Object _) {
      _photoUrls.remove(path);
      return '';
    });
    return url;
  }

  void clearError() {
    if (error == null) return;
    error = null;
    _notify();
  }

  ChatMessage _local({String? body, Uint8List? photo}) {
    final clientId = newClientId();
    return ChatMessage(
      id: 'local-$clientId',
      clientId: clientId,
      mateId: mateId,
      senderId: myId,
      body: body,
      createdAt: DateTime.now(),
      state: SendState.sending,
      localPhoto: photo,
    );
  }

  final Map<String, String> _uploaded = {};

  Future<void> _deliver(ChatMessage local) async {
    error = null;
    _replace(local);
    final api = _api;
    if (api == null) {
      _replace(local.copyWith(state: SendState.sent));
      return;
    }
    final clientId = local.clientId!;
    try {
      String? path;
      final photo = local.localPhoto;
      if (photo != null) {
        path = _uploaded[clientId] ??= await api.uploadChatPhoto(mateId, photo);
      }
      final saved = await api.sendMessage(
        mateId,
        body: local.body,
        imagePath: path,
        clientId: clientId,
      );
      _uploaded.remove(clientId);
      _replace(saved);
      onActivity?.call();
    } catch (e) {
      debugPrint('Chat send failed: $e');
      error = friendlyChatError(e);
      _replace(local.copyWith(state: SendState.failed));
    }
  }

  void _onChange(PostgresChangePayload payload) {
    if (payload.eventType == PostgresChangeEvent.delete) {
      final id = payload.oldRecord['id'];
      messages.removeWhere((m) => m.id == id);
      _notify();
      return;
    }
    final message = ChatMessage.fromRow(payload.newRecord);
    _replace(message);
    if (message.senderId != myId && message.readAt == null) {
      otherTyping = false;
      _scheduleRead();
    }
    onActivity?.call();
  }

  void _onTyping(Map<String, dynamic> payload) {
    final body = payload['payload'] is Map
        ? payload['payload'] as Map
        : payload;
    if (body['user'] == myId) return;
    otherTyping = true;
    _typingOff?.cancel();
    _typingOff = Timer(const Duration(seconds: 4), () {
      otherTyping = false;
      _notify();
    });
    _notify();
  }

  /// Puts [message] in place of the copy with the same id, or the local copy
  /// with the same client id, keeping the picked photo bytes so the bubble
  /// does not flash while the stored photo loads.
  void _replace(ChatMessage message) {
    final index = messages.indexWhere(
      (m) =>
          m.id == message.id ||
          (message.clientId != null && m.clientId == message.clientId),
    );
    if (index == -1) {
      messages.add(message);
    } else {
      final previous = messages[index];
      messages[index] = message.removed || message.localPhoto != null
          ? message
          : message.copyWith(localPhoto: previous.localPhoto);
    }
    _sort();
    _notify();
  }

  void _sort() {
    messages.sort((a, b) {
      final pendingA = a.state != SendState.sent;
      final pendingB = b.state != SendState.sent;
      if (pendingA != pendingB) return pendingA ? -1 : 1;
      final byTime = b.createdAt.compareTo(a.createdAt);
      return byTime != 0 ? byTime : b.id.compareTo(a.id);
    });
  }

  void _scheduleRead() {
    final api = _api;
    if (api == null) return;
    final state = WidgetsBinding.instance.lifecycleState;
    if (state != null && state != AppLifecycleState.resumed) return;
    if (!messages.any((m) => m.senderId != myId && m.readAt == null)) return;
    _readSoon?.cancel();
    _readSoon = Timer(const Duration(milliseconds: 300), () async {
      try {
        await api.markThreadRead(mateId);
        onActivity?.call();
      } catch (e) {
        debugPrint('Mark read failed: $e');
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _loadLatest();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _typingOff?.cancel();
    _readSoon?.cancel();
    final api = _api;
    if (api != null) {
      for (final channel in [_changes, _typing]) {
        if (channel != null) api.closeChannel(channel);
      }
    }
    super.dispose();
  }
}

String friendlyChatError(Object error) {
  if (error is PostgrestException) return error.message;
  if (error is StorageException) return 'That photo could not be sent.';
  return 'Not sent. Check your connection and try again.';
}
