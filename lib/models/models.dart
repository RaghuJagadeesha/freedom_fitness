// ──────────────────────────────────────────────────────────────
//  Exercise Model
// ──────────────────────────────────────────────────────────────

enum MuscleGroup { glutes, quads, hamstrings, core, chest, back, shoulders, arms, fullBody }
enum ExerciseCategory { compound, isolation, cardio, stretch, bodyweight }

class Exercise {
  final String id;
  final String name;
  final ExerciseCategory category;
  final MuscleGroup muscleGroup;
  final int sets;
  final int reps;            // 0 if duration-based
  final int durationSeconds; // 0 if rep-based
  final String? youtubeUrl;
  final String description;

  const Exercise({
    required this.id,
    required this.name,
    required this.category,
    required this.muscleGroup,
    required this.sets,
    this.reps = 0,
    this.durationSeconds = 0,
    this.youtubeUrl,
    this.description = '',
  });

  bool get isDurationBased => durationSeconds > 0;

  Exercise copyWith({
    String? id,
    String? name,
    ExerciseCategory? category,
    MuscleGroup? muscleGroup,
    int? sets,
    int? reps,
    int? durationSeconds,
    String? youtubeUrl,
    String? description,
  }) {
    return Exercise(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      muscleGroup: muscleGroup ?? this.muscleGroup,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      youtubeUrl: youtubeUrl ?? this.youtubeUrl,
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category.index,
    'muscleGroup': muscleGroup.index,
    'sets': sets,
    'reps': reps,
    'durationSeconds': durationSeconds,
    'youtubeUrl': youtubeUrl,
    'description': description,
  };

  factory Exercise.fromJson(Map<String, dynamic> json) => Exercise(
    id: json['id'],
    name: json['name'],
    category: ExerciseCategory.values[json['category']],
    muscleGroup: MuscleGroup.values[json['muscleGroup']],
    sets: json['sets'],
    reps: json['reps'] ?? 0,
    durationSeconds: json['durationSeconds'] ?? 0,
    youtubeUrl: json['youtubeUrl'],
    description: json['description'] ?? '',
  );
}

// ──────────────────────────────────────────────────────────────
//  Workout Type Enum
// ──────────────────────────────────────────────────────────────

enum WorkoutType { a, b }

extension WorkoutTypeExt on WorkoutType {
  String get label => this == WorkoutType.a ? 'Workout A' : 'Workout B';
  String get subtitle => this == WorkoutType.a
      ? 'Lower Body & Deep Core'
      : 'Upper Body & Power';
  WorkoutType get opposite =>
      this == WorkoutType.a ? WorkoutType.b : WorkoutType.a;
}

// ──────────────────────────────────────────────────────────────
//  Queue State
// ──────────────────────────────────────────────────────────────

class QueueState {
  final WorkoutType nextWorkout;
  final DateTime? lastWorkoutDate;
  final WorkoutType? lastWorkoutType;
  final int totalWorkoutsA;
  final int totalWorkoutsB;

  const QueueState({
    this.nextWorkout = WorkoutType.a,
    this.lastWorkoutDate,
    this.lastWorkoutType,
    this.totalWorkoutsA = 0,
    this.totalWorkoutsB = 0,
  });

  /// Auto-suggest: opposite of last completed workout
  WorkoutType get suggestedWorkout {
    if (lastWorkoutType == null) return WorkoutType.a;
    return lastWorkoutType!.opposite;
  }

  QueueState advance(WorkoutType completedType) {
    return QueueState(
      nextWorkout: completedType.opposite,
      lastWorkoutDate: DateTime.now(),
      lastWorkoutType: completedType,
      totalWorkoutsA: totalWorkoutsA + (completedType == WorkoutType.a ? 1 : 0),
      totalWorkoutsB: totalWorkoutsB + (completedType == WorkoutType.b ? 1 : 0),
    );
  }

  Map<String, dynamic> toJson() => {
    'nextWorkout': nextWorkout.index,
    'lastWorkoutDate': lastWorkoutDate?.toIso8601String(),
    'lastWorkoutType': lastWorkoutType?.index,
    'totalWorkoutsA': totalWorkoutsA,
    'totalWorkoutsB': totalWorkoutsB,
  };

  factory QueueState.fromJson(Map<String, dynamic> json) => QueueState(
    nextWorkout: WorkoutType.values[json['nextWorkout'] ?? 0],
    lastWorkoutDate: json['lastWorkoutDate'] != null
        ? DateTime.parse(json['lastWorkoutDate'])
        : null,
    lastWorkoutType: json['lastWorkoutType'] != null
        ? WorkoutType.values[json['lastWorkoutType']]
        : null,
    totalWorkoutsA: json['totalWorkoutsA'] ?? 0,
    totalWorkoutsB: json['totalWorkoutsB'] ?? 0,
  );
}

// ──────────────────────────────────────────────────────────────
//  Set Log
// ──────────────────────────────────────────────────────────────

class SetLog {
  final int setNumber;
  final double weight;
  final int repsCompleted;
  final bool isDropSet;
  final double? dropSetWeight;

  const SetLog({
    required this.setNumber,
    required this.weight,
    required this.repsCompleted,
    this.isDropSet = false,
    this.dropSetWeight,
  });

  Map<String, dynamic> toJson() => {
    'setNumber': setNumber,
    'weight': weight,
    'repsCompleted': repsCompleted,
    'isDropSet': isDropSet,
    'dropSetWeight': dropSetWeight,
  };

  factory SetLog.fromJson(Map<String, dynamic> json) => SetLog(
    setNumber: json['setNumber'],
    weight: (json['weight'] as num).toDouble(),
    repsCompleted: json['repsCompleted'],
    isDropSet: json['isDropSet'] ?? false,
    dropSetWeight: json['dropSetWeight'] != null
        ? (json['dropSetWeight'] as num).toDouble()
        : null,
  );
}

// ──────────────────────────────────────────────────────────────
//  Exercise Log (within a workout session)
// ──────────────────────────────────────────────────────────────

enum Difficulty { easy, moderate, hard }

class ExerciseLog {
  final String exerciseId;
  final String exerciseName;
  final List<SetLog> sets;
  final Difficulty? difficulty;
  final String notes;

  const ExerciseLog({
    required this.exerciseId,
    required this.exerciseName,
    this.sets = const [],
    this.difficulty,
    this.notes = '',
  });

  double get maxWeight =>
      sets.isEmpty ? 0 : sets.map((s) => s.weight).reduce((a, b) => a > b ? a : b);

  int get totalReps => sets.fold(0, (sum, s) => sum + s.repsCompleted);

  bool get hasDropSet => sets.any((s) => s.isDropSet);

  ExerciseLog copyWith({
    List<SetLog>? sets,
    Difficulty? difficulty,
    String? notes,
  }) {
    return ExerciseLog(
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      sets: sets ?? this.sets,
      difficulty: difficulty ?? this.difficulty,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
    'exerciseId': exerciseId,
    'exerciseName': exerciseName,
    'sets': sets.map((s) => s.toJson()).toList(),
    'difficulty': difficulty?.index,
    'notes': notes,
  };

  factory ExerciseLog.fromJson(Map<String, dynamic> json) => ExerciseLog(
    exerciseId: json['exerciseId'],
    exerciseName: json['exerciseName'],
    sets: (json['sets'] as List?)
        ?.map((s) => SetLog.fromJson(s as Map<String, dynamic>))
        .toList() ?? [],
    difficulty: json['difficulty'] != null
        ? Difficulty.values[json['difficulty']]
        : null,
    notes: json['notes'] ?? '',
  );
}

// ──────────────────────────────────────────────────────────────
//  Override Reason
// ──────────────────────────────────────────────────────────────

enum OverrideReason { soreness, injury, other }

extension OverrideReasonExt on OverrideReason {
  String get label {
    switch (this) {
      case OverrideReason.soreness: return '💪 Soreness';
      case OverrideReason.injury: return '🩹 Injury';
      case OverrideReason.other: return '📝 Other';
    }
  }
  String get icon {
    switch (this) {
      case OverrideReason.soreness: return '💪';
      case OverrideReason.injury: return '🩹';
      case OverrideReason.other: return '📝';
    }
  }
}

// ──────────────────────────────────────────────────────────────
//  Workout Session
// ──────────────────────────────────────────────────────────────

class WorkoutSession {
  final String id;
  final DateTime date;
  final WorkoutType suggestedType;
  final WorkoutType actualType;
  final bool wasOverridden;
  final OverrideReason? overrideReason;
  final String? overrideNotes;
  final List<ExerciseLog> exercises;
  final int durationMinutes;
  final bool completed;

  const WorkoutSession({
    required this.id,
    required this.date,
    required this.suggestedType,
    required this.actualType,
    this.wasOverridden = false,
    this.overrideReason,
    this.overrideNotes,
    this.exercises = const [],
    this.durationMinutes = 0,
    this.completed = false,
  });

  WorkoutSession copyWith({
    List<ExerciseLog>? exercises,
    int? durationMinutes,
    bool? completed,
  }) {
    return WorkoutSession(
      id: id,
      date: date,
      suggestedType: suggestedType,
      actualType: actualType,
      wasOverridden: wasOverridden,
      overrideReason: overrideReason,
      overrideNotes: overrideNotes,
      exercises: exercises ?? this.exercises,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      completed: completed ?? this.completed,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'suggestedType': suggestedType.index,
    'actualType': actualType.index,
    'wasOverridden': wasOverridden,
    'overrideReason': overrideReason?.index,
    'overrideNotes': overrideNotes,
    'exercises': exercises.map((e) => e.toJson()).toList(),
    'durationMinutes': durationMinutes,
    'completed': completed,
  };

  factory WorkoutSession.fromJson(Map<String, dynamic> json) => WorkoutSession(
    id: json['id'],
    date: DateTime.parse(json['date']),
    suggestedType: WorkoutType.values[json['suggestedType'] ?? 0],
    actualType: WorkoutType.values[json['actualType'] ?? 0],
    wasOverridden: json['wasOverridden'] ?? false,
    overrideReason: json['overrideReason'] != null
        ? OverrideReason.values[json['overrideReason']]
        : null,
    overrideNotes: json['overrideNotes'],
    exercises: (json['exercises'] as List?)
        ?.map((e) => ExerciseLog.fromJson(e as Map<String, dynamic>))
        .toList() ?? [],
    durationMinutes: json['durationMinutes'] ?? 0,
    completed: json['completed'] ?? false,
  );
}

// ──────────────────────────────────────────────────────────────
//  User Progress (per exercise)
// ──────────────────────────────────────────────────────────────

class WeightEntry {
  final DateTime date;
  final double weight;

  const WeightEntry({required this.date, required this.weight});

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'weight': weight,
  };

  factory WeightEntry.fromJson(Map<String, dynamic> json) => WeightEntry(
    date: DateTime.parse(json['date']),
    weight: (json['weight'] as num).toDouble(),
  );
}

class UserProgress {
  final String exerciseId;
  final double currentWeight;
  final List<WeightEntry> weightHistory;
  final DateTime? lastPromotionDate;
  final int totalTimesPerformed;
  final int consecutiveEasySessions;

  const UserProgress({
    required this.exerciseId,
    this.currentWeight = 0,
    this.weightHistory = const [],
    this.lastPromotionDate,
    this.totalTimesPerformed = 0,
    this.consecutiveEasySessions = 0,
  });

  UserProgress copyWith({
    double? currentWeight,
    List<WeightEntry>? weightHistory,
    DateTime? lastPromotionDate,
    int? totalTimesPerformed,
    int? consecutiveEasySessions,
  }) {
    return UserProgress(
      exerciseId: exerciseId,
      currentWeight: currentWeight ?? this.currentWeight,
      weightHistory: weightHistory ?? this.weightHistory,
      lastPromotionDate: lastPromotionDate ?? this.lastPromotionDate,
      totalTimesPerformed: totalTimesPerformed ?? this.totalTimesPerformed,
      consecutiveEasySessions: consecutiveEasySessions ?? this.consecutiveEasySessions,
    );
  }

  Map<String, dynamic> toJson() => {
    'exerciseId': exerciseId,
    'currentWeight': currentWeight,
    'weightHistory': weightHistory.map((w) => w.toJson()).toList(),
    'lastPromotionDate': lastPromotionDate?.toIso8601String(),
    'totalTimesPerformed': totalTimesPerformed,
    'consecutiveEasySessions': consecutiveEasySessions,
  };

  factory UserProgress.fromJson(Map<String, dynamic> json) => UserProgress(
    exerciseId: json['exerciseId'],
    currentWeight: (json['currentWeight'] as num?)?.toDouble() ?? 0,
    weightHistory: (json['weightHistory'] as List?)
        ?.map((w) => WeightEntry.fromJson(w as Map<String, dynamic>))
        .toList() ?? [],
    lastPromotionDate: json['lastPromotionDate'] != null
        ? DateTime.parse(json['lastPromotionDate'])
        : null,
    totalTimesPerformed: json['totalTimesPerformed'] ?? 0,
    consecutiveEasySessions: json['consecutiveEasySessions'] ?? 0,
  );
}

// ──────────────────────────────────────────────────────────────
//  Floater Log
// ──────────────────────────────────────────────────────────────

enum FloaterType { tennis, run }

extension FloaterTypeExt on FloaterType {
  String get label => this == FloaterType.tennis ? '🎾 Tennis' : '🏃 3-Mile Run';
}

class FloaterLog {
  final String id;
  final DateTime date;
  final FloaterType type;
  final int durationMinutes;
  final String notes;

  const FloaterLog({
    required this.id,
    required this.date,
    required this.type,
    this.durationMinutes = 0,
    this.notes = '',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'type': type.index,
    'durationMinutes': durationMinutes,
    'notes': notes,
  };

  factory FloaterLog.fromJson(Map<String, dynamic> json) => FloaterLog(
    id: json['id'],
    date: DateTime.parse(json['date']),
    type: FloaterType.values[json['type']],
    durationMinutes: json['durationMinutes'] ?? 0,
    notes: json['notes'] ?? '',
  );
}

// ──────────────────────────────────────────────────────────────
//  Morning Routine State
// ──────────────────────────────────────────────────────────────

class MorningRoutineState {
  final DateTime? lastCompletedDate;
  final bool hydrationDone;
  final bool couchStretchDone;
  final bool catCowDone;
  final bool gluteBridgesDone;

  const MorningRoutineState({
    this.lastCompletedDate,
    this.hydrationDone = false,
    this.couchStretchDone = false,
    this.catCowDone = false,
    this.gluteBridgesDone = false,
  });

  bool get isCompletedToday {
    if (lastCompletedDate == null) return false;
    final now = DateTime.now();
    return lastCompletedDate!.year == now.year &&
        lastCompletedDate!.month == now.month &&
        lastCompletedDate!.day == now.day;
  }

  bool get allDone => hydrationDone && couchStretchDone && catCowDone && gluteBridgesDone;

  MorningRoutineState copyWith({
    DateTime? lastCompletedDate,
    bool? hydrationDone,
    bool? couchStretchDone,
    bool? catCowDone,
    bool? gluteBridgesDone,
  }) {
    return MorningRoutineState(
      lastCompletedDate: lastCompletedDate ?? this.lastCompletedDate,
      hydrationDone: hydrationDone ?? this.hydrationDone,
      couchStretchDone: couchStretchDone ?? this.couchStretchDone,
      catCowDone: catCowDone ?? this.catCowDone,
      gluteBridgesDone: gluteBridgesDone ?? this.gluteBridgesDone,
    );
  }

  Map<String, dynamic> toJson() => {
    'lastCompletedDate': lastCompletedDate?.toIso8601String(),
    'hydrationDone': hydrationDone,
    'couchStretchDone': couchStretchDone,
    'catCowDone': catCowDone,
    'gluteBridgesDone': gluteBridgesDone,
  };

  factory MorningRoutineState.fromJson(Map<String, dynamic> json) => MorningRoutineState(
    lastCompletedDate: json['lastCompletedDate'] != null
        ? DateTime.parse(json['lastCompletedDate'])
        : null,
    hydrationDone: json['hydrationDone'] ?? false,
    couchStretchDone: json['couchStretchDone'] ?? false,
    catCowDone: json['catCowDone'] ?? false,
    gluteBridgesDone: json['gluteBridgesDone'] ?? false,
  );
}
