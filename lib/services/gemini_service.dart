import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

/// Wrapper around the Google Generative AI SDK (Gemini).
///
/// Uses the user's own API key (BYOA model) to access Gemini 1.5 Flash
/// for Machine ID, form analysis, and coaching features.
class GeminiService {
  static GenerativeModel? _model;
  static GenerativeModel? _visionModel;
  static String? _currentModelName;
  static final Set<String> _blacklistedModels = {};

  /// Initialize the Gemini client with the user's API key.
  static Future<bool> initialize({bool forceRefresh = false}) async {
    final apiKey = await AuthService.getApiKey();
    if (apiKey == null || apiKey.isEmpty) return false;

    if (!forceRefresh && _model != null) return true;

    // Discover the best available model (excluding blacklisted ones)
    final bestModel = await _discoverBestModel(apiKey);
    _currentModelName = bestModel;
    debugPrint('Discovered best model: $bestModel');

    _model = GenerativeModel(
      model: bestModel,
      apiKey: apiKey,
    );
    _visionModel = GenerativeModel(
      model: bestModel,
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
      ),
    );
    return true;
  }

  /// Internal helper to find the most capable model available to this key.
  static Future<String> _discoverBestModel(String apiKey) async {
    try {
      final response = await http.get(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final models = data['models'] as List;
        
        // Priority list per user request (3.1 -> 3.0 -> 2.5 -> 2.0 -> 1.5)
        final families = [
          'gemini-3.1',
          'gemini-3.0',
          'gemini-2.5',
          'gemini-2.0',
          'gemini-1.5',
        ];

        // First, look for the most specific/latest version that supports generation
        for (final family in families) {
          final bestMatch = models.firstWhere(
            (m) => (m['name'] as String).contains(family) && 
                   (m['supportedGenerationMethods'] as List).contains('generateContent') &&
                   !_blacklistedModels.contains(m['name']),
            orElse: () => null,
          );
          if (bestMatch != null) return bestMatch['name'];
        }
        
        // Fallback to any model that supports generation (not blacklisted)
        final fallback = models.firstWhere(
          (m) => (m['supportedGenerationMethods'] as List).contains('generateContent') &&
                 !_blacklistedModels.contains(m['name'] as String),
          orElse: () => null,
        );
        if (fallback != null) return fallback['name'];
      }
    } catch (e) {
      debugPrint('Model discovery error: $e');
    }
    
    // Safety fallback
    return 'models/gemini-1.5-flash';
  }

  /// Whether the Gemini client is ready.
  static bool get isReady => _model != null;

  /// Dispose of the client when signing out.
  static void dispose() {
    _model = null;
    _visionModel = null;
  }

  // ─── Machine ID (P0.2) ────────────────────────

  /// Identify a gym machine from an image and suggest exercises.
  ///
  /// Returns a structured response or throws an exception with a descriptive message.
  static Future<MachineIdResult?> identifyMachine(Uint8List imageBytes, {int retryCount = 0}) async {
    if (_visionModel == null) {
      await initialize();
    }
    if (_visionModel == null) {
      throw Exception('AI not initialized. Please check your API key.');
    }

    try {
      final prompt = TextPart('''
        Analyze this image of a gym machine and return a JSON object.
        Identify the equipment and suggest 3-4 exercises.
        
        Return the response in this exact JSON schema:
          "machineName": "string",
          "exercises": [
            {
              "name": "string",
              "muscleGroup": "glutes | quads | hamstrings | core | chest | back | shoulders | arms",
              "sets": number,
              "reps": number,
              "formCue": "string",
              "youtubeSearchQuery": "string"
            }
          ]
        }
        
        Important: The 'youtubeSearchQuery' should be a perfect search string like '[Exercise Name] gym form tutorial'.
      ''');

      final imagePart = DataPart('image/jpeg', imageBytes);
      final response = await _visionModel!.generateContent([
        Content.multi([prompt, imagePart]),
      ]);

      final text = response.text;
      if (text == null || text.isEmpty) {
        throw Exception('AI returned an empty response. Try a different angle.');
      }

      return MachineIdResult.fromJson(text);
    } catch (e) {
      final errorStr = e.toString();
      debugPrint('Gemini Machine ID error: $errorStr');

      // Handle Quota/Limit issues with automatic failover
      if ((errorStr.contains('quota') || errorStr.contains('limit') || errorStr.contains('429')) && retryCount < 3) {
        debugPrint('Quota exceeded for $_currentModelName. Attempting fallback...');
        if (_currentModelName != null) {
          _blacklistedModels.add(_currentModelName!);
        }
        await initialize(forceRefresh: true);
        return identifyMachine(imageBytes, retryCount: retryCount + 1);
      }

      if (errorStr.contains('Safety')) {
        throw Exception('Gemini safety filters blocked this image. Ensure no people are visible.');
      }
      if (errorStr.contains('API_KEY_INVALID')) {
        throw Exception('Invalid API Key. Please update it in Settings.');
      }
      throw Exception('Analysis failed: $errorStr');
    }
  }

  // ─── Coaching Summary (P1.5) ──────────────────

  /// Generate a coaching summary from workout history context.
  static Future<String?> generateCoachingSummary(String contextPrompt) async {
    if (_model == null) return null;

    try {
      final response = await _model!.generateContent([
        Content.text(contextPrompt),
      ]);
      return response.text;
    } catch (e) {
      debugPrint('Gemini coaching error: $e');
      return null;
    }
  }

  // ─── General text generation ──────────────────

  /// General-purpose text generation.
  static Future<String?> generate(String prompt) async {
    if (_model == null) return null;

    try {
      final response = await _model!.generateContent([
        Content.text(prompt),
      ]);
      return response.text;
    } catch (e) {
      debugPrint('Gemini generate error: $e');
      return null;
    }
  }

  /// List all models available to the current API key via REST.
  static Future<String> listAvailableModels() async {
    final apiKey = await AuthService.getApiKey();
    if (apiKey == null || apiKey.isEmpty) return 'No API Key found.';

    try {
      final response = await http.get(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey'),
      );

      if (response.statusCode != 200) {
        return 'API Error (${response.statusCode}): ${response.body}';
      }

      final data = jsonDecode(response.body);
      final models = data['models'] as List;
      final buffer = StringBuffer('Authorized Models for your Key:\n');
      
      for (final m in models) {
        final name = m['name'];
        final methods = (m['supportedGenerationMethods'] as List).join(", ");
        final isBlacklisted = _blacklistedModels.contains(name);
        buffer.writeln('• $name ${isBlacklisted ? "[BLACKLISTED - NO QUOTA]" : ""}\n  Methods: $methods');
      }
      return buffer.toString();
    } catch (e) {
      return 'Connection failed: $e';
    }
  }
}

// ──────────────────────────────────────────────────────────────
//  Machine ID Result Model
// ──────────────────────────────────────────────────────────────

class MachineIdResult {
  final String machineName;
  final List<SuggestedExercise> exercises;

  const MachineIdResult({
    required this.machineName,
    required this.exercises,
  });

  /// Parse the JSON Gemini response into a result object.
  static MachineIdResult? fromJson(String jsonString) {
    try {
      final Map<String, dynamic> data = jsonDecode(jsonString);
      
      final exercises = (data['exercises'] as List).map((e) => SuggestedExercise(
        name: e['name'] ?? 'Unknown Exercise',
        muscleGroup: e['muscleGroup'] ?? 'full_body',
        sets: (e['sets'] as num?)?.toInt() ?? 3,
        reps: (e['reps'] as num?)?.toInt() ?? 12,
        formCue: e['formCue'] ?? 'Follow standard safety procedures.',
        youtubeSearchQuery: e['youtubeSearchQuery'] ?? (e['name'] != null ? '${e['name']} exercise' : null),
      )).toList();

      return MachineIdResult(
        machineName: data['machineName'] ?? 'Unknown Machine',
        exercises: exercises,
      );
    } catch (e) {
      debugPrint('Error parsing Machine ID JSON: $e');
      throw Exception('AI returned invalid data format.');
    }
  }
}

class SuggestedExercise {
  final String name;
  final String muscleGroup;
  final int sets;
  final int reps;
  final String formCue;
  final String? youtubeSearchQuery;
  String? videoId; // To be populated via search later
  SuggestedExercise({
    required this.name,
    required this.muscleGroup,
    required this.sets,
    required this.reps,
    required this.formCue,
    this.youtubeSearchQuery,
    this.videoId,
  });
}
