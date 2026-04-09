import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../data/seed_data.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';


class MorningScreen extends ConsumerWidget {
  const MorningScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(morningRoutineProvider);
    final notifier = ref.read(morningRoutineProvider.notifier);

    final items = [

      _RoutineItem(
        icon: '💧',
        title: 'Hydration & Sunlight',
        subtitle: '16oz water + 10 mins natural light',
        duration: '10 min',
        done: state.hydrationDone,
        onToggle: notifier.toggleHydration,
        youtubeUrl: SeedData.morningExercises[0].youtubeUrl,
      ),
      _RoutineItem(
        icon: '🧘',
        title: 'Couch Stretch',
        subtitle: '1 min per side — opens hips for glute activation',
        duration: '2 min',
        done: state.couchStretchDone,
        onToggle: notifier.toggleCouchStretch,
        youtubeUrl: SeedData.morningExercises[1].youtubeUrl,
      ),
      _RoutineItem(
        icon: '🐱',
        title: 'Cat-Cow to Bird-Dog',
        subtitle: 'Wakes up the deep core',
        duration: '1 min',
        done: state.catCowDone,
        onToggle: notifier.toggleCatCow,
        youtubeUrl: SeedData.morningExercises[2].youtubeUrl,
      ),
      _RoutineItem(
        icon: '🍑',
        title: 'Bodyweight Glute Bridges',
        subtitle: 'Primes the posterior chain',
        duration: '1 min',
        done: state.gluteBridgesDone,
        onToggle: notifier.toggleGluteBridges,
        youtubeUrl: SeedData.morningExercises[3].youtubeUrl,
      ),
    ];

    final completedCount = [
      state.hydrationDone,
      state.couchStretchDone,
      state.catCowDone,
      state.gluteBridgesDone,
    ].where((d) => d).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Daily Ignition',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Progress header
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.morning.withValues(alpha: 0.2),
                  AppColors.morning.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.morning.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      state.allDone ? '🔥' : '☀️',
                      style: const TextStyle(fontSize: 32),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      state.allDone
                          ? 'Morning Routine Complete!'
                          : 'Hormonal Reset & Mobility',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: completedCount / 4,
                    backgroundColor: AppColors.surfaceLight,
                    valueColor: const AlwaysStoppedAnimation(AppColors.morning),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$completedCount of 4 completed',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),

          // Routine items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: items.length,
              itemBuilder: (context, index) => items[index],
            ),
          ),

          // Done button
          if (state.allDone)
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Continue to Workout'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.morning,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RoutineItem extends StatefulWidget {
  final String icon;
  final String title;
  final String subtitle;
  final String duration;
  final bool done;
  final VoidCallback onToggle;
  final String? youtubeUrl;

  const _RoutineItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.duration,
    required this.done,
    required this.onToggle,
    this.youtubeUrl,
  });

  @override
  State<_RoutineItem> createState() => _RoutineItemState();
}

class _RoutineItemState extends State<_RoutineItem> {
  bool _showVideo = false;
  YoutubePlayerController? _controller;

  void _toggleVideo() {
    if (widget.youtubeUrl == null) return;
    setState(() {
      _showVideo = !_showVideo;
      if (_showVideo) {
        _controller = YoutubePlayerController.fromVideoId(
          videoId: widget.youtubeUrl!,
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
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.done
            ? AppColors.morning.withValues(alpha: 0.1)
            : AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.done
              ? AppColors.morning.withValues(alpha: 0.4)
              : AppColors.surfaceLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: widget.onToggle,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: widget.done
                        ? AppColors.morning.withValues(alpha: 0.2)
                        : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: widget.done
                        ? const Icon(Icons.check, color: AppColors.morning, size: 24)
                        : Text(widget.icon, style: const TextStyle(fontSize: 24)),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: GestureDetector(
                  onTap: widget.onToggle,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: widget.done
                              ? AppColors.textSecondary
                              : AppColors.textPrimary,
                          decoration: widget.done ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.subtitle,
                        style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.duration,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (widget.youtubeUrl != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(_showVideo ? Icons.keyboard_arrow_up : Icons.play_circle_fill, color: AppColors.morning, size: 28),
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
