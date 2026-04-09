import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../data/seed_data.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

class WorkoutScreen extends ConsumerStatefulWidget {
  const WorkoutScreen({super.key});

  @override
  ConsumerState<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends ConsumerState<WorkoutScreen> {
  final _stopwatch = Stopwatch();
  bool _primerDone = false;

  @override
  void initState() {
    super.initState();
    _stopwatch.start();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(activeWorkoutProvider);
    if (session == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Text('No active workout', style: TextStyle(color: AppColors.textPrimary)),
        ),
      );
    }

    final isA = session.actualType == WorkoutType.a;
    final exercises = SeedData.getWorkoutExercises(session.actualType);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          session.actualType.label,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _showCancelDialog(context),
        ),
        actions: [
          if (session.wasOverridden)
            Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.swap_horiz, size: 14, color: AppColors.warning),
                  const SizedBox(width: 4),
                  Text(
                    'Overridden',
                    style: TextStyle(color: AppColors.warning, fontSize: 12),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Workout type banner
          Container(
            margin: const EdgeInsets.fromLTRB(20, 8, 20, 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: isA ? AppColors.workoutAGradient : AppColors.workoutBGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  isA ? Icons.fitness_center : Icons.sports_martial_arts,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  session.actualType.subtitle,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Metabolic Primer section
          if (!_primerDone)
            _PrimerSection(
              onComplete: () => setState(() => _primerDone = true),
            ),

          if (_primerDone) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Text(
                    'Exercises',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${session.exercises.where((e) => e.sets.isNotEmpty).length}/${exercises.length} done',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],

          // Exercise list
          if (_primerDone)
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                itemCount: exercises.length,
                itemBuilder: (context, index) {
                  final exercise = exercises[index];
                  final log = session.exercises[index];
                  final completedSets = log.sets.length;
                  final totalSets = exercise.sets;
                  final isDone = completedSets >= totalSets;

                  return GestureDetector(
                    onTap: () => context.push('/exercise/$index'),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDone
                            ? AppColors.primary.withValues(alpha: 0.08)
                            : AppColors.cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDone
                              ? AppColors.primary.withValues(alpha: 0.3)
                              : AppColors.surfaceLight,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Number badge
                          Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color: isDone
                                  ? AppColors.primary.withValues(alpha: 0.2)
                                  : (isA ? AppColors.workoutA : AppColors.workoutB)
                                      .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: isDone
                                  ? const Icon(Icons.check, color: AppColors.primary, size: 18)
                                  : Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                        color: isA ? AppColors.workoutA : AppColors.workoutB,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  exercise.name,
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: isDone
                                        ? AppColors.textSecondary
                                        : AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  exercise.isDurationBased
                                      ? '${exercise.sets} × ${exercise.durationSeconds}s'
                                      : '${exercise.sets} × ${exercise.reps} reps',
                                  style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Sets completed indicator
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(totalSets, (i) {
                              return Container(
                                width: 8, height: 8,
                                margin: const EdgeInsets.only(left: 4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: i < completedSets
                                      ? AppColors.primary
                                      : AppColors.surfaceLight,
                                ),
                              );
                            }),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.chevron_right,
                            color: AppColors.textMuted,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

          // Complete Workout button
          if (_primerDone)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _completeWorkout(context, ref),
                  child: Text('Complete ${session.actualType.label}'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Cancel Workout?', style: TextStyle(color: AppColors.textPrimary)),
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

  Future<void> _completeWorkout(BuildContext context, WidgetRef ref) async {
    _stopwatch.stop();
    final minutes = _stopwatch.elapsed.inMinutes;
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
            const Text('🎉', style: TextStyle(fontSize: 48)),
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
              '$minutes minutes',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
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
}

// ──────────────────────────────────────────────────────────────
//  Metabolic Primer Section
// ──────────────────────────────────────────────────────────────

class _PrimerSection extends StatelessWidget {
  final VoidCallback onComplete;

  const _PrimerSection({required this.onComplete});

  @override
  Widget build(BuildContext context) {
    final primers = SeedData.primerExercises;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            children: [
              Text(
                'Metabolic Primer',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '20 min',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
        ...primers.map((exercise) => _PrimerItem(exercise: exercise)),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onComplete,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Primer Done — Show Exercises'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.secondary,
                side: const BorderSide(color: AppColors.secondary),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PrimerItem extends StatefulWidget {
  final Exercise exercise;
  const _PrimerItem({required this.exercise});
  @override
  State<_PrimerItem> createState() => _PrimerItemState();
}

class _PrimerItemState extends State<_PrimerItem> {
  bool _showVideo = false;
  YoutubePlayerController? _controller;

  void _toggleVideo() {
    if (widget.exercise.youtubeUrl == null) return;
    setState(() {
      _showVideo = !_showVideo;
      if (_showVideo) {
        _controller = YoutubePlayerController.fromVideoId(
          videoId: widget.exercise.youtubeUrl!,
          autoPlay: false,
          params: const YoutubePlayerParams(showControls: true, playsInline: true),
        );
      } else {
        _controller?.close();
        _controller = null;
      }
    });
  }

  @override
  void dispose() {
    _controller?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.directions_run, color: AppColors.secondary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.exercise.name,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${widget.exercise.durationSeconds ~/ 60} min',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (widget.exercise.youtubeUrl != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(_showVideo ? Icons.keyboard_arrow_up : Icons.play_circle_fill, color: AppColors.secondary, size: 28),
                  onPressed: _toggleVideo,
                )
              ],
            ],
          ),
          if (_showVideo && _controller != null) ...[
            const SizedBox(height: 16),
            Center(
              child: SizedBox(
                width: 320,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: YoutubePlayer(
                    controller: _controller!,
                    aspectRatio: 16 / 9,
                  ),
                ),
              ),
            ),
          ]
        ],
      ),
    );
  }
}
