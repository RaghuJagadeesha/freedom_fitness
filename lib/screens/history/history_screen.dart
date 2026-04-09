import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(workoutHistoryProvider);
    final floaters = ref.watch(floaterProvider);
    final queueState = ref.watch(queueProvider);
    final progress = ref.watch(userProgressProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text('History & Progress', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            )),

            // Stats overview
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Row(children: [
                _StatCard(label: 'Total A', value: '${queueState.totalWorkoutsA}', color: AppColors.workoutA),
                const SizedBox(width: 10),
                _StatCard(label: 'Total B', value: '${queueState.totalWorkoutsB}', color: AppColors.workoutB),
                const SizedBox(width: 10),
                _StatCard(label: 'Floaters', value: '${floaters.length}', color: AppColors.floater),
              ]),
            )),

            // A/B distribution bar
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: _DistributionBar(a: queueState.totalWorkoutsA, b: queueState.totalWorkoutsB),
            )),

            // Progressive load section
            if (progress.isNotEmpty) ...[
              SliverToBoxAdapter(child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text('Progressive Load', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              )),
              SliverToBoxAdapter(child: SizedBox(height: 120, child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: progress.length,
                itemBuilder: (ctx, i) {
                  final p = progress.values.elementAt(i);
                  return _ProgressChip(progress: p);
                },
              ))),
            ],

            // Recent sessions
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text('Recent Sessions', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            )),

            if (sessions.isEmpty && floaters.isEmpty)
              SliverToBoxAdapter(child: Padding(
                padding: const EdgeInsets.all(20),
                child: Container(padding: const EdgeInsets.all(32), decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(20)),
                  child: Column(children: [
                    const Text('🏋️', style: TextStyle(fontSize: 40)),
                    const SizedBox(height: 12),
                    Text('No workouts yet', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    const SizedBox(height: 4),
                    Text('Complete your first workout to see it here.', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                  ])),
              )),

            // Merged timeline
            SliverList(delegate: SliverChildBuilderDelegate((ctx, i) {
              if (i < sessions.length) {
                final s = sessions[i];
                return _SessionTile(session: s);
              }
              return null;
            }, childCount: sessions.length)),

            // Floater logs
            if (floaters.isNotEmpty) ...[
              SliverToBoxAdapter(child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text('Floater Activities', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              )),
              SliverList(delegate: SliverChildBuilderDelegate((ctx, i) {
                final f = floaters[i];
                return _FloaterTile(floater: f);
              }, childCount: floaters.length)),
            ],

            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withValues(alpha: 0.25))),
      child: Column(children: [
        Text(value, style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      ]),
    ));
  }
}

class _DistributionBar extends StatelessWidget {
  final int a, b;
  const _DistributionBar({required this.a, required this.b});

  @override
  Widget build(BuildContext context) {
    final total = a + b;
    if (total == 0) return const SizedBox.shrink();
    final aRatio = a / total;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('A/B Distribution', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        const SizedBox(height: 10),
        ClipRRect(borderRadius: BorderRadius.circular(6), child: SizedBox(height: 12, child: Row(children: [
          Expanded(flex: (aRatio * 100).round(), child: Container(color: AppColors.workoutA)),
          Expanded(flex: ((1 - aRatio) * 100).round(), child: Container(color: AppColors.workoutB)),
        ]))),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('A: ${(aRatio * 100).round()}%', style: TextStyle(color: AppColors.workoutA, fontSize: 12, fontWeight: FontWeight.w600)),
          Text('B: ${((1 - aRatio) * 100).round()}%', style: TextStyle(color: AppColors.workoutB, fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
      ]),
    );
  }
}

class _ProgressChip extends StatelessWidget {
  final UserProgress progress;
  const _ProgressChip({required this.progress});

  @override
  Widget build(BuildContext context) {
    final name = progress.exerciseId.replaceAll(RegExp(r'^[ab]_'), '').replaceAll('_', ' ');
    return Container(
      width: 140, margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.surfaceLight)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(name[0].toUpperCase() + name.substring(1), style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 8),
        Text('${progress.currentWeight} lbs', style: GoogleFonts.outfit(color: AppColors.primary, fontSize: 22, fontWeight: FontWeight.w800)),
        Text('${progress.totalTimesPerformed}× performed', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
      ]),
    );
  }
}

class _SessionTile extends StatelessWidget {
  final WorkoutSession session;
  const _SessionTile({required this.session});

  @override
  Widget build(BuildContext context) {
    final isA = session.actualType == WorkoutType.a;
    final color = isA ? AppColors.workoutA : AppColors.workoutB;
    final df = DateFormat('MMM d, yyyy • h:mm a');

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.surfaceLight)),
      child: Row(children: [
        Container(width: 44, height: 44, decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
          child: Center(child: Text(isA ? 'A' : 'B', style: GoogleFonts.outfit(color: color, fontSize: 20, fontWeight: FontWeight.w800)))),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(session.actualType.label, style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 15)),
            if (session.wasOverridden) ...[const SizedBox(width: 6),
              Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                child: Text('Override', style: TextStyle(color: AppColors.warning, fontSize: 10, fontWeight: FontWeight.w600)))],
          ]),
          const SizedBox(height: 4),
          Text(df.format(session.date), style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('${session.durationMinutes}m', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
          Text('${session.exercises.where((e) => e.sets.isNotEmpty).length} exercises', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
        ]),
      ]),
    );
  }
}

class _FloaterTile extends StatelessWidget {
  final FloaterLog floater;
  const _FloaterTile({required this.floater});

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('MMM d, yyyy • h:mm a');
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.surfaceLight)),
      child: Row(children: [
        Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.floater.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
          child: Center(child: Text(floater.type == FloaterType.tennis ? '🎾' : '🏃', style: const TextStyle(fontSize: 20)))),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(floater.type.label, style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 15)),
          const SizedBox(height: 4),
          Text(df.format(floater.date), style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
        ])),
        Text('${floater.durationMinutes}m', style: TextStyle(color: AppColors.floater, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}
