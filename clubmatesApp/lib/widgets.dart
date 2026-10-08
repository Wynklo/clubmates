import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'club_icon.dart';
import 'mock_model.dart';
import 'theme.dart';

class Wordmark extends StatelessWidget {
  const Wordmark({super.key, this.large = false});

  final bool large;

  @override
  Widget build(BuildContext context) {
    final size = large ? 43.0 : 22.0;
    final style = ClubType.inter(
      size,
      weight: FontWeight.w600,
      height: 1,
      letterSpacing: size * -0.055,
    );
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          const TextSpan(text: 'club'),
          TextSpan(
            text: 'mates',
            style: style.copyWith(color: ClubColors.brand),
          ),
        ],
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton(this.label, {super.key, this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Material(
      color: enabled ? ClubColors.ink : ClubColors.disabledFill,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: enabled ? ClubColors.ink : ClubColors.disabledLine,
        ),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 48,
          width: double.infinity,
          child: Center(
            child: Text(
              label,
              style: ClubType.inter(
                16,
                weight: FontWeight.w600,
                height: 1,
                color: enabled ? ClubColors.paper : ClubColors.disabledText,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  const SecondaryButton(
    this.label, {
    super.key,
    this.onPressed,
    this.icon,
    this.foreground,
  });

  final String label;
  final VoidCallback? onPressed;
  final String? icon;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final color = foreground ?? ClubColors.ink;
    return Material(
      color: ClubColors.paper,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: ClubColors.border),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 48,
          width: double.infinity,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                ClubIcon(icon!, size: 18, color: color),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: ClubType.inter(
                  16,
                  weight: FontWeight.w600,
                  height: 1,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TextLink extends StatelessWidget {
  const TextLink(
    this.label, {
    super.key,
    this.onPressed,
    this.color = ClubColors.ink,
    this.underline = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final bool underline;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: color,
        minimumSize: const Size(0, 44),
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        label,
        style:
            ClubType.inter(
              15,
              weight: FontWeight.w600,
              height: 1,
              color: color,
            ).copyWith(
              decoration: underline
                  ? TextDecoration.underline
                  : TextDecoration.none,
              decorationColor: color,
            ),
      ),
    );
  }
}

class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text.toUpperCase(), style: ClubType.eyebrow);
  }
}

class ClubField extends StatelessWidget {
  const ClubField({
    super.key,
    this.label,
    required this.hint,
    this.controller,
    this.onChanged,
    this.keyboardType,
    this.inputFormatters,
    this.maxLines = 1,
  });

  final String? label;
  final String hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label!.toUpperCase(), style: ClubType.eyebrow),
          const SizedBox(height: 8),
        ],
        TextField(
          controller: controller,
          onChanged: onChanged,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          maxLines: maxLines,
          style: ClubType.inter(16, height: 1.3),
          cursorColor: ClubColors.brand,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: ClubType.inter(
              16,
              color: ClubColors.disabled,
              height: 1.3,
            ),
            filled: true,
            fillColor: ClubColors.field,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 14,
              vertical: maxLines > 1 ? 14 : 14,
            ),
            constraints: maxLines == 1
                ? const BoxConstraints(minHeight: 48)
                : const BoxConstraints(minHeight: 96),
            enabledBorder: _border(ClubColors.border),
            focusedBorder: _border(ClubColors.brand, width: 1.5),
          ),
        ),
      ],
    );
  }

  OutlineInputBorder _border(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}

class PhoneField extends StatelessWidget {
  const PhoneField({super.key, required this.controller, this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: ClubColors.field,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ClubColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13),
            decoration: const BoxDecoration(
              border: Border(right: BorderSide(color: ClubColors.border)),
            ),
            child: Center(
              child: Text(
                '+91',
                style: ClubType.inter(16, weight: FontWeight.w500, height: 1),
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              onChanged: onChanged,
              style: ClubType.inter(17, height: 1),
              cursorColor: ClubColors.brand,
              decoration: InputDecoration(
                hintText: '98765 43210',
                hintStyle: ClubType.inter(
                  17,
                  color: ClubColors.disabled,
                  height: 1,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                isCollapsed: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OtpInput extends StatefulWidget {
  const OtpInput({super.key, required this.values, required this.onChanged});

  final List<String> values;
  final void Function(int index, String value) onChanged;

  @override
  State<OtpInput> createState() => _OtpInputState();
}

class _OtpInputState extends State<OtpInput> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _nodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      6,
      (index) => TextEditingController(text: widget.values[index]),
    );
    _nodes = List.generate(6, (_) => FocusNode());
  }

  @override
  void didUpdateWidget(OtpInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    for (var i = 0; i < 6; i++) {
      if (_controllers[i].text != widget.values[i]) {
        _controllers[i].text = widget.values[i];
      }
    }
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

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < 6; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: SizedBox(
              height: 54,
              child: TextField(
                controller: _controllers[i],
                focusNode: _nodes[i],
                autofocus: i == 0,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(1),
                ],
                style: ClubType.inter(21, height: 1),
                cursorColor: ClubColors.brand,
                decoration: InputDecoration(
                  counterText: '',
                  contentPadding: EdgeInsets.zero,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: ClubColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: ClubColors.brand,
                      width: 1.5,
                    ),
                  ),
                ),
                onChanged: (value) {
                  widget.onChanged(i, value);
                  if (value.isNotEmpty && i < 5) _nodes[i + 1].requestFocus();
                  if (value.isEmpty && i > 0) _nodes[i - 1].requestFocus();
                },
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class ChoiceChipButton extends StatelessWidget {
  const ChoiceChipButton(
    this.label, {
    super.key,
    this.selected = false,
    this.onPressed,
    this.compact = false,
  });

  final String label;
  final bool selected;
  final VoidCallback? onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? ClubColors.soft : ClubColors.field,
      shape: StadiumBorder(
        side: BorderSide(
          color: selected ? const Color(0x8C994EA8) : ClubColors.border,
        ),
      ),
      child: InkWell(
        onTap: onPressed,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 11 : 14,
            vertical: compact ? 7 : 9,
          ),
          child: Text(
            label,
            style: ClubType.inter(
              compact ? 12 : 13,
              height: 1.2,
              color: selected ? ClubColors.plum : ClubColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}

class ChipWrap extends StatelessWidget {
  const ChipWrap({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Wrap(spacing: 8, runSpacing: 8, children: children);
  }
}

class VerifiedLabel extends StatelessWidget {
  const VerifiedLabel({super.key, this.onDark = false});

  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final color = onDark
        ? Colors.white.withValues(alpha: 0.88)
        : ClubColors.muted;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(
            color: ClubColors.brand,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text('Verified', style: ClubType.inter(13, color: color, height: 1.2)),
      ],
    );
  }
}

class PlaceLine extends StatelessWidget {
  const PlaceLine(
    this.location, {
    super.key,
    this.onDark = false,
    this.size = 13,
  });

  final String location;
  final bool onDark;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = onDark
        ? Colors.white.withValues(alpha: 0.88)
        : ClubColors.muted;
    final style = ClubType.inter(size, color: color, height: 1.2);
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      runSpacing: 4,
      children: [
        Text(location, style: style),
        Text('·', style: style),
        VerifiedLabel(onDark: onDark),
      ],
    );
  }
}

class Note extends StatelessWidget {
  const Note(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: ClubType.inter(12, color: ClubColors.muted, height: 1.55),
    );
  }
}

class OnboardingFrame extends StatelessWidget {
  const OnboardingFrame({
    super.key,
    required this.title,
    required this.children,
    this.supporting,
    this.onBack,
    this.progress,
    this.footer,
    this.headerAction,
  });

  final String title;
  final String? supporting;
  final VoidCallback? onBack;
  final int? progress;
  final Widget? footer;
  final Widget? headerAction;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 32,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (progress != null) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: (progress! * 0.125).clamp(0.08, 1),
                            minHeight: 2,
                            backgroundColor: ClubColors.track,
                            color: ClubColors.brand,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (onBack != null)
                        IconButton(
                          onPressed: onBack,
                          tooltip: 'Back',
                          icon: const ClubIcon('back'),
                          style: IconButton.styleFrom(
                            backgroundColor: ClubColors.paper,
                            fixedSize: const Size(44, 44),
                            padding: EdgeInsets.zero,
                          ),
                        )
                      else
                        const SizedBox(height: 44),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(title, style: ClubType.lora(32)),
                                if (supporting != null) ...[
                                  const SizedBox(height: 10),
                                  Text(
                                    supporting!,
                                    style: ClubType.inter(
                                      15,
                                      color: ClubColors.muted,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          ?headerAction,
                        ],
                      ),
                      const SizedBox(height: 32),
                      ...children,
                      const SizedBox(height: 24),
                      ?footer,
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class CenteredScreen extends StatelessWidget {
  const CenteredScreen({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 40, 28, 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: children,
          ),
        ),
      ),
    );
  }
}

class SuccessMark extends StatelessWidget {
  const SuccessMark({super.key, this.quiet = false});

  final bool quiet;

  @override
  Widget build(BuildContext context) {
    final size = quiet ? 54.0 : 62.0;
    return Container(
      width: size,
      height: size,
      margin: EdgeInsets.only(bottom: quiet ? 28 : 28),
      decoration: BoxDecoration(
        color: ClubColors.soft,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0x66994EA8)),
      ),
      child: Center(
        child: ClubIcon(
          'check',
          size: quiet ? 28 : 30,
          color: ClubColors.brand,
        ),
      ),
    );
  }
}

class BottomNav extends StatelessWidget {
  const BottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    final model = MockScope.watch(context);
    const items = [
      (AppTab.club, 'Club', 'club'),
      (AppTab.likes, 'Likes', 'heart'),
      (AppTab.mates, 'Mates', 'mates'),
      (AppTab.profile, 'Profile', 'profile'),
    ];
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0xF7FFFEFD),
        border: Border(top: BorderSide(color: ClubColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Row(
            children: [
              for (final item in items)
                Expanded(
                  child: InkWell(
                    onTap: () => MockScope.read(context).goTab(item.$1),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ClubIcon(
                          item.$3,
                          color: model.tab == item.$1
                              ? ClubColors.ink
                              : ClubColors.disabled,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.$2,
                          style: ClubType.inter(
                            10,
                            weight: FontWeight.w500,
                            height: 1.2,
                            color: model.tab == item.$1
                                ? ClubColors.ink
                                : ClubColors.disabled,
                          ),
                        ),
                      ],
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

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(bottom: false, child: child),
      bottomNavigationBar: const BottomNav(),
    );
  }
}

class PageHeading extends StatelessWidget {
  const PageHeading({super.key, required this.title, this.supporting});

  final String title;
  final String? supporting;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: ClubType.lora(30, height: 1.16)),
          if (supporting != null) ...[
            const SizedBox(height: 7),
            Text(
              supporting!,
              style: ClubType.inter(14, color: ClubColors.muted),
            ),
          ],
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.copy,
    this.action,
    this.onPressed,
  });

  final String title;
  final String copy;
  final String? action;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 80),
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: ClubType.lora(27, height: 1.2),
          ),
          const SizedBox(height: 10),
          Text(
            copy,
            textAlign: TextAlign.center,
            style: ClubType.inter(14, color: ClubColors.muted),
          ),
          if (action != null) ...[
            const SizedBox(height: 24),
            SecondaryButton(action!, onPressed: onPressed),
          ],
        ],
      ),
    );
  }
}

class SettingsRow extends StatelessWidget {
  const SettingsRow(
    this.label, {
    super.key,
    this.onPressed,
    this.detail,
    this.danger = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final String? detail;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? ClubColors.error : ClubColors.ink;
    return InkWell(
      onTap: onPressed,
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: ClubColors.border)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(label, style: ClubType.inter(14, color: color)),
            ),
            if (detail != null)
              Text(
                detail!,
                style: ClubType.inter(
                  14,
                  color: ClubColors.brand,
                  weight: FontWeight.w600,
                  height: 1.2,
                ),
              )
            else
              ClubIcon('chevron', size: 18, color: color),
          ],
        ),
      ),
    );
  }
}

class ProfilePhoto extends StatelessWidget {
  const ProfilePhoto(
    this.asset, {
    super.key,
    this.width,
    this.height,
    this.radius = 0,
    this.alignment = const Alignment(0, -0.5),
  });

  final String asset;
  final double? width;
  final double? height;
  final double radius;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.asset(
        asset,
        width: width,
        height: height,
        fit: BoxFit.cover,
        alignment: alignment,
      ),
    );
  }
}

class ActionBar extends StatelessWidget {
  const ActionBar({
    super.key,
    required this.onPass,
    required this.onInvite,
    this.inviteLabel = 'Invite',
    this.pinned = true,
  });

  final VoidCallback onPass;
  final VoidCallback onInvite;
  final String inviteLabel;
  final bool pinned;

  @override
  Widget build(BuildContext context) {
    final bar = Padding(
      padding: EdgeInsets.fromLTRB(20, pinned ? 10 : 4, 20, pinned ? 10 : 10),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: _Decision(
              label: 'Pass',
              icon: 'close',
              filled: false,
              onPressed: onPass,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 3,
            child: _Decision(
              label: inviteLabel,
              icon: 'check',
              filled: true,
              onPressed: onInvite,
            ),
          ),
        ],
      ),
    );
    if (!pinned) return bar;
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0xFAFFFEFD),
        border: Border(top: BorderSide(color: ClubColors.border)),
      ),
      child: SafeArea(top: false, child: bar),
    );
  }
}

class _Decision extends StatelessWidget {
  const _Decision({
    required this.label,
    required this.icon,
    required this.filled,
    required this.onPressed,
  });

  final String label;
  final String icon;
  final bool filled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final color = filled ? ClubColors.paper : ClubColors.ink;
    return Material(
      color: filled ? ClubColors.ink : ClubColors.field,
      shape: StadiumBorder(
        side: BorderSide(color: filled ? ClubColors.ink : ClubColors.border),
      ),
      child: InkWell(
        onTap: onPressed,
        customBorder: const StadiumBorder(),
        child: SizedBox(
          height: 50,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClubIcon(icon, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: ClubType.inter(
                  16,
                  weight: FontWeight.w600,
                  height: 1,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PhotoGrid extends StatefulWidget {
  const PhotoGrid({super.key});

  @override
  State<PhotoGrid> createState() => _PhotoGridState();
}

class _PhotoGridState extends State<PhotoGrid> {
  int _count = 2;
  static const _photos = [ownPhoto, 'assets/photos/meera.jpg', nightPhoto];

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 0.78,
      children: [
        for (var i = 0; i < 6; i++)
          if (i < _count)
            Stack(
              fit: StackFit.expand,
              children: [
                ProfilePhoto(_photos[i % 3], radius: 12),
                if (i == 0)
                  Positioned(
                    left: 6,
                    bottom: 6,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: ClubColors.ink,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        child: Text(
                          'PRIMARY',
                          style: ClubType.inter(
                            9,
                            color: Colors.white,
                            weight: FontWeight.w600,
                            height: 1,
                            letterSpacing: 0.7,
                          ),
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  top: 5,
                  right: 5,
                  child: Material(
                    color: Colors.white,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () =>
                          setState(() => _count = (_count - 1).clamp(1, 6)),
                      child: const SizedBox(
                        width: 26,
                        height: 26,
                        child: Center(child: ClubIcon('close', size: 16)),
                      ),
                    ),
                  ),
                ),
              ],
            )
          else
            Material(
              color: ClubColors.field,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0x731A1A1A)),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => setState(() => _count = (_count + 1).clamp(1, 6)),
                child: const Center(child: ClubIcon('plus')),
              ),
            ),
      ],
    );
  }
}
