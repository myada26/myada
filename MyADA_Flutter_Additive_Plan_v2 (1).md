# MyADA — Flutter Additive Implementation Plan
## Based on Actual Project Structure at c:\Flutter_Projects\my_ada\my_ada\
## Antigravity Agent — Add and Refactor Only. Zero Restructuring.

---

## AGENT RULES — READ THIS ENTIRE SECTION BEFORE OPENING ANY FILE

You are working on an **existing, partially-built Flutter project**.
Your job is to ADD missing pieces and REFACTOR where needed.
You are NOT allowed to rename, move, delete, or restructure anything.

### Files you must NEVER touch or overwrite:
- `lib/main.dart`
- `lib/core/theme/app_colors.dart`
- `lib/core/theme/app_text_styles.dart`
- `lib/core/theme/app_spacing.dart`
- `lib/core/constants/app_constants.dart`
- `lib/shared/widgets/main_nav_shell.dart`
- `lib/shared/widgets/empty_state_widget.dart`
- `lib/components/buttons/app_button.dart`
- `lib/components/cards/app_cards.dart`

### Files you CAN read and carefully append to (never full rewrite):
- `lib/features/home/presentation/screens/home_screen.dart`
- `lib/features/learn/presentation/screens/learn_screen.dart`
- `lib/features/ranks/presentation/screens/ranks_screen.dart`
- `lib/features/progress/presentation/screens/progress_screen.dart`
- `lib/features/profile/presentation/screens/profile_screen.dart`
- `lib/controllers/diagnostic_controller.dart`
- `lib/models/diagnostic_models.dart`
- `lib/models/learning_path_model.dart`
- `pubspec.yaml`

### Files you CREATE from scratch (these do not exist yet):
Everything listed in the phases below.

---

## ACTUAL CURRENT STRUCTURE (confirmed from project tree)

```
lib/
├── main.dart                                          ← EXISTS, do not touch
├── components/
│   ├── buttons/app_button.dart                        ← EXISTS, do not touch
│   └── cards/app_cards.dart                           ← EXISTS, do not touch
├── controllers/
│   └── diagnostic_controller.dart                     ← EXISTS, read before editing
├── core/
│   ├── constants/app_constants.dart                   ← EXISTS, do not touch
│   └── theme/
│       ├── app_colors.dart                            ← EXISTS, do not touch
│       ├── app_spacing.dart                           ← EXISTS, do not touch
│       └── app_text_styles.dart                       ← EXISTS, do not touch
├── features/
│   ├── home/presentation/screens/home_screen.dart     ← EXISTS, read before editing
│   ├── learn/presentation/screens/learn_screen.dart   ← EXISTS, read before editing
│   ├── profile/presentation/screens/profile_screen.dart ← EXISTS, read before editing
│   ├── progress/presentation/screens/progress_screen.dart ← EXISTS, read before editing
│   └── ranks/presentation/screens/ranks_screen.dart   ← EXISTS, read before editing
├── models/
│   ├── diagnostic_models.dart                         ← EXISTS, read before editing
│   └── learning_path_model.dart                       ← EXISTS, read before editing
└── shared/
    └── widgets/
        ├── empty_state_widget.dart                    ← EXISTS, do not touch
        └── main_nav_shell.dart                        ← EXISTS, do not touch
```

---

## STEP 1 — pubspec.yaml

Read `pubspec.yaml` first. Then append ONLY the dependencies below that are
not already present. Do not change any existing line.

```yaml
# Append under dependencies: (check each one — skip if already present)
  sqflite: ^2.3.3
  path: ^1.9.0
  connectivity_plus: ^6.0.3
  uuid: ^4.4.0
  intl: ^0.19.0
  shared_preferences: ^2.2.3
  flutter_riverpod: ^2.5.1

# Append under flutter: assets: (create the block if it does not exist)
flutter:
  assets:
    - assets/data/modules.json
    - assets/data/quiz_questions.json
    - assets/data/retry_questions.json
    - assets/data/diagnostic_questions.json
```

After editing, run: `flutter pub get`

---

## STEP 2 — CREATE ASSET DATA FOLDER

Create folder: `assets/data/`
Create these four JSON seed files inside it.

### `assets/data/modules.json`
```json
[
  { "id": "module_01", "sequence_order": 1,
    "title": "The genesis of execution",
    "description": "Output and memory — your first Python programs.",
    "skill_tag": "sequencing", "estimated_minutes": 25 },
  { "id": "module_02", "sequence_order": 2,
    "title": "The data blueprint",
    "description": "Types, operators, and user input.",
    "skill_tag": "syntax", "estimated_minutes": 30 },
  { "id": "module_03", "sequence_order": 3,
    "title": "Branching realities",
    "description": "Conditional logic — if, elif, else.",
    "skill_tag": "logic_flow", "estimated_minutes": 35 },
  { "id": "module_04", "sequence_order": 4,
    "title": "Cycles and simulations",
    "description": "For and while loops.",
    "skill_tag": "logic_flow", "estimated_minutes": 40 },
  { "id": "module_05", "sequence_order": 5,
    "title": "Architects of abstraction",
    "description": "Functions, parameters, scope, return values.",
    "skill_tag": "computational_thinking", "estimated_minutes": 40 },
  { "id": "module_06", "sequence_order": 6,
    "title": "Textual forensics",
    "description": "Advanced string manipulation and methods.",
    "skill_tag": "syntax", "estimated_minutes": 30 },
  { "id": "module_07", "sequence_order": 7,
    "title": "The data arsenal",
    "description": "Lists, tuples, indexing, and iteration.",
    "skill_tag": "sequencing", "estimated_minutes": 40 },
  { "id": "module_08", "sequence_order": 8,
    "title": "Associative architecture",
    "description": "Dictionaries, sets, and key-value data.",
    "skill_tag": "computational_thinking", "estimated_minutes": 35 },
  { "id": "module_09", "sequence_order": 9,
    "title": "Resilience and resolution",
    "description": "Error handling, tracebacks, try/except.",
    "skill_tag": "debugging", "estimated_minutes": 30 },
  { "id": "module_10", "sequence_order": 10,
    "title": "The giant's shoulders",
    "description": "Importing modules and the standard library.",
    "skill_tag": "computational_thinking", "estimated_minutes": 25 },
  { "id": "module_11", "sequence_order": 11,
    "title": "Persistent memory",
    "description": "File I/O — reading and writing data.",
    "skill_tag": "sequencing", "estimated_minutes": 30 },
  { "id": "module_12", "sequence_order": 12,
    "title": "Paradigms of objects",
    "description": "Intro to OOP — classes, methods, instances.",
    "skill_tag": "computational_thinking", "estimated_minutes": 40 }
]
```

### `assets/data/diagnostic_questions.json`
Each skill has 2 questions: tier 1 (easy) and tier 2 (hard).
Total: 10 questions (5 skills × 2 tiers).
```json
[
  {
    "id": "dq_seq_t1",
    "skill_tag": "sequencing",
    "tier": 1,
    "question_type": "parsons",
    "prompt_text": "Arrange these lines in the correct order to print 'Hello Ada'.",
    "content": {
      "lines": ["print('Hello Ada')", "name = 'Ada'", "greeting = 'Hello '"],
      "correct_order": [1, 2, 0]
    },
    "correct_answer": "1,2,0"
  },
  {
    "id": "dq_seq_t2",
    "skill_tag": "sequencing",
    "tier": 2,
    "question_type": "parsons",
    "prompt_text": "Arrange these lines to compute and print the sum of 1 to 5.",
    "content": {
      "lines": ["print(total)", "total = 0", "for i in range(1, 6):", "    total += i"],
      "correct_order": [1, 2, 3, 0]
    },
    "correct_answer": "1,2,3,0"
  },
  {
    "id": "dq_logic_t1",
    "skill_tag": "logic_flow",
    "tier": 1,
    "question_type": "multiple_choice",
    "prompt_text": "What does this print?\nx = 10\nif x > 5:\n    print('big')\nelse:\n    print('small')",
    "content": {
      "options": ["small", "big", "10", "Error"],
      "correct_index": 1
    },
    "correct_answer": "1"
  },
  {
    "id": "dq_logic_t2",
    "skill_tag": "logic_flow",
    "tier": 2,
    "question_type": "multiple_choice",
    "prompt_text": "What is the output?\nfor i in range(3):\n    if i == 1:\n        continue\n    print(i)",
    "content": {
      "options": ["0 1 2", "0 2", "1 2", "0 1"],
      "correct_index": 1
    },
    "correct_answer": "1"
  },
  {
    "id": "dq_debug_t1",
    "skill_tag": "debugging",
    "tier": 1,
    "question_type": "spot_bug",
    "prompt_text": "Find the bug in this code.",
    "content": {
      "buggy_code": "for i in range(5)\n    print(i)",
      "bug_description": "Missing colon after range(5)"
    },
    "correct_answer": "Missing colon after range(5)"
  },
  {
    "id": "dq_debug_t2",
    "skill_tag": "debugging",
    "tier": 2,
    "question_type": "spot_bug",
    "prompt_text": "What is wrong with this function?",
    "content": {
      "buggy_code": "def add(a, b):\n    result = a + b\nprint(result)",
      "bug_description": "print(result) is outside the function and result is not in scope"
    },
    "correct_answer": "print(result) is outside the function"
  },
  {
    "id": "dq_syntax_t1",
    "skill_tag": "syntax",
    "tier": 1,
    "question_type": "fill_in_blank",
    "prompt_text": "Complete the line to convert user input to an integer.",
    "content": {
      "code_with_blank": "age = _____(input('Enter age: '))",
      "hint": "Type conversion function"
    },
    "correct_answer": "int"
  },
  {
    "id": "dq_syntax_t2",
    "skill_tag": "syntax",
    "tier": 2,
    "question_type": "fill_in_blank",
    "prompt_text": "Complete the f-string.",
    "content": {
      "code_with_blank": "name = 'Ada'\nprint(_____'Hello {name}!')",
      "hint": "f-string prefix character"
    },
    "correct_answer": "f"
  },
  {
    "id": "dq_ct_t1",
    "skill_tag": "computational_thinking",
    "tier": 1,
    "question_type": "multiple_choice",
    "prompt_text": "You need to do the same task 100 times. What is the best approach?",
    "content": {
      "options": [
        "Write the code 100 times",
        "Use a loop",
        "Use 100 variables",
        "Use 100 functions"
      ],
      "correct_index": 1
    },
    "correct_answer": "1"
  },
  {
    "id": "dq_ct_t2",
    "skill_tag": "computational_thinking",
    "tier": 2,
    "question_type": "multiple_choice",
    "prompt_text": "A function that calls itself is called a _____ function.",
    "content": {
      "options": ["iterative", "recursive", "sequential", "parallel"],
      "correct_index": 1
    },
    "correct_answer": "1"
  }
]
```

### `assets/data/quiz_questions.json`
Placeholder structure — the agent must generate 10 questions per module (120 total).
Each question must follow this exact schema:
```json
[
  {
    "id": "m01_q01",
    "module_id": "module_01",
    "question_type": "multiple_choice",
    "skill_tag": "sequencing",
    "difficulty_tier": 1,
    "prompt_text": "What will this print?\nprint('Hello, World!')",
    "content": {
      "options": ["Hello, World!", "print", "Hello", "Error"],
      "correct_index": 0
    },
    "correct_answer": "0",
    "explanation": "print() outputs whatever is inside the parentheses as text.",
    "point_weight": 1.0,
    "is_retry_eligible": false
  }
]
```

Per-module question type distribution (10 questions per module):
- 3 × multiple_choice (point_weight: 1.0)
- 2 × parsons        (point_weight: 1.5)
- 2 × fill_in_blank  (point_weight: 1.5)
- 2 × spot_bug       (point_weight: 1.5)
- 1 × coding         (point_weight: 2.0)

### `assets/data/retry_questions.json`
6 questions per module (72 total). Same schema as quiz_questions.json.
Set `"is_retry_eligible": true` on all of them.
Per-module retry distribution:
- 3 × multiple_choice
- 2 × fill_in_blank
- 1 × spot_bug
No coding questions in retry. No parsons required but allowed.

---

## STEP 3 — DATABASE LAYER

Create new folder: `lib/core/database/`

### `lib/core/database/app_database.dart`

```dart
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AppDatabase {
  static AppDatabase? _instance;
  static Database? _db;

  AppDatabase._();

  static AppDatabase get instance {
    _instance ??= AppDatabase._();
    return _instance!;
  }

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = join(await getDatabasesPath(), 'myada.db');
    return openDatabase(
      dbPath,
      version: 1,
      onCreate: _createSchema,
      onOpen: (db) async => await _seedIfNeeded(db),
    );
  }

  Future<void> _createSchema(Database db, int version) async {
    final batch = db.batch();

    batch.execute('''CREATE TABLE IF NOT EXISTS learners (
      id TEXT PRIMARY KEY,
      first_name TEXT NOT NULL,
      last_name TEXT NOT NULL,
      email TEXT UNIQUE NOT NULL,
      created_at TEXT NOT NULL,
      last_active TEXT
    )''');

    batch.execute('''CREATE TABLE IF NOT EXISTS modules (
      id TEXT PRIMARY KEY,
      sequence_order INTEGER NOT NULL UNIQUE,
      title TEXT NOT NULL,
      description TEXT NOT NULL,
      skill_tag TEXT NOT NULL,
      estimated_minutes INTEGER NOT NULL
    )''');

    batch.execute('''CREATE TABLE IF NOT EXISTS lessons (
      id TEXT PRIMARY KEY,
      module_id TEXT NOT NULL,
      sequence_order INTEGER NOT NULL,
      title TEXT NOT NULL,
      content_json TEXT NOT NULL,
      FOREIGN KEY (module_id) REFERENCES modules(id),
      UNIQUE(module_id, sequence_order)
    )''');

    batch.execute('''CREATE TABLE IF NOT EXISTS quiz_questions (
      id TEXT PRIMARY KEY,
      module_id TEXT NOT NULL,
      question_type TEXT NOT NULL,
      skill_tag TEXT NOT NULL,
      difficulty_tier INTEGER NOT NULL,
      prompt_text TEXT NOT NULL,
      content_json TEXT NOT NULL,
      correct_answer TEXT NOT NULL,
      explanation TEXT NOT NULL,
      point_weight REAL NOT NULL DEFAULT 1.0,
      is_retry_eligible INTEGER NOT NULL DEFAULT 0,
      FOREIGN KEY (module_id) REFERENCES modules(id)
    )''');

    batch.execute('''CREATE TABLE IF NOT EXISTS diagnostic_questions (
      id TEXT PRIMARY KEY,
      skill_tag TEXT NOT NULL,
      tier INTEGER NOT NULL,
      question_type TEXT NOT NULL,
      prompt_text TEXT NOT NULL,
      content_json TEXT NOT NULL,
      correct_answer TEXT NOT NULL
    )''');

    batch.execute('''CREATE TABLE IF NOT EXISTS module_unlocks (
      id TEXT PRIMARY KEY,
      learner_id TEXT NOT NULL,
      module_id TEXT NOT NULL,
      unlocked_at TEXT NOT NULL,
      unlock_reason TEXT NOT NULL,
      FOREIGN KEY (learner_id) REFERENCES learners(id),
      FOREIGN KEY (module_id) REFERENCES modules(id),
      UNIQUE(learner_id, module_id)
    )''');

    batch.execute('''CREATE TABLE IF NOT EXISTS lesson_completions (
      id TEXT PRIMARY KEY,
      learner_id TEXT NOT NULL,
      lesson_id TEXT NOT NULL,
      completed_at TEXT NOT NULL,
      FOREIGN KEY (learner_id) REFERENCES learners(id),
      UNIQUE(learner_id, lesson_id)
    )''');

    batch.execute('''CREATE TABLE IF NOT EXISTS quiz_attempts (
      id TEXT PRIMARY KEY,
      learner_id TEXT NOT NULL,
      module_id TEXT NOT NULL,
      attempt_type TEXT NOT NULL,
      attempt_number INTEGER NOT NULL DEFAULT 1,
      started_at TEXT NOT NULL,
      submitted_at TEXT,
      time_limit_seconds INTEGER NOT NULL,
      time_used_seconds INTEGER,
      accuracy_score INTEGER NOT NULL DEFAULT 0,
      time_bonus INTEGER NOT NULL DEFAULT 0,
      first_attempt_bonus INTEGER NOT NULL DEFAULT 0,
      streak_bonus INTEGER NOT NULL DEFAULT 0,
      total_score INTEGER NOT NULL DEFAULT 0,
      passed INTEGER,
      accuracy_pct REAL,
      skill_level_achieved TEXT,
      FOREIGN KEY (learner_id) REFERENCES learners(id),
      FOREIGN KEY (module_id) REFERENCES modules(id)
    )''');

    batch.execute('''CREATE TABLE IF NOT EXISTS quiz_responses (
      id TEXT PRIMARY KEY,
      attempt_id TEXT NOT NULL,
      question_id TEXT NOT NULL,
      answer_given TEXT,
      is_correct INTEGER,
      was_skipped INTEGER NOT NULL DEFAULT 0,
      points_earned INTEGER NOT NULL DEFAULT 0,
      time_taken_seconds INTEGER,
      answered_at TEXT NOT NULL,
      FOREIGN KEY (attempt_id) REFERENCES quiz_attempts(id)
    )''');

    batch.execute('''CREATE TABLE IF NOT EXISTS skill_profiles (
      id TEXT PRIMARY KEY,
      learner_id TEXT NOT NULL,
      skill_tag TEXT NOT NULL,
      level TEXT NOT NULL,
      raw_score REAL NOT NULL DEFAULT 0,
      updated_at TEXT NOT NULL,
      FOREIGN KEY (learner_id) REFERENCES learners(id),
      UNIQUE(learner_id, skill_tag)
    )''');

    batch.execute('''CREATE TABLE IF NOT EXISTS diagnostic_sessions (
      id TEXT PRIMARY KEY,
      learner_id TEXT NOT NULL,
      completed_at TEXT,
      overall_level TEXT,
      bypass_reason TEXT,
      FOREIGN KEY (learner_id) REFERENCES learners(id)
    )''');

    batch.execute('''CREATE TABLE IF NOT EXISTS leaderboard_scores (
      id TEXT PRIMARY KEY,
      learner_id TEXT NOT NULL UNIQUE,
      total_points INTEGER NOT NULL DEFAULT 0,
      modules_completed INTEGER NOT NULL DEFAULT 0,
      first_attempt_passes INTEGER NOT NULL DEFAULT 0,
      current_streak INTEGER NOT NULL DEFAULT 0,
      longest_streak INTEGER NOT NULL DEFAULT 0,
      last_updated TEXT NOT NULL,
      FOREIGN KEY (learner_id) REFERENCES learners(id)
    )''');

    batch.execute('''CREATE TABLE IF NOT EXISTS learner_badges (
      id TEXT PRIMARY KEY,
      learner_id TEXT NOT NULL,
      badge_id TEXT NOT NULL,
      earned_at TEXT NOT NULL,
      FOREIGN KEY (learner_id) REFERENCES learners(id),
      UNIQUE(learner_id, badge_id)
    )''');

    batch.execute('''CREATE TABLE IF NOT EXISTS learner_certificates (
      id TEXT PRIMARY KEY,
      learner_id TEXT NOT NULL,
      module_id TEXT NOT NULL,
      cert_code TEXT NOT NULL UNIQUE,
      issued_at TEXT NOT NULL,
      score_pct REAL NOT NULL,
      skills_covered TEXT NOT NULL,
      FOREIGN KEY (learner_id) REFERENCES learners(id),
      UNIQUE(learner_id, module_id)
    )''');

    batch.execute('''CREATE TABLE IF NOT EXISTS sync_queue (
      id TEXT PRIMARY KEY,
      table_name TEXT NOT NULL,
      record_id TEXT NOT NULL,
      operation TEXT NOT NULL,
      payload TEXT NOT NULL,
      created_at TEXT NOT NULL,
      synced_at TEXT,
      sync_attempts INTEGER NOT NULL DEFAULT 0
    )''');

    batch.execute('''CREATE TABLE IF NOT EXISTS app_meta (
      key TEXT PRIMARY KEY,
      value TEXT NOT NULL
    )''');

    await batch.commit(noResult: true);

    await db.insert('app_meta', {'key': 'schema_version', 'value': '1'},
        conflictAlgorithm: ConflictAlgorithm.ignore);
    await db.insert('app_meta', {'key': 'seed_loaded', 'value': '0'},
        conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> _seedIfNeeded(Database db) async {
    final meta = await db.query('app_meta',
        where: 'key = ?', whereArgs: ['seed_loaded']);
    if (meta.isNotEmpty && meta.first['value'] == '1') return;

    await _loadJsonAsset(db, 'assets/data/modules.json', 'modules');
    await _loadJsonAsset(db, 'assets/data/quiz_questions.json', 'quiz_questions',
        transform: (m) => {
          ...m,
          'content_json': jsonEncode(m['content']),
          'is_retry_eligible': (m['is_retry_eligible'] as bool) ? 1 : 0,
        });
    await _loadJsonAsset(db, 'assets/data/retry_questions.json', 'quiz_questions',
        transform: (m) => {
          ...m,
          'content_json': jsonEncode(m['content']),
          'is_retry_eligible': 1,
        });
    await _loadJsonAsset(db, 'assets/data/diagnostic_questions.json',
        'diagnostic_questions',
        transform: (m) => {
          ...m,
          'content_json': jsonEncode(m['content']),
        });

    await db.update('app_meta', {'value': '1'},
        where: 'key = ?', whereArgs: ['seed_loaded']);
  }

  Future<void> _loadJsonAsset(
    Database db,
    String assetPath,
    String tableName, {
    Map<String, dynamic> Function(Map<String, dynamic>)? transform,
  }) async {
    final raw = await rootBundle.loadString(assetPath);
    final List<dynamic> items = jsonDecode(raw);
    final batch = db.batch();
    for (final item in items) {
      final map = Map<String, dynamic>.from(item as Map);
      final row = transform != null ? transform(map) : map;
      // Remove keys not in table schema
      row.remove('content');
      batch.insert(tableName, row,
          conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    await batch.commit(noResult: true);
  }
}
```

---

## STEP 4 — MODELS

### Read `lib/models/diagnostic_models.dart` first.

Then append these classes at the bottom IF they do not already exist.
Do not rewrite any existing class.

```dart
// APPEND to lib/models/diagnostic_models.dart
// Only add classes that are not already defined in the file.

enum SkillTag {
  sequencing,
  logicFlow,
  debugging,
  syntax,
  computationalThinking;

  String get dbValue => switch (this) {
    SkillTag.sequencing            => 'sequencing',
    SkillTag.logicFlow             => 'logic_flow',
    SkillTag.debugging             => 'debugging',
    SkillTag.syntax                => 'syntax',
    SkillTag.computationalThinking => 'computational_thinking',
  };

  static SkillTag fromString(String s) => switch (s) {
    'sequencing'             => SkillTag.sequencing,
    'logic_flow'             => SkillTag.logicFlow,
    'debugging'              => SkillTag.debugging,
    'syntax'                 => SkillTag.syntax,
    'computational_thinking' => SkillTag.computationalThinking,
    _                        => SkillTag.sequencing,
  };
}

enum SkillLevel {
  developing,
  building,
  confident;

  static SkillLevel fromString(String s) => switch (s) {
    'building'  => SkillLevel.building,
    'confident' => SkillLevel.confident,
    _           => SkillLevel.developing,
  };
}

class DiagnosticResponse {
  final SkillTag skillTag;
  final int tier;
  final bool isCorrect;
  final bool wasSkipped;

  const DiagnosticResponse({
    required this.skillTag,
    required this.tier,
    required this.isCorrect,
    required this.wasSkipped,
  });

  factory DiagnosticResponse.skipped(SkillTag tag, int tier) =>
      DiagnosticResponse(
          skillTag: tag, tier: tier, isCorrect: false, wasSkipped: true);
}

class SkillScore {
  final SkillTag skillTag;
  final double rawScore;
  final SkillLevel level;
  const SkillScore(
      {required this.skillTag,
      required this.rawScore,
      required this.level});
}

class DiagnosticResult {
  final List<SkillScore> skillScores;
  final String overallLevel; // 'beginner' | 'novice' | 'intermediate'
  final List<String> modulesToSkip;
  final List<String> modulesRequired;

  const DiagnosticResult({
    required this.skillScores,
    required this.overallLevel,
    required this.modulesToSkip,
    required this.modulesRequired,
  });
}
```

### Read `lib/models/learning_path_model.dart` first.

Then append IF not already present:

```dart
// APPEND to lib/models/learning_path_model.dart

enum ModuleStatus {
  mastered,    // Skipped via diagnostic — pre-existing knowledge
  required,    // Unlocked and must be completed
  inProgress,  // Currently active
  completed,   // Quiz passed
  locked,      // Not yet unlocked
}

class ModulePath {
  final String moduleId;
  final ModuleStatus status;
  final String? unlockedAt;
  final String? unlockReason;
  final SkillLevel? currentSkillLevel;

  const ModulePath({
    required this.moduleId,
    required this.status,
    this.unlockedAt,
    this.unlockReason,
    this.currentSkillLevel,
  });

  ModulePath copyWith({ModuleStatus? status, SkillLevel? currentSkillLevel}) =>
      ModulePath(
        moduleId: moduleId,
        status: status ?? this.status,
        unlockedAt: unlockedAt,
        unlockReason: unlockReason,
        currentSkillLevel: currentSkillLevel ?? this.currentSkillLevel,
      );
}

class QuizAttemptModel {
  final String id;
  final String learnerId;
  final String moduleId;
  final String attemptType; // 'module_quiz' | 'retry_quiz'
  final int attemptNumber;
  final int timeLimitSeconds;
  final int? timeUsedSeconds;
  final int accuracyScore;
  final int timeBonus;
  final int firstAttemptBonus;
  final int streakBonus;
  final int totalScore;
  final bool? passed;
  final double? accuracyPct;
  final String? skillLevelAchieved;

  const QuizAttemptModel({
    required this.id,
    required this.learnerId,
    required this.moduleId,
    required this.attemptType,
    required this.attemptNumber,
    required this.timeLimitSeconds,
    this.timeUsedSeconds,
    this.accuracyScore = 0,
    this.timeBonus = 0,
    this.firstAttemptBonus = 0,
    this.streakBonus = 0,
    this.totalScore = 0,
    this.passed,
    this.accuracyPct,
    this.skillLevelAchieved,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'learner_id': learnerId,
    'module_id': moduleId,
    'attempt_type': attemptType,
    'attempt_number': attemptNumber,
    'time_limit_seconds': timeLimitSeconds,
    'time_used_seconds': timeUsedSeconds,
    'accuracy_score': accuracyScore,
    'time_bonus': timeBonus,
    'first_attempt_bonus': firstAttemptBonus,
    'streak_bonus': streakBonus,
    'total_score': totalScore,
    'passed': passed == null ? null : (passed! ? 1 : 0),
    'accuracy_pct': accuracyPct,
    'skill_level_achieved': skillLevelAchieved,
    'started_at': DateTime.now().toIso8601String(),
  };
}
```

---

## STEP 5 — SCORING ENGINE

Create new folder: `lib/core/engine/`

### `lib/core/engine/scoring_engine.dart`

```dart
class ScoringConstants {
  static const Map<String, int> questionWeights = {
    'multiple_choice': 10,
    'parsons':         15,
    'fill_in_blank':   15,
    'spot_bug':        15,
    'coding':          20,
    'coding_partial':  10,
  };

  static const int    timeBonusMax         = 30;
  static const double fullZoneThreshold    = 0.30;
  static const double zeroZoneThreshold    = 0.70;
  static const int    firstAttemptBonus    = 15;
  static const int    streakBonus          = 20;
  static const double passThreshold        = 0.70;
  static const double confidentThreshold   = 0.90;
  static const int    moduleQuizMinutes    = 15;
  static const int    retryQuizMinutes     = 10;
  static const int    maxModuleScore       = 185;
}

class QuizSessionResult {
  final int    accuracyScore;
  final int    timeBonus;
  final int    firstAttemptBonus;
  final int    streakBonus;
  final int    totalScore;
  final double accuracyPct;
  final bool   passed;
  final String skillLevelAchieved;

  const QuizSessionResult({
    required this.accuracyScore,
    required this.timeBonus,
    required this.firstAttemptBonus,
    required this.streakBonus,
    required this.totalScore,
    required this.accuracyPct,
    required this.passed,
    required this.skillLevelAchieved,
  });
}

class ScoringEngine {
  /// 3-zone time bonus.
  /// Zone 1 — used ≤ 30% of limit  → full +30
  /// Zone 2 — used 30%–70%         → linear decay to 0
  /// Zone 3 — used ≥ 70% of limit  → +0
  static int calcTimeBonus(int timeUsedSeconds, int timeLimitSeconds) {
    if (timeLimitSeconds == 0) return 0;
    final pct = timeUsedSeconds / timeLimitSeconds;
    if (pct <= ScoringConstants.fullZoneThreshold) {
      return ScoringConstants.timeBonusMax;
    }
    if (pct >= ScoringConstants.zeroZoneThreshold) return 0;
    final decay = (pct - ScoringConstants.fullZoneThreshold) /
        (ScoringConstants.zeroZoneThreshold -
            ScoringConstants.fullZoneThreshold);
    return (ScoringConstants.timeBonusMax * (1 - decay)).floor();
  }

  /// Points for a single question.
  static int calcQuestionPoints({
    required String questionType,
    required bool isCorrect,
    bool isPartialCredit = false,
  }) {
    if (!isCorrect && !isPartialCredit) return 0;
    if (isPartialCredit && questionType == 'coding') {
      return ScoringConstants.questionWeights['coding_partial'] ?? 10;
    }
    return ScoringConstants.questionWeights[questionType] ?? 10;
  }

  /// Skill level from accuracy percentage.
  static String resolveSkillLevel(double accuracyPct) {
    if (accuracyPct >= ScoringConstants.confidentThreshold) return 'confident';
    if (accuracyPct >= ScoringConstants.passThreshold) return 'building';
    return 'developing';
  }

  /// Full session result. Call when learner submits.
  static QuizSessionResult calcSessionResult({
    required List<int> pointsPerQuestion,
    required int totalQuestions,
    required int timeUsedSeconds,
    required int timeLimitSeconds,
    required bool isFirstAttempt,
    required bool hasStreak,
    required String attemptType,
  }) {
    final accuracyScore = pointsPerQuestion.fold(0, (a, b) => a + b);
    final correctCount  = pointsPerQuestion.where((p) => p > 0).length;
    final accuracyPct   = totalQuestions > 0
        ? correctCount / totalQuestions : 0.0;
    final passed       = accuracyPct >= ScoringConstants.passThreshold;
    final isModule     = attemptType == 'module_quiz';

    final tBonus  = isModule
        ? calcTimeBonus(timeUsedSeconds, timeLimitSeconds) : 0;
    final fBonus  = (isModule && isFirstAttempt && passed)
        ? ScoringConstants.firstAttemptBonus : 0;
    final sBonus  = (isModule && hasStreak && passed)
        ? ScoringConstants.streakBonus : 0;

    return QuizSessionResult(
      accuracyScore:     accuracyScore,
      timeBonus:         tBonus,
      firstAttemptBonus: fBonus,
      streakBonus:       sBonus,
      totalScore:        accuracyScore + tBonus + fBonus + sBonus,
      accuracyPct:       accuracyPct,
      passed:            passed,
      skillLevelAchieved: resolveSkillLevel(accuracyPct),
    );
  }
}
```

---

## STEP 6 — DIAGNOSTIC ENGINE

### Read `lib/controllers/diagnostic_controller.dart` first.

Then create `lib/core/engine/diagnostic_engine.dart` as a pure logic class.
The existing `diagnostic_controller.dart` can call into this engine.

```dart
// lib/core/engine/diagnostic_engine.dart

import '../../models/diagnostic_models.dart';

class DiagnosticEngine {
  static const double _tier1Correct  =  1.0;
  static const double _tier2Correct  =  2.0;
  static const double _skippedPen    = -0.5;
  static const double _buildingMin   =  1.5;
  static const double _confidentMin  =  2.5;

  static const Map<SkillTag, List<String>> _skillModuleMap = {
    SkillTag.sequencing:             ['module_01', 'module_07', 'module_11'],
    SkillTag.syntax:                 ['module_02', 'module_06'],
    SkillTag.logicFlow:              ['module_03', 'module_04'],
    SkillTag.computationalThinking:  ['module_05', 'module_08', 'module_12'],
    SkillTag.debugging:              ['module_09'],
  };

  static double _calcRaw({
    required bool t1Correct, required bool t1Skipped,
    required bool t2Correct, required bool t2Skipped,
  }) {
    double s = 0;
    s += t1Skipped ? _skippedPen : (t1Correct ? _tier1Correct : 0);
    s += t2Skipped ? _skippedPen : (t2Correct ? _tier2Correct : 0);
    return s.clamp(0, 3.0);
  }

  static SkillLevel _level(double raw) {
    if (raw >= _confidentMin) return SkillLevel.confident;
    if (raw >= _buildingMin)  return SkillLevel.building;
    return SkillLevel.developing;
  }

  static String _overallLevel(List<SkillScore> scores) {
    final n         = scores.length;
    final confident = scores.where((s) => s.level == SkillLevel.confident).length;
    final building  = scores.where((s) => s.level == SkillLevel.building).length;
    if (confident / n >= 0.6) return 'intermediate';
    if ((confident + building) / n >= 0.4) return 'novice';
    return 'beginner';
  }

  /// Main entry point. Pass all 10 diagnostic responses.
  static DiagnosticResult calculate(List<DiagnosticResponse> responses) {
    DiagnosticResponse find(SkillTag tag, int tier) =>
        responses.firstWhere(
          (r) => r.skillTag == tag && r.tier == tier,
          orElse: () => DiagnosticResponse.skipped(tag, tier),
        );

    final scores = SkillTag.values.map((tag) {
      final t1  = find(tag, 1);
      final t2  = find(tag, 2);
      final raw = _calcRaw(
        t1Correct: t1.isCorrect, t1Skipped: t1.wasSkipped,
        t2Correct: t2.isCorrect, t2Skipped: t2.wasSkipped,
      );
      return SkillScore(skillTag: tag, rawScore: raw, level: _level(raw));
    }).toList();

    final toSkip     = <String>[];
    final toRequired = <String>[];

    for (final score in scores) {
      final gated = _skillModuleMap[score.skillTag] ?? [];
      if (score.level == SkillLevel.developing) {
        toRequired.addAll(gated);
      } else {
        toSkip.addAll(gated);
      }
    }

    // Required wins over skip
    final reqSet      = toRequired.toSet();
    final uniqueSkip  = toSkip.toSet().difference(reqSet).toList();

    return DiagnosticResult(
      skillScores:     scores,
      overallLevel:    _overallLevel(scores),
      modulesToSkip:   uniqueSkip,
      modulesRequired: reqSet.toList(),
    );
  }

  /// After Tier 1 answer — should next question come from hard pool?
  static bool shouldUpgradeTier(bool tier1WasCorrect) => tier1WasCorrect;
}
```

---

## STEP 7 — REFACTOR diagnostic_controller.dart

Read `lib/controllers/diagnostic_controller.dart` first.
Then refactor it to use `DiagnosticEngine.calculate()` instead of any
inline scoring logic it may have. Do not change function signatures
that are already being called elsewhere. Only replace the internal
scoring math with a call to `DiagnosticEngine`.

---

## STEP 8 — NEW SCREENS TO ADD

These files do not exist. Create them inside the existing feature folders.

```
lib/features/learn/presentation/screens/
├── diagnostic_self_report_screen.dart   ← "Never coded" / "Tried a little" / "Took a class"
├── diagnostic_briefing_screen.dart      ← Explain what diagnostic is, show 8–10 min estimate
├── diagnostic_quiz_screen.dart          ← 10-question adaptive diagnostic
├── lesson_viewer_screen.dart            ← Slide-by-slide lesson with step dots
├── module_quiz_screen.dart              ← Timed quiz using ScoringEngine
├── retry_quiz_screen.dart               ← Retry gate, 6 questions, zero points
└── quiz_result_screen.dart              ← Score breakdown, skill level, badge reveal
```

### `lib/features/learn/presentation/screens/diagnostic_quiz_screen.dart`

Full implementation — uses `DiagnosticEngine` and `AppDatabase`.

```dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/engine/diagnostic_engine.dart';
import '../../../../models/diagnostic_models.dart';

class DiagnosticQuizScreen extends StatefulWidget {
  final String learnerId;
  const DiagnosticQuizScreen({super.key, required this.learnerId});

  @override
  State<DiagnosticQuizScreen> createState() => _DiagnosticQuizScreenState();
}

class _DiagnosticQuizScreenState extends State<DiagnosticQuizScreen> {
  List<Map<String, dynamic>> _questions = [];
  final List<DiagnosticResponse> _responses = [];
  int _currentIndex = 0;
  bool _loading = true;
  String? _selectedAnswer;
  DateTime _questionStart = DateTime.now();
  // Adaptive: after tier-1 answer, next question tier determined by correctness
  bool? _lastTier1Correct;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    final db = await AppDatabase.instance.database;
    // Load tier-1 questions first (one per skill)
    final tier1 = await db.query('diagnostic_questions',
        where: 'tier = ?', whereArgs: [1]);
    setState(() {
      _questions = tier1;
      _loading = false;
    });
  }

  Future<void> _loadTier2ForSkill(String skillTag, bool upgradeToHard) async {
    final db = await AppDatabase.instance.database;
    // Hard pool = questions marked tier 2; easy fallback = tier 1 again with different id
    final tier2 = await db.query('diagnostic_questions',
        where: 'tier = ? AND skill_tag = ?',
        whereArgs: [2, skillTag],
        limit: 1);
    if (tier2.isNotEmpty) {
      setState(() => _questions.add(tier2.first));
    }
  }

  void _submitAnswer(String answer) {
    final q = _questions[_currentIndex];
    final skillTag = SkillTag.fromString(q['skill_tag'] as String);
    final tier = q['tier'] as int;
    final isCorrect = answer == q['correct_answer'];

    _responses.add(DiagnosticResponse(
      skillTag: skillTag,
      tier: tier,
      isCorrect: isCorrect,
      wasSkipped: false,
    ));

    setState(() => _selectedAnswer = answer);

    // After tier-1 question, load appropriate tier-2 question
    if (tier == 1) {
      _lastTier1Correct = isCorrect;
      _loadTier2ForSkill(q['skill_tag'] as String, isCorrect);
    }

    Future.delayed(const Duration(milliseconds: 600), _advance);
  }

  void _skipQuestion() {
    final q = _questions[_currentIndex];
    _responses.add(DiagnosticResponse.skipped(
      SkillTag.fromString(q['skill_tag'] as String),
      q['tier'] as int,
    ));
    _advance();
  }

  void _advance() {
    setState(() => _selectedAnswer = null);
    _questionStart = DateTime.now();
    if (_currentIndex + 1 >= _questions.length &&
        _responses.length >= 10) {
      _finishDiagnostic();
    } else if (_currentIndex + 1 < _questions.length) {
      setState(() => _currentIndex++);
    }
  }

  Future<void> _finishDiagnostic() async {
    final result = DiagnosticEngine.calculate(_responses);
    final db = await AppDatabase.instance.database;
    final sessionId =
        'ds_${widget.learnerId}_${DateTime.now().millisecondsSinceEpoch}';

    await db.insert('diagnostic_sessions', {
      'id': sessionId,
      'learner_id': widget.learnerId,
      'completed_at': DateTime.now().toIso8601String(),
      'overall_level': result.overallLevel,
    });

    // Save skill profiles
    for (final score in result.skillScores) {
      await db.insert('skill_profiles', {
        'id': 'sp_${widget.learnerId}_${score.skillTag.dbValue}',
        'learner_id': widget.learnerId,
        'skill_tag': score.skillTag.dbValue,
        'level': score.level.name,
        'raw_score': score.rawScore,
        'updated_at': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    // Unlock required modules
    for (final moduleId in result.modulesRequired) {
      final isFirst = result.modulesRequired.indexOf(moduleId) == 0;
      if (isFirst) {
        await db.insert('module_unlocks', {
          'id': 'mu_${widget.learnerId}_$moduleId',
          'learner_id': widget.learnerId,
          'module_id': moduleId,
          'unlocked_at': DateTime.now().toIso8601String(),
          'unlock_reason': 'diagnostic_initial_unlock',
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    }

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _questions.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final q = _questions[_currentIndex];
    final content = jsonDecode(q['content_json'] as String) as Map<String, dynamic>;
    final total = 10;
    final progress = (_currentIndex + 1) / total;

    return Scaffold(
      appBar: AppBar(
        title: Text('${_currentIndex + 1} of $total'),
        leading: const SizedBox.shrink(),
      ),
      body: Column(
        children: [
          LinearProgressIndicator(value: progress),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(q['prompt_text'] as String,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 24),
                  _buildQuestionWidget(q['question_type'] as String, content),
                  const Spacer(),
                  TextButton(
                    onPressed: _skipQuestion,
                    child: const Text('Skip this question'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionWidget(
      String type, Map<String, dynamic> content) {
    switch (type) {
      case 'multiple_choice':
        final options = (content['options'] as List).cast<String>();
        return Column(
          children: options.asMap().entries.map((e) {
            final idx = e.key.toString();
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  backgroundColor: _selectedAnswer == idx
                      ? Theme.of(context).colorScheme.primaryContainer
                      : null,
                  minimumSize: const Size(double.infinity, 48),
                ),
                onPressed:
                    _selectedAnswer == null ? () => _submitAnswer(idx) : null,
                child: Text(e.value, textAlign: TextAlign.start),
              ),
            );
          }).toList(),
        );
      case 'fill_in_blank':
        final controller = TextEditingController();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(content['code_with_blank'] as String,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 14)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: content['hint'] as String? ?? 'Type your answer',
                border: const OutlineInputBorder(),
              ),
              onSubmitted: _submitAnswer,
            ),
          ],
        );
      default:
        return Text('Question type: $type');
    }
  }
}
```

### `lib/features/learn/presentation/screens/module_quiz_screen.dart`

```dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/engine/scoring_engine.dart';
import '../../../../models/learning_path_model.dart';

class ModuleQuizScreen extends StatefulWidget {
  final String moduleId;
  final String learnerId;
  final List<Map<String, dynamic>> questions;
  final bool isFirstAttempt;
  final bool hasStreak;
  final bool isRetryQuiz;

  const ModuleQuizScreen({
    super.key,
    required this.moduleId,
    required this.learnerId,
    required this.questions,
    required this.isFirstAttempt,
    required this.hasStreak,
    this.isRetryQuiz = false,
  });

  @override
  State<ModuleQuizScreen> createState() => _ModuleQuizScreenState();
}

class _ModuleQuizScreenState extends State<ModuleQuizScreen> {
  int _currentIndex = 0;
  final List<int> _pointsPerQuestion = [];
  int _timeElapsed = 0;
  late int _timeLimit;
  Timer? _timer;
  bool _showFeedback = false;
  String? _selectedAnswer;

  @override
  void initState() {
    super.initState();
    _timeLimit = widget.isRetryQuiz
        ? ScoringConstants.retryQuizMinutes * 60
        : ScoringConstants.moduleQuizMinutes * 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_timeElapsed >= _timeLimit) {
        _submitQuiz();
      } else {
        setState(() => _timeElapsed++);
      }
    });
  }

  void _submitAnswer(String answer) {
    final q = widget.questions[_currentIndex];
    final isCorrect = answer == q['correct_answer'];
    final pts = ScoringEngine.calcQuestionPoints(
      questionType: q['question_type'] as String,
      isCorrect: isCorrect,
    );
    _pointsPerQuestion.add(pts);
    setState(() {
      _showFeedback = true;
      _selectedAnswer = answer;
    });
  }

  void _skipQuestion() {
    _pointsPerQuestion.add(0);
    _advance();
  }

  void _advance() {
    setState(() {
      _showFeedback = false;
      _selectedAnswer = null;
    });
    if (_currentIndex + 1 >= widget.questions.length) {
      _submitQuiz();
    } else {
      setState(() => _currentIndex++);
    }
  }

  Future<void> _submitQuiz() async {
    _timer?.cancel();
    while (_pointsPerQuestion.length < widget.questions.length) {
      _pointsPerQuestion.add(0);
    }
    final result = ScoringEngine.calcSessionResult(
      pointsPerQuestion: _pointsPerQuestion,
      totalQuestions:    widget.questions.length,
      timeUsedSeconds:   _timeElapsed,
      timeLimitSeconds:  _timeLimit,
      isFirstAttempt:    widget.isFirstAttempt,
      hasStreak:         widget.hasStreak,
      attemptType:       widget.isRetryQuiz ? 'retry_quiz' : 'module_quiz',
    );

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => QuizResultScreen(
          result: result,
          moduleId: widget.moduleId,
          learnerId: widget.learnerId,
          isRetryQuiz: widget.isRetryQuiz,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = _timeLimit - _timeElapsed;
    final q = widget.questions[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
            '${_currentIndex + 1} / ${widget.questions.length}'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${remaining ~/ 60}:${(remaining % 60).toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: remaining <= 30 ? Colors.redAccent : null,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: (_currentIndex + 1) / widget.questions.length,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(q['prompt_text'] as String,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 20),
                  // TODO: Replace with typed question widgets per question_type
                  // For now renders MC options if available
                  const Spacer(),
                  if (_showFeedback) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(q['explanation'] as String? ?? ''),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _advance,
                      style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48)),
                      child: _currentIndex + 1 >= widget.questions.length
                          ? const Text('See results')
                          : const Text('Next question'),
                    ),
                  ] else
                    TextButton(
                      onPressed: _skipQuestion,
                      child: const Text('Skip'),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class QuizResultScreen extends StatelessWidget {
  final QuizSessionResult result;
  final String moduleId;
  final String learnerId;
  final bool isRetryQuiz;

  const QuizResultScreen({
    super.key,
    required this.result,
    required this.moduleId,
    required this.learnerId,
    required this.isRetryQuiz,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                result.passed ? 'Module complete' : 'Not quite yet',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                result.passed
                    ? 'You reached ${result.skillLevelAchieved} level.'
                    : isRetryQuiz
                        ? 'Review the lessons and try again.'
                        : 'A short practice quiz will help you get there.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              _ScoreRow('Accuracy score', '${result.accuracyScore} pts'),
              if (!isRetryQuiz) ...[
                _ScoreRow('Time bonus', '+${result.timeBonus} pts'),
                _ScoreRow('First attempt bonus', '+${result.firstAttemptBonus} pts'),
                _ScoreRow('Streak bonus', '+${result.streakBonus} pts'),
              ],
              const Divider(height: 32),
              _ScoreRow('Total', '${result.totalScore} pts',
                  bold: true),
              const Spacer(),
              ElevatedButton(
                onPressed: () => Navigator.popUntil(
                    context, ModalRoute.withName('/home')),
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52)),
                child: const Text('Back to learning path'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  const _ScoreRow(this.label, this.value, {this.bold = false});

  @override
  Widget build(BuildContext context) {
    final style = bold
        ? Theme.of(context).textTheme.titleMedium
        : Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(value, style: style),
        ],
      ),
    );
  }
}
```

---

## STEP 9 — WIRING EXISTING SCREENS (append only)

### `lib/features/learn/presentation/screens/learn_screen.dart`

Read the file first. Then add a method `_loadModules()` that fetches
from `AppDatabase` and displays the list. Add navigation to
`DiagnosticSelfReportScreen` if no diagnostic session exists for the
current learner. If diagnostic is complete, navigate to
`LessonViewerScreen` on module tap.

### `lib/features/ranks/presentation/screens/ranks_screen.dart`

Read the file first. Add a `DefaultTabController` with 3 tabs:
- Leaderboard — query `leaderboard_scores JOIN learners`
- Badges — query `learner_badges` for current user
- Certificates — query `learner_certificates` for current user

### `lib/features/progress/presentation/screens/progress_screen.dart`

Read the file first. Add 5 skill level progress bars pulled from
`skill_profiles` for the current learner. Show label, level name, and
a LinearProgressIndicator where value = rawScore / 3.0.

---

## STEP 10 — ENFORCE THESE RULES IN ALL NEW CODE

1. **All DB calls go through `AppDatabase.instance.database`** — never open sqflite directly.
2. **All score math goes through `ScoringEngine`** — no inline arithmetic in widgets.
3. **Retry quiz always passes `isRetryQuiz: true`** to `ModuleQuizScreen` — this zeroes all bonuses automatically inside `ScoringEngine.calcSessionResult`.
4. **Module quiz locked after passing** — before loading `ModuleQuizScreen`, query `quiz_attempts` for a row where `learner_id = ? AND module_id = ? AND attempt_type = 'module_quiz' AND passed = 1`. If found, go directly to `QuizResultScreen` showing the stored result.
5. **Leaderboard recalculated on every quiz submission** — after saving a `quiz_attempts` row, run an aggregate query over all passed `module_quiz` attempts for the learner and overwrite their `leaderboard_scores` row entirely.
6. **`flutter analyze` must pass with zero errors** before any phase is considered done.
7. **Never import from a file that does not yet exist.** Build bottom-up: database → models → engine → screens.
