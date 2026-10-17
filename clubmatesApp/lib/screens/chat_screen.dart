import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../state/app_model.dart';
import '../theme/theme.dart';
import '../ui/club_icon.dart';
import '../ui/liquid_glass.dart' show ClubChrome;
import '../ui/widgets.dart';
import 'people_screens.dart' show ActivityLine;

class MateChatScreen extends StatefulWidget {
  const MateChatScreen({super.key});

  @override
  State<MateChatScreen> createState() => _MateChatScreenState();
}

class _MateChatScreenState extends State<MateChatScreen> {
  final _text = TextEditingController();
  final _scroll = ScrollController();
  var _plansOpen = false;
  var _hidden = false;
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onStateChange: (state) {
        final hidden = state != AppLifecycleState.resumed;
        if (hidden != _hidden) setState(() => _hidden = hidden);
      },
    );
    _scroll.addListener(() {
      final position = _scroll.position;
      if (position.pixels > position.maxScrollExtent - 400) {
        AppScope.read(context).chat?.loadOlder();
      }
    });
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _text.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send(ChatController chat) {
    final text = _text.text;
    if (text.trim().isEmpty) return;
    _text.clear();
    setState(() => _plansOpen = false);
    chat.send(text);
    _toBottom();
  }

  void _sendPlan(ChatController chat, String text) {
    setState(() => _plansOpen = false);
    chat.send(text);
    _toBottom();
  }

  void _toBottom() {
    if (!_scroll.hasClients) return;
    _scroll.animateTo(
      0,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final model = AppScope.watch(context);
    final chat = model.chat;
    final person = model.opened ?? riya;
    if (chat == null) return const Scaffold(backgroundColor: ClubColors.paper);
    final headerHeight = _headerHeight(context);
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [ClubColors.paper, Color(0xFFF8F2F7)],
            stops: [0.2, 1],
          ),
        ),
        child: ListenableBuilder(
          listenable: chat,
          builder: (context, _) => Stack(
            children: [
              Column(
                children: [
                  SizedBox(height: headerHeight),
                  Expanded(
                    child: chat.loading
                        ? const Center(
                            child: ClubPulse(color: ClubColors.brand, size: 7),
                          )
                        : _Thread(chat: chat, person: person, scroll: _scroll),
                  ),
                  if (chat.error != null || model.errorMessage != null)
                    _ErrorLine(
                      text: chat.error ?? model.errorMessage!,
                      onDismiss: () {
                        chat.clearError();
                        if (model.errorMessage != null) {
                          model.go(AppRoute.mateChat);
                        }
                      },
                    ),
                  _Composer(
                    controller: _text,
                    name: person.name,
                    onChanged: (_) => chat.typing(),
                    onSend: () => _send(chat),
                  ),
                ],
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _Header(
                  person: person,
                  typing: chat.otherTyping,
                  plansOpen: _plansOpen,
                  onBack: () => model.go(AppRoute.mates),
                  onProfile: () => model.go(AppRoute.mateProfile),
                  onPlans: () => setState(() => _plansOpen = !_plansOpen),
                  onMore: () => _showChatMenu(context, model, person),
                ),
              ),
              if (_plansOpen)
                Positioned(
                  top: headerHeight + 8,
                  left: 12,
                  right: 12,
                  child: _PlanMenu(
                    onClubs: () => _sendPlan(
                      chat,
                      'Want to check out a club together tonight?',
                    ),
                    onDrinks: () =>
                        _sendPlan(chat, 'Up for drinks nearby tonight?'),
                  ),
                ),
              if (_hidden) const Positioned.fill(child: _PrivacyCover()),
            ],
          ),
        ),
      ),
    );
  }
}

/// Covers the thread while the app is in the background so the app switcher
/// snapshot never shows a conversation.
class _PrivacyCover extends StatelessWidget {
  const _PrivacyCover();

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: ColoredBox(
          color: ClubColors.paper.withValues(alpha: 0.85),
          child: const Center(child: Wordmark()),
        ),
      ),
    );
  }
}

double _headerHeight(BuildContext context) {
  final top = MediaQuery.paddingOf(context).top;
  return (top < 12 ? 12.0 : top) + 44 + 10;
}

// ---------------------------------------------------------------------------
// Thread
// ---------------------------------------------------------------------------

class _Thread extends StatelessWidget {
  const _Thread({
    required this.chat,
    required this.person,
    required this.scroll,
  });

  final ChatController chat;
  final Person person;
  final ScrollController scroll;

  @override
  Widget build(BuildContext context) {
    final messages = chat.messages;
    final mine = chat.myId;
    final latestMine = messages
        .where((m) => m.senderId == mine && m.state == SendState.sent)
        .firstOrNull;
    final items = <Widget>[
      if (chat.otherTyping)
        const Padding(
          padding: EdgeInsets.only(top: 6),
          child: Align(alignment: Alignment.centerLeft, child: _TypingDots()),
        ),
    ];
    for (var i = 0; i < messages.length; i++) {
      final message = messages[i];
      final newer = i > 0 ? messages[i - 1] : null;
      final older = i + 1 < messages.length ? messages[i + 1] : null;
      final isMine = message.senderId == mine;
      final endsGroup =
          newer == null ||
          newer.senderId != message.senderId ||
          newer.createdAt.difference(message.createdAt).inMinutes > 5;
      items.add(
        Padding(
          padding: EdgeInsets.only(top: endsGroup ? 10 : 3),
          child: _MessageRow(
            message: message,
            mine: isMine,
            tail: endsGroup,
            status: _statusFor(message, isMine, latestMine),
            chat: chat,
            person: person,
          ),
        ),
      );
      if (older == null || !_sameDay(older.createdAt, message.createdAt)) {
        items.add(
          Padding(
            padding: const EdgeInsets.only(top: 18, bottom: 4),
            child: Center(child: _DayPill(_dayLabel(message.createdAt))),
          ),
        );
      }
    }
    if (chat.loadingOlder) {
      items.add(
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Center(child: ClubPulse(color: ClubColors.brand, size: 5)),
        ),
      );
    } else if (!chat.hasMore) {
      items.add(_Intro(name: person.name));
    }
    return ListView.builder(
      controller: scroll,
      reverse: true,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
      itemCount: items.length,
      itemBuilder: (context, index) => items[index],
    );
  }

  String? _statusFor(ChatMessage message, bool isMine, ChatMessage? latest) {
    if (!isMine || message.removed) return null;
    return switch (message.state) {
      SendState.sending => 'Sending…',
      SendState.failed => 'Not sent. Tap to retry.',
      SendState.sent when identical(message, latest) =>
        message.readAt != null ? 'Read' : 'Delivered',
      SendState.sent => null,
    };
  }
}

class _Intro extends StatelessWidget {
  const _Intro({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Column(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFFF5ECF7),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const SizedBox.square(
              dimension: 44,
              child: Center(
                child: ClubIcon('mates', size: 22, color: ClubColors.brand),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'You and $name are mates',
            textAlign: TextAlign.center,
            style: ClubType.lora(19, height: 1.2),
          ),
          const SizedBox(height: 6),
          Text(
            'Start with a plan, not just “hey”. Only the two of you can see '
            'this chat. Never send money or share passwords.',
            textAlign: TextAlign.center,
            style: ClubType.inter(12, color: ClubColors.muted, height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _MessageRow extends StatelessWidget {
  const _MessageRow({
    required this.message,
    required this.mine,
    required this.tail,
    required this.status,
    required this.chat,
    required this.person,
  });

  final ChatMessage message;
  final bool mine;
  final bool tail;
  final String? status;
  final ChatController chat;
  final Person person;

  @override
  Widget build(BuildContext context) {
    final failed = message.state == SendState.failed;
    return Column(
      crossAxisAlignment: mine
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: failed ? () => chat.retry(message) : null,
          onLongPress: () {
            HapticFeedback.selectionClick();
            _showMessageActions(context, chat, message, person, mine: mine);
          },
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: message.state == SendState.sending ? 0.7 : 1,
            child: _Bubble(
              message: message,
              mine: mine,
              tail: tail,
              chat: chat,
            ),
          ),
        ),
        if (status != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, right: 4, left: 4),
            child: Text(
              status!,
              style: ClubType.inter(
                10,
                weight: FontWeight.w600,
                color: failed
                    ? ClubColors.error
                    : status == 'Read'
                    ? ClubColors.brand
                    : ClubColors.muted,
              ),
            ),
          ),
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.message,
    required this.mine,
    required this.tail,
    required this.chat,
  });

  final ChatMessage message;
  final bool mine;
  final bool tail;
  final ChatController chat;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(20),
      topRight: const Radius.circular(20),
      bottomLeft: Radius.circular(!mine && tail ? 6 : 20),
      bottomRight: Radius.circular(mine && tail ? 6 : 20),
    );
    final maxWidth = MediaQuery.sizeOf(context).width * 0.76;
    final time = TimeOfDay.fromDateTime(
      message.createdAt.toLocal(),
    ).format(context);

    if (message.removed) {
      return DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          border: Border.all(color: ClubColors.border),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          child: Text(
            mine ? 'You unsent a message' : 'Message removed',
            style: ClubType.inter(
              13,
              color: ClubColors.muted,
            ).copyWith(fontStyle: FontStyle.italic),
          ),
        ),
      );
    }

    final textColor = mine ? ClubColors.paper : ClubColors.ink;
    final body = message.body;
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: mine
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2A1B2E), Color(0xFF1A1A1A)],
                )
              : null,
          color: mine ? null : ClubColors.field,
          borderRadius: radius,
          boxShadow: const [
            BoxShadow(
              color: Color(0x12281921),
              blurRadius: 18,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (message.hasPhoto) _ChatPhoto(message: message, chat: chat),
              Padding(
                padding: EdgeInsets.fromLTRB(14, body == null ? 6 : 10, 12, 8),
                child: Wrap(
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.end,
                  spacing: 8,
                  children: [
                    if (body != null)
                      Text(
                        body,
                        style: ClubType.inter(
                          15,
                          height: 1.38,
                          color: textColor,
                        ),
                      ),
                    Text(
                      time,
                      style: ClubType.inter(
                        10,
                        height: 1.6,
                        color: textColor.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatPhoto extends StatelessWidget {
  const _ChatPhoto({required this.message, required this.chat});

  final ChatMessage message;
  final ChatController chat;

  @override
  Widget build(BuildContext context) {
    const size = Size(232, 290);
    final local = message.localPhoto;
    final placeholder = Container(
      width: size.width,
      height: size.height,
      color: const Color(0xFFEDE6EE),
      alignment: Alignment.center,
      child: const ClubPulse(color: ClubColors.brand, size: 5),
    );
    Widget image;
    if (local != null) {
      image = Image.memory(
        local,
        width: size.width,
        height: size.height,
        fit: BoxFit.cover,
        gaplessPlayback: true,
      );
    } else {
      image = FutureBuilder<String>(
        future: chat.photoUrl(message.imagePath!),
        builder: (context, snapshot) {
          final url = snapshot.data;
          if (url == null || url.isEmpty) return placeholder;
          return Image.network(
            url,
            width: size.width,
            height: size.height,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            loadingBuilder: (context, child, progress) =>
                progress == null ? child : placeholder,
            errorBuilder: (context, error, stack) => placeholder,
          );
        },
      );
    }
    return GestureDetector(
      onTap: () => _openPhoto(context, image),
      child: Hero(tag: 'chat-photo-${message.id}', child: image),
    );
  }

  void _openPhoto(BuildContext context, Widget image) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (context, _, _) => Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              Positioned.fill(
                child: InteractiveViewer(
                  maxScale: 4,
                  child: Center(
                    child: Hero(
                      tag: 'chat-photo-${message.id}',
                      child: FittedBox(child: image),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: MediaQuery.paddingOf(context).top + 8,
                left: 16,
                child: GlassIconButton(
                  icon: 'close',
                  clear: true,
                  tooltip: 'Close',
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _beat = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _beat.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Typing',
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: ClubColors.field,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
            bottomLeft: Radius.circular(6),
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x12281921),
              blurRadius: 18,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: AnimatedBuilder(
            animation: _beat,
            builder: (context, _) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < 3; i++) ...[
                  if (i > 0) const SizedBox(width: 5),
                  Transform.translate(
                    offset: Offset(0, -3 * _bounce(_beat.value - i * 0.15)),
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: ClubColors.brand.withValues(
                          alpha: 0.35 + 0.5 * _bounce(_beat.value - i * 0.15),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  double _bounce(double t) {
    final x = t % 1;
    return x < 0.4 ? Curves.easeOut.transform(1 - (x - 0.2).abs() / 0.2) : 0;
  }
}

class _DayPill extends StatelessWidget {
  const _DayPill(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xCCFFFFFF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0x0F1A1A1A)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        child: Text(
          label,
          style: ClubType.inter(
            11,
            color: ClubColors.muted,
            weight: FontWeight.w600,
            height: 1,
          ),
        ),
      ),
    );
  }
}

bool _sameDay(DateTime a, DateTime b) {
  final x = a.toLocal();
  final y = b.toLocal();
  return x.year == y.year && x.month == y.month && x.day == y.day;
}

String _dayLabel(DateTime when) {
  final day = when.toLocal();
  final now = DateTime.now();
  if (_sameDay(day, now)) return 'Today';
  if (_sameDay(day, now.subtract(const Duration(days: 1)))) return 'Yesterday';
  const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final label =
      '${weekdays[day.weekday - 1]} ${day.day} ${months[day.month - 1]}';
  return day.year == now.year ? label : '$label ${day.year}';
}

// ---------------------------------------------------------------------------
// Header, plans, composer
// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  const _Header({
    required this.person,
    required this.typing,
    required this.plansOpen,
    required this.onBack,
    required this.onProfile,
    required this.onPlans,
    required this.onMore,
  });

  final Person person;
  final bool typing;
  final bool plansOpen;
  final VoidCallback onBack;
  final VoidCallback onProfile;
  final VoidCallback onPlans;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final activity = tonightStatus(person.outTonightUntil);
    return _Frosted(
      child: SizedBox(
        height: _headerHeight(context),
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, top < 12 ? 12 : top, 16, 10),
          child: Row(
            children: [
              GlassIconButton(onPressed: onBack),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: onProfile,
                  borderRadius: BorderRadius.circular(14),
                  child: Row(
                    children: [
                      ProfilePhoto(
                        person.photo,
                        width: 38,
                        height: 38,
                        radius: 19,
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              person.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: ClubType.inter(
                                15,
                                weight: FontWeight.w700,
                                height: 1.1,
                              ),
                            ),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 180),
                              child: typing
                                  ? Padding(
                                      key: const ValueKey('typing'),
                                      padding: const EdgeInsets.only(top: 3),
                                      child: Text(
                                        'typing…',
                                        style: ClubType.inter(
                                          11,
                                          weight: FontWeight.w600,
                                          color: ClubColors.brand,
                                          height: 1,
                                        ),
                                      ),
                                    )
                                  : activity != null
                                  ? Padding(
                                      key: const ValueKey('activity'),
                                      padding: const EdgeInsets.only(top: 3),
                                      child: ActivityLine(activity, size: 9),
                                    )
                                  : const SizedBox(key: ValueKey('none')),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              GlassIconButton(
                icon: plansOpen ? 'close' : 'plus',
                tooltip: 'Plan something',
                onPressed: onPlans,
              ),
              const SizedBox(width: 8),
              GlassIconButton(icon: 'more', tooltip: 'More', onPressed: onMore),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanMenu extends StatelessWidget {
  const _PlanMenu({required this.onClubs, required this.onDrinks});

  final VoidCallback onClubs;
  final VoidCallback onDrinks;

  @override
  Widget build(BuildContext context) {
    return _Frosted(
      radius: 24,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Eyebrow('Make a plan'),
            const SizedBox(height: 4),
            Text('Send a plan', style: ClubType.lora(21, height: 1.15)),
            const SizedBox(height: 12),
            _PlanRow(
              index: '01',
              title: 'Check out a club together',
              subtitle: 'Sends: Want to check out a club together tonight?',
              onPressed: onClubs,
            ),
            _PlanRow(
              index: '02',
              title: 'Drinks nearby',
              subtitle: 'Sends: Up for drinks nearby tonight?',
              onPressed: onDrinks,
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanRow extends StatelessWidget {
  const _PlanRow({
    required this.index,
    required this.title,
    required this.subtitle,
    required this.onPressed,
  });

  final String index;
  final String title;
  final String subtitle;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        constraints: const BoxConstraints(minHeight: 62),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0x171A1A1A))),
        ),
        child: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFFF8F1F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: SizedBox.square(
                dimension: 36,
                child: Center(
                  child: Text(
                    index,
                    style: ClubType.inter(
                      10,
                      color: ClubColors.brand,
                      weight: FontWeight.w700,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: ClubType.inter(13, weight: FontWeight.w600),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: ClubType.inter(11, color: ClubColors.muted),
                  ),
                ],
              ),
            ),
            const ClubIcon('send', size: 17, color: ClubColors.brand),
          ],
        ),
      ),
    );
  }
}

class _ErrorLine extends StatelessWidget {
  const _ErrorLine({required this.text, required this.onDismiss});

  final String text;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 0, 20, 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: ClubType.inter(12, color: ClubColors.error, height: 1.35),
            ),
          ),
          IconButton(
            onPressed: onDismiss,
            tooltip: 'Dismiss',
            icon: const ClubIcon('close', size: 16, color: ClubColors.muted),
          ),
        ],
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.name,
    required this.onChanged,
    required this.onSend,
  });

  final TextEditingController controller;
  final String name;
  final ValueChanged<String> onChanged;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final home = MediaQuery.paddingOf(context).bottom;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final bottom = keyboard > 0 ? 8.0 : (home < 24 ? 24.0 : home);
    const shadow = [
      BoxShadow(color: Color(0x1A000000), blurRadius: 30, offset: Offset(0, 8)),
    ];
    return Padding(
      padding: EdgeInsets.fromLTRB(14, 4, 14, bottom),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: ClubColors.field,
                borderRadius: BorderRadius.all(Radius.circular(24)),
                boxShadow: shadow,
              ),
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                keyboardType: TextInputType.multiline,
                inputFormatters: [LengthLimitingTextInputFormatter(1000)],
                onChanged: onChanged,
                style: ClubType.inter(16, height: 1.3),
                decoration: InputDecoration(
                  hintText: 'Message $name',
                  hintStyle: ClubType.inter(
                    16,
                    height: 1.3,
                    color: const Color(0xFFB5B0B4),
                  ),
                  isCollapsed: true,
                  contentPadding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) {
              final ready = value.text.trim().isNotEmpty;
              return Tooltip(
                message: 'Send message',
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutBack,
                  scale: ready ? 1 : 0.92,
                  child: Material(
                    color: ready ? ClubColors.brand : const Color(0xFFD9D3D8),
                    shape: const CircleBorder(),
                    elevation: ready ? 6 : 0,
                    shadowColor: const Color(0x55994EA8),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: ready ? onSend : null,
                      child: const SizedBox.square(
                        dimension: 48,
                        child: Center(
                          child: ClubIcon(
                            'send',
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Frosted extends StatelessWidget {
  const _Frosted({required this.child, this.radius = 0});

  final Widget child;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final reduce = ClubChrome.reduceTransparency(context);
    final shape = BorderRadius.circular(radius);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: shape,
        boxShadow: radius == 0
            ? null
            : const [
                BoxShadow(
                  color: Color(0x2E281921),
                  blurRadius: 50,
                  offset: Offset(0, 18),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: shape,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: reduce ? 0 : 24,
            sigmaY: reduce ? 0 : 24,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: reduce ? ClubColors.paper : const Color(0xE0FFFFFF),
              borderRadius: shape,
              border: radius == 0
                  ? const Border(bottom: BorderSide(color: Color(0x141A1A1A)))
                  : null,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sheets: message actions, chat menu, report
// ---------------------------------------------------------------------------

class _SheetRow extends StatelessWidget {
  const _SheetRow({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.caption,
    this.danger = false,
  });

  final String icon;
  final String label;
  final String? caption;
  final VoidCallback onPressed;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? ClubColors.error : ClubColors.ink;
    return InkWell(
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        child: Row(
          children: [
            ClubIcon(icon, size: 21, color: color),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: ClubType.inter(
                      15,
                      weight: FontWeight.w500,
                      color: color,
                    ),
                  ),
                  if (caption != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      caption!,
                      style: ClubType.inter(12, color: ClubColors.muted),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _showSheet(BuildContext context, List<Widget> rows) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: ClubColors.paper,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [...rows, const SizedBox(height: 8)],
      ),
    ),
  );
}

void _showMessageActions(
  BuildContext context,
  ChatController chat,
  ChatMessage message,
  Person person, {
  required bool mine,
}) {
  final body = message.body;
  _showSheet(context, [
    if (message.state == SendState.failed) ...[
      _SheetRow(
        icon: 'retry',
        label: 'Try again',
        onPressed: () {
          Navigator.pop(context);
          chat.retry(message);
        },
      ),
      _SheetRow(
        icon: 'trash',
        label: 'Delete',
        danger: true,
        onPressed: () {
          Navigator.pop(context);
          chat.discard(message);
        },
      ),
    ],
    if (body != null && !message.removed)
      _SheetRow(
        icon: 'copy',
        label: 'Copy',
        onPressed: () {
          Clipboard.setData(ClipboardData(text: body));
          Navigator.pop(context);
        },
      ),
    if (mine && message.state == SendState.sent && !message.removed)
      _SheetRow(
        icon: 'undo',
        label: 'Unsend',
        caption: 'Removes it for both of you.',
        danger: true,
        onPressed: () {
          Navigator.pop(context);
          chat.unsend(message);
        },
      ),
    if (!mine && !message.removed)
      _SheetRow(
        icon: 'flag',
        label: 'Report message',
        danger: true,
        onPressed: () {
          Navigator.pop(context);
          showReportSheet(context, person, messageId: message.id);
        },
      ),
  ]);
}

void _showChatMenu(BuildContext context, AppModel model, Person person) {
  _showSheet(context, [
    _SheetRow(
      icon: 'profile',
      label: 'View profile',
      onPressed: () {
        Navigator.pop(context);
        model.go(AppRoute.mateProfile);
      },
    ),
    if (model.live) ...[
      _SheetRow(
        icon: 'flag',
        label: 'Report ${person.name}',
        danger: true,
        onPressed: () {
          Navigator.pop(context);
          showReportSheet(context, person);
        },
      ),
      _SheetRow(
        icon: 'block',
        label: 'Block ${person.name}',
        caption: 'Ends your mate connection and closes this chat.',
        danger: true,
        onPressed: () async {
          Navigator.pop(context);
          final sure = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Block ${person.name}?'),
              content: const Text(
                'You will stop being mates and this chat closes for both of '
                'you. You can unblock later from Profile.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(
                    'Block',
                    style: ClubType.inter(14, color: ClubColors.error),
                  ),
                ),
              ],
            ),
          );
          if (sure == true) await model.blockOpened();
        },
      ),
    ],
  ]);
}

/// Report a person, optionally about one message. Blocking is on by default.
Future<void> showReportSheet(
  BuildContext context,
  Person person, {
  String? messageId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: ClubColors.paper,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) => _ReportSheet(person: person, messageId: messageId),
  );
}

class _ReportSheet extends StatefulWidget {
  const _ReportSheet({required this.person, this.messageId});

  final Person person;
  final String? messageId;

  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  final _details = TextEditingController();
  String? _reason;
  var _block = true;

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  Future<void> _submit(AppModel model) async {
    final reason = _reason;
    if (reason == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final ok = await model.report(
      widget.person,
      reason: reason,
      details: _details.text.trim().isEmpty ? null : _details.text.trim(),
      messageId: widget.messageId,
      block: _block,
    );
    if (!ok) return;
    navigator.pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          _block
              ? 'Thanks. ${widget.person.name} is blocked and we will review your report.'
              : 'Thanks. We will review your report.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final model = AppScope.watch(context);
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.messageId == null
                    ? 'Report ${widget.person.name}'
                    : 'Report this message',
                style: ClubType.lora(26),
              ),
              const SizedBox(height: 6),
              Text(
                'Reports are private. ${widget.person.name} is not told who '
                'reported them.',
                style: ClubType.inter(13, color: ClubColors.muted, height: 1.4),
              ),
              const SizedBox(height: 14),
              for (final entry in reportReasons.entries)
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => setState(() => _reason = entry.key),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _reason == entry.key
                                ? ClubColors.brand
                                : Colors.transparent,
                            border: Border.all(
                              color: _reason == entry.key
                                  ? ClubColors.brand
                                  : ClubColors.disabled,
                              width: 1.6,
                            ),
                          ),
                          child: _reason == entry.key
                              ? const Center(
                                  child: ClubIcon(
                                    'check',
                                    size: 13,
                                    color: Colors.white,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(entry.value, style: ClubType.inter(15)),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 10),
              TextField(
                controller: _details,
                minLines: 2,
                maxLines: 4,
                inputFormatters: [LengthLimitingTextInputFormatter(500)],
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Anything else we should know? (optional)',
                  hintStyle: ClubType.inter(14, color: ClubColors.disabled),
                  filled: true,
                  fillColor: ClubColors.field,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: ClubColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: ClubColors.border),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _block,
                activeTrackColor: ClubColors.brand,
                onChanged: (value) => setState(() => _block = value),
                title: Text(
                  'Also block ${widget.person.name}',
                  style: ClubType.inter(15, weight: FontWeight.w500),
                ),
                subtitle: Text(
                  'Ends your mate connection and closes the chat.',
                  style: ClubType.inter(12, color: ClubColors.muted),
                ),
              ),
              if (model.errorMessage != null) ...[
                const SizedBox(height: 6),
                Text(
                  model.errorMessage!,
                  style: ClubType.inter(13, color: ClubColors.error),
                ),
              ],
              const SizedBox(height: 12),
              PrimaryButton(
                'Send report',
                loading: model.busy,
                onPressed: _reason == null ? null : () => _submit(model),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
