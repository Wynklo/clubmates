import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../state/app_model.dart';
import '../theme/theme.dart';
import 'club_icon.dart';
import 'liquid_glass.dart';

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
  const PrimaryButton(
    this.label, {
    super.key,
    this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null || loading;
    const radius = BorderRadius.all(Radius.circular(17));
    return DecoratedBox(
      decoration: BoxDecoration(
        color: enabled ? const Color(0xF51A1A1A) : ClubColors.disabledFill,
        borderRadius: radius,
        border: Border.all(
          color: enabled ? const Color(0xD1000000) : ClubColors.disabledLine,
        ),
        boxShadow: enabled
            ? const [
                BoxShadow(
                  color: Color(0x2E1A1A1A),
                  blurRadius: 22,
                  offset: Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: loading ? null : onPressed,
          borderRadius: radius,
          child: SizedBox(
            height: 52,
            width: double.infinity,
            child: Center(
              child: loading
                  ? const ClubPulse()
                  : Text(
                      label,
                      style: ClubType.inter(
                        16,
                        weight: FontWeight.w600,
                        height: 1,
                        letterSpacing: -0.16,
                        color: enabled
                            ? ClubColors.paper
                            : ClubColors.disabledText,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class ClubPulse extends StatefulWidget {
  const ClubPulse({super.key, this.color = ClubColors.paper, this.size = 7});

  final Color color;
  final double size;

  @override
  State<ClubPulse> createState() => _ClubPulseState();
}

class _ClubPulseState extends State<ClubPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  var _motionReady = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.disableAnimationsOf(context);
    if (reduce) {
      _controller.value = 1;
      _controller.stop();
      _motionReady = true;
      return;
    }
    if (_motionReady) return;
    _motionReady = true;
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _opacity(int index) {
    final phase = (_controller.value + index * 0.18) % 1;
    return 0.25 + 0.75 * math.sin(phase * math.pi);
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 3; i++) ...[
              if (i > 0) SizedBox(width: size * 0.75),
              Opacity(
                opacity: _opacity(i),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: widget.color,
                    shape: BoxShape.circle,
                  ),
                  child: SizedBox(width: size, height: size),
                ),
              ),
            ],
          ],
        );
      },
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
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final String? icon;
  final Color? foreground;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final color = foreground ?? ClubColors.ink;
    final enabled = onPressed != null || loading;
    const radius = BorderRadius.all(Radius.circular(17));
    return DecoratedBox(
      decoration: BoxDecoration(
        color: enabled ? const Color(0xC7FFFFFF) : ClubColors.disabledFill,
        borderRadius: radius,
        border: Border.all(
          color: enabled ? const Color(0xB8FFFFFF) : ClubColors.disabledLine,
        ),
        boxShadow: enabled
            ? const [
                BoxShadow(
                  color: Color(0x1F24171F),
                  blurRadius: 32,
                  offset: Offset(0, 10),
                ),
              ]
            : null,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: loading ? null : onPressed,
          borderRadius: radius,
          child: SizedBox(
            height: 52,
            width: double.infinity,
            child: loading
                ? Center(child: ClubPulse(color: color, size: 6))
                : Row(
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
    final radius = BorderRadius.circular(15);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label!.toUpperCase(), style: ClubType.eyebrow),
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
            fillColor: const Color(0xD6FFFFFF),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 14,
              vertical: maxLines > 1 ? 14 : 0,
            ),
            constraints: maxLines == 1
                ? const BoxConstraints(minHeight: 52)
                : const BoxConstraints(minHeight: 96),
            enabledBorder: OutlineInputBorder(
              borderRadius: radius,
              borderSide: BorderSide(
                color: invalid ? ClubColors.error : const Color(0x171A1A1A),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: radius,
              borderSide: BorderSide(
                color: invalid ? ClubColors.error : ClubColors.brand,
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
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xD6FFFFFF),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0x171A1A1A)),
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
          fit: StackFit.expand,
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
    final glyph = icon == 'back' ? 17.0 : (size <= 32 ? 14.0 : 20.0);
    final button = SizedBox(
      width: size,
      height: size,
      child: Center(
        child: ClubIcon(
          icon,
          size: glyph,
          color: clear ? Colors.white : ClubColors.ink,
        ),
      ),
    );
    if (clear) {
      return Tooltip(
        message: tooltip,
        child: Material(
          color: const Color(0xCC1A1A1A),
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            child: button,
          ),
        ),
      );
    }
    return Tooltip(
      message: tooltip,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFFF7F7F7),
          boxShadow: [
            BoxShadow(
              color: Color(0x1F000000),
              blurRadius: 40,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: const Color(0xA6FFFFFF),
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            child: button,
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
  var _motionReady = false;

  @override
  void initState() {
    super.initState();
    _slide = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      value: 1,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_motionReady) return;
    _motionReady = true;
    final model = AppScope.read(context);
    _current = _indexOf(model.tab);
    _previous = model.lensFrom;
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
    return SizedBox(
      height: ClubChrome.barFrameHeight,
      child: Padding(
        padding: ClubChrome.barFramePadding,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Positioned(
              left: -4,
              right: -4,
              top: -4,
              bottom: -4,
              child: _TabBarGlass(),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: SizedBox(
                height: ClubChrome.navHeight,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return AnimatedBuilder(
                      animation: _slide,
                      builder: (context, _) {
                        final width = constraints.maxWidth;
                        final slot = width / _tabs.length;
                        final t = Curves.easeOutCubic.transform(_slide.value);
                        final from = _previous * slot;
                        final to = _current * slot;
                        final left = (from + (to - from) * t - 2).clamp(
                          0.0,
                          (width - 4).clamp(0.0, width),
                        );
                        final pillWidth = (slot + 4).clamp(0.0, width - left);
                        return Stack(
                          children: [
                            Positioned(
                              left: left,
                              top: 0,
                              width: pillWidth,
                              bottom: 0,
                              child: const DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Color(0xFFEDEDED),
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(100),
                                  ),
                                ),
                              ),
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                for (var i = 0; i < _tabs.length; i++)
                                  Expanded(
                                    child: _NavItem(
                                      label: _tabs[i].$2,
                                      icon: _tabs[i].$3,
                                      selected: i == _current,
                                      onTap: () => AppScope.read(
                                        context,
                                      ).goTab(_tabs[i].$1),
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
            ),
          ],
        ),
      ),
    );
  }
}

class _TabBarGlass extends StatelessWidget {
  const _TabBarGlass();

  static const _radius = BorderRadius.all(Radius.circular(296));
  static const _shadow = [
    BoxShadow(color: Color(0x1F000000), blurRadius: 40, offset: Offset(0, 8)),
  ];

  @override
  Widget build(BuildContext context) {
    final reduce = ClubChrome.reduceTransparency(context);
    if (reduce) {
      return const DecoratedBox(
        decoration: BoxDecoration(
          color: Color(0xFFF7F7F7),
          borderRadius: _radius,
          boxShadow: _shadow,
        ),
      );
    }
    return DecoratedBox(
      decoration: const BoxDecoration(
        borderRadius: _radius,
        boxShadow: _shadow,
      ),
      child: ClipRRect(
        borderRadius: _radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: BackdropFilter(
            filter: ColorFilter.mode(Color(0xA6FFFFFF), BlendMode.srcOver),
            child: BackdropFilter(
              filter: ColorFilter.mode(Color(0xFFDDDDDD), BlendMode.colorBurn),
              child: BackdropFilter(
                filter: ColorFilter.mode(Color(0xFFF7F7F7), BlendMode.darken),
                child: SizedBox.expand(),
              ),
            ),
          ),
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
    final color = selected ? ClubColors.brand : ClubColors.ink;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 7),
          child: Column(
            children: [
              SizedBox(
                height: 28,
                child: Center(
                  child: ClubIcon(
                    icon,
                    size: 22,
                    color: color,
                    filled: selected,
                  ),
                ),
              ),
              SizedBox(height: selected ? 1 : 0.5),
              SizedBox(
                height: 12,
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: ClubType.inter(
                    10,
                    weight: FontWeight.w600,
                    height: 1.2,
                    letterSpacing: selected ? -0.1 : 0,
                    color: color,
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

class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.child});

  final Widget child;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  var _shown = true;

  bool _onScroll(ScrollNotification note) {
    if (note.metrics.axis != Axis.vertical) return false;
    if (note is! ScrollUpdateNotification) return false;
    if (note.metrics.pixels <= 0) {
      _setShown(true);
      return false;
    }
    final delta = note.scrollDelta ?? 0;
    if (delta > 10) _setShown(false);
    if (delta < -10) _setShown(true);
    return false;
  }

  void _setShown(bool value) {
    if (_shown == value) return;
    setState(() => _shown = value);
  }

  @override
  Widget build(BuildContext context) {
    final motionOff = MediaQuery.disableAnimationsOf(context);
    return Scaffold(
      body: NotificationListener<ScrollNotification>(
        onNotification: _onScroll,
        child: Stack(
          fit: StackFit.expand,
          children: [
            SafeArea(bottom: false, child: widget.child),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AnimatedSlide(
                offset: _shown ? Offset.zero : const Offset(0, 1.8),
                duration: Duration(milliseconds: motionOff ? 0 : 240),
                curve: Curves.easeOutCubic,
                child: const BottomNav(),
              ),
            ),
          ],
        ),
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
    this.loading = false,
  });

  final String title;
  final String copy;
  final String? action;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 80),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
            SecondaryButton(action!, onPressed: onPressed, loading: loading),
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
    this.divider = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final String? detail;
  final bool danger;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    final color = danger ? ClubColors.error : ClubColors.ink;
    return InkWell(
      onTap: onPressed,
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(
          border: divider
              ? const Border(bottom: BorderSide(color: ClubColors.border))
              : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(label, style: ClubType.inter(14, color: color)),
            ),
            if (detail != null) ...[
              const SizedBox(width: 12),
              Text(
                detail!,
                style: ClubType.inter(
                  14,
                  color: ClubColors.brand,
                  weight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
            ] else
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
    final busy = AppScope.watch(context).busy;
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: _Decision(
            label: 'Pass',
            icon: 'close',
            filled: false,
            loading: busy,
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
            loading: busy,
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
    required this.loading,
  });

  final String label;
  final String icon;
  final bool filled;
  final VoidCallback onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final color = filled ? ClubColors.paper : ClubColors.ink;
    const radius = BorderRadius.all(Radius.circular(17));
    return DecoratedBox(
      decoration: filled
          ? const BoxDecoration(
              color: Color(0xF21A1A1A),
              borderRadius: radius,
              border: Border.fromBorderSide(
                BorderSide(color: Color(0xD1000000)),
              ),
            )
          : const BoxDecoration(
              color: Color(0xC2FFFFFF),
              borderRadius: radius,
              border: Border.fromBorderSide(
                BorderSide(color: Color(0xB8FFFFFF)),
              ),
            ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: loading ? null : onPressed,
          borderRadius: radius,
          child: SizedBox(
            height: 52,
            child: loading
                ? Center(child: ClubPulse(color: color, size: 6))
                : Row(
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
    final model = AppScope.watch(context);
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
    final model = AppScope.read(context);
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
    final model = AppScope.watch(context);
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
