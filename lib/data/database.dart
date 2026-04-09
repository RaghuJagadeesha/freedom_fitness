import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/models.dart';

/// Manages all Hive database operations for the app.
class Database {
  static const String _queueBoxName = 'queue_state';
  static const String _sessionsBoxName = 'workout_sessions';
  static const String _progressBoxName = 'user_progress';
  static const String _floaterBoxName = 'floater_logs';
  static const String _morningBoxName = 'morning_routine';
  static const String _settingsBoxName = 'app_settings';

  static late Box _queueBox;
  static late Box _sessionsBox;
  static late Box _progressBox;
  static late Box _floaterBox;
  static late Box _morningBox;
  static late Box _settingsBox;

  /// Initialize Hive and open all boxes
  static Future<void> init() async {
    await Hive.initFlutter();
    _queueBox = await Hive.openBox(_queueBoxName);
    _sessionsBox = await Hive.openBox(_sessionsBoxName);
    _progressBox = await Hive.openBox(_progressBoxName);
    _floaterBox = await Hive.openBox(_floaterBoxName);
    _morningBox = await Hive.openBox(_morningBoxName);
    _settingsBox = await Hive.openBox(_settingsBoxName);
  }

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
}
