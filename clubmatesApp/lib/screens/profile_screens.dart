import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../state/app_model.dart';
import '../theme/theme.dart';
import '../ui/club_icon.dart';
import '../ui/liquid_glass.dart';
import '../ui/widgets.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  var _safety = false;

  @override
  Widget build(BuildContext context) {
    final model = AppScope.watch(context);
    return MainShell(
      child: ListView(
        padding: EdgeInsets.only(bottom: ClubChrome.clearance(context)),
        children: [
          const PageHeading(
            title: 'Your profile',
            supporting: 'Manage your presence and peace of mind.',
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x14281921),
                        blurRadius: 24,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ProfilePhoto(
                    model.avatar,
                    width: 94,
                    height: 112,
                    radius: 18,
                  ),
                ),
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
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
            child: _ProfileStrength(model),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFFF1EEEF),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: const Color(0x171A1A1A)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                      child: _ProfileTab(
                        'Settings',
                        selected: !_safety,
                        onPressed: () => setState(() => _safety = false),
                      ),
                    ),
                    Expanded(
                      child: _ProfileTab(
                        'Safety',
                        icon: 'shield',
                        selected: _safety,
                        onPressed: () => setState(() => _safety = true),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_safety)
            const _SafetyList()
          else
            _SettingsList(onSignOut: model.signOut),
        ],
      ),
    );
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab(
    this.label, {
    required this.selected,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;
  final String? icon;

  @override
  Widget build(BuildContext context) {
    final color = selected ? ClubColors.ink : ClubColors.muted;
    return Material(
      color: selected ? ClubColors.field : Colors.transparent,
      borderRadius: BorderRadius.circular(11),
      elevation: selected ? 1 : 0,
      shadowColor: const Color(0x17281921),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(11),
        child: SizedBox(
          height: 40,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                ClubIcon(icon!, size: 17, color: color),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: ClubType.inter(
                  12,
                  color: color,
                  weight: FontWeight.w600,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileStrength extends StatelessWidget {
  const _ProfileStrength(this.model);

  final AppModel model;

  @override
  Widget build(BuildContext context) {
    final checks = [
      model.name.trim().isNotEmpty,
      model.location.trim().isNotEmpty,
      model.bio.trim().isNotEmpty,
      model.avatar.isNotEmpty,
      model.interests.isNotEmpty,
    ];
    final done = checks.where((item) => item).length;
    final percent = ((done / checks.length) * 100).round();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ClubColors.field,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0x171A1A1A)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14281921),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Profile strength',
                        style: ClubType.inter(
                          13,
                          weight: FontWeight.w600,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        percent == 100
                            ? 'People can see your name, city, bio, and photos.'
                            : 'Add the missing details so people can recognise you.',
                        style: ClubType.inter(
                          10,
                          color: ClubColors.muted,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '$percent%',
                  style: ClubType.inter(
                    13,
                    color: ClubColors.brand,
                    weight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: done / checks.length,
                minHeight: 4,
                backgroundColor: const Color(0xFFEEE9ED),
                color: ClubColors.brand,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsList extends StatelessWidget {
  const _SettingsList({required this.onSignOut});

  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final model = AppScope.watch(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
      child: DecoratedBox(
        decoration: _cardDecoration,
        child: Column(
          children: [
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
              'Push notifications',
              onPressed: () => model.go(AppRoute.notifications),
            ),
            SettingsRow(
              'Location & distance',
              detail: '10 km',
              onPressed: model.openNearby,
            ),
            SettingsRow(
              'Settings',
              onPressed: () => model.go(AppRoute.settings),
            ),
            SettingsRow('Log out', divider: false, onPressed: onSignOut),
          ],
        ),
      ),
    );
  }
}

const _cardDecoration = BoxDecoration(
  color: ClubColors.field,
  borderRadius: BorderRadius.all(Radius.circular(18)),
  border: Border.fromBorderSide(BorderSide(color: Color(0x171A1A1A))),
  boxShadow: [
    BoxShadow(color: Color(0x14281921), blurRadius: 24, offset: Offset(0, 8)),
  ],
);

class _SafetyList extends StatelessWidget {
  const _SafetyList();

  @override
  Widget build(BuildContext context) {
    final model = AppScope.watch(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0x24994EA8)),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF8F1F9), ClubColors.field],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 22, 18, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: ClubColors.field,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x14281921),
                          blurRadius: 24,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const SizedBox(
                      width: 48,
                      height: 48,
                      child: Center(
                        child: ClubIcon(
                          'shield',
                          size: 26,
                          color: ClubColors.brand,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your safety comes first',
                    style: ClubType.lora(22, height: 1.2),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'Control sensitive information, get help, and understand how Clubmates protects your privacy.',
                    style: ClubType.inter(13, color: ClubColors.muted),
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: DecoratedBox(
            decoration: _cardDecoration,
            child: Column(
              children: [
                const SettingsRow('Privacy controls'),
                const SettingsRow('Blocked people'),
                for (final person in model.blocked)
                  SettingsRow(
                    person.name,
                    detail: 'Unblock',
                    onPressed: () => model.unblock(person.id),
                  ),
                const SettingsRow('Report a concern'),
                const SettingsRow('Meeting safely'),
                const SettingsRow('Emergency resources'),
                const SettingsRow(
                  'Data & sensitive information',
                  divider: false,
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
          child: Text(
            'Logging out ends this session. Deleting an account removes your profile, photos, invites, mates, and blocks. That cannot be undone.',
            style: ClubType.inter(12, color: ClubColors.muted),
          ),
        ),
      ],
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
  late final TextEditingController _height;

  @override
  void initState() {
    super.initState();
    final model = AppScope.read(context);
    _name = TextEditingController(text: model.displayName);
    _location = TextEditingController(text: model.location);
    _bio = TextEditingController(text: model.bio);
    _height = TextEditingController(text: model.height);
  }

  @override
  void dispose() {
    _name.dispose();
    _location.dispose();
    _bio.dispose();
    _height.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final model = AppScope.watch(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
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
                  child: ProfilePhoto(
                    model.avatar,
                    width: 110,
                    height: 130,
                    radius: 18,
                  ),
                ),
                const SizedBox(height: 28),
                ClubField(
                  label: 'Name',
                  hint: 'Aanya',
                  controller: _name,
                  error: nameIssue(_name.text),
                  onChanged: (value) {
                    model.setName(value);
                    setState(() {});
                  },
                ),
                const SizedBox(height: 20),
                ClubField(
                  label: 'Bio',
                  hint: 'What are you up for tonight?',
                  controller: _bio,
                  maxLines: 4,
                  error: bioIssue(_bio.text),
                  inputFormatters: [LengthLimitingTextInputFormatter(500)],
                  onChanged: (value) {
                    model.setBio(value);
                    setState(() {});
                  },
                ),
                const SizedBox(height: 20),
                ClubField(
                  label: 'Location',
                  hint: 'Bengaluru',
                  controller: _location,
                  error: cityIssue(_location.text),
                  onChanged: (value) {
                    model.setLocation(value);
                    setState(() {});
                  },
                ),
                const SizedBox(height: 20),
                ClubField(
                  label: 'Height',
                  hint: '172',
                  controller: _height,
                  keyboardType: TextInputType.number,
                  error: heightIssue(_height.text),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(3),
                  ],
                  onChanged: (value) {
                    model.setHeight(value);
                    setState(() {});
                  },
                ),
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
                const Eyebrow('Who do you want to meet?'),
                const SizedBox(height: 12),
                ChipWrap(
                  children: [
                    for (final option in interestLabels.values)
                      ChoiceChipButton(
                        option,
                        selected: model.lookingFor == option,
                        onPressed: () => model.setLookingFor(option),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                const PhotoGrid(),
              ],
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: ClubChrome.barGap(context),
            child: PrimaryButton(
              'Save changes',
              loading: model.busy,
              onPressed:
                  nameIssue(_name.text, required: true) != null ||
                      cityIssue(_location.text, required: true) != null ||
                      bioIssue(_bio.text) != null ||
                      heightIssue(_height.text) != null
                  ? null
                  : () => model.saveEdits(
                      nextName: _name.text,
                      nextBio: _bio.text,
                      nextCity: _location.text,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final model = AppScope.watch(context);
    return _InnerPage(
      title: 'Push notifications',
      supporting:
          'Choose the updates that are worth interrupting your night. These choices stay on this phone.',
      onBack: () => model.go(AppRoute.profile),
      child: Column(
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              'New invites',
              style: ClubType.inter(13, weight: FontWeight.w600),
            ),
            subtitle: Text(
              'When someone wants to go out with you.',
              style: ClubType.inter(12, color: ClubColors.muted),
            ),
            value: model.notifyInvites,
            activeThumbColor: ClubColors.brand,
            onChanged: (value) => model.setNotify(invites: value),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              'Mate messages',
              style: ClubType.inter(13, weight: FontWeight.w600),
            ),
            subtitle: Text(
              'Messages and shared plans from your mates.',
              style: ClubType.inter(12, color: ClubColors.muted),
            ),
            value: model.notifyMates,
            activeThumbColor: ClubColors.brand,
            onChanged: (value) => model.setNotify(mates: value),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              'Nearby activity',
              style: ClubType.inter(13, weight: FontWeight.w600),
            ),
            subtitle: Text(
              'People active within your distance tonight.',
              style: ClubType.inter(12, color: ClubColors.muted),
            ),
            value: model.notifyNearby,
            activeThumbColor: ClubColors.brand,
            onChanged: (value) => model.setNotify(nearby: value),
          ),
        ],
      ),
    );
  }
}

class NearbyScreen extends StatelessWidget {
  const NearbyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final model = AppScope.watch(context);
    return _InnerPage(
      title: 'Location & distance',
      supporting: 'Closer plans mean a better chance of actually meeting.',
      onBack: () => model.go(model.nearbyBack),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PrimaryButton(
            model.locationOn ? 'Location is on' : 'Allow location',
            loading: model.busy,
            onPressed: model.locationOn ? null : model.allowLocation,
          ),
          if (model.errorMessage != null) ...[
            const SizedBox(height: 10),
            Text(
              model.errorMessage!,
              textAlign: TextAlign.start,
              style: ClubType.inter(13, color: ClubColors.error),
            ),
          ],
          const SizedBox(height: 28),
          const Align(
            alignment: Alignment.centerLeft,
            child: Eyebrow('Distance'),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.start,
            children: [
              ChoiceChipButton(
                'Within 10 km',
                selected: model.nearbyOnly,
                onPressed: model.chooseNearby,
              ),
              ChoiceChipButton(
                'Further · Paid',
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Further than 10 km'),
                      content: const Text(
                        'Searching past 10 km is paid. Payment is not available in this version, so Club stays within 10 km.',
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
          const SizedBox(height: 16),
          Text(
            'People further than 10 km stay hidden. Your exact location is not shown on your profile.',
            textAlign: TextAlign.start,
            style: ClubType.inter(12, color: ClubColors.muted, height: 1.55),
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
    final model = AppScope.watch(context);
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
          const SettingsRow('Account'),
          SettingsRow(
            'Notifications',
            onPressed: () => model.go(AppRoute.notifications),
          ),
          const SettingsRow('Privacy'),
          SettingsRow('Location', onPressed: model.openNearby),
          SettingsRow(
            'Verification',
            onPressed: () => model.go(AppRoute.status),
          ),
          const SettingsRow('Blocked people'),
          const SettingsRow('Help'),
          const SettingsRow('Terms'),
          const SettingsRow('Privacy Policy'),
          for (final person in model.blocked)
            SettingsRow(
              person.name,
              detail: 'Unblock',
              onPressed: () => model.unblock(person.id),
            ),
          SettingsRow(
            'Delete account',
            danger: true,
            divider: false,
            onPressed: model.busy ? null : () => _confirmDeleteAccount(context),
          ),
          if (model.errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              model.errorMessage!,
              style: ClubType.inter(12, color: ClubColors.error, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }
}

class StatusScreen extends StatelessWidget {
  const StatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final model = AppScope.watch(context);
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
    final model = AppScope.read(context);
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
        PrimaryButton('Try again', loading: model.busy, onPressed: model.retry),
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
            Text(title, textAlign: TextAlign.start, style: ClubType.lora(32)),
            if (supporting != null) ...[
              const SizedBox(height: 10),
              Text(
                supporting!,
                textAlign: TextAlign.start,
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

Future<void> _confirmDeleteAccount(BuildContext context) async {
  final model = AppScope.read(context);
  final first = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete account'),
      content: Text(
        model.live
            ? 'This permanently removes your profile, photos, invites, mates, and blocks. You will be signed out.'
            : 'No account is stored yet. This clears the session on this phone.',
        style: ClubType.inter(14, height: 1.45),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Continue'),
        ),
      ],
    ),
  );
  if (first != true || !context.mounted) return;

  final second = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete account?'),
      content: Text(
        model.live
            ? 'This cannot be undone. Your account and the data stored for it will be deleted.'
            : 'Clear this session on this phone?',
        style: ClubType.inter(14, height: 1.45),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(
            'Delete account',
            style: ClubType.inter(14, color: ClubColors.error),
          ),
        ),
      ],
    ),
  );
  if (second != true || !context.mounted) return;
  await model.deleteAccount();
}
