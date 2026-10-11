import 'dart:io';

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'club_icon.dart';
import 'liquid_glass.dart';
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
    const radius = BorderRadius.all(Radius.circular(28));
    return DecoratedBox(
      decoration: BoxDecoration(
        color: enabled ? ClubColors.ink : ClubColors.disabledFill,
        borderRadius: radius,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onPressed,
          borderRadius: radius,
          child: SizedBox(
            height: 50,
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
    const radius = BorderRadius.all(Radius.circular(28));
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ClubColors.field,
        borderRadius: radius,
        border: Border.all(
          color: onPressed == null ? ClubColors.disabledLine : ClubColors.ink,
        ),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onPressed,
          borderRadius: radius,
          child: SizedBox(
            height: 50,
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
    this.focusNode,
    this.onChanged,
    this.onTap,
    this.keyboardType,
    this.inputFormatters,
    this.maxLines = 1,
    this.error,
    this.textAlign = TextAlign.start,
    this.autofocus = false,
  });

  final String? label;
  final String hint;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;
  final String? error;
  final TextAlign textAlign;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final invalid = error != null && error!.isNotEmpty;
    final radius = BorderRadius.circular(14);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label!, style: ClubType.inter(14, weight: FontWeight.w600)),
          const SizedBox(height: 8),
        ],
        TextField(
          controller: controller,
          focusNode: focusNode,
          autofocus: autofocus,
          onChanged: onChanged,
          onTap: onTap,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          maxLines: maxLines,
          textAlign: textAlign,
          style: ClubType.inter(17, height: 1.3),
          cursorColor: ClubColors.ink,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: ClubType.inter(
              17,
              color: ClubColors.disabled,
              height: 1.3,
            ),
            filled: true,
            fillColor: ClubColors.field,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: maxLines > 1 ? 14 : 16,
            ),
            constraints: maxLines == 1
                ? const BoxConstraints(minHeight: 56)
                : const BoxConstraints(minHeight: 96),
            enabledBorder: OutlineInputBorder(
              borderRadius: radius,
              borderSide: BorderSide(
                color: invalid ? ClubColors.error : ClubColors.border,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: radius,
              borderSide: BorderSide(
                color: invalid ? ClubColors.error : ClubColors.ink,
                width: 1.5,
              ),
            ),
          ),
        ),
        if (invalid) ...[
          const SizedBox(height: 6),
          Text(error!, style: ClubType.inter(13, color: ClubColors.error)),
        ],
      ],
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
      height: 56,
      decoration: BoxDecoration(
        color: ClubColors.field,
        borderRadius: BorderRadius.circular(14),
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
  static const _marker = '\u200b';

  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _nodes;
  late final List<String> _digits;
  var _editing = false;

  @override
  void initState() {
    super.initState();
    _digits = [...widget.values];
    _controllers = List.generate(
      6,
      (index) => TextEditingController(text: _shown(_digits[index])),
    );
    _nodes = List.generate(6, (_) => FocusNode());
  }

  @override
  void didUpdateWidget(OtpInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    for (var i = 0; i < 6; i++) {
      if (_digits[i] == widget.values[i]) continue;
      _digits[i] = widget.values[i];
      _show(i, widget.values[i]);
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

  String _shown(String digit) => digit.isEmpty ? _marker : digit;

  void _show(int index, String digit) {
    final text = _shown(digit);
    final controller = _controllers[index];
    if (controller.text == text) return;
    _editing = true;
    controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    _editing = false;
  }

  void _onChanged(int index, String raw) {
    if (_editing) return;
    final digits = raw.replaceAll(_marker, '').replaceAll(RegExp(r'\D'), '');
    final hadDigit = _digits[index].isNotEmpty;
    if (digits.isEmpty) {
      _digits[index] = '';
      widget.onChanged(index, '');
      _show(index, '');
      if (hadDigit) {
        if (index > 0) _nodes[index - 1].requestFocus();
        return;
      }
      if (index == 0) return;
      _digits[index - 1] = '';
      widget.onChanged(index - 1, '');
      _show(index - 1, '');
      _nodes[index - 1].requestFocus();
      return;
    }
    if (digits.length > 1) {
      for (
        var offset = 0;
        offset < digits.length && index + offset < 6;
        offset++
      ) {
        final digit = digits[offset];
        _digits[index + offset] = digit;
        widget.onChanged(index + offset, digit);
        _show(index + offset, digit);
      }
      final next = index + digits.length;
      _nodes[next >= 6 ? 5 : next].requestFocus();
      return;
    }
    _digits[index] = digits;
    widget.onChanged(index, digits);
    _show(index, digits);
    if (index < 5) _nodes[index + 1].requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < 6; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: DecoratedBox(
              decoration: glassPaint(radius: 16),
              child: TextField(
                controller: _controllers[i],
                focusNode: _nodes[i],
                autofocus: i == 0,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                style: ClubType.inter(21, height: 1),
                cursorColor: ClubColors.brand,
                decoration: InputDecoration(
                  counterText: '',
                  contentPadding: EdgeInsets.zero,
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Colors.transparent),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: ClubColors.brand,
                      width: 1.5,
                    ),
                  ),
                ),
                onChanged: (value) => _onChanged(i, value),
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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: selected ? ClubColors.ink : ClubColors.field,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: selected ? ClubColors.ink : ClubColors.border,
        ),
      ),
      child: Material(
        type: MaterialType.transparency,
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
                color: selected ? ClubColors.paper : ClubColors.ink,
              ),
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
    this.verified = true,
  });

  final String location;
  final bool onDark;
  final double size;
  final bool verified;

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
        if (verified) ...[
          Text('·', style: style),
          VerifiedLabel(onDark: onDark),
        ],
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
    this.error,
  });

  final String title;
  final String? supporting;
  final VoidCallback? onBack;
  final int? progress;
  final Widget? footer;
  final Widget? headerAction;
  final String? error;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final footerSpace = footer == null ? 20.0 : safeBottom + 108;
    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Stack(
          children: [
            SafeArea(
              bottom: false,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(20, 12, 20, footerSpace),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 12 - footerSpace,
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
                            GlassIconButton(onPressed: onBack!)
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
                                    Text(
                                      title,
                                      style: ClubType.lora(34, height: 1.12),
                                    ),
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
                          if (error != null && error!.isNotEmpty) ...[
                            Text(
                              error!,
                              style: ClubType.inter(
                                13,
                                color: ClubColors.error,
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          ...children,
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            if (footer != null)
              Positioned(
                left: 20,
                right: 20,
                bottom: ClubChrome.barGap(context),
                child: footer!,
              ),
          ],
        ),
      ),
    );
  }
}

class GlassIconButton extends StatelessWidget {
  const GlassIconButton({
    super.key,
    required this.onPressed,
    this.icon = 'back',
    this.clear = false,
    this.tooltip = 'Back',
    this.size = 44,
  });

  final VoidCallback onPressed;
  final String icon;
  final bool clear;
  final String tooltip;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: clear ? const Color(0xCC1A1A1A) : ClubColors.field,
        shape: CircleBorder(
          side: BorderSide(
            color: clear ? Colors.transparent : ClubColors.border,
          ),
        ),
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: size,
            height: size,
            child: Center(
              child: ClubIcon(
                icon,
                size: size < 40 ? 16 : 22,
                color: clear ? Colors.white : ClubColors.ink,
              ),
            ),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: LiquidGlass(
        borderRadius: BorderRadius.circular(size / 2),
        child: SizedBox(
          width: size,
          height: size,
          child: Center(
            child: ClubIcon(
              'check',
              size: quiet ? 28 : 30,
              color: ClubColors.brand,
            ),
          ),
        ),
      ),
    );
  }
}

class BottomNav extends StatefulWidget {
  const BottomNav({super.key});

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav>
    with SingleTickerProviderStateMixin {
  static const _tabs = [
    (AppTab.club, 'Club', 'club'),
    (AppTab.likes, 'Likes', 'heart'),
    (AppTab.mates, 'Mates', 'mates'),
    (AppTab.profile, 'Profile', 'profile'),
  ];

  late final AnimationController _slide;
  int _current = 0;
  int _previous = 0;

  @override
  void initState() {
    super.initState();
    final model = MockScope.read(context);
    _current = _indexOf(model.tab);
    _previous = model.lensFrom;
    _slide = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
      value: 1,
    );
    if (_previous != _current && !MediaQuery.disableAnimationsOf(context)) {
      _slide.value = 0;
      _slide.forward();
    }
  }

  int _indexOf(AppTab tab) {
    final index = _tabs.indexWhere((item) => item.$1 == tab);
    return index < 0 ? 0 : index;
  }

  @override
  void dispose() {
    _slide.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LiquidGlass(
      borderRadius: BorderRadius.circular(34),
      child: SizedBox(
        height: ClubChrome.navHeight,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return AnimatedBuilder(
              animation: _slide,
              builder: (context, _) {
                final width = constraints.maxWidth;
                final slot = width / _tabs.length;
                final t = Curves.easeInOutCubic.transform(_slide.value);
                final from = (_previous + 0.5) * slot;
                final to = (_current + 0.5) * slot;
                final center = from + (to - from) * t;
                final stretch = math.sin(t * math.pi);
                final lens = (slot * (0.74 + stretch * 0.7)).clamp(
                  52.0,
                  width - 8,
                );
                final left = (center - lens / 2).clamp(4.0, width - lens - 4);
                return Stack(
                  children: [
                    Positioned(
                      left: left,
                      top: 5,
                      width: lens,
                      height: ClubChrome.navHeight - 10,
                      child: const DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(28)),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xC7FFFFFF), Color(0x66F4E9F8)],
                          ),
                          border: Border.fromBorderSide(
                            BorderSide(color: Color(0xE6FFFFFF)),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x33994EA8),
                              blurRadius: 18,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        for (var i = 0; i < _tabs.length; i++)
                          Expanded(
                            child: _NavItem(
                              label: _tabs[i].$2,
                              icon: _tabs[i].$3,
                              selected: i == _current,
                              onTap: () =>
                                  MockScope.read(context).goTab(_tabs[i].$1),
                            ),
                          ),
                      ],
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? ClubColors.brand : ClubColors.disabled;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClubIcon(icon, color: color),
            const SizedBox(height: 3),
            Text(
              label,
              style: ClubType.inter(
                10,
                weight: FontWeight.w600,
                height: 1.2,
                color: color,
              ),
            ),
          ],
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
      body: Stack(
        children: [
          SafeArea(bottom: false, child: child),
          Positioned(
            left: 16,
            right: 16,
            bottom: ClubChrome.barGap(context),
            child: const BottomNav(),
          ),
        ],
      ),
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
    final remote = asset.startsWith('http');
    final localFile = asset.startsWith('/') || asset.startsWith('file://');
    final filePath = asset.startsWith('file://') ? asset.substring(7) : asset;
    final child = asset.isEmpty
        ? ColoredBox(
            color: ClubColors.track,
            child: SizedBox(width: width, height: height),
          )
        : remote
        ? Image.network(
            asset,
            width: width,
            height: height,
            fit: BoxFit.cover,
            alignment: alignment,
            errorBuilder: (context, error, stackTrace) => ColoredBox(
              color: ClubColors.track,
              child: SizedBox(width: width, height: height),
            ),
          )
        : localFile
        ? Image.file(
            File(filePath),
            width: width,
            height: height,
            fit: BoxFit.cover,
            alignment: alignment,
            errorBuilder: (context, error, stackTrace) => ColoredBox(
              color: ClubColors.track,
              child: SizedBox(width: width, height: height),
            ),
          )
        : Image.asset(
            asset,
            width: width,
            height: height,
            fit: BoxFit.cover,
            alignment: alignment,
          );
    return ClipRRect(borderRadius: BorderRadius.circular(radius), child: child);
  }
}

class ActionBar extends StatelessWidget {
  const ActionBar({
    super.key,
    required this.onPass,
    required this.onInvite,
    this.inviteLabel = 'Invite',
  });

  final VoidCallback onPass;
  final VoidCallback onInvite;
  final String inviteLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
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
        const SizedBox(width: 8),
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
    const radius = BorderRadius.all(Radius.circular(24));
    return DecoratedBox(
      decoration: filled
          ? const BoxDecoration(color: ClubColors.ink, borderRadius: radius)
          : const BoxDecoration(
              color: ClubColors.field,
              borderRadius: radius,
              border: Border.fromBorderSide(BorderSide(color: ClubColors.ink)),
            ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onPressed,
          borderRadius: radius,
          customBorder: const StadiumBorder(),
          child: SizedBox(
            height: 48,
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
      ),
    );
  }
}

class PhotoGrid extends StatelessWidget {
  const PhotoGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final model = MockScope.watch(context);
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 0.78,
      children: [
        for (final photo in model.ownPhotos) _FilledPhoto(photo: photo),
        for (var i = model.ownPhotos.length; i < maxProfilePhotos; i++)
          const _EmptyPhotoSlot(),
      ],
    );
  }
}

class _FilledPhoto extends StatelessWidget {
  const _FilledPhoto({required this.photo});

  final OwnPhoto photo;

  @override
  Widget build(BuildContext context) {
    final model = MockScope.read(context);
    return GestureDetector(
      onTap: () => model.makePrimary(photo),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ProfilePhoto(photo.url, radius: 12),
          if (photo.primary)
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
            child: GlassIconButton(
              icon: 'close',
              tooltip: 'Remove photo',
              size: 28,
              clear: true,
              onPressed: () => model.removePhoto(photo),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPhotoSlot extends StatelessWidget {
  const _EmptyPhotoSlot();

  @override
  Widget build(BuildContext context) {
    final model = MockScope.watch(context);
    return Material(
      color: ClubColors.field,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: ClubColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: model.busy ? null : () => model.pickPhoto(camera: false),
        child: const Center(child: ClubIcon('plus', size: 28)),
      ),
    );
  }
}
