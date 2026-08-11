import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../data/database.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../services/gemini_service.dart';


class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider);
    final units = Database.getUnits();
    final restTimer = Database.getRestTimer();
    final currentSplit = ref.watch(splitPreferenceProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        title: Text(
          'Settings',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        children: [
          // ─── Account Section ───
          _buildSectionHeader('Account'),
          if (profile != null && profile.isSignedIn)
            _buildAccountCard(profile)
          else
            _buildSignInCard(),

          const SizedBox(height: 24),

          // ─── Workout Split ───
          _buildSectionHeader('Workout Split'),
          _buildSplitCard(currentSplit),

          const SizedBox(height: 24),

          // ─── AI Configuration ───
          _buildSectionHeader('AI Coach'),
          _buildAiConfigCard(profile),

          const SizedBox(height: 24),

          // ─── Experience Level ───
          _buildSectionHeader('Experience Level'),
          _buildExperienceLevelCard(profile),

          const SizedBox(height: 24),

          // ─── General Settings ───
          _buildSectionHeader('General'),
          _buildSettingsTile(
            icon: Icons.straighten,
            title: 'Units',
            subtitle: units == 'lbs' ? 'Pounds (lbs)' : 'Kilograms (kg)',
            onTap: () => _toggleUnits(units),
          ),
          _buildSettingsTile(
            icon: Icons.timer_outlined,
            title: 'Rest Timer',
            subtitle: '${restTimer}s between sets',
            onTap: () => _showRestTimerPicker(restTimer),
          ),

          const SizedBox(height: 24),

          // ─── Version Info ───
          Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Freedom Fitness v2.0',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSplitCard(WorkoutSplitType currentSplit) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose how many days per week you want to train.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 12),
          ...WorkoutSplitType.values.map((split) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: () => _setSplit(split),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: currentSplit == split
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: currentSplit == split
                        ? AppColors.primary
                        : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      currentSplit == split
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: currentSplit == split
                          ? AppColors.primary
                          : AppColors.textMuted,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            split.label,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: currentSplit == split
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                          Text(
                            split.subtitle,
                            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: currentSplit == split
                            ? AppColors.primary.withValues(alpha: 0.15)
                            : AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${split.dayCount}d',
                        style: TextStyle(
                          color: currentSplit == split
                              ? AppColors.primary
                              : AppColors.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildAccountCard(UserProfile profile) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primary.withValues(alpha: 0.2),
            backgroundImage: profile.photoUrl != null
                ? NetworkImage(profile.photoUrl!)
                : null,
            child: profile.photoUrl == null
                ? const Icon(Icons.person, color: AppColors.primary)
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.displayName ?? 'User',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  profile.email ?? '',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _handleSignOut,
            child: Text(
              'Sign Out',
              style: TextStyle(color: AppColors.error, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignInCard() {
    return GestureDetector(
      onTap: () => context.push('/login'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.login, color: AppColors.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sign In',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Unlock AI-powered features',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildAiConfigCard(UserProfile? profile) {
    final isEnabled = profile?.isSignedIn ?? false;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                isEnabled ? Icons.auto_awesome : Icons.auto_awesome_outlined,
                color: isEnabled ? AppColors.primary : AppColors.textMuted,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gemini AI',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      isEnabled
                          ? 'Connected — using your API key'
                          : 'Not connected',
                      style: TextStyle(
                        color: isEnabled
                            ? AppColors.primary
                            : AppColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isEnabled
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isEnabled ? 'ACTIVE' : 'OFF',
                  style: TextStyle(
                    color: isEnabled ? AppColors.primary : AppColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          if (isEnabled) ...[
            const Divider(color: AppColors.surfaceLight, height: 24),
            _buildSettingsTileCompact(
              icon: Icons.key,
              title: 'Manage API Key',
              onTap: _showApiKeyDialog,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExperienceLevelCard(UserProfile? profile) {
    final currentLevel =
        profile?.experienceLevel ?? ExperienceLevel.beginner;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This affects exercise recommendations and safety guardrails.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 12),
          ...ExperienceLevel.values.map((level) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: () => _setExperienceLevel(level),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: currentLevel == level
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: currentLevel == level
                            ? AppColors.primary
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          currentLevel == level
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color: currentLevel == level
                              ? AppColors.primary
                              : AppColors.textMuted,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          level.label,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: currentLevel == level
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surfaceLight),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textSecondary, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(subtitle,
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTileCompact({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
            ),
          ),
          const Icon(Icons.chevron_right,
              color: AppColors.textMuted, size: 18),
        ],
      ),
    );
  }

  // ─── Actions ───────────────────────────────────

  void _toggleUnits(String current) {
    final next = current == 'lbs' ? 'kg' : 'lbs';
    Database.setUnits(next);
    setState(() {});
  }

  void _showRestTimerPicker(int current) {
    final options = [60, 90, 120, 150, 180];
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Rest Timer Duration',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ...options.map((sec) => ListTile(
                  title: Text('${sec}s',
                      style: TextStyle(color: AppColors.textPrimary)),
                  trailing: current == sec
                      ? const Icon(Icons.check, color: AppColors.primary)
                      : null,
                  onTap: () {
                    Database.setRestTimer(sec);
                    Navigator.pop(ctx);
                    setState(() {});
                  },
                )),
          ],
        ),
      ),
    );
  }

  void _setExperienceLevel(ExperienceLevel level) {
    ref.read(userProfileProvider.notifier).updateExperienceLevel(level);
  }

  void _setSplit(WorkoutSplitType split) {
    ref.read(queueProvider.notifier).changeSplit(split);
    ref.read(splitPreferenceProvider.notifier).state = split;
  }

  Future<void> _handleSignOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Sign Out?',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          'AI features will be disabled. Your workout data stays safe on this device.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                Text('Sign Out', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AuthService.signOut();
      GeminiService.dispose();
      ref.read(userProfileProvider.notifier).signOut();
    }
  }

  void _showApiKeyDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Gemini API Key',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Replace your current API key. Get a free key from ai.google.dev',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              style: TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'AIzaSy...',
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
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                await AuthService.saveApiKey(controller.text.trim());
                await GeminiService.initialize();
                if (ctx.mounted) Navigator.pop(ctx);
                setState(() {});
              }
            },
            child: Text('Save',
                style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}
