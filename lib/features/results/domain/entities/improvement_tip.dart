import 'package:equatable/equatable.dart';

import 'package:lumoni/core/constants/app_constants.dart';

/// Difficulty level for an improvement tip exercise.
enum TipDifficulty {
  beginner,
  intermediate,
  advanced;

  String get label {
    switch (this) {
      case TipDifficulty.beginner:
        return 'Beginner';
      case TipDifficulty.intermediate:
        return 'Intermediate';
      case TipDifficulty.advanced:
        return 'Advanced';
    }
  }
}

/// An actionable improvement tip mapped to a specific intelligence category.
class ImprovementTip extends Equatable {
  /// Short title of the tip.
  final String title;

  /// Detailed description of the exercise or practice.
  final String description;

  /// The category key this tip targets (e.g. 'pattern', 'selfAwareness').
  final String category;

  /// Difficulty level of the exercise.
  final TipDifficulty difficulty;

  /// Minimum score threshold below which this tip is relevant (0-100).
  /// Tips with higher thresholds are shown for higher-performing users.
  final double scoreThreshold;

  const ImprovementTip({
    required this.title,
    required this.description,
    required this.category,
    required this.difficulty,
    this.scoreThreshold = 100,
  });

  @override
  List<Object?> get props => [title, description, category, difficulty];

  /// Returns tips relevant for the given [category] and [score].
  ///
  /// Tips are returned in order of relevance: lower-threshold tips first
  /// for low scores, higher-threshold tips for strong performers.
  static List<ImprovementTip> tipsForCategory(String category, double score) {
    return allTips
        .where((tip) => tip.category == category && score <= tip.scoreThreshold)
        .toList();
  }

  /// Returns a curated selection of tips across multiple categories based on
  /// the provided [categoryScores]. Picks the weakest categories first.
  static List<ImprovementTip> recommendedTips({
    required Map<String, double> categoryScores,
    int maxTips = 5,
  }) {
    // Sort categories by score ascending (weakest first).
    final sorted = categoryScores.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    final tips = <ImprovementTip>[];
    for (final entry in sorted) {
      final categoryTips = tipsForCategory(entry.key, entry.value);
      if (categoryTips.isNotEmpty) {
        // Take up to 2 tips per weak category.
        tips.addAll(categoryTips.take(2));
      }
      if (tips.length >= maxTips) break;
    }

    return tips.take(maxTips).toList();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Master list of 60+ improvement tips
  // ──────────────────────────────────────────────────────────────────────────

  static const List<ImprovementTip> allTips = [
    // ───── IQ: Pattern Recognition ─────────────────────────────────────────
    ImprovementTip(
      title: 'Daily Pattern Puzzles',
      description:
          'Spend 10 minutes each day solving visual pattern puzzles such as '
          'Raven\'s Progressive Matrices. This strengthens your ability to '
          'detect regularities and predict sequences.',
      category: AppConstants.iqCategoryPattern,
      difficulty: TipDifficulty.beginner,
      scoreThreshold: 50,
    ),
    ImprovementTip(
      title: 'Number Sequence Games',
      description:
          'Practice finding the next number in sequences (e.g. 2, 6, 18, 54, ?). '
          'Start with simple arithmetic progressions and work up to complex '
          'multi-rule sequences.',
      category: AppConstants.iqCategoryPattern,
      difficulty: TipDifficulty.beginner,
      scoreThreshold: 60,
    ),
    ImprovementTip(
      title: 'Play Strategy Board Games',
      description:
          'Games like chess, Go, and Othello require pattern recognition at '
          'multiple levels. Regular play trains your brain to spot structural '
          'patterns under time pressure.',
      category: AppConstants.iqCategoryPattern,
      difficulty: TipDifficulty.intermediate,
      scoreThreshold: 75,
    ),
    ImprovementTip(
      title: 'Learn Music Theory',
      description:
          'Music is built on patterns. Learning to read music, identify chord '
          'progressions, and recognize rhythmic patterns exercises the same '
          'neural circuits used in abstract pattern matching.',
      category: AppConstants.iqCategoryPattern,
      difficulty: TipDifficulty.intermediate,
      scoreThreshold: 80,
    ),
    ImprovementTip(
      title: 'Code Kata Practice',
      description:
          'If you know any programming, solving coding challenges on platforms '
          'like LeetCode or HackerRank trains algorithmic pattern recognition '
          'at an advanced level.',
      category: AppConstants.iqCategoryPattern,
      difficulty: TipDifficulty.advanced,
      scoreThreshold: 90,
    ),
    ImprovementTip(
      title: 'Visual Memory Exercises',
      description:
          'Study a complex image for 30 seconds, then try to recall specific '
          'details. Gradually increase complexity. This builds the visual '
          'working memory essential for pattern detection.',
      category: AppConstants.iqCategoryPattern,
      difficulty: TipDifficulty.beginner,
      scoreThreshold: 100,
    ),

    // ───── IQ: Logical Reasoning ───────────────────────────────────────────
    ImprovementTip(
      title: 'Practice Syllogisms',
      description:
          'Work through logical syllogisms daily (e.g. "All A are B. All B are C. '
          'Therefore all A are C."). This builds foundational deductive reasoning '
          'skills used in many IQ test questions.',
      category: AppConstants.iqCategoryLogical,
      difficulty: TipDifficulty.beginner,
      scoreThreshold: 50,
    ),
    ImprovementTip(
      title: 'Solve Logic Grid Puzzles',
      description:
          'Logic grid puzzles (like Einstein\'s riddle) require systematic '
          'elimination and deduction. Start with 3x3 grids and progress to '
          '5x5 or larger for a real challenge.',
      category: AppConstants.iqCategoryLogical,
      difficulty: TipDifficulty.beginner,
      scoreThreshold: 60,
    ),
    ImprovementTip(
      title: 'Debate Both Sides',
      description:
          'Pick a topic and argue both for and against it. This forces you to '
          'evaluate evidence objectively, identify logical fallacies, and '
          'strengthen your reasoning muscles.',
      category: AppConstants.iqCategoryLogical,
      difficulty: TipDifficulty.intermediate,
      scoreThreshold: 70,
    ),
    ImprovementTip(
      title: 'Study Formal Logic',
      description:
          'Learn the basics of propositional logic: AND, OR, NOT, implications, '
          'and truth tables. Understanding formal logic gives you a framework '
          'for evaluating any argument systematically.',
      category: AppConstants.iqCategoryLogical,
      difficulty: TipDifficulty.intermediate,
      scoreThreshold: 80,
    ),
    ImprovementTip(
      title: 'Analyze Real-World Arguments',
      description:
          'Read editorials or opinion pieces and identify the premises, '
          'conclusions, and any logical fallacies. This transfers abstract '
          'logic skills to practical critical thinking.',
      category: AppConstants.iqCategoryLogical,
      difficulty: TipDifficulty.advanced,
      scoreThreshold: 90,
    ),
    ImprovementTip(
      title: 'Conditional Reasoning Drills',
      description:
          'Practice "if-then" reasoning: "If it rains, the ground is wet. '
          'The ground is wet. Can we conclude it rained?" Understanding '
          'affirming the consequent fallacy sharpens logical precision.',
      category: AppConstants.iqCategoryLogical,
      difficulty: TipDifficulty.beginner,
      scoreThreshold: 100,
    ),

    // ───── IQ: Mathematical Ability ────────────────────────────────────────
    ImprovementTip(
      title: 'Mental Math Practice',
      description:
          'Spend 5 minutes daily doing mental arithmetic: addition, subtraction, '
          'multiplication of 2-3 digit numbers. Speed and accuracy both improve '
          'with consistent practice.',
      category: AppConstants.iqCategoryMath,
      difficulty: TipDifficulty.beginner,
      scoreThreshold: 50,
    ),
    ImprovementTip(
      title: 'Master Estimation',
      description:
          'Practice Fermi estimation: "How many piano tuners are in Chicago?" '
          'Breaking complex problems into estimable parts builds mathematical '
          'intuition and numerical reasoning.',
      category: AppConstants.iqCategoryMath,
      difficulty: TipDifficulty.beginner,
      scoreThreshold: 60,
    ),
    ImprovementTip(
      title: 'Learn Number Properties',
      description:
          'Study divisibility rules, prime numbers, and number relationships. '
          'Understanding why numbers behave the way they do gives you shortcuts '
          'for solving mathematical problems faster.',
      category: AppConstants.iqCategoryMath,
      difficulty: TipDifficulty.intermediate,
      scoreThreshold: 70,
    ),
    ImprovementTip(
      title: 'Word Problem Decomposition',
      description:
          'Practice converting word problems into equations. The key skill is '
          'translating verbal descriptions into mathematical relationships, '
          'which is heavily tested in cognitive assessments.',
      category: AppConstants.iqCategoryMath,
      difficulty: TipDifficulty.intermediate,
      scoreThreshold: 80,
    ),
    ImprovementTip(
      title: 'Explore Probability & Statistics',
      description:
          'Learn basic probability concepts: independent events, conditional '
          'probability, and expected value. This type of quantitative reasoning '
          'appears frequently in advanced IQ assessments.',
      category: AppConstants.iqCategoryMath,
      difficulty: TipDifficulty.advanced,
      scoreThreshold: 90,
    ),
    ImprovementTip(
      title: 'Percentage & Ratio Mastery',
      description:
          'Practice percentage calculations, proportions, and ratios in daily '
          'life: tip calculations, recipe scaling, discount comparisons. '
          'Fluency with ratios is a strong cognitive indicator.',
      category: AppConstants.iqCategoryMath,
      difficulty: TipDifficulty.beginner,
      scoreThreshold: 100,
    ),

    // ───── IQ: Verbal Intelligence ─────────────────────────────────────────
    ImprovementTip(
      title: 'Read Widely Every Day',
      description:
          'Read at least 20 minutes daily from varied sources: fiction, '
          'non-fiction, science, philosophy. Diverse reading builds vocabulary, '
          'comprehension, and verbal reasoning simultaneously.',
      category: AppConstants.iqCategoryVerbal,
      difficulty: TipDifficulty.beginner,
      scoreThreshold: 50,
    ),
    ImprovementTip(
      title: 'Learn a New Word Daily',
      description:
          'Use a word-of-the-day app or dictionary. For each new word, write '
          'three original sentences using it. Active usage cements new vocabulary '
          'far better than passive reading.',
      category: AppConstants.iqCategoryVerbal,
      difficulty: TipDifficulty.beginner,
      scoreThreshold: 60,
    ),
    ImprovementTip(
      title: 'Practice Analogies',
      description:
          'Work through verbal analogies: "Book is to reading as fork is to ___." '
          'Analogical reasoning is a core measure of verbal intelligence and '
          'can be improved through deliberate practice.',
      category: AppConstants.iqCategoryVerbal,
      difficulty: TipDifficulty.intermediate,
      scoreThreshold: 70,
    ),
    ImprovementTip(
      title: 'Summarize What You Read',
      description:
          'After reading an article or chapter, write a one-paragraph summary. '
          'This forces deeper comprehension and trains you to extract key ideas '
          'from complex text.',
      category: AppConstants.iqCategoryVerbal,
      difficulty: TipDifficulty.intermediate,
      scoreThreshold: 80,
    ),
    ImprovementTip(
      title: 'Study Etymology',
      description:
          'Learn common Latin and Greek roots, prefixes, and suffixes. '
          'Understanding word origins lets you decode unfamiliar words on the fly, '
          'a powerful advantage on verbal assessments.',
      category: AppConstants.iqCategoryVerbal,
      difficulty: TipDifficulty.advanced,
      scoreThreshold: 90,
    ),
    ImprovementTip(
      title: 'Crossword & Word Games',
      description:
          'Regular crossword puzzles, Scrabble, or Wordle challenge vocabulary '
          'recall, spelling, and flexible word association. Aim for at least '
          '3 sessions per week.',
      category: AppConstants.iqCategoryVerbal,
      difficulty: TipDifficulty.beginner,
      scoreThreshold: 100,
    ),

    // ───── IQ: Spatial Reasoning ───────────────────────────────────────────
    ImprovementTip(
      title: 'Build with Blocks or LEGO',
      description:
          'Constructing 3D models from instructions or imagination exercises '
          'spatial visualization. Try building from memory after studying a '
          'model for one minute.',
      category: AppConstants.iqCategorySpatial,
      difficulty: TipDifficulty.beginner,
      scoreThreshold: 50,
    ),
    ImprovementTip(
      title: 'Mental Rotation Exercises',
      description:
          'Practice mentally rotating 2D and 3D shapes. Start with simple '
          'shapes and progress to complex figures. Many free apps offer '
          'timed mental rotation drills.',
      category: AppConstants.iqCategorySpatial,
      difficulty: TipDifficulty.beginner,
      scoreThreshold: 60,
    ),
    ImprovementTip(
      title: 'Draw from Different Angles',
      description:
          'Take an everyday object and sketch it from the top, side, and front. '
          'This trains your brain to maintain and manipulate 3D representations, '
          'a core spatial reasoning skill.',
      category: AppConstants.iqCategorySpatial,
      difficulty: TipDifficulty.intermediate,
      scoreThreshold: 70,
    ),
    ImprovementTip(
      title: 'Play Spatial Video Games',
      description:
          'Games like Tetris, Minecraft, and Portal require constant spatial '
          'manipulation. Research shows Tetris players develop measurably '
          'thicker cortex in spatial processing regions.',
      category: AppConstants.iqCategorySpatial,
      difficulty: TipDifficulty.intermediate,
      scoreThreshold: 80,
    ),
    ImprovementTip(
      title: 'Navigate Without GPS',
      description:
          'Periodically navigate using only a paper map or memory. Spatial '
          'navigation activates the hippocampus and strengthens your internal '
          'map-making ability.',
      category: AppConstants.iqCategorySpatial,
      difficulty: TipDifficulty.advanced,
      scoreThreshold: 90,
    ),
    ImprovementTip(
      title: 'Origami & Paper Folding',
      description:
          'Origami requires visualizing how flat paper transforms into 3D '
          'shapes through sequential folds. It directly trains the paper-folding '
          'spatial skills tested in many IQ assessments.',
      category: AppConstants.iqCategorySpatial,
      difficulty: TipDifficulty.beginner,
      scoreThreshold: 100,
    ),

    // ───── EQ: Self-Awareness ──────────────────────────────────────────────
    ImprovementTip(
      title: 'Daily Emotion Journal',
      description:
          'Each evening, write down the 3 strongest emotions you felt that day '
          'and what triggered them. Over time you will recognize patterns in '
          'your emotional responses and develop deeper self-knowledge.',
      category: AppConstants.eqCategorySelfAwareness,
      difficulty: TipDifficulty.beginner,
      scoreThreshold: 50,
    ),
    ImprovementTip(
      title: 'Body Scan Meditation',
      description:
          'Spend 5 minutes scanning your body from head to toe, noticing '
          'physical sensations without judgment. Emotions often manifest as '
          'physical tension; learning to notice this is a gateway to awareness.',
      category: AppConstants.eqCategorySelfAwareness,
      difficulty: TipDifficulty.beginner,
      scoreThreshold: 60,
    ),
    ImprovementTip(
      title: 'Ask for Feedback',
      description:
          'Ask a trusted friend or colleague how they perceive your emotional '
          'responses. Others often see patterns we miss. Approach feedback with '
          'curiosity, not defensiveness.',
      category: AppConstants.eqCategorySelfAwareness,
      difficulty: TipDifficulty.intermediate,
      scoreThreshold: 70,
    ),
    ImprovementTip(
      title: 'Values Clarification Exercise',
      description:
          'List your top 10 values, then rank them. When your actions conflict '
          'with your values, emotional discomfort arises. Knowing your values '
          'helps you understand why certain situations trigger strong reactions.',
      category: AppConstants.eqCategorySelfAwareness,
      difficulty: TipDifficulty.intermediate,
      scoreThreshold: 80,
    ),
    ImprovementTip(
      title: 'Emotional Vocabulary Expansion',
      description:
          'Learn to distinguish between related emotions (frustrated vs. '
          'disappointed, anxious vs. excited). A richer emotional vocabulary '
          'leads to more precise self-understanding and better regulation.',
      category: AppConstants.eqCategorySelfAwareness,
      difficulty: TipDifficulty.advanced,
      scoreThreshold: 90,
    ),
    ImprovementTip(
      title: 'Hourly Check-Ins',
      description:
          'Set a timer to pause every hour and ask yourself: "What am I feeling '
          'right now?" Rate it 1-10. This simple practice dramatically increases '
          'real-time emotional awareness over weeks.',
      category: AppConstants.eqCategorySelfAwareness,
      difficulty: TipDifficulty.beginner,
      scoreThreshold: 100,
    ),

    // ───── EQ: Self-Regulation ─────────────────────────────────────────────
    ImprovementTip(
      title: 'The Pause Technique',
      description:
          'When you feel a strong emotion rising, pause for 3 deep breaths '
          'before responding. This engages your prefrontal cortex and gives '
          'your rational brain time to override impulsive reactions.',
      category: AppConstants.eqCategorySelfRegulation,
      difficulty: TipDifficulty.beginner,
      scoreThreshold: 50,
    ),
    ImprovementTip(
      title: 'Reframe Negative Thoughts',
      description:
          'When you catch a negative thought, reframe it constructively. '
          '"This is terrible" becomes "This is challenging but I can handle it." '
          'Cognitive reframing is one of the most effective regulation strategies.',
      category: AppConstants.eqCategorySelfRegulation,
      difficulty: TipDifficulty.beginner,
      scoreThreshold: 60,
    ),
    ImprovementTip(
      title: 'Stress Inoculation',
      description:
          'Gradually expose yourself to mildly stressful situations while '
          'practicing calm responses. Like a vaccine, small doses of managed '
          'stress build resilience for larger challenges.',
      category: AppConstants.eqCategorySelfRegulation,
      difficulty: TipDifficulty.intermediate,
      scoreThreshold: 70,
    ),
    ImprovementTip(
      title: 'Progressive Muscle Relaxation',
      description:
          'Tense and release each muscle group for 5 seconds. Start with your '
          'toes and work up. This technique directly counters the physical '
          'symptoms of emotional arousal and restores calm.',
      category: AppConstants.eqCategorySelfRegulation,
      difficulty: TipDifficulty.intermediate,
      scoreThreshold: 80,
    ),
    ImprovementTip(
      title: 'Emotional Trigger Mapping',
      description:
          'Create a map of your emotional triggers: situations, people, and '
          'thoughts that reliably provoke strong reactions. With awareness, '
          'you can prepare regulation strategies in advance.',
      category: AppConstants.eqCategorySelfRegulation,
      difficulty: TipDifficulty.advanced,
      scoreThreshold: 90,
    ),
    ImprovementTip(
      title: 'Box Breathing',
      description:
          'Breathe in for 4 counts, hold for 4, out for 4, hold for 4. Repeat '
          '4 times. Used by Navy SEALs, this technique activates the '
          'parasympathetic nervous system in under 2 minutes.',
      category: AppConstants.eqCategorySelfRegulation,
      difficulty: TipDifficulty.beginner,
      scoreThreshold: 100,
    ),

    // ───── EQ: Motivation ──────────────────────────────────────────────────
    ImprovementTip(
      title: 'Set Intrinsic Goals',
      description:
          'Focus on goals driven by personal growth, curiosity, or purpose '
          'rather than external rewards. Intrinsic motivation is more '
          'sustainable and leads to greater satisfaction and resilience.',
      category: AppConstants.eqCategoryMotivation,
      difficulty: TipDifficulty.beginner,
      scoreThreshold: 50,
    ),
    ImprovementTip(
      title: 'Visualize Success Daily',
      description:
          'Spend 2 minutes each morning vividly imagining yourself achieving '
          'a goal. Visualization activates the same neural pathways as actual '
          'experience and primes your brain for motivated action.',
      category: AppConstants.eqCategoryMotivation,
      difficulty: TipDifficulty.beginner,
      scoreThreshold: 60,
    ),
    ImprovementTip(
      title: 'Track Small Wins',
      description:
          'Keep a daily log of 3 small accomplishments. Recognizing progress '
          'triggers dopamine release and builds momentum. Even tiny wins '
          'compound into powerful motivational fuel.',
      category: AppConstants.eqCategoryMotivation,
      difficulty: TipDifficulty.intermediate,
      scoreThreshold: 70,
    ),
    ImprovementTip(
      title: 'Find Your "Why"',
      description:
          'For each major goal, write down why it matters to you at 5 levels '
          'deep (the "5 Whys" technique). Connecting actions to deep values '
          'creates unshakable motivation even when things get hard.',
      category: AppConstants.eqCategoryMotivation,
      difficulty: TipDifficulty.intermediate,
      scoreThreshold: 80,
    ),
    ImprovementTip(
      title: 'Embrace Productive Discomfort',
      description:
          'Deliberately do one thing outside your comfort zone each week. '
          'Building tolerance for discomfort expands your capacity for '
          'sustained effort and perseverance in challenging pursuits.',
      category: AppConstants.eqCategoryMotivation,
      difficulty: TipDifficulty.advanced,
      scoreThreshold: 90,
    ),
    ImprovementTip(
      title: 'Gratitude Journaling',
      description:
          'Write 3 things you are grateful for each morning. Gratitude shifts '
          'your brain from a scarcity to an abundance mindset, naturally '
          'increasing optimism and intrinsic motivation.',
      category: AppConstants.eqCategoryMotivation,
      difficulty: TipDifficulty.beginner,
      scoreThreshold: 100,
    ),

    // ───── EQ: Empathy ─────────────────────────────────────────────────────
    ImprovementTip(
      title: 'Active Listening Practice',
      description:
          'In your next conversation, focus entirely on understanding the other '
          'person. Paraphrase what they said before responding. Resist planning '
          'your reply while they are still speaking.',
      category: AppConstants.eqCategoryEmpathy,
      difficulty: TipDifficulty.beginner,
      scoreThreshold: 50,
    ),
    ImprovementTip(
      title: 'Read Fiction Regularly',
      description:
          'Literary fiction requires you to infer characters\' thoughts and '
          'feelings from their actions. Studies show that fiction readers score '
          'significantly higher on empathy measures.',
      category: AppConstants.eqCategoryEmpathy,
      difficulty: TipDifficulty.beginner,
      scoreThreshold: 60,
    ),
    ImprovementTip(
      title: 'Perspective-Taking Exercises',
      description:
          'When you disagree with someone, spend 2 minutes genuinely trying '
          'to understand their perspective. Ask yourself: "What experiences '
          'might lead someone to hold this view?"',
      category: AppConstants.eqCategoryEmpathy,
      difficulty: TipDifficulty.intermediate,
      scoreThreshold: 70,
    ),
    ImprovementTip(
      title: 'Volunteer & Serve Others',
      description:
          'Regular volunteering exposes you to diverse life experiences and '
          'challenges. Direct service work has been shown to increase empathic '
          'concern and reduce self-focused thinking.',
      category: AppConstants.eqCategoryEmpathy,
      difficulty: TipDifficulty.intermediate,
      scoreThreshold: 80,
    ),
    ImprovementTip(
      title: 'Micro-Expression Training',
      description:
          'Study the 7 universal facial expressions (happiness, sadness, fear, '
          'anger, surprise, contempt, disgust). Practice identifying them in '
          'real conversations to improve emotional reading accuracy.',
      category: AppConstants.eqCategoryEmpathy,
      difficulty: TipDifficulty.advanced,
      scoreThreshold: 90,
    ),
    ImprovementTip(
      title: 'Empathy Mapping',
      description:
          'Choose someone you interact with regularly. Map out what they might '
          'be thinking, feeling, seeing, and hearing in a given situation. '
          'This structured exercise deepens your empathic understanding.',
      category: AppConstants.eqCategoryEmpathy,
      difficulty: TipDifficulty.beginner,
      scoreThreshold: 100,
    ),

    // ───── EQ: Social Skills ───────────────────────────────────────────────
    ImprovementTip(
      title: 'Practice Small Talk',
      description:
          'Start brief, friendly conversations with people you encounter daily: '
          'baristas, colleagues, neighbors. Small talk is a foundational social '
          'skill that opens doors to deeper connections.',
      category: AppConstants.eqCategorySocialSkills,
      difficulty: TipDifficulty.beginner,
      scoreThreshold: 50,
    ),
    ImprovementTip(
      title: 'Give Genuine Compliments',
      description:
          'Offer one specific, sincere compliment each day. Focus on effort or '
          'character rather than appearance: "Your presentation was really '
          'well-organized" builds more connection than surface-level praise.',
      category: AppConstants.eqCategorySocialSkills,
      difficulty: TipDifficulty.beginner,
      scoreThreshold: 60,
    ),
    ImprovementTip(
      title: 'Conflict Resolution Practice',
      description:
          'Use the "I feel ___ when ___ because ___" framework in your next '
          'disagreement. This structure communicates your needs without blame '
          'and dramatically improves conflict outcomes.',
      category: AppConstants.eqCategorySocialSkills,
      difficulty: TipDifficulty.intermediate,
      scoreThreshold: 70,
    ),
    ImprovementTip(
      title: 'Join a Group Activity',
      description:
          'Join a team sport, book club, or hobby group. Structured group '
          'activities provide a low-pressure environment to practice '
          'collaboration, negotiation, and social awareness.',
      category: AppConstants.eqCategorySocialSkills,
      difficulty: TipDifficulty.intermediate,
      scoreThreshold: 80,
    ),
    ImprovementTip(
      title: 'Study Influence & Persuasion',
      description:
          'Read about the psychology of influence (e.g. Cialdini\'s principles). '
          'Understanding social dynamics helps you communicate more effectively '
          'and build stronger professional relationships.',
      category: AppConstants.eqCategorySocialSkills,
      difficulty: TipDifficulty.advanced,
      scoreThreshold: 90,
    ),
    ImprovementTip(
      title: 'Practice Assertiveness',
      description:
          'Express your needs clearly and respectfully without being aggressive '
          'or passive. Start by saying "no" to small requests you would normally '
          'reluctantly accept. Healthy boundaries strengthen all relationships.',
      category: AppConstants.eqCategorySocialSkills,
      difficulty: TipDifficulty.beginner,
      scoreThreshold: 100,
    ),
  ];
}
