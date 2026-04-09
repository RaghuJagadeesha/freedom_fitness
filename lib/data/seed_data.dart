import '../models/models.dart';

/// All predefined exercises and workout templates for Freedom Fitness.
class SeedData {
  // ─────────────────────────────────────────────
  //  Morning Routine Exercises
  // ─────────────────────────────────────────────
  static const morningExercises = [
    Exercise(
      id: 'morning_hydration',
      name: 'Hydration & Sunlight',
      category: ExerciseCategory.bodyweight,
      muscleGroup: MuscleGroup.fullBody,
      sets: 1,
      durationSeconds: 600,
      youtubeUrl: 'WDv4AWk0J3U',
      description: '16oz water + 10 mins natural light for hormonal reset.',
    ),
    Exercise(
      id: 'morning_couch_stretch',
      name: 'Couch Stretch',
      category: ExerciseCategory.stretch,
      muscleGroup: MuscleGroup.glutes,
      sets: 1,
      durationSeconds: 120,
      youtubeUrl: 'B3rOeBLqlF4',
      description: '1 min per side. Opens hips for glute activation.',
    ),
    Exercise(
      id: 'morning_cat_cow',
      name: 'Cat-Cow to Bird-Dog',
      category: ExerciseCategory.stretch,
      muscleGroup: MuscleGroup.core,
      sets: 1,
      durationSeconds: 60,
      youtubeUrl: 'LIVJZZyZ2qM',
      description: 'Wakes up the deep core. Flow for 1 minute.',
    ),
    Exercise(
      id: 'morning_glute_bridges',
      name: 'Bodyweight Glute Bridges',
      category: ExerciseCategory.bodyweight,
      muscleGroup: MuscleGroup.glutes,
      sets: 1,
      durationSeconds: 60,
      youtubeUrl: 'Cj5zDEgmumA',
      description: 'Primes the posterior chain. 1 minute continuous.',
    ),
  ];

  // ─────────────────────────────────────────────
  //  Metabolic Primer Exercises
  // ─────────────────────────────────────────────
  static const primerExercises = [
    Exercise(
      id: 'primer_incline_walk',
      name: 'Incline Walk',
      category: ExerciseCategory.cardio,
      muscleGroup: MuscleGroup.glutes,
      sets: 1,
      durationSeconds: 900,
      youtubeUrl: '0EoCEWzWeeMw',
      description: '15 min at 6-10% incline, 3.0-3.5 mph. No handrails — engage core/glutes.',
    ),
    Exercise(
      id: 'primer_interval_run',
      name: 'Interval Run',
      category: ExerciseCategory.cardio,
      muscleGroup: MuscleGroup.fullBody,
      sets: 1,
      durationSeconds: 300,
      youtubeUrl: 'IODxDxX7oi4',
      description: '5 min: 45s @ 8.0 mph / 15s @ 6.0 mph. Targets visceral fat.',
    ),
    Exercise(
      id: 'primer_dynamic_stretch',
      name: "World's Greatest Stretch",
      category: ExerciseCategory.stretch,
      muscleGroup: MuscleGroup.fullBody,
      sets: 1,
      durationSeconds: 120,
      youtubeUrl: 'JCXUYuzwNrM',
      description: '2 min dynamic stretch to prepare for lifting.',
    ),
  ];

  // ─────────────────────────────────────────────
  //  Workout A: Lower Body & Deep Core
  // ─────────────────────────────────────────────
  static const workoutAExercises = [
    Exercise(
      id: 'a_goblet_squat',
      name: 'Goblet Squat',
      category: ExerciseCategory.compound,
      muscleGroup: MuscleGroup.quads,
      sets: 3,
      reps: 12,
      youtubeUrl: 'IODxDxX7oi4',
      description: 'Hold dumbbell at chest. Full depth, drive through heels.',
    ),
    Exercise(
      id: 'a_romanian_deadlift',
      name: 'Romanian Deadlift',
      category: ExerciseCategory.compound,
      muscleGroup: MuscleGroup.hamstrings,
      sets: 3,
      reps: 12,
      youtubeUrl: 'JCXUYuzwNrM',
      description: 'Hinge at hips, slight knee bend. Feel the stretch in hamstrings.',
    ),
    Exercise(
      id: 'a_walking_lunges',
      name: 'Walking Lunges',
      category: ExerciseCategory.compound,
      muscleGroup: MuscleGroup.glutes,
      sets: 3,
      reps: 12,
      youtubeUrl: 'L8fvypPrzzs',
      description: '12 reps each leg. Keep torso upright, deep lunge.',
    ),
    Exercise(
      id: 'a_weighted_glute_bridges',
      name: 'Glute Bridges (Weighted)',
      category: ExerciseCategory.isolation,
      muscleGroup: MuscleGroup.glutes,
      sets: 3,
      reps: 15,
      description: 'Barbell or dumbbell on hips. Squeeze at the top.',
    ),
    Exercise(
      id: 'a_hanging_leg_raises',
      name: 'Hanging Leg Raises',
      category: ExerciseCategory.isolation,
      muscleGroup: MuscleGroup.core,
      sets: 3,
      reps: 12,
      description: 'Control the movement. No swinging. Target lower abs.',
    ),
    Exercise(
      id: 'a_plank_shoulder_taps',
      name: 'Plank w/ Shoulder Taps',
      category: ExerciseCategory.bodyweight,
      muscleGroup: MuscleGroup.core,
      sets: 3,
      durationSeconds: 45,
      description: 'Hold plank, alternate tapping opposite shoulder. Minimize hip rotation.',
    ),
  ];

  // ─────────────────────────────────────────────
  //  Workout B: Upper Body & Power
  // ─────────────────────────────────────────────
  static const workoutBExercises = [
    Exercise(
      id: 'b_dumbbell_chest_press',
      name: 'Dumbbell Chest Press',
      category: ExerciseCategory.compound,
      muscleGroup: MuscleGroup.chest,
      sets: 3,
      reps: 12,
      youtubeUrl: 'VmB1G1K7v94',
      description: 'Flat bench. Control the descent, explosive push.',
    ),
    Exercise(
      id: 'b_lat_pulldown',
      name: 'Lat Pulldown / Row',
      category: ExerciseCategory.compound,
      muscleGroup: MuscleGroup.back,
      sets: 3,
      reps: 12,
      youtubeUrl: '0EoCEWzWeeMw',
      description: 'Wide grip pulldown or bent-over row. Squeeze shoulder blades.',
    ),
    Exercise(
      id: 'b_overhead_press',
      name: 'Dumbbell Overhead Press',
      category: ExerciseCategory.compound,
      muscleGroup: MuscleGroup.shoulders,
      sets: 3,
      reps: 12,
      description: 'Standing or seated. Full lockout overhead.',
    ),
    Exercise(
      id: 'b_face_pulls',
      name: 'Face Pulls',
      category: ExerciseCategory.isolation,
      muscleGroup: MuscleGroup.shoulders,
      sets: 3,
      reps: 15,
      description: 'Cable or bands. Pull to face, external rotate at the end.',
    ),
    Exercise(
      id: 'b_russian_twists',
      name: 'Russian Twists',
      category: ExerciseCategory.isolation,
      muscleGroup: MuscleGroup.core,
      sets: 3,
      reps: 20,
      description: '20 reps each side. Hold weight, feet off ground.',
    ),
    Exercise(
      id: 'b_mountain_climbers',
      name: 'Mountain Climbers',
      category: ExerciseCategory.cardio,
      muscleGroup: MuscleGroup.core,
      sets: 3,
      durationSeconds: 45,
      description: '45 seconds. Fast pace, drive knees to chest.',
    ),
  ];

  /// Get exercises for a workout type
  static List<Exercise> getWorkoutExercises(WorkoutType type) {
    return type == WorkoutType.a ? workoutAExercises : workoutBExercises;
  }
}
