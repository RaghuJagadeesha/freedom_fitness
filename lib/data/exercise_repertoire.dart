import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/models.dart';

/// A single exercise pulled from the bundled exercises dataset
/// (hasaneyldrm/exercises-dataset, MIT).
class RepertoireExercise {
  final String id;
  final String name;
  final String bodyPart;
  final String equipment;
  final String target;
  final String description;
  final String gifUrl;

  const RepertoireExercise({
    required this.id,
    required this.name,
    required this.bodyPart,
    required this.equipment,
    required this.target,
    required this.description,
    required this.gifUrl,
  });

  factory RepertoireExercise.fromJson(Map<String, dynamic> json) {
    final instructions = json['instructions'] is Map
        ? Map<String, dynamic>.from(json['instructions'] as Map)
        : const <String, dynamic>{};
    final gif = json['gif_url'] as String? ?? '';
    return RepertoireExercise(
      id: 'dataset_${json['id']}',
      name: json['name'] as String? ?? 'Unknown',
      bodyPart: json['body_part'] as String? ?? 'other',
      equipment: json['equipment'] as String? ?? '',
      target: json['target'] as String? ?? '',
      description: (instructions['en'] as String?) ?? '',
      gifUrl: gif.startsWith('http')
          ? gif
          : 'https://raw.githubusercontent.com/hasaneyldrm/exercises-dataset/main/$gif',
    );
  }
}

/// Loads + caches the bundled exercise dataset.
class ExerciseRepertoire {
  static List<RepertoireExercise>? _cache;

  static Future<List<RepertoireExercise>> load() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString('assets/data/exercises.json');
    final list = jsonDecode(raw) as List<dynamic>;
    _cache = list
        .map((e) => RepertoireExercise.fromJson(e as Map<String, dynamic>))
        .toList();
    return _cache!;
  }

  /// Distinct body parts shown in the filter chips.
  static List<String> bodyParts(List<RepertoireExercise> all) {
    final seen = <String>{};
    for (final e in all) {
      seen.add(_titleCase(e.bodyPart));
    }
    final list = seen.toList()..sort();
    return list;
  }

  /// Distinct equipment types shown in the filter chips.
  static List<String> equipmentTypes(List<RepertoireExercise> all) {
    final seen = <String>{};
    for (final e in all) {
      if (e.equipment.isNotEmpty) seen.add(_titleCase(e.equipment));
    }
    final list = seen.toList()..sort();
    return list;
  }

  static String _titleCase(String s) {
    if (s.isEmpty) return s;
    final words = s.split(' ');
    return words
        .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  /// Convert a repertoire exercise into an app `Exercise` (custom, user-added)
  /// with sensible defaults for sets/reps.
  static Exercise toAppExercise(RepertoireExercise r) {
    return Exercise(
      id: r.id,
      name: r.name,
      category: _mapCategory(r),
      muscleGroup: _mapMuscleGroup(r.bodyPart),
      sets: 3,
      reps: 10,
      description: r.description.isEmpty
          ? '${r.bodyPart} • ${r.equipment} • ${r.target}'
          : r.description,
      equipmentType: r.equipment,
      gifUrl: r.gifUrl,
      isUserAdded: true,
    );
  }

  static ExerciseCategory _mapCategory(RepertoireExercise r) {
    if (r.equipment.toLowerCase() == 'body weight') {
      return ExerciseCategory.bodyweight;
    }
    if (r.bodyPart.toLowerCase() == 'cardio') {
      return ExerciseCategory.cardio;
    }
    const isolation = ['curl', 'raise', 'fly', 'extension', 'kickback',
      'lateral', 'crunch', 'leg raise', 'side bend', 'adduction',
      'abduction', 'row', 'face', 'pullover', 'pull-down', 'pulldown'];
    final lower = r.name.toLowerCase();
    if (isolation.any(lower.contains)) {
      return ExerciseCategory.isolation;
    }
    return ExerciseCategory.compound;
  }

  static MuscleGroup _mapMuscleGroup(String bodyPart) {
    switch (bodyPart.toLowerCase()) {
      case 'chest':
        return MuscleGroup.chest;
      case 'back':
        return MuscleGroup.back;
      case 'shoulders':
        return MuscleGroup.shoulders;
      case 'upper arms':
      case 'lower arms':
        return MuscleGroup.arms;
      case 'upper legs':
      case 'lower legs':
        return MuscleGroup.quads;
      case 'waist':
        return MuscleGroup.core;
      default:
        return MuscleGroup.fullBody;
    }
  }
}