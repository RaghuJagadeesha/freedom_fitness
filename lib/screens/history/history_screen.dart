import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../data/seed_data.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(workoutHistoryProvider);
    final floaters = ref.watch(floaterProvider);
    final queueState = ref.watch(queueProvider);
    final progress = ref.watch(userProgressProvider);

    final split = queueState.splitType;
    final days = SeedData.getDayMetadatas(split);
    final dayColors = [AppColors.workoutA, AppColors.workoutB, AppColors.primary, AppColors.floater, AppColors.accent];

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
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  ...days.map((d) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _StatCard(
                      label: d.label,
                      value: '${queueState.getTotalWorkoutsForDay(d.dayIndex)}',
                      color: dayColors[d.dayIndex % dayColors.length],
                    ),
                  )),
                  _StatCard(label: 'Floaters', value: '${floaters.length}', color: AppColors.floater),
                ]),
              ),
            )),

            // Day distribution bar
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: _DistributionBar(days: days, counts: queueState.normalizedCounts, colors: dayColors),
            )),

            // Progressive load section
            if (progress.isNotEmpty) ...[
              SliverToBoxAdapter(child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text('Progressive Load', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              )),
              SliverToBoxAdapter(child: SizedBox(height: 140, child: ListView.builder(
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
              SliverFillRemaining(
                hasScrollBody: false,
                fillOverscroll: true,
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(24),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.surfaceLight),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🏋️', style: TextStyle(fontSize: 40)),
                      const SizedBox(height: 12),
                      Text('No workouts yet',
                          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      const SizedBox(height: 4),
                      Text('Complete your first workout to see it here.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                    ],
                  ),
                ),
              ),

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
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 110),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withValues(alpha: 0.25))),
        child: Column(children: [
          Text(value, style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 4),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ]),
      ),
    );
  }
}

class _DistributionBar extends StatelessWidget {
  final List<SplitDay> days;
  final List<int> counts;
  final List<Color> colors;
  const _DistributionBar({required this.days, required this.counts, required this.colors});

  @override
  Widget build(BuildContext context) {
    final total = counts.fold(0, (a, b) => a + b);
    if (total == 0) return const SizedBox.shrink();
    final ratios = counts.map((c) => c / total).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Day Distribution', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        const SizedBox(height: 10),
        ClipRRect(borderRadius: BorderRadius.circular(6), child: SizedBox(height: 12, child: Row(children: [
          for (int i = 0; i < days.length; i++)
            Expanded(flex: (ratios[i] * 100).round().clamp(1, 100), child: Container(color: colors[i % colors.length])),
        ]))),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          for (int i = 0; i < days.length; i++)
            Text('${days[i].label}: ${(ratios[i] * 100).round()}%',
              style: TextStyle(color: colors[i % colors.length], fontSize: 12, fontWeight: FontWeight.w600),
            ),
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
    final name = progress.exerciseId.replaceAll(RegExp(r'^[a-z]+\d?_'), '').replaceAll('_', ' ');
    final displayName = name.isEmpty ? '' : name[0].toUpperCase() + name.substring(1);
    return Container(
      width: 140, margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.surfaceLight)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(displayName, style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 8),
        Text('${progress.currentWeight} lbs', style: GoogleFonts.outfit(color: AppColors.primary, fontSize: 22, fontWeight: FontWeight.w800)),
        Text('${progress.totalTimesPerformed}× performed', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
      ]),
    );
  }
}

class _SessionTile extends StatefulWidget {
  final WorkoutSession session;
  const _SessionTile({required this.session});

  @override
  State<_SessionTile> createState() => _SessionTileState();
}

class _SessionTileState extends State<_SessionTile> {
  bool _expanded = false;

  Color get _color {
    final dayColors = [AppColors.workoutA, AppColors.workoutB, AppColors.primary, AppColors.floater, AppColors.accent];
    return dayColors[widget.session.dayIndex % dayColors.length];
  }
  String get _shortLabel {
    final words = widget.session.dayLabel.split(' ');
    if (words.length >= 2) return words[0].substring(0, 2);
    return widget.session.dayLabel.substring(0, 2);
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final df = DateFormat('MMM d, yyyy • h:mm a');
    final exercises = session.exercises.where((e) => e.sets.isNotEmpty).toList();

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(children: [
                    Container(width: 44, height: 44, decoration: BoxDecoration(color: _color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                      child: Center(child: Text(_shortLabel, style: GoogleFonts.outfit(color: _color, fontSize: 20, fontWeight: FontWeight.w800)))),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                        Flexible(child: Text(widget.session.dayLabel, style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 15), overflow: TextOverflow.ellipsis)),
                        if (session.wasOverridden) ...[const SizedBox(width: 6),
                          Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                            child: Text('Override', style: TextStyle(color: AppColors.warning, fontSize: 10, fontWeight: FontWeight.w600)))],
                      ]),
                      const SizedBox(height: 4),
                      Text(df.format(session.date), style: TextStyle(color: AppColors.textMuted, fontSize: 12), overflow: TextOverflow.ellipsis),
                    ])),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text('${session.durationMinutes}m', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                      Text('${exercises.length} exercises', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                    ]),
                    const SizedBox(width: 8),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(Icons.expand_more, color: AppColors.textMuted, size: 20),
                    ),
                  ]),
                ),
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: _buildExpandedContent(exercises),
                  crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 200),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedContent(List<ExerciseLog> exercises) {
    final totalRest = exercises.fold<int>(0, (sum, e) => sum + e.totalRestSeconds);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ...exercises.map((ex) => Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: _color.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(10)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(ex.exerciseName, style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis, maxLines: 1)),
              if (ex.elapsedSeconds > 0)
                Text(_fmtRest(ex.elapsedSeconds), style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w600)),
              if (ex.totalRestSeconds > 0) ...[
                const SizedBox(width: 6),
                Text('rest ${_fmtRest(ex.totalRestSeconds)}', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
              ],
            ]),
            const SizedBox(height: 6),
            ...ex.sets.map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(children: [
                Container(width: 24, height: 24, decoration: BoxDecoration(color: _color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                  child: Center(child: Text('${s.setNumber}', style: TextStyle(color: _color, fontSize: 11, fontWeight: FontWeight.w700)))),
                const SizedBox(width: 10),
                Expanded(child: Text('${s.weight} lbs × ${s.repsCompleted} reps', style: TextStyle(color: AppColors.textSecondary, fontSize: 13), overflow: TextOverflow.ellipsis)),
                if (s.isDropSet) ...[
                  const SizedBox(width: 6),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(color: AppColors.floater.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                    child: Text('drop ${s.dropSetWeight?.toStringAsFixed(0)}', style: TextStyle(color: AppColors.floater, fontSize: 10, fontWeight: FontWeight.w600))),
                ],
                if (s.restSeconds > 0) ...[
                  const SizedBox(width: 6),
                  Text('+${_fmtRest(s.restSeconds)} rest', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                ],
              ])),
            ),
          ]),
        )),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: _color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
          child: Row(children: [
            const Icon(Icons.timer_outlined, color: AppColors.textMuted, size: 16),
            const SizedBox(width: 8),
            Expanded(child: Text('Total rest this session', style: TextStyle(color: AppColors.textSecondary, fontSize: 12))),
            Text(_fmtRest(totalRest), style: GoogleFonts.outfit(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
          ]),
        ),
      ]),
    );
  }
}

String _fmtRest(int seconds) {
  if (seconds <= 0) return '0s';
  final m = seconds ~/ 60;
  final s = seconds % 60;
  if (m == 0) return '${s}s';
  return s == 0 ? '${m}m' : '${m}m ${s}s';
}

class _FloaterTile extends StatelessWidget {
  final FloaterLog floater;
  const _FloaterTile({required this.floater});

  String get _icon {
    switch (floater.type) {
      case FloaterType.tennis: return '🎾';
      case FloaterType.run: return '🏃';
      case FloaterType.other: return '📋';
    }
  }

  String get _detail {
    final parts = <String>[];
    if (floater.distance != null) parts.add('${floater.distance} mi');
    if (floater.setsPlayed != null) parts.add('Sets: ${floater.setsPlayed}');
    if (floater.customName != null) parts.add(floater.customName!);
    return parts.isNotEmpty ? parts.join(' • ') : '${floater.durationMinutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('MMM d, yyyy • h:mm a');
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.surfaceLight)),
      child: Row(children: [
        Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.floater.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
          child: Center(child: Text(_icon, style: const TextStyle(fontSize: 20)))),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(floater.type.label, style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 15), overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(df.format(floater.date), style: TextStyle(color: AppColors.textMuted, fontSize: 12), overflow: TextOverflow.ellipsis),
        ])),
                    const SizedBox(width: 8),
                    Flexible(child: Text(_detail, style: TextStyle(color: AppColors.floater, fontWeight: FontWeight.w600, fontSize: 13), overflow: TextOverflow.ellipsis)),
      ]),
    );
  }
}
