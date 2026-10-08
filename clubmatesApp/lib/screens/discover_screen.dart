import 'package:flutter/material.dart';

import '../club_icon.dart';
import '../mock_model.dart';
import '../theme.dart';
import '../widgets.dart';

class ClubScreen extends StatelessWidget {
  const ClubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final model = MockScope.watch(context);
    if (model.profiles > 1) {
      return MainShell(
        child: EmptyState(
          title: 'No one nearby tonight.',
          copy:
              'New people show up as plans take shape. Check back a little later.',
          action: 'Refresh',
          onPressed: model.refreshClub,
        ),
      );
    }

    final person = model.clubPerson;
    return MainShell(
      child: ListView(
        padding: const EdgeInsets.only(bottom: 12),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Center(child: Wordmark()),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: GestureDetector(
              onTap: () => model.go(AppRoute.details),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
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
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: const Color(0xC71A1A1A),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
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
          ActionBar(
            pinned: false,
            onPass: model.passClub,
            onInvite: () => model.go(AppRoute.inviteSent),
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
