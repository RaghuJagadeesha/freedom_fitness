import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_theme.dart';
import '../../data/database.dart';
import '../../services/gemini_service.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import 'package:uuid/uuid.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

class MachineIdScreen extends ConsumerStatefulWidget {
  const MachineIdScreen({super.key});

  @override
  ConsumerState<MachineIdScreen> createState() => _MachineIdScreenState();
}

class _MachineIdScreenState extends ConsumerState<MachineIdScreen>
    with SingleTickerProviderStateMixin {
  final _picker = ImagePicker();
  Uint8List? _imageBytes;
  MachineIdResult? _result;
  bool _isAnalyzing = false;
  String? _errorMessage;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _captureFromCamera() async {
    final image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      maxWidth: 1024,
    );
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _result = null;
        _errorMessage = null;
      });
      await _analyzeImage();
    }
  }

  Future<void> _pickFromGallery() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1024,
    );
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _result = null;
        _errorMessage = null;
      });
      await _analyzeImage();
    }
  }

  Future<void> _analyzeImage() async {
    if (_imageBytes == null) return;

    if (!GeminiService.isReady) {
      setState(() =>
          _errorMessage = 'AI not configured. Add your Gemini API key in Settings.');
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _errorMessage = null;
    });

    try {
      final result = await GeminiService.identifyMachine(_imageBytes!);

      setState(() {
        _result = result;
        _isAnalyzing = false;
      });
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
        _errorMessage = e.toString().contains('Exception: ') 
            ? e.toString().split('Exception: ')[1] 
            : e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAiEnabled = ref.watch(isAiEnabledProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Machine ID',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (!isAiEnabled)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.warning_amber,
                        size: 14, color: AppColors.warning),
                    const SizedBox(width: 4),
                    Text('No AI',
                        style: TextStyle(
                            color: AppColors.warning, fontSize: 12)),
                  ],
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // ─── Image Preview Area ───
          Expanded(
            flex: 3,
            child: _imageBytes != null
                ? _buildImagePreview()
                : _buildEmptyState(),
          ),

          // ─── Results Area ───
          if (_isAnalyzing)
            _buildAnalyzingIndicator()
          else if (_result != null)
            Expanded(flex: 4, child: _buildResults())
          else if (_errorMessage != null)
            _buildErrorCard(),

          // ─── Capture Buttons ───
          _buildCaptureButtons(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(28),
            ),
            child: const Icon(
              Icons.photo_camera_outlined,
              color: AppColors.secondary,
              size: 48,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Snap a Gym Machine',
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Take a photo of any gym equipment and AI will identify it '
              'and suggest exercises for your workout.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isAnalyzing
              ? AppColors.secondary.withValues(alpha: 0.5)
              : AppColors.surfaceLight,
          width: 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Image.memory(
          _imageBytes!,
          fit: BoxFit.cover,
          width: double.infinity,
        ),
      ),
    );
  }

  Widget _buildAnalyzingIndicator() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.secondary
                  .withValues(alpha: 0.05 + (_pulseController.value * 0.08)),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.secondary
                    .withValues(alpha: 0.2 + (_pulseController.value * 0.2)),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(width: 14),
                Text(
                  'Analyzing equipment...',
                  style: GoogleFonts.inter(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildResults() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      children: [
        // Machine name header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Identified',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _result!.machineName,
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Suggested exercises
        Text(
          'Suggested Exercises',
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        ..._result!.exercises.asMap().entries.map((entry) {
          final index = entry.key;
          final exercise = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.surfaceLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        exercise.name,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${exercise.sets}×${exercise.reps}',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        exercise.muscleGroup,
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  exercise.formCue,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _playVideo(exercise),
                        icon: const Icon(Icons.play_circle_fill, size: 18),
                        label: const Text('Play Tutorial'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
                          foregroundColor: Colors.redAccent,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showAddOptions(exercise),
                        icon: const Icon(Icons.add_circle_outline, size: 18),
                        label: const Text('Add to Plan'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                          foregroundColor: AppColors.primary,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  void _playVideo(SuggestedExercise exercise) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        contentPadding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.topRight,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: YoutubeVideoPlayer(
                      searchQuery: exercise.youtubeSearchQuery ?? '${exercise.name} tutorial',
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                exercise.name,
                style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddOptions(SuggestedExercise exercise) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.today, color: Colors.amber),
                ),
                title: const Text('Just for Today',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Temporary addition to current workout'),
                onTap: () {
                  Navigator.pop(context);
                  _addToToday(exercise);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.update, color: Colors.green),
                ),
                title: const Text('Permanent Addition',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Save to routine for future sessions'),
                onTap: () {
                  Navigator.pop(context);
                  _addToPermanent(exercise);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addToToday(SuggestedExercise suggestion) {
    final activeWorkout = ref.read(activeWorkoutProvider);
    if (activeWorkout == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please start a workout first from the Home tab.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final log = ExerciseLog(
      exerciseId: const Uuid().v4(),
      exerciseName: suggestion.name,
    );

    ref.read(activeWorkoutProvider.notifier).addExerciseLog(log);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added ${suggestion.name} to today\'s session!'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.secondary,
      ),
    );
  }

  void _addToPermanent(SuggestedExercise suggestion) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Select Routine', style: GoogleFonts.outfit()),
        content: const Text('Which workout rotation should this add to?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => _saveToRoutineAndNotify(
              suggestion: suggestion,
              routine: '3-day: Day 1',
              message: 'Added to workout plan',
            ),
            child: const Text('ADD TO PLAN'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveToRoutineAndNotify({
    required SuggestedExercise suggestion,
    required String routine,
    required String message,
  }) async {
    Navigator.of(context).pop();
    await _saveToLibrary(suggestion);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _saveToLibrary(SuggestedExercise suggestion) async {
    final exercise = Exercise(
      id: const Uuid().v4(),
      name: suggestion.name,
      category: ExerciseCategory.compound,
      muscleGroup: MuscleGroup.values.firstWhere(
        (m) => m.name.toLowerCase() == suggestion.muscleGroup.toLowerCase(),
        orElse: () => MuscleGroup.fullBody,
      ),
      sets: suggestion.sets,
      reps: suggestion.reps,
      isUserAdded: true,
      description: suggestion.formCue,
    );

    await Database.saveCustomExercise(exercise);
  }

  Widget _buildErrorCard() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.error.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline,
                    color: AppColors.error, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: AppColors.error, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: _showAiDiagnostics,
            icon: const Icon(Icons.analytics_outlined, size: 18),
            label: const Text('Check AI Capability'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAiDiagnostics() async {
    showDialog(
      context: context,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final status = await GeminiService.listAvailableModels();
    
    if (!mounted) return;
    Navigator.of(context).pop(); // Dismiss loading

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('AI Diagnostic Info'),
        content: SingleChildScrollView(
          child: SelectableText(
            status,
            style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildCaptureButtons() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(
            color: AppColors.surfaceLight.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isAnalyzing ? null : _captureFromCamera,
              icon: const Icon(Icons.camera_alt, size: 20),
              label: const Text('Camera'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _isAnalyzing ? null : _pickFromGallery,
              icon: const Icon(Icons.photo_library, size: 20),
              label: const Text('Gallery'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: const BorderSide(color: AppColors.surfaceLight),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class YoutubeVideoPlayer extends StatefulWidget {
  final String searchQuery;
  const YoutubeVideoPlayer({super.key, required this.searchQuery});

  @override
  State<YoutubeVideoPlayer> createState() => _YoutubeVideoPlayerState();
}

class _YoutubeVideoPlayerState extends State<YoutubeVideoPlayer> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    // In a real app, we would resolve the search query to a Video ID here.
    // For this simulation, we'll use a high-quality fitness fallback ID.
    _controller = YoutubePlayerController.fromVideoId(
      videoId: 'IODxDxX7oi4', 
      autoPlay: true,
      params: const YoutubePlayerParams(showFullscreenButton: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayer(controller: _controller);
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }
}
