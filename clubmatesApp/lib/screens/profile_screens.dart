import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../state/app_model.dart';
import '../theme/theme.dart';
import '../ui/club_icon.dart';
import '../ui/height_picker.dart';
import '../ui/liquid_glass.dart';
import '../ui/profile_prompts.dart';
import '../ui/widgets.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final model = AppScope.watch(context);
    final strength = _profileStrength(model);
    return MainShell(
      child: ListView(
        padding: EdgeInsets.only(bottom: ClubChrome.clearance(context)),
        children: [
          const SizedBox(height: 22),
          _ProfileHeader(model),
          const SizedBox(height: 26),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: _OutTonightCard(model),
          ),
          if (model.errorMessage != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
              child: Text(
                model.errorMessage!,
                style: ClubType.inter(13, color: ClubColors.error),
              ),
            ),
          _Section(
            title: 'Your profile',
            children: [
              _Row(
                icon: 'edit',
                label: 'Edit profile and photos',
                detail: strength < 100 ? '$strength% complete' : null,
                onPressed: () => model.go(AppRoute.editProfile),
              ),
              _Row(
                icon: 'shield',
                label: 'Verification',
                detail: model.isVerified ? 'Verified' : 'Not yet',
                onPressed: () => model.go(AppRoute.status),
              ),
            ],
          ),
          _Section(
            title: 'In Club',
            children: [
              _SwitchRow(
                icon: 'club',
                label: 'Show me in Club',
                caption: model.discoverable
                    ? 'People nearby can see your profile.'
                    : 'Hidden. Your mates can still reach you.',
                value: model.discoverable,
                onChanged: model.busy ? null : model.setDiscoverable,
              ),
              _Row(
                icon: 'location',
                label: 'Location and distance',
                detail: model.locationOn ? 'Within 10 km' : 'Off',
                onPressed: model.openNearby,
              ),
              _Row(
                icon: 'bell',
                label: 'Notifications',
                detail: model.notifyInvites ? 'On' : 'Off',
                onPressed: () => model.go(AppRoute.notifications),
              ),
            ],
          ),
          _Section(
            title: 'Safety',
            children: [
              _Row(
                icon: 'shield',
                label: 'Meeting safely',
                onPressed: () => _showMeetingSafely(context),
              ),
              _Row(
                icon: 'block',
                label: 'Blocked people',
                detail: model.blocked.isEmpty
                    ? 'None'
                    : '${model.blocked.length}',
                onPressed: () => _showBlocked(context),
              ),
            ],
          ),
          _Section(
            title: 'Account',
            children: [
              _Row(icon: 'logout', label: 'Log out', onPressed: model.signOut),
              _Row(
                icon: 'trash',
                label: 'Delete account',
                danger: true,
                onPressed: model.busy
                    ? null
                    : () => _confirmDeleteAccount(context),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 22, 32, 8),
            child: Text(
              'Your exact location is never shown. Blocking is instant, and '
              'deleting your account removes your profile, photos, invites '
              'and mates.',
              textAlign: TextAlign.center,
              style: ClubType.inter(12, color: ClubColors.muted, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

int _profileStrength(AppModel model) {
  final checks = [
    model.name.trim().isNotEmpty,
    model.location.trim().isNotEmpty,
    model.bio.trim().isNotEmpty,
    model.avatar.isNotEmpty,
    model.interests.isNotEmpty,
  ];
  return (checks.where((item) => item).length / checks.length * 100).round();
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader(this.model);

  final AppModel model;

  static const _ring = SweepGradient(
    colors: [
      Color(0xFF64316E),
      Color(0xFF994EA8),
      Color(0xFFE58C8A),
      Color(0xFF994EA8),
      Color(0xFF64316E),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final name = model.ageLabel.isEmpty
        ? model.displayName
        : '${model.displayName}, ${model.ageLabel}';
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            DecoratedBox(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: _ring,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x33994EA8),
                    blurRadius: 30,
                    offset: Offset(0, 12),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: ClubColors.paper,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(3),
                    child: ClipOval(
                      child: ProfilePhoto(
                        model.avatar,
                        width: 108,
                        height: 108,
                        radius: 54,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (model.isVerified)
              Positioned(
                right: 2,
                bottom: 4,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: ClubColors.brand,
                    shape: BoxShape.circle,
                    border: Border.all(color: ClubColors.paper, width: 3),
                  ),
                  child: const SizedBox.square(
                    dimension: 28,
                    child: Center(
                      child: ClubIcon('check', size: 15, color: Colors.white),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            name,
            textAlign: TextAlign.center,
            style: ClubType.lora(28, height: 1.15),
          ),
        ),
        const SizedBox(height: 6),
        PlaceLine(model.location, size: 13, verified: model.isVerified),
      ],
    );
  }
}

class _OutTonightCard extends StatelessWidget {
  const _OutTonightCard(this.model);

  final AppModel model;

  @override
  Widget build(BuildContext context) {
    final on = model.outTonight;
    final until = model.outTonightUntil;
    final caption = on && until != null
        ? 'Showing in Club until ${TimeOfDay.fromDateTime(until).format(context)}. '
              'It turns off on its own.'
        : 'Let people in Club know you are heading out.';
    void toggle(bool value) =>
        value ? _chooseOutTonight(context) : model.setOutTonight(on: false);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: on
              ? const [Color(0xFF2B1532), Color(0xFF64316E), Color(0xFF9A4E7E)]
              : const [Color(0xFF231C25), Color(0xFF2E2531), Color(0xFF3A2E3D)],
        ),
        boxShadow: [
          BoxShadow(
            color: on ? const Color(0x47994EA8) : const Color(0x24000000),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: model.busy ? null : () => toggle(!on),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 14, 18),
            child: Row(
              children: [
                _Pulse(on: on),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        on ? 'You are out tonight' : 'Going out tonight?',
                        style: ClubType.lora(
                          19,
                          height: 1.15,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        caption,
                        style: ClubType.inter(
                          12,
                          height: 1.4,
                          color: Colors.white.withValues(alpha: 0.72),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Switch.adaptive(
                  value: on,
                  activeTrackColor: const Color(0xFFE58C8A),
                  activeThumbColor: Colors.white,
                  inactiveTrackColor: Colors.white.withValues(alpha: 0.18),
                  onChanged: model.busy ? null : toggle,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Pulse extends StatefulWidget {
  const _Pulse({required this.on});

  final bool on;

  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _beat = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(_Pulse old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() {
    if (widget.on && !MediaQuery.disableAnimationsOf(context)) {
      if (!_beat.isAnimating) _beat.repeat();
    } else {
      _beat.stop();
      _beat.value = 0;
    }
  }

  @override
  void dispose() {
    _beat.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.on ? const Color(0xFF70D39A) : const Color(0x66FFFFFF);
    return SizedBox.square(
      dimension: 26,
      child: AnimatedBuilder(
        animation: _beat,
        builder: (context, _) {
          final t = _beat.value;
          return Stack(
            alignment: Alignment.center,
            children: [
              if (widget.on)
                Container(
                  width: 10 + 16 * t,
                  height: 10 + 16 * t,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.4 * (1 - t)),
                  ),
                ),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(shape: BoxShape.circle, color: color),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 26, 18, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 6, bottom: 10),
            child: Text(title, style: ClubType.lora(19, height: 1.1)),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: ClubColors.field,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0x121A1A1A)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0F281921),
                  blurRadius: 24,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Column(
                children: [
                  for (var i = 0; i < children.length; i++) ...[
                    if (i > 0)
                      const Padding(
                        padding: EdgeInsets.only(left: 62),
                        child: Divider(height: 1, color: ClubColors.border),
                      ),
                    children[i],
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RowIcon extends StatelessWidget {
  const _RowIcon(this.icon, {this.danger = false});

  final String icon;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: danger ? const Color(0x149E3328) : const Color(0xFFF5ECF7),
        borderRadius: BorderRadius.circular(10),
      ),
      child: SizedBox.square(
        dimension: 32,
        child: Center(
          child: ClubIcon(
            icon,
            size: 18,
            color: danger ? ClubColors.error : ClubColors.brand,
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.detail,
    this.danger = false,
  });

  final String icon;
  final String label;
  final VoidCallback? onPressed;
  final String? detail;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onPressed,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 58),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 14, 10),
            child: Row(
              children: [
                _RowIcon(icon, danger: danger),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: ClubType.inter(
                      15,
                      weight: FontWeight.w500,
                      color: danger ? ClubColors.error : ClubColors.ink,
                    ),
                  ),
                ),
                if (detail != null) ...[
                  const SizedBox(width: 10),
                  Text(
                    detail!,
                    style: ClubType.inter(13, color: ClubColors.muted),
                  ),
                ],
                if (!danger) ...[
                  const SizedBox(width: 6),
                  const ClubIcon(
                    'chevron',
                    size: 16,
                    color: ClubColors.disabled,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.icon,
    required this.label,
    required this.caption,
    required this.value,
    required this.onChanged,
  });

  final String icon;
  final String label;
  final String caption;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 10, 12),
      child: Row(
        children: [
          _RowIcon(icon),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: ClubType.inter(15, weight: FontWeight.w500)),
                const SizedBox(height: 3),
                Text(
                  caption,
                  style: ClubType.inter(
                    12,
                    color: ClubColors.muted,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeTrackColor: ClubColors.brand,
            activeThumbColor: Colors.white,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

Future<void> _showMeetingSafely(BuildContext context) {
  const tips = [
    (
      'Meet in public',
      'The first time, meet at the club or another busy place, not at '
          'someone\'s home.',
    ),
    ('Tell a friend', 'Share where you are going and who you are meeting.'),
    (
      'Keep your own ride',
      'Get there and back on your own terms, so you can leave whenever '
          'you want.',
    ),
    (
      'Watch your drink',
      'Keep it with you, and do not accept one you did not see poured.',
    ),
    (
      'Trust your gut',
      'If something feels off, leave. You can block anyone from their '
          'profile.',
    ),
  ];
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: ClubColors.paper,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Meeting safely', style: ClubType.lora(28)),
            const SizedBox(height: 6),
            Text(
              'A few habits that keep a good night good.',
              style: ClubType.inter(14, color: ClubColors.muted),
            ),
            const SizedBox(height: 20),
            for (final (index, tip) in tips.indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DecoratedBox(
                      decoration: const BoxDecoration(
                        color: Color(0xFFF5ECF7),
                        shape: BoxShape.circle,
                      ),
                      child: SizedBox.square(
                        dimension: 30,
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: ClubType.inter(
                              13,
                              weight: FontWeight.w700,
                              color: ClubColors.brand,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tip.$1,
                            style: ClubType.inter(15, weight: FontWeight.w600),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            tip.$2,
                            style: ClubType.inter(
                              13,
                              color: ClubColors.muted,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

Future<void> _showBlocked(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: ClubColors.paper,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) {
      final model = AppScope.watch(context);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Blocked people', style: ClubType.lora(28)),
              const SizedBox(height: 6),
              Text(
                'They cannot see you in Club or send you invites. '
                'Block someone from their profile.',
                style: ClubType.inter(14, color: ClubColors.muted, height: 1.4),
              ),
              const SizedBox(height: 18),
              if (model.blocked.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: Text(
                    'You have not blocked anyone.',
                    style: ClubType.inter(14, color: ClubColors.muted),
                  ),
                )
              else
                for (final person in model.blocked)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            person.name,
                            style: ClubType.inter(15, weight: FontWeight.w500),
                          ),
                        ),
                        OutlinedButton(
                          onPressed: model.busy
                              ? null
                              : () => model.unblock(person.id),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: ClubColors.ink,
                            side: const BorderSide(color: ClubColors.border),
                            shape: const StadiumBorder(),
                          ),
                          child: const Text('Unblock'),
                        ),
                      ],
                    ),
                  ),
            ],
          ),
        ),
      );
    },
  );
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
    final model = AppScope.read(context);
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
    final model = AppScope.watch(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          PinnedBackPage(
            onBack: () => model.go(AppRoute.profile),
            child: SafeArea(
              bottom: false,
              child: ListView(
                padding: EdgeInsets.fromLTRB(20, 8, 20, bottom + 100),
                children: [
                  const SizedBox(height: 44),
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
                    textCapitalization: TextCapitalization.words,
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
                    textCapitalization: TextCapitalization.words,
                    error: cityIssue(_location.text),
                    onChanged: (value) {
                      model.setLocation(value);
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 20),
                  const Eyebrow('Height'),
                  const SizedBox(height: 12),
                  HeightPicker(
                    cm: int.tryParse(model.height),
                    onChanged: (cm) => model.setHeight('$cm'),
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
                  const SizedBox(height: 28),
                  const Eyebrow('Prompts'),
                  const SizedBox(height: 6),
                  Text(
                    'They show between your photos on your profile.',
                    style: ClubType.inter(13, color: ClubColors.muted),
                  ),
                  const SizedBox(height: 12),
                  PromptEditorList(
                    prompts: model.prompts,
                    onChanged: model.setPrompt,
                    onRemove: model.removePrompt,
                  ),
                ],
              ),
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
                      heightIssue(model.height) != null
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
          'Choose the updates that are worth interrupting your night. These choices are saved to your account.',
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
              'When someone invites you, and when your invite is accepted.',
              style: ClubType.inter(12, color: ClubColors.muted),
            ),
            value: model.notifyInvites,
            activeThumbColor: ClubColors.brand,
            onChanged: model.busy
                ? null
                : (value) => model.setNotify(invites: value),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              'Mate messages',
              style: ClubType.inter(13, weight: FontWeight.w600),
            ),
            subtitle: Text(
              'When a mate sends you a message. The notification never shows what they wrote.',
              style: ClubType.inter(12, color: ClubColors.muted),
            ),
            value: model.notifyMates,
            activeThumbColor: ClubColors.brand,
            onChanged: model.busy
                ? null
                : (value) => model.setNotify(mates: value),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              'Nearby activity',
              style: ClubType.inter(13, weight: FontWeight.w600),
            ),
            subtitle: Text(
              'Coming soon. Your choice is saved for later.',
              style: ClubType.inter(12, color: ClubColors.muted),
            ),
            value: model.notifyNearby,
            activeThumbColor: ClubColors.brand,
            onChanged: model.busy
                ? null
                : (value) => model.setNotify(nearby: value),
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

class StatusScreen extends StatelessWidget {
  const StatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final model = AppScope.watch(context);
    return _InnerPage(
      title: 'Verification',
      supporting: model.isVerified
          ? 'Your profile has passed both checks.'
          : 'Verification is coming to Clubmates soon.',
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
            onPressed: model.isVerified
                ? null
                : () => ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Identity document checks will be available soon.',
                        ),
                      ),
                    ),
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
      body: PinnedBackPage(
        onBack: onBack,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              const SizedBox(height: 44),
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
      ),
    );
  }
}

Future<void> _chooseOutTonight(BuildContext context) async {
  final model = AppScope.read(context);
  final endTime = TimeOfDay.fromDateTime(endOfNight()).format(context);
  final choices = <(String, Duration?)>[
    ('End of night ($endTime)', null),
    ('2 hours', const Duration(hours: 2)),
    ('4 hours', const Duration(hours: 4)),
  ];
  final picked = await showModalBottomSheet<(String, Duration?)>(
    context: context,
    backgroundColor: ClubColors.paper,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Text(
              'Out tonight for how long?',
              style: ClubType.inter(16, weight: FontWeight.w600),
            ),
          ),
          for (final choice in choices)
            ListTile(
              title: Text(choice.$1, style: ClubType.inter(14)),
              onTap: () => Navigator.pop(context, choice),
            ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
  if (picked == null) return;
  await model.setOutTonight(on: true, forDuration: picked.$2);
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
