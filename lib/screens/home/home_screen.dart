import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../data/seed_data.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queueState = ref.watch(queueProvider);
    final morningState = ref.watch(morningRoutineProvider);
    final weeklyStats = ref.watch(weeklyStatsProvider);
    final active = ref.watch(activeWorkoutProvider);
    final suggested = SeedData.getSplitDay(queueState.splitType, queueState.nextDayIndex);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ─── Header ───
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getGreeting(),
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Freedom Fitness',
                      style: GoogleFonts.outfit(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ─── Resume Workout Banner ───
            if (active != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                  child: GestureDetector(
                    onTap: () => context.push('/workout'),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                      ),
                      child: Row(children: [
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.refresh, color: AppColors.primary),
                        ),
                        const SizedBox(width: 14),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Resume Workout', style: GoogleFonts.outfit(color: AppColors.primary, fontSize: 15, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text(active.dayLabel, style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                        ])),
                        const Icon(Icons.chevron_right, color: AppColors.primary),
                      ]),
                    ),
                  ),
                ),
              ),

            // ─── Morning Routine Card ───
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: _MorningRoutineCard(
                  state: morningState,
                  onTap: () => context.push('/morning'),
                ),
              ),
            ),

            // ─── Weekly Progress ───
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                child: _WeeklyProgressCard(stats: weeklyStats),
              ),
            ),

            // ─── Today's Suggested Workout ───
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                child: _SuggestedWorkoutCard(
                  suggested: suggested,
                  queueState: queueState,
                  onStart: () => _startWorkout(context, ref, queueState.splitType, suggested.dayIndex, suggested.dayIndex),
                  onOverride: () => _showOverrideDialog(context, ref, queueState),
                ),
              ),
            ),

            // ─── Floater Button ───
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                child: _FloaterCard(
                  onTap: () => _showFloaterDialog(context, ref),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning ☀️';
    if (hour < 17) return 'Good Afternoon 💪';
    return 'Good Evening 🌙';
  }

  void _startWorkout(
    BuildContext context,
    WidgetRef ref,
    WorkoutSplitType splitType,
    int suggestedDayIndex,
    int actualDayIndex, {
    OverrideReason? reason,
    String? notes,
  }) {
    ref.read(activeWorkoutProvider.notifier).startWorkout(
      splitType: splitType,
      suggestedDayIndex: suggestedDayIndex,
      actualDayIndex: actualDayIndex,
      overrideReason: reason,
      overrideNotes: notes,
    );
    context.push('/workout');
  }

  void _showOverrideDialog(BuildContext context, WidgetRef ref, QueueState queueState) {
    final days = SeedData.getDayMetadatas(queueState.splitType);
    final suggested = SeedData.getSplitDay(queueState.splitType, queueState.nextDayIndex);
    int? selectedDayIdx;
    OverrideReason? selectedReason;
    final notesController = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              24, 24, 24,
              MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Text(
                'Switch Workout?',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'The app suggested ${suggested.label}. Choose a different day:',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 20),
              ...days.map((day) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: () => setState(() => selectedDayIdx = day.dayIndex),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: selectedDayIdx == day.dayIndex
                          ? AppColors.primary.withValues(alpha: 0.15)
                          : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selectedDayIdx == day.dayIndex
                            ? AppColors.primary
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          day.label,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: selectedDayIdx == day.dayIndex
                                ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                        Text(
                          day.subtitle,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                        ),
                        if (selectedDayIdx == day.dayIndex) ...[
                          const SizedBox(height: 10),
                          _buildDayPreview(ctx, queueState.splitType, day.dayIndex),
                        ],
                      ],
                    ),
                  ),
                ),
              )),
              const SizedBox(height: 12),
              Text('Why switch?', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 8),
              ...OverrideReason.values.map((reason) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: GestureDetector(
                  onTap: () => setState(() => selectedReason = reason),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: selectedReason == reason
                          ? AppColors.warning.withValues(alpha: 0.12)
                          : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Text(reason.icon, style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 8),
                        Text(
                          reason.label.replaceAll(RegExp(r'[^\w\s]'), '').trim(),
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )),
              if (selectedReason == OverrideReason.other) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: notesController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Tell us more...',
                    hintStyle: TextStyle(color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.surfaceLight,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: selectedDayIdx == null || selectedReason == null
                        ? null
                        : () {
                            Navigator.pop(ctx);
                            _startWorkout(
                              context, ref, queueState.splitType, suggested.dayIndex, selectedDayIdx!,
                              reason: selectedReason,
                              notes: notesController.text,
                            );
                          },
                    child: Text('Start ${selectedDayIdx != null ? SeedData.getSplitDay(queueState.splitType, selectedDayIdx!).label : ''}'),
                  ),
                ),
            ],
          ),
          ),
        ),
      ),
    );
  }

  /// Preview of the exercises that make up a split day (used in the
  /// "Switch Workout?" sheet so the user can see what they'd be doing).
  Widget _buildDayPreview(BuildContext ctx, WorkoutSplitType split, int dayIndex) {
    final slots = SeedData.getDaySlots(split, dayIndex)
        .where((s) => !s.isAlternative)
        .toList();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${slots.length} exercises',
            style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          ...slots.asMap().entries.map((entry) {
            final ex = entry.value.exercise;
            final reps = ex.isDurationBased
                ? '${ex.durationSeconds}s'
                : '${ex.reps} reps';
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Container(width: 20, height: 20,
                    decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                    child: Center(child: Text('${entry.key + 1}', style: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w700)))),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('${ex.sets} × $reps  ${ex.name}',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ),
                  if (ex.gifUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: SizedBox(
                        width: 34, height: 34,
                        child: Image.network(ex.gifUrl!, fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => Container(color: AppColors.surfaceLight,
                            child: const Icon(Icons.fitness_center, color: AppColors.textMuted, size: 14))),
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showFloaterDialog(BuildContext context, WidgetRef ref) {
    FloaterType? selectedType;
    final durationController = TextEditingController(text: '60');
    final distanceController = TextEditingController();
    final setsController = TextEditingController();
    final customNameController = TextEditingController();
    final notesController = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: EdgeInsets.fromLTRB(
            24, 24, 24,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textMuted,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Log Floater Activity',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This won\'t advance your workout queue.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 20),
              ...FloaterType.values.map((type) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: () => setState(() => selectedType = type),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: selectedType == type
                          ? AppColors.floater.withValues(alpha: 0.15)
                          : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selectedType == type
                            ? AppColors.floater
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(type.label.split(' ')[0], style: const TextStyle(fontSize: 24)),
                        const SizedBox(width: 12),
                        Text(
                          type.label.substring(2).trim(),
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: selectedType == type
                                ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )),
              const SizedBox(height: 12),

              // Dynamic fields based on type
              if (selectedType == FloaterType.run)
                TextField(
                  controller: distanceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Distance (miles)',
                    hintText: 'e.g. 3.2',
                    hintStyle: TextStyle(color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.surfaceLight,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              if (selectedType == FloaterType.run) const SizedBox(height: 12),

              if (selectedType == FloaterType.tennis)
                TextField(
                  controller: setsController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Sets Played',
                    hintText: 'e.g. 2/3 or 3',
                    hintStyle: TextStyle(color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.surfaceLight,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              if (selectedType == FloaterType.tennis) const SizedBox(height: 12),

              if (selectedType == FloaterType.other)
                TextField(
                  controller: customNameController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Activity Name',
                    hintText: 'e.g. Yoga, Swimming, Bike',
                    hintStyle: TextStyle(color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.surfaceLight,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              if (selectedType == FloaterType.other) const SizedBox(height: 12),

              TextField(
                controller: durationController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Duration (minutes)',
                  labelStyle: TextStyle(color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.surfaceLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: selectedType == null
                      ? null
                      : () {
                          ref.read(floaterProvider.notifier).logFloater(
                            type: selectedType!,
                            durationMinutes: int.tryParse(durationController.text) ?? 60,
                            distance: selectedType == FloaterType.run
                                ? distanceController.text.isNotEmpty ? distanceController.text : null
                                : null,
                            setsPlayed: selectedType == FloaterType.tennis
                                ? setsController.text.isNotEmpty ? setsController.text : null
                                : null,
                            customName: selectedType == FloaterType.other
                                ? customNameController.text.isNotEmpty ? customNameController.text : null
                                : null,
                            notes: notesController.text,
                          );
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${selectedType!.label} logged!'),
                              backgroundColor: AppColors.primary,
                            ),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.floater,
                  ),
                  child: const Text('Log Activity'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
//  Morning Routine Card
// ──────────────────────────────────────────────────────────────

class _MorningRoutineCard extends StatelessWidget {
  final MorningRoutineState state;
  final VoidCallback onTap;

  const _MorningRoutineCard({required this.state, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final done = state.isCompletedToday;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: done
              ? LinearGradient(
                  colors: [
                    AppColors.morning.withValues(alpha: 0.2),
                    AppColors.morning.withValues(alpha: 0.05),
                  ],
                )
              : AppColors.cardGradient,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: done ? AppColors.morning.withValues(alpha: 0.4) : AppColors.surfaceLight,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: done
                    ? AppColors.morning.withValues(alpha: 0.2)
                    : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                done ? Icons.check_circle : Icons.wb_sunny_outlined,
                color: AppColors.morning,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Daily Ignition',
                    style: GoogleFonts.outfit(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    done ? 'Completed ✓' : '5-10 min morning routine',
                    style: TextStyle(
                      color: done ? AppColors.morning : AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
//  Weekly Progress Card
// ──────────────────────────────────────────────────────────────

class _WeeklyProgressCard extends StatelessWidget {
  final Map<String, dynamic> stats;

  const _WeeklyProgressCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final gym = stats['gymSessions'] ?? 0;
    final floaters = stats['floaters'] ?? 0;
    final gymGoal = 4;
    final floaterGoal = 1;

    // Build day chips dynamically
    final dayChips = <Widget>[];
    final dayColors = [AppColors.workoutA, AppColors.workoutB, AppColors.primary, AppColors.floater, AppColors.accent];
    for (int i = 0; i < 5; i++) {
      final key = 'workoutDay$i';
      final labelKey = 'workoutDayLabel$i';
      if (stats.containsKey(key)) {
        dayChips.add(_StatChip(
          label: stats[labelKey] as String? ?? 'Day ${i + 1}',
          count: stats[key] ?? 0,
          color: dayColors[i % dayColors.length],
        ));
        dayChips.add(const SizedBox(width: 8));
      }
    }
    if (dayChips.isNotEmpty) dayChips.removeLast(); // remove last spacer

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surfaceLight, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This Week',
            style: GoogleFonts.outfit(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ProgressIndicator(
                  label: 'Gym',
                  current: gym,
                  goal: gymGoal,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _ProgressIndicator(
                  label: 'Floater',
                  current: floaters,
                  goal: floaterGoal,
                  color: AppColors.floater,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: dayChips),
          ),
        ],
      ),
    );
  }
}

class _ProgressIndicator extends StatelessWidget {
  final String label;
  final int current;
  final int goal;
  final Color color;

  const _ProgressIndicator({
    required this.label,
    required this.current,
    required this.goal,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (current / goal).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            Text(
              '$current/$goal',
              style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.surfaceLight,
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatChip({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label: $count',
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
//  Suggested Workout Card
// ──────────────────────────────────────────────────────────────

class _SuggestedWorkoutCard extends StatelessWidget {
  final SplitDay suggested;
  final QueueState queueState;
  final VoidCallback onStart;
  final VoidCallback onOverride;

  const _SuggestedWorkoutCard({
    required this.suggested,
    required this.queueState,
    required this.onStart,
    required this.onOverride,
  });

  @override
  Widget build(BuildContext context) {
    final gradient = AppColors.workoutBGradient;
    final slots = SeedData.getMainSlots(queueState.splitType, suggested.dayIndex);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: gradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.workoutB.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'SUGGESTED',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: onOverride,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      'SWITCH',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.9),
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              suggested.label,
              style: GoogleFonts.outfit(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              suggested.subtitle,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: slots.map((s) => ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 200),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    s.exercise.name,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 12,
                    ),
                  ),
                ),
              )).toList(),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onStart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.workoutB,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Start ${suggested.label}',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            if (queueState.lastWorkoutDate != null) ...[
              const SizedBox(height: 12),
              Center(
                child: Text(
                  'Last: ${queueState.lastDayIndex != null ? SeedData.getSplitDay(queueState.splitType, queueState.lastDayIndex!).label : "—"}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
//  Floater Card
// ──────────────────────────────────────────────────────────────

class _FloaterCard extends StatelessWidget {
  final VoidCallback onTap;

  const _FloaterCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.floater.withValues(alpha: 0.1),
              AppColors.floater.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.floater.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: AppColors.floater.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.swap_horiz, color: AppColors.floater, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Log Floater',
                    style: GoogleFonts.outfit(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tennis, Run, or Other',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
            Icon(Icons.add_circle_outline, color: AppColors.floater),
          ],
        ),
      ),
    );
  }
}
