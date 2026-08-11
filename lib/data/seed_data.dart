import '../models/models.dart';
import 'exercise_alternatives.dart';

// ──────────────────────────────────────────────────────────────
//  Day Template Helper (flat exercise list, no blocks)
// ──────────────────────────────────────────────────────────────
class _DayTemplate {
  final SplitDay meta;
  final List<ExerciseSlot> exercises;

  const _DayTemplate({required this.meta, required this.exercises});

  List<ExerciseSlot> get allSlots => exercises;
  List<ExerciseSlot> get mainSlots => exercises;
}

/// All predefined exercises and workout templates.
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
  //  Primer Exercises (8 min total)
  // ─────────────────────────────────────────────
  static const primerExercises = [
    Exercise(
      id: 'primer_walk',
      name: 'Incline Walk',
      category: ExerciseCategory.cardio,
      muscleGroup: MuscleGroup.glutes,
      sets: 1,
      durationSeconds: 240,
      description: '4 min at 6-10% incline, 3.0-3.5 mph. No handrails.',
    ),
    Exercise(
      id: 'primer_run',
      name: 'Interval Run',
      category: ExerciseCategory.cardio,
      muscleGroup: MuscleGroup.fullBody,
      sets: 1,
      durationSeconds: 180,
      description: '3 min: 45s @ 8.0 mph / 15s @ 6.0 mph.',
    ),
    Exercise(
      id: 'primer_stretch',
      name: "World's Greatest Stretch",
      category: ExerciseCategory.stretch,
      muscleGroup: MuscleGroup.fullBody,
      sets: 1,
      durationSeconds: 60,
      youtubeUrl: 'JCXUYuzwNrM',
      description: '1 min dynamic stretch to prepare for lifting.',
    ),
  ];

  static int get primerCount => primerExercises.length;

  /// Prefix for GitHub raw GIF URLs from the exercises dataset.
  static const _gifBase = 'https://raw.githubusercontent.com/hasaneyldrm/exercises-dataset/main/';

  static ExerciseSlot _ds({
    required String id,
    required String name,
    required ExerciseCategory category,
    required MuscleGroup muscleGroup,
    required String gifPath,
    required String description,
    int sets = 3,
    int reps = 10,
    int durationSeconds = 0,
    String? easierAlternativeId,
  }) {
    return ExerciseSlot(
      block: WorkoutBlock.blockA,
      exercise: Exercise(
        id: id,
        name: name,
        category: category,
        muscleGroup: muscleGroup,
        sets: sets,
        reps: reps,
        durationSeconds: durationSeconds,
        gifUrl: '$_gifBase$gifPath',
        description: description,
      ),
      easierAlternativeId: easierAlternativeId,
    );
  }

  /// Shared dataset exercises used across all splits (flat day lists).
  static final _shared = {
    // ── Push / Shoulders & Triceps ──
    'cableStandingLift': _ds(
      id: 'ds_0230',
      name: 'Cable Standing Lift',
      category: ExerciseCategory.compound,
      muscleGroup: MuscleGroup.core,
      gifPath: 'videos/0230-qFpAkpP.gif',
      description: 'Hold cable at waist, arms straight. Rotate torso and lift the handle to the opposite shoulder. Repeat per side.',
    ),
    'overheadPress': _ds(
      id: 'ds_0091',
      name: 'Barbell Seated Overhead Press',
      category: ExerciseCategory.compound,
      muscleGroup: MuscleGroup.shoulders,
      gifPath: 'videos/0091-kTbSH9h.gif',
      description: 'Seated, overhand grip slightly wider than shoulders. Press the bar overhead, pause, then lower to shoulder level.',
      easierAlternativeId: 'alt_machine_shoulder_press',
    ),
    'lateralRaise': _ds(
      id: 'ds_0334',
      name: 'Dumbbell Lateral Raise',
      category: ExerciseCategory.isolation,
      muscleGroup: MuscleGroup.shoulders,
      gifPath: 'videos/0334-DsgkuIt.gif',
      description: 'Raise arms out to the sides until parallel to the floor, slight bend in the elbows. Control the descent.',
      sets: 3, reps: 15,
      easierAlternativeId: 'alt_band_pull_apart',
    ),
    'pushdown': _ds(
      id: 'ds_0201',
      name: 'Cable Pushdown',
      category: ExerciseCategory.isolation,
      muscleGroup: MuscleGroup.arms,
      gifPath: 'videos/0201-3ZflifB.gif',
      description: 'Elbows pinned to sides. Push the bar down until elbows are fully extended, pause, then return slowly.',
      sets: 3, reps: 12,
    ),
    'ropePushdown': _ds(
      id: 'ds_0200',
      name: 'Cable Pushdown (Rope)',
      category: ExerciseCategory.isolation,
      muscleGroup: MuscleGroup.arms,
      gifPath: 'videos/0200-dU605di.gif',
      description: 'Rope attachment. Keep elbows close, push the rope down and split the ends at full extension.',
      sets: 3, reps: 12,
    ),
    'standingTriExt': _ds(
      id: 'ds_0430',
      name: 'Dumbbell Standing Triceps Extension',
      category: ExerciseCategory.isolation,
      muscleGroup: MuscleGroup.arms,
      gifPath: 'videos/0430-PdmaD0N.gif',
      description: 'Overhead dumbbell, upper arm stationary. Lower behind your head, then extend back up.',
      sets: 3, reps: 12,
    ),
    'lyingTriExt': _ds(
      id: 'ds_0061',
      name: 'Barbell Lying Triceps Extension',
      category: ExerciseCategory.isolation,
      muscleGroup: MuscleGroup.arms,
      gifPath: 'videos/0061-iZop9xO.gif',
      description: 'Lying on a bench, arms straight over chest. Lower the bar to your forehead, then extend back up.',
      sets: 3, reps: 12,
    ),
    'inclinePress': _ds(
      id: 'ds_0314',
      name: 'Dumbbell Incline Bench Press',
      category: ExerciseCategory.compound,
      muscleGroup: MuscleGroup.chest,
      gifPath: 'videos/0314-ns0SIbU.gif',
      description: '45° incline. Lower the dumbbells to the sides of your chest, then press up with full extension.',
      easierAlternativeId: 'alt_machine_chest_press',
    ),

    // ── Pull / Back ──
    'farmersWalk': _ds(
      id: 'ds_2133',
      name: 'Farmers Walk',
      category: ExerciseCategory.compound,
      muscleGroup: MuscleGroup.fullBody,
      gifPath: 'videos/2133-qPEzJjA.gif',
      description: 'Carry a dumbbell in each hand with a tall posture. Take small, controlled steps for the distance or time.',
      sets: 3, durationSeconds: 30,
    ),
    'latPulldown': _ds(
      id: 'ds_2330',
      name: 'Cable Lat Pulldown',
      category: ExerciseCategory.compound,
      muscleGroup: MuscleGroup.back,
      gifPath: 'videos/2330-LEprlgG.gif',
      description: 'Wide overhand grip, chest up. Pull the bar to your upper chest, squeezing the shoulder blades.',
      sets: 3, reps: 12,
      easierAlternativeId: 'alt_lat_pulldown',
    ),
    'bentOverRow': _ds(
      id: 'ds_0027',
      name: 'Barbell Bent Over Row',
      category: ExerciseCategory.compound,
      muscleGroup: MuscleGroup.back,
      gifPath: 'videos/0027-eZyBC3j.gif',
      description: 'Hinge forward with a straight back. Pull the bar to your lower chest, retracting the shoulder blades.',
    ),
    'rearDeltRow': _ds(
      id: 'ds_0203',
      name: 'Cable Rear Delt Row (Rope)',
      category: ExerciseCategory.isolation,
      muscleGroup: MuscleGroup.shoulders,
      gifPath: 'videos/0203-wqNPGCg.gif',
      description: 'Rope on a low pulley. Hinge slightly, pull the rope to your chest squeezing the shoulder blades.',
      sets: 3, reps: 15,
      easierAlternativeId: 'alt_band_pull_apart',
    ),
    'seatedRow': _ds(
      id: 'ds_0861',
      name: 'Cable Seated Row',
      category: ExerciseCategory.compound,
      muscleGroup: MuscleGroup.back,
      gifPath: 'videos/0861-fUBheHs.gif',
      description: 'Sit tall, knees slightly bent. Pull the handles to your body, squeezing the shoulder blades, then release slowly.',
    ),

    // ── Legs ──
    'lateralLunge': _ds(
      id: 'ds_1410',
      name: 'Barbell Lateral Lunge',
      category: ExerciseCategory.compound,
      muscleGroup: MuscleGroup.glutes,
      gifPath: 'videos/1410-py1HSzx.gif',
      description: 'Big step to the side, bend that knee while keeping the other leg straight. Push back to stand.',
      easierAlternativeId: 'alt_walking_lunges',
    ),
    'rearLunge': _ds(
      id: 'ds_0381',
      name: 'Dumbbell Rear Lunge',
      category: ExerciseCategory.compound,
      muscleGroup: MuscleGroup.glutes,
      gifPath: 'videos/0381-SSsBDwB.gif',
      description: 'Step backward into a lunge, front thigh parallel to the ground. Drive through the front heel to return.',
      easierAlternativeId: 'alt_walking_lunges',
    ),
    'sumoSquat': _ds(
      id: 'ds_3142',
      name: 'Smith Sumo Squat',
      category: ExerciseCategory.compound,
      muscleGroup: MuscleGroup.glutes,
      gifPath: 'videos/3142-dzz6BiV.gif',
      description: 'Wide stance, toes out. Lower until thighs are parallel, then drive through the heels.',
      easierAlternativeId: 'alt_leg_press',
    ),
    'hipAbduction': _ds(
      id: 'ds_0597',
      name: 'Lever Seated Hip Abduction',
      category: ExerciseCategory.isolation,
      muscleGroup: MuscleGroup.glutes,
      gifPath: 'videos/0597-CHpahtl.gif',
      description: 'Seated, push the pads apart against resistance, pause, then return slowly.',
      sets: 3, reps: 12,
    ),
    'hipAdduction': _ds(
      id: 'ds_0598',
      name: 'Lever Seated Hip Adduction',
      category: ExerciseCategory.isolation,
      muscleGroup: MuscleGroup.quads,
      gifPath: 'videos/0598-oHsrypV.gif',
      description: 'Seated, squeeze the pads together engaging the inner thighs, pause at peak contraction.',
      sets: 3, reps: 12,
    ),
    'sideHipAbduction': _ds(
      id: 'ds_0710',
      name: 'Side Hip Abduction',
      category: ExerciseCategory.bodyweight,
      muscleGroup: MuscleGroup.glutes,
      gifPath: 'videos/0710-7WaDzyL.gif',
      description: 'Stand on one leg, lift the other leg straight out to the side, pause, then lower slowly. Alternate sides.',
      sets: 3, reps: 15,
    ),
    'legPress': _ds(
      id: 'ds_2611',
      name: 'Lever Horizontal One Leg Press',
      category: ExerciseCategory.compound,
      muscleGroup: MuscleGroup.quads,
      gifPath: 'videos/2611-9KU9TYF.gif',
      description: 'Push the footplate away with one leg, keeping the back against the rest. Slow return, then switch legs.',
      easierAlternativeId: 'alt_leg_press',
    ),
    'kettlebellSwing': _ds(
      id: 'ds_0549',
      name: 'Kettlebell Swing',
      category: ExerciseCategory.compound,
      muscleGroup: MuscleGroup.glutes,
      gifPath: 'videos/0549-UHJlbu3.gif',
      description: 'Hinge at the hips, swing the bell to shoulder height using hip drive. Flat back, arms straight.',
      sets: 3, reps: 15,
      easierAlternativeId: 'alt_bodyweight_glute',
    ),

    // ── Core / Abs ──
    'cableCrunch': _ds(
      id: 'ds_0175',
      name: 'Cable Kneeling Crunch',
      category: ExerciseCategory.isolation,
      muscleGroup: MuscleGroup.core,
      gifPath: 'videos/0175-WW95auq.gif',
      description: 'Rope behind your head, kneel away from the machine. Crunch your torso down toward your thighs.',
      sets: 3, reps: 15,
      easierAlternativeId: 'alt_captains_chair',
    ),
    'hangingLegRaise': _ds(
      id: 'ds_0472',
      name: 'Hanging Leg Raise',
      category: ExerciseCategory.bodyweight,
      muscleGroup: MuscleGroup.core,
      gifPath: 'videos/0472-I3tsCnC.gif',
      description: 'Hang with arms extended. Lift straight legs to parallel (or as high as comfortable), then lower slowly.',
      sets: 3, reps: 12,
      easierAlternativeId: 'alt_captains_chair',
    ),
    'hangingKneeRaise': _ds(
      id: 'ds_1761',
      name: 'Hanging Oblique Knee Raise',
      category: ExerciseCategory.bodyweight,
      muscleGroup: MuscleGroup.core,
      gifPath: 'videos/1761-BaE7O6U.gif',
      description: 'Hang and lift knees toward the chest while twisting the torso to the side. Alternate sides.',
      sets: 3, reps: 12,
      easierAlternativeId: 'alt_captains_chair',
    ),
  };

  /// Optional final finisher: Dead Hangs (grip + spinal decompression).
  static final _deadHangs = ExerciseSlot(
    block: WorkoutBlock.blockA,
    exercise: const Exercise(
      id: 'shared_dead_hangs',
      name: 'Dead Hangs',
      category: ExerciseCategory.bodyweight,
      muscleGroup: MuscleGroup.back,
      sets: 3,
      durationSeconds: 30,
      description: 'Max duration each set. Grip + spinal decompression.',
    ),
    easierAlternativeId: 'alt_captains_chair',
  );

  // ─────────────────────────────────────────────
  //  Split Day Metadata
  // ─────────────────────────────────────────────
  static final _dayMeta3 = [
    const SplitDay(id: '3day_push', label: 'Push', subtitle: 'Shoulders, Triceps & Obliques', splitType: WorkoutSplitType.split3, dayIndex: 0),
    const SplitDay(id: '3day_pull', label: 'Pull', subtitle: 'Upper Back, Lats & Abs', splitType: WorkoutSplitType.split3, dayIndex: 1),
    const SplitDay(id: '3day_legs', label: 'Legs', subtitle: 'Inner/Outer Thighs & Lower Abs', splitType: WorkoutSplitType.split3, dayIndex: 2),
  ];

  static final _dayMeta4 = [
    const SplitDay(id: '4day_upper_a', label: 'Upper A', subtitle: 'Shoulders & Triceps', splitType: WorkoutSplitType.split4, dayIndex: 0),
    const SplitDay(id: '4day_lower_a', label: 'Lower A', subtitle: 'Inner & Outer Thighs', splitType: WorkoutSplitType.split4, dayIndex: 1),
    const SplitDay(id: '4day_upper_b', label: 'Upper B', subtitle: 'Upper Back & Width', splitType: WorkoutSplitType.split4, dayIndex: 2),
    const SplitDay(id: '4day_lower_b', label: 'Lower B', subtitle: 'Leg Agility & Core', splitType: WorkoutSplitType.split4, dayIndex: 3),
  ];

  static final _dayMeta5 = [
    const SplitDay(id: '5day_shoulders_abs', label: 'Shoulders & Abs', subtitle: 'Delts, Core & Obliques', splitType: WorkoutSplitType.split5, dayIndex: 0),
    const SplitDay(id: '5day_legs', label: 'Legs', subtitle: 'Inner & Outer Thighs', splitType: WorkoutSplitType.split5, dayIndex: 1),
    const SplitDay(id: '5day_back_lats', label: 'Upper Back & Lats', subtitle: 'Row, Pull & Rear Delts', splitType: WorkoutSplitType.split5, dayIndex: 2),
    const SplitDay(id: '5day_triceps_chest', label: 'Triceps & Upper Chest', subtitle: 'Pushdowns, Extensions & Press', splitType: WorkoutSplitType.split5, dayIndex: 3),
    const SplitDay(id: '5day_agility_core', label: 'Lower Body Agility & Core', subtitle: 'Swing, Lunge & Core', splitType: WorkoutSplitType.split5, dayIndex: 4),
  ];

  /// Append the optional Dead Hangs finisher to a day list.
  static List<ExerciseSlot> _withDeadHangs(List<ExerciseSlot> list) => [...list, _deadHangs];

  // ─────────────────────────────────────────────
  //  3-DAY SPLIT (Push / Pull / Legs)
  // ─────────────────────────────────────────────
  static final _split3 = [
    _DayTemplate(
      meta: _dayMeta3[0],
      exercises: _withDeadHangs([
        _shared['cableStandingLift']!,
        _shared['overheadPress']!,
        _shared['lateralRaise']!,
        _shared['pushdown']!,
        _shared['standingTriExt']!,
        _shared['hangingLegRaise']!,
      ]),
    ),
    _DayTemplate(
      meta: _dayMeta3[1],
      exercises: _withDeadHangs([
        _shared['farmersWalk']!,
        _shared['latPulldown']!,
        _shared['bentOverRow']!,
        _shared['rearDeltRow']!,
        _shared['seatedRow']!,
        _shared['cableCrunch']!,
      ]),
    ),
    _DayTemplate(
      meta: _dayMeta3[2],
      exercises: _withDeadHangs([
        _shared['lateralLunge']!,
        _shared['sumoSquat']!,
        _shared['hipAbduction']!,
        _shared['hipAdduction']!,
        _shared['rearLunge']!,
        _shared['hangingKneeRaise']!,
      ]),
    ),
  ];

  // ─────────────────────────────────────────────
  //  4-DAY SPLIT (Upper A / Lower A / Upper B / Lower B)
  // ─────────────────────────────────────────────
  static final _split4 = [
    _DayTemplate(
      meta: _dayMeta4[0],
      exercises: _withDeadHangs([
        _shared['overheadPress']!,
        _shared['lateralRaise']!,
        _shared['ropePushdown']!,
        _shared['lyingTriExt']!,
        _shared['hangingLegRaise']!,
      ]),
    ),
    _DayTemplate(
      meta: _dayMeta4[1],
      exercises: _withDeadHangs([
        _shared['kettlebellSwing']!,
        _shared['hipAbduction']!,
        _shared['hipAdduction']!,
        _shared['legPress']!,
        _shared['cableStandingLift']!,
      ]),
    ),
    _DayTemplate(
      meta: _dayMeta4[2],
      exercises: _withDeadHangs([
        _shared['farmersWalk']!,
        _shared['latPulldown']!,
        _shared['bentOverRow']!,
        _shared['rearDeltRow']!,
        _shared['inclinePress']!,
        _shared['cableCrunch']!,
      ]),
    ),
    _DayTemplate(
      meta: _dayMeta4[3],
      exercises: _withDeadHangs([
        _shared['lateralLunge']!,
        _shared['rearLunge']!,
        _shared['sideHipAbduction']!,
        _shared['sumoSquat']!,
        _shared['hangingKneeRaise']!,
      ]),
    ),
  ];

  // ─────────────────────────────────────────────
  //  5-DAY SPLIT (Isolated Muscle Group Rotation)
  // ─────────────────────────────────────────────
  static final _split5 = [
    _DayTemplate(
      meta: _dayMeta5[0],
      exercises: _withDeadHangs([
        _shared['cableStandingLift']!,
        _shared['overheadPress']!,
        _shared['lateralRaise']!,
        _shared['hangingLegRaise']!,
      ]),
    ),
    _DayTemplate(
      meta: _dayMeta5[1],
      exercises: _withDeadHangs([
        _shared['lateralLunge']!,
        _shared['hipAbduction']!,
        _shared['hipAdduction']!,
        _shared['sumoSquat']!,
      ]),
    ),
    _DayTemplate(
      meta: _dayMeta5[2],
      exercises: _withDeadHangs([
        _shared['farmersWalk']!,
        _shared['latPulldown']!,
        _shared['bentOverRow']!,
        _shared['seatedRow']!,
        _shared['rearDeltRow']!,
      ]),
    ),
    _DayTemplate(
      meta: _dayMeta5[3],
      exercises: _withDeadHangs([
        _shared['inclinePress']!,
        _shared['pushdown']!,
        _shared['standingTriExt']!,
        _shared['cableCrunch']!,
      ]),
    ),
    _DayTemplate(
      meta: _dayMeta5[4],
      exercises: _withDeadHangs([
        _shared['kettlebellSwing']!,
        _shared['rearLunge']!,
        _shared['sideHipAbduction']!,
        _shared['hangingKneeRaise']!,
      ]),
    ),
  ];

  static List<_DayTemplate> _getTemplates(WorkoutSplitType split) {
    switch (split) {
      case WorkoutSplitType.split3: return _split3;
      case WorkoutSplitType.split4: return _split4;
      case WorkoutSplitType.split5: return _split5;
    }
  }

  // ─────────────────────────────────────────────
  //  Public API
  // ─────────────────────────────────────────────

  /// Return the SplitDay metadata for every day in a split.
  static List<SplitDay> getDayMetadatas(WorkoutSplitType split) {
    return _getTemplates(split).map((t) => t.meta).toList();
  }

  /// Return metadata for a specific day in a split.
  static SplitDay getSplitDay(WorkoutSplitType split, int dayIndex) {
    final templates = _getTemplates(split);
    if (dayIndex < 0 || dayIndex >= templates.length) {
      return templates[0].meta;
    }
    return templates[dayIndex].meta;
  }

  /// Get all exercise slots for a given split day.
  static List<ExerciseSlot> getDaySlots(WorkoutSplitType split, int dayIndex) {
    final templates = _getTemplates(split);
    if (dayIndex < 0 || dayIndex >= templates.length) return [];
    return templates[dayIndex].exercises;
  }

  /// Get the main (non-alternative) slots for a given split day.
  static List<ExerciseSlot> getMainSlots(WorkoutSplitType split, int dayIndex) {
    return getDaySlots(split, dayIndex).where((s) => !s.isAlternative).toList();
  }

  /// Get the easier alternative for an exercise slot.
  static Exercise? getEasierAlternative(List<ExerciseSlot> slots, String exerciseId) {
    final slot = slots.where((s) => s.exercise.id == exerciseId).firstOrNull;
    if (slot?.easierAlternativeId == null) return null;
    return ExerciseAlternatives.tennisEasierSwaps[slot!.easierAlternativeId];
  }

  /// The optional Dead Hangs finisher (grip + decompression).
  static List<ExerciseSlot> getHardStopFinishers(WorkoutSplitType split, int dayIndex) {
    return getDaySlots(split, dayIndex)
        .where((s) => s.exercise.name.contains('Dead Hangs'))
        .toList();
  }
}