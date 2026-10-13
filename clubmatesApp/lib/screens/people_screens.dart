import 'dart:ui';

import 'package:flutter/material.dart';

import '../state/app_model.dart';
import '../theme/theme.dart';
import '../ui/club_icon.dart';
import '../ui/liquid_glass.dart';
import '../ui/widgets.dart';

class LikesScreen extends StatelessWidget {
  const LikesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final model = AppScope.watch(context);
    return MainShell(
      child: ListView(
        padding: EdgeInsets.only(bottom: ClubChrome.clearance(context)),
        children: [
          const PageHeading(title: 'People who want to go out with you'),
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
                        model.openPerson(person, AppRoute.likes);
                        model.passInvite();
                      },
                    ),
                    const SizedBox(width: 8),
                    _SmallAction(
                      'Accept',
                      filled: true,
                      onPressed: () {
                        model.openPerson(person, AppRoute.likes);
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
    );
  }
}

class MatesScreen extends StatelessWidget {
  const MatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final model = AppScope.watch(context);
    return MainShell(
      child: ListView(
        padding: EdgeInsets.only(bottom: ClubChrome.clearance(context)),
        children: [
          const PageHeading(
            title: 'Mates',
            supporting: 'People who are up for going out with you.',
          ),
          if (model.mateList.isNotEmpty)
            for (final person in model.mateList)
              _PersonRow(
                person: person,
                showChevron: true,
                subtitle: person.tonight.trim().isEmpty
                    ? person.preview
                    : 'Tonight: ${person.tonight}',
                onOpen: () => model.openPerson(person, AppRoute.mateProfile),
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
    );
  }
}

class PersonDetailScreen extends StatelessWidget {
  const PersonDetailScreen({super.key, required this.kind});

  final AppRoute kind;

  @override
  Widget build(BuildContext context) {
    final model = AppScope.watch(context);
    final person = model.personFor(kind);
    final back = switch (kind) {
      AppRoute.inviteDetail => AppRoute.likes,
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
    final heroHeight = MediaQuery.sizeOf(context).height * 0.6;
    final backTop = topInset < 14 ? 14.0 : topInset;
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          ListView(
            padding: EdgeInsets.only(
              bottom: kind == AppRoute.mateProfile
                  ? bottom + 160
                  : bottom + 110,
            ),
            children: [
              DecoratedBox(
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(28),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x2923141D),
                      blurRadius: 50,
                      offset: Offset(0, 18),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(28),
                  ),
                  child: Stack(
                    children: [
                      ProfilePhoto(
                        person.photo,
                        height: heroHeight,
                        width: double.infinity,
                      ),
                      Positioned(
                        top: backTop,
                        left: 14,
                        child: GlassIconButton(onPressed: () => model.go(back)),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 26, 20, 34),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${person.name}, ${person.age}',
                      style: ClubType.lora(27, height: 1.2),
                    ),
                    const SizedBox(height: 5),
                    PlaceLine(person.location, verified: person.verified),
                    const SizedBox(height: 24),
                    const Divider(height: 1, color: ClubColors.border),
                    if (kind == AppRoute.mateProfile) ...[
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          const _MatchedLabel(),
                          const Spacer(),
                          if (recentActivity(person.minutesAgo) != null)
                            _ActivityLine(recentActivity(person.minutesAgo)!),
                        ],
                      ),
                    ] else if (recentActivity(person.minutesAgo) != null) ...[
                      const SizedBox(height: 14),
                      _ActivityLine(recentActivity(person.minutesAgo)!),
                    ],
                    const SizedBox(height: 26),
                    _CopyBlock('Tonight', person.tonight),
                    if (person.usually.isNotEmpty) ...[
                      const SizedBox(height: 26),
                      _CopyBlock('Usually out for', person.usually),
                    ],
                    const SizedBox(height: 26),
                    const Eyebrow('Interests'),
                    const SizedBox(height: 7),
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
                    if (model.live && kind != AppRoute.mateProfile) ...[
                      const SizedBox(height: 20),
                      TextLink(
                        'Block',
                        color: ClubColors.error,
                        onPressed: model.blockOpened,
                      ),
                    ],
                    if (person.id.isEmpty) ...[
                      const SizedBox(height: 26),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(22)),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x14281921),
                              blurRadius: 24,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ProfilePhoto(
                          nightPhoto,
                          height: 360,
                          width: double.infinity,
                          radius: 22,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
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
              child: _MessageBubbleButton(
                onPressed: () => _openMateChat(context),
              ),
            ),
          ] else
            Positioned(
              left: 12,
              right: 12,
              bottom: bottom < 10 ? 10 : bottom,
              child: _DetailActions(
                inviteLabel: inviteLabel,
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
        ],
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
    this.showChevron = false,
  });

  final Person person;
  final VoidCallback onOpen;
  final String? subtitle;
  final Widget? actions;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final activity = recentActivity(person.minutesAgo);
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
                        _ActivityLine(activity),
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
                if (showChevron) const ClubIcon('chevron', size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActivityLine extends StatelessWidget {
  const _ActivityLine(this.label, {this.size = 10});

  final String label;
  final double size;

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
            color: ClubColors.muted,
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

class _DetailActions extends StatelessWidget {
  const _DetailActions({
    required this.inviteLabel,
    required this.onPass,
    required this.onInvite,
  });

  final String inviteLabel;
  final VoidCallback onPass;
  final VoidCallback onInvite;

  @override
  Widget build(BuildContext context) {
    final busy = AppScope.watch(context).busy;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xF7FFFFFF),
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: const Color(0xB8FFFFFF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F24171F),
            blurRadius: 32,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(7),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: _DetailButton(
                label: 'Pass',
                icon: 'close',
                filled: false,
                loading: busy,
                onPressed: onPass,
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              flex: 3,
              child: _DetailButton(
                label: inviteLabel,
                icon: 'check',
                filled: true,
                loading: busy,
                onPressed: onInvite,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailButton extends StatelessWidget {
  const _DetailButton({
    required this.label,
    required this.icon,
    required this.filled,
    required this.loading,
    required this.onPressed,
  });

  final String label;
  final String icon;
  final bool filled;
  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final color = filled ? ClubColors.paper : ClubColors.ink;
    const radius = BorderRadius.all(Radius.circular(17));
    return Material(
      color: filled ? ClubColors.ink : ClubColors.field,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: filled ? ClubColors.ink : ClubColors.border),
      ),
      child: InkWell(
        onTap: loading ? null : onPressed,
        borderRadius: radius,
        child: SizedBox(
          height: 52,
          child: loading
              ? Center(child: ClubPulse(color: color, size: 6))
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ClubIcon(icon, size: 20, color: color),
                    const SizedBox(width: 7),
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ClubType.inter(
                          16,
                          weight: FontWeight.w600,
                          height: 1,
                          color: color,
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

class MateChatScreen extends StatefulWidget {
  const MateChatScreen({super.key});

  @override
  State<MateChatScreen> createState() => _MateChatScreenState();
}

class _MateChatScreenState extends State<MateChatScreen> {
  final _text = TextEditingController();
  var _plansOpen = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _togglePlans() => setState(() => _plansOpen = !_plansOpen);

  void _send(AppModel model) {
    model.sendChat(_text.text);
    _text.clear();
    setState(() => _plansOpen = false);
  }

  void _sharePlan(void Function() share) {
    share();
    setState(() => _plansOpen = false);
  }

  @override
  Widget build(BuildContext context) {
    final model = AppScope.watch(context);
    final person = model.opened ?? riya;
    final lines = model.chatForOpened();
    final activity = recentActivity(person.minutesAgo);
    final headerHeight = _chatHeaderHeight(context);
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
        child: Stack(
          children: [
            Column(
              children: [
                _ChatHeader(
                  person: person,
                  activity: activity,
                  plansOpen: _plansOpen,
                  onBack: () => model.go(AppRoute.mateProfile),
                  onPlans: _togglePlans,
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                    children: [
                      const Center(child: _DayPill('Today')),
                      const SizedBox(height: 10),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: _ChatBubble(
                          mine: false,
                          text:
                              'You’re mates now. Start with a plan, not just “hey”.',
                        ),
                      ),
                      for (final line in lines) ...[
                        const SizedBox(height: 10),
                        Align(
                          alignment: line.mine
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: _ChatBubble(mine: line.mine, text: line.text),
                        ),
                      ],
                    ],
                  ),
                ),
                _ChatComposer(
                  controller: _text,
                  name: person.name,
                  onSend: () => _send(model),
                ),
              ],
            ),
            if (_plansOpen)
              Positioned(
                top: headerHeight + 8,
                left: 12,
                right: 12,
                child: _PlanMenu(
                  onClubs: () => _sharePlan(model.exploreClubsTogether),
                  onDrinks: () => _sharePlan(model.shareNearbyDrinks),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

double _chatHeaderHeight(BuildContext context) {
  final top = MediaQuery.paddingOf(context).top;
  final rowTop = top < 12 ? 12.0 : top;
  return rowTop + 42 + 10;
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({
    required this.person,
    required this.activity,
    required this.plansOpen,
    required this.onBack,
    required this.onPlans,
  });

  final Person person;
  final String? activity;
  final bool plansOpen;
  final VoidCallback onBack;
  final VoidCallback onPlans;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final rowTop = top < 12 ? 12.0 : top;
    return _FrostedBar(
      bottomBorder: true,
      child: SizedBox(
        height: _chatHeaderHeight(context),
        child: Padding(
          padding: EdgeInsets.fromLTRB(14, rowTop, 14, 10),
          child: Row(
            children: [
              GlassIconButton(onPressed: onBack),
              Expanded(
                child: InkWell(
                  onTap: onBack,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ProfilePhoto(
                        person.photo,
                        width: 40,
                        height: 40,
                        radius: 20,
                      ),
                      const SizedBox(width: 9),
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
                                14,
                                weight: FontWeight.w600,
                                height: 1.1,
                              ),
                            ),
                            if (activity != null) ...[
                              const SizedBox(height: 2),
                              _ActivityLine(activity!, size: 9),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              GlassIconButton(
                icon: 'plus',
                size: 42,
                tooltip: 'Plan something',
                onPressed: onPlans,
              ),
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
    return _FrostedBar(
      radius: 24,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Eyebrow('Make a plan'),
            const SizedBox(height: 4),
            Text('Explore together', style: ClubType.lora(21, height: 1.15)),
            const SizedBox(height: 12),
            _PlanRow(
              index: '01',
              title: 'Explore clubs together',
              subtitle: 'Browse active clubs nearby',
              onPressed: onClubs,
            ),
            _PlanRow(
              index: '02',
              title: 'Find drinks nearby',
              subtitle: 'Discover bars within your radius',
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
              child: SizedBox(
                width: 36,
                height: 36,
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
                    style: ClubType.inter(
                      13,
                      weight: FontWeight.w600,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: ClubType.inter(
                      10,
                      color: ClubColors.muted,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            const ClubIcon('chevron', size: 17),
          ],
        ),
      ),
    );
  }
}

class _DayPill extends StatelessWidget {
  const _DayPill(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xB3FFFFFF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        child: Text(
          label,
          style: ClubType.inter(
            9,
            color: ClubColors.muted,
            weight: FontWeight.w600,
            height: 1,
          ),
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.mine, required this.text});

  final bool mine;
  final String text;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: Radius.circular(mine ? 18 : 5),
      bottomRight: Radius.circular(mine ? 5 : 18),
    );
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * 0.78,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: mine ? ClubColors.ink : ClubColors.field,
          borderRadius: radius,
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F281921),
              blurRadius: 18,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(13, 11, 13, 11),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                text,
                style: ClubType.inter(
                  13,
                  height: 1.42,
                  color: mine ? ClubColors.paper : ClubColors.ink,
                ),
              ),
              if (mine) ...[
                const SizedBox(height: 4),
                Text(
                  'Delivered',
                  style: ClubType.inter(
                    8,
                    height: 1,
                    color: ClubColors.paper.withValues(alpha: 0.62),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

void _openMateChat(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const _MateChatPopup(),
  );
}

class _MateChatPopup extends StatefulWidget {
  const _MateChatPopup();

  @override
  State<_MateChatPopup> createState() => _MateChatPopupState();
}

class _MateChatPopupState extends State<_MateChatPopup> {
  final _text = TextEditingController();
  var _plansOpen = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _send(AppModel model) {
    model.sendChat(_text.text);
    _text.clear();
    setState(() => _plansOpen = false);
  }

  void _sharePlan(void Function() share) {
    share();
    setState(() => _plansOpen = false);
  }

  @override
  Widget build(BuildContext context) {
    final model = AppScope.watch(context);
    final person = model.opened ?? riya;
    final lines = model.chatForOpened();
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final height = MediaQuery.sizeOf(context).height * 0.86;
    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: SizedBox(
          height: height,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: ClubColors.paper,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                  child: Row(
                    children: [
                      _LeadingIconButton(
                        icon: 'plus',
                        tooltip: 'Plan something',
                        onPressed: () =>
                            setState(() => _plansOpen = !_plansOpen),
                      ),
                      Expanded(
                        child: Text(
                          person.name,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: ClubType.inter(16, weight: FontWeight.w600),
                        ),
                      ),
                      _LeadingIconButton(
                        icon: 'close',
                        tooltip: 'Close',
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                if (_plansOpen)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                    child: _PlanMenu(
                      onClubs: () => _sharePlan(model.exploreClubsTogether),
                      onDrinks: () => _sharePlan(model.shareNearbyDrinks),
                    ),
                  ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    children: [
                      const Center(child: _DayPill('Today')),
                      const SizedBox(height: 10),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: _ChatBubble(
                          mine: false,
                          text:
                              'You’re mates now. Start with a plan, not just “hey”.',
                        ),
                      ),
                      for (final line in lines) ...[
                        const SizedBox(height: 10),
                        Align(
                          alignment: line.mine
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: _ChatBubble(mine: line.mine, text: line.text),
                        ),
                      ],
                    ],
                  ),
                ),
                _ChatComposer(
                  controller: _text,
                  name: person.name,
                  onSend: () => _send(model),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LeadingIconButton extends StatelessWidget {
  const _LeadingIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final String icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: const Color(0x29787880),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Center(
              child: ClubIcon(icon, size: 17, color: const Color(0xFF727272)),
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

class _ChatComposer extends StatelessWidget {
  const _ChatComposer({
    required this.controller,
    required this.name,
    required this.onSend,
  });

  final TextEditingController controller;
  final String name;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final home = MediaQuery.paddingOf(context).bottom;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final bottom = keyboard > 0 ? 4.0 : (home < 32 ? 32.0 : home);
    return Padding(
      padding: EdgeInsets.fromLTRB(28, 4, 28, bottom),
      child: Row(
        children: [
          Expanded(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: Color(0xFFF7F7F7),
                borderRadius: BorderRadius.all(Radius.circular(296)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x1F000000),
                    blurRadius: 40,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: TextField(
                controller: controller,
                textInputAction: TextInputAction.send,
                style: ClubType.inter(
                  17,
                  weight: FontWeight.w500,
                  height: 20 / 17,
                ),
                decoration: InputDecoration(
                  hintText: 'Message $name',
                  hintStyle: ClubType.inter(
                    17,
                    weight: FontWeight.w500,
                    height: 20 / 17,
                    color: const Color(0xFFBFBFBF),
                  ),
                  filled: true,
                  fillColor: const Color(0xA6FFFFFF),
                  isCollapsed: true,
                  contentPadding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  constraints: const BoxConstraints(
                    minHeight: 48,
                    maxHeight: 48,
                  ),
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(296)),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(296)),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(296)),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Tooltip(
            message: 'Send message',
            child: DecoratedBox(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x1F000000),
                    blurRadius: 40,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Material(
                color: ClubColors.ink,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onSend,
                  child: const SizedBox(
                    width: 48,
                    height: 48,
                    child: Center(
                      child: ClubIcon(
                        'send',
                        size: 20,
                        color: ClubColors.paper,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FrostedBar extends StatelessWidget {
  const _FrostedBar({
    required this.child,
    this.bottomBorder = true,
    this.radius = 0,
  });

  final Widget child;
  final bool bottomBorder;
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
              border: Border(
                top: bottomBorder
                    ? BorderSide.none
                    : const BorderSide(color: Color(0xB8FFFFFF)),
                bottom: bottomBorder
                    ? const BorderSide(color: Color(0xB8FFFFFF))
                    : BorderSide.none,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
