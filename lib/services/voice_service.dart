import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

/// Voice command type parsed from speech input.
enum VoiceCommand {
  setDone,
  startRest,
  addTime,
  nextExercise,
  previousExercise,
  unknown,
}

/// Result of parsing a voice command from speech.
class VoiceCommandResult {
  final VoiceCommand command;
  final String rawText;
  final int? extraSeconds; // For "add 30 seconds" type commands

  const VoiceCommandResult({
    required this.command,
    required this.rawText,
    this.extraSeconds,
  });
}

/// Callback signature for voice command events.
typedef VoiceCommandCallback = void Function(VoiceCommandResult result);

/// Manages local speech-to-text and text-to-speech for hands-free gym mode.
///
/// Supports commands: "set done", "start rest", "add 30 seconds",
/// "next exercise", "previous exercise".
class VoiceService {
  static final stt.SpeechToText _speech = stt.SpeechToText();
  static final FlutterTts _tts = FlutterTts();
  static bool _isInitialized = false;
  static bool _isListening = false;

  /// Initialize STT and TTS engines.
  static Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      final available = await _speech.initialize(
        onError: (error) => debugPrint('STT Error: ${error.errorMsg}'),
        onStatus: (status) => debugPrint('STT Status: $status'),
      );

      if (!available) return false;

      // Configure TTS
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.5);
      await _tts.setVolume(0.8);
      await _tts.setPitch(1.0);

      _isInitialized = true;
      return true;
    } catch (e) {
      debugPrint('Voice init error: $e');
      return false;
    }
  }

  /// Whether the voice engine is ready.
  static bool get isInitialized => _isInitialized;

  /// Whether we are currently listening for commands.
  static bool get isListening => _isListening;

  // ─── Speech-to-Text ────────────────────────────

  /// Start listening for voice commands.
  /// [onCommand] is called when a valid command is recognized.
  static Future<void> startListening(VoiceCommandCallback onCommand) async {
    if (!_isInitialized) {
      final ok = await initialize();
      if (!ok) return;
    }

    if (_isListening) return;
    _isListening = true;

    await _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          final parsed = parseCommand(result.recognizedWords);
          onCommand(parsed);
        }
      },
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 3),
      listenOptions: stt.SpeechListenOptions(listenMode: stt.ListenMode.confirmation),
    );
  }

  /// Stop listening.
  static Future<void> stopListening() async {
    _isListening = false;
    await _speech.stop();
  }

  /// Toggle listening on/off.
  static Future<void> toggleListening(VoiceCommandCallback onCommand) async {
    if (_isListening) {
      await stopListening();
    } else {
      await startListening(onCommand);
    }
  }

  // ─── Text-to-Speech (Feedback) ─────────────────

  /// Speak a message aloud (e.g., "Set 2 of 3 logged. Starting rest timer.").
  static Future<void> speak(String message) async {
    if (!_isInitialized) return;
    await _tts.speak(message);
  }

  /// Stop speaking.
  static Future<void> stopSpeaking() async {
    await _tts.stop();
  }

  // ─── Command Parsing ──────────────────────────

  /// Parse raw speech text into a structured command.
  static VoiceCommandResult parseCommand(String text) {
    final lower = text.toLowerCase().trim();

    // "Set done" / "log set" / "done"
    if (_matches(lower, ['set done', 'log set', 'set complete', 'done', 'log it'])) {
      return VoiceCommandResult(
        command: VoiceCommand.setDone,
        rawText: text,
      );
    }

    // "Start rest" / "rest" / "timer"
    if (_matches(lower, ['start rest', 'rest timer', 'begin rest', 'rest', 'start timer'])) {
      return VoiceCommandResult(
        command: VoiceCommand.startRest,
        rawText: text,
      );
    }

    // "Add 30 seconds" / "add time" / "extend"
    if (lower.contains('add') && (lower.contains('second') || lower.contains('time'))) {
      final seconds = _extractSeconds(lower);
      return VoiceCommandResult(
        command: VoiceCommand.addTime,
        rawText: text,
        extraSeconds: seconds,
      );
    }

    // "Next exercise" / "next"
    if (_matches(lower, ['next exercise', 'next', 'skip'])) {
      return VoiceCommandResult(
        command: VoiceCommand.nextExercise,
        rawText: text,
      );
    }

    // "Previous exercise" / "back" / "go back"
    if (_matches(lower, ['previous exercise', 'previous', 'go back', 'back'])) {
      return VoiceCommandResult(
        command: VoiceCommand.previousExercise,
        rawText: text,
      );
    }

    return VoiceCommandResult(
      command: VoiceCommand.unknown,
      rawText: text,
    );
  }

  /// Check if the input matches any of the patterns.
  static bool _matches(String input, List<String> patterns) {
    return patterns.any((p) => input.contains(p));
  }

  /// Extract a number of seconds from the input (e.g., "add 30 seconds" → 30).
  static int _extractSeconds(String input) {
    final regex = RegExp(r'(\d+)\s*second');
    final match = regex.firstMatch(input);
    if (match != null) {
      return int.tryParse(match.group(1)!) ?? 30;
    }
    return 30; // Default to 30 seconds
  }

  /// Dispose of resources.
  static Future<void> dispose() async {
    await stopListening();
    await _tts.stop();
    _isInitialized = false;
  }
}
