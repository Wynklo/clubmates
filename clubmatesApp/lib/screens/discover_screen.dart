import 'package:flutter/material.dart';

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
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => model.openPerson(person, AppRoute.details),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      height: MediaQuery.sizeOf(context).height * 0.5,
                      width: double.infinity,
                      child: ProfilePhoto(person.photo),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '${person.name}, ${person.age}',
                  style: ClubType.lora(34, height: 1.05),
                ),
                const SizedBox(height: 6),
                PlaceLine(person.location, verified: person.verified),
                const SizedBox(height: 18),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: ClubColors.field,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: ClubColors.border),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tonight',
                          style: ClubType.inter(13, color: ClubColors.muted),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          person.preview,
                          style: ClubType.lora(22, height: 1.25),
                        ),
                      ],
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextLink(
                    'View full profile',
                    underline: false,
                    onPressed: () => model.openPerson(person, AppRoute.details),
                  ),
                ),
                ActionBar(onPass: model.passClub, onInvite: model.inviteClub),
              ],
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
