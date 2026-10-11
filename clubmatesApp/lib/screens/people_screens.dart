import 'package:flutter/material.dart';

import '../club_icon.dart';
import '../liquid_glass.dart';
import '../mock_model.dart';
import '../theme.dart';
import '../widgets.dart';

class LikesScreen extends StatelessWidget {
  const LikesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final model = MockScope.watch(context);
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
    final model = MockScope.watch(context);
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
    final model = MockScope.watch(context);
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

    final bottom = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.only(bottom: bottom + 96),
            children: [
              Stack(
                children: [
                  ProfilePhoto(
                    person.photo,
                    height: MediaQuery.sizeOf(context).height * 0.62,
                    width: double.infinity,
                  ),
                  Positioned(
                    top: MediaQuery.paddingOf(context).top + 14,
                    left: 14,
                    child: GlassIconButton(
                      clear: true,
                      onPressed: () => model.go(back),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 34),
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
                      DecoratedBox(
                        decoration: glassPaint(selected: true, radius: 999),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 6,
                          ),
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
                      ),
                    ],
                    const SizedBox(height: 26),
                    _CopyBlock('Tonight', person.tonight),
                    if (person.usually.isNotEmpty) ...[
                      const SizedBox(height: 26),
                      _CopyBlock('Usually out for', person.usually),
                    ],
                    if (person.interests.isNotEmpty) ...[
                      const SizedBox(height: 26),
                      const Eyebrow('Interests'),
                      const SizedBox(height: 7),
                      ChipWrap(
                        children: [
                          for (final interest in person.interests)
                            ChoiceChipButton(interest, compact: true),
                        ],
                      ),
                    ],
                    if (model.live) ...[
                      const SizedBox(height: 20),
                      TextLink(
                        'Block',
                        color: ClubColors.error,
                        onPressed: model.blockOpened,
                      ),
                    ],
                    if (!model.live) ...[
                      const SizedBox(height: 26),
                      const ProfilePhoto(
                        nightPhoto,
                        height: 360,
                        width: double.infinity,
                        radius: 14,
                      ),
                    ],
                    if (kind == AppRoute.mateProfile) ...[
                      const SizedBox(height: 24),
                      SecondaryButton(
                        'Remove Mate',
                        foreground: ClubColors.error,
                        onPressed: model.removeMate,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: bottom + 8,
            child: ActionBar(
              inviteLabel: inviteLabel,
              onPass: () {
                if (kind == AppRoute.inviteDetail) {
                  model.passInvite();
                } else if (kind == AppRoute.details) {
                  model.passClub();
                } else {
                  model.go(AppRoute.club);
                }
              },
              onInvite: () {
                if (kind == AppRoute.inviteDetail) {
                  model.acceptInvite();
                } else if (kind == AppRoute.mateProfile) {
                  model.go(AppRoute.mates);
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
    this.actions,
    this.showChevron = false,
  });

  final MockPerson person;
  final VoidCallback onOpen;
  final Widget? actions;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onOpen,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
        child: Container(
          padding: const EdgeInsets.only(top: 12, bottom: 18),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: ClubColors.border)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ProfilePhoto(person.photo, width: 84, height: 104, radius: 12),
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
                    const SizedBox(height: 8),
                    Text(
                      person.preview,
                      style: ClubType.inter(
                        12,
                        color: ClubColors.muted,
                        height: 1.3,
                      ),
                    ),
                    if (actions != null) ...[
                      const SizedBox(height: 12),
                      actions!,
                    ],
                  ],
                ),
              ),
              if (showChevron) const ClubIcon('chevron'),
            ],
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
    const radius = BorderRadius.all(Radius.circular(18));
    return DecoratedBox(
      decoration: filled
          ? tintedPaint(enabled: true, radius: 18)
          : glassPaint(radius: 18),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onPressed,
          borderRadius: radius,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            child: Text(
              label,
              style: ClubType.inter(
                12,
                weight: FontWeight.w600,
                height: 1,
                color: filled ? ClubColors.paper : ClubColors.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
