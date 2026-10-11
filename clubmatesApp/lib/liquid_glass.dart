import 'dart:ui';

import 'package:flutter/material.dart';

import 'theme.dart';

/// Floating control material, following Apple's Liquid Glass guidance:
/// bars and controls sit above content, content itself stays solid,
/// and related actions share one surface while the primary action is tinted.
enum GlassRole { regular, clear }

abstract final class ClubChrome {
  static const navHeight = 66.0;

  /// Space between a bottom control and the physical screen edge.
  /// Keeps the home indicator visible underneath floating bars and buttons.
  static double barGap(BuildContext context) {
    final safe = MediaQuery.paddingOf(context).bottom;
    return safe > 0 ? safe + 10 : 16;
  }

  static double clearance(BuildContext context) {
    return barGap(context) + navHeight + 18;
  }

  static bool reduceTransparency(BuildContext context) {
    return View.of(
      context,
    ).platformDispatcher.accessibilityFeatures.highContrast;
  }
}

class LiquidGlass extends StatelessWidget {
  const LiquidGlass({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(28)),
    this.role = GlassRole.regular,
    this.padding,
    this.onPressed,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final GlassRole role;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final reduce = ClubChrome.reduceTransparency(context);
    final clear = role == GlassRole.clear && !reduce;
    Widget body = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: reduce
              ? const [ClubColors.paper, ClubColors.paper]
              : clear
              ? [Colors.white.withValues(alpha: 0.30), const Color(0x99141016)]
              : [Colors.white.withValues(alpha: 0.78), const Color(0xC7F7F4F1)],
        ),
      ),
      child: Padding(padding: padding ?? EdgeInsets.zero, child: child),
    );
    if (onPressed != null) {
      body = Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onPressed,
          borderRadius: borderRadius,
          child: body,
        ),
      );
    }
    body = ClipRRect(
      borderRadius: borderRadius,
      child: reduce
          ? body
          : BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: clear ? 16 : 24,
                sigmaY: clear ? 16 : 24,
              ),
              child: body,
            ),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: reduce
            ? null
            : const [
                BoxShadow(
                  color: Color(0x241A1A1A),
                  blurRadius: 28,
                  offset: Offset(0, 12),
                ),
              ],
      ),
      child: Stack(
        children: [
          body,
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: borderRadius,
                  border: Border.all(
                    color: reduce
                        ? ClubColors.border
                        : Colors.white.withValues(alpha: clear ? 0.5 : 0.82),
                    width: 0.7,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

BoxDecoration glassPaint({bool selected = false, double radius = 26}) {
  return BoxDecoration(
    borderRadius: BorderRadius.circular(radius),
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: selected
          ? const [Color(0xFFF6E9F8), Color(0xFFEAD4F0)]
          : const [Color(0xF7FFFFFF), Color(0xE6F3F0EE)],
    ),
    border: Border.all(
      color: selected ? const Color(0x80994EA8) : const Color(0x241A1A1A),
    ),
    boxShadow: const [
      BoxShadow(color: Color(0x121A1A1A), blurRadius: 14, offset: Offset(0, 5)),
    ],
  );
}

BoxDecoration tintedPaint({required bool enabled, double radius = 26}) {
  return BoxDecoration(
    borderRadius: BorderRadius.circular(radius),
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: enabled
          ? const [Color(0xFF3A3A3A), ClubColors.ink]
          : const [ClubColors.disabledFill, ClubColors.disabledFill],
    ),
    border: Border.all(
      color: enabled ? const Color(0x40FFFFFF) : ClubColors.disabledLine,
    ),
    boxShadow: enabled
        ? const [
            BoxShadow(
              color: Color(0x2E1A1A1A),
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ]
        : null,
  );
}
