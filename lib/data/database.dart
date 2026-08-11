import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/models.dart';
import '../models/user_profile.dart';

typedef SplitPref = WorkoutSplitType;

/// Manages all Hive database operations for the app.
class Database {
  static const String _queueBoxName = 'queue_state';
  static const String _sessionsBoxName = 'workout_sessions';
  static const String _progressBoxName = 'user_progress';
  static const String _floaterBoxName = 'floater_logs';
  static const String _morningBoxName = 'morning_routine';
  static const String _settingsBoxName = 'app_settings';
  static const String _userProfileBoxName = 'user_profile';
  static const String _userExercisesBoxName = 'user_exercises';
  static const String _activeBoxName = 'active_workout';

  static late Box _queueBox;
  static late Box _sessionsBox;
  static late Box _progressBox;
  static late Box _floaterBox;
  static late Box _morningBox;
  static late Box _settingsBox;
  static late Box _userProfileBox;

  /// Initialize Hive and open all boxes
  static Future<void> init() async {
    await Hive.initFlutter();
    _queueBox = await Hive.openBox(_queueBoxName);
    _sessionsBox = await Hive.openBox(_sessionsBoxName);
    _progressBox = await Hive.openBox(_progressBoxName);
    _floaterBox = await Hive.openBox(_floaterBoxName);
    _morningBox = await Hive.openBox(_morningBoxName);
    _settingsBox = await Hive.openBox(_settingsBoxName);
    _userProfileBox = await Hive.openBox(_userProfileBoxName);
    _userExercisesBox = await Hive.openBox(_userExercisesBoxName);
    _activeBox = await Hive.openBox(_activeBoxName);
  }

  static late Box _userExercisesBox;
  static late Box _activeBox;

  // ─── Queue State ───────────────────────────────────────

  static QueueState getQueueState() {
    final data = _queueBox.get('state');
    if (data == null) return const QueueState();
    return QueueState.fromJson(Map<String, dynamic>.from(jsonDecode(jsonEncode(data))));
  }

  static Future<void> saveQueueState(QueueState state) async {
    await _queueBox.put('state', state.toJson());
  }

  // ─── Workout Sessions ─────────────────────────────────

  static List<WorkoutSession> getAllSessions() {
    return _sessionsBox.values.map((data) {
      return WorkoutSession.fromJson(Map<String, dynamic>.from(jsonDecode(jsonEncode(data))));
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  static Future<void> saveSession(WorkoutSession session) async {
    await _sessionsBox.put(session.id, session.toJson());
  }

  // ─── Active (in-progress) Workout ─────────────────────

  static WorkoutSession? getActiveWorkoutSession() {
    final data = _activeBox.get('session');
    if (data == null) return null;
    return WorkoutSession.fromJson(Map<String, dynamic>.from(jsonDecode(jsonEncode(data))));
  }

  static TimerSnapshot? getActiveTimerSnapshot() {
    final data = _activeBox.get('timer');
    if (data == null) return null;
    final map = Map<String, dynamic>.from(jsonDecode(jsonEncode(data)));
    return TimerSnapshot(
      state: WorkoutTimerState.fromJson(Map<String, dynamic>.from(map['timer'])),
      savedAt: DateTime.parse(map['savedAt']),
    );
  }

  /// Persist the in-progress session + timer snapshot (called on every mutation
  /// and by the 2-minute periodic writer).
  static Future<void> saveActiveWorkout(WorkoutSession session, WorkoutTimerState timer) async {
    await _activeBox.put('session', session.toJson());
    await _activeBox.put('timer', {
      'timer': timer.toJson(),
      'savedAt': DateTime.now().toIso8601String(),
    });
  }

  static Future<void> clearActiveWorkout() async {
    await _activeBox.delete('session');
    await _activeBox.delete('timer');
  }

  static List<WorkoutSession> getSessionsInRange(DateTime start, DateTime end) {
    return getAllSessions().where((s) =>
      s.date.isAfter(start) && s.date.isBefore(end)
    ).toList();
  }

  // ─── User Progress ────────────────────────────────────

  static UserProgress? getProgress(String exerciseId) {
    final data = _progressBox.get(exerciseId);
    if (data == null) return null;
    return UserProgress.fromJson(Map<String, dynamic>.from(jsonDecode(jsonEncode(data))));
  }

  static Map<String, UserProgress> getAllProgress() {
    final map = <String, UserProgress>{};
    for (final key in _progressBox.keys) {
      final data = _progressBox.get(key);
      if (data != null) {
        map[key as String] = UserProgress.fromJson(
          Map<String, dynamic>.from(jsonDecode(jsonEncode(data))),
        );
      }
    }
    return map;
  }

  static Future<void> saveProgress(UserProgress progress) async {
    await _progressBox.put(progress.exerciseId, progress.toJson());
  }

  // ─── Floater Logs ─────────────────────────────────────

  static List<FloaterLog> getAllFloaters() {
    return _floaterBox.values.map((data) {
      return FloaterLog.fromJson(Map<String, dynamic>.from(jsonDecode(jsonEncode(data))));
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  static Future<void> saveFloater(FloaterLog floater) async {
    await _floaterBox.put(floater.id, floater.toJson());
  }

  // ─── Morning Routine ──────────────────────────────────

  static MorningRoutineState getMorningState() {
    final data = _morningBox.get('state');
    if (data == null) return const MorningRoutineState();
    return MorningRoutineState.fromJson(Map<String, dynamic>.from(jsonDecode(jsonEncode(data))));
  }

  static Future<void> saveMorningState(MorningRoutineState state) async {
    await _morningBox.put('state', state.toJson());
  }

  // ─── Settings ─────────────────────────────────────────

  static String getUnits() => _settingsBox.get('units', defaultValue: 'lbs') as String;
  static Future<void> setUnits(String units) => _settingsBox.put('units', units);

  static int getRestTimer() => _settingsBox.get('restTimer', defaultValue: 90) as int;
  static Future<void> setRestTimer(int seconds) => _settingsBox.put('restTimer', seconds);

  // ─── Split Preference ──────────────────────────────

  static WorkoutSplitType getSplitPreference() {
    final val = _settingsBox.get('splitPref', defaultValue: 0) as int;
    return WorkoutSplitType.values[val.clamp(0, 2)];
  }
  static Future<void> setSplitPreference(WorkoutSplitType split) async {
    await _settingsBox.put('splitPref', split.index);
  }

  // ─── User Profile ──────────────────────────────

  static UserProfile? getUserProfile() {
    final data = _userProfileBox.get('profile');
    if (data == null) return null;
    return UserProfile.fromJson(Map<String, dynamic>.from(jsonDecode(jsonEncode(data))));
  }

  static Future<void> saveUserProfile(UserProfile profile) async {
    await _userProfileBox.put('profile', profile.toJson());
  }

  static Future<void> deleteUserProfile() async {
    await _userProfileBox.delete('profile');
  }

  static bool get hasUserProfile => _userProfileBox.containsKey('profile');

  // ─── User Exercises ───────────────────────────

  static List<Exercise> getCustomExercises() {
    return _userExercisesBox.values.map((data) {
      return Exercise.fromJson(Map<String, dynamic>.from(jsonDecode(jsonEncode(data))));
    }).toList();
  }

  static Future<void> saveCustomExercise(Exercise exercise) async {
    await _userExercisesBox.put(exercise.id, exercise.toJson());
  }
}
