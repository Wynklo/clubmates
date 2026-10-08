import 'package:flutter/material.dart';

import '../club_icon.dart';
import '../mock_model.dart';
import '../theme.dart';
import '../widgets.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final model = MockScope.watch(context);
    return MainShell(
      child: ListView(
        children: [
          const PageHeading(title: 'Your profile'),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Row(
              children: [
                const ProfilePhoto(
                  ownPhoto,
                  width: 94,
                  height: 112,
                  radius: 14,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${model.displayName}, 27',
                        style: ClubType.lora(23, height: 1.2),
                      ),
                      const SizedBox(height: 5),
                      PlaceLine(model.location, size: 12),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Container(height: 1, color: ClubColors.border),
                SettingsRow(
                  'Edit profile',
                  onPressed: () => model.go(AppRoute.editProfile),
                ),
                SettingsRow(
                  'Edit photos',
                  onPressed: () => model.go(AppRoute.editProfile),
                ),
                SettingsRow(
                  'Verification',
                  detail: 'Verified',
                  onPressed: () => model.go(AppRoute.status),
                ),
                SettingsRow(
                  'Nightlife preferences',
                  onPressed: () => model.go(AppRoute.editProfile),
                ),
                SettingsRow(
                  'Settings',
                  onPressed: () => model.go(AppRoute.settings),
                ),
                SettingsRow(
                  'Log out',
                  onPressed: () => model.go(AppRoute.phone),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _name;
  late final TextEditingController _location;
  late final TextEditingController _bio;

  @override
  void initState() {
    super.initState();
    final model = MockScope.read(context);
    _name = TextEditingController(text: model.displayName);
    _location = TextEditingController(text: model.location);
    _bio = TextEditingController(
      text: 'Always up for good food and a new playlist.',
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _location.dispose();
    _bio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final model = MockScope.watch(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      tooltip: 'Back',
                      onPressed: () => model.go(AppRoute.profile),
                      icon: const ClubIcon('back'),
                    ),
                  ),
                  Text('Edit profile', style: ClubType.lora(32)),
                  const SizedBox(height: 30),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: 120,
                      height: 140,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const ProfilePhoto(
                            ownPhoto,
                            width: 110,
                            height: 130,
                            radius: 14,
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Material(
                              color: ClubColors.field,
                              shape: const CircleBorder(
                                side: BorderSide(color: ClubColors.border),
                              ),
                              child: const SizedBox(
                                width: 42,
                                height: 42,
                                child: Center(
                                  child: ClubIcon('camera', size: 18),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  ClubField(
                    label: 'Name',
                    hint: 'Aanya',
                    controller: _name,
                    onChanged: model.setName,
                  ),
                  const SizedBox(height: 20),
                  ClubField(
                    label: 'Bio',
                    hint: 'Bio',
                    controller: _bio,
                    maxLines: 4,
                  ),
                  const SizedBox(height: 20),
                  ClubField(
                    label: 'Location',
                    hint: 'Bengaluru',
                    controller: _location,
                    onChanged: model.setLocation,
                  ),
                  const SizedBox(height: 20),
                  const ClubField(label: 'Height', hint: '172 cm'),
                  const SizedBox(height: 20),
                  const Eyebrow('Sex'),
                  const SizedBox(height: 12),
                  ChipWrap(
                    children: [ChoiceChipButton(model.sex, selected: true)],
                  ),
                  const SizedBox(height: 20),
                  const Eyebrow('Nightlife preferences'),
                  const SizedBox(height: 12),
                  ChipWrap(
                    children: [
                      for (final item in model.interests)
                        ChoiceChipButton(item, selected: true),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const PhotoGrid(),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              decoration: const BoxDecoration(
                color: ClubColors.paper,
                border: Border(top: BorderSide(color: ClubColors.border)),
              ),
              child: SafeArea(
                top: false,
                child: PrimaryButton(
                  'Save changes',
                  onPressed: () => model.go(AppRoute.profile),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final model = MockScope.watch(context);
    return _InnerPage(
      title: 'Settings',
      onBack: () => model.go(AppRoute.profile),
      child: Column(
        children: [
          for (final label in [
            'Account',
            'Notifications',
            'Privacy',
            'Location',
          ])
            SettingsRow(label),
          SettingsRow(
            'Verification',
            onPressed: () => model.go(AppRoute.status),
          ),
          for (final label in [
            'Blocked people',
            'Help',
            'Terms',
            'Privacy Policy',
          ])
            SettingsRow(label),
          const SettingsRow('Delete account', danger: true),
        ],
      ),
    );
  }
}

class StatusScreen extends StatelessWidget {
  const StatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final model = MockScope.watch(context);
    return _InnerPage(
      title: 'Verification',
      supporting: 'Your profile has passed both checks.',
      onBack: () => model.go(AppRoute.profile),
      child: Column(
        children: [
          const SizedBox(height: 36),
          const SuccessMark(),
          Text('Profile verified', style: ClubType.lora(27, height: 1.2)),
          const SizedBox(height: 9),
          Text(
            'Verified profiles help everyone feel more confident making plans.',
            textAlign: TextAlign.center,
            style: ClubType.inter(14, color: ClubColors.muted),
          ),
          const SizedBox(height: 28),
          const SettingsRow('Identity document', detail: 'Verified'),
          const SettingsRow('Face check', detail: 'Verified'),
          const SizedBox(height: 8),
          TextLink(
            'Having trouble with verification?',
            color: ClubColors.muted,
            onPressed: () => model.go(AppRoute.error),
          ),
        ],
      ),
    );
  }
}

class ErrorScreen extends StatelessWidget {
  const ErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final model = MockScope.read(context);
    return CenteredScreen(
      children: [
        Container(
          width: 54,
          height: 54,
          margin: const EdgeInsets.only(bottom: 26),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0x599E3328)),
          ),
          child: Text(
            '!',
            style: ClubType.lora(28, color: ClubColors.error, height: 1),
          ),
        ),
        Text(
          "Couldn't complete that",
          textAlign: TextAlign.center,
          style: ClubType.lora(32),
        ),
        const SizedBox(height: 10),
        Text(
          'There was a problem connecting. Your information is safe.',
          textAlign: TextAlign.center,
          style: ClubType.inter(15, color: ClubColors.muted),
        ),
        const SizedBox(height: 32),
        PrimaryButton('Try again', onPressed: () => model.go(AppRoute.status)),
        const SizedBox(height: 10),
        SecondaryButton(
          'Back to profile',
          onPressed: () => model.go(AppRoute.profile),
        ),
      ],
    );
  }
}

class _InnerPage extends StatelessWidget {
  const _InnerPage({
    required this.title,
    required this.onBack,
    required this.child,
    this.supporting,
  });

  final String title;
  final String? supporting;
  final VoidCallback onBack;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                tooltip: 'Back',
                onPressed: onBack,
                icon: const ClubIcon('back'),
              ),
            ),
            Text(title, style: ClubType.lora(32)),
            if (supporting != null) ...[
              const SizedBox(height: 10),
              Text(
                supporting!,
                style: ClubType.inter(15, color: ClubColors.muted),
              ),
            ],
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
