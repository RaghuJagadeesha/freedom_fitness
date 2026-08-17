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
  final String? equipmentType;
  final String? gifUrl;
  final bool isUserAdded;

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
    this.equipmentType,
    this.gifUrl,
    this.isUserAdded = false,
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
    String? equipmentType,
    String? gifUrl,
    bool? isUserAdded,
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
      equipmentType: equipmentType ?? this.equipmentType,
      gifUrl: gifUrl ?? this.gifUrl,
      isUserAdded: isUserAdded ?? this.isUserAdded,
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
    'equipmentType': equipmentType,
    'gifUrl': gifUrl,
    'isUserAdded': isUserAdded,
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
    equipmentType: json['equipmentType'],
    gifUrl: json['gifUrl'],
    isUserAdded: json['isUserAdded'] ?? false,
  );
}

// ──────────────────────────────────────────────────────────────
//  Workout Split Type (3, 4, or 5-day)
// ──────────────────────────────────────────────────────────────

enum WorkoutSplitType { split3, split4, split5 }

extension WorkoutSplitTypeExt on WorkoutSplitType {
  String get label {
    switch (this) {
      case WorkoutSplitType.split3: return '3-Day Split';
      case WorkoutSplitType.split4: return '4-Day Split';
      case WorkoutSplitType.split5: return '5-Day Split';
    }
  }
  String get subtitle {
    switch (this) {
      case WorkoutSplitType.split3: return 'Upper / Lower / Full Body';
      case WorkoutSplitType.split4: return 'Upper Push / Lower / Upper Pull / Full Body';
      case WorkoutSplitType.split5: return 'Chest & Tris / Back & Bis / Legs / Shoulders & Core / Full Body';
    }
  }
  int get dayCount {
    switch (this) {
      case WorkoutSplitType.split3: return 3;
      case WorkoutSplitType.split4: return 4;
      case WorkoutSplitType.split5: return 5;
    }
  }
}

// ──────────────────────────────────────────────────────────────
//  Split Day (metadata for one day in a split)
// ──────────────────────────────────────────────────────────────

class SplitDay {
  final String id;
  final String label;
  final String subtitle;
  final WorkoutSplitType splitType;
  final int dayIndex;

  const SplitDay({
    required this.id,
    required this.label,
    required this.subtitle,
    required this.splitType,
    required this.dayIndex,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'subtitle': subtitle,
    'splitType': splitType.index,
    'dayIndex': dayIndex,
  };

  factory SplitDay.fromJson(Map<String, dynamic> json) => SplitDay(
    id: json['id'],
    label: json['label'],
    subtitle: json['subtitle'],
    splitType: WorkoutSplitType.values[json['splitType']],
    dayIndex: json['dayIndex'],
  );
}

// ──────────────────────────────────────────────────────────────
//  Workout Block Enum
// ──────────────────────────────────────────────────────────────

enum WorkoutBlock { primer, blockA, blockB, blockC }

extension WorkoutBlockExt on WorkoutBlock {
  String get label {
    switch (this) {
      case WorkoutBlock.primer: return 'Primer';
      case WorkoutBlock.blockA: return 'Block A';
      case WorkoutBlock.blockB: return 'Block B (Giant Set)';
      case WorkoutBlock.blockC: return 'Block C';
    }
  }
}

// ──────────────────────────────────────────────────────────────
//  Exercise Slot (ties an exercise to a block with metadata)
// ──────────────────────────────────────────────────────────────

class ExerciseSlot {
  final Exercise exercise;
  final WorkoutBlock block;
  final bool isAlternative;
  final String? easierAlternativeId;
  final bool isGiantSetMember;

  const ExerciseSlot({
    required this.exercise,
    required this.block,
    this.isAlternative = false,
    this.easierAlternativeId,
    this.isGiantSetMember = false,
  });

  ExerciseSlot copyWith({Exercise? exercise}) {
    return ExerciseSlot(
      exercise: exercise ?? this.exercise,
      block: block,
      isAlternative: isAlternative,
      easierAlternativeId: easierAlternativeId,
      isGiantSetMember: isGiantSetMember,
    );
  }
}

// ──────────────────────────────────────────────────────────────
//  Queue State (flexible rolling queue for 3/4/5-day splits)
// ──────────────────────────────────────────────────────────────

class QueueState {
  final WorkoutSplitType splitType;
  final int nextDayIndex;
  final DateTime? lastWorkoutDate;
  final int? lastDayIndex;
  final List<int> totalWorkoutsByDay;

  const QueueState({
    this.splitType = WorkoutSplitType.split3,
    this.nextDayIndex = 0,
    this.lastWorkoutDate,
    this.lastDayIndex,
    this.totalWorkoutsByDay = const [0, 0, 0],
  });

  int get dayCount => splitType.dayCount;

  List<int> get normalizedCounts {
    final list = List<int>.from(totalWorkoutsByDay);
    while (list.length < dayCount) list.add(0);
    while (list.length > dayCount) list.removeLast();
    return list;
  }

  int getTotalWorkoutsForDay(int dayIndex) {
    final counts = normalizedCounts;
    if (dayIndex < 0 || dayIndex >= counts.length) return 0;
    return counts[dayIndex];
  }

  int get totalWorkouts => normalizedCounts.fold(0, (a, b) => a + b);

  QueueState advance(int completedDayIndex) {
    final counts = normalizedCounts;
    counts[completedDayIndex] = counts[completedDayIndex] + 1;
    return QueueState(
      splitType: splitType,
      nextDayIndex: (completedDayIndex + 1) % dayCount,
      lastWorkoutDate: DateTime.now(),
      lastDayIndex: completedDayIndex,
      totalWorkoutsByDay: counts,
    );
  }

  Map<String, dynamic> toJson() => {
    'splitType': splitType.index,
    'nextDayIndex': nextDayIndex,
    'lastWorkoutDate': lastWorkoutDate?.toIso8601String(),
    'lastDayIndex': lastDayIndex,
    'totalWorkoutsByDay': normalizedCounts,
  };

  factory QueueState.fromJson(Map<String, dynamic> json) => QueueState(
    splitType: WorkoutSplitType.values[json['splitType'] ?? 0],
    nextDayIndex: json['nextDayIndex'] ?? 0,
    lastWorkoutDate: json['lastWorkoutDate'] != null
        ? DateTime.parse(json['lastWorkoutDate'])
        : null,
    lastDayIndex: json['lastDayIndex'],
    totalWorkoutsByDay: (json['totalWorkoutsByDay'] as List<dynamic>?)
        ?.map((e) => e as int)
        .toList() ?? [0, 0, 0],
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
  final int restSeconds;

  const SetLog({
    required this.setNumber,
    required this.weight,
    required this.repsCompleted,
    this.isDropSet = false,
    this.dropSetWeight,
    this.restSeconds = 0,
  });

  SetLog copyWith({
    int? setNumber,
    double? weight,
    int? repsCompleted,
    bool? isDropSet,
    double? dropSetWeight,
    int? restSeconds,
  }) {
    return SetLog(
      setNumber: setNumber ?? this.setNumber,
      weight: weight ?? this.weight,
      repsCompleted: repsCompleted ?? this.repsCompleted,
      isDropSet: isDropSet ?? this.isDropSet,
      dropSetWeight: dropSetWeight ?? this.dropSetWeight,
      restSeconds: restSeconds ?? this.restSeconds,
    );
  }

  Map<String, dynamic> toJson() => {
    'setNumber': setNumber,
    'weight': weight,
    'repsCompleted': repsCompleted,
    'isDropSet': isDropSet,
    'dropSetWeight': dropSetWeight,
    'restSeconds': restSeconds,
  };

  factory SetLog.fromJson(Map<String, dynamic> json) => SetLog(
    setNumber: json['setNumber'],
    weight: (json['weight'] as num).toDouble(),
    repsCompleted: json['repsCompleted'],
    isDropSet: json['isDropSet'] ?? false,
    dropSetWeight: json['dropSetWeight'] != null
        ? (json['dropSetWeight'] as num).toDouble()
        : null,
    restSeconds: json['restSeconds'] ?? 0,
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
  final int restSeconds; // rest taken between finishing this exercise and starting the next
  final int elapsedSeconds; // true time spent on the exercise (from opening to completion)
  final DateTime? startedAt;
  final DateTime? completedAt;

  const ExerciseLog({
    required this.exerciseId,
    required this.exerciseName,
    this.sets = const [],
    this.difficulty,
    this.notes = '',
    this.restSeconds = 0,
    this.elapsedSeconds = 0,
    this.startedAt,
    this.completedAt,
  });

  double get maxWeight =>
      sets.isEmpty ? 0 : sets.map((s) => s.weight).reduce((a, b) => a > b ? a : b);

  int get totalReps => sets.fold(0, (sum, s) => sum + s.repsCompleted);

  bool get hasDropSet => sets.any((s) => s.isDropSet);

  int get totalRestSeconds =>
      restSeconds + sets.fold(0, (sum, s) => sum + s.restSeconds);

  /// Computes the true total duration in seconds.
  /// Uses completedAt - startedAt if completed, or DateTime.now() - startedAt if in progress.
  /// Falls back to elapsedSeconds.
  int get activeElapsedSeconds {
    if (startedAt != null) {
      final end = completedAt ?? DateTime.now();
      final diff = end.difference(startedAt!).inSeconds;
      return diff > elapsedSeconds ? diff : elapsedSeconds;
    }
    return elapsedSeconds;
  }

  ExerciseLog copyWith({
    List<SetLog>? sets,
    Difficulty? difficulty,
    String? notes,
    int? restSeconds,
    int? elapsedSeconds,
    DateTime? startedAt,
    DateTime? completedAt,
  }) {
    return ExerciseLog(
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      sets: sets ?? this.sets,
      difficulty: difficulty ?? this.difficulty,
      notes: notes ?? this.notes,
      restSeconds: restSeconds ?? this.restSeconds,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'exerciseId': exerciseId,
    'exerciseName': exerciseName,
    'sets': sets.map((s) => s.toJson()).toList(),
    'difficulty': difficulty?.index,
    'notes': notes,
    'restSeconds': restSeconds,
    'elapsedSeconds': elapsedSeconds,
    'startedAt': startedAt?.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
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
    restSeconds: json['restSeconds'] ?? 0,
    elapsedSeconds: json['elapsedSeconds'] ?? 0,
    startedAt: json['startedAt'] != null ? DateTime.tryParse(json['startedAt']) : null,
    completedAt: json['completedAt'] != null ? DateTime.tryParse(json['completedAt']) : null,
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

class WorkoutTimerState {
  final int elapsedSeconds;
  final int remainingSeconds;
  final bool isHardStopTriggered;
  final bool isTimeUp;
  final bool primerDone;
  final bool skipAlternatives;
  final bool isPaused;
  final WorkoutBlock currentBlock;
  final String? lastOverrideReason;
  final int extensionMinutes;

  const WorkoutTimerState({
    this.elapsedSeconds = 0,
    this.remainingSeconds = 3600,
    this.isHardStopTriggered = false,
    this.isTimeUp = false,
    this.primerDone = false,
    this.skipAlternatives = false,
    this.isPaused = false,
    this.currentBlock = WorkoutBlock.primer,
    this.lastOverrideReason,
    this.extensionMinutes = 0,
  });

  int get totalDuration => 3600 + extensionMinutes * 60;
  int get elapsedMinutes => elapsedSeconds ~/ 60;
  int get remainingMinutes => remainingSeconds ~/ 60;
  int get remainingSecs => remainingSeconds % 60;
  bool get isFinal10 => remainingSeconds <= 600 && remainingSeconds > 0;
  bool get canExtend => extensionMinutes == 0;

  WorkoutTimerState copyWith({
    int? elapsedSeconds,
    int? remainingSeconds,
    bool? isHardStopTriggered,
    bool? isTimeUp,
    bool? primerDone,
    bool? skipAlternatives,
    bool? isPaused,
    WorkoutBlock? currentBlock,
    String? lastOverrideReason,
    int? extensionMinutes,
  }) {
    return WorkoutTimerState(
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      isHardStopTriggered: isHardStopTriggered ?? this.isHardStopTriggered,
      isTimeUp: isTimeUp ?? this.isTimeUp,
      primerDone: primerDone ?? this.primerDone,
      skipAlternatives: skipAlternatives ?? this.skipAlternatives,
      isPaused: isPaused ?? this.isPaused,
      currentBlock: currentBlock ?? this.currentBlock,
      lastOverrideReason: lastOverrideReason ?? this.lastOverrideReason,
      extensionMinutes: extensionMinutes ?? this.extensionMinutes,
    );
  }

  Map<String, dynamic> toJson() => {
    'elapsedSeconds': elapsedSeconds,
    'remainingSeconds': remainingSeconds,
    'isHardStopTriggered': isHardStopTriggered,
    'isTimeUp': isTimeUp,
    'primerDone': primerDone,
    'skipAlternatives': skipAlternatives,
    'isPaused': isPaused,
    'currentBlock': currentBlock.index,
    'lastOverrideReason': lastOverrideReason,
    'extensionMinutes': extensionMinutes,
  };

  factory WorkoutTimerState.fromJson(Map<String, dynamic> json) =>
      WorkoutTimerState(
        elapsedSeconds: json['elapsedSeconds'] ?? 0,
        remainingSeconds: json['remainingSeconds'] ?? 3600,
        isHardStopTriggered: json['isHardStopTriggered'] ?? false,
        isTimeUp: json['isTimeUp'] ?? false,
        primerDone: json['primerDone'] ?? false,
        skipAlternatives: json['skipAlternatives'] ?? false,
        isPaused: json['isPaused'] ?? false,
        currentBlock: WorkoutBlock.values[json['currentBlock'] ?? 0],
        lastOverrideReason: json['lastOverrideReason'],
        extensionMinutes: json['extensionMinutes'] ?? 0,
      );
}

/// A persisted snapshot of the timer: the timer state plus when it was saved,
/// so elapsed time can be recomputed after a crash/restart.
class TimerSnapshot {
  final WorkoutTimerState state;
  final DateTime savedAt;
  const TimerSnapshot({required this.state, required this.savedAt});
}

class WorkoutSession {
  final String id;
  final DateTime date;
  final WorkoutSplitType splitType;
  final int dayIndex;
  final String dayLabel;
  final String daySubtitle;
  final bool wasOverridden;
  final OverrideReason? overrideReason;
  final String? overrideNotes;
  final List<ExerciseLog> exercises;
  final int durationMinutes;
  final bool completed;

  const WorkoutSession({
    required this.id,
    required this.date,
    required this.splitType,
    required this.dayIndex,
    required this.dayLabel,
    this.daySubtitle = '',
    this.wasOverridden = false,
    this.overrideReason,
    this.overrideNotes,
    this.exercises = const [],
    this.durationMinutes = 0,
    this.completed = false,
  });

  ExerciseLog? getLogFor(String exerciseId) {
    for (final e in exercises) {
      if (e.exerciseId == exerciseId) return e;
    }
    return null;
  }

  WorkoutSession copyWith({
    List<ExerciseLog>? exercises,
    int? durationMinutes,
    bool? completed,
  }) {
    return WorkoutSession(
      id: id,
      date: date,
      splitType: splitType,
      dayIndex: dayIndex,
      dayLabel: dayLabel,
      daySubtitle: daySubtitle,
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
    'splitType': splitType.index,
    'dayIndex': dayIndex,
    'dayLabel': dayLabel,
    'daySubtitle': daySubtitle,
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
    splitType: WorkoutSplitType.values[json['splitType'] ?? 0],
    dayIndex: json['dayIndex'] ?? 0,
    dayLabel: json['dayLabel'] ?? '',
    daySubtitle: json['daySubtitle'] ?? '',
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

enum FloaterType { tennis, run, other }

extension FloaterTypeExt on FloaterType {
  String get label {
    switch (this) {
      case FloaterType.tennis: return '🎾 Tennis';
      case FloaterType.run: return '🏃 Run';
      case FloaterType.other: return '📋 Other';
    }
  }
}

class FloaterLog {
  final String id;
  final DateTime date;
  final FloaterType type;
  final int durationMinutes;
  final String? distance;     // miles, for runs
  final String? setsPlayed;   // e.g. "2/3", for tennis
  final String? customName;   // activity name, for "other"
  final String notes;

  const FloaterLog({
    required this.id,
    required this.date,
    required this.type,
    this.durationMinutes = 0,
    this.distance,
    this.setsPlayed,
    this.customName,
    this.notes = '',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'type': type.index,
    'durationMinutes': durationMinutes,
    'distance': distance,
    'setsPlayed': setsPlayed,
    'customName': customName,
    'notes': notes,
  };

  factory FloaterLog.fromJson(Map<String, dynamic> json) => FloaterLog(
    id: json['id'],
    date: DateTime.parse(json['date']),
    type: FloaterType.values[json['type']],
    durationMinutes: json['durationMinutes'] ?? 0,
    distance: json['distance'] as String?,
    setsPlayed: json['setsPlayed'] as String?,
    customName: json['customName'] as String?,
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

// ──────────────────────────────────────────────────────────────
//  Custom Swap / Custom Exercise
// ──────────────────────────────────────────────────────────────

class CustomSwap {
  String exerciseName;
  final String replacedExerciseId;
  Exercise exercise;
  CustomSwap({
    required this.exerciseName,
    required this.replacedExerciseId,
    required this.exercise,
  });
}
