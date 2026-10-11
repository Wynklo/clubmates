import 'package:flutter/material.dart';

import '../club_icon.dart';
import '../liquid_glass.dart';
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
        padding: EdgeInsets.only(bottom: ClubChrome.clearance(context)),
        children: [
          const PageHeading(title: 'Your profile'),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Row(
              children: [
                ProfilePhoto(model.avatar, width: 94, height: 112, radius: 14),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        model.ageLabel.isEmpty
                            ? model.displayName
                            : '${model.displayName}, ${model.ageLabel}',
                        style: ClubType.lora(23, height: 1.2),
                      ),
                      const SizedBox(height: 5),
                      PlaceLine(
                        model.location,
                        size: 12,
                        verified: model.isVerified,
                      ),
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
                  detail: model.isVerified ? 'Verified' : 'Not yet',
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
                SettingsRow('Log out', onPressed: model.signOut),
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
    _bio = TextEditingController(text: model.bio);
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
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: ListView(
              padding: EdgeInsets.fromLTRB(20, 8, 20, bottom + 100),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: GlassIconButton(
                    onPressed: () => model.go(AppRoute.profile),
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
                        const Positioned(
                          right: 0,
                          bottom: 0,
                          child: LiquidGlass(
                            borderRadius: BorderRadius.all(Radius.circular(21)),
                            child: SizedBox(
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
                  children: [
                    for (final option in sexOptions)
                      ChoiceChipButton(
                        option,
                        selected: model.sex == option,
                        onPressed: () => model.setSex(option),
                      ),
                  ],
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
          Positioned(
            left: 16,
            right: 16,
            bottom: bottom + 10,
            child: LiquidGlass(
              borderRadius: BorderRadius.circular(32),
              padding: const EdgeInsets.all(6),
              child: PrimaryButton(
                'Save changes',
                onPressed: model.busy
                    ? null
                    : () => model.saveEdits(
                        nextName: _name.text,
                        nextBio: _bio.text,
                        nextCity: _location.text,
                      ),
              ),
            ),
          ),
        ],
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
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Discoverable', style: ClubType.inter(14)),
            subtitle: Text(
              'People can find you in Club when this is on.',
              style: ClubType.inter(12, color: ClubColors.muted),
            ),
            value: model.discoverable,
            activeThumbColor: ClubColors.brand,
            onChanged: model.busy ? null : model.setDiscoverable,
          ),
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
            if (label != 'Blocked people') SettingsRow(label),
          for (final person in model.blocked)
            SettingsRow(
              person.name,
              detail: 'Unblock',
              onPressed: () => model.unblock(person.id),
            ),
          SettingsRow(
            'Delete account',
            danger: true,
            onPressed: () {
              showDialog<void>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete account'),
                  content: const Text(
                    'Account deletion is not finished. This does not erase your profile or photos. Log out to end this session.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
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
          Text(
            model.isVerified ? 'Profile verified' : 'Not verified yet',
            style: ClubType.lora(27, height: 1.2),
          ),
          const SizedBox(height: 9),
          Text(
            model.isVerified
                ? 'Verified profiles help everyone feel more confident making plans.'
                : 'Identity and face checks are not part of this version. Clubmates adds the badge after a real check.',
            textAlign: TextAlign.center,
            style: ClubType.inter(14, color: ClubColors.muted),
          ),
          const SizedBox(height: 28),
          SettingsRow(
            'Identity document',
            detail: model.isVerified ? 'Verified' : 'Not checked',
          ),
          SettingsRow(
            'Face check',
            detail: model.isVerified ? 'Verified' : 'Not checked',
          ),
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
        Padding(
          padding: const EdgeInsets.only(bottom: 26),
          child: LiquidGlass(
            borderRadius: BorderRadius.circular(27),
            child: SizedBox(
              width: 54,
              height: 54,
              child: Center(
                child: Text(
                  '!',
                  style: ClubType.lora(28, color: ClubColors.error, height: 1),
                ),
              ),
            ),
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
        PrimaryButton('Try again', onPressed: model.retry),
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
              child: GlassIconButton(onPressed: onBack),
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
