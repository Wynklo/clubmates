import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/records.dart';
import '../theme/theme.dart';
import 'club_icon.dart';
import 'liquid_glass.dart' show glassPaint;
import 'widgets.dart';

/// A prompt as other members see it on a profile.
class PromptCard extends StatelessWidget {
  const PromptCard(this.prompt, {super.key});

  final ProfilePrompt prompt;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0x171A1A1A)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D23141D),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              prompt.prompt,
              style: ClubType.inter(
                13,
                weight: FontWeight.w600,
                color: ClubColors.muted,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 10),
            Text(prompt.answer, style: ClubType.lora(24, height: 1.25)),
          ],
        ),
      ),
    );
  }
}

/// The member's own prompts, with add, edit and remove.
class PromptEditorList extends StatelessWidget {
  const PromptEditorList({
    super.key,
    required this.prompts,
    required this.onChanged,
    required this.onRemove,
  });

  final List<ProfilePrompt> prompts;
  final void Function(int index, ProfilePrompt prompt) onChanged;
  final ValueChanged<int> onRemove;

  Future<void> _edit(BuildContext context, int index) async {
    final used = {
      for (var i = 0; i < prompts.length; i++)
        if (i != index) prompts[i].prompt,
    };
    final result = await showPromptSheet(
      context,
      current: index < prompts.length ? prompts[index] : null,
      used: used,
    );
    if (result != null) onChanged(index, result);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < prompts.length; i++) ...[
          _OwnPromptCard(
            prompt: prompts[i],
            onTap: () => _edit(context, i),
            onRemove: () => onRemove(i),
          ),
          const SizedBox(height: 10),
        ],
        if (prompts.length < maxProfilePrompts)
          SecondaryButton(
            prompts.isEmpty ? 'Add a prompt' : 'Add another prompt',
            icon: 'plus',
            onPressed: () => _edit(context, prompts.length),
          ),
      ],
    );
  }
}

class _OwnPromptCard extends StatelessWidget {
  const _OwnPromptCard({
    required this.prompt,
    required this.onTap,
    required this.onRemove,
  });

  final ProfilePrompt prompt;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: glassPaint(radius: 20),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 6, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        prompt.prompt,
                        style: ClubType.inter(
                          13,
                          weight: FontWeight.w600,
                          color: ClubColors.muted,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        prompt.answer,
                        style: ClubType.inter(16, height: 1.35),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Remove prompt',
                  onPressed: onRemove,
                  icon: const ClubIcon('close', size: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Pick a prompt, then write the answer. Returns null when dismissed.
Future<ProfilePrompt?> showPromptSheet(
  BuildContext context, {
  ProfilePrompt? current,
  Set<String> used = const {},
}) {
  return showModalBottomSheet<ProfilePrompt>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: ClubColors.paper,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) => _PromptSheet(current: current, used: used),
  );
}

class _PromptSheet extends StatefulWidget {
  const _PromptSheet({required this.current, required this.used});

  final ProfilePrompt? current;
  final Set<String> used;

  @override
  State<_PromptSheet> createState() => _PromptSheetState();
}

class _PromptSheetState extends State<_PromptSheet> {
  late String? _prompt = widget.current?.prompt;
  late final _answer = TextEditingController(text: widget.current?.answer);

  @override
  void dispose() {
    _answer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final prompt = _prompt;
    if (prompt == null) {
      final options = [
        for (final option in promptOptions)
          if (!widget.used.contains(option)) option,
      ];
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pick a prompt', style: ClubType.lora(24)),
            const SizedBox(height: 4),
            Text(
              'Give people something to start a conversation with.',
              style: ClubType.inter(14, color: ClubColors.muted),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: options.length,
                separatorBuilder: (_, _) =>
                    const Divider(height: 1, color: Color(0x141A1A1A)),
                itemBuilder: (context, index) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    options[index],
                    style: ClubType.inter(16, height: 1.3),
                  ),
                  trailing: const ClubIcon('chevron', size: 16),
                  onTap: () => setState(() => _prompt = options[index]),
                ),
              ),
            ),
          ],
        ),
      );
    }
    final answer = _answer.text.trim();
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, keyboard + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(prompt, style: ClubType.lora(22))),
              TextLink(
                'Change',
                underline: false,
                color: ClubColors.brand,
                onPressed: () => setState(() => _prompt = null),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClubField(
            hint: 'Write your answer',
            controller: _answer,
            maxLines: 4,
            autofocus: true,
            inputFormatters: [
              LengthLimitingTextInputFormatter(maxPromptAnswer),
            ],
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 6),
          Text(
            '${_answer.text.length}/$maxPromptAnswer',
            style: ClubType.inter(12, color: ClubColors.disabledText),
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            'Save prompt',
            onPressed: answer.isEmpty
                ? null
                : () => Navigator.pop(
                    context,
                    ProfilePrompt(prompt: prompt, answer: answer),
                  ),
          ),
        ],
      ),
    );
  }
}
