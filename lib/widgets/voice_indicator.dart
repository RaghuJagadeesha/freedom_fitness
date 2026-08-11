import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Floating voice listening indicator widget.
///
/// Shows a pulsing microphone icon when voice mode is active,
/// along with the recognized text and command feedback.
class VoiceIndicator extends StatefulWidget {
  final bool isListening;
  final String? recognizedText;
  final String? feedbackText;
  final VoidCallback onToggle;

  const VoiceIndicator({
    super.key,
    required this.isListening,
    this.recognizedText,
    this.feedbackText,
    required this.onToggle,
  });

  @override
  State<VoiceIndicator> createState() => _VoiceIndicatorState();
}

class _VoiceIndicatorState extends State<VoiceIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(VoiceIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isListening && !oldWidget.isListening) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isListening && oldWidget.isListening) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Feedback text (e.g., "Set 2 logged ✓")
        if (widget.feedbackText != null)
          AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: 1.0,
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                widget.feedbackText!,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

        // Recognized text
        if (widget.isListening && widget.recognizedText != null)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.surfaceLight),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.hearing, size: 14, color: AppColors.secondary),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    '"${widget.recognizedText}"',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

        // Microphone button
        GestureDetector(
          onTap: widget.onToggle,
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              final scale = widget.isListening ? _pulseAnimation.value : 1.0;
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.isListening
                        ? AppColors.error
                        : AppColors.secondary,
                    boxShadow: [
                      BoxShadow(
                        color: (widget.isListening
                                ? AppColors.error
                                : AppColors.secondary)
                            .withValues(alpha: 0.4),
                        blurRadius: widget.isListening ? 20 : 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    widget.isListening ? Icons.mic : Icons.mic_none,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
