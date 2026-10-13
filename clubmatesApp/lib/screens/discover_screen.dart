import 'dart:ui';

import 'package:flutter/material.dart';

import '../state/app_model.dart';
import '../theme/theme.dart';
import '../ui/liquid_glass.dart';
import '../ui/widgets.dart';

class ClubScreen extends StatefulWidget {
  const ClubScreen({super.key});

  @override
  State<ClubScreen> createState() => _ClubScreenState();
}

class _ClubScreenState extends State<ClubScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      AppScope.read(context).captureLocation();
    });
  }

  @override
  Widget build(BuildContext context) {
    final model = AppScope.watch(context);
    if (model.clubPerson == null) {
      return MainShell(
        child: Padding(
          padding: EdgeInsets.only(bottom: ClubChrome.clearance(context)),
          child: EmptyState(
            title: 'No one nearby tonight.',
            copy:
                'Club shows people active in the last 20 minutes, within 10 km.',
            action: 'Refresh',
            loading: model.busy,
            onPressed: model.refreshClub,
          ),
        ),
      );
    }

    final person = model.clubPerson;
    if (person == null) {
      return const SizedBox.shrink();
    }
    final height = MediaQuery.sizeOf(context).height;
    final cardHeight = height * 0.58 > 545 ? 545.0 : height * 0.58;
    final activity = recentActivity(person.minutesAgo);
    return MainShell(
      child: ListView(
        padding: EdgeInsets.only(bottom: ClubChrome.clearance(context)),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 6, 12, 10),
            child: _ClubHeader(),
          ),
          if (model.errorMessage != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                model.errorMessage!,
                style: ClubType.inter(13, color: ClubColors.error),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: GestureDetector(
              onTap: () => model.openPerson(person, AppRoute.details),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: SizedBox(
                  height: cardHeight,
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
                              Color(0x14140C11),
                              Color(0x00000000),
                              Color(0x42140C11),
                            ],
                            stops: [0, 0.4, 1],
                          ),
                        ),
                      ),
                      if (activity != null)
                        Positioned(
                          top: 14,
                          left: 14,
                          child: _OverlayActivity(activity),
                        ),
                      Positioned(
                        left: 9,
                        right: 9,
                        bottom: 9,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: const Color(0x80181316),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0x47FFFFFF)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(15, 14, 12, 14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${person.name}, ${person.age}',
                                        style: ClubType.lora(
                                          29,
                                          height: 1.05,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      PlaceLine(
                                        person.location,
                                        onDark: true,
                                        verified: person.verified,
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  'View profile',
                                  style: ClubType.inter(
                                    11,
                                    color: Colors.white.withValues(alpha: 0.9),
                                    weight: FontWeight.w500,
                                    height: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('THEIR PLAN TONIGHT', style: ClubType.eyebrow),
                const SizedBox(height: 6),
                Text(person.preview, style: ClubType.lora(15, height: 1.35)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: ActionBar(
              onPass: model.passClub,
              onInvite: model.inviteClub,
            ),
          ),
        ],
      ),
    );
  }
}

class _OverlayActivity extends StatelessWidget {
  const _OverlayActivity(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0x4C191417),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0x5CFFFFFF)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 16,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 11),
            child: SizedBox(
              height: 30,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _LiveDot(),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: ClubType.inter(
                      10,
                      color: Colors.white,
                      weight: FontWeight.w600,
                      height: 1,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LiveDot extends StatelessWidget {
  const _LiveDot();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        color: Color(0xFF70D39A),
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Color(0x2970D39A), spreadRadius: 3)],
      ),
      child: SizedBox(width: 7, height: 7),
    );
  }
}

class _ClubHeader extends StatelessWidget {
  const _ClubHeader();

  @override
  Widget build(BuildContext context) {
    final model = AppScope.watch(context);
    return SizedBox(
      height: 44,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Expanded(
            child: Align(alignment: Alignment.centerLeft, child: Wordmark()),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'TONIGHT IN',
                textAlign: TextAlign.center,
                style: ClubType.inter(
                  9,
                  color: ClubColors.muted,
                  weight: FontWeight.w600,
                  height: 1.1,
                  letterSpacing: 0.9,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                model.location,
                textAlign: TextAlign.center,
                style: ClubType.lora(13, height: 1.05),
              ),
            ],
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: GlassIconButton(
                icon: 'tune',
                tooltip: 'Discovery preferences',
                size: 40,
                onPressed: () => model.openNearby(back: AppRoute.club),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class InviteSentScreen extends StatelessWidget {
  const InviteSentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CenteredScreen(
      children: [
        const SuccessMark(quiet: true),
        Text(
          'Invite sent',
          textAlign: TextAlign.center,
          style: ClubType.lora(32),
        ),
        const SizedBox(height: 10),
        Text(
          "Let's see where the night goes.",
          textAlign: TextAlign.center,
          style: ClubType.inter(15, color: ClubColors.muted),
        ),
        const SizedBox(height: 32),
        PrimaryButton(
          'Keep exploring',
          onPressed: () => AppScope.read(context).keepExploring(),
        ),
      ],
    );
  }
}
