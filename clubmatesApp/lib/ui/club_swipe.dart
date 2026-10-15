import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';

import '../theme/theme.dart';
import 'club_icon.dart';

enum SwipeDecision { pass, invite }

/// Drives a [SwipeDeck] from outside, so the Pass and Invite buttons fling
/// the card the same way a drag does. [progress] runs from -1 (fully toward
/// Pass) to 1 (fully toward Invite).
class SwipeController {
  final progress = ValueNotifier<double>(0);
  _SwipeDeckState? _deck;

  void fling(SwipeDecision decision) => _deck?._fling(decision);

  void dispose() => progress.dispose();
}

/// A card that can be dragged left to pass or right to invite. It tilts as
/// it moves, shows a PASS or INVITE stamp, and springs back if released
/// before the threshold.
class SwipeDeck extends StatefulWidget {
  const SwipeDeck({
    super.key,
    required this.controller,
    required this.onDecision,
    required this.child,
    this.enabled = true,
  });

  final SwipeController controller;
  final ValueChanged<SwipeDecision> onDecision;
  final Widget child;
  final bool enabled;

  @override
  State<SwipeDeck> createState() => _SwipeDeckState();
}

class _SwipeDeckState extends State<SwipeDeck>
    with SingleTickerProviderStateMixin {
  static const _commitFraction = 0.32;
  static const _flingVelocity = 900.0;

  late final AnimationController _motion = AnimationController.unbounded(
    vsync: this,
  )..addListener(_onMotion);

  Offset _offset = Offset.zero;
  double _width = 360;
  var _pastThreshold = false;
  var _deciding = false;

  @override
  void initState() {
    super.initState();
    widget.controller._deck = this;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.controller.progress.value = 0;
    });
  }

  @override
  void didUpdateWidget(SwipeDeck old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      if (old.controller._deck == this) old.controller._deck = null;
      widget.controller._deck = this;
    }
  }

  @override
  void dispose() {
    if (widget.controller._deck == this) widget.controller._deck = null;
    _motion.dispose();
    super.dispose();
  }

  void _onMotion() => _setOffset(Offset(_motion.value, _offset.dy * 0.9));

  void _setOffset(Offset next) {
    setState(() => _offset = next);
    final progress = (next.dx / (_width * _commitFraction)).clamp(-1.0, 1.0);
    widget.controller.progress.value = progress;
    final past = progress.abs() >= 1;
    if (past != _pastThreshold) {
      _pastThreshold = past;
      if (past) HapticFeedback.selectionClick();
    }
  }

  void _onDragStart(DragStartDetails _) {
    if (_deciding) return;
    _motion.stop();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_deciding) return;
    _setOffset(
      Offset(_offset.dx + details.delta.dx, _offset.dy + details.delta.dy / 4),
    );
  }

  void _onDragEnd(DragEndDetails details) {
    if (_deciding) return;
    final velocity = details.velocity.pixelsPerSecond.dx;
    final far = _offset.dx.abs() > _width * _commitFraction;
    final fast = velocity.abs() > _flingVelocity;
    if (far || fast) {
      final toRight = fast ? velocity > 0 : _offset.dx > 0;
      _fling(
        toRight ? SwipeDecision.invite : SwipeDecision.pass,
        velocity: velocity,
      );
    } else {
      _springBack(velocity);
    }
  }

  void _springBack(double velocity) {
    const spring = SpringDescription(mass: 1, stiffness: 520, damping: 30);
    _motion.value = _offset.dx;
    _motion.animateWith(SpringSimulation(spring, _offset.dx, 0, velocity));
  }

  Future<void> _fling(SwipeDecision decision, {double velocity = 0}) async {
    if (_deciding || !widget.enabled) return;
    _deciding = true;
    HapticFeedback.mediumImpact();
    final sign = decision == SwipeDecision.invite ? 1.0 : -1.0;
    final target = sign * _width * 1.5;
    if (MediaQuery.disableAnimationsOf(context)) {
      _setOffset(Offset(target, 0));
    } else {
      _motion.value = _offset.dx;
      final distance = (target - _offset.dx).abs();
      final speed = math.max(velocity.abs(), 2200.0);
      final ms = (distance / speed * 1000).clamp(180, 340).round();
      await _motion.animateTo(
        target,
        duration: Duration(milliseconds: ms),
        curve: Curves.easeOutCubic,
      );
    }
    if (!mounted) return;
    widget.onDecision(decision);
    // The screen swaps in the next person, so this only runs when the same
    // card stays, for example when the request fails.
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    _deciding = false;
    _pastThreshold = false;
    _springBack(0);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _width = constraints.maxWidth;
        final progress = (_offset.dx / (_width * _commitFraction)).clamp(
          -1.0,
          1.0,
        );
        final angle = (_offset.dx / _width) * 0.22;
        return GestureDetector(
          onHorizontalDragStart: widget.enabled ? _onDragStart : null,
          onHorizontalDragUpdate: widget.enabled ? _onDragUpdate : null,
          onHorizontalDragEnd: widget.enabled ? _onDragEnd : null,
          child: Transform.translate(
            offset: _offset,
            child: Transform.rotate(
              angle: angle,
              alignment: const Alignment(0, 1.6),
              child: Stack(
                fit: StackFit.passthrough,
                children: [
                  widget.child,
                  Positioned(
                    top: 22,
                    left: 18,
                    child: _Stamp(
                      label: 'INVITE',
                      color: const Color(0xFFE7B6F2),
                      angle: -0.2,
                      strength: progress.clamp(0.0, 1.0),
                    ),
                  ),
                  Positioned(
                    top: 22,
                    right: 18,
                    child: _Stamp(
                      label: 'PASS',
                      color: Colors.white,
                      angle: 0.2,
                      strength: (-progress).clamp(0.0, 1.0),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Stamp extends StatelessWidget {
  const _Stamp({
    required this.label,
    required this.color,
    required this.angle,
    required this.strength,
  });

  final String label;
  final Color color;
  final double angle;
  final double strength;

  @override
  Widget build(BuildContext context) {
    if (strength <= 0) return const SizedBox.shrink();
    return IgnorePointer(
      child: Opacity(
        opacity: Curves.easeOut.transform(strength),
        child: Transform.rotate(
          angle: angle,
          child: Transform.scale(
            scale: 0.85 + 0.15 * strength,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0x33140C11),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: color, width: 2.4),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.45 * strength),
                        blurRadius: 24,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    child: Text(
                      label,
                      style: ClubType.inter(
                        22,
                        weight: FontWeight.w800,
                        letterSpacing: 2.2,
                        height: 1,
                        color: color,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The Pass and Invite buttons wired to a [SwipeDeck], so they light up as
/// the card is dragged toward them and fling it when tapped.
class SwipeActions extends StatelessWidget {
  const SwipeActions({super.key, required this.controller, required this.busy});

  final SwipeController controller;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: controller.progress,
      builder: (context, progress, _) => DecisionButtons(
        busy: busy,
        lean: progress,
        onPass: () => controller.fling(SwipeDecision.pass),
        onInvite: () => controller.fling(SwipeDecision.invite),
      ),
    );
  }
}

/// Pass as a frosted circle and Invite as a glowing gradient pill.
/// [lean] runs from -1 (toward Pass) to 1 (toward Invite).
class DecisionButtons extends StatelessWidget {
  const DecisionButtons({
    super.key,
    required this.onPass,
    required this.onInvite,
    required this.busy,
    this.inviteLabel = 'Invite',
    this.inviteIcon = 'send',
    this.lean = 0,
  });

  final VoidCallback onPass;
  final VoidCallback onInvite;
  final bool busy;
  final String inviteLabel;
  final String inviteIcon;
  final double lean;

  @override
  Widget build(BuildContext context) {
    final toPass = (-lean).clamp(0.0, 1.0);
    final toInvite = lean.clamp(0.0, 1.0);
    return Row(
      children: [
        _PressSpring(
          enabled: !busy,
          onTap: onPass,
          semantics: 'Pass',
          child: Transform.scale(
            scale: 1 + 0.1 * toPass,
            child: _PassButton(lean: toPass),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _PressSpring(
            enabled: !busy,
            onTap: onInvite,
            semantics: inviteLabel,
            child: Transform.scale(
              scale: 1 + 0.04 * toInvite,
              child: _InviteButton(
                lean: toInvite,
                busy: busy,
                label: inviteLabel,
                icon: inviteIcon,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PassButton extends StatelessWidget {
  const _PassButton({required this.lean});

  final double lean;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 62,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.lerp(Colors.white, ClubColors.ink, lean * 0.9)!,
              Color.lerp(const Color(0xFFF1EDEA), Colors.black, lean * 0.9)!,
            ],
          ),
          border: Border.all(
            color: Color.lerp(const Color(0x1F1A1A1A), Colors.black, lean)!,
          ),
          boxShadow: [
            const BoxShadow(
              color: Color(0x1A1A1A1A),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
            const BoxShadow(
              color: Color(0xCCFFFFFF),
              blurRadius: 0,
              spreadRadius: -1,
              offset: Offset(0, -1),
            ),
          ],
        ),
        child: Center(
          child: ClubIcon(
            'close',
            size: 24,
            color: Color.lerp(ClubColors.ink, Colors.white, lean),
          ),
        ),
      ),
    );
  }
}

class _InviteButton extends StatelessWidget {
  const _InviteButton({
    required this.lean,
    required this.busy,
    required this.label,
    required this.icon,
  });

  final double lean;
  final bool busy;
  final String label;
  final String icon;

  static const _from = Color(0xFF64316E);
  static const _mid = Color(0xFF994EA8);
  static const _to = Color(0xFFE58C8A);

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(31);
    return SizedBox(
      height: 62,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [_from, _mid, _to],
            stops: [0, 0.55, 1],
          ),
          boxShadow: [
            BoxShadow(
              color: _mid.withValues(alpha: 0.32 + 0.3 * lean),
              blurRadius: 22 + 18 * lean,
              spreadRadius: lean * 2,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Stack(
            fit: StackFit.expand,
            children: [
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x40FFFFFF), Color(0x00FFFFFF)],
                    stops: [0, 0.55],
                  ),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: radius,
                  border: Border.all(color: const Color(0x4DFFFFFF)),
                ),
              ),
              Center(
                child: busy
                    ? const SizedBox.square(
                        dimension: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ClubIcon(icon, size: 20, color: Colors.white),
                          const SizedBox(width: 10),
                          Text(
                            label,
                            style: ClubType.inter(
                              17,
                              weight: FontWeight.w700,
                              letterSpacing: 0.2,
                              height: 1,
                              color: Colors.white,
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
}

/// Squeezes its child while pressed and springs back on release.
class _PressSpring extends StatefulWidget {
  const _PressSpring({
    required this.child,
    required this.onTap,
    required this.enabled,
    required this.semantics,
  });

  final Widget child;
  final VoidCallback onTap;
  final bool enabled;
  final String semantics;

  @override
  State<_PressSpring> createState() => _PressSpringState();
}

class _PressSpringState extends State<_PressSpring> {
  var _down = false;

  void _set(bool value) {
    if (_down == value) return;
    setState(() => _down = value);
  }

  @override
  Widget build(BuildContext context) {
    final motionOff = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      button: true,
      enabled: widget.enabled,
      label: widget.semantics,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: widget.enabled ? (_) => _set(true) : null,
        onTapCancel: () => _set(false),
        onTapUp: widget.enabled ? (_) => _set(false) : null,
        onTap: widget.enabled ? widget.onTap : null,
        child: AnimatedScale(
          scale: _down ? 0.94 : 1,
          duration: Duration(milliseconds: motionOff ? 0 : (_down ? 90 : 260)),
          curve: _down ? Curves.easeOut : Curves.elasticOut,
          child: AnimatedOpacity(
            opacity: widget.enabled ? 1 : 0.6,
            duration: const Duration(milliseconds: 150),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
