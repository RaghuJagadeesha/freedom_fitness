import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../models/models.dart';

class CustomExerciseDetailScreen extends StatefulWidget {
  final CustomSwap custom;
  const CustomExerciseDetailScreen({super.key, required this.custom});

  @override
  State<CustomExerciseDetailScreen> createState() => _CustomExerciseDetailState();
}

class _CustomExerciseDetailState extends State<CustomExerciseDetailScreen> {
  final _weightCtrl = TextEditingController();
  final _repsCtrl = TextEditingController();
  Timer? _restTimer;
  int _restSec = 0;
  bool _resting = false;

  List<SetLog> _logs = [];
  Difficulty? _difficulty;

  CustomSwap get custom => widget.custom;

  @override
  void initState() {
    super.initState();
    _repsCtrl.text = custom.exercise.reps.toString();
  }

  @override
  void dispose() {
    _restTimer?.cancel();
    _weightCtrl.dispose();
    _repsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final done = _logs.length >= custom.exercise.sets;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(custom.exerciseName, style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new), onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 100),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Info card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(gradient: AppColors.workoutBGradient, borderRadius: BorderRadius.circular(20)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.fitness_center, color: Colors.white, size: 24),
                const SizedBox(width: 10),
                Text('${custom.exercise.sets} × ${custom.exercise.reps} reps',
                  style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
              ]),
              const SizedBox(height: 10),
              Text(custom.exercise.description,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 14, height: 1.4)),
              const SizedBox(height: 8),
              Text(custom.exercise.muscleGroup.name.toUpperCase(),
                style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.6), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
            ]),
          ),

          // ─── Large GIF preview ───
          if (custom.exercise.gifUrl != null && custom.exercise.gifUrl!.isNotEmpty) ...[
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  border: Border.all(color: AppColors.surfaceLight),
                ),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    custom.exercise.gifUrl!,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: AppColors.surfaceLight,
                      child: const Center(
                        child: Icon(Icons.fitness_center,
                            color: AppColors.textMuted, size: 40),
                      ),
                    ),
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

          const SizedBox(height: 24),

          // Sets completed
          Text('Sets Completed', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          if (_logs.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.surfaceLight)),
              child: Center(child: Text('No sets logged yet.', style: TextStyle(color: AppColors.textMuted, fontSize: 14))),
            ),
          ..._logs.asMap().entries.map((entry) {
            final s = entry.value;
            final setIndex = entry.key;
            return GestureDetector(
              onTap: () => _showEditSetDialog(setIndex, s),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: (s.isDropSet ? AppColors.warning : AppColors.primary).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: (s.isDropSet ? AppColors.warning : AppColors.primary).withValues(alpha: 0.2)),
                ),
                child: Row(children: [
                  Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      color: (s.isDropSet ? AppColors.warning : AppColors.primary).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(child: Text('${s.setNumber}',
                      style: TextStyle(color: s.isDropSet ? AppColors.warning : AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13))),
                  ),
                  const SizedBox(width: 14),
                  Text('${s.weight} lbs', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 15)),
                  const SizedBox(width: 8),
                  Text('×', style: TextStyle(color: AppColors.textMuted)),
                  const SizedBox(width: 8),
                  Text('${s.repsCompleted} reps', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 15)),
                  const Spacer(),
                  if (s.isDropSet)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
                      child: Text('DROP', style: TextStyle(color: AppColors.warning, fontSize: 10, fontWeight: FontWeight.w700)),
                    ),
                  const Icon(Icons.edit, color: AppColors.textMuted, size: 14),
                ]),
              ),
            );
          }),

          // Rest timer
          if (_resting) ...[
            const SizedBox(height: 20),
            Center(child: Column(children: [
              Text('REST', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 2)),
              const SizedBox(height: 8),
              Text('${_restSec}s', style: GoogleFonts.outfit(color: AppColors.secondary, fontSize: 48, fontWeight: FontWeight.w800)),
              TextButton(onPressed: _skipRest, child: Text('Skip', style: TextStyle(color: AppColors.textSecondary))),
            ])),
          ],

          // Log set input
          if (!done && !_resting) ...[
            const SizedBox(height: 24),
            Text('Set ${_logs.length + 1} of ${custom.exercise.sets}',
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: TextField(
                controller: _weightCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 18),
                decoration: InputDecoration(
                  labelText: 'Weight (lbs)', labelStyle: TextStyle(color: AppColors.textMuted),
                  filled: true, fillColor: AppColors.cardBg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.surfaceLight)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.surfaceLight)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.primary)),
                ),
              )),
              const SizedBox(width: 12),
              Expanded(child: TextField(
                controller: _repsCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 18),
                decoration: InputDecoration(
                  labelText: 'Reps', labelStyle: TextStyle(color: AppColors.textMuted),
                  filled: true, fillColor: AppColors.cardBg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.surfaceLight)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.surfaceLight)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.primary)),
                ),
              )),
            ]),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: ElevatedButton(
                onPressed: () => _logSet(false),
                child: const Text('Log Set ✓'),
              )),
              if (_logs.length >= 2) ...[
                const SizedBox(width: 10),
                Expanded(child: ElevatedButton(
                  onPressed: _showDropSet,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning, foregroundColor: AppColors.background),
                  child: const Text('Gap? Drop Set'),
                )),
              ],
            ]),
          ],

          // Difficulty rating
          if (done && _difficulty == null) ...[
            const SizedBox(height: 24),
            Text('How did it feel?', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            Row(children: Difficulty.values.map((d) {
              final c = {Difficulty.easy: AppColors.primary, Difficulty.moderate: AppColors.secondary, Difficulty.hard: AppColors.error};
              final l = {Difficulty.easy: '😎 Easy', Difficulty.moderate: '💪 Mod', Difficulty.hard: '🔥 Hard'};
              return Expanded(child: GestureDetector(
                onTap: () => setState(() => _difficulty = d),
                child: Container(
                  margin: EdgeInsets.only(right: d != Difficulty.hard ? 8 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: c[d]!.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: c[d]!.withValues(alpha: 0.3)),
                  ),
                  child: Center(child: Text(l[d]!, style: TextStyle(color: c[d], fontWeight: FontWeight.w600, fontSize: 13))),
                ),
              ));
            }).toList()),
          ],

          // Complete
          if (done && _difficulty != null) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Column(children: [
                const Text('✅', style: TextStyle(fontSize: 32)),
                const SizedBox(height: 8),
                Text('Exercise Complete!', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.primary)),
                Text('Rated: ${_difficulty!.name.toUpperCase()}', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ]),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back to Exercises'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ]),
      ),
    );
  }

  void _logSet(bool isDrop) {
    final w = double.tryParse(_weightCtrl.text) ?? 0;
    final r = int.tryParse(_repsCtrl.text) ?? 0;
    if (w <= 0 && r <= 0) return;
    setState(() {
      _logs.add(SetLog(
        setNumber: _logs.length + 1,
        weight: w,
        repsCompleted: r,
        isDropSet: isDrop,
      ));
    });
    _startRest(60);
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
          TextField(
            controller: wCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              labelText: 'Weight (lbs)', labelStyle: TextStyle(color: AppColors.textMuted),
              filled: true, fillColor: AppColors.cardBg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: rCtrl,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              labelText: 'Reps', labelStyle: TextStyle(color: AppColors.textMuted),
              filled: true, fillColor: AppColors.cardBg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary))),
          ElevatedButton(
            onPressed: () {
              final w = double.tryParse(wCtrl.text) ?? set.weight;
              final r = int.tryParse(rCtrl.text) ?? set.repsCompleted;
              setState(() {
                _logs[setIndex] = SetLog(
                  setNumber: set.setNumber,
                  weight: w,
                  repsCompleted: r,
                  isDropSet: set.isDropSet,
                );
              });
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDropSet() {
    final cw = double.tryParse(_weightCtrl.text) ?? 0;
    final dw = (cw * 0.8).roundToDouble();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          const Icon(Icons.trending_down, color: AppColors.warning),
          const SizedBox(width: 8),
          Text('Drop Set', style: TextStyle(color: AppColors.textPrimary)),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Reduce weight by 20% and finish reps.', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          const SizedBox(height: 16),
          Text('Drop to: $dw lbs', style: GoogleFonts.outfit(color: AppColors.warning, fontSize: 20, fontWeight: FontWeight.w700)),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _weightCtrl.text = dw.toString();
              _logSet(true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
            child: const Text('Drop & Log'),
          ),
        ],
      ),
    );
  }

  void _startRest(int sec) {
    setState(() { _resting = true; _restSec = sec; });
    _restTimer?.cancel();
    _restTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() { _restSec--; if (_restSec <= 0) { _resting = false; t.cancel(); } });
    });
  }

  void _skipRest() {
    _restTimer?.cancel();
    setState(() { _resting = false; _restSec = 0; });
  }
}
