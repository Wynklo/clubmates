import 'dart:async';

import 'package:flutter/material.dart';

import '../club_icon.dart';
import '../mock_model.dart';
import '../theme.dart';
import '../widgets.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    final reduced = WidgetsBinding
        .instance
        .platformDispatcher
        .accessibilityFeatures
        .disableAnimations;
    if (reduced) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
    _timer = Timer(const Duration(milliseconds: 1700), () {
      if (!mounted) return;
      final model = MockScope.read(context);
      if (model.route == AppRoute.splash) model.go(AppRoute.phone);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final club = CurvedAnimation(
      parent: _controller,
      curve: const Cubic(0.2, 0.85, 0.25, 1.15),
    );
    final fade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.75, 1, curve: Curves.ease),
    );
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: club,
                  builder: (context, child) => Opacity(
                    opacity: club.value.clamp(0, 1),
                    child: Transform.translate(
                      offset: Offset(-18 * (1 - club.value), 0),
                      child: child,
                    ),
                  ),
                  child: Text(
                    'club',
                    style: ClubType.inter(
                      43,
                      weight: FontWeight.w600,
                      height: 1,
                      letterSpacing: 43 * -0.055,
                    ),
                  ),
                ),
                AnimatedBuilder(
                  animation: club,
                  builder: (context, child) => Opacity(
                    opacity: club.value.clamp(0, 1),
                    child: Transform.translate(
                      offset: Offset(18 * (1 - club.value), 0),
                      child: child,
                    ),
                  ),
                  child: Text(
                    'mates',
                    style: ClubType.inter(
                      43,
                      weight: FontWeight.w600,
                      height: 1,
                      letterSpacing: 43 * -0.055,
                      color: ClubColors.brand,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            FadeTransition(
              opacity: fade,
              child: Text(
                'NIGHTLIFE, TOGETHER',
                style: ClubType.inter(
                  10,
                  weight: FontWeight.w600,
                  height: 1,
                  letterSpacing: 2.2,
                  color: ClubColors.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PhoneScreen extends StatefulWidget {
  const PhoneScreen({super.key});

  @override
  State<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends State<PhoneScreen> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: MockScope.read(context).phone);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final model = MockScope.watch(context);
    return OnboardingFrame(
      title: "What's your number?",
      supporting: "We'll text you a code.",
      onBack: () => model.go(AppRoute.splash),
      footer: PrimaryButton(
        'Continue',
        onPressed: model.phone.length == 10
            ? () => model.go(AppRoute.otp)
            : null,
      ),
      children: [
        PhoneField(controller: _controller, onChanged: model.setPhone),
        const SizedBox(height: 20),
        const Note('By continuing, you agree to our Terms and Privacy Policy.'),
      ],
    );
  }
}

class OtpScreen extends StatelessWidget {
  const OtpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final model = MockScope.watch(context);
    final sentTo = model.phone.length == 10
        ? '+91 ${model.phone.substring(0, 5)} ${model.phone.substring(5)}'
        : '+91 98765 43210';
    return OnboardingFrame(
      title: 'Enter the code',
      supporting: 'Sent to $sentTo',
      onBack: () => model.go(AppRoute.phone),
      headerAction: TextLink(
        'Edit',
        color: ClubColors.brand,
        onPressed: () => model.go(AppRoute.phone),
      ),
      footer: PrimaryButton(
        'Verify',
        onPressed: model.otp.join().length == 6 ? model.verifyOtp : null,
      ),
      children: [
        OtpInput(values: model.otp, onChanged: model.setOtp),
        if (model.otpError) ...[
          const SizedBox(height: 12),
          Text(
            'Incorrect code. Try again.',
            style: ClubType.inter(13, color: ClubColors.error),
          ),
        ],
        const SizedBox(height: 4),
        const Align(
          alignment: Alignment.centerLeft,
          child: TextLink('Resend code'),
        ),
      ],
    );
  }
}

class NameScreen extends StatefulWidget {
  const NameScreen({super.key});

  @override
  State<NameScreen> createState() => _NameScreenState();
}

class _NameScreenState extends State<NameScreen> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: MockScope.read(context).name);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final model = MockScope.watch(context);
    return OnboardingFrame(
      title: 'Your name',
      supporting: 'What should people call you?',
      progress: 1,
      onBack: () => model.go(AppRoute.otp),
      footer: PrimaryButton(
        'Continue',
        onPressed: model.name.trim().isEmpty
            ? null
            : () => model.go(AppRoute.dob),
      ),
      children: [
        ClubField(
          hint: 'First name',
          controller: _controller,
          onChanged: model.setName,
        ),
      ],
    );
  }
}

class DobScreen extends StatelessWidget {
  const DobScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final model = MockScope.watch(context);
    return OnboardingFrame(
      title: 'When were you born?',
      supporting: 'You need to be 18 or older.',
      progress: 2,
      onBack: () => model.go(AppRoute.name),
      footer: PrimaryButton(
        'Continue',
        onPressed: () => model.go(AppRoute.location),
      ),
      children: [
        const Row(
          children: [
            Expanded(
              flex: 7,
              child: ClubField(hint: 'DD', keyboardType: TextInputType.number),
            ),
            SizedBox(width: 10),
            Expanded(
              flex: 7,
              child: ClubField(hint: 'MM', keyboardType: TextInputType.number),
            ),
            SizedBox(width: 10),
            Expanded(
              flex: 13,
              child: ClubField(
                hint: 'YYYY',
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Note('Your age will be visible on your profile.'),
      ],
    );
  }
}

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: MockScope.read(context).location);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final model = MockScope.watch(context);
    return OnboardingFrame(
      title: 'Where are you?',
      supporting: "We'll show you people heading out nearby.",
      progress: 3,
      onBack: () => model.go(AppRoute.dob),
      footer: PrimaryButton(
        'Continue',
        onPressed: () => model.go(AppRoute.nightlife),
      ),
      children: [
        ClubField(
          hint: 'Search a city',
          controller: _controller,
          onChanged: model.setLocation,
        ),
        const SizedBox(height: 20),
        const Eyebrow('Suggested locations'),
        const SizedBox(height: 12),
        ChipWrap(
          children: [
            for (final city in cityOptions)
              ChoiceChipButton(
                city,
                selected: model.location == city,
                onPressed: () {
                  _controller.text = city;
                  model.setLocation(city);
                },
              ),
          ],
        ),
      ],
    );
  }
}

class NightlifeScreen extends StatelessWidget {
  const NightlifeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final model = MockScope.watch(context);
    return OnboardingFrame(
      title: 'What kind of night are you after?',
      supporting: "Tell people what you're usually up for.",
      progress: 4,
      onBack: () => model.go(AppRoute.location),
      footer: PrimaryButton(
        'Continue',
        onPressed: () => model.go(AppRoute.about),
      ),
      children: [
        const ClubField(label: 'Tonight', hint: 'Dinner, then a bar.'),
        const SizedBox(height: 20),
        const ClubField(
          label: 'Usually out for',
          hint: 'Drinks, cafés and late-night food.',
        ),
        const SizedBox(height: 20),
        const ClubField(
          label: "I'll be at",
          hint: 'Somewhere around Koregaon Park.',
        ),
        const SizedBox(height: 20),
        ChipWrap(
          children: [
            for (final item in nightlifeOptions)
              ChoiceChipButton(
                item,
                selected: model.interests.contains(item),
                onPressed: () => model.toggleInterest(item),
              ),
          ],
        ),
      ],
    );
  }
}

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final model = MockScope.watch(context);
    return OnboardingFrame(
      title: 'A bit about you',
      progress: 5,
      onBack: () => model.go(AppRoute.nightlife),
      footer: PrimaryButton(
        'Continue',
        onPressed: () => model.go(AppRoute.photos),
      ),
      children: [
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
        const Eyebrow('Height'),
        const SizedBox(height: 12),
        const ClubField(hint: '172 cm', keyboardType: TextInputType.number),
      ],
    );
  }
}

class PhotosScreen extends StatelessWidget {
  const PhotosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final model = MockScope.watch(context);
    return OnboardingFrame(
      title: 'Add your photos',
      supporting: 'Your first photo is the one people see.',
      progress: 6,
      onBack: () => model.go(AppRoute.about),
      footer: PrimaryButton(
        'Continue',
        onPressed: () => model.go(AppRoute.identity),
      ),
      children: [
        const PhotoGrid(),
        const SizedBox(height: 8),
        const Row(
          children: [
            Expanded(child: SecondaryButton('Camera', icon: 'camera')),
            SizedBox(width: 8),
            Expanded(child: SecondaryButton('Upload', icon: 'plus')),
          ],
        ),
        const SizedBox(height: 12),
        const Note(
          'Use clear photos where people can see you. Hold and drag to reorder.',
        ),
      ],
    );
  }
}

class IdentityScreen extends StatelessWidget {
  const IdentityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final model = MockScope.watch(context);
    return OnboardingFrame(
      title: 'Verify your identity',
      supporting: 'Verification helps keep Clubmates real.',
      progress: 7,
      onBack: () => model.go(AppRoute.photos),
      footer: PrimaryButton(
        'Continue',
        onPressed: model.uploaded ? () => model.go(AppRoute.face) : null,
      ),
      children: [
        for (final type in ['Aadhaar', 'PAN']) ...[
          _IdOption(
            type,
            selected: model.idType == type,
            onPressed: () => model.setIdType(type),
          ),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 6),
        Material(
          color: model.uploaded ? ClubColors.soft : ClubColors.field,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: model.uploaded
                  ? const Color(0x66994EA8)
                  : const Color(0x591A1A1A),
              style: model.uploaded ? BorderStyle.solid : BorderStyle.solid,
            ),
          ),
          child: InkWell(
            onTap: model.markUploaded,
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 104,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ClubIcon(
                    model.uploaded ? 'check' : 'plus',
                    color: model.uploaded ? ClubColors.plum : ClubColors.ink,
                  ),
                  const SizedBox(width: 9),
                  Text(
                    model.uploaded ? 'Document uploaded' : 'Upload document',
                    style: ClubType.inter(
                      16,
                      weight: FontWeight.w600,
                      height: 1,
                      color: model.uploaded ? ClubColors.plum : ClubColors.ink,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Note(
          'Your identity document is encrypted and used only for verification. It is never shown on your profile.',
        ),
      ],
    );
  }
}

class _IdOption extends StatelessWidget {
  const _IdOption(
    this.label, {
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? ClubColors.soft : ClubColors.field,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? const Color(0x8C994EA8) : ClubColors.border,
        ),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: ClubType.inter(
                        16,
                        weight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Government ID verification',
                      style: ClubType.inter(
                        13,
                        color: ClubColors.muted,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: selected ? ClubColors.brand : ClubColors.field,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? ClubColors.brand : ClubColors.border,
                  ),
                ),
                child: selected
                    ? const Center(
                        child: ClubIcon('check', size: 16, color: Colors.white),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FaceScreen extends StatelessWidget {
  const FaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final model = MockScope.watch(context);
    return OnboardingFrame(
      title: "Confirm it's you",
      supporting: 'Look at the camera so we can verify your profile.',
      onBack: () => model.go(AppRoute.identity),
      footer: Column(
        children: [
          PrimaryButton(
            'Capture',
            onPressed: () => model.go(AppRoute.verified),
          ),
          Center(child: TextLink('Need help?', underline: false)),
        ],
      ),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 440,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const ProfilePhoto(ownPhoto),
                const ColoredBox(color: Color(0x14000000)),
                Positioned(
                  top: 70,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      width: 190,
                      height: 255,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(140),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.9),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 18,
                  child: Text(
                    'Face the light.',
                    textAlign: TextAlign.center,
                    style: ClubType.inter(
                      13,
                      color: Colors.white,
                      weight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class VerifiedScreen extends StatelessWidget {
  const VerifiedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CenteredScreen(
      children: [
        const SuccessMark(),
        Text(
          "You're verified",
          textAlign: TextAlign.center,
          style: ClubType.lora(32),
        ),
        const SizedBox(height: 10),
        Text(
          'Your profile is now verified.',
          textAlign: TextAlign.center,
          style: ClubType.inter(15, color: ClubColors.muted),
        ),
        const SizedBox(height: 32),
        PrimaryButton(
          'See people',
          onPressed: () => MockScope.read(context).go(AppRoute.club),
        ),
      ],
    );
  }
}
