import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../state/app_model.dart';
import '../theme/theme.dart';
import '../ui/height_picker.dart';
import '../ui/profile_prompts.dart';
import '../ui/widgets.dart';

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
      final model = AppScope.read(context);
      if (model.route == AppRoute.splash) model.start();
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
    final club = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    final fade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.75, 1, curve: Curves.ease),
    );
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FadeTransition(
                opacity: club,
                child: Image.asset(
                  'assets/photos/clubmateslogo.png',
                  width: 240,
                  fit: BoxFit.contain,
                ),
              ),
              FadeTransition(
                opacity: fade,
                child: Text(
                  'NIGHTLIFE, TOGETHER',
                  style: ClubType.inter(
                    10,
                    weight: FontWeight.w600,
                    height: 1,
                    letterSpacing: 2.2,
                    color: ClubColors.paper,
                  ),
                ),
              ),
            ],
          ),
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
    _controller = TextEditingController(text: AppScope.read(context).phone);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final model = AppScope.watch(context);
    return OnboardingFrame(
      title: "What's your number?",
      supporting: model.testLogin
          ? 'Any Indian number. The test code is 111111.'
          : "We'll text you a code.",
      error: model.errorMessage,
      onBack: () => model.go(AppRoute.splash),
      footer: PrimaryButton(
        'Continue',
        loading: model.busy,
        onPressed: phoneIssue(model.phone) != null
            ? null
            : () => model.sendCode(),
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
    final model = AppScope.watch(context);
    final sentTo = model.phone.length == 10
        ? '+91 ${model.phone.substring(0, 5)} ${model.phone.substring(5)}'
        : '+91 98765 43210';
    return OnboardingFrame(
      title: 'Enter the code',
      supporting: model.testLogin
          ? 'Enter 111111 to continue.'
          : 'Sent to $sentTo',
      error: model.errorMessage,
      onBack: () => model.go(AppRoute.phone),
      headerAction: TextLink(
        'Edit',
        color: ClubColors.brand,
        onPressed: () => model.go(AppRoute.phone),
      ),
      footer: PrimaryButton(
        'Verify',
        loading: model.busy,
        onPressed: model.otp.join().length != 6 ? null : model.verifyOtp,
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
        const Align(alignment: Alignment.centerLeft, child: _ResendCode()),
      ],
    );
  }
}

class InterestScreen extends StatelessWidget {
  const InterestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final model = AppScope.watch(context);
    return OnboardingFrame(
      title: 'Who do you want to meet?',
      supporting: 'Club shows people of the gender you choose.',
      error: model.errorMessage,
      progress: 1,
      onBack: () => model.go(AppRoute.otp),
      footer: PrimaryButton(
        'Continue',
        loading: model.busy,
        onPressed: interestCode(model.lookingFor) == null
            ? null
            : model.saveInterest,
      ),
      children: [
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
    _controller = TextEditingController(text: AppScope.read(context).name);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final model = AppScope.watch(context);
    return OnboardingFrame(
      title: 'Your name',
      supporting: 'What should people call you?',
      error: model.errorMessage,
      progress: 2,
      onBack: () => model.go(AppRoute.interest),
      footer: PrimaryButton(
        'Continue',
        loading: model.busy,
        onPressed: nameIssue(model.name, required: true) != null
            ? null
            : model.saveName,
      ),
      children: [
        ClubField(
          hint: 'First name',
          controller: _controller,
          textCapitalization: TextCapitalization.words,
          onChanged: model.setName,
        ),
      ],
    );
  }
}

class DobScreen extends StatefulWidget {
  const DobScreen({super.key});

  @override
  State<DobScreen> createState() => _DobScreenState();
}

class _DobScreenState extends State<DobScreen> {
  static const _marker = '\u200b';
  static const _limits = [2, 2, 4];

  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _nodes;
  late final List<String> _digits;
  var _editing = false;

  @override
  void initState() {
    super.initState();
    final model = AppScope.read(context);
    _digits = [model.month, model.day, model.year];
    _controllers = [
      for (final digits in _digits) TextEditingController(text: _shown(digits)),
    ];
    _nodes = List.generate(3, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _nodes) {
      node.dispose();
    }
    super.dispose();
  }

  String _shown(String digits) => digits.isEmpty ? _marker : digits;

  void _show(int index, String digits) {
    final text = _shown(digits);
    final controller = _controllers[index];
    if (controller.text == text) return;
    _editing = true;
    controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    _editing = false;
  }

  void _commit(int index, String digits) {
    _digits[index] = digits;
    final model = AppScope.read(context);
    switch (index) {
      case 0:
        model.setDobPart(nextMonth: digits);
      case 1:
        model.setDobPart(nextDay: digits);
      case 2:
        model.setDobPart(nextYear: digits);
    }
  }

  void _onChanged(int index, String raw) {
    if (_editing) return;
    final before = _digits[index];
    final typed = raw.replaceAll(_marker, '').replaceAll(RegExp(r'\D'), '');
    if (typed.isEmpty) {
      _commit(index, '');
      _show(index, '');
      if (before.isNotEmpty || index == 0) return;
      final previous = _digits[index - 1];
      final trimmed = previous.isEmpty
          ? ''
          : previous.substring(0, previous.length - 1);
      _commit(index - 1, trimmed);
      _show(index - 1, trimmed);
      _nodes[index - 1].requestFocus();
      return;
    }
    if (typed.length <= _limits[index]) {
      _commit(index, typed);
      _show(index, typed);
      if (typed.length == _limits[index] && index < 2) {
        _nodes[index + 1].requestFocus();
      }
      return;
    }
    final keep = typed.substring(0, _limits[index]);
    final extra = typed.substring(_limits[index]);
    _commit(index, keep);
    _show(index, keep);
    if (index == 2) return;
    if (_digits[index + 1].isEmpty) {
      _onChanged(index + 1, extra);
      return;
    }
    _nodes[index + 1].requestFocus();
  }

  void _selectBox(int index) {
    final text = _controllers[index].text;
    if (text.isEmpty || text == _marker) return;
    _controllers[index].selection = TextSelection(
      baseOffset: 0,
      extentOffset: text.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    final model = AppScope.watch(context);
    const labels = ['Month', 'Date', 'Year'];
    const hints = ['04', '12', '1998'];
    return OnboardingFrame(
      title: 'When were you born?',
      supporting: 'Month, date, then year. You need to be 18 or older.',
      error: model.errorMessage,
      progress: 3,
      onBack: () => model.go(AppRoute.name),
      footer: PrimaryButton(
        'Continue',
        loading: model.busy,
        onPressed: model.dobReady ? model.saveDob : null,
      ),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < 3; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              Expanded(
                flex: i == 2 ? 2 : 1,
                child: ClubField(
                  label: labels[i],
                  hint: hints[i],
                  controller: _controllers[i],
                  focusNode: _nodes[i],
                  autofocus: i == 0,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  onChanged: (value) => _onChanged(i, value),
                  onTap: () => _selectBox(i),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        const Note('Example: 04 / 12 / 1998. Only your age is shown.'),
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
    _controller = TextEditingController(text: AppScope.read(context).location);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final model = AppScope.watch(context);
    return OnboardingFrame(
      title: 'Where are you?',
      supporting: "We'll show you people heading out nearby.",
      error: model.errorMessage,
      progress: 4,
      onBack: () => model.go(AppRoute.dob),
      footer: PrimaryButton(
        'Continue',
        loading: model.busy,
        onPressed: cityIssue(model.location, required: true) != null
            ? null
            : model.saveCity,
      ),
      children: [
        SecondaryButton(
          model.locating ? 'Finding you…' : 'Use my current location',
          icon: 'location',
          loading: model.locating,
          onPressed: () async {
            await model.useCurrentLocation();
            if (mounted) _controller.text = model.location;
          },
        ),
        const SizedBox(height: 14),
        ClubField(
          hint: 'Or type your city',
          controller: _controller,
          textCapitalization: TextCapitalization.words,
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
    final model = AppScope.watch(context);
    return OnboardingFrame(
      title: 'What kind of night are you after?',
      supporting: "Tell people what you're usually up for.",
      progress: 5,
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

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  @override
  Widget build(BuildContext context) {
    final model = AppScope.watch(context);
    return OnboardingFrame(
      title: 'A bit about you',
      error: model.errorMessage,
      progress: 6,
      onBack: () => model.go(AppRoute.nightlife),
      footer: PrimaryButton(
        'Continue',
        loading: model.busy,
        onPressed: heightIssue(model.height) != null ? null : model.saveAbout,
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
        HeightPicker(
          cm: int.tryParse(model.height),
          onChanged: (cm) => model.setHeight('$cm'),
        ),
      ],
    );
  }
}

class PhotosScreen extends StatelessWidget {
  const PhotosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final model = AppScope.watch(context);
    return OnboardingFrame(
      title: 'Add your photos',
      supporting: 'Add up to 3 photos. The first one is the one people see.',
      error: model.errorMessage,
      progress: 7,
      onBack: () => model.go(AppRoute.about),
      footer: PrimaryButton(
        'Continue',
        loading: model.busy,
        onPressed: model.ownPhotos.isEmpty
            ? null
            : () => model.go(AppRoute.prompts),
      ),
      children: [
        const PhotoGrid(),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: SecondaryButton(
                'Camera',
                icon: 'camera',
                loading: model.busy,
                onPressed: () => model.pickPhoto(camera: true),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SecondaryButton(
                'Upload',
                icon: 'plus',
                loading: model.busy,
                onPressed: () => model.pickPhoto(camera: false),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Note(
          'Use clear photos where people can see you. New photos stay pending until Clubmates approves them.',
        ),
      ],
    );
  }
}

class PromptsScreen extends StatelessWidget {
  const PromptsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final model = AppScope.watch(context);
    return OnboardingFrame(
      title: 'Add your prompts',
      supporting:
          'Answer up to 3 prompts. They sit between your photos and give people something to talk about.',
      error: model.errorMessage,
      progress: 8,
      onBack: () => model.go(AppRoute.photos),
      footer: PrimaryButton(
        'Continue',
        loading: model.busy,
        onPressed: model.prompts.isEmpty
            ? null
            : () => model.savePrompts(onboarding: true),
      ),
      children: [
        PromptEditorList(
          prompts: model.prompts,
          onChanged: model.setPrompt,
          onRemove: model.removePrompt,
        ),
        const SizedBox(height: 12),
        const Note(
          'Add at least one. You can change them later in your profile.',
        ),
      ],
    );
  }
}

class FaceScreen extends StatelessWidget {
  const FaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final model = AppScope.watch(context);
    return OnboardingFrame(
      title: "Confirm it's you",
      supporting: 'Look at the camera so we can verify your profile.',
      onBack: () => model.go(AppRoute.prompts),
      footer: Column(
        mainAxisSize: MainAxisSize.min,
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
                ProfilePhoto(model.avatar.isEmpty ? ownPhoto : model.avatar),
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
    final model = AppScope.watch(context);
    return CenteredScreen(
      children: [
        const SuccessMark(),
        Text(
          model.isVerified ? "You're verified" : "You're in",
          textAlign: TextAlign.center,
          style: ClubType.lora(32),
        ),
        const SizedBox(height: 10),
        Text(
          model.isVerified
              ? 'Your profile is now verified.'
              : 'Your profile is ready. A verified badge appears only after Clubmates confirms it.',
          textAlign: TextAlign.center,
          style: ClubType.inter(15, color: ClubColors.muted),
        ),
        const SizedBox(height: 32),
        PrimaryButton(
          'See people',
          loading: model.busy,
          onPressed: model.enterApp,
        ),
      ],
    );
  }
}

class _ResendCode extends StatelessWidget {
  const _ResendCode();

  @override
  Widget build(BuildContext context) {
    final model = AppScope.watch(context);
    return model.busy
        ? const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: ClubPulse(color: ClubColors.brand, size: 6),
          )
        : TextLink(
            'Resend code',
            onPressed: () => model.sendCode(resend: true),
          );
  }
}
