import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database.dart';
import '../models/models.dart';
import '../models/user_profile.dart';
import '../data/seed_data.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

// ──────────────────────────────────────────────────────────────
//  Split Preference Provider
// ──────────────────────────────────────────────────────────────

final splitPreferenceProvider = StateProvider<WorkoutSplitType>((ref) {
  return Database.getSplitPreference();
});

// ──────────────────────────────────────────────────────────────
//  Queue State Provider (flexible rolling queue)
// ──────────────────────────────────────────────────────────────

class QueueNotifier extends StateNotifier<QueueState> {
  QueueNotifier() : super(Database.getQueueState());

  int get suggestedDayIndex => state.nextDayIndex;

  SplitDay get suggestedDay => SeedData.getSplitDay(state.splitType, state.nextDayIndex);

  List<SplitDay> get allDays => SeedData.getDayMetadatas(state.splitType);

  Future<void> completeWorkout(int dayIndex) async {
    state = state.advance(dayIndex);
    await Database.saveQueueState(state);
  }

  Future<void> changeSplit(WorkoutSplitType newSplit) async {
    final newQueue = QueueState(splitType: newSplit, nextDayIndex: 0);
    state = newQueue;
    await Database.saveQueueState(newQueue);
    await Database.setSplitPreference(newSplit);
  }

  Future<void> overrideToDay(int dayIndex) async {
    // Just record it — override is stored in WorkoutSession, not QueueState
  }
}

final queueProvider = StateNotifierProvider<QueueNotifier, QueueState>((ref) {
  return QueueNotifier();
});

// ──────────────────────────────────────────────────────────────
//  60-Minute Workout Timer Provider
// ──────────────────────────────────────────────────────────────

class WorkoutTimerNotifier extends StateNotifier<WorkoutTimerState> {
  Timer? _ticker;
  DateTime? _startTime;

  WorkoutTimerNotifier() : super(const WorkoutTimerState());

  void startTimer() {
    _startTime = DateTime.now();
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  /// Rebuild the timer from a persisted snapshot, crediting elapsed wall-clock
  /// time since the snapshot was saved (unless the workout was paused).
  void restore(TimerSnapshot snapshot) {
    _ticker?.cancel();
    final snap = snapshot.state;
    var elapsed = snap.elapsedSeconds;
    if (!snap.isPaused && !snap.isTimeUp) {
      elapsed += DateTime.now().difference(snapshot.savedAt).inSeconds;
    }
    final total = snap.totalDuration;
    if (elapsed >= total) {
      state = snap.copyWith(
        elapsedSeconds: total,
        remainingSeconds: 0,
        isHardStopTriggered: true,
        isTimeUp: true,
        currentBlock: WorkoutBlock.blockC,
      );
      return;
    }
    _startTime = DateTime.now().subtract(Duration(seconds: elapsed));
    state = snap.copyWith(
      elapsedSeconds: elapsed,
      remainingSeconds: total - elapsed,
      isTimeUp: false,
    );
    if (!snap.isPaused) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    }
  }

  void _tick() {
    final elapsed = DateTime.now().difference(_startTime!).inSeconds;
    final totalDuration = state.totalDuration;
    final remaining = totalDuration - elapsed;
    if (remaining <= 0) {
      state = state.copyWith(
        elapsedSeconds: totalDuration,
        remainingSeconds: 0,
        isHardStopTriggered: true,
        isTimeUp: true,
        currentBlock: WorkoutBlock.blockC,
      );
      _ticker?.cancel();
      return;
    }
    state = state.copyWith(
      elapsedSeconds: elapsed,
      remainingSeconds: remaining,
      isHardStopTriggered: elapsed >= totalDuration - 600,
    );
  }

  void extendWorkout(int minutes) {
    _startTime = DateTime.now().subtract(Duration(seconds: state.elapsedSeconds));
    final totalDuration = 3600 + minutes * 60;
    final remaining = totalDuration - state.elapsedSeconds;
    state = state.copyWith(
      extensionMinutes: minutes,
      remainingSeconds: remaining,
      isHardStopTriggered: false,
      isTimeUp: false,
    );
  }

  int get elapsedSeconds => state.elapsedSeconds;
  bool get isHardStopTriggered => state.isHardStopTriggered;
  bool get isFinal10 => state.isFinal10;

  void setBlock(WorkoutBlock block) {
    state = state.copyWith(currentBlock: block);
  }

  void completePrimer() {
    state = state.copyWith(primerDone: true);
  }

  void triggerOverride(String reason) {
    state = state.copyWith(lastOverrideReason: reason);
  }

  void autoSkipAlternatives() {
    state = state.copyWith(skipAlternatives: true);
  }

  void pause() {
    _ticker?.cancel();
    state = state.copyWith(isPaused: true);
  }

  void resume() {
    if (state.isTimeUp) return;
    state = state.copyWith(isPaused: false);
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void reset() {
    _ticker?.cancel();
    _startTime = null;
    state = const WorkoutTimerState();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}

final workoutTimerProvider = StateNotifierProvider<WorkoutTimerNotifier, WorkoutTimerState>((ref) {
  return WorkoutTimerNotifier();
});

/// Accessor for remaining seconds (readable from outside)
final remainingSecondsProvider = Provider<int>((ref) {
  return ref.watch(workoutTimerProvider).remainingSeconds;
});

final isHardStopTriggeredProvider = Provider<bool>((ref) {
  return ref.watch(workoutTimerProvider).isHardStopTriggered;
});

final isFinal10Provider = Provider<bool>((ref) {
  return ref.watch(workoutTimerProvider).isFinal10;
});

/// Tracks swapped-in alternative exercises: slot index -> alternative Exercise
final activeSwapProvider = StateProvider<Map<int, Exercise>>((ref) => {});

// ──────────────────────────────────────────────────────────────
//  Active Workout Session Provider
// ──────────────────────────────────────────────────────────────

class ActiveWorkoutNotifier extends StateNotifier<WorkoutSession?> {
  final Ref ref;
  Timer? _snapshotTimer;

  ActiveWorkoutNotifier(this.ref) : super(null) {
    _restoreOrFinalize();
  }

  void startWorkout({
    required WorkoutSplitType splitType,
    required int suggestedDayIndex,
    required int actualDayIndex,
    OverrideReason? overrideReason,
    String? overrideNotes,
  }) {
    final day = SeedData.getSplitDay(splitType, actualDayIndex);
    final slots = SeedData.getMainSlots(splitType, actualDayIndex);

    state = WorkoutSession(
      id: _uuid.v4(),
      date: DateTime.now(),
      splitType: splitType,
      dayIndex: actualDayIndex,
      dayLabel: day.label,
      daySubtitle: day.subtitle,
      wasOverridden: suggestedDayIndex != actualDayIndex,
      overrideReason: overrideReason,
      overrideNotes: overrideNotes,
      exercises: [
        ...SeedData.primerExercises.map((e) => ExerciseLog(
          exerciseId: e.id,
          exerciseName: e.name,
        )),
        ...slots.map((s) => ExerciseLog(
          exerciseId: s.exercise.id,
          exerciseName: s.exercise.name,
        )),
      ],
    );

    // Start the 60-min timer (primer is now inside the logged list, not a block)
    ref.read(workoutTimerProvider.notifier).startTimer();
    ref.read(workoutTimerProvider.notifier).setBlock(WorkoutBlock.blockA);
    _startSnapshotTimer();
    _persistDraft();
  }

  /// Start/refresh the periodic writer so the active session is always
  /// persisted within the last 2 minutes of work.
  void _startSnapshotTimer() {
    _snapshotTimer?.cancel();
    _snapshotTimer = Timer.periodic(const Duration(minutes: 2), (_) => _persistDraft());
  }

  /// Write the current session + timer snapshot to persistent storage.
  void _persistDraft() {
    final s = state;
    if (s == null) return;
    Database.saveActiveWorkout(s, ref.read(workoutTimerProvider));
  }

  /// On startup: if a draft exists and is < 2h old, restore it so the user can
  /// resume; otherwise finalize whatever was finished into history.
  Future<void> _restoreOrFinalize() async {
    final draft = Database.getActiveWorkoutSession();
    if (draft == null) return;
    final age = DateTime.now().difference(draft.date);
    if (age.inMinutes <= 120) {
      final snap = Database.getActiveTimerSnapshot();
      if (snap != null) {
        ref.read(workoutTimerProvider.notifier).restore(snap);
      } else {
        ref.read(workoutTimerProvider.notifier).startTimer();
      }
      state = draft;
      _startSnapshotTimer();
      _persistDraft();
    } else {
      await finalizeAbandonedWorkout();
    }
  }

  /// Finalize an abandoned draft: keep every exercise that has at least one
  /// logged set, write it to history as completed, count the day, and clear.
  Future<void> finalizeAbandonedWorkout() async {
    final draft = Database.getActiveWorkoutSession();
    if (draft == null) return;

    final snap = Database.getActiveTimerSnapshot();
    int elapsed = snap?.state.elapsedSeconds ?? draft.durationMinutes * 60;
    if (snap != null && !snap.state.isPaused && !snap.state.isTimeUp) {
      elapsed += DateTime.now().difference(snap.savedAt).inSeconds;
    }

    final exercises = draft.exercises.where((e) => e.sets.isNotEmpty).toList();
    if (exercises.isEmpty) {
      await Database.clearActiveWorkout();
      return;
    }

    final session = WorkoutSession(
      id: draft.id,
      date: draft.date,
      splitType: draft.splitType,
      dayIndex: draft.dayIndex,
      dayLabel: draft.dayLabel,
      daySubtitle: draft.daySubtitle,
      wasOverridden: draft.wasOverridden,
      overrideReason: draft.overrideReason,
      overrideNotes: draft.overrideNotes,
      exercises: exercises,
      durationMinutes: (elapsed / 60).ceil().clamp(1, 200),
      completed: true,
    );

    await Database.saveSession(session);
    await ref.read(queueProvider.notifier).completeWorkout(session.dayIndex);
    for (final exerciseLog in session.exercises) {
      await _updateProgress(exerciseLog);
    }

    await Database.clearActiveWorkout();
    ref.read(workoutTimerProvider.notifier).reset();
    if (state?.id == session.id) state = null;
  }

  void addExerciseLog(ExerciseLog log) {
    if (state == null) return;
    state = state!.copyWith(
      exercises: [...state!.exercises, log],
    );
    _persistDraft();
  }

  void logSet(int exerciseIndex, SetLog setLog) {
    if (state == null) return;
    final exercises = List<ExerciseLog>.from(state!.exercises);
    final exercise = exercises[exerciseIndex];
    exercises[exerciseIndex] = exercise.copyWith(
      sets: [...exercise.sets, setLog],
    );
    state = state!.copyWith(exercises: exercises);
    _persistDraft();
  }

  /// Toggle a primer (metabolic warm-up) exercise done/undone.
  void togglePrimerExercise(int exerciseIndex) {
    if (state == null) return;
    final exercises = List<ExerciseLog>.from(state!.exercises);
    final exercise = exercises[exerciseIndex];
    final done = exercise.sets.isNotEmpty;
    exercises[exerciseIndex] = done
        ? exercise.copyWith(sets: const [])
        : exercise.copyWith(sets: const [
            SetLog(setNumber: 1, weight: 0, repsCompleted: 1),
          ]);
    state = state!.copyWith(exercises: exercises);
    _persistDraft();
  }

  void editSet(int exerciseIndex, int setIndex, double newWeight, int newReps) {
    if (state == null) return;
    final exercises = List<ExerciseLog>.from(state!.exercises);
    final oldSets = List<SetLog>.from(exercises[exerciseIndex].sets);
    oldSets[setIndex] = oldSets[setIndex].copyWith(
      weight: newWeight,
      repsCompleted: newReps,
    );
    exercises[exerciseIndex] = exercises[exerciseIndex].copyWith(sets: oldSets);
    state = state!.copyWith(exercises: exercises);
    _persistDraft();
  }

  /// Record the rest the user took before logging the next set — applied to
  /// the most recently logged set of [exerciseIndex].
  void recordSetRest(int exerciseIndex, int restSeconds) {
    if (state == null || restSeconds <= 0) return;
    final exercises = List<ExerciseLog>.from(state!.exercises);
    final theExercise = exercises[exerciseIndex];
    if (theExercise.sets.isEmpty) return;
    final sets = List<SetLog>.from(theExercise.sets);
    sets[sets.length - 1] = sets[sets.length - 1].copyWith(restSeconds: restSeconds);
    exercises[exerciseIndex] = theExercise.copyWith(sets: sets);
    state = state!.copyWith(exercises: exercises);
    _persistDraft();
  }

  /// Record the rest the user took between finishing [exerciseIndex] and
  /// starting the next exercise.
  void recordExerciseRest(int exerciseIndex, int restSeconds) {
    if (state == null || restSeconds <= 0) return;
    final exercises = List<ExerciseLog>.from(state!.exercises);
    final theExercise = exercises[exerciseIndex];
    exercises[exerciseIndex] = theExercise.copyWith(restSeconds: restSeconds);
    state = state!.copyWith(exercises: exercises);
    _persistDraft();
  }

  /// Add [elapsedSeconds] of time the user spent on [exerciseIndex] (from when
  /// the exercise was opened until it was completed / left).
  void addExerciseElapsed(int exerciseIndex, int elapsedSeconds) {
    if (state == null || elapsedSeconds <= 0) return;
    final exercises = List<ExerciseLog>.from(state!.exercises);
    final theExercise = exercises[exerciseIndex];
    exercises[exerciseIndex] = theExercise.copyWith(
      elapsedSeconds: theExercise.elapsedSeconds + elapsedSeconds,
    );
    state = state!.copyWith(exercises: exercises);
    _persistDraft();
  }

  void rateExercise(int exerciseIndex, Difficulty difficulty) {
    if (state == null) return;
    final exercises = List<ExerciseLog>.from(state!.exercises);
    exercises[exerciseIndex] = exercises[exerciseIndex].copyWith(
      difficulty: difficulty,
    );
    state = state!.copyWith(exercises: exercises);
    _persistDraft();
  }

  Future<void> completeWorkout(int durationMinutes) async {
    if (state == null) return;
    final completed = state!.copyWith(
      completed: true,
      durationMinutes: durationMinutes,
    );
    await Database.saveSession(completed);

    // Advance the queue
    await ref.read(queueProvider.notifier).completeWorkout(completed.dayIndex);

    // Update user progress for each exercise
    for (final exerciseLog in completed.exercises) {
      if (exerciseLog.sets.isNotEmpty) {
        await _updateProgress(exerciseLog);
      }
    }

    // Reset timer
    ref.read(workoutTimerProvider.notifier).reset();
    _snapshotTimer?.cancel();
    await Database.clearActiveWorkout();
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
    ref.read(workoutTimerProvider.notifier).reset();
    _snapshotTimer?.cancel();
    Database.clearActiveWorkout();
    state = null;
  }

  @override
  void dispose() {
    _snapshotTimer?.cancel();
    super.dispose();
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

  Future<void> logFloater({
    required FloaterType type,
    required int durationMinutes,
    String? distance,
    String? setsPlayed,
    String? customName,
    String notes = '',
  }) async {
    final floater = FloaterLog(
      id: _uuid.v4(),
      date: DateTime.now(),
      type: type,
      durationMinutes: durationMinutes,
      distance: distance,
      setsPlayed: setsPlayed,
      customName: customName,
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

final weeklyStatsProvider = Provider<Map<String, dynamic>>((ref) {
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

  final split = Database.getSplitPreference();
  final dayCount = split.dayCount;
  final dayMap = <String, dynamic>{'gymSessions': weekSessions.length, 'floaters': weekFloaters.length};
  for (int i = 0; i < dayCount; i++) {
    final label = SeedData.getSplitDay(split, i).label;
    dayMap['workoutDay$i'] = weekSessions.where((s) => s.dayIndex == i && s.splitType == split).length;
    dayMap['workoutDayLabel$i'] = label;
  }
  return dayMap;
});

// ──────────────────────────────────────────────────────────────
//  User Profile Provider
// ──────────────────────────────────────────────────────────────

class UserProfileNotifier extends StateNotifier<UserProfile?> {
  UserProfileNotifier() : super(Database.getUserProfile());

  Future<void> setProfile(UserProfile profile) async {
    state = profile;
    await Database.saveUserProfile(profile);
  }

  Future<void> updateExperienceLevel(ExperienceLevel level) async {
    if (state == null) return;
    final updated = state!.copyWith(experienceLevel: level);
    state = updated;
    await Database.saveUserProfile(updated);
  }

  Future<void> signOut() async {
    state = null;
    await Database.deleteUserProfile();
  }
}

final userProfileProvider =
    StateNotifierProvider<UserProfileNotifier, UserProfile?>((ref) {
  return UserProfileNotifier();
});

/// Whether AI features are available
final isAiEnabledProvider = Provider<bool>((ref) {
  final profile = ref.watch(userProfileProvider);
  return profile?.isSignedIn ?? false;
});
