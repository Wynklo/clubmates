import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../state/app_model.dart';
import '../theme/theme.dart';
import 'widgets.dart';

/// The plan-tonight field with quick suggestions.
class PlanTonightEditor extends StatelessWidget {
  const PlanTonightEditor({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final current = value.text.trim();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClubField(
              hint: 'Dinner, then dancing in Koregaon Park',
              controller: controller,
              maxLines: 2,
              error: planIssue(value.text),
              inputFormatters: [
                LengthLimitingTextInputFormatter(maxPlanTonight),
              ],
              onChanged: onChanged,
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${value.text.length}/$maxPlanTonight',
                style: ClubType.inter(12, color: ClubColors.muted),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Quick picks',
              style: ClubType.inter(
                13,
                weight: FontWeight.w600,
                color: ClubColors.muted,
              ),
            ),
            const SizedBox(height: 8),
            ChipWrap(
              children: [
                for (final idea in planSuggestions)
                  ChoiceChipButton(
                    idea,
                    selected: current == idea,
                    onPressed: () {
                      controller.text = idea;
                      controller.selection = TextSelection.collapsed(
                        offset: idea.length,
                      );
                      onChanged(idea);
                    },
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

/// Predefined interests, up to [maxInterests].
class InterestPicker extends StatelessWidget {
  const InterestPicker({
    super.key,
    required this.selected,
    required this.onToggle,
  });

  final List<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final full = selected.length >= maxInterests;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          full
              ? 'All $maxInterests picked. Tap one to swap it out.'
              : '${selected.length} of $maxInterests picked',
          style: ClubType.inter(
            13,
            weight: FontWeight.w600,
            color: full ? ClubColors.brand : ClubColors.muted,
          ),
        ),
        const SizedBox(height: 10),
        ChipWrap(
          children: [
            for (final option in interestOptions)
              Opacity(
                opacity: full && !selected.contains(option) ? 0.45 : 1,
                child: ChoiceChipButton(
                  option,
                  selected: selected.contains(option),
                  onPressed: full && !selected.contains(option)
                      ? null
                      : () {
                          HapticFeedback.selectionClick();
                          onToggle(option);
                        },
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Edit plan tonight or interests straight from the Profile tab.
Future<void> showNightlifeSheet(
  BuildContext context, {
  bool interests = false,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: ClubColors.paper,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) => _NightlifeSheet(interests: interests),
  );
}

class _NightlifeSheet extends StatefulWidget {
  const _NightlifeSheet({required this.interests});

  final bool interests;

  @override
  State<_NightlifeSheet> createState() => _NightlifeSheetState();
}

class _NightlifeSheetState extends State<_NightlifeSheet> {
  late final TextEditingController _plan;
  late List<String> _picked;

  @override
  void initState() {
    super.initState();
    final model = AppScope.read(context);
    _plan = TextEditingController(text: model.planTonight);
    _picked = [...model.interests];
  }

  @override
  void dispose() {
    _plan.dispose();
    super.dispose();
  }

  void _toggle(String option) {
    setState(() {
      _picked = _picked.contains(option)
          ? _picked.where((item) => item != option).toList()
          : [..._picked, option].take(maxInterests).toList();
    });
  }

  Future<void> _save(AppModel model) async {
    final navigator = Navigator.of(context);
    final saved = await model.saveNightlife(plan: _plan.text, picked: _picked);
    if (saved) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final model = AppScope.watch(context);
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final title = widget.interests ? 'Your interests' : 'Your plan tonight';
    final supporting = widget.interests
        ? 'Pick what you are into. They show on your profile.'
        : 'Tell people what you are up for. It shows on your card in Club.';
    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.88,
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: ClubType.lora(28)),
                      const SizedBox(height: 6),
                      Text(
                        supporting,
                        style: ClubType.inter(
                          14,
                          color: ClubColors.muted,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 18),
                      if (widget.interests)
                        InterestPicker(selected: _picked, onToggle: _toggle)
                      else
                        PlanTonightEditor(
                          controller: _plan,
                          onChanged: (_) => setState(() {}),
                        ),
                      if (model.errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          model.errorMessage!,
                          style: ClubType.inter(13, color: ClubColors.error),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
                child: PrimaryButton(
                  'Save',
                  loading: model.busy,
                  onPressed: planIssue(_plan.text) != null
                      ? null
                      : () => _save(model),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
