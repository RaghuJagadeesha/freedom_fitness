import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database.dart';
import '../models/models.dart';
import '../data/seed_data.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

// ──────────────────────────────────────────────────────────────
//  Queue State Provider
// ──────────────────────────────────────────────────────────────

class QueueNotifier extends StateNotifier<QueueState> {
  QueueNotifier() : super(Database.getQueueState());

  WorkoutType get suggestedWorkout => state.suggestedWorkout;

  Future<void> completeWorkout(WorkoutType type) async {
    state = state.advance(type);
    await Database.saveQueueState(state);
  }
}

final queueProvider = StateNotifierProvider<QueueNotifier, QueueState>((ref) {
  return QueueNotifier();
});

// ──────────────────────────────────────────────────────────────
//  Active Workout Session Provider
// ──────────────────────────────────────────────────────────────

class ActiveWorkoutNotifier extends StateNotifier<WorkoutSession?> {
  final Ref ref;

  ActiveWorkoutNotifier(this.ref) : super(null);

  void startWorkout({
    required WorkoutType suggestedType,
    required WorkoutType actualType,
    OverrideReason? overrideReason,
    String? overrideNotes,
  }) {
    final exercises = SeedData.getWorkoutExercises(actualType);
    state = WorkoutSession(
      id: _uuid.v4(),
      date: DateTime.now(),
      suggestedType: suggestedType,
      actualType: actualType,
      wasOverridden: suggestedType != actualType,
      overrideReason: overrideReason,
      overrideNotes: overrideNotes,
      exercises: exercises.map((e) => ExerciseLog(
        exerciseId: e.id,
        exerciseName: e.name,
      )).toList(),
    );
  }

  void logSet(int exerciseIndex, SetLog setLog) {
    if (state == null) return;
    final exercises = List<ExerciseLog>.from(state!.exercises);
    final exercise = exercises[exerciseIndex];
    exercises[exerciseIndex] = exercise.copyWith(
      sets: [...exercise.sets, setLog],
    );
    state = state!.copyWith(exercises: exercises);
  }

  void rateExercise(int exerciseIndex, Difficulty difficulty) {
    if (state == null) return;
    final exercises = List<ExerciseLog>.from(state!.exercises);
    exercises[exerciseIndex] = exercises[exerciseIndex].copyWith(
      difficulty: difficulty,
    );
    state = state!.copyWith(exercises: exercises);
  }

  Future<void> completeWorkout(int durationMinutes) async {
    if (state == null) return;
    final completed = state!.copyWith(
      completed: true,
      durationMinutes: durationMinutes,
    );
    await Database.saveSession(completed);

    // Advance the queue
    await ref.read(queueProvider.notifier).completeWorkout(completed.actualType);

    // Update user progress for each exercise
    for (final exerciseLog in completed.exercises) {
      if (exerciseLog.sets.isNotEmpty) {
        await _updateProgress(exerciseLog);
      }
    }

    state = null;
  }

  Future<void> _updateProgress(ExerciseLog log) async {
    var progress = Database.getProgress(log.exerciseId) ??
        UserProgress(exerciseId: log.exerciseId);

    final maxWeight = log.maxWeight;
    final newHistory = [
      ...progress.weightHistory,
      WeightEntry(date: DateTime.now(), weight: maxWeight),
    ];

    int easySessions = progress.consecutiveEasySessions;
    if (log.difficulty == Difficulty.easy) {
      easySessions++;
    } else {
      easySessions = 0;
    }

    progress = progress.copyWith(
      currentWeight: maxWeight > 0 ? maxWeight : progress.currentWeight,
      weightHistory: newHistory,
      totalTimesPerformed: progress.totalTimesPerformed + 1,
      consecutiveEasySessions: easySessions,
    );

    await Database.saveProgress(progress);
  }

  void cancelWorkout() {
    state = null;
  }
}

final activeWorkoutProvider =
    StateNotifierProvider<ActiveWorkoutNotifier, WorkoutSession?>((ref) {
  return ActiveWorkoutNotifier(ref);
});

// ──────────────────────────────────────────────────────────────
//  Workout History Provider
// ──────────────────────────────────────────────────────────────

final workoutHistoryProvider = Provider<List<WorkoutSession>>((ref) {
  // Re-read when queue changes (workout completed)
  ref.watch(queueProvider);
  return Database.getAllSessions();
});

// ──────────────────────────────────────────────────────────────
//  User Progress Provider
// ──────────────────────────────────────────────────────────────

final userProgressProvider = Provider<Map<String, UserProgress>>((ref) {
  ref.watch(queueProvider);
  return Database.getAllProgress();
});

// ──────────────────────────────────────────────────────────────
//  Morning Routine Provider
// ──────────────────────────────────────────────────────────────

class MorningRoutineNotifier extends StateNotifier<MorningRoutineState> {
  MorningRoutineNotifier() : super(Database.getMorningState()) {
    // Reset if it's a new day
    if (!state.isCompletedToday) {
      state = const MorningRoutineState();
    }
  }

  void toggleHydration() {
    state = state.copyWith(hydrationDone: !state.hydrationDone);
    _checkCompletion();
  }

  void toggleCouchStretch() {
    state = state.copyWith(couchStretchDone: !state.couchStretchDone);
    _checkCompletion();
  }

  void toggleCatCow() {
    state = state.copyWith(catCowDone: !state.catCowDone);
    _checkCompletion();
  }

  void toggleGluteBridges() {
    state = state.copyWith(gluteBridgesDone: !state.gluteBridgesDone);
    _checkCompletion();
  }

  void _checkCompletion() {
    if (state.allDone) {
      state = state.copyWith(lastCompletedDate: DateTime.now());
    }
    Database.saveMorningState(state);
  }
}

final morningRoutineProvider =
    StateNotifierProvider<MorningRoutineNotifier, MorningRoutineState>((ref) {
  return MorningRoutineNotifier();
});

// ──────────────────────────────────────────────────────────────
//  Floater Provider
// ──────────────────────────────────────────────────────────────

class FloaterNotifier extends StateNotifier<List<FloaterLog>> {
  FloaterNotifier() : super(Database.getAllFloaters());

  Future<void> logFloater(FloaterType type, int durationMinutes, String notes) async {
    final floater = FloaterLog(
      id: _uuid.v4(),
      date: DateTime.now(),
      type: type,
      durationMinutes: durationMinutes,
      notes: notes,
    );
    await Database.saveFloater(floater);
    state = Database.getAllFloaters();
  }
}

final floaterProvider =
    StateNotifierProvider<FloaterNotifier, List<FloaterLog>>((ref) {
  return FloaterNotifier();
});

// ──────────────────────────────────────────────────────────────
//  Timer Provider (for rest between sets)
// ──────────────────────────────────────────────────────────────

final restTimerDurationProvider = StateProvider<int>((ref) {
  return Database.getRestTimer();
});

// ──────────────────────────────────────────────────────────────
//  Weekly Stats
// ──────────────────────────────────────────────────────────────

final weeklyStatsProvider = Provider<Map<String, int>>((ref) {
  final sessions = ref.watch(workoutHistoryProvider);
  final floaters = ref.watch(floaterProvider);

  final now = DateTime.now();
  final weekStart = now.subtract(Duration(days: now.weekday - 1));
  final startOfWeek = DateTime(weekStart.year, weekStart.month, weekStart.day);

  final weekSessions = sessions.where(
    (s) => s.date.isAfter(startOfWeek) && s.completed,
  );
  final weekFloaters = floaters.where(
    (f) => f.date.isAfter(startOfWeek),
  );

  return {
    'gymSessions': weekSessions.length,
    'floaters': weekFloaters.length,
    'workoutA': weekSessions.where((s) => s.actualType == WorkoutType.a).length,
    'workoutB': weekSessions.where((s) => s.actualType == WorkoutType.b).length,
  };
});
