import 'package:flutter/material.dart';

import '../club_icon.dart';
import '../liquid_glass.dart';
import '../mock_model.dart';
import '../theme.dart';
import '../widgets.dart';

class ClubScreen extends StatelessWidget {
  const ClubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final model = MockScope.watch(context);
    if (model.clubPerson == null) {
      return MainShell(
        child: Padding(
          padding: EdgeInsets.only(bottom: ClubChrome.clearance(context)),
          child: EmptyState(
            title: 'No one nearby tonight.',
            copy:
                'New people show up as plans take shape. Check back a little later.',
            action: 'Refresh',
            onPressed: model.refreshClub,
          ),
        ),
      );
    }

    final person = model.clubPerson;
    if (person == null) {
      return const SizedBox.shrink();
    }
    return MainShell(
      child: ListView(
        padding: EdgeInsets.only(bottom: ClubChrome.clearance(context)),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Center(child: Wordmark()),
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
                  height: MediaQuery.sizeOf(context).height * 0.58,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ProfilePhoto(person.photo),
                      Positioned(
                        left: 10,
                        right: 10,
                        bottom: 10,
                        child: LiquidGlass(
                          role: GlassRole.clear,
                          borderRadius: BorderRadius.circular(18),
                          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${person.name}, ${person.age}',
                                style: ClubType.lora(
                                  29,
                                  color: Colors.white,
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Expanded(
                                    child: PlaceLine(
                                      person.location,
                                      onDark: true,
                                      verified: person.verified,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'View full profile',
                                    style: ClubType.inter(
                                      11,
                                      color: Colors.white,
                                      height: 1.2,
                                    ),
                                  ),
                                  const ClubIcon(
                                    'chevron',
                                    size: 16,
                                    color: Colors.white,
                                  ),
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
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 15, 20, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Eyebrow('Tonight'),
                const SizedBox(height: 5),
                Text(
                  person.preview,
                  style: ClubType.inter(14, color: ClubColors.ink),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
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
          onPressed: () => MockScope.read(context).keepExploring(),
        ),
      ],
    );
  }
}
