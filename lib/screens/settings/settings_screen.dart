import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../data/database.dart';
import '../../providers/providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final restTimer = ref.watch(restTimerDurationProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Settings', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            const SizedBox(height: 24),

            // Rest Timer
            _SettingsSection(title: 'Workout', children: [
              _SettingsTile(
                icon: Icons.timer_outlined,
                title: 'Rest Timer',
                subtitle: '$restTimer seconds between sets',
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: AppColors.textSecondary),
                    onPressed: () {
                      final newVal = (restTimer - 15).clamp(15, 300);
                      ref.read(restTimerDurationProvider.notifier).state = newVal;
                      Database.setRestTimer(newVal);
                    },
                  ),
                  Text('${restTimer}s', style: GoogleFonts.outfit(color: AppColors.primary, fontSize: 18, fontWeight: FontWeight.w700)),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: AppColors.textSecondary),
                    onPressed: () {
                      final newVal = (restTimer + 15).clamp(15, 300);
                      ref.read(restTimerDurationProvider.notifier).state = newVal;
                      Database.setRestTimer(newVal);
                    },
                  ),
                ]),
              ),
            ]),

            // About
            _SettingsSection(title: 'About', children: [
              _SettingsTile(
                icon: Icons.info_outline,
                title: 'Freedom Fitness',
                subtitle: 'Version 1.0.0',
              ),
              _SettingsTile(
                icon: Icons.favorite_outline,
                title: 'Design Philosophy',
                subtitle: 'Rolling Queue — Never skip, never guilt.',
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SettingsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 1)),
      const SizedBox(height: 8),
      Container(
        decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(16)),
        child: Column(children: children),
      ),
      const SizedBox(height: 24),
    ]);
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final Widget? trailing;
  const _SettingsTile({required this.icon, required this.title, required this.subtitle, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: AppColors.primary, size: 20)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 15)),
          Text(subtitle, style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
        ])),
        ?trailing,
      ]),
    );
  }
}
