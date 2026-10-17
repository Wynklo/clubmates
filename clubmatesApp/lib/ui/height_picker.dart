import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/records.dart';
import '../theme/theme.dart';

enum HeightUnit { ft, cm }

/// Height in centimetres, picked on an iOS-style wheel and shown in feet or
/// centimetres. The stored value is always centimetres.
class HeightPicker extends StatefulWidget {
  const HeightPicker({super.key, required this.cm, required this.onChanged});

  /// Current height, or null when not set yet.
  final int? cm;
  final ValueChanged<int> onChanged;

  @override
  State<HeightPicker> createState() => _HeightPickerState();
}

class _HeightPickerState extends State<HeightPicker> {
  static const _fallbackCm = 170;
  static final _minInches = (minHeightCm / 2.54).ceil();
  static final _maxInches = (maxHeightCm / 2.54).floor();

  var _unit = HeightUnit.ft;
  late FixedExtentScrollController _wheel = FixedExtentScrollController(
    initialItem: _selectedIndex,
  );

  @override
  void dispose() {
    _wheel.dispose();
    super.dispose();
  }

  void _switchUnit(HeightUnit unit) {
    final old = _wheel;
    setState(() {
      _unit = unit;
      _wheel = FixedExtentScrollController(initialItem: _selectedIndex);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
  }

  int get _cm => widget.cm ?? _fallbackCm;

  int _cmForInches(int inches) =>
      (inches * 2.54).round().clamp(minHeightCm, maxHeightCm);

  int get _itemCount => _unit == HeightUnit.cm
      ? maxHeightCm - minHeightCm + 1
      : _maxInches - _minInches + 1;

  int get _selectedIndex => _unit == HeightUnit.cm
      ? _cm - minHeightCm
      : ((_cm / 2.54).round() - _minInches).clamp(0, _itemCount - 1);

  String _label(int index) => _unit == HeightUnit.cm
      ? '${minHeightCm + index} cm'
      : feetLabel(_cmForInches(_minInches + index));

  void _select(int index) {
    HapticFeedback.selectionClick();
    widget.onChanged(
      _unit == HeightUnit.cm
          ? minHeightCm + index
          : _cmForInches(_minInches + index),
    );
  }

  @override
  Widget build(BuildContext context) {
    final set = widget.cm != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                set
                    ? (_unit == HeightUnit.cm
                          ? '$_cm cm'
                          : '${feetLabel(_cm)}  ·  $_cm cm')
                    : 'Scroll to set your height',
                style: set
                    ? ClubType.lora(22, height: 1.2)
                    : ClubType.inter(15, color: ClubColors.disabledText),
              ),
            ),
            UnitSwitch(unit: _unit, onChanged: _switchUnit),
          ],
        ),
        const SizedBox(height: 12),
        DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xD6FFFFFF),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: const Color(0x171A1A1A)),
          ),
          child: SizedBox(
            height: 176,
            child: CupertinoPicker(
              key: ValueKey(_unit),
              scrollController: _wheel,
              itemExtent: 38,
              squeeze: 1.1,
              selectionOverlay: const CupertinoPickerDefaultSelectionOverlay(
                background: Color(0x14994EA8),
              ),
              onSelectedItemChanged: _select,
              children: [
                for (var i = 0; i < _itemCount; i++)
                  Center(
                    child: Text(
                      _label(i),
                      style: ClubType.inter(20, height: 1),
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

/// iOS stepper-shaped switch with "ft" and "cm" halves.
class UnitSwitch extends StatelessWidget {
  const UnitSwitch({super.key, required this.unit, required this.onChanged});

  final HeightUnit unit;
  final ValueChanged<HeightUnit> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 92,
      height: 32,
      child: Stack(
        children: [
          Row(
            children: [
              _half(HeightUnit.ft, left: true),
              _half(HeightUnit.cm, left: false),
            ],
          ),
          const Positioned(
            left: 45.5,
            top: 4,
            child: SizedBox(
              width: 1,
              height: 24,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Color(0x4D3C3C43),
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _half(HeightUnit value, {required bool left}) {
    final selected = unit == value;
    final radius = left
        ? const BorderRadius.horizontal(left: Radius.circular(100))
        : const BorderRadius.horizontal(right: Radius.circular(100));
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: value == HeightUnit.ft ? 'Feet' : 'Centimetres',
        child: Material(
          color: selected ? const Color(0x33747480) : const Color(0x14747480),
          borderRadius: radius,
          child: InkWell(
            borderRadius: radius,
            onTap: selected
                ? null
                : () {
                    HapticFeedback.selectionClick();
                    onChanged(value);
                  },
            child: Center(
              child: Text(
                value.name,
                style: ClubType.inter(
                  17,
                  weight: FontWeight.w600,
                  height: 22 / 17,
                  letterSpacing: -0.43,
                  color: selected ? ClubColors.ink : ClubColors.disabledText,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
