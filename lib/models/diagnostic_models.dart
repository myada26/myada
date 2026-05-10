export 'learning_path_model.dart';
import 'learning_path_model.dart';

enum QuestionType { mcq, parsons, dropdown }

class DiagnosticQuestion {
  final int skillIndex;
  final int tier;
  final QuestionType type;
  final String label;
  final String text;
  final String? code;
  final List<String>? opts; // mcq options
  final int? answer; // mcq answer index
  final List<String>? items; // parsons items
  final List<int>? correctSequence; // parsons answer
  final List<Map<String, dynamic>>? drops; // dropdown fields

  DiagnosticQuestion({
    required this.skillIndex,
    required this.tier,
    required this.type,
    required this.label,
    required this.text,
    this.code,
    this.opts,
    this.answer,
    this.items,
    this.correctSequence,
    this.drops,
  });
}


// Data definitions translated from HTML prototype
final List<String> diagnosticSkills = [
  'Sequencing',
  'Logic Flow',
  'Debugging',
  'Syntax',
  'Computational Thinking',
];

final List<String> diagnosticMicrocopy = [
  'Almost there — keep going.',
  'Good thinking, take your time.',
  'You\'ve got this.',
  'One step at a time.',
  'Focus and trust yourself.',
  'No rush — think it through.',
  'Great instinct, keep it up.',
  'Nearly halfway there.',
  'Your path is taking shape.',
  'Last question — you\'re doing well.',
];

final List<DiagnosticQuestion> diagnosticQuestions = [
  DiagnosticQuestion(
    skillIndex: 0,
    tier: 1,
    type: QuestionType.parsons,
    label: 'Sequencing',
    text: 'Arrange these lines so the program prints "Hello, Ada!" correctly.',
    items: [
      'print("Hello, Ada!")',
      'name = "Ada"',
      'greeting = "Hello, " + name + "!"',
    ],
    correctSequence: [1, 2, 0],
  ),
  DiagnosticQuestion(
    skillIndex: 0,
    tier: 1,
    type: QuestionType.mcq,
    label: 'Sequencing',
    text: 'What is printed last?',
    code: 'x = 5\nx = x + 3\nprint(x)\nx = x * 2\nprint(x)',
    opts: ['5', '8', '16', '13'],
    answer: 2,
  ),
  DiagnosticQuestion(
    skillIndex: 1,
    tier: 1,
    type: QuestionType.mcq,
    label: 'Logic Flow',
    text: 'What does this code print?',
    code:
        'score = 72\nif score >= 90:\n    print("A")\nelif score >= 75:\n    print("B")\nelse:\n    print("C")',
    opts: ['A', 'B', 'C', 'Nothing'],
    answer: 2,
  ),
  DiagnosticQuestion(
    skillIndex: 1,
    tier: 1,
    type: QuestionType.mcq,
    label: 'Logic Flow',
    text: 'How many times does "hello" print?',
    code: 'i = 0\nwhile i < 3:\n    print("hello")\n    i += 1',
    opts: ['0', '2', '3', 'Infinite'],
    answer: 2,
  ),
  DiagnosticQuestion(
    skillIndex: 2,
    tier: 1,
    type: QuestionType.mcq,
    label: 'Debugging',
    text: 'This code has a bug. What kind of error will it cause?',
    code: 'age = input("Your age: ")\nresult = age + 5\nprint(result)',
    opts: ['SyntaxError', 'TypeError', 'NameError', 'No error — it works fine'],
    answer: 1,
  ),
  DiagnosticQuestion(
    skillIndex: 2,
    tier: 1,
    type: QuestionType.mcq,
    label: 'Debugging',
    text: 'Which line has the bug?',
    code: 'def greet(name):\n    mesage = "Hello, " + name\n    return message',
    opts: [
      'Line 1 (def greet)',
      'Line 2 (mesage/message mismatch)',
      'Line 3 (return)',
      'No bug',
    ],
    answer: 1,
  ),
  DiagnosticQuestion(
    skillIndex: 4,
    tier: 1,
    type: QuestionType.parsons,
    label: 'Computational Thinking',
    text:
        'A vending machine checks if you have enough coins. Arrange the steps in the right order.',
    items: [
      'Dispense item',
      'Ask user to insert coins',
      'Check if coins >= item price',
      'Show "insufficient funds"',
    ],
    correctSequence: [1, 2, 0, 3],
  ),
  DiagnosticQuestion(
    skillIndex: 4,
    tier: 1,
    type: QuestionType.mcq,
    label: 'Computational Thinking',
    text: 'Which describes decomposition in computational thinking?',
    opts: [
      'Writing code faster using shortcuts',
      'Breaking a big problem into smaller manageable parts',
      'Memorizing syntax rules',
      'Running code to find bugs',
    ],
    answer: 1,
  ),
  DiagnosticQuestion(
    skillIndex: 3,
    tier: 1,
    type: QuestionType.dropdown,
    label: 'Syntax',
    text: 'Complete the code so it prints the length of the list.',
    code: 'fruits = ["apple", "banana", "mango"]\nprint( ___1___(fruits) )',
    drops: [
      {
        'id': '1',
        'opts': ['len', 'count', 'size', 'length'],
        'answer': 0,
      },
    ],
  ),
  DiagnosticQuestion(
    skillIndex: 3,
    tier: 1,
    type: QuestionType.dropdown,
    label: 'Syntax',
    text:
        'Fill in the blank to create a function that returns the square of a number.',
    code: 'def square(n):\n    ___1___ n * n',
    drops: [
      {
        'id': '1',
        'opts': ['return', 'print', 'yield', 'pass'],
        'answer': 0,
      },
    ],
  ),
  DiagnosticQuestion(
    skillIndex: 0,
    tier: 2,
    type: QuestionType.mcq,
    label: 'Sequencing',
    text: 'What is the final value of total?',
    code:
        'total = 0\nfor n in [1, 2, 3, 4]:\n    if n % 2 == 0:\n        total += n\nprint(total)',
    opts: ['10', '6', '4', '7'],
    answer: 1,
  ),
  DiagnosticQuestion(
    skillIndex: 1,
    tier: 2,
    type: QuestionType.mcq,
    label: 'Logic Flow',
    text: 'What prints?',
    code:
        'x = 10\nif x > 5 and x < 20:\n    if x != 10:\n        print("A")\n    else:\n        print("B")\nelse:\n    print("C")',
    opts: ['A', 'B', 'C', 'Nothing'],
    answer: 1,
  ),
  DiagnosticQuestion(
    skillIndex: 2,
    tier: 2,
    type: QuestionType.mcq,
    label: 'Debugging',
    text: 'What is the output of this corrected version?',
    code:
        'try:\n    print(int("hello"))\nexcept ValueError:\n    print("not a number")',
    opts: ['hello', '0', 'not a number', 'ValueError crash'],
    answer: 2,
  ),
  DiagnosticQuestion(
    skillIndex: 4,
    tier: 2,
    type: QuestionType.mcq,
    label: 'Computational Thinking',
    text: 'What does this function return when called as double(4)?',
    code:
        'def double(x):\n    return x * 2\n\nresult = double(4)\nprint(result)',
    opts: ['4', '8', 'None', 'double(4)'],
    answer: 1,
  ),
  DiagnosticQuestion(
    skillIndex: 3,
    tier: 2,
    type: QuestionType.parsons,
    label: 'Syntax',
    text: 'Arrange these lines to build a dictionary and print Ada\'s score.',
    items: ['print(scores["Ada"])', 'scores = {}', 'scores["Ada"] = 95'],
    correctSequence: [1, 2, 0],
  ),
];

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

extension SkillLevelExt on SkillLevel {
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

class EngineDiagnosticResult {
  final List<SkillScore> skillScores;
  final String overallLevel; // 'beginner' | 'novice' | 'intermediate'
  final List<String> modulesToSkip;       // confident — can skip
  final List<String> modulesRecommended;  // building — optional review
  final List<String> modulesRequired;     // developing — must complete

  const EngineDiagnosticResult({
    required this.skillScores,
    required this.overallLevel,
    required this.modulesToSkip,
    required this.modulesRecommended,
    required this.modulesRequired,
  });
}
