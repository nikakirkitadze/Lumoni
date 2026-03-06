import 'package:lumoni/core/constants/app_constants.dart';
import 'package:lumoni/core/models/eq_question_model.dart';

/// Local bank of 80+ psychologically-valid EQ self-assessment statements.
///
/// Statements are organized across the five Goleman EQ categories:
/// Self-Awareness, Self-Regulation, Motivation, Empathy, and Social Skills.
///
/// Each statement is rated on a 5-point Likert scale from
/// Strongly Disagree (1) to Strongly Agree (5).
///
/// Some items are reverse-scored ([isReversed] = true), meaning they use
/// negative phrasing and higher agreement indicates lower EQ in that dimension.
///
/// Key discriminating items have [weight] = 1.5; all others default to 1.0.
abstract final class EQStatementBank {
  /// Returns all EQ statements as [EQQuestionModel] instances.
  static List<EQQuestionModel> getAllStatements() {
    return _allStatements
        .map((json) => EQQuestionModel.fromJson(json))
        .toList();
  }

  /// Returns statements filtered by [category].
  static List<EQQuestionModel> getStatementsByCategory(String category) {
    return _allStatements
        .where((json) => json['category'] == category)
        .map((json) => EQQuestionModel.fromJson(json))
        .toList();
  }

  /// Returns the total number of statements in the bank.
  static int get totalCount => _allStatements.length;

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // SELF-AWARENESS (17 statements)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  static const String _sa = AppConstants.eqCategorySelfAwareness;

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // SELF-REGULATION (17 statements)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  static const String _sr = AppConstants.eqCategorySelfRegulation;

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // MOTIVATION (17 statements)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  static const String _mo = AppConstants.eqCategoryMotivation;

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // EMPATHY (17 statements)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  static const String _em = AppConstants.eqCategoryEmpathy;

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // SOCIAL SKILLS (17 statements)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  static const String _ss = AppConstants.eqCategorySocialSkills;

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // COMBINED STATEMENT BANK (85 total)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  static const List<Map<String, dynamic>> _allStatements = [
    // ────────────── SELF-AWARENESS ──────────────────────────────────────

    {
      'id': 'sa_01',
      'statement': 'I am aware of my emotions as I experience them',
      'category': _sa,
      'isReversed': false,
      'weight': 1.5,
    },
    {
      'id': 'sa_02',
      'statement': 'I can accurately identify what I am feeling at any given moment',
      'category': _sa,
      'isReversed': false,
      'weight': 1.5,
    },
    {
      'id': 'sa_03',
      'statement': 'I understand how my feelings affect my performance at work or school',
      'category': _sa,
      'isReversed': false,
      'weight': 1.0,
    },
    {
      'id': 'sa_04',
      'statement': 'I recognize my strengths and limitations honestly',
      'category': _sa,
      'isReversed': false,
      'weight': 1.0,
    },
    {
      'id': 'sa_05',
      'statement': 'I know which emotions I am feeling and why',
      'category': _sa,
      'isReversed': false,
      'weight': 1.0,
    },
    {
      'id': 'sa_06',
      'statement': 'I understand the link between my feelings and my behavior',
      'category': _sa,
      'isReversed': false,
      'weight': 1.0,
    },
    {
      'id': 'sa_07',
      'statement': 'I am often confused about what I am feeling',
      'category': _sa,
      'isReversed': true,
      'weight': 1.0,
    },
    {
      'id': 'sa_08',
      'statement': 'I can describe my feelings to others with clarity',
      'category': _sa,
      'isReversed': false,
      'weight': 1.0,
    },
    {
      'id': 'sa_09',
      'statement': 'I am aware of my emotional triggers',
      'category': _sa,
      'isReversed': false,
      'weight': 1.0,
    },
    {
      'id': 'sa_10',
      'statement': 'I reflect on my emotions to understand what caused them',
      'category': _sa,
      'isReversed': false,
      'weight': 1.0,
    },
    {
      'id': 'sa_11',
      'statement': 'I have a realistic assessment of my own abilities',
      'category': _sa,
      'isReversed': false,
      'weight': 1.0,
    },
    {
      'id': 'sa_12',
      'statement': 'My emotions seem to come out of nowhere and surprise me',
      'category': _sa,
      'isReversed': true,
      'weight': 1.0,
    },
    {
      'id': 'sa_13',
      'statement': 'I notice how my mood changes throughout the day',
      'category': _sa,
      'isReversed': false,
      'weight': 1.0,
    },
    {
      'id': 'sa_14',
      'statement': 'I understand how my emotions influence my decisions',
      'category': _sa,
      'isReversed': false,
      'weight': 1.5,
    },
    {
      'id': 'sa_15',
      'statement': 'I can recognize when stress is affecting my judgment',
      'category': _sa,
      'isReversed': false,
      'weight': 1.0,
    },
    {
      'id': 'sa_16',
      'statement': 'I pay attention to how I feel during conversations',
      'category': _sa,
      'isReversed': false,
      'weight': 1.0,
    },
    {
      'id': 'sa_17',
      'statement': 'I have difficulty telling the difference between similar emotions like frustration and disappointment',
      'category': _sa,
      'isReversed': true,
      'weight': 1.0,
    },

    // ────────────── SELF-REGULATION ─────────────────────────────────────

    {
      'id': 'sr_01',
      'statement': 'I can manage my impulses and distressing emotions effectively',
      'category': _sr,
      'isReversed': false,
      'weight': 1.5,
    },
    {
      'id': 'sr_02',
      'statement': 'I stay calm under pressure',
      'category': _sr,
      'isReversed': false,
      'weight': 1.5,
    },
    {
      'id': 'sr_03',
      'statement': 'I think before acting when I am angry',
      'category': _sr,
      'isReversed': false,
      'weight': 1.0,
    },
    {
      'id': 'sr_04',
      'statement': 'I can delay gratification to achieve long-term goals',
      'category': _sr,
      'isReversed': false,
      'weight': 1.0,
    },
    {
      'id': 'sr_05',
      'statement': 'I recover quickly from emotional setbacks',
      'category': _sr,
      'isReversed': false,
      'weight': 1.0,
    },
    {
      'id': 'sr_06',
      'statement': 'I tend to overreact to minor problems',
      'category': _sr,
      'isReversed': true,
      'weight': 1.0,
    },
    {
      'id': 'sr_07',
      'statement': 'I can redirect negative thoughts in a constructive direction',
      'category': _sr,
      'isReversed': false,
      'weight': 1.0,
    },
    {
      'id': 'sr_08',
      'statement': 'I maintain my composure in difficult or confrontational situations',
      'category': _sr,
      'isReversed': false,
      'weight': 1.0,
    },
    {
      'id': 'sr_09',
      'statement': 'I often say things I later regret when I am upset',
      'category': _sr,
      'isReversed': true,
      'weight': 1.0,
    },
    {
      'id': 'sr_10',
      'statement': 'I adapt my emotional responses to fit different situations',
      'category': _sr,
      'isReversed': false,
      'weight': 1.0,
    },
    {
      'id': 'sr_11',
      'statement': 'I am comfortable with ambiguity and uncertainty',
      'category': _sr,
      'isReversed': false,
      'weight': 1.0,
    },
    {
      'id': 'sr_12',
      'statement': 'I can soothe myself when I feel anxious or upset',
      'category': _sr,
      'isReversed': false,
      'weight': 1.0,
    },
    {
      'id': 'sr_13',
      'statement': 'I find it hard to concentrate when I am emotionally upset',
      'category': _sr,
      'isReversed': true,
      'weight': 1.0,
    },
    {
      'id': 'sr_14',
      'statement': 'I hold myself accountable for my emotional reactions',
      'category': _sr,
      'isReversed': false,
      'weight': 1.5,
    },
    {
      'id': 'sr_15',
      'statement': 'I can manage feelings of jealousy or envy without acting on them',
      'category': _sr,
      'isReversed': false,
      'weight': 1.0,
    },
    {
      'id': 'sr_16',
      'statement': 'I use healthy coping strategies when dealing with stress',
      'category': _sr,
      'isReversed': false,
      'weight': 1.0,
    },
    {
      'id': 'sr_17',
      'statement': 'I often feel overwhelmed by my emotions',
      'category': _sr,
      'isReversed': true,
      'weight': 1.0,
    },

    // ────────────── MOTIVATION ──────────────────────────────────────────

    {
      'id': 'mo_01',
      'statement': 'I persist in the face of obstacles and setbacks',
      'category': _mo,
      'isReversed': false,
      'weight': 1.5,
    },
    {
      'id': 'mo_02',
      'statement': 'I set challenging goals for myself and strive to achieve them',
      'category': _mo,
      'isReversed': false,
      'weight': 1.0,
    },
    {
      'id': 'mo_03',
      'statement': 'I am driven by a desire to achieve beyond expectations',
      'category': _mo,
      'isReversed': false,
      'weight': 1.0,
    },
    {
      'id': 'mo_04',
      'statement': 'I remain optimistic even when things do not go as planned',
      'category': _mo,
      'isReversed': false,
      'weight': 1.5,
    },
    {
      'id': 'mo_05',
      'statement': 'I am passionate about what I do in my daily life',
      'category': _mo,
      'isReversed': false,
      'weight': 1.0,
    },
    {
      'id': 'mo_06',
      'statement': 'I look for creative solutions when faced with a challenge',
      'category': _mo,
      'isReversed': false,
      'weight': 1.0,
    },
    {
      'id': 'mo_07',
      'statement': 'I give up easily when tasks become difficult',
      'category': _mo,
      'isReversed': true,
      'weight': 1.0,
    },
    {
      'id': 'mo_08',
      'statement': 'I view failures as learning opportunities rather than defeats',
      'category': _mo,
      'isReversed': false,
      'weight': 1.0,
    },
    {
      'id': 'mo_09',
      'statement': 'I maintain focus and dedication on tasks even when they are tedious',
      'category': _mo,
      'isReversed': false,
      'weight': 1.0,
    },
    {
      'id': 'mo_10',
      'statement': 'I take initiative rather than waiting for others to direct me',
      'category': _mo,
      'isReversed': false,
      'weight': 1.0,
    },
    {
      'id': 'mo_11',
      'statement': 'I feel a sense of purpose in the work that I do',
      'category': _mo,
      'isReversed': false,
      'weight': 1.0,
    },
    {
      'id': 'mo_12',
      'statement': 'I have difficulty motivating myself without external rewards',
      'category': _mo,
      'isReversed': true,
      'weight': 1.0,
    },
    {
      'id': 'mo_13',
      'statement': 'I continuously look for ways to improve myself',
      'category': _mo,
      'isReversed': false,
      'weight': 1.0,
    },
    {
      'id': 'mo_14',
      'statement': 'I stay committed to my goals even when progress is slow',
      'category': _mo,
      'isReversed': false,
      'weight': 1.5,
    },
    {
      'id': 'mo_15',
      'statement': 'I embrace change as an opportunity for growth',
      'category': _mo,
      'isReversed': false,
      'weight': 1.0,
    },
    {
      'id': 'mo_16',
      'statement': 'I often procrastinate on important tasks',
      'category': _mo,
      'isReversed': true,
      'weight': 1.0,
    },
    {
      'id': 'mo_17',
      'statement': 'I find it easy to bounce back after a disappointment',
      'category': _mo,
      'isReversed': false,
      'weight': 1.0,
    },

    // ────────────── EMPATHY ────────────────────────────────────────────

    {
      'id': 'em_01',
      'statement': 'I can sense what others are feeling without them telling me',
      'category': _em,
      'isReversed': false,
      'weight': 1.5,
    },
    {
      'id': 'em_02',
      'statement': 'I listen attentively to what others have to say',
      'category': _em,
      'isReversed': false,
      'weight': 1.0,
    },
    {
      'id': 'em_03',
      'statement': 'I can put myself in other people\'s shoes and understand their perspective',
      'category': _em,
      'isReversed': false,
      'weight': 1.5,
    },
    {
      'id': 'em_04',
      'statement': 'I pick up on social cues and body language easily',
      'category': _em,
      'isReversed': false,
      'weight': 1.0,
    },
    {
      'id': 'em_05',
      'statement': 'I am sensitive to the feelings and needs of others',
      'category': _em,
      'isReversed': false,
      'weight': 1.0,
    },
    {
      'id': 'em_06',
      'statement': 'I find it difficult to understand why people react the way they do',
      'category': _em,
      'isReversed': true,
      'weight': 1.0,
    },
    {
      'id': 'em_07',
      'statement': 'I offer support to people when they are going through a hard time',
      'category': _em,
      'isReversed': false,
      'weight': 1.0,
    },
    {
      'id': 'em_08',
      'statement': 'I recognize when someone is uncomfortable in a social situation',
      'category': _em,
      'isReversed': false,
      'weight': 1.0,
    },
    {
      'id': 'em_09',
      'statement': 'I feel moved by others\' emotional experiences',
      'category': _em,
      'isReversed': false,
      'weight': 1.0,
    },
    {
      'id': 'em_10',
      'statement': 'I have trouble reading the emotional tone in a conversation',
      'category': _em,
      'isReversed': true,
      'weight': 1.0,
    },
    {
      'id': 'em_11',
      'statement': 'I consider how my actions might affect other people\'s feelings',
      'category': _em,
      'isReversed': false,
      'weight': 1.0,
    },
    {
      'id': 'em_12',
      'statement': 'I can tell when someone is saying one thing but feeling another',
      'category': _em,
      'isReversed': false,
      'weight': 1.0,
    },
    {
      'id': 'em_13',
      'statement': 'I try to understand people\'s behavior by considering their circumstances',
      'category': _em,
      'isReversed': false,
      'weight': 1.0,
    },
    {
      'id': 'em_14',
      'statement': 'I notice shifts in group mood or energy during meetings or gatherings',
      'category': _em,
      'isReversed': false,
      'weight': 1.0,
    },
    {
      'id': 'em_15',
      'statement': 'I am comfortable being around people who express strong emotions',
      'category': _em,
      'isReversed': false,
      'weight': 1.0,
    },
    {
      'id': 'em_16',
      'statement': 'I tend to dismiss or minimize other people\'s emotional reactions',
      'category': _em,
      'isReversed': true,
      'weight': 1.0,
    },
    {
      'id': 'em_17',
      'statement': 'I adjust my communication style based on the emotional state of the person I am speaking with',
      'category': _em,
      'isReversed': false,
      'weight': 1.5,
    },

    // ────────────── SOCIAL SKILLS ──────────────────────────────────────

    {
      'id': 'ss_01',
      'statement': 'I can resolve conflicts effectively and fairly',
      'category': _ss,
      'isReversed': false,
      'weight': 1.5,
    },
    {
      'id': 'ss_02',
      'statement': 'I communicate my ideas clearly and persuasively',
      'category': _ss,
      'isReversed': false,
      'weight': 1.0,
    },
    {
      'id': 'ss_03',
      'statement': 'I work well in teams and value collaboration',
      'category': _ss,
      'isReversed': false,
      'weight': 1.0,
    },
    {
      'id': 'ss_04',
      'statement': 'I can build rapport easily with new people',
      'category': _ss,
      'isReversed': false,
      'weight': 1.0,
    },
    {
      'id': 'ss_05',
      'statement': 'I inspire and guide others toward shared goals',
      'category': _ss,
      'isReversed': false,
      'weight': 1.0,
    },
    {
      'id': 'ss_06',
      'statement': 'I find it hard to maintain friendships over time',
      'category': _ss,
      'isReversed': true,
      'weight': 1.0,
    },
    {
      'id': 'ss_07',
      'statement': 'I am effective at negotiating and finding win-win solutions',
      'category': _ss,
      'isReversed': false,
      'weight': 1.0,
    },
    {
      'id': 'ss_08',
      'statement': 'I can influence others without resorting to manipulation or pressure',
      'category': _ss,
      'isReversed': false,
      'weight': 1.5,
    },
    {
      'id': 'ss_09',
      'statement': 'I give constructive feedback in a way that is helpful rather than hurtful',
      'category': _ss,
      'isReversed': false,
      'weight': 1.0,
    },
    {
      'id': 'ss_10',
      'statement': 'I avoid social situations because they feel uncomfortable',
      'category': _ss,
      'isReversed': true,
      'weight': 1.0,
    },
    {
      'id': 'ss_11',
      'statement': 'I can manage disagreements without damaging the relationship',
      'category': _ss,
      'isReversed': false,
      'weight': 1.0,
    },
    {
      'id': 'ss_12',
      'statement': 'I help create a positive and supportive environment in groups',
      'category': _ss,
      'isReversed': false,
      'weight': 1.0,
    },
    {
      'id': 'ss_13',
      'statement': 'I adapt my approach based on the dynamics of the group I am in',
      'category': _ss,
      'isReversed': false,
      'weight': 1.0,
    },
    {
      'id': 'ss_14',
      'statement': 'I am skilled at reading the political and social currents in an organization',
      'category': _ss,
      'isReversed': false,
      'weight': 1.0,
    },
    {
      'id': 'ss_15',
      'statement': 'I struggle to express my needs or boundaries in relationships',
      'category': _ss,
      'isReversed': true,
      'weight': 1.0,
    },
    {
      'id': 'ss_16',
      'statement': 'I listen to and acknowledge other viewpoints even when I disagree',
      'category': _ss,
      'isReversed': false,
      'weight': 1.5,
    },
    {
      'id': 'ss_17',
      'statement': 'I use humor appropriately to ease tension in difficult situations',
      'category': _ss,
      'isReversed': false,
      'weight': 1.0,
    },
  ];
}
