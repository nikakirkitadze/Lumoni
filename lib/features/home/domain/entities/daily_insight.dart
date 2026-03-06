import 'package:flutter/material.dart';

/// A daily insight about intelligence, the brain, or emotions.
///
/// The app displays one random insight per day on the home dashboard
/// to keep users engaged and educated.
class DailyInsight {
  final String title;
  final String description;
  final String category;
  final IconData icon;

  const DailyInsight({
    required this.title,
    required this.description,
    required this.category,
    required this.icon,
  });

  /// Returns the insight of the day based on the current date.
  ///
  /// Uses the day-of-year as an index into the list so the insight
  /// changes once per day but remains consistent throughout that day.
  static DailyInsight ofTheDay() {
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year)).inDays;
    return insights[dayOfYear % insights.length];
  }

  /// Master list of curated insights about intelligence, brain science,
  /// emotional intelligence, and cognitive performance.
  static const List<DailyInsight> insights = [
    // ── Brain Science ──────────────────────────────────────────────────
    DailyInsight(
      title: 'Your Brain Never Stops',
      description:
          'Your brain generates about 70,000 thoughts per day and uses '
          '20% of your body\'s total energy, even though it\'s only 2% '
          'of your body weight.',
      category: 'Brain Science',
      icon: Icons.psychology,
    ),
    DailyInsight(
      title: 'Neuroplasticity Is Real',
      description:
          'Your brain can rewire itself at any age. Every time you learn '
          'something new, you physically change the structure of your brain '
          'by forming new neural connections.',
      category: 'Brain Science',
      icon: Icons.hub,
    ),
    DailyInsight(
      title: 'Sleep Powers Intelligence',
      description:
          'During deep sleep, your brain consolidates memories and clears '
          'toxic waste products. Just one night of poor sleep can reduce '
          'cognitive performance by up to 30%.',
      category: 'Brain Science',
      icon: Icons.nightlight_round,
    ),
    DailyInsight(
      title: 'The Mozart Effect',
      description:
          'While listening to classical music doesn\'t permanently raise IQ, '
          'it can temporarily improve spatial-temporal reasoning and boost '
          'focus during complex tasks.',
      category: 'Brain Science',
      icon: Icons.music_note,
    ),
    DailyInsight(
      title: 'Brain Speed',
      description:
          'Information travels through your neurons at speeds up to 268 mph. '
          'That\'s faster than a Formula 1 car. Your brain processes images '
          'in as little as 13 milliseconds.',
      category: 'Brain Science',
      icon: Icons.speed,
    ),
    DailyInsight(
      title: 'The Reading Brain',
      description:
          'Reading physically changes your brain. Regular readers show '
          'increased connectivity in the left temporal cortex, the area '
          'associated with language comprehension.',
      category: 'Brain Science',
      icon: Icons.auto_stories,
    ),

    // ── IQ & Cognitive Performance ─────────────────────────────────────
    DailyInsight(
      title: 'IQ Is Not Fixed',
      description:
          'Research shows that IQ scores can change by up to 20 points '
          'over a lifetime. Education, mental challenges, and a stimulating '
          'environment all contribute to cognitive growth.',
      category: 'IQ',
      icon: Icons.trending_up,
    ),
    DailyInsight(
      title: 'Practice Makes Permanent',
      description:
          'Deliberate practice on cognitive tasks can strengthen specific '
          'neural pathways. The more you challenge your pattern recognition, '
          'the sharper it becomes.',
      category: 'IQ',
      icon: Icons.fitness_center,
    ),
    DailyInsight(
      title: 'The Power of Curiosity',
      description:
          'Curious people tend to score higher on intelligence tests. '
          'Curiosity activates the brain\'s reward system and enhances '
          'memory formation for new information.',
      category: 'IQ',
      icon: Icons.lightbulb,
    ),
    DailyInsight(
      title: 'Working Memory Matters',
      description:
          'Working memory, your ability to hold and manipulate information, '
          'is one of the strongest predictors of fluid intelligence. It can '
          'be trained through targeted exercises.',
      category: 'IQ',
      icon: Icons.memory,
    ),
    DailyInsight(
      title: 'The Testing Effect',
      description:
          'Taking tests actually improves learning more than additional study '
          'time. Each test you complete strengthens the neural pathways for '
          'recall and problem-solving.',
      category: 'IQ',
      icon: Icons.quiz,
    ),
    DailyInsight(
      title: 'Fluid vs. Crystallized',
      description:
          'Fluid intelligence (problem-solving) peaks in your 20s, but '
          'crystallized intelligence (accumulated knowledge) continues '
          'growing well into your 60s and 70s.',
      category: 'IQ',
      icon: Icons.diamond,
    ),
    DailyInsight(
      title: 'Bilingual Advantage',
      description:
          'People who speak two or more languages show enhanced executive '
          'function, better attention control, and delayed cognitive decline '
          'in older age.',
      category: 'IQ',
      icon: Icons.translate,
    ),

    // ── Emotional Intelligence ─────────────────────────────────────────
    DailyInsight(
      title: 'EQ Predicts Success',
      description:
          'Studies show that emotional intelligence accounts for up to 58% '
          'of job performance across all types of careers. It\'s often a '
          'stronger predictor of success than IQ alone.',
      category: 'EQ',
      icon: Icons.favorite,
    ),
    DailyInsight(
      title: 'Emotions Are Data',
      description:
          'Your emotions are information signals from your brain. Learning '
          'to read and interpret them accurately is a core skill of emotional '
          'intelligence that can be developed over time.',
      category: 'EQ',
      icon: Icons.analytics,
    ),
    DailyInsight(
      title: 'The Empathy Muscle',
      description:
          'Empathy is like a muscle that gets stronger with use. Actively '
          'practicing perspective-taking can increase activity in your '
          'brain\'s empathy circuits within weeks.',
      category: 'EQ',
      icon: Icons.people,
    ),
    DailyInsight(
      title: 'Name It to Tame It',
      description:
          'Simply labeling your emotions reduces amygdala activation by up '
          'to 50%. The more specific you can be about what you feel, the '
          'better you can regulate your response.',
      category: 'EQ',
      icon: Icons.label,
    ),
    DailyInsight(
      title: 'Emotional Contagion',
      description:
          'Emotions are literally contagious. Mirror neurons in your brain '
          'cause you to unconsciously mimic the emotions of those around you. '
          'Awareness of this is key to self-regulation.',
      category: 'EQ',
      icon: Icons.group,
    ),
    DailyInsight(
      title: 'The 90-Second Rule',
      description:
          'The chemical process of any emotion lasts only about 90 seconds. '
          'After that, any remaining emotional response is caused by you '
          'choosing to stay in that emotional loop.',
      category: 'EQ',
      icon: Icons.timer,
    ),
    DailyInsight(
      title: 'Self-Awareness First',
      description:
          'Self-awareness is the foundation of all emotional intelligence. '
          'People who regularly reflect on their emotions make better decisions '
          'and build stronger relationships.',
      category: 'EQ',
      icon: Icons.self_improvement,
    ),

    // ── Productivity & Performance ─────────────────────────────────────
    DailyInsight(
      title: 'The 20-Minute Rule',
      description:
          'It takes an average of 23 minutes to refocus after a distraction. '
          'Protecting your focus time is one of the most effective ways to '
          'maximize cognitive performance.',
      category: 'Performance',
      icon: Icons.timer_outlined,
    ),
    DailyInsight(
      title: 'Exercise Boosts IQ',
      description:
          'Regular aerobic exercise increases the size of the hippocampus, '
          'improving memory and learning. Just 30 minutes of exercise can '
          'boost cognitive performance for hours afterward.',
      category: 'Performance',
      icon: Icons.directions_run,
    ),
    DailyInsight(
      title: 'The Power of Breaks',
      description:
          'Strategic breaks during mental work improve focus and creativity. '
          'The Pomodoro technique (25 min work, 5 min break) aligns with '
          'your brain\'s natural attention cycles.',
      category: 'Performance',
      icon: Icons.coffee,
    ),
    DailyInsight(
      title: 'Hydration & Cognition',
      description:
          'Even mild dehydration (1-2% body weight loss) can impair attention, '
          'memory, and mood. Staying hydrated is one of the simplest ways to '
          'maintain peak mental performance.',
      category: 'Performance',
      icon: Icons.water_drop,
    ),
    DailyInsight(
      title: 'Meditation Changes the Brain',
      description:
          'Just 8 weeks of regular meditation can increase gray matter density '
          'in brain regions linked to memory, empathy, and stress regulation. '
          'Even 10 minutes daily makes a difference.',
      category: 'Performance',
      icon: Icons.spa,
    ),
    DailyInsight(
      title: 'The Spacing Effect',
      description:
          'Spreading learning over time (spaced repetition) is far more '
          'effective than cramming. Your brain consolidates information better '
          'when given time between study sessions.',
      category: 'Performance',
      icon: Icons.calendar_today,
    ),

    // ── Mindset & Growth ───────────────────────────────────────────────
    DailyInsight(
      title: 'Growth Mindset Wins',
      description:
          'People who believe intelligence can be developed (growth mindset) '
          'outperform those who think it\'s fixed. Your beliefs about your '
          'own ability literally shape your brain.',
      category: 'Mindset',
      icon: Icons.rocket_launch,
    ),
    DailyInsight(
      title: 'Embrace the Struggle',
      description:
          'The feeling of cognitive struggle is actually a sign of learning. '
          'When a problem feels hard, your brain is building new connections. '
          'Discomfort is where growth happens.',
      category: 'Mindset',
      icon: Icons.bolt,
    ),
    DailyInsight(
      title: 'Failure Is Fertilizer',
      description:
          'Your brain learns more from mistakes than from successes. Error '
          'signals trigger stronger neural encoding, making failures some of '
          'your most valuable learning experiences.',
      category: 'Mindset',
      icon: Icons.eco,
    ),
    DailyInsight(
      title: 'The Power of Yet',
      description:
          'Adding the word "yet" to negative self-talk transforms it. '
          '"I can\'t solve this" becomes "I can\'t solve this yet." '
          'This simple shift activates growth-oriented thinking.',
      category: 'Mindset',
      icon: Icons.auto_awesome,
    ),
    DailyInsight(
      title: 'Teach to Learn',
      description:
          'Explaining concepts to others is one of the most effective '
          'learning strategies. Teaching forces your brain to organize '
          'knowledge more deeply and identify gaps in understanding.',
      category: 'Mindset',
      icon: Icons.school,
    ),
    DailyInsight(
      title: 'Your Brain on Nature',
      description:
          'Spending just 20 minutes in nature reduces cortisol levels and '
          'improves working memory. Natural environments give your brain\'s '
          'directed attention circuits a chance to rest and recharge.',
      category: 'Performance',
      icon: Icons.park,
    ),
    DailyInsight(
      title: 'Social Intelligence',
      description:
          'Strong social connections are linked to better cognitive function '
          'and slower cognitive decline. Meaningful conversations challenge '
          'your brain in ways that solitary activities cannot.',
      category: 'EQ',
      icon: Icons.connect_without_contact,
    ),
    DailyInsight(
      title: 'The Creativity Connection',
      description:
          'Creativity and intelligence share neural networks but are not '
          'identical. Daydreaming activates the brain\'s default mode network, '
          'which is essential for creative problem-solving.',
      category: 'Brain Science',
      icon: Icons.palette,
    ),
  ];
}
