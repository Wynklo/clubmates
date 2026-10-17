import 'package:flutter/material.dart';

import '../state/app_model.dart';
import '../theme/theme.dart';
import '../ui/club_icon.dart';
import '../ui/club_swipe.dart';
import '../ui/liquid_glass.dart';
import '../ui/profile_prompts.dart';
import '../ui/widgets.dart';
import 'chat_screen.dart' show showReportSheet;

class InvitesScreen extends StatelessWidget {
  const InvitesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final model = AppScope.watch(context);
    return MainShell(
      child: RefreshIndicator.adaptive(
        color: ClubColors.brand,
        backgroundColor: ClubColors.paper,
        onRefresh: model.refreshPeople,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.only(bottom: ClubChrome.clearance(context)),
          children: [
            const PageHeading(title: 'People who want to go out with you'),
            if (model.errorMessage != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(
                  model.errorMessage!,
                  style: ClubType.inter(13, color: ClubColors.error),
                ),
              ),
            if (model.incoming.isNotEmpty)
              for (final person in model.incoming)
                _PersonRow(
                  person: person,
                  onOpen: () => model.openPerson(person, AppRoute.inviteDetail),
                  subtitle: person.interests.isEmpty
                      ? person.preview
                      : person.interests.join(', '),
                  actions: Row(
                    children: [
                      _SmallAction(
                        'Pass',
                        filled: false,
                        onPressed: () {
                          model.openPerson(person, AppRoute.invites);
                          model.passInvite();
                        },
                      ),
                      const SizedBox(width: 8),
                      _SmallAction(
                        'Accept',
                        filled: true,
                        onPressed: () {
                          model.openPerson(person, AppRoute.invites);
                          model.acceptInvite();
                        },
                      ),
                    ],
                  ),
                )
            else
              const EmptyState(
                title: 'No invites yet.',
                copy:
                    "When someone wants to make a plan with you, they'll appear here.",
              ),
          ],
        ),
      ),
    );
  }
}

class MatesScreen extends StatelessWidget {
  const MatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final model = AppScope.watch(context);
    return MainShell(
      child: RefreshIndicator.adaptive(
        color: ClubColors.brand,
        backgroundColor: ClubColors.paper,
        onRefresh: model.refreshPeople,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.only(bottom: ClubChrome.clearance(context)),
          children: [
            const PageHeading(
              title: 'Mates',
              supporting: 'People who are up for going out with you.',
            ),
            if (model.errorMessage != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(
                  model.errorMessage!,
                  style: ClubType.inter(13, color: ClubColors.error),
                ),
              ),
            if (model.mateList.isNotEmpty)
              for (final person in _byLatestMessage(model))
                _ChatRow(
                  person: person,
                  thread: model.threadFor(person),
                  onOpen: () {
                    model.opened = person;
                    model.openChat();
                  },
                )
            else
              EmptyState(
                title: 'No mates yet.',
                copy:
                    'Mutual invites become mates. Keep discovering people nearby.',
                action: 'Explore Club',
                onPressed: () => model.go(AppRoute.club),
              ),
          ],
        ),
      ),
    );
  }
}

List<Person> _byLatestMessage(AppModel model) {
  final epoch = DateTime(2000);
  return [...model.mateList]..sort((a, b) {
    final atA = model.threadFor(a)?.lastAt ?? epoch;
    final atB = model.threadFor(b)?.lastAt ?? epoch;
    return atB.compareTo(atA);
  });
}

class _ChatRow extends StatelessWidget {
  const _ChatRow({
    required this.person,
    required this.thread,
    required this.onOpen,
  });

  final Person person;
  final MateThread? thread;
  final VoidCallback onOpen;

  static const _grey = Color(0xFF767779);

  @override
  Widget build(BuildContext context) {
    final unread = thread?.unread ?? 0;
    final lastAt = thread?.lastAt;
    final out = isOutTonight(person.outTonightUntil);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Material(
        color: ClubColors.field,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onOpen,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0x171A1A1A)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14281921),
                  blurRadius: 24,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ChatAvatar(photo: person.photo, outTonight: out),
                const SizedBox(width: 12.66),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                person.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: ClubType.inter(
                                  16,
                                  weight: FontWeight.w600,
                                  height: 19 / 16,
                                  letterSpacing: -0.32,
                                  color: const Color(0xFF0A0A0A),
                                ),
                              ),
                            ),
                            if (lastAt != null) ...[
                              const SizedBox(width: 8),
                              Text(
                                _chatTime(context, lastAt),
                                style: ClubType.inter(
                                  14,
                                  height: 19 / 14,
                                  letterSpacing: -0.14,
                                  weight: unread > 0
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: unread > 0 ? ClubColors.brand : _grey,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 1.5),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                thread?.preview ?? 'Say hi and make a plan.',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: ClubType.inter(
                                  14,
                                  height: 19 / 14,
                                  letterSpacing: -0.14,
                                  weight: unread > 0
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: unread > 0
                                      ? const Color(0xFF0A0A0A)
                                      : _grey,
                                ),
                              ),
                            ),
                            if (unread > 0) ...[
                              const SizedBox(width: 8),
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: _UnreadBadge(unread),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatAvatar extends StatelessWidget {
  const _ChatAvatar({required this.photo, required this.outTonight});

  final String photo;
  final bool outTonight;

  @override
  Widget build(BuildContext context) {
    final picture = Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0x1A0A0A0A), width: 0.33),
      ),
      child: ClipOval(
        child: ProfilePhoto(photo, width: 56, height: 56, radius: 28),
      ),
    );
    if (!outTonight) return picture;
    return Container(
      width: 56,
      height: 56,
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: SweepGradient(
          colors: [
            Color(0xFF64316E),
            Color(0xFF994EA8),
            Color(0xFFE58C8A),
            Color(0xFF994EA8),
            Color(0xFF64316E),
          ],
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(2.5),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
        ),
        child: ClipOval(
          child: ProfilePhoto(photo, width: 47, height: 47, radius: 24),
        ),
      ),
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge(this.count);

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      padding: const EdgeInsets.symmetric(horizontal: 5),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: ClubColors.brand,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: ClubType.inter(
          11,
          weight: FontWeight.w700,
          color: Colors.white,
          height: 1,
        ),
      ),
    );
  }
}

/// WhatsApp style: time today, then Yesterday, weekday this week, else date.
String _chatTime(BuildContext context, DateTime when) {
  final local = when.toLocal();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(local.year, local.month, local.day);
  final daysAgo = today.difference(day).inDays;
  if (daysAgo <= 0) return TimeOfDay.fromDateTime(local).format(context);
  if (daysAgo == 1) return 'Yesterday';
  if (daysAgo < 7) {
    const names = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return names[local.weekday - 1];
  }
  final dd = local.day.toString().padLeft(2, '0');
  final mm = local.month.toString().padLeft(2, '0');
  return '$dd/$mm/${local.year % 100}';
}

class PersonDetailScreen extends StatelessWidget {
  const PersonDetailScreen({super.key, required this.kind});

  final AppRoute kind;

  @override
  Widget build(BuildContext context) {
    final model = AppScope.watch(context);
    final person = model.personFor(kind);
    final back = switch (kind) {
      AppRoute.inviteDetail => AppRoute.invites,
      AppRoute.mateProfile => AppRoute.mates,
      _ => AppRoute.club,
    };
    final inviteLabel = switch (kind) {
      AppRoute.inviteDetail => 'Accept Invite',
      AppRoute.mateProfile => 'Plan something',
      _ => 'Invite',
    };

    final topInset = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final heroHeight = screenHeight * 0.62 > 560 ? 560.0 : screenHeight * 0.62;
    final status = tonightStatus(person.outTonightUntil);
    final firstName = person.name.split(' ').first;
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          PinnedBackPage(
            onBack: () => model.go(back),
            left: 24,
            top: 20,
            fadeAfter: heroHeight - 56,
            clearUntilFade: true,
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                12,
                topInset + 8,
                12,
                kind == AppRoute.mateProfile ? bottom + 160 : bottom + 120,
              ),
              children: [
                _DetailHero(person: person, height: heroHeight, status: status),
                const SizedBox(height: 12),
                if (kind == AppRoute.mateProfile) ...[
                  _DetailCard(
                    child: Row(
                      children: [
                        const _MatchedLabel(),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'You are mates. Plan your night together.',
                            style: ClubType.inter(
                              13,
                              color: ClubColors.muted,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                ..._photosAndPrompts(
                  model.extrasFor(person),
                  photoHeight: heroHeight,
                ),
                _DetailCard(
                  child: _CopyBlock('Their plan tonight', person.tonight),
                ),
                if (person.usually.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _DetailCard(
                    child: _CopyBlock('Usually out for', person.usually),
                  ),
                ],
                const SizedBox(height: 12),
                _DetailCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Eyebrow('Interests'),
                      const SizedBox(height: 10),
                      if (person.interests.isEmpty)
                        Text(
                          'No interests on this profile yet.',
                          style: ClubType.inter(14, color: ClubColors.muted),
                        )
                      else
                        ChipWrap(
                          children: [
                            for (final interest in person.interests)
                              ChoiceChipButton(interest, compact: true),
                          ],
                        ),
                    ],
                  ),
                ),
                if (person.id.isEmpty) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: const ProfilePhoto(
                      nightPhoto,
                      height: 360,
                      width: double.infinity,
                    ),
                  ),
                ],
                if (model.live) ...[
                  const SizedBox(height: 20),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      TextButton.icon(
                        onPressed: model.busy
                            ? null
                            : () => showReportSheet(context, person),
                        style: TextButton.styleFrom(
                          foregroundColor: ClubColors.ink,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                            side: const BorderSide(color: ClubColors.border),
                          ),
                        ),
                        icon: const ClubIcon('flag', size: 16),
                        label: Text(
                          'Report',
                          style: ClubType.inter(
                            13,
                            weight: FontWeight.w600,
                            height: 1,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: model.busy ? null : model.blockOpened,
                        style: TextButton.styleFrom(
                          foregroundColor: ClubColors.error,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                            side: const BorderSide(color: ClubColors.border),
                          ),
                        ),
                        icon: const Icon(Icons.block, size: 16),
                        label: Text(
                          'Block $firstName',
                          style: ClubType.inter(
                            13,
                            color: ClubColors.error,
                            weight: FontWeight.w600,
                            height: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (kind == AppRoute.mateProfile) ...[
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: DecoratedBox(
                decoration: const BoxDecoration(color: ClubColors.paper),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    12,
                    20,
                    bottom < 16 ? 16 : bottom,
                  ),
                  child: SecondaryButton(
                    'Remove Mate',
                    foreground: ClubColors.error,
                    onPressed: model.removeMate,
                  ),
                ),
              ),
            ),
            Positioned(
              right: 20,
              bottom: (bottom < 16 ? 16 : bottom) + 76,
              child: _MessageBubbleButton(onPressed: model.openChat),
            ),
          ] else
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      ClubColors.paper.withValues(alpha: 0),
                      ClubColors.paper.withValues(alpha: 0.92),
                      ClubColors.paper,
                    ],
                    stops: const [0, 0.38, 1],
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    34,
                    16,
                    bottom < 14 ? 14 : bottom,
                  ),
                  child: DecisionButtons(
                    busy: model.busy,
                    inviteLabel: inviteLabel,
                    inviteIcon: kind == AppRoute.inviteDetail
                        ? 'check'
                        : 'send',
                    onPass: () {
                      if (kind == AppRoute.inviteDetail) {
                        model.passInvite();
                      } else {
                        model.passClub();
                      }
                    },
                    onInvite: () {
                      if (kind == AppRoute.inviteDetail) {
                        model.acceptInvite();
                      } else {
                        model.inviteClub();
                      }
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Prompt, photo, prompt, photo… under the hero photo, which is photo one.
List<Widget> _photosAndPrompts(
  ProfileExtras? extras, {
  required double photoHeight,
}) {
  if (extras == null) return const [];
  final photos = extras.photos.skip(1).toList();
  final prompts = extras.prompts;
  final count = photos.length > prompts.length ? photos.length : prompts.length;
  return [
    for (var i = 0; i < count; i++) ...[
      if (i < prompts.length) ...[
        PromptCard(prompts[i]),
        const SizedBox(height: 12),
      ],
      if (i < photos.length) ...[
        ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: ProfilePhoto(
            photos[i],
            height: photoHeight,
            width: double.infinity,
          ),
        ),
        const SizedBox(height: 12),
      ],
    ],
  ];
}

class _DetailHero extends StatelessWidget {
  const _DetailHero({
    required this.person,
    required this.height,
    required this.status,
  });

  final Person person;
  final double height;
  final String? status;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: ClubColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2923141D),
            blurRadius: 40,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ProfilePhoto(person.photo),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x47140C11),
                      Color(0x00000000),
                      Color(0x00000000),
                      Color(0x8C140C11),
                    ],
                    stops: [0, 0.22, 0.55, 1],
                  ),
                ),
              ),
              if (status != null)
                Positioned(top: 19, right: 12, child: _HeroStatus(status!)),
              Positioned(
                left: 10,
                right: 10,
                bottom: 10,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0x80181316),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0x47FFFFFF)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${person.name}, ${person.age}',
                          style: ClubType.lora(
                            28,
                            height: 1.05,
                            color: Colors.white,
                          ),
                        ),
                        if (person.location.isNotEmpty || person.verified) ...[
                          const SizedBox(height: 6),
                          PlaceLine(
                            person.location,
                            onDark: true,
                            verified: person.verified,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroStatus extends StatelessWidget {
  const _HeroStatus(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0x80181316),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0x5CFFFFFF)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
        child: ActivityLine(label, onDark: true),
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ClubColors.field,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x171A1A1A)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F281921),
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    );
  }
}

class _CopyBlock extends StatelessWidget {
  const _CopyBlock(this.label, this.copy);

  final String label;
  final String copy;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Eyebrow(label),
        const SizedBox(height: 7),
        Text(copy, style: ClubType.inter(15)),
      ],
    );
  }
}

class _PersonRow extends StatelessWidget {
  const _PersonRow({
    required this.person,
    required this.onOpen,
    this.subtitle,
    this.actions,
  });

  final Person person;
  final VoidCallback onOpen;
  final String? subtitle;
  final Widget? actions;

  @override
  Widget build(BuildContext context) {
    final activity = tonightStatus(person.outTonightUntil);
    final line = subtitle ?? person.preview;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Material(
        color: ClubColors.field,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onOpen,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0x171A1A1A)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14281921),
                  blurRadius: 24,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ProfilePhoto(person.photo, width: 84, height: 112, radius: 15),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${person.name}, ${person.age}',
                        style: ClubType.lora(18, height: 1.2),
                      ),
                      const SizedBox(height: 4),
                      PlaceLine(
                        person.location,
                        size: 12,
                        verified: person.verified,
                      ),
                      if (activity != null) ...[
                        const SizedBox(height: 7),
                        ActivityLine(activity),
                      ],
                      if (line.trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          line,
                          style: ClubType.inter(
                            12,
                            color: ClubColors.muted,
                            height: 1.3,
                          ),
                        ),
                      ],
                      if (actions != null) ...[
                        const SizedBox(height: 12),
                        actions!,
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ActivityLine extends StatelessWidget {
  const ActivityLine(
    this.label, {
    super.key,
    this.size = 10,
    this.onDark = false,
  });

  final String label;
  final double size;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final dot = size < 10 ? 6.0 : 7.0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: dot,
          height: dot,
          decoration: BoxDecoration(
            color: const Color(0xFF70D39A),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0x2970D39A),
                spreadRadius: size < 10 ? 2 : 3,
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: ClubType.inter(
            size,
            color: onDark ? Colors.white : ClubColors.muted,
            weight: FontWeight.w600,
            height: 1,
          ),
        ),
      ],
    );
  }
}

class _MatchedLabel extends StatelessWidget {
  const _MatchedLabel();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ClubColors.soft,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        child: Text(
          'MATCHED',
          style: ClubType.inter(
            11,
            color: ClubColors.plum,
            weight: FontWeight.w600,
            height: 1,
            letterSpacing: 0.9,
          ),
        ),
      ),
    );
  }
}

class _SmallAction extends StatelessWidget {
  const _SmallAction(
    this.label, {
    required this.filled,
    required this.onPressed,
  });

  final String label;
  final bool filled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final busy = AppScope.watch(context).busy;
    const radius = BorderRadius.all(Radius.circular(12));
    final color = filled ? ClubColors.paper : ClubColors.ink;
    return Material(
      color: filled ? ClubColors.ink : ClubColors.field,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: filled ? ClubColors.ink : ClubColors.border),
      ),
      child: InkWell(
        onTap: busy ? null : onPressed,
        borderRadius: radius,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 70, minHeight: 38),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: busy
                  ? ClubPulse(color: color, size: 5)
                  : Text(
                      label,
                      style: ClubType.inter(
                        12,
                        weight: FontWeight.w600,
                        height: 1,
                        color: color,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MessageBubbleButton extends StatelessWidget {
  const _MessageBubbleButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Message',
      child: DecoratedBox(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFFF7F7F7),
          boxShadow: [
            BoxShadow(
              color: Color(0x1F000000),
              blurRadius: 40,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: const Color(0xA6FFFFFF),
          elevation: 0,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: const SizedBox(
              width: 64,
              height: 64,
              child: Center(
                child: ClubIcon('message', size: 28, color: ClubColors.ink),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
