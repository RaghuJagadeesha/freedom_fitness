# Freedom Fitness — App Logic (page/experience level)

Concise reference of how each screen/experience behaves. Not implementation detail — what the user experiences and the rules that drive it.

## Navigation / Shell

- App starts at `/login` (or `/home` if already signed in). A GoRouter redirect guards every route — unauthenticated users get sent to `/login`; signed-in users can never reach `/login`.
- Signed-in experience lives in a shell with a **bottom nav**: Home, History, Settings.
- Full-screen flows pushed on top: Morning, Workout, Exercise detail, Machine ID.

## Login

- Google Sign-In (web/Android). Silent sign-in is attempted at app cold start; FedCM "canceled" errors on web are swallowed and harmless.
- After success → `/home`.

## Home

- Shows the **suggested workout day** for the current split + rolling queue (e.g. "Chest & Triceps" if it's day 1 of a 5-day split).
- **Start Workout** begins the suggested day. **Switch Workout?** bottom sheet lets you pick a different day and a reason (soreness / injury / other with notes) — the override is recorded on the session as "was overridden".
- Shows weekly progress (split-specific day bars), progressive load carousel, and a **Resume Workout** banner whenever an in-progress (persisted < 2h) session exists.
- Quick links: /morning routine, floater activities.

## Morning Routine (/morning)

- Daily checklist: hydration, couch stretch, cat-cow, glute bridges. Resets each calendar day; a day is "complete" when all four are done.

## Workout (/workout) — the core experience

- A workout = one split day. Exercises render in blocks: **Primer** → **Block A** (targeted) → **Block B (Giant Set)** → **Block C (Finishers)** → optional Custom Exercises.
- **Primer**: 3 metabolic warm-ups (Incline Walk, Interval Run, World's Greatest Stretch), each with its own countdown timer (play/pause + restart). Auto-marks DONE at 0:00; can also be toggled by hand. Primer exercises are logged as part of the session's exercise list (they count, appear in history detail).
- **60-minute countdown** banner spans everything. At 10 minutes left it warns; user may extend to 70 minutes. Final-10 state flips the day to a "Hard Stop": only the finishers (Hanging Crunches, Dead Hangs, etc.) remain and Block C alternatives are skipped.
- **Exercise tiles** show progress (e.g. `2/3 sets`) and DONE/UNDO state for swaps. Tapping a tile opens the exercise detail screen.
- **Low Energy mode**: bulk-swaps all remaining exercises to their easier alternatives at once (records "Low Energy" override on timer).
- **Complete** stops the timer, saves the session to history, advances the queue to the next day, and updates per-exercise progressive load.

## Exercise Detail (/exercise/:index)

- Shows exercise info (sets × reps or duration, description, muscle group) + YouTube demo when available.
- **Sets Completed**: each logged set is a tappable row (edit weight/reps via dialog, shows DROP tag for drop sets).
- **Log Set ✓**: one-tap logging — reps default to the exercise's target reps and weight to the last/known value. It never silently fails (bodyweight/duration moves log fine). After logging, a rest timer starts (skippable). Drop-set button appears from the 2nd set onward.
- After target sets are logged → **rate difficulty** (Easy/Mod/ Hard) → "Exercise Complete" state.
- Index resolution: primer exercises shift the session list by 3; reads/writes all use that offset, and the exercise being logged is resolved from the day's slots/swap-map, not by list position.

## Swaps (inside Workout)

- A **swap** replaces one exercise with an easier alternative for the session, tracked per slot index.
- Each swapped-in exercise gets its **own set queue** (starts at 0). If you logged 1 set of the original then swap, the alternative shows 0 sets — the original's recorded sets stay with the original.
- Swap back (UNDO) restores the original and its sets.

## History

- **Stats row**: per-split-day workout counts + floater count (horizontally scrollable).
- **Day distribution** bar + **Progressive load** carousel (per-exercise current weight).
- **Recent Sessions**: expandable tiles per completed session showing the workout day, duration, real exercise count, sets (weight × reps) + drop-set tags. Floater activities listed separately when present.

## Settings

- **Split selector** (3 / 4 / 5 day) — changing it rebuilds the queue for the new split. Home, History, and Workout all reflect the active split.
- Machine ID page, and other personalization toggles. Back arrow returns to Home.

## Machine ID (/machine-id)

- Collects a machine identifier; can also append custom exercises to the active workout (persisted as user-added exercises).

## Data / Persistence Rules

- **Splits**: 3/4/5-day programs. Overlapping muscle days share templates; each split day mixes targeted work (Block A — e.g. real chest moves on chest day) with functional conditioning (Block B giant set — KB swings, sled, burpees). This is intentional.
- **Persistent workout draft**: every set edit / rating / exercise-add writes to a Hive `active_workout` box, plus a 2-minute periodic snapshot. Includes a timer snapshot with `savedAt`.
- **Crash recovery**: on startup, a draft < 2 hours old is restored (timer re-credits wall-clock elapsed time) and a Resume banner shows. A draft ≥ 2h is auto-finalized: every exercise with ≥ 1 logged set is kept (partials included), written to history as completed, the queue advances, progress updates, and the draft clears.
- **Progressive load**: per-exercise `UserProgress` — current weight, weight history, times performed, consecutive easy sessions. Updated on session completion/finalize.
- **History** always reads only finalized `workout_sessions`; drafts never pollute it.

## Notable current-state areas

- Set logging bug (primer index offset) fixed — reads/writes aligned; logging simply defaults to exercise targets.
- Recent-session tile bug fixed — shows the real logged exercise count.
- Repertoire of exercises from external dataset (1,324) is planned; not yet implemented.