import 'dart:math';

// ---------------------------------------------------------------------------
// Typedefs
// ---------------------------------------------------------------------------

/// A single seed entry: when it occurred and the field-UUID-keyed data map.
typedef SeedEntry = ({DateTime occurredAt, Map<String, dynamic> data});

/// A future todo: just a scheduled date.
typedef SeedTodo = ({DateTime scheduledFor});

// ---------------------------------------------------------------------------
// FieldLookup
// ---------------------------------------------------------------------------

/// Maps human-readable field labels to their UUIDs.
///
/// Used by generator functions so they can reference fields by name
/// (e.g. "Mood") without knowing the UUID ahead of time.
class FieldLookup {
  final Map<String, String> _map;

  const FieldLookup(this._map);

  /// Returns the UUID for [label]. Throws if missing.
  String operator [](String label) {
    final id = _map[label];
    if (id == null) {
      throw ArgumentError('FieldLookup: no UUID for label "$label". '
          'Available: ${_map.keys.join(', ')}');
    }
    return id;
  }

  /// Whether [label] exists in the lookup.
  bool has(String label) => _map.containsKey(label);
}

// ---------------------------------------------------------------------------
// Generator registry
// ---------------------------------------------------------------------------

/// Registry of entry generators keyed by template slug.
///
/// Each generator is a pure function: given a [FieldLookup] and a seeded
/// [Random], it returns a list of [SeedEntry] ready for insertion.
final Map<String, List<SeedEntry> Function(FieldLookup f, Random r)>
    entryGenerators = {
  'mood-energy': _generateMoodEnergy,
  'sleep': _generateSleep,
  'weight': _generateWeight,
  'period-tracker': _generatePeriodTracker,
  'journal': _generateJournal,
  'medication-log': _generateMedicationLog,
  'cardio-running': _generateCardioRunning,
  'cardio-cycling': _generateCardioCycling,
  'cardio-swimming': _generateCardioSwimming,
  'lifting': _generateLifting,
  'food': _generateFood,
  'water': _generateWater,
  'habits': _generateHabits,
  'habit': _generateHabit,
  'emotion': _generateEmotion,
  'symptoms-health': _generateSymptomsHealth,
  'work-productivity': _generateWorkProductivity,
};

/// Slugs that should also generate future todos.
const todosForSlugs = <String>{
  'mood-energy',
  'habit',
  'habits',
  'water',
};

// ---------------------------------------------------------------------------
// Todo generator
// ---------------------------------------------------------------------------

/// Returns 5 future [SeedTodo]s spread over the next 5 days.
List<SeedTodo> generateTodos(Random r) {
  final now = DateTime.now();
  return List.generate(5, (i) {
    final daysAhead = i + 1;
    final hour = 7 + r.nextInt(12); // 07:00 – 18:00
    return (
      scheduledFor: DateTime(
        now.year,
        now.month,
        now.day + daysAhead,
        hour,
        r.nextInt(60),
      ),
    );
  });
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

final _moodNotes = [
  'Feeling great today!',
  'A bit tired but okay.',
  'Had a wonderful morning walk.',
  'Stressed about work deadlines.',
  'Grateful for a good conversation.',
  'Couldn\'t sleep well last night.',
  'Energized after a workout.',
  'Rainy day, cozy vibes.',
  'Productive day at work.',
  'Took some time to meditate.',
  'Feeling a bit under the weather.',
  'Excited about the weekend.',
  'Had a great meal with friends.',
  'Need more sleep.',
  'Feeling calm and centered.',
];

String _randomMoodNote(Random r) => _moodNotes[r.nextInt(_moodNotes.length)];

final _journalEntries = [
  'Spent the morning reading a fascinating book about habits.',
  'Tried a new recipe for dinner — turned out surprisingly well.',
  'Had a long phone call with an old friend. Felt reconnected.',
  'Went for a hike in the hills. The view was breathtaking.',
  'Struggled with focus today. Maybe I need a change of scenery.',
  'Wrote down three things I\'m grateful for. Simple but effective.',
  'Started learning a new language. Day one is always exciting.',
  'Reflected on the past month. Growth is slow but visible.',
  'Cleaned and reorganized my workspace. Feels like a fresh start.',
  'Watched the sunset from the balcony. Peaceful moment.',
];

final _liftingExercises = [
  'Bench Press',
  'Squat',
  'Deadlift',
  'Overhead Press',
  'Barbell Row',
  'Pull-up',
  'Lunges',
  'Romanian Deadlift',
];

final _symptoms = [
  'Headache',
  'Fatigue',
  'Nausea',
  'Back pain',
  'Congestion',
  'Sore throat',
  'Dizziness',
  'Joint pain',
];

final _triggers = [
  'Stress',
  'Poor sleep',
  'Weather change',
  'Skipped meal',
  'Screen time',
  'Dehydration',
  'Allergens',
  'Unknown',
];

final _workNotes = [
  'Deep work session in the morning.',
  'Too many meetings today.',
  'Made good progress on the project.',
  'Got stuck on a tricky bug.',
  'Pair programming was productive.',
  'Need to prioritize better tomorrow.',
  'Wrapped up a milestone!',
  'Slow start but picked up after lunch.',
];

final _emotions = [
  'Happy',
  'Sad',
  'Anxious',
  'Calm',
  'Angry',
  'Grateful',
  'Excited',
  'Tired',
  'Hopeful',
  'Frustrated',
  'Content',
  'Surprised',
];

DateTime _daysAgo(int days) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day - days, 9 + days % 12,
      (days * 17) % 60);
}

bool _isWeekday(DateTime d) => d.weekday <= 5;

// ---------------------------------------------------------------------------
// Ported generators
// ---------------------------------------------------------------------------

List<SeedEntry> _generateMoodEnergy(FieldLookup f, Random r) {
  final entries = <SeedEntry>[];
  for (var day = 0; day < 30; day++) {
    if (r.nextDouble() < 0.15) continue; // 15% skip
    final mood = 5 + r.nextInt(5); // 5–9
    final energy = 3 + r.nextInt(7); // 3–9
    entries.add((
      occurredAt: _daysAgo(day),
      data: {
        f['Mood']: mood,
        f['Energy']: energy,
        f['Notes']: _randomMoodNote(r),
      },
    ));
  }
  return entries;
}

List<SeedEntry> _generateSleep(FieldLookup f, Random r) {
  final entries = <SeedEntry>[];
  for (var day = 0; day < 14; day++) {
    final hours = 6.0 + r.nextDouble() * 3.0; // 6.0–9.0
    final quality = 4 + r.nextInt(6); // 4–9
    entries.add((
      occurredAt: _daysAgo(day),
      data: {
        f['Hours Slept']: double.parse(hours.toStringAsFixed(1)),
        f['Sleep Quality']: quality,
        f['Woke Up Refreshed']: quality >= 7,
      },
    ));
  }
  return entries;
}

List<SeedEntry> _generateWeight(FieldLookup f, Random r) {
  final entries = <SeedEntry>[];
  final startWeight = 72.0 + r.nextDouble() * 5.0; // 72–77
  var weight = startWeight;
  for (var week = 0; week < 8; week++) {
    // Random walk: +-0.5 kg per week
    weight += (r.nextDouble() - 0.5) * 1.0;
    final notes = week == 0
        ? 'Starting measurement'
        : (r.nextBool() ? '' : 'After morning routine');
    entries.add((
      occurredAt: _daysAgo(week * 7),
      data: {
        f['Weight']: double.parse(weight.toStringAsFixed(1)),
        f['Notes']: notes,
      },
    ));
  }
  return entries;
}

List<SeedEntry> _generatePeriodTracker(FieldLookup f, Random r) {
  final entries = <SeedEntry>[];
  const logMean = 3.33;
  const logStd = 0.12;

  var cursor = _daysAgo(0);

  // Walk backwards through ~8 cycles
  for (var cycle = 0; cycle < 8; cycle++) {
    // Lognormal cycle length
    final z = _boxMullerZ(r);
    final cycleLength = exp(logMean + logStd * z).round().clamp(21, 40);

    // 3–5 days of flow per cycle
    final flowDays = 3 + r.nextInt(3);

    for (var day = 0; day < flowDays; day++) {
      // Flow tapers: starts high, decreases
      final intensity = (flowDays - day).clamp(1, 5);
      final cramps = 1 + r.nextInt(4); // 1–4
      final notes = day == 0 ? 'Cycle start' : '';
      entries.add((
        occurredAt: cursor.subtract(Duration(days: day)),
        data: {
          f['Flow Intensity']: intensity,
          f['Cramps']: cramps,
          f['Notes']: notes,
        },
      ));
    }

    cursor = cursor.subtract(Duration(days: cycleLength));
  }

  return entries;
}

List<SeedEntry> _generateJournal(FieldLookup f, Random r) {
  final entries = <SeedEntry>[];
  for (var i = 0; i < 10; i++) {
    final day = i * 2; // every 2 days, 20 days total
    entries.add((
      occurredAt: _daysAgo(day),
      data: {
        f['Entry']: _journalEntries[r.nextInt(_journalEntries.length)],
      },
    ));
  }
  return entries;
}

List<SeedEntry> _generateMedicationLog(FieldLookup f, Random r) {
  final entries = <SeedEntry>[];
  for (var day = 0; day < 14; day++) {
    final taken = r.nextDouble() < 0.90; // 90% adherence
    entries.add((
      occurredAt: _daysAgo(day),
      data: {
        f['Medication']: 'Vitamin D',
        f['Dosage']: 1000.0,
        f['Taken']: taken,
      },
    ));
  }
  return entries;
}

// ---------------------------------------------------------------------------
// New generators
// ---------------------------------------------------------------------------

List<SeedEntry> _generateCardioRunning(FieldLookup f, Random r) {
  final entries = <SeedEntry>[];
  for (var day = 0; day < 20; day++) {
    if (r.nextDouble() < 0.50) continue; // 50% skip
    final distance = 3.0 + r.nextDouble() * 7.0; // 3–10 km
    final duration = 20 + r.nextInt(41); // 20–60 min
    entries.add((
      occurredAt: _daysAgo(day),
      data: {
        f['Distance (km)']: double.parse(distance.toStringAsFixed(1)),
        f['Duration']: duration,
        f['Notes']: '',
      },
    ));
  }
  return entries;
}

List<SeedEntry> _generateCardioCycling(FieldLookup f, Random r) {
  final entries = <SeedEntry>[];
  for (var day = 0; day < 20; day++) {
    if (r.nextDouble() < 0.50) continue;
    final distance = 10.0 + r.nextDouble() * 30.0; // 10–40 km
    final duration = 30 + r.nextInt(61); // 30–90 min
    entries.add((
      occurredAt: _daysAgo(day),
      data: {
        f['Distance (km)']: double.parse(distance.toStringAsFixed(1)),
        f['Duration']: duration,
        f['Notes']: '',
      },
    ));
  }
  return entries;
}

List<SeedEntry> _generateCardioSwimming(FieldLookup f, Random r) {
  final entries = <SeedEntry>[];
  for (var day = 0; day < 20; day++) {
    if (r.nextDouble() < 0.50) continue;
    final laps = 10 + r.nextInt(41); // 10–50
    final duration = 20 + r.nextInt(41); // 20–60 min
    entries.add((
      occurredAt: _daysAgo(day),
      data: {
        f['Laps']: laps,
        f['Duration']: duration,
        f['Notes']: '',
      },
    ));
  }
  return entries;
}

List<SeedEntry> _generateLifting(FieldLookup f, Random r) {
  final entries = <SeedEntry>[];
  for (var day = 0; day < 20; day++) {
    if (r.nextDouble() < 0.50) continue;
    final exercise =
        _liftingExercises[r.nextInt(_liftingExercises.length)];
    final setCount = 3 + r.nextInt(3); // 3–5 sets
    final sets = List.generate(setCount, (_) {
      return {
        'Weight': double.parse(
            (20.0 + r.nextDouble() * 80.0).toStringAsFixed(1)),
        'Reps': 5 + r.nextInt(11), // 5–15
        'RPE': 5 + r.nextInt(5), // 5–9
      };
    });
    entries.add((
      occurredAt: _daysAgo(day),
      data: {
        f['Exercise']: exercise,
        f['Sets']: sets,
        f['Notes']: '',
      },
    ));
  }
  return entries;
}

List<SeedEntry> _generateFood(FieldLookup f, Random r) {
  final entries = <SeedEntry>[];
  for (var day = 0; day < 30; day++) {
    final mealsPerDay = 2 + r.nextInt(2); // 2–3
    for (var meal = 0; meal < mealsPerDay; meal++) {
      final hourOffset = 7 + meal * 5 + r.nextInt(2); // ~7, ~12, ~17
      final base = _daysAgo(day);
      final occurredAt = DateTime(
        base.year,
        base.month,
        base.day,
        hourOffset,
        r.nextInt(60),
      );
      entries.add((
        occurredAt: occurredAt,
        data: {
          f['Calories']: 300 + r.nextInt(501), // 300–800
          f['Protein']: double.parse(
              (10.0 + r.nextDouble() * 40.0).toStringAsFixed(1)),
          f['Carbs']: double.parse(
              (20.0 + r.nextDouble() * 60.0).toStringAsFixed(1)),
          f['Fat']: double.parse(
              (5.0 + r.nextDouble() * 30.0).toStringAsFixed(1)),
        },
      ));
    }
  }
  return entries;
}

List<SeedEntry> _generateWater(FieldLookup f, Random r) {
  final entries = <SeedEntry>[];
  for (var day = 0; day < 30; day++) {
    final cups = 4 + r.nextInt(6); // 4–9
    entries.add((
      occurredAt: _daysAgo(day),
      data: {
        f['Cups']: cups,
      },
    ));
  }
  return entries;
}

List<SeedEntry> _generateHabits(FieldLookup f, Random r) {
  // "Meditated" habit
  final entries = <SeedEntry>[];
  for (var day = 0; day < 30; day++) {
    entries.add((
      occurredAt: _daysAgo(day),
      data: {
        f['Done']: r.nextDouble() < 0.70, // 70% true
      },
    ));
  }
  return entries;
}

List<SeedEntry> _generateHabit(FieldLookup f, Random r) {
  final entries = <SeedEntry>[];
  for (var day = 0; day < 30; day++) {
    entries.add((
      occurredAt: _daysAgo(day),
      data: {
        f['Name']: 'Read 20 pages',
        f['Done']: r.nextDouble() < 0.60, // 60% true
      },
    ));
  }
  return entries;
}

List<SeedEntry> _generateEmotion(FieldLookup f, Random r) {
  final entries = <SeedEntry>[];
  for (var day = 0; day < 30; day++) {
    final count = 1 + r.nextInt(3); // 1–3 emotions
    final selected = <String>{};
    while (selected.length < count) {
      selected.add(_emotions[r.nextInt(_emotions.length)]);
    }
    entries.add((
      occurredAt: _daysAgo(day),
      data: {
        f['Emotions']: selected.toList(),
      },
    ));
  }
  return entries;
}

List<SeedEntry> _generateSymptomsHealth(FieldLookup f, Random r) {
  final entries = <SeedEntry>[];
  for (var day = 0; day < 14; day++) {
    if (r.nextDouble() < 0.50) continue; // 50% skip
    entries.add((
      occurredAt: _daysAgo(day),
      data: {
        f['Symptom']: _symptoms[r.nextInt(_symptoms.length)],
        f['Severity']: 2 + r.nextInt(4), // 2–5
        f['Trigger']: _triggers[r.nextInt(_triggers.length)],
        f['Notes']: '',
      },
    ));
  }
  return entries;
}

List<SeedEntry> _generateWorkProductivity(FieldLookup f, Random r) {
  final entries = <SeedEntry>[];
  for (var day = 0; day < 20; day++) {
    final date = _daysAgo(day);
    if (!_isWeekday(date)) continue; // weekdays only
    entries.add((
      occurredAt: date,
      data: {
        f['Focus Time']: 60 + r.nextInt(181), // 60–240 min
        f['Tasks Completed']: 2 + r.nextInt(6), // 2–7
        f['Notes']: _workNotes[r.nextInt(_workNotes.length)],
      },
    ));
  }
  return entries;
}

// ---------------------------------------------------------------------------
// Math helpers
// ---------------------------------------------------------------------------

/// Box-Muller transform: returns a standard-normal random variate.
double _boxMullerZ(Random r) {
  final u1 = r.nextDouble();
  final u2 = r.nextDouble();
  return sqrt(-2.0 * log(u1)) * cos(2.0 * pi * u2);
}

/// Natural exponential (e^x). Dart's `math` has `exp` but we import via
/// the `dart:math` show.
double exp(double x) => pow(e, x).toDouble();
