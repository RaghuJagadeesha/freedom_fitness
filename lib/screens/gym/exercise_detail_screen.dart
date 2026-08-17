import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../data/seed_data.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../../widgets/voice_indicator.dart';
import '../../services/voice_service.dart';

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
  DateTime? _restStart;
  YoutubePlayerController? _ytController;

  Timer? _ticker;
  bool _isVoiceListening = false;
  String? _voiceRecognizedText;
  String? _voiceFeedbackText;

  @override
  void initState() {
    super.initState();
    final session = ref.read(activeWorkoutProvider);
    if (session == null) return;
    final ex = _exerciseFor(session);
    ref.read(activeWorkoutProvider.notifier).startExercise(ex.id, ex.name);

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        ref.read(activeWorkoutProvider.notifier).updateExerciseElapsed(ex.id);
        setState(() {});
      }
    });

    final slots = SeedData.getMainSlots(session.splitType, session.dayIndex);
    if (widget.exerciseIndex < slots.length) {
      final exId = slots[widget.exerciseIndex].exercise.id;
      final prog = ref.read(userProgressProvider)[exId];
      if (prog != null && prog.currentWeight > 0) _weightCtrl.text = prog.currentWeight.toString();

      final ytUrl = slots[widget.exerciseIndex].exercise.youtubeUrl;
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
    VoiceService.initialize();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _restTimer?.cancel();
    final session = ref.read(activeWorkoutProvider);
    if (session != null) {
      final ex = _exerciseFor(session);
      if (_resting && _restStart != null) {
        _recordCurrentRest(ex.id);
      }
      Future.microtask(() {
        ref.read(activeWorkoutProvider.notifier).updateExerciseElapsed(ex.id);
      });
    }
    _weightCtrl.dispose();
    _repsCtrl.dispose();
    _ytController?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(activeWorkoutProvider);
    if (session == null) return Scaffold(backgroundColor: AppColors.background, body: Center(child: Text('No workout', style: TextStyle(color: AppColors.textPrimary))));

    final slots = SeedData.getMainSlots(session.splitType, session.dayIndex);
    final swapMap = ref.watch(activeSwapProvider);
    final swappedEx = swapMap[widget.exerciseIndex];
    final ex = swappedEx ?? slots[widget.exerciseIndex].exercise;
    final log = session.getLogFor(ex.id) ?? ExerciseLog(exerciseId: ex.id, exerciseName: ex.name);
    final done = log.sets.length >= ex.sets;
    final dayColors = [AppColors.workoutA, AppColors.workoutB, AppColors.primary, AppColors.floater, AppColors.accent];
    final color = dayColors[session.dayIndex % dayColors.length];
    if (_repsCtrl.text.isEmpty && ex.reps > 0) _repsCtrl.text = ex.reps.toString();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(ex.name, style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new), onPressed: () => Navigator.pop(context))),
      floatingActionButton: VoiceIndicator(
        isListening: _isVoiceListening,
        recognizedText: _voiceRecognizedText,
        feedbackText: _voiceFeedbackText,
        onToggle: _toggleVoice,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: SingleChildScrollView(padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 100), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Info card
        Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(
          gradient: AppColors.workoutBGradient, borderRadius: BorderRadius.circular(20)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Icon(ex.isDurationBased ? Icons.timer : Icons.fitness_center, color: Colors.white, size: 24), const SizedBox(width: 10),
              Text(ex.isDurationBased ? '${ex.sets} × ${ex.durationSeconds}s' : '${ex.sets} × ${ex.reps} reps',
                style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white))]),
            const SizedBox(height: 10),
            Text(ex.description, style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 14, height: 1.4)),
            const SizedBox(height: 8),
            Text(ex.muscleGroup.name.toUpperCase(), style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.6), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
          ])),
        
        if (ex.gifUrl != null && ex.gifUrl!.isNotEmpty) ...[
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.surfaceLight),
              borderRadius: BorderRadius.circular(16),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  ex.gifUrl!,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Center(
                      child: Icon(Icons.fitness_center,
                          color: AppColors.textMuted, size: 40)),
                  loadingBuilder: (ctx, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      color: AppColors.surfaceLight,
                      child: const Center(
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.textMuted),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
        
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
        ...log.sets.asMap().entries.map((entry) {
          final s = entry.value;
          final setIndex = entry.key;
          return GestureDetector(
            onTap: () => _showEditSetDialog(setIndex, s),
            child: Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                const Icon(Icons.edit, color: AppColors.textMuted, size: 14),
              ])));
        }),

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
            return Expanded(child: GestureDetector(onTap: () => ref.read(activeWorkoutProvider.notifier).rateExercise(ex.id, ex.name, d),
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

  void _handleVoiceCommand(VoiceCommandResult result) {
    setState(() => _voiceRecognizedText = result.rawText);

    switch (result.command) {
      case VoiceCommand.setDone:
        if (_repsCtrl.text.isEmpty) _repsCtrl.text = "10";
        if (_weightCtrl.text.isEmpty) _weightCtrl.text = "0";
        _logSet(false);
        setState(() => _voiceFeedbackText = "Set logged");
        VoiceService.speak("Set logged. Starting rest time.");
        break;
      case VoiceCommand.startRest:
        if (!_resting) {
          final rest = ref.read(restTimerDurationProvider);
          _startRest(rest);
          setState(() => _voiceFeedbackText = "Rest started");
          VoiceService.speak("Rest started.");
        }
        break;
      case VoiceCommand.addTime:
        if (_resting) {
          setState(() {
            _restSec += result.extraSeconds ?? 30;
            _voiceFeedbackText = "Added request time";
          });
          VoiceService.speak("Added time.");
        }
        break;
      case VoiceCommand.nextExercise:
      case VoiceCommand.previousExercise:
        VoiceService.speak("Navigating exercise.");
        Navigator.pop(context);
        break;
      case VoiceCommand.unknown:
        setState(() => _voiceFeedbackText = "Unknown command");
        break;
    }
  }

  void _showEditSetDialog(int setIndex, SetLog set) {
    final wCtrl = TextEditingController(text: set.weight.toString());
    final rCtrl = TextEditingController(text: set.repsCompleted.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Edit Set ${set.setNumber}', style: TextStyle(color: AppColors.textPrimary)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: wCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(labelText: 'Weight (lbs)', labelStyle: TextStyle(color: AppColors.textMuted),
              filled: true, fillColor: AppColors.cardBg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
          const SizedBox(height: 12),
          TextField(controller: rCtrl, keyboardType: TextInputType.number,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(labelText: 'Reps', labelStyle: TextStyle(color: AppColors.textMuted),
              filled: true, fillColor: AppColors.cardBg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary))),
          ElevatedButton(onPressed: () {
            final w = double.tryParse(wCtrl.text) ?? set.weight;
            final r = int.tryParse(rCtrl.text) ?? set.repsCompleted;
            final session = ref.read(activeWorkoutProvider);
            if (session != null) {
              final ex = _exerciseFor(session);
              ref.read(activeWorkoutProvider.notifier).editSet(ex.id, setIndex, w, r);
            }
            Navigator.pop(ctx);
          }, child: const Text('Save')),
        ],
      ),
    );
  }

  void _toggleVoice() async {
    await VoiceService.toggleListening(_handleVoiceCommand);
    setState(() {
      _isVoiceListening = VoiceService.isListening;
      _voiceFeedbackText = null;
      _voiceRecognizedText = null;
    });
  }

  void _logSet(bool isDrop) {
    final session = ref.read(activeWorkoutProvider);
    if (session == null) return;
    final ex = _exerciseFor(session);
    final currentLog = session.getLogFor(ex.id);
    final currentSetCount = currentLog?.sets.length ?? 0;
    final w = double.tryParse(_weightCtrl.text) ?? 0;
    var r = int.tryParse(_repsCtrl.text) ?? 0;
    // Never silently fail to log: default to the exercise's targets.
    if (r <= 0) r = ex.reps > 0 ? ex.reps : 1;
    if (_weightCtrl.text.isEmpty) _weightCtrl.text = w.toString();
    // Close out rest taken before this set was logged (per-set rest).
    _recordCurrentRest(ex.id);
    ref.read(activeWorkoutProvider.notifier).logSet(
      ex.id, ex.name,
      SetLog(setNumber: currentSetCount + 1, weight: w, repsCompleted: r, isDropSet: isDrop),
    );
    final rest = ref.read(restTimerDurationProvider);
    _startRest(rest);
  }

  /// Persist the elapsed rest for [exerciseId]'s most recent set (rest between
  /// sets), then reset the clock.
  void _recordCurrentRest(String exerciseId) {
    final elapsed = _restStartElapsed;
    if (elapsed <= 0) { _restStart = DateTime.now(); return; }
    ref.read(activeWorkoutProvider.notifier).recordSetRest(exerciseId, elapsed);
    _restStart = DateTime.now();
  }

  /// Resolve the exercise being logged from its slot/swap map — order in the
  /// session list is irrelevant to which details a completed set should carry.
  Exercise _exerciseFor(WorkoutSession session) {
    final swappedEx = ref.read(activeSwapProvider)[widget.exerciseIndex];
    if (swappedEx != null) return swappedEx;
    final slots = SeedData.getMainSlots(session.splitType, session.dayIndex);
    if (widget.exerciseIndex < slots.length) return slots[widget.exerciseIndex].exercise;
    return const Exercise(
      id: '', name: '', category: ExerciseCategory.isolation,
      muscleGroup: MuscleGroup.fullBody, sets: 1,
      description: '', isUserAdded: true,
    );
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

  /// Seconds elapsed since the last rest started (close-out for per-set rest).
  int get _restStartElapsed {
    final start = _restStart;
    if (start == null) return 0;
    return DateTime.now().difference(start).inSeconds;
  }

  void _startRest(int sec) {
    setState(() {
      _resting = true;
      _restSec = sec;
      _restStart = DateTime.now();
    });
    _restTimer?.cancel();
    _restTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() {
        _restSec--;
        if (_restSec <= 0) {
          _resting = false;
          final session = ref.read(activeWorkoutProvider);
          if (session != null) {
            final ex = _exerciseFor(session);
            _recordCurrentRest(ex.id);
          }
          t.cancel();
        }
      });
    });
  }

  void _skipRest() {
    _restTimer?.cancel();
    final session = ref.read(activeWorkoutProvider);
    if (session != null) {
      final ex = _exerciseFor(session);
      _recordCurrentRest(ex.id);
    }
    setState(() { _resting = false; _restSec = 0; });
  }
}
