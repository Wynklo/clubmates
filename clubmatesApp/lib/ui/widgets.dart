import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart'
    show
        AnimatedGlassIndicator,
        GlassQuality,
        GlassTab,
        GlassTabBar,
        LiquidGlassSettings;

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
    this.textCapitalization = TextCapitalization.sentences,
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
  final TextCapitalization textCapitalization;

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
          textCapitalization: textCapitalization,
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

/// Keeps the back button at the top of the screen while [child] scrolls
/// under it. A soft fade appears behind the button once the page scrolls.
/// [child] should leave [GlassIconButton]-sized room at the top.
class PinnedBackPage extends StatefulWidget {
  const PinnedBackPage({
    super.key,
    required this.onBack,
    required this.child,
    this.left = 16,
    this.top = 0,
    this.fadeAfter = 4,
    this.clearUntilFade = false,
  });

  final VoidCallback onBack;
  final Widget child;
  final double left;
  final double top;

  /// Scroll offset after which the fade shows.
  final double fadeAfter;

  /// Use the dark button (for photos) until the fade shows.
  final bool clearUntilFade;

  @override
  State<PinnedBackPage> createState() => _PinnedBackPageState();
}

class _PinnedBackPageState extends State<PinnedBackPage> {
  var _scrolled = false;

  bool _onScroll(ScrollNotification note) {
    if (note.depth != 0 || note.metrics.axis != Axis.vertical) return false;
    final scrolled = note.metrics.pixels > widget.fadeAfter;
    if (scrolled != _scrolled) setState(() => _scrolled = scrolled);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final safeTop = MediaQuery.paddingOf(context).top;
    final motionOff = MediaQuery.disableAnimationsOf(context);
    final duration = Duration(milliseconds: motionOff ? 0 : 200);
    final buttonTop = safeTop + widget.top;
    return Stack(
      fit: StackFit.expand,
      children: [
        NotificationListener<ScrollNotification>(
          onNotification: _onScroll,
          child: widget.child,
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: buttonTop + 44 + 18,
          child: IgnorePointer(
            child: AnimatedOpacity(
              opacity: _scrolled ? 1 : 0,
              duration: duration,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      ClubColors.paper,
                      ClubColors.paper.withValues(alpha: 0.88),
                      ClubColors.paper.withValues(alpha: 0),
                    ],
                    stops: const [0, 0.62, 1],
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: buttonTop,
          left: widget.left,
          child: AnimatedSwitcher(
            duration: duration,
            child: GlassIconButton(
              key: ValueKey(widget.clearUntilFade && !_scrolled),
              onPressed: widget.onBack,
              clear: widget.clearUntilFade && !_scrolled,
            ),
          ),
        ),
      ],
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

class BottomNav extends StatelessWidget {
  const BottomNav({super.key});

  static const _tabs = [
    (AppTab.club, 'Club', 'club'),
    (AppTab.invites, 'Invites', 'heart'),
    (AppTab.mates, 'Mates', 'mates'),
    (AppTab.profile, 'Profile', 'profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final model = AppScope.watch(context);
    final selected = _tabs.indexWhere((item) => item.$1 == model.tab);
    int badgeFor(AppTab tab) => switch (tab) {
      AppTab.invites => model.incoming.length,
      AppTab.mates => model.unreadMessages,
      _ => 0,
    };
    return SizedBox(
      height: ClubChrome.barFrameHeight,
      child: Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 19),
        child: GlassTabBar.bottom(
          selectedIndex: selected < 0 ? 0 : selected,
          onTabSelected: (index) {
            if (index == selected) return;
            HapticFeedback.selectionClick();
            model.goTab(_tabs[index].$1);
          },
          horizontalPadding: 25,
          verticalPadding: 0,
          barHeight: 62,
          quality: GlassQuality.premium,
          settings: LiquidGlassSettings.ios27Light,
          indicatorColor: const Color(0x14994EA8),
          indicatorSettings: AnimatedGlassIndicator.baseIndicatorSettings
              .copyWith(
                thickness: 30,
                refractiveIndex: 1.3,
                chromaticAberration: 0.45,
                lightIntensity: 0.9,
              ),
          indicatorExpansion: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          magnification: 1.3,
          pressScale: 1.06,
          iconSize: 22,
          labelFontSize: 10,
          selectedLabelColor: ClubColors.brand,
          unselectedLabelColor: ClubColors.ink,
          selectedLabelStyle: ClubType.inter(
            10,
            weight: FontWeight.w600,
            letterSpacing: -0.1,
            color: ClubColors.brand,
          ),
          unselectedLabelStyle: ClubType.inter(
            10,
            weight: FontWeight.w600,
            color: ClubColors.ink,
          ),
          tabs: [
            for (final tab in _tabs)
              GlassTab(
                label: tab.$2,
                semanticLabel: badgeFor(tab.$1) > 0
                    ? '${tab.$2}, ${badgeFor(tab.$1)} new'
                    : null,
                icon: _TabBadge(
                  count: badgeFor(tab.$1),
                  child: ClubIcon(tab.$3, size: 22, color: ClubColors.ink),
                ),
                activeIcon: _TabBadge(
                  count: badgeFor(tab.$1),
                  child: ClubIcon(
                    tab.$3,
                    size: 22,
                    color: ClubColors.brand,
                    filled: true,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// iOS-style red count bubble on the top-right of a tab icon.
class _TabBadge extends StatelessWidget {
  const _TabBadge({required this.count, required this.child});

  final int count;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final motionOff = MediaQuery.disableAnimationsOf(context);
    final text = count > 99 ? '99+' : '$count';
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          top: -7,
          left: 13,
          child: AnimatedScale(
            scale: count > 0 ? 1 : 0,
            duration: Duration(milliseconds: motionOff ? 0 : 320),
            curve: count > 0 ? Curves.elasticOut : Curves.easeIn,
            child: AnimatedSwitcher(
              duration: Duration(milliseconds: motionOff ? 0 : 200),
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: Container(
                key: ValueKey(text),
                constraints: const BoxConstraints(minWidth: 18),
                height: 18,
                padding: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF3B30),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: Colors.white, width: 1.5),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33FF3B30),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  text,
                  style: ClubType.inter(
                    10.5,
                    weight: FontWeight.w700,
                    height: 1,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Holds the tab bar for Club, Invites, Mates and Profile. It stays mounted
/// while the tab changes, so the glass indicator glides between tabs and
/// the screens cross-fade underneath it.
class TabChrome extends StatefulWidget {
  const TabChrome({super.key, required this.tab, required this.child});

  final AppTab tab;
  final Widget child;

  @override
  State<TabChrome> createState() => _TabChromeState();
}

class _TabChromeState extends State<TabChrome> {
  var _shown = true;

  @override
  void didUpdateWidget(TabChrome old) {
    super.didUpdateWidget(old);
    if (old.tab != widget.tab) _shown = true;
  }

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
    return Material(
      color: ClubColors.paper,
      child: Stack(
        fit: StackFit.expand,
        children: [
          NotificationListener<ScrollNotification>(
            onNotification: _onScroll,
            child: AnimatedSwitcher(
              duration: Duration(milliseconds: motionOff ? 0 : 260),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: Tween(begin: 0.985, end: 1.0).animate(animation),
                  child: child,
                ),
              ),
              child: KeyedSubtree(
                key: ValueKey(widget.tab),
                child: widget.child,
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedSlide(
              offset: _shown ? Offset.zero : const Offset(0, 1.6),
              duration: Duration(milliseconds: motionOff ? 0 : 380),
              curve: _shown ? Curves.easeOutBack : Curves.easeInCubic,
              child: AnimatedOpacity(
                opacity: _shown ? 1 : 0,
                duration: Duration(milliseconds: motionOff ? 0 : 220),
                child: const BottomNav(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: SafeArea(bottom: false, child: child));
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
