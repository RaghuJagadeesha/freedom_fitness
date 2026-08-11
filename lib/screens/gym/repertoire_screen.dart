import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../data/exercise_repertoire.dart';

/// Full-screen explorer over the bundled exercise dataset.
/// Multi-select with the standard row layout: checkbox | details | gif.
class RepertoireScreen extends StatefulWidget {
  const RepertoireScreen({super.key});

  @override
  State<RepertoireScreen> createState() => _RepertoireScreenState();
}

class _RepertoireScreenState extends State<RepertoireScreen> {
  List<RepertoireExercise>? _all;
  String _query = '';
  String? _bodyPart;
  String? _equipment;
  final Set<String> _selected = {};

  @override
  void initState() {
    super.initState();
    ExerciseRepertoire.load().then((list) {
      if (mounted) setState(() => _all = list);
    });
  }

  List<RepertoireExercise> get _filtered {
    final all = _all ?? const <RepertoireExercise>[];
    final q = _query.trim().toLowerCase();
    return all.where((e) {
      if (q.isNotEmpty &&
          !e.name.toLowerCase().contains(q) &&
          !e.target.toLowerCase().contains(q) &&
          !e.description.toLowerCase().contains(q)) {
        return false;
      }
      if (_bodyPart != null &&
          e.bodyPart.toLowerCase() != _bodyPart!.toLowerCase()) {
        return false;
      }
      if (_equipment != null &&
          e.equipment.toLowerCase() != _equipment!.toLowerCase()) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final all = _all;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Exercise Library',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context)),
        actions: [
          if (_selected.isNotEmpty)
            TextButton(
              onPressed: () => Navigator.pop(context, _selected.toList()),
              child: Text('Add (${_selected.length})',
                  style: const TextStyle(color: AppColors.primary)),
            ),
        ],
      ),
      body: Column(
        children: [
          // ─── Search + filters ───
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Search exercises, muscles...',
                hintStyle: const TextStyle(color: AppColors.textMuted),
                prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.cardBg,
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          if (all != null) ...[
            _FilterChips(
              values: ExerciseRepertoire.bodyParts(all),
              selected: _bodyPart,
              onSelect: (v) => setState(() => _bodyPart = v),
            ),
            _FilterChips(
              values: ExerciseRepertoire.equipmentTypes(all),
              selected: _equipment,
              onSelect: (v) => setState(() => _equipment = v),
            ),
          ],

          // ─── Results ───
          Expanded(
            child: all == null
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _filtered.isEmpty
                    ? const Center(
                        child: Text('No exercises match',
                            style: TextStyle(color: AppColors.textMuted)),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                        itemCount: _filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 4),
                        itemBuilder: (ctx, i) => _ExerciseRow(
                          exercise: _filtered[i],
                          selected: _selected.contains(_filtered[i].id),
                          onToggle: () => setState(() {
                            final id = _filtered[i].id;
                            if (_selected.contains(id)) {
                              _selected.remove(id);
                            } else {
                              _selected.add(id);
                            }
                          }),
                        ),
                      ),
          ),
        ],
      ),
      bottomNavigationBar: _selected.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context, _selected.toList()),
                    icon: const Icon(Icons.add),
                    label: Text('Add ${_selected.length} to Workout'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  final List<String> values;
  final String? selected;
  final ValueChanged<String?> onSelect;
  const _FilterChips({
    required this.values,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        children: [
          ChoiceChip(
            label: const Text('All', style: TextStyle(fontSize: 12)),
            selected: selected == null,
            onSelected: (_) => onSelect(null),
            selectedColor: AppColors.surfaceLight,
            backgroundColor: AppColors.cardBg,
            labelStyle: const TextStyle(color: AppColors.textMuted),
          ),
          ...values.map((v) => Padding(
                padding: const EdgeInsets.only(left: 6),
                child: ChoiceChip(
                  label: Text(v, style: const TextStyle(fontSize: 12)),
                  selected: selected == v,
                  onSelected: (_) => onSelect(v),
                  selectedColor: AppColors.primary.withValues(alpha: 0.25),
                  backgroundColor: AppColors.cardBg,
                  labelStyle: TextStyle(
                    color: selected == v
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                ),
              )),
        ],
      ),
    );
  }
}

class _ExerciseRow extends StatefulWidget {
  final RepertoireExercise exercise;
  final bool selected;
  final VoidCallback onToggle;
  const _ExerciseRow({
    required this.exercise,
    required this.selected,
    required this.onToggle,
  });

  @override
  State<_ExerciseRow> createState() => _ExerciseRowState();
}

class _ExerciseRowState extends State<_ExerciseRow> {
  bool _expanded = false;

  RepertoireExercise get exercise => widget.exercise;

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    return Container(
      decoration: BoxDecoration(
        color: selected
            ? AppColors.primary.withValues(alpha: 0.1)
            : AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.5)
              : AppColors.surfaceLight,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // ─── Collapsed header row ───
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 10, 8),
              child: Row(
                children: [
                  // ─── Select checkbox (left) ───
                  Checkbox(
                    value: selected,
                    onChanged: (_) => widget.onToggle(),
                    activeColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.textMuted),
                  ),
                  const SizedBox(width: 6),
                  // ─── Details (middle) ───
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exercise.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${_title(exercise.bodyPart)} • ${_title(exercise.equipment)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 12),
                        ),
                        if (exercise.target.isNotEmpty) ...[
                          const SizedBox(height: 1),
                          Text(
                            'Target: ${_title(exercise.target)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 11),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  // ─── GIF (right) ───
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 56,
                      height: 56,
                      child: Image.network(
                        exercise.gifUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: AppColors.surfaceLight,
                          child: const Icon(Icons.fitness_center,
                              color: AppColors.textMuted, size: 20),
                        ),
                        loadingBuilder: (ctx, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            color: AppColors.surfaceLight,
                            child: const Center(
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.textMuted),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // ─── Expand chevron ───
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.expand_more,
                        color: AppColors.textMuted, size: 22),
                  ),
                ],
              ),
            ),
          ),

          // ─── Expanded detail: larger GIF + description ───
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: _expanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.surfaceLight,
                              border: Border.all(color: AppColors.surfaceLight),
                            ),
                            child: AspectRatio(
                              aspectRatio: 16 / 9,
                              child: Image.network(
                                exercise.gifUrl,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Center(
                                        child: Icon(Icons.fitness_center,
                                            color: AppColors.textMuted,
                                            size: 40)),
                                loadingBuilder: (ctx, child, progress) {
                                  if (progress == null) return child;
                                  return const Center(
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.textMuted),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        if (exercise.description.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            exercise.description,
                            style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                                height: 1.4),
                          ),
                        ],
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }

  static String _title(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}