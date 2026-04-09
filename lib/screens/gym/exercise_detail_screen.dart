import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../data/seed_data.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

class ExerciseDetailScreen extends ConsumerStatefulWidget {
  final int exerciseIndex;
  const ExerciseDetailScreen({super.key, required this.exerciseIndex});
  @override
  ConsumerState<ExerciseDetailScreen> createState() => _ExerciseDetailState();
}

class _ExerciseDetailState extends ConsumerState<ExerciseDetailScreen> {
  final _weightCtrl = TextEditingController();
  final _repsCtrl = TextEditingController();
  Timer? _restTimer;
  int _restSec = 0;
  bool _resting = false;
  YoutubePlayerController? _ytController;

  @override
  void initState() {
    super.initState();
    final session = ref.read(activeWorkoutProvider);
    if (session == null) return;
    final exId = SeedData.getWorkoutExercises(session.actualType)[widget.exerciseIndex].id;
    final prog = ref.read(userProgressProvider)[exId];
    if (prog != null && prog.currentWeight > 0) _weightCtrl.text = prog.currentWeight.toString();

    final ytUrl = SeedData.getWorkoutExercises(session.actualType)[widget.exerciseIndex].youtubeUrl;
    if (ytUrl != null && ytUrl.isNotEmpty) {
      _ytController = YoutubePlayerController.fromVideoId(
        videoId: ytUrl,
        autoPlay: false,
        params: const YoutubePlayerParams(
          showControls: true, 
          showFullscreenButton: true,
          playsInline: true,
          strictRelatedVideos: true,
        ),
      );
    }
  }

  @override
  void dispose() { _restTimer?.cancel(); _weightCtrl.dispose(); _repsCtrl.dispose(); _ytController?.close(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(activeWorkoutProvider);
    if (session == null) return Scaffold(backgroundColor: AppColors.background, body: Center(child: Text('No workout', style: TextStyle(color: AppColors.textPrimary))));

    final exercises = SeedData.getWorkoutExercises(session.actualType);
    final ex = exercises[widget.exerciseIndex];
    final log = session.exercises[widget.exerciseIndex];
    final done = log.sets.length >= ex.sets;
    final isA = session.actualType == WorkoutType.a;
    final color = isA ? AppColors.workoutA : AppColors.workoutB;
    if (_repsCtrl.text.isEmpty && ex.reps > 0) _repsCtrl.text = ex.reps.toString();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(ex.name, style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new), onPressed: () => Navigator.pop(context))),
      body: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Info card
        Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(
          gradient: isA ? AppColors.workoutAGradient : AppColors.workoutBGradient, borderRadius: BorderRadius.circular(20)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Icon(ex.isDurationBased ? Icons.timer : Icons.fitness_center, color: Colors.white, size: 24), const SizedBox(width: 10),
              Text(ex.isDurationBased ? '${ex.sets} × ${ex.durationSeconds}s' : '${ex.sets} × ${ex.reps} reps',
                style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white))]),
            const SizedBox(height: 10),
            Text(ex.description, style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 14, height: 1.4)),
            const SizedBox(height: 8),
            Text(ex.muscleGroup.name.toUpperCase(), style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.6), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
          ])),
        
        if (_ytController != null) ...[
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(border: Border.all(color: AppColors.surfaceLight), borderRadius: BorderRadius.circular(16)),
            child: YoutubePlayer(
              controller: _ytController!,
              aspectRatio: 16 / 9,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton.icon(
                onPressed: () => _ytController?.playVideo(),
                icon: const Icon(Icons.play_arrow, color: AppColors.primary),
                label: const Text('Play', style: TextStyle(color: AppColors.primary)),
              ),
              const SizedBox(width: 16),
              TextButton.icon(
                onPressed: () => _ytController?.pauseVideo(),
                icon: const Icon(Icons.pause, color: AppColors.secondary),
                label: const Text('Pause', style: TextStyle(color: AppColors.secondary)),
              ),
            ],
          ),
        ],

        const SizedBox(height: 24),

        // Sets completed
        Text('Sets Completed', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        if (log.sets.isEmpty) Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.surfaceLight)),
          child: Center(child: Text('No sets logged yet.', style: TextStyle(color: AppColors.textMuted, fontSize: 14)))),
        ...log.sets.map((s) => Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(color: (s.isDropSet ? AppColors.warning : AppColors.primary).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12),
            border: Border.all(color: (s.isDropSet ? AppColors.warning : AppColors.primary).withValues(alpha: 0.2))),
          child: Row(children: [
            Container(width: 28, height: 28, decoration: BoxDecoration(color: (s.isDropSet ? AppColors.warning : AppColors.primary).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
              child: Center(child: Text('${s.setNumber}', style: TextStyle(color: s.isDropSet ? AppColors.warning : AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13)))),
            const SizedBox(width: 14),
            Text('${s.weight} lbs', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(width: 8), Text('×', style: TextStyle(color: AppColors.textMuted)), const SizedBox(width: 8),
            Text('${s.repsCompleted} reps', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 15)),
            const Spacer(),
            if (s.isDropSet) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
              child: Text('DROP', style: TextStyle(color: AppColors.warning, fontSize: 10, fontWeight: FontWeight.w700))),
          ]))),

        // Rest timer
        if (_resting) ...[const SizedBox(height: 20), Center(child: Column(children: [
          Text('REST', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 2)),
          const SizedBox(height: 8), Text('${_restSec}s', style: GoogleFonts.outfit(color: AppColors.secondary, fontSize: 48, fontWeight: FontWeight.w800)),
          TextButton(onPressed: _skipRest, child: Text('Skip', style: TextStyle(color: AppColors.textSecondary)))]))],

        // Log set input
        if (!done && !_resting) ...[const SizedBox(height: 24),
          Text('Set ${log.sets.length + 1} of ${ex.sets}', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: TextField(controller: _weightCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 18),
              decoration: InputDecoration(labelText: 'Weight (lbs)', labelStyle: TextStyle(color: AppColors.textMuted), filled: true, fillColor: AppColors.cardBg,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.surfaceLight)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.surfaceLight)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: color))))),
            const SizedBox(width: 12),
            Expanded(child: TextField(controller: _repsCtrl, keyboardType: TextInputType.number,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 18),
              decoration: InputDecoration(labelText: 'Reps', labelStyle: TextStyle(color: AppColors.textMuted), filled: true, fillColor: AppColors.cardBg,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.surfaceLight)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.surfaceLight)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: color)))))]),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: ElevatedButton(onPressed: () => _logSet(false), child: const Text('Log Set ✓'))),
            if (log.sets.length >= 2) ...[const SizedBox(width: 10),
              Expanded(child: ElevatedButton(onPressed: _showDropSet, style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning, foregroundColor: AppColors.background),
                child: const Text('Gap? Drop Set')))]])],

        // Difficulty rating
        if (done && log.difficulty == null) ...[const SizedBox(height: 24),
          Text('How did it feel?', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          Row(children: Difficulty.values.map((d) {
            final c = {Difficulty.easy: AppColors.primary, Difficulty.moderate: AppColors.secondary, Difficulty.hard: AppColors.error};
            final l = {Difficulty.easy: '😎 Easy', Difficulty.moderate: '💪 Mod', Difficulty.hard: '🔥 Hard'};
            return Expanded(child: GestureDetector(onTap: () => ref.read(activeWorkoutProvider.notifier).rateExercise(widget.exerciseIndex, d),
              child: Container(margin: EdgeInsets.only(right: d != Difficulty.hard ? 8 : 0), padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(color: c[d]!.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12), border: Border.all(color: c[d]!.withValues(alpha: 0.3))),
                child: Center(child: Text(l[d]!, style: TextStyle(color: c[d], fontWeight: FontWeight.w600, fontSize: 13))))));
          }).toList())],

        // Complete
        if (done && log.difficulty != null) ...[const SizedBox(height: 24),
          Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.primary.withValues(alpha: 0.3))),
            child: Column(children: [const Text('✅', style: TextStyle(fontSize: 32)), const SizedBox(height: 8),
              Text('Exercise Complete!', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.primary)),
              Text('Rated: ${log.difficulty!.name.toUpperCase()}', style: TextStyle(color: AppColors.textSecondary, fontSize: 13))])),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back), label: const Text('Back to Exercises'),
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary, side: const BorderSide(color: AppColors.primary), padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)))))],
      ])),
    );
  }

  void _logSet(bool isDrop) {
    final w = double.tryParse(_weightCtrl.text) ?? 0;
    final r = int.tryParse(_repsCtrl.text) ?? 0;
    if (w <= 0 && r <= 0) return;
    final session = ref.read(activeWorkoutProvider);
    if (session == null) return;
    ref.read(activeWorkoutProvider.notifier).logSet(widget.exerciseIndex,
      SetLog(setNumber: session.exercises[widget.exerciseIndex].sets.length + 1, weight: w, repsCompleted: r, isDropSet: isDrop));
    final rest = ref.read(restTimerDurationProvider);
    _startRest(rest);
  }

  void _showDropSet() {
    final cw = double.tryParse(_weightCtrl.text) ?? 0;
    final dw = (cw * 0.8).roundToDouble();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.surface, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(children: [const Icon(Icons.trending_down, color: AppColors.warning), const SizedBox(width: 8), Text('Drop Set', style: TextStyle(color: AppColors.textPrimary))]),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Reduce weight by 20% and finish reps.', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
        const SizedBox(height: 16),
        Text('Drop to: $dw lbs', style: GoogleFonts.outfit(color: AppColors.warning, fontSize: 20, fontWeight: FontWeight.w700))]),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(onPressed: () { Navigator.pop(ctx); _weightCtrl.text = dw.toString(); _logSet(true); },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning), child: const Text('Drop & Log'))]));
  }

  void _startRest(int sec) {
    setState(() { _resting = true; _restSec = sec; });
    _restTimer?.cancel();
    _restTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() { _restSec--; if (_restSec <= 0) { _resting = false; t.cancel(); } });
    });
  }

  void _skipRest() { _restTimer?.cancel(); setState(() { _resting = false; _restSec = 0; }); }
}
