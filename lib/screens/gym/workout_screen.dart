import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../data/seed_data.dart';
import '../../data/database.dart';
import '../../data/exercise_repertoire.dart';
import 'custom_exercise_detail_screen.dart';

class WorkoutScreen extends ConsumerStatefulWidget {
  const WorkoutScreen({super.key});

  @override
  ConsumerState<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends ConsumerState<WorkoutScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  final List<CustomSwap> _customExercises = [];
  Timer? _restTimer;
  int _restElapsed = 0;
  bool _resting = false;
  int? _restAfterSessionIndex;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _restTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(activeWorkoutProvider);
    if (session == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Text('No active workout',
              style: TextStyle(color: AppColors.textPrimary)),
        ),
      );
    }

    final timerState = ref.watch(workoutTimerProvider);
    ref.listen<WorkoutTimerState>(workoutTimerProvider, (prev, next) {
      if (prev != null && !prev.isHardStopTriggered && next.isHardStopTriggered && next.canExtend) {
        _showExtensionDialog();
      }
    });
    // Auto-start a between-exercises elapsed timer whenever an exercise's last
    // set is logged (transitions from incomplete to complete). The rest is
    // attributed to that just-completed exercise and persisted.
    ref.listen<WorkoutSession?>(activeWorkoutProvider, (prev, next) {
      if (prev == null || next == null) return;
      if (_resting || _restTimer != null) return;
      final completedNow = _findJustCompleted(prev, next);
      if (completedNow != null) {
        _restAfterSessionIndex = completedNow;
        _startRest();
      }
    });
    // End-of-rest detection: once the user starts a different exercise (logs
    // its first set), stop the timer and persist how long the rest lasted.
    ref.listen<WorkoutSession?>(activeWorkoutProvider, (prev, next) {
      if (prev == null || next == null) return;
      if (!_resting) return;
      for (var i = 0; i < next.exercises.length; i++) {
        final justStarted = next.exercises[i].sets.isNotEmpty &&
            (prev.exercises.length <= i || prev.exercises[i].sets.isEmpty);
        if (justStarted && i != _restAfterSessionIndex) {
          _stopRest(record: true);
          break;
        }
      }
    });
    final swapMap = ref.watch(activeSwapProvider);
    final splitType = session.splitType;
    final dayIdx = session.dayIndex;
    final allSlots = SeedData.getMainSlots(splitType, dayIdx);

    // Determine which slots to show based on hard-stop: skip any exercise that
    // was not completed for the day.
    final List<ExerciseSlot> showSlots;
    if (timerState.skipAlternatives) {
      showSlots = [
        for (final s in allSlots)
          if (_isCompleted(allSlots.indexOf(s), s.exercise.sets, session)) s,
      ];
    } else {
      showSlots = allSlots;
    }
    final skippedCount = allSlots.length - showSlots.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          session.dayLabel,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _showCancelDialog(context),
        ),
        actions: [
          if (timerState.lastOverrideReason != null)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                timerState.lastOverrideReason!,
                style: const TextStyle(color: AppColors.warning, fontSize: 10, fontWeight: FontWeight.w600),
              ),
            ),
          if (timerState.isHardStopTriggered)
            FadeTransition(
              opacity: _pulseController,
              child: Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.error, width: 1),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.warning_amber_rounded, size: 14, color: AppColors.error),
                    SizedBox(width: 4),
                    Text('FINAL 10', style: TextStyle(color: AppColors.error, fontSize: 10, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // ─── 60-Minute Countdown Banner ───
          _CountdownBanner(timerState: timerState),

          Expanded(
            child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                children: [
                  // ─── Primer (logged exercises) ───
                  _BlockHeader(
                    label: 'Primer',
                    subtitle: 'Metabolic warm-up • tap each to mark done',
                    color: AppColors.secondary,
                    icon: Icons.directions_run,
                  ),
                  ..._buildPrimerTiles(session),

                  const SizedBox(height: 16),

                  // ─── Workout Exercises (flat list) ───
                  _BlockHeader(
                    label: 'Workout',
                    subtitle: timerState.skipAlternatives
                        ? '$skippedCount not completed were skipped • Final 10 active'
                        : 'Log sets • Tap any exercise',
                    color: AppColors.secondary,
                    icon: Icons.fitness_center,
                  ),
                  ..._buildExerciseTiles(
                    session, splitType,
                    allSlots: allSlots,
                    showSlots: showSlots,
                    swapMap: swapMap,
                  ),

                  // ─── Between-Exercises Rest Timer (elapsed seconds) ───
                  if (_resting)
                    _RestBanner(
                      elapsed: _restElapsed,
                      onSkip: () => _stopRest(record: true),
                    ),
                  const SizedBox(height: 8),

                  // Show skipped exercises if hard-stopped
                  if (timerState.skipAlternatives) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.skip_next, color: AppColors.error, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Hard Stop: $skippedCount uncompleted exercise(s) '
                              'skipped. Completed work is saved.',
                              style: TextStyle(color: AppColors.error, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // ─── Custom Exercises ───
                  if (_customExercises.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _BlockHeader(
                      label: 'Custom Exercises',
                      subtitle: 'Added by you',
                      color: AppColors.primary,
                      icon: Icons.add_box_outlined,
                    ),
                     ..._customExercises.map((custom) {
                      return GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => CustomExerciseDetailScreen(custom: custom),
                        )),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.fitness_center, color: AppColors.primary, size: 18),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(custom.exerciseName,
                                      style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                                    Text('${custom.exercise.sets} × ${custom.exercise.reps} reps',
                                      style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () => _renameCustomExercise(custom),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(Icons.edit, color: AppColors.primary, size: 16),
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.chevron_right, color: AppColors.primary, size: 18),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],

                  const SizedBox(height: 16),

                  // ─── Manual Override Buttons ───
                  _ManualOverrideButtons(
                    onLowEnergy: () => _showLowEnergySwap(splitType, dayIdx),
                  ),

                  const SizedBox(height: 16),

                  // ─── Add Custom Exercise ───
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showAddCustomExercise(),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Custom Exercise'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.4)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ─── Complete Button ───
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _completeWorkout(context, ref, timerState),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        'Complete ${session.dayLabel}',
                        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  int get _primerCount => SeedData.primerCount;
  int _sessionIndexOf(int slotIndex) => slotIndex + _primerCount;

  List<Widget> _buildPrimerTiles(WorkoutSession session) {
    const primers = SeedData.primerExercises;
    return [
      for (var i = 0; i < primers.length; i++)
        _PrimerTile(
          name: primers[i].name,
          durationSeconds: primers[i].durationSeconds,
          done: i < session.exercises.length && session.exercises[i].sets.isNotEmpty,
          onToggle: () => ref.read(activeWorkoutProvider.notifier).togglePrimerExercise(i),
        ),
    ];
  }

  List<Widget> _buildExerciseTiles(
    WorkoutSession session,
    WorkoutSplitType splitType, {
    required List<ExerciseSlot> allSlots,
    required List<ExerciseSlot> showSlots,
    required Map<int, Exercise> swapMap,
  }) {
    final results = <Widget>[];

    for (final slot in showSlots) {
      final globalIndex = allSlots.indexOf(slot);
      final sessionIndex = _sessionIndexOf(globalIndex);
      final isSwappedOut = swapMap.containsKey(globalIndex);
      final swappedInEx = swapMap[globalIndex];
      final log = sessionIndex < session.exercises.length
          ? session.exercises[sessionIndex]
          : null;
      final completed = log != null && log.sets.length >= slot.exercise.sets;
      final hasLogs = log != null && log.sets.isNotEmpty;

      // ── Main (or swapped-out) exercise tile ──
      results.add(AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSwappedOut || completed
              ? AppColors.cardBg.withValues(alpha: 0.4)
              : AppColors.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.surfaceLight),
        ),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: completed
                    ? const Icon(Icons.check, color: AppColors.primary, size: 18)
                    : Text('${showSlots.indexOf(slot) + 1}',
                        style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 14)),
              ),
            ),
            const SizedBox(width: 12),
            _ExerciseThumb(gifUrl: slot.exercise.gifUrl),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    slot.exercise.name,
                    style: GoogleFonts.inter(
                      fontSize: 14, fontWeight: FontWeight.w600,
                      color: isSwappedOut ? AppColors.textMuted : AppColors.textPrimary,
                    ),
                  ),
                  if (hasLogs) Text(
                    '${log.sets.length}/${slot.exercise.sets} sets',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: (isSwappedOut ? AppColors.textMuted : AppColors.primary).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                isSwappedOut ? 'SWAPPED' : (completed ? 'DONE' : ''),
                style: TextStyle(
                  color: isSwappedOut ? AppColors.textMuted : AppColors.primary,
                  fontSize: 9, fontWeight: FontWeight.w700),
              ),
            ),
            if (isSwappedOut) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => _swapBack(globalIndex, slot.exercise.name),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('UNDO',
                    style: TextStyle(color: AppColors.warning, fontSize: 9, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () => _openExercise(globalIndex),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.chevron_right, color: AppColors.primary, size: 18),
              ),
            ),
          ],
        ),
      ));

      if (isSwappedOut && swappedInEx != null) {
        // ── Swapped-in alt exercise (ACTIVE, tappable) ──
        results.add(GestureDetector(
          onTap: globalIndex < session.exercises.length
              ? () => context.push('/exercise/$globalIndex')
              : null,
          child: Container(
            margin: const EdgeInsets.only(bottom: 8, left: 24),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                _ExerciseThumb(gifUrl: swappedInEx.gifUrl),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(swappedInEx.name,
                        style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                      Text('${swappedInEx.sets} × ${swappedInEx.reps} reps',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.primary, size: 18),
              ],
            ),
          ),
        ));
      } else {
        // ── Show available alt exercise (grayed, tappable to swap) ──
        final altEx = SeedData.getEasierAlternative(allSlots, slot.exercise.id);
        if (altEx != null) {
          results.add(GestureDetector(
            onTap: () => _showAlternativeSwap(globalIndex, slot, altEx),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8, left: 24),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.textMuted.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.textMuted.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.swap_horiz, color: AppColors.textMuted, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(altEx.name,
                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textMuted)),
                        Text('${altEx.sets} × ${altEx.reps} reps • Tap to swap',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 16),
                ],
              ),
            ),
          ));
        }
      }
    }

    return results;
  }

  /// Open the detail screen for an exercise; any active between-exercises
  /// rest timer is stopped (and recorded) first.
  void _openExercise(int globalIndex) {
    if (_resting) {
      _stopRest(record: true);
    }
    context.push('/exercise/$globalIndex');
  }

  /// Whether the exercise at [globalIndex] has all its sets logged.
  bool _isCompleted(int globalIndex, int targetSets, WorkoutSession session) {
    final sessionIndex = _sessionIndexOf(globalIndex);
    final log = sessionIndex < session.exercises.length
        ? session.exercises[sessionIndex]
        : null;
    return log != null && log.sets.length >= targetSets;
  }

  /// The session index that just transitioned from incomplete → complete.
  int? _findJustCompleted(WorkoutSession prev, WorkoutSession next) {
    final split = next.splitType;
    final day = next.dayIndex;
    final slots = SeedData.getMainSlots(split, day);
    for (final slot in slots) {
      final globalIndex = slots.indexOf(slot);
      final sessionIndex = _sessionIndexOf(globalIndex);
      final nextDone = _isCompleted(globalIndex, slot.exercise.sets, next);
      final prevDone = _isCompleted(globalIndex, slot.exercise.sets, prev);
      if (nextDone && !prevDone) return sessionIndex;
    }
    return null;
  }

  void _startRest() {
    if (_restTimer != null) return;
    setState(() {
      _resting = true;
      _restElapsed = 0;
    });
    _restTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() => _restElapsed++);
    });
  }

  void _stopRest({required bool record}) {
    _restTimer?.cancel();
    _restTimer = null;
    if (record && _restAfterSessionIndex != null && _restElapsed > 0) {
      ref.read(activeWorkoutProvider.notifier)
          .recordExerciseRest(_restAfterSessionIndex!, _restElapsed);
    }
    setState(() {
      _resting = false;
      _restElapsed = 0;
      _restAfterSessionIndex = null;
    });
  }

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Cancel Workout?',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          'Your progress will be lost.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep Going'),
          ),
          TextButton(
            onPressed: () {
              ref.read(activeWorkoutProvider.notifier).cancelWorkout();
              Navigator.pop(ctx);
              context.go('/home');
            },
            child: Text('Cancel', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  Future<void> _completeWorkout(
      BuildContext context, WidgetRef ref, WorkoutTimerState timerState) async {
    if (_resting) {
      _stopRest(record: true);
    }
    final minutes = timerState.elapsedMinutes;
    await ref.read(activeWorkoutProvider.notifier).completeWorkout(minutes);

    if (context.mounted) {
      _showCompletionDialog(context, minutes);
    }
  }

  void _showCompletionDialog(BuildContext context, int minutes) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            const Text('🎾', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              'Workout Complete!',
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$minutes minutes • Under 60-min cap ✓',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              'Queue updated for next session.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.go('/home');
                },
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Alternative Exercise Swap ───
  void _showAlternativeSwap(int globalIndex, ExerciseSlot slot, Exercise altEx) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Swap Exercise', style: TextStyle(color: AppColors.textPrimary)),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Replace "${slot.exercise.name}" with:', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(altEx.name, style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 15)),
              const SizedBox(height: 4),
              Text(altEx.description, style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
              Text('${altEx.sets} × ${altEx.reps} reps', style: TextStyle(color: AppColors.primary, fontSize: 12)),
            ]),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary))),
          ElevatedButton(
            onPressed: () {
              ref.read(activeSwapProvider.notifier).state = {
                ...ref.read(activeSwapProvider),
                globalIndex: altEx,
              };
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Swapped to ${altEx.name}'), backgroundColor: AppColors.primary),
              );
            },
            child: Text('Swap to ${altEx.name}'),
          ),
        ],
      ),
    );
  }

  // ─── Swap Back ───
  void _swapBack(int globalIndex, String originalName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Restore Exercise?', style: TextStyle(color: AppColors.textPrimary)),
        content: Text('Swap back to "$originalName"?', style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary))),
          ElevatedButton(
            onPressed: () {
              final updated = Map<int, Exercise>.from(ref.read(activeSwapProvider));
              updated.remove(globalIndex);
              ref.read(activeSwapProvider.notifier).state = updated;
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Restored $originalName'), backgroundColor: AppColors.primary),
              );
            },
            child: Text('Restore $originalName'),
          ),
        ],
      ),
    );
  }

  // ─── Low Energy Bulk Swap ───
  void _showLowEnergySwap(WorkoutSplitType splitType, int dayIdx) {
    final slots = SeedData.getMainSlots(splitType, dayIdx);
    final currentSwapMap = ref.read(activeSwapProvider);
    final swaps = <Map<String, dynamic>>[];
    for (final slot in slots) {
      final idx = slots.indexOf(slot);
      if (!currentSwapMap.containsKey(idx)) {
        final alt = SeedData.getEasierAlternative(slots, slot.exercise.id);
        if (alt != null) {
          swaps.add({'from': slot.exercise.name, 'to': alt.name, 'index': idx, 'alt': alt});
        }
      }
    }
    if (swaps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No easier alternatives found for remaining exercises'),
            backgroundColor: AppColors.warning),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Low Energy Mode', style: TextStyle(color: AppColors.textPrimary)),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Swap ALL remaining exercises to easier alternatives?',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
            const SizedBox(height: 12),
            ...swaps.map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(children: [
                const Icon(Icons.swap_horiz, color: AppColors.warning, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text('${s['from']} → ${s['to']}', style: TextStyle(color: AppColors.textPrimary, fontSize: 13))),
              ]),
            )),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary))),
          ElevatedButton(
            onPressed: () {
              final updated = Map<int, Exercise>.from(ref.read(activeSwapProvider));
              for (final s in swaps) {
                updated[s['index'] as int] = s['alt'] as Exercise;
              }
              ref.read(activeSwapProvider.notifier).state = updated;
              ref.read(workoutTimerProvider.notifier).triggerOverride('Low Energy');
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${swaps.length} exercises swapped to easier versions'),
                    backgroundColor: AppColors.warning),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
            child: Text('Swap All (${swaps.length})'),
          ),
        ],
      ),
    );
  }

  // ─── Add Custom Exercise ───
  void _showAddCustomExercise() {
    final nameCtrl = TextEditingController();
    final setsCtrl = TextEditingController(text: '3');
    final repsCtrl = TextEditingController(text: '10');
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setDialogState) {
          return AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text('Add Custom Exercise', style: TextStyle(color: AppColors.textPrimary)),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              // ─── Browse exercise library ───
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _openRepertoire();
                  },
                  icon: const Icon(Icons.grid_view, size: 18),
                  label: const Text('Browse Exercise Library',
                      style: TextStyle(fontSize: 14)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.secondary,
                    side: BorderSide(color: AppColors.secondary.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Divider(color: AppColors.surfaceLight),
              const SizedBox(height: 6),
              TextField(
                controller: nameCtrl,
                onChanged: (_) => setDialogState(() {}),
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Exercise Name',
                  hintText: 'e.g. Cable Woodchop',
                  hintStyle: TextStyle(color: AppColors.textMuted),
                  filled: true, fillColor: AppColors.cardBg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: TextField(
                  controller: setsCtrl, keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(labelText: 'Sets', filled: true, fillColor: AppColors.cardBg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)))),
                const SizedBox(width: 12),
                Expanded(child: TextField(
                  controller: repsCtrl, keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(labelText: 'Reps', filled: true, fillColor: AppColors.cardBg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)))),
              ]),
              const SizedBox(height: 12),
              Text('Will be added at the bottom of the finishers block.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
            ]),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary))),
              ElevatedButton(
                onPressed: nameCtrl.text.trim().isEmpty
                    ? null
                    : () async {
                        final nav = Navigator.of(ctx);
                        final messenger = ScaffoldMessenger.of(context);
                        final exerciseName = nameCtrl.text.trim();
                        final sets = int.tryParse(setsCtrl.text) ?? 3;
                        final reps = int.tryParse(repsCtrl.text) ?? 10;
                        final exercise = Exercise(
                          id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                          name: exerciseName,
                          category: ExerciseCategory.isolation,
                          muscleGroup: MuscleGroup.fullBody,
                          sets: sets,
                          reps: reps,
                          description: 'Custom exercise',
                          isUserAdded: true,
                        );
                        await Database.saveCustomExercise(exercise);
                        if (mounted) {
                          setState(() {
                            _customExercises.add(CustomSwap(
                              exerciseName: exerciseName,
                              replacedExerciseId: '',
                              exercise: exercise,
                            ));
                          });
                          nav.pop();
                          messenger.showSnackBar(
                            SnackBar(content: Text('Added "$exerciseName"'), backgroundColor: AppColors.primary),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                child: const Text('Add Exercise'),
              ),
            ],
          );
        });
      },
    );
  }

  /// Open the exercise library; convert any selection into custom exercises
  /// added to this session's custom list.
  Future<void> _openRepertoire() async {
    final all = await ExerciseRepertoire.load();
    final selectedIds = await context.push<List<String>>('/repertoire');
    if (!mounted || selectedIds == null || selectedIds.isEmpty) return;

    final picked = all.where((e) => selectedIds.contains(e.id)).toList();
    if (picked.isEmpty) return;

    final messenger = ScaffoldMessenger.of(context);
    for (final r in picked) {
      final exercise = ExerciseRepertoire.toAppExercise(r);
      await Database.saveCustomExercise(exercise);
      if (!mounted) return;
      setState(() {
        _customExercises.add(CustomSwap(
          exerciseName: exercise.name,
          replacedExerciseId: '',
          exercise: exercise,
        ));
      });
    }
    messenger.showSnackBar(
      SnackBar(
        content: Text('Added ${picked.length} exercise${picked.length > 1 ? 's' : ''} to workout'),
        backgroundColor: AppColors.secondary,
      ),
    );
  }

  void _renameCustomExercise(CustomSwap custom) {
    final ctrl = TextEditingController(text: custom.exerciseName);
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setDialogState) {
          return AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text('Rename Exercise', style: TextStyle(color: AppColors.textPrimary)),
            content: TextField(
              controller: ctrl,
              onChanged: (_) => setDialogState(() {}),
              autofocus: true,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'New name',
                hintStyle: TextStyle(color: AppColors.textMuted),
                filled: true, fillColor: AppColors.cardBg,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary))),
              ElevatedButton(
                onPressed: ctrl.text.trim().isEmpty ? null : () async {
                  final newName = ctrl.text.trim();
                  final updated = custom.exercise.copyWith(name: newName);
                  setState(() {
                    custom.exerciseName = newName;
                    custom.exercise = updated;
                  });
                  await Database.saveCustomExercise(updated);
                  if (mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Renamed to "$newName"'), backgroundColor: AppColors.primary),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                child: const Text('Rename'),
              ),
            ],
          );
        });
      },
    );
  }

  void _showExtensionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          const Icon(Icons.access_time, color: AppColors.warning, size: 24),
          const SizedBox(width: 10),
          Text('Time Check', style: TextStyle(color: AppColors.textPrimary)),
        ]),
        content: Text('You have 10 minutes remaining. '
            'Would you like to extend by 10 minutes for a total of 70?',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(workoutTimerProvider.notifier).extendWorkout(10);
            },
            child: Text('Extend 10 min', style: TextStyle(color: AppColors.primary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.surfaceLight),
            child: Text('Keep 60 min', style: TextStyle(color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
//  60-Minute Countdown Banner
// ──────────────────────────────────────────────────────────────

class _CountdownBanner extends StatelessWidget {
  final WorkoutTimerState timerState;
  const _CountdownBanner({required this.timerState});

  @override
  Widget build(BuildContext context) {
    final mins = timerState.remainingMinutes;
    final secs = timerState.remainingSecs;
    final pct = timerState.elapsedSeconds / 3600.0;
    final isFinal10 = timerState.isFinal10;
    final isHardStop = timerState.isHardStopTriggered;

    Color barColor;
    if (isHardStop) {
      barColor = AppColors.error;
    } else if (isFinal10) {
      barColor = AppColors.warning;
    } else {
      barColor = AppColors.primary;
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHardStop
              ? AppColors.error.withValues(alpha: 0.4)
              : isFinal10
                  ? AppColors.warning.withValues(alpha: 0.3)
                  : AppColors.surfaceLight,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.timer_outlined,
                color: barColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}',
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: barColor,
                ),
              ),
              const Spacer(),
              Text(
                'of 60:00',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: barColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  timerState.currentBlock.label,
                  style: TextStyle(
                    color: barColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct.clamp(0.0, 1.0),
              backgroundColor: AppColors.surfaceLight,
              valueColor: AlwaysStoppedAnimation(barColor),
              minHeight: 8,
            ),
          ),
          if (isHardStop) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber, color: AppColors.error, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
child: Text(
                    'FINAL 10 MINUTES — Hard stop active. '
                    'Uncompleted exercises will be skipped automatically.',
                    style: TextStyle(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
//  Primer Tile (logged as an exercise; own countdown + pause/restart)
// ──────────────────────────────────────────────────────────────

class _PrimerTile extends StatefulWidget {
  final String name;
  final int durationSeconds;
  final bool done;
  final VoidCallback onToggle;

  const _PrimerTile({
    required this.name,
    required this.durationSeconds,
    required this.done,
    required this.onToggle,
  });

  @override
  State<_PrimerTile> createState() => _PrimerTileState();
}

class _PrimerTileState extends State<_PrimerTile> {
  Timer? _countdown;
  late int _remaining;
  bool _running = false;

  @override
  void initState() {
    super.initState();
    _remaining = widget.durationSeconds;
  }

  @override
  void dispose() {
    _countdown?.cancel();
    super.dispose();
  }

  void _toggleRun() {
    setState(() {
      _running = !_running;
      if (_running) {
        _countdown?.cancel();
        _countdown = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
      } else {
        _countdown?.cancel();
      }
    });
  }

  void _restart() {
    _countdown?.cancel();
    setState(() {
      _remaining = widget.durationSeconds;
      _running = false;
    });
  }

  void _tick() {
    if (_remaining <= 1) {
      _countdown?.cancel();
      setState(() {
        _remaining = 0;
        _running = false;
      });
      if (!widget.done) widget.onToggle();
      return;
    }
    setState(() => _remaining--);
  }

  String get _timeLabel {
    final m = _remaining ~/ 60;
    final s = _remaining % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final completed = widget.done;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: completed ? AppColors.cardBg.withValues(alpha: 0.4) : AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: completed
              ? AppColors.secondary.withValues(alpha: 0.4)
              : AppColors.surfaceLight,
          width: completed ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          // Play / Pause (start or pause the per-exercise timer)
          GestureDetector(
            onTap: completed ? null : _toggleRun,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (completed ? AppColors.secondary : AppColors.primary).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                completed ? Icons.check : (_running ? Icons.pause : Icons.play_arrow),
                color: completed ? AppColors.secondary : AppColors.primary,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.name,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: completed ? AppColors.textMuted : AppColors.textPrimary,
                  ),
                ),
                Text(
                  _timeLabel,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          // Restart (reset the per-exercise timer)
          if (!completed)
            GestureDetector(
              onTap: _restart,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.refresh, color: AppColors.textSecondary, size: 16),
              ),
            ),
          const SizedBox(width: 4),
          // Manual done toggle
          GestureDetector(
            onTap: widget.onToggle,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: (completed ? AppColors.secondary : AppColors.primary).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                completed ? 'DONE' : 'MARK DONE',
                style: TextStyle(
                  color: completed ? AppColors.secondary : AppColors.primary,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
//  Block Header
// ──────────────────────────────────────────────────────────────

class _BlockHeader extends StatelessWidget {
  final String label, subtitle;
  final Color color;
  final IconData? icon;

  const _BlockHeader({
    required this.label,
    required this.subtitle,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
//  Exercise GIF Thumbnail (dataset GIF, fallback icon)
// ──────────────────────────────────────────────────────────────

class _ExerciseThumb extends StatelessWidget {
  final String? gifUrl;

  const _ExerciseThumb({required this.gifUrl});

  @override
  Widget build(BuildContext context) {
    final url = gifUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 48,
        height: 48,
        child: url == null || url.isEmpty
            ? _thumbFallback()
            : Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _thumbFallback(),
                loadingBuilder: (ctx, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    color: AppColors.surfaceLight,
                    child: const Center(
                      child: SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.textMuted),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _thumbFallback() {
    return Container(
      color: AppColors.surfaceLight,
      child: const Icon(Icons.fitness_center,
          color: AppColors.textMuted, size: 20),
    );
  }
}

// ──────────────────────────────────────────────────────────────
//  Between-Exercises Rest Timer Banner (elapsed seconds)
// ──────────────────────────────────────────────────────────────

class _RestBanner extends StatelessWidget {
  final int elapsed;
  final VoidCallback onSkip;

  const _RestBanner({required this.elapsed, required this.onSkip});

  String get _timeLabel {
    final m = elapsed ~/ 60;
    final s = elapsed % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.timer, color: AppColors.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rest between exercises',
                  style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                Text(
                  _timeLabel,
                  style: GoogleFonts.outfit(
                    color: AppColors.primary,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onSkip,
            child: const Text('Skip', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
//  Manual Override Buttons
// ──────────────────────────────────────────────────────────────

class _ManualOverrideButtons extends StatelessWidget {
  final VoidCallback onLowEnergy;

  const _ManualOverrideButtons({
    required this.onLowEnergy,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Need an adjustment?',
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onLowEnergy,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.warning.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.battery_alert_outlined, color: AppColors.warning, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Low Energy', style: TextStyle(color: AppColors.warning, fontWeight: FontWeight.w700, fontSize: 13)),
                      Text('Swap ALL exercises for easier alternatives', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.warning, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
