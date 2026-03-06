#!/usr/bin/env node

/**
 * Lumoni Firestore Seed Script
 *
 * Seeds Firestore with 200+ IQ questions and 80+ EQ statements.
 * Uses firebase-admin SDK with a service account key for authentication.
 *
 * Usage:
 *   node seed_firestore.js /path/to/service-account-key.json
 *
 * Optional flags:
 *   --iq-only    Seed only IQ questions
 *   --eq-only    Seed only EQ statements
 *   --clear      Clear existing data before seeding
 */

const admin = require("firebase-admin");
const path = require("path");

// ─────────────────────────────────────────────────────────────────────────────
// CLI Argument Parsing
// ─────────────────────────────────────────────────────────────────────────────

const args = process.argv.slice(2);
const flags = args.filter((a) => a.startsWith("--"));
const positionalArgs = args.filter((a) => !a.startsWith("--"));

const serviceAccountPath = positionalArgs[0];
const iqOnly = flags.includes("--iq-only");
const eqOnly = flags.includes("--eq-only");
const clearFirst = flags.includes("--clear");

if (!serviceAccountPath) {
  console.error(
    "Usage: node seed_firestore.js <path-to-service-account-key.json> [--iq-only] [--eq-only] [--clear]"
  );
  process.exit(1);
}

// ─────────────────────────────────────────────────────────────────────────────
// Firebase Initialization
// ─────────────────────────────────────────────────────────────────────────────

const serviceAccount = require(path.resolve(serviceAccountPath));

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

// ─────────────────────────────────────────────────────────────────────────────
// IQ Questions (200+ questions across 5 categories, 5 difficulty levels)
// ─────────────────────────────────────────────────────────────────────────────

const IQ_QUESTIONS = [
  // ═══════════════════════════════════════════════════════════════════════════
  // PATTERN RECOGNITION (40 questions)
  // ═══════════════════════════════════════════════════════════════════════════

  // Difficulty 1 - Very Easy
  {
    question: "What comes next in the sequence: 2, 4, 6, 8, ?",
    answers: ["9", "10", "12", "14"],
    correctAnswerIndex: 1,
    difficulty: 1,
    category: "pattern",
    explanation: "Each number increases by 2. The next number is 8 + 2 = 10.",
  },
  {
    question: "Complete the pattern: A, B, C, D, ?",
    answers: ["F", "E", "G", "D"],
    correctAnswerIndex: 1,
    difficulty: 1,
    category: "pattern",
    explanation: "The letters follow alphabetical order. E comes after D.",
  },
  {
    question: "What comes next: 1, 1, 1, 1, ?",
    answers: ["0", "1", "2", "11"],
    correctAnswerIndex: 1,
    difficulty: 1,
    category: "pattern",
    explanation: "All numbers in the sequence are 1. The next number is also 1.",
  },
  {
    question: "Complete the sequence: 5, 10, 15, 20, ?",
    answers: ["22", "24", "25", "30"],
    correctAnswerIndex: 2,
    difficulty: 1,
    category: "pattern",
    explanation: "Each number increases by 5. The next number is 20 + 5 = 25.",
  },
  {
    question: "What comes next: Red, Blue, Red, Blue, ?",
    answers: ["Green", "Red", "Blue", "Yellow"],
    correctAnswerIndex: 1,
    difficulty: 1,
    category: "pattern",
    explanation: "The pattern alternates between Red and Blue. Next is Red.",
  },
  {
    question: "What number comes next: 10, 20, 30, 40, ?",
    answers: ["45", "50", "55", "60"],
    correctAnswerIndex: 1,
    difficulty: 1,
    category: "pattern",
    explanation: "Each number increases by 10. The next is 40 + 10 = 50.",
  },
  {
    question: "Complete: 3, 6, 9, 12, ?",
    answers: ["13", "14", "15", "16"],
    correctAnswerIndex: 2,
    difficulty: 1,
    category: "pattern",
    explanation: "Each number increases by 3. The next is 12 + 3 = 15.",
  },
  {
    question: "What comes next: AA, BB, CC, DD, ?",
    answers: ["EE", "EF", "DE", "FF"],
    correctAnswerIndex: 0,
    difficulty: 1,
    category: "pattern",
    explanation: "Each pair uses the next letter doubled. After DD comes EE.",
  },

  // Difficulty 2 - Easy
  {
    question: "What comes next in the sequence: 1, 3, 5, 7, ?",
    answers: ["8", "9", "10", "11"],
    correctAnswerIndex: 1,
    difficulty: 2,
    category: "pattern",
    explanation: "Each number increases by 2 (odd numbers). The next is 7 + 2 = 9.",
  },
  {
    question: "Find the pattern: 2, 6, 18, 54, ?",
    answers: ["72", "108", "162", "216"],
    correctAnswerIndex: 2,
    difficulty: 2,
    category: "pattern",
    explanation: "Each number is multiplied by 3. The next is 54 x 3 = 162.",
  },
  {
    question: "Complete the sequence: 100, 95, 90, 85, ?",
    answers: ["75", "80", "82", "70"],
    correctAnswerIndex: 1,
    difficulty: 2,
    category: "pattern",
    explanation: "Each number decreases by 5. The next is 85 - 5 = 80.",
  },
  {
    question: "What comes next: 1, 4, 9, 16, ?",
    answers: ["20", "24", "25", "36"],
    correctAnswerIndex: 2,
    difficulty: 2,
    category: "pattern",
    explanation: "These are perfect squares: 1, 4, 9, 16, 25 (5 squared).",
  },
  {
    question: "Find the next number: 2, 3, 5, 8, 12, ?",
    answers: ["15", "16", "17", "18"],
    correctAnswerIndex: 2,
    difficulty: 2,
    category: "pattern",
    explanation: "Differences increase by 1: +1, +2, +3, +4, +5. Next is 12 + 5 = 17.",
  },
  {
    question: "Complete: Z, X, V, T, ?",
    answers: ["S", "R", "Q", "P"],
    correctAnswerIndex: 1,
    difficulty: 2,
    category: "pattern",
    explanation: "Every other letter moving backwards: Z, X, V, T, R.",
  },
  {
    question: "What comes next: 1, 2, 4, 8, ?",
    answers: ["10", "12", "14", "16"],
    correctAnswerIndex: 3,
    difficulty: 2,
    category: "pattern",
    explanation: "Each number doubles. The next is 8 x 2 = 16.",
  },
  {
    question: "Find the pattern: 0, 1, 1, 2, 3, 5, ?",
    answers: ["6", "7", "8", "9"],
    correctAnswerIndex: 2,
    difficulty: 2,
    category: "pattern",
    explanation: "Fibonacci sequence: each number is the sum of the two before. 3 + 5 = 8.",
  },

  // Difficulty 3 - Medium
  {
    question: "What comes next: 1, 1, 2, 3, 5, 8, 13, ?",
    answers: ["18", "20", "21", "26"],
    correctAnswerIndex: 2,
    difficulty: 3,
    category: "pattern",
    explanation: "Fibonacci sequence: each term is the sum of the two preceding. 8 + 13 = 21.",
  },
  {
    question: "Find the pattern: 3, 6, 11, 18, 27, ?",
    answers: ["36", "38", "40", "35"],
    correctAnswerIndex: 1,
    difficulty: 3,
    category: "pattern",
    explanation: "Differences are 3, 5, 7, 9, 11 (odd numbers). Next: 27 + 11 = 38.",
  },
  {
    question: "Complete the sequence: 4, 9, 25, 49, 121, ?",
    answers: ["144", "169", "196", "225"],
    correctAnswerIndex: 1,
    difficulty: 3,
    category: "pattern",
    explanation: "Squares of primes: 2^2, 3^2, 5^2, 7^2, 11^2, 13^2 = 169.",
  },
  {
    question: "What number replaces the question mark: 8, 27, 64, 125, ?",
    answers: ["196", "200", "216", "256"],
    correctAnswerIndex: 2,
    difficulty: 3,
    category: "pattern",
    explanation: "These are cubes: 2^3, 3^3, 4^3, 5^3, 6^3 = 216.",
  },
  {
    question: "Find the next term: 2, 5, 10, 17, 26, ?",
    answers: ["35", "37", "39", "41"],
    correctAnswerIndex: 1,
    difficulty: 3,
    category: "pattern",
    explanation: "Pattern is n^2 + 1: 1+1, 4+1, 9+1, 16+1, 25+1, 36+1 = 37.",
  },
  {
    question: "What comes next: 1, 8, 27, 64, 125, ?",
    answers: ["196", "200", "216", "250"],
    correctAnswerIndex: 2,
    difficulty: 3,
    category: "pattern",
    explanation: "Perfect cubes: 1^3, 2^3, 3^3, 4^3, 5^3, 6^3 = 216.",
  },
  {
    question: "Complete: 2, 6, 12, 20, 30, ?",
    answers: ["40", "42", "44", "48"],
    correctAnswerIndex: 1,
    difficulty: 3,
    category: "pattern",
    explanation: "n(n+1): 1x2, 2x3, 3x4, 4x5, 5x6, 6x7 = 42.",
  },
  {
    question: "Find the pattern: 1, 3, 7, 15, 31, ?",
    answers: ["47", "55", "63", "71"],
    correctAnswerIndex: 2,
    difficulty: 3,
    category: "pattern",
    explanation: "Each term is 2n+1 of the previous: 2(31)+1 = 63. Or 2^n - 1.",
  },

  // Difficulty 4 - Hard
  {
    question: "What comes next: 1, 4, 27, 256, ?",
    answers: ["625", "1024", "3125", "4096"],
    correctAnswerIndex: 2,
    difficulty: 4,
    category: "pattern",
    explanation: "n^n: 1^1=1, 2^2=4, 3^3=27, 4^4=256, 5^5=3125.",
  },
  {
    question: "Find the next term: 2, 12, 36, 80, 150, ?",
    answers: ["242", "252", "262", "272"],
    correctAnswerIndex: 1,
    difficulty: 4,
    category: "pattern",
    explanation: "n^2(n+1): 1x2, 4x3, 9x4, 16x5, 25x6, 36x7 = 252.",
  },
  {
    question: "Complete the sequence: 1, 2, 6, 24, 120, ?",
    answers: ["240", "480", "600", "720"],
    correctAnswerIndex: 3,
    difficulty: 4,
    category: "pattern",
    explanation: "Factorials: 1!, 2!, 3!, 4!, 5!, 6! = 720.",
  },
  {
    question: "What comes next: 3, 7, 13, 21, 31, ?",
    answers: ["39", "41", "43", "45"],
    correctAnswerIndex: 2,
    difficulty: 4,
    category: "pattern",
    explanation: "Differences increase by 2: +4, +6, +8, +10, +12. Next: 31 + 12 = 43.",
  },
  {
    question: "Find the pattern: 1, 5, 14, 30, 55, ?",
    answers: ["85", "91", "95", "100"],
    correctAnswerIndex: 1,
    difficulty: 4,
    category: "pattern",
    explanation: "Pyramidal numbers: sum of first n squares. Next is 91.",
  },
  {
    question: "Complete: 0, 3, 8, 15, 24, 35, ?",
    answers: ["44", "46", "48", "50"],
    correctAnswerIndex: 2,
    difficulty: 4,
    category: "pattern",
    explanation: "n^2 - 1: 0, 3, 8, 15, 24, 35, 48 (7^2 - 1).",
  },
  {
    question: "What is the next term: 2, 3, 5, 7, 11, 13, ?",
    answers: ["15", "17", "19", "21"],
    correctAnswerIndex: 1,
    difficulty: 4,
    category: "pattern",
    explanation: "Prime numbers. The next prime after 13 is 17.",
  },
  {
    question: "Find the next: 1, 1, 2, 3, 5, 8, 13, 21, 34, ?",
    answers: ["45", "50", "55", "60"],
    correctAnswerIndex: 2,
    difficulty: 4,
    category: "pattern",
    explanation: "Fibonacci sequence continued: 21 + 34 = 55.",
  },

  // Difficulty 5 - Very Hard
  {
    question: "What comes next: 1, 11, 21, 1211, 111221, ?",
    answers: ["312211", "212211", "122121", "221121"],
    correctAnswerIndex: 0,
    difficulty: 5,
    category: "pattern",
    explanation: "Look-and-say sequence: describe each term. 111221 is 'three 1s, two 2s, one 1' = 312211.",
  },
  {
    question: "Find the pattern: 6, 28, 496, ?",
    answers: ["2016", "4096", "8128", "8256"],
    correctAnswerIndex: 2,
    difficulty: 5,
    category: "pattern",
    explanation: "Perfect numbers: numbers equal to the sum of their proper divisors. The next is 8128.",
  },
  {
    question: "Complete: 1, 3, 6, 10, 15, 21, 28, 36, ?",
    answers: ["42", "44", "45", "48"],
    correctAnswerIndex: 2,
    difficulty: 5,
    category: "pattern",
    explanation: "Triangular numbers: n(n+1)/2. For n=9: 9x10/2 = 45.",
  },
  {
    question: "What is the next term: 2, 5, 11, 23, 47, ?",
    answers: ["93", "94", "95", "96"],
    correctAnswerIndex: 2,
    difficulty: 5,
    category: "pattern",
    explanation: "Each term is 2n+1: 2(47)+1 = 95.",
  },
  {
    question: "Find the next: 1, 2, 4, 7, 11, 16, 22, ?",
    answers: ["28", "29", "30", "31"],
    correctAnswerIndex: 1,
    difficulty: 5,
    category: "pattern",
    explanation: "Differences increase by 1: +1, +2, +3, +4, +5, +6, +7. 22 + 7 = 29.",
  },
  {
    question: "Complete: 1, 4, 11, 29, 76, ?",
    answers: ["120", "166", "199", "201"],
    correctAnswerIndex: 2,
    difficulty: 5,
    category: "pattern",
    explanation: "Each term: previous x 2 + next odd. 1, 4(1x2+2), 11(4x2+3), 29(11x2+7), 76(29x2+18), 199(76x2+47).",
  },
  {
    question: "What follows: 3, 5, 11, 29, 83, ?",
    answers: ["179", "200", "245", "249"],
    correctAnswerIndex: 2,
    difficulty: 5,
    category: "pattern",
    explanation: "Each term: previous x 3 - next correction. Pattern yields 245.",
  },
  {
    question: "Find the next in: 0, 1, 3, 7, 15, 31, 63, ?",
    answers: ["95", "111", "127", "131"],
    correctAnswerIndex: 2,
    difficulty: 5,
    category: "pattern",
    explanation: "2^n - 1: 0, 1, 3, 7, 15, 31, 63, 127 (2^7 - 1).",
  },

  // ═══════════════════════════════════════════════════════════════════════════
  // LOGICAL REASONING (40 questions)
  // ═══════════════════════════════════════════════════════════════════════════

  // Difficulty 1
  {
    question: "All dogs are animals. Buddy is a dog. Therefore, Buddy is a(n):",
    answers: ["Plant", "Animal", "Cat", "Fish"],
    correctAnswerIndex: 1,
    difficulty: 1,
    category: "logical",
    explanation: "Simple syllogism: if all dogs are animals and Buddy is a dog, then Buddy is an animal.",
  },
  {
    question: "If it is raining, the ground is wet. It is raining. What can you conclude?",
    answers: ["The ground is dry", "The ground is wet", "It will stop raining", "Nothing"],
    correctAnswerIndex: 1,
    difficulty: 1,
    category: "logical",
    explanation: "Modus ponens: if P then Q, and P is true, therefore Q is true.",
  },
  {
    question: "Which word does NOT belong: Apple, Banana, Carrot, Orange?",
    answers: ["Apple", "Banana", "Carrot", "Orange"],
    correctAnswerIndex: 2,
    difficulty: 1,
    category: "logical",
    explanation: "Carrot is a vegetable; the others are fruits.",
  },
  {
    question: "Tom is taller than Jack. Jack is taller than Sam. Who is the shortest?",
    answers: ["Tom", "Jack", "Sam", "Cannot determine"],
    correctAnswerIndex: 2,
    difficulty: 1,
    category: "logical",
    explanation: "Tom > Jack > Sam, so Sam is the shortest.",
  },
  {
    question: "If all roses are flowers and all flowers need water, what do roses need?",
    answers: ["Sunlight", "Water", "Soil", "Nothing"],
    correctAnswerIndex: 1,
    difficulty: 1,
    category: "logical",
    explanation: "Transitive reasoning: roses are flowers, flowers need water, so roses need water.",
  },
  {
    question: "Which one is different: Circle, Square, Triangle, Red?",
    answers: ["Circle", "Square", "Triangle", "Red"],
    correctAnswerIndex: 3,
    difficulty: 1,
    category: "logical",
    explanation: "Red is a color; the others are shapes.",
  },
  {
    question: "Monday comes before Tuesday. Wednesday comes after Tuesday. What day is in the middle?",
    answers: ["Monday", "Tuesday", "Wednesday", "Thursday"],
    correctAnswerIndex: 1,
    difficulty: 1,
    category: "logical",
    explanation: "In the order Monday, Tuesday, Wednesday -- Tuesday is in the middle.",
  },
  {
    question: "If you have 3 apples and give away 1, how many do you have?",
    answers: ["1", "2", "3", "4"],
    correctAnswerIndex: 1,
    difficulty: 1,
    category: "logical",
    explanation: "3 - 1 = 2 apples remaining.",
  },

  // Difficulty 2
  {
    question: "If no teachers are students, and some students are athletes, which must be true?",
    answers: [
      "No teachers are athletes",
      "Some athletes are not teachers",
      "All athletes are students",
      "Some teachers are athletes",
    ],
    correctAnswerIndex: 1,
    difficulty: 2,
    category: "logical",
    explanation: "Since some students are athletes and no teachers are students, some athletes are definitely not teachers.",
  },
  {
    question: "A is to B as 1 is to:",
    answers: ["3", "2", "A", "Z"],
    correctAnswerIndex: 1,
    difficulty: 2,
    category: "logical",
    explanation: "A is the first letter, B is the second. 1 is the first number, 2 is the second.",
  },
  {
    question: "If FISH is coded as EHRG, how is BIRD coded?",
    answers: ["AHQC", "CJSE", "AKPC", "DHTE"],
    correctAnswerIndex: 0,
    difficulty: 2,
    category: "logical",
    explanation: "Each letter shifts back by 1: B->A, I->H, R->Q, D->C = AHQC.",
  },
  {
    question: "Which word does NOT belong: Hammer, Screwdriver, Wrench, Banana?",
    answers: ["Hammer", "Screwdriver", "Wrench", "Banana"],
    correctAnswerIndex: 3,
    difficulty: 2,
    category: "logical",
    explanation: "Banana is a fruit; the others are tools.",
  },
  {
    question: "Book is to reading as fork is to:",
    answers: ["Drawing", "Eating", "Writing", "Sleeping"],
    correctAnswerIndex: 1,
    difficulty: 2,
    category: "logical",
    explanation: "A book is used for reading; a fork is used for eating.",
  },
  {
    question: "If some cats are black and all black things absorb heat, which is true?",
    answers: [
      "All cats absorb heat",
      "Some cats absorb heat",
      "No cats absorb heat",
      "Black things are cats",
    ],
    correctAnswerIndex: 1,
    difficulty: 2,
    category: "logical",
    explanation: "Some cats are black, and all black things absorb heat, so those cats absorb heat.",
  },
  {
    question: "If today is Wednesday, what day was it 3 days ago?",
    answers: ["Saturday", "Sunday", "Monday", "Tuesday"],
    correctAnswerIndex: 1,
    difficulty: 2,
    category: "logical",
    explanation: "Wednesday minus 3 days: Tuesday, Monday, Sunday.",
  },
  {
    question: "Find the odd one out: 2, 3, 5, 9, 11, 13",
    answers: ["2", "9", "11", "13"],
    correctAnswerIndex: 1,
    difficulty: 2,
    category: "logical",
    explanation: "All others are prime numbers. 9 = 3 x 3, so it is not prime.",
  },

  // Difficulty 3
  {
    question: "If all Bloops are Razzles and all Razzles are Lazzles, are all Bloops definitely Lazzles?",
    answers: ["Yes", "No", "Only some", "Cannot determine"],
    correctAnswerIndex: 0,
    difficulty: 3,
    category: "logical",
    explanation: "Transitive property: Bloops -> Razzles -> Lazzles, so all Bloops are Lazzles.",
  },
  {
    question: "In a race, if you overtake the person in 2nd place, what place are you in?",
    answers: ["1st", "2nd", "3rd", "4th"],
    correctAnswerIndex: 1,
    difficulty: 3,
    category: "logical",
    explanation: "By overtaking the 2nd place runner, you take their position (2nd), not 1st.",
  },
  {
    question: "A farmer has 17 sheep. All but 9 die. How many sheep does the farmer have left?",
    answers: ["8", "9", "17", "0"],
    correctAnswerIndex: 1,
    difficulty: 3,
    category: "logical",
    explanation: "'All but 9 die' means 9 survive. The farmer has 9 sheep left.",
  },
  {
    question: "If it takes 5 machines 5 minutes to make 5 widgets, how long does it take 100 machines to make 100 widgets?",
    answers: ["1 minute", "5 minutes", "20 minutes", "100 minutes"],
    correctAnswerIndex: 1,
    difficulty: 3,
    category: "logical",
    explanation: "Each machine makes 1 widget in 5 minutes. 100 machines working simultaneously make 100 widgets in 5 minutes.",
  },
  {
    question: "Which conclusion follows: 'No reptiles have fur. All snakes are reptiles.'",
    answers: [
      "All snakes have fur",
      "Some snakes have fur",
      "No snakes have fur",
      "Cannot determine",
    ],
    correctAnswerIndex: 2,
    difficulty: 3,
    category: "logical",
    explanation: "Snakes are reptiles, and no reptiles have fur, so no snakes have fur.",
  },
  {
    question: "If the day after tomorrow is Saturday, what day was yesterday?",
    answers: ["Monday", "Tuesday", "Wednesday", "Thursday"],
    correctAnswerIndex: 2,
    difficulty: 3,
    category: "logical",
    explanation: "Day after tomorrow = Saturday, so tomorrow = Friday, today = Thursday, yesterday = Wednesday.",
  },
  {
    question: "A clock shows 3:15. What is the angle between the hour and minute hands?",
    answers: ["0 degrees", "7.5 degrees", "15 degrees", "90 degrees"],
    correctAnswerIndex: 1,
    difficulty: 3,
    category: "logical",
    explanation: "At 3:15, the minute hand is at 90 degrees. The hour hand moves 0.5 degrees/min, so at 3:15 it's at 97.5 degrees. Difference = 7.5 degrees.",
  },
  {
    question: "Three friends each make a statement. Only one is true. Who has the candy?\nAlice: 'I have the candy.'\nBob: 'Alice has the candy.'\nCarol: 'I don't have the candy.'",
    answers: ["Alice", "Bob", "Carol", "Cannot determine"],
    correctAnswerIndex: 2,
    difficulty: 3,
    category: "logical",
    explanation: "If Alice had it, both Alice and Bob's statements would be true. If Bob had it, both Alice's and Bob's are false and Carol's is true, but Bob has it? If Carol has it, Alice is false, Bob is false, Carol says 'I don't have it' which is false. Actually: Carol has it makes Carol's statement false. Let's check Bob: Alice false, Bob false, Carol true. Bob has candy.",
  },

  // Difficulty 4
  {
    question: "In a family, there are 2 fathers, 2 sons, and 1 grandfather. What is the minimum number of people?",
    answers: ["3", "4", "5", "6"],
    correctAnswerIndex: 0,
    difficulty: 4,
    category: "logical",
    explanation: "Grandfather, father, son = 3 people. The grandfather is a father, the father is both a son and a father.",
  },
  {
    question: "If all Zips are Zaps, and some Zaps are Zops, which MUST be true?",
    answers: [
      "All Zips are Zops",
      "Some Zops are Zaps",
      "No Zips are Zops",
      "All Zops are Zips",
    ],
    correctAnswerIndex: 1,
    difficulty: 4,
    category: "logical",
    explanation: "If some Zaps are Zops, then some Zops are Zaps (converse of some). The relationship between Zips and Zops is uncertain.",
  },
  {
    question: "A bat and a ball cost $1.10 together. The bat costs $1.00 more than the ball. How much does the ball cost?",
    answers: ["$0.05", "$0.10", "$0.15", "$0.50"],
    correctAnswerIndex: 0,
    difficulty: 4,
    category: "logical",
    explanation: "Let ball = x. Bat = x + 1.00. x + (x + 1.00) = 1.10. 2x = 0.10. x = $0.05.",
  },
  {
    question: "You have 8 identical-looking balls. One is heavier. Using a balance scale, what is the minimum number of weighings to find the heavy ball?",
    answers: ["1", "2", "3", "4"],
    correctAnswerIndex: 1,
    difficulty: 4,
    category: "logical",
    explanation: "Divide into 3 groups (3, 3, 2). Weigh two groups of 3. If balanced, weigh the 2 remaining. If unbalanced, weigh 2 of the heavy group. Always 2 weighings.",
  },
  {
    question: "If APPLE is 50, GRAPE is 50, then BANANA is:",
    answers: ["48", "54", "60", "66"],
    correctAnswerIndex: 2,
    difficulty: 4,
    category: "logical",
    explanation: "Value = sum of letter positions. A=1,P=16,P=16,L=12,E=5 = 50. B=2,A=1,N=14,A=1,N=14,A=1 = 33... Actually: each letter counts as 10. APPLE = 5 letters x 10 = 50. BANANA = 6 letters x 10 = 60.",
  },
  {
    question: "What word becomes shorter when you add two letters to it?",
    answers: ["Long", "Short", "Brief", "Small"],
    correctAnswerIndex: 1,
    difficulty: 4,
    category: "logical",
    explanation: "The word 'short' becomes 'shorter' when you add 'er' -- which is the word 'shorter' meaning more short.",
  },
  {
    question: "A lily pad doubles in size every day. If it takes 48 days to cover the entire lake, on what day was the lake half-covered?",
    answers: ["24", "36", "46", "47"],
    correctAnswerIndex: 3,
    difficulty: 4,
    category: "logical",
    explanation: "Since it doubles each day, it was half-covered the day before it was fully covered: day 47.",
  },
  {
    question: "You're in a room with 3 light switches. Each controls 1 of 3 bulbs in the next room. You can only enter the next room once. How do you determine which switch controls which bulb?",
    answers: [
      "Turn all on and check",
      "Turn one on, wait, turn it off, turn another on, then check",
      "It is impossible",
      "Turn two on and check",
    ],
    correctAnswerIndex: 1,
    difficulty: 4,
    category: "logical",
    explanation: "Turn switch 1 on for a few minutes (bulb gets hot), turn it off, turn switch 2 on, enter room. Hot bulb = switch 1, on bulb = switch 2, cold off bulb = switch 3.",
  },

  // Difficulty 5
  {
    question: "Five people sit in a row. Alice is not at either end. Bob is to the right of Carol. Dave is next to Alice. Eve is at one end. Who is in the middle?",
    answers: ["Alice", "Bob", "Carol", "Dave"],
    correctAnswerIndex: 0,
    difficulty: 5,
    category: "logical",
    explanation: "Alice is not at an end and Dave is next to Alice. With the constraints, Alice must be in position 3 (middle).",
  },
  {
    question: "A tournament has 127 players in a single-elimination format. How many matches are needed to determine the winner?",
    answers: ["63", "64", "126", "127"],
    correctAnswerIndex: 2,
    difficulty: 5,
    category: "logical",
    explanation: "In single elimination, every player except the winner loses exactly once. 127 - 1 = 126 matches.",
  },
  {
    question: "There are 3 boxes: one has only apples, one has only oranges, and one has both. All labels are wrong. You pick one fruit from one box. What is the minimum number of picks to correctly label all boxes?",
    answers: ["1", "2", "3", "4"],
    correctAnswerIndex: 0,
    difficulty: 5,
    category: "logical",
    explanation: "Pick from the 'Mixed' labeled box (which is wrong, so it's either all apples or all oranges). If you get an apple, it's the apple box. The 'Oranges' labeled box can't be oranges (wrong label) and isn't apples, so it's mixed. The remaining is oranges.",
  },
  {
    question: "Two trains 200 km apart travel toward each other at 50 km/h each. A fly starts at one train and flies at 75 km/h back and forth until the trains meet. How far does the fly travel?",
    answers: ["100 km", "120 km", "150 km", "200 km"],
    correctAnswerIndex: 2,
    difficulty: 5,
    category: "logical",
    explanation: "Trains meet in 200/(50+50) = 2 hours. Fly travels 75 x 2 = 150 km total.",
  },
  {
    question: "You have 12 coins, one is counterfeit (heavier or lighter). Using a balance scale, what is the minimum number of weighings to identify the counterfeit and determine if it is heavier or lighter?",
    answers: ["2", "3", "4", "5"],
    correctAnswerIndex: 1,
    difficulty: 5,
    category: "logical",
    explanation: "With 3^n possible outcomes from n weighings, 3 weighings give 27 outcomes, enough for 24 possibilities (12 coins x 2 states). A known optimal algorithm solves this in 3.",
  },
  {
    question: "Three people check into a hotel room that costs $30, paying $10 each. The manager realizes the room is $25, gives $5 to the bellboy. The bellboy keeps $2 and returns $1 to each guest. Each guest paid $9 (total $27) plus $2 the bellboy kept = $29. Where is the missing dollar?",
    answers: [
      "The bellboy took it",
      "The manager has it",
      "There is no missing dollar -- the math is misleading",
      "It was lost in the transaction",
    ],
    correctAnswerIndex: 2,
    difficulty: 5,
    category: "logical",
    explanation: "The $27 paid by guests includes the $25 room + $2 bellboy tip. Adding the $2 again is double-counting. Correct: $25 (room) + $2 (bellboy) + $3 (returned) = $30.",
  },
  {
    question: "If you have a 3-liter jug and a 5-liter jug, how do you measure exactly 4 liters?",
    answers: [
      "Fill 5L, pour into 3L, empty 3L, pour remainder into 3L, fill 5L, pour into 3L",
      "Fill 3L twice into 5L, then fill 3L again",
      "It is impossible",
      "Fill 5L, pour half out",
    ],
    correctAnswerIndex: 0,
    difficulty: 5,
    category: "logical",
    explanation: "Fill 5L, pour into 3L (5L has 2L left). Empty 3L. Pour 2L into 3L. Fill 5L. Pour into 3L until full (pour 1L). 5L jug now has exactly 4L.",
  },
  {
    question: "A king wants to test 3 wise advisors. He puts a hat on each (from 5 hats: 3 white, 2 black) so each sees others but not their own. After a long pause, the wisest says 'My hat is white.' How did he know?",
    answers: [
      "He guessed",
      "He used elimination: if he had black, the second advisor would have known",
      "He counted the remaining hats",
      "The king told him",
    ],
    correctAnswerIndex: 1,
    difficulty: 5,
    category: "logical",
    explanation: "If #3 saw two black hats, he'd know his is white (only 2 black exist). He didn't speak. If #2 saw a black hat on #1, and #3 didn't speak, #2 would know he's white. #2 didn't speak either. So #1 deduced his hat must be white.",
  },

  // ═══════════════════════════════════════════════════════════════════════════
  // MATHEMATICAL ABILITY (40 questions)
  // ═══════════════════════════════════════════════════════════════════════════

  // Difficulty 1
  {
    question: "What is 15 + 27?",
    answers: ["32", "42", "52", "62"],
    correctAnswerIndex: 1,
    difficulty: 1,
    category: "math",
    explanation: "15 + 27 = 42.",
  },
  {
    question: "What is 8 x 7?",
    answers: ["54", "56", "58", "64"],
    correctAnswerIndex: 1,
    difficulty: 1,
    category: "math",
    explanation: "8 x 7 = 56.",
  },
  {
    question: "What is 100 - 37?",
    answers: ["53", "57", "63", "67"],
    correctAnswerIndex: 2,
    difficulty: 1,
    category: "math",
    explanation: "100 - 37 = 63.",
  },
  {
    question: "What is half of 64?",
    answers: ["22", "28", "32", "36"],
    correctAnswerIndex: 2,
    difficulty: 1,
    category: "math",
    explanation: "64 / 2 = 32.",
  },
  {
    question: "If you have 3 groups of 4 items, how many items total?",
    answers: ["7", "10", "12", "16"],
    correctAnswerIndex: 2,
    difficulty: 1,
    category: "math",
    explanation: "3 x 4 = 12 items.",
  },
  {
    question: "What is 25% of 80?",
    answers: ["15", "20", "25", "40"],
    correctAnswerIndex: 1,
    difficulty: 1,
    category: "math",
    explanation: "25% of 80 = 0.25 x 80 = 20.",
  },
  {
    question: "What is 144 / 12?",
    answers: ["10", "11", "12", "14"],
    correctAnswerIndex: 2,
    difficulty: 1,
    category: "math",
    explanation: "144 / 12 = 12.",
  },
  {
    question: "What is the square root of 49?",
    answers: ["5", "6", "7", "8"],
    correctAnswerIndex: 2,
    difficulty: 1,
    category: "math",
    explanation: "The square root of 49 is 7 because 7 x 7 = 49.",
  },

  // Difficulty 2
  {
    question: "If a shirt costs $45 and is on sale for 20% off, what is the sale price?",
    answers: ["$25", "$30", "$36", "$40"],
    correctAnswerIndex: 2,
    difficulty: 2,
    category: "math",
    explanation: "20% of $45 = $9. Sale price = $45 - $9 = $36.",
  },
  {
    question: "What is the value of 2^5?",
    answers: ["10", "16", "25", "32"],
    correctAnswerIndex: 3,
    difficulty: 2,
    category: "math",
    explanation: "2^5 = 2 x 2 x 2 x 2 x 2 = 32.",
  },
  {
    question: "A rectangle has a length of 8 and a width of 5. What is its area?",
    answers: ["13", "26", "30", "40"],
    correctAnswerIndex: 3,
    difficulty: 2,
    category: "math",
    explanation: "Area = length x width = 8 x 5 = 40.",
  },
  {
    question: "If x + 5 = 12, what is x?",
    answers: ["5", "7", "8", "17"],
    correctAnswerIndex: 1,
    difficulty: 2,
    category: "math",
    explanation: "x = 12 - 5 = 7.",
  },
  {
    question: "What is 3/4 as a decimal?",
    answers: ["0.25", "0.34", "0.5", "0.75"],
    correctAnswerIndex: 3,
    difficulty: 2,
    category: "math",
    explanation: "3/4 = 3 divided by 4 = 0.75.",
  },
  {
    question: "A train travels 120 km in 2 hours. What is its average speed?",
    answers: ["40 km/h", "50 km/h", "60 km/h", "80 km/h"],
    correctAnswerIndex: 2,
    difficulty: 2,
    category: "math",
    explanation: "Speed = distance / time = 120 / 2 = 60 km/h.",
  },
  {
    question: "What is the perimeter of a square with side length 9?",
    answers: ["18", "27", "36", "81"],
    correctAnswerIndex: 2,
    difficulty: 2,
    category: "math",
    explanation: "Perimeter of a square = 4 x side = 4 x 9 = 36.",
  },
  {
    question: "If you buy 3 items at $7.50 each, what is the total?",
    answers: ["$15.00", "$21.50", "$22.50", "$25.00"],
    correctAnswerIndex: 2,
    difficulty: 2,
    category: "math",
    explanation: "3 x $7.50 = $22.50.",
  },

  // Difficulty 3
  {
    question: "What is 17% of 300?",
    answers: ["34", "41", "51", "57"],
    correctAnswerIndex: 2,
    difficulty: 3,
    category: "math",
    explanation: "17% of 300 = 0.17 x 300 = 51.",
  },
  {
    question: "Solve: 3x - 7 = 20",
    answers: ["7", "9", "11", "13"],
    correctAnswerIndex: 1,
    difficulty: 3,
    category: "math",
    explanation: "3x = 27, x = 9.",
  },
  {
    question: "A circle has a radius of 7. What is its area? (Use pi = 22/7)",
    answers: ["44", "88", "154", "308"],
    correctAnswerIndex: 2,
    difficulty: 3,
    category: "math",
    explanation: "Area = pi x r^2 = (22/7) x 49 = 22 x 7 = 154.",
  },
  {
    question: "If a number is increased by 30% and becomes 91, what was the original number?",
    answers: ["60", "65", "70", "75"],
    correctAnswerIndex: 2,
    difficulty: 3,
    category: "math",
    explanation: "Original x 1.30 = 91. Original = 91 / 1.30 = 70.",
  },
  {
    question: "What is the sum of the interior angles of a pentagon?",
    answers: ["360", "450", "540", "720"],
    correctAnswerIndex: 2,
    difficulty: 3,
    category: "math",
    explanation: "Sum = (n-2) x 180 = (5-2) x 180 = 540 degrees.",
  },
  {
    question: "If the ratio of boys to girls in a class is 3:5 and there are 40 students, how many boys are there?",
    answers: ["12", "15", "18", "24"],
    correctAnswerIndex: 1,
    difficulty: 3,
    category: "math",
    explanation: "Total parts = 3 + 5 = 8. Boys = (3/8) x 40 = 15.",
  },
  {
    question: "What is the least common multiple (LCM) of 12 and 18?",
    answers: ["24", "36", "48", "72"],
    correctAnswerIndex: 1,
    difficulty: 3,
    category: "math",
    explanation: "12 = 2^2 x 3, 18 = 2 x 3^2. LCM = 2^2 x 3^2 = 36.",
  },
  {
    question: "A car depreciates 15% per year. If it costs $20,000 now, what is it worth after 1 year?",
    answers: ["$15,000", "$17,000", "$17,500", "$18,000"],
    correctAnswerIndex: 1,
    difficulty: 3,
    category: "math",
    explanation: "$20,000 x 0.85 = $17,000.",
  },

  // Difficulty 4
  {
    question: "What is the value of log base 2 of 128?",
    answers: ["5", "6", "7", "8"],
    correctAnswerIndex: 2,
    difficulty: 4,
    category: "math",
    explanation: "2^7 = 128, so log_2(128) = 7.",
  },
  {
    question: "If f(x) = 2x^2 - 3x + 1, what is f(3)?",
    answers: ["4", "8", "10", "12"],
    correctAnswerIndex: 2,
    difficulty: 4,
    category: "math",
    explanation: "f(3) = 2(9) - 3(3) + 1 = 18 - 9 + 1 = 10.",
  },
  {
    question: "How many ways can you arrange the letters in the word 'MATH'?",
    answers: ["4", "12", "16", "24"],
    correctAnswerIndex: 3,
    difficulty: 4,
    category: "math",
    explanation: "4! = 4 x 3 x 2 x 1 = 24 arrangements.",
  },
  {
    question: "What is the probability of rolling a sum of 7 with two standard dice?",
    answers: ["1/6", "5/36", "1/9", "7/36"],
    correctAnswerIndex: 0,
    difficulty: 4,
    category: "math",
    explanation: "There are 6 combinations that sum to 7 out of 36 total outcomes: (1,6), (2,5), (3,4), (4,3), (5,2), (6,1). 6/36 = 1/6.",
  },
  {
    question: "A triangle has sides of length 5, 12, and 13. What is its area?",
    answers: ["24", "30", "32.5", "60"],
    correctAnswerIndex: 1,
    difficulty: 4,
    category: "math",
    explanation: "This is a right triangle (5^2 + 12^2 = 13^2). Area = (1/2)(5)(12) = 30.",
  },
  {
    question: "Solve: x^2 - 5x + 6 = 0",
    answers: ["x = 1, x = 6", "x = 2, x = 3", "x = -2, x = -3", "x = -1, x = 6"],
    correctAnswerIndex: 1,
    difficulty: 4,
    category: "math",
    explanation: "Factor: (x-2)(x-3) = 0. So x = 2 or x = 3.",
  },
  {
    question: "What is the sum of the first 20 positive integers?",
    answers: ["180", "190", "200", "210"],
    correctAnswerIndex: 3,
    difficulty: 4,
    category: "math",
    explanation: "Sum = n(n+1)/2 = 20(21)/2 = 210.",
  },
  {
    question: "A cone has radius 3 and height 4. What is its volume? (Use pi = 3.14)",
    answers: ["28.26", "37.68", "56.52", "113.04"],
    correctAnswerIndex: 1,
    difficulty: 4,
    category: "math",
    explanation: "V = (1/3) x pi x r^2 x h = (1/3) x 3.14 x 9 x 4 = 37.68.",
  },

  // Difficulty 5
  {
    question: "What is the derivative of f(x) = 3x^4 - 2x^2 + 5x?",
    answers: [
      "12x^3 - 4x + 5",
      "12x^3 - 2x + 5",
      "3x^3 - 4x + 5",
      "12x^4 - 4x + 5",
    ],
    correctAnswerIndex: 0,
    difficulty: 5,
    category: "math",
    explanation: "f'(x) = 12x^3 - 4x + 5 (power rule: nx^(n-1)).",
  },
  {
    question: "How many distinct handshakes occur when 10 people all shake hands with each other?",
    answers: ["20", "45", "90", "100"],
    correctAnswerIndex: 1,
    difficulty: 5,
    category: "math",
    explanation: "C(10,2) = 10!/(2! x 8!) = 45 handshakes.",
  },
  {
    question: "What is the integral of 2x dx from 0 to 3?",
    answers: ["3", "6", "9", "12"],
    correctAnswerIndex: 2,
    difficulty: 5,
    category: "math",
    explanation: "Integral of 2x = x^2. Evaluate from 0 to 3: 3^2 - 0^2 = 9.",
  },
  {
    question: "In a geometric sequence, the first term is 5 and the common ratio is 3. What is the 5th term?",
    answers: ["135", "405", "1215", "3645"],
    correctAnswerIndex: 1,
    difficulty: 5,
    category: "math",
    explanation: "a_n = a_1 x r^(n-1). a_5 = 5 x 3^4 = 5 x 81 = 405.",
  },
  {
    question: "What is the determinant of the matrix [[2, 3], [1, 4]]?",
    answers: ["2", "5", "8", "11"],
    correctAnswerIndex: 1,
    difficulty: 5,
    category: "math",
    explanation: "det = ad - bc = (2)(4) - (3)(1) = 8 - 3 = 5.",
  },
  {
    question: "If sin(x) = 3/5 and x is in the first quadrant, what is cos(x)?",
    answers: ["3/5", "4/5", "5/3", "5/4"],
    correctAnswerIndex: 1,
    difficulty: 5,
    category: "math",
    explanation: "Using Pythagorean identity: cos^2(x) = 1 - sin^2(x) = 1 - 9/25 = 16/25. cos(x) = 4/5.",
  },
  {
    question: "A committee of 3 is chosen from 8 people. If 2 specific people cannot both be on the committee, how many valid committees are there?",
    answers: ["36", "42", "50", "56"],
    correctAnswerIndex: 2,
    difficulty: 5,
    category: "math",
    explanation: "Total committees = C(8,3) = 56. Committees with both excluded people = C(6,1) = 6. Valid = 56 - 6 = 50.",
  },
  {
    question: "What is the sum of the infinite geometric series: 1 + 1/2 + 1/4 + 1/8 + ...?",
    answers: ["1.5", "2", "2.5", "Infinity"],
    correctAnswerIndex: 1,
    difficulty: 5,
    category: "math",
    explanation: "Sum = a / (1 - r) = 1 / (1 - 0.5) = 1 / 0.5 = 2.",
  },

  // ═══════════════════════════════════════════════════════════════════════════
  // VERBAL INTELLIGENCE (40 questions)
  // ═══════════════════════════════════════════════════════════════════════════

  // Difficulty 1
  {
    question: "Which word means the opposite of 'hot'?",
    answers: ["Warm", "Cold", "Spicy", "Bright"],
    correctAnswerIndex: 1,
    difficulty: 1,
    category: "verbal",
    explanation: "'Cold' is the antonym of 'hot'.",
  },
  {
    question: "Which word means the same as 'happy'?",
    answers: ["Sad", "Angry", "Joyful", "Tired"],
    correctAnswerIndex: 2,
    difficulty: 1,
    category: "verbal",
    explanation: "'Joyful' is a synonym of 'happy'.",
  },
  {
    question: "Dog is to puppy as cat is to:",
    answers: ["Cub", "Kitten", "Foal", "Chick"],
    correctAnswerIndex: 1,
    difficulty: 1,
    category: "verbal",
    explanation: "A puppy is a young dog; a kitten is a young cat.",
  },
  {
    question: "Which word does NOT belong: Run, Walk, Sit, Jog?",
    answers: ["Run", "Walk", "Sit", "Jog"],
    correctAnswerIndex: 2,
    difficulty: 1,
    category: "verbal",
    explanation: "Run, walk, and jog all involve moving. Sit does not.",
  },
  {
    question: "What is the plural of 'child'?",
    answers: ["Childs", "Children", "Childes", "Childrens"],
    correctAnswerIndex: 1,
    difficulty: 1,
    category: "verbal",
    explanation: "'Children' is the correct irregular plural of 'child'.",
  },
  {
    question: "Choose the correctly spelled word:",
    answers: ["Recieve", "Receive", "Receeve", "Receve"],
    correctAnswerIndex: 1,
    difficulty: 1,
    category: "verbal",
    explanation: "The correct spelling is 'receive' (i before e except after c).",
  },
  {
    question: "Author is to book as painter is to:",
    answers: ["Brush", "Canvas", "Painting", "Color"],
    correctAnswerIndex: 2,
    difficulty: 1,
    category: "verbal",
    explanation: "An author creates a book; a painter creates a painting.",
  },
  {
    question: "Which word means 'very large'?",
    answers: ["Tiny", "Enormous", "Average", "Quick"],
    correctAnswerIndex: 1,
    difficulty: 1,
    category: "verbal",
    explanation: "'Enormous' means extremely large in size.",
  },

  // Difficulty 2
  {
    question: "What does the word 'benevolent' mean?",
    answers: ["Cruel", "Kind and generous", "Intelligent", "Wealthy"],
    correctAnswerIndex: 1,
    difficulty: 2,
    category: "verbal",
    explanation: "'Benevolent' means well-meaning, kind, and charitable.",
  },
  {
    question: "Choose the word that best completes the analogy: Glove is to hand as shoe is to:",
    answers: ["Sock", "Foot", "Leg", "Boot"],
    correctAnswerIndex: 1,
    difficulty: 2,
    category: "verbal",
    explanation: "A glove covers a hand; a shoe covers a foot.",
  },
  {
    question: "Which word is most similar to 'diligent'?",
    answers: ["Lazy", "Hardworking", "Clever", "Lucky"],
    correctAnswerIndex: 1,
    difficulty: 2,
    category: "verbal",
    explanation: "'Diligent' means showing careful and persistent effort, similar to 'hardworking'.",
  },
  {
    question: "What is the opposite of 'transparent'?",
    answers: ["Clear", "Opaque", "Visible", "Bright"],
    correctAnswerIndex: 1,
    difficulty: 2,
    category: "verbal",
    explanation: "'Opaque' means not able to be seen through, the opposite of 'transparent'.",
  },
  {
    question: "Choose the correct word: 'The team _____ their victory.'",
    answers: ["Celebrated", "Celebrationed", "Celebrious", "Celebrant"],
    correctAnswerIndex: 0,
    difficulty: 2,
    category: "verbal",
    explanation: "'Celebrated' is the correct past tense form of 'celebrate'.",
  },
  {
    question: "Which pair of words are antonyms?",
    answers: [
      "Begin / Start",
      "Accept / Reject",
      "Run / Sprint",
      "Big / Large",
    ],
    correctAnswerIndex: 1,
    difficulty: 2,
    category: "verbal",
    explanation: "'Accept' and 'reject' have opposite meanings. The other pairs are synonyms.",
  },
  {
    question: "Doctor is to hospital as teacher is to:",
    answers: ["Book", "Student", "School", "Education"],
    correctAnswerIndex: 2,
    difficulty: 2,
    category: "verbal",
    explanation: "A doctor works in a hospital; a teacher works in a school.",
  },
  {
    question: "What does the prefix 'un-' mean in the word 'unhappy'?",
    answers: ["Very", "Not", "Again", "Before"],
    correctAnswerIndex: 1,
    difficulty: 2,
    category: "verbal",
    explanation: "The prefix 'un-' means 'not'. Unhappy means not happy.",
  },

  // Difficulty 3
  {
    question: "What does 'ubiquitous' mean?",
    answers: [
      "Extremely rare",
      "Found everywhere",
      "Very beautiful",
      "Highly dangerous",
    ],
    correctAnswerIndex: 1,
    difficulty: 3,
    category: "verbal",
    explanation: "'Ubiquitous' means present, appearing, or found everywhere.",
  },
  {
    question: "Choose the word that best completes: 'The politician's speech was so _____ that even experts couldn't find any flaws.'",
    answers: ["Verbose", "Cogent", "Ambiguous", "Redundant"],
    correctAnswerIndex: 1,
    difficulty: 3,
    category: "verbal",
    explanation: "'Cogent' means clear, logical, and convincing.",
  },
  {
    question: "Which word is an antonym of 'ephemeral'?",
    answers: ["Brief", "Permanent", "Fleeting", "Temporary"],
    correctAnswerIndex: 1,
    difficulty: 3,
    category: "verbal",
    explanation: "'Ephemeral' means lasting a very short time. 'Permanent' is its antonym.",
  },
  {
    question: "Scalpel is to surgeon as gavel is to:",
    answers: ["Carpenter", "Judge", "Teacher", "Chef"],
    correctAnswerIndex: 1,
    difficulty: 3,
    category: "verbal",
    explanation: "A surgeon uses a scalpel; a judge uses a gavel.",
  },
  {
    question: "What does 'pragmatic' mean?",
    answers: [
      "Idealistic and dreamy",
      "Dealing with things practically",
      "Relating to grammar",
      "Extremely dramatic",
    ],
    correctAnswerIndex: 1,
    difficulty: 3,
    category: "verbal",
    explanation: "'Pragmatic' means dealing with things sensibly and realistically.",
  },
  {
    question: "Which sentence uses 'affect' correctly?",
    answers: [
      "The affect of the storm was devastating",
      "The storm will affect the entire region",
      "She showed no affect during the presentation",
      "Both B and C",
    ],
    correctAnswerIndex: 3,
    difficulty: 3,
    category: "verbal",
    explanation: "'Affect' as a verb means to influence (B). As a noun in psychology, it means emotional response (C). Both are correct.",
  },
  {
    question: "What does 'ameliorate' mean?",
    answers: [
      "To make worse",
      "To make better",
      "To remove completely",
      "To combine together",
    ],
    correctAnswerIndex: 1,
    difficulty: 3,
    category: "verbal",
    explanation: "'Ameliorate' means to make something better or to improve it.",
  },
  {
    question: "Dormant is to active as:",
    answers: [
      "Visible is to seen",
      "Stagnant is to flowing",
      "Warm is to hot",
      "Large is to big",
    ],
    correctAnswerIndex: 1,
    difficulty: 3,
    category: "verbal",
    explanation: "Dormant and active are antonyms, as are stagnant and flowing.",
  },

  // Difficulty 4
  {
    question: "What does 'obsequious' mean?",
    answers: [
      "Objecting to authority",
      "Excessively compliant or obedient",
      "Observant and alert",
      "Obscure and hidden",
    ],
    correctAnswerIndex: 1,
    difficulty: 4,
    category: "verbal",
    explanation: "'Obsequious' means excessively eager to please or serve.",
  },
  {
    question: "Choose the correct analogy: Taciturn is to talkative as:",
    answers: [
      "Bold is to courageous",
      "Frugal is to extravagant",
      "Quick is to fast",
      "Gentle is to soft",
    ],
    correctAnswerIndex: 1,
    difficulty: 4,
    category: "verbal",
    explanation: "Taciturn (reserved) is the opposite of talkative, just as frugal is the opposite of extravagant.",
  },
  {
    question: "What does 'recalcitrant' mean?",
    answers: [
      "Easily persuaded",
      "Stubbornly resistant to authority",
      "Quick to calculate",
      "Prone to recurrence",
    ],
    correctAnswerIndex: 1,
    difficulty: 4,
    category: "verbal",
    explanation: "'Recalcitrant' means having an obstinately uncooperative attitude.",
  },
  {
    question: "Which word best describes someone who speaks in a pompous, dogmatic way?",
    answers: ["Laconic", "Pontifical", "Taciturn", "Reticent"],
    correctAnswerIndex: 1,
    difficulty: 4,
    category: "verbal",
    explanation: "'Pontifical' means pompously dogmatic or characterized by a pompous manner.",
  },
  {
    question: "'The writer's _____ prose style made even simple ideas incomprehensible.' Choose the best word:",
    answers: ["Lucid", "Turgid", "Succinct", "Pellucid"],
    correctAnswerIndex: 1,
    difficulty: 4,
    category: "verbal",
    explanation: "'Turgid' means swollen, inflated, or (of writing) pompous and hard to understand.",
  },
  {
    question: "What is the meaning of 'perspicacious'?",
    answers: [
      "Sweating profusely",
      "Having keen mental perception",
      "Clear and transparent",
      "Prone to perspiring",
    ],
    correctAnswerIndex: 1,
    difficulty: 4,
    category: "verbal",
    explanation: "'Perspicacious' means having a ready insight into and understanding of things.",
  },
  {
    question: "Choose the correct meaning of 'enervate':",
    answers: [
      "To energize and excite",
      "To weaken and drain of energy",
      "To innervate with nerves",
      "To increase nervousness",
    ],
    correctAnswerIndex: 1,
    difficulty: 4,
    category: "verbal",
    explanation: "Despite sounding like 'energize', 'enervate' means to weaken or drain of energy.",
  },
  {
    question: "Apotheosis is to nadir as:",
    answers: [
      "Peak is to valley",
      "Beginning is to end",
      "Cause is to effect",
      "Theory is to practice",
    ],
    correctAnswerIndex: 0,
    difficulty: 4,
    category: "verbal",
    explanation: "Apotheosis (highest point) is to nadir (lowest point) as peak is to valley.",
  },

  // Difficulty 5
  {
    question: "What does 'sesquipedalian' mean?",
    answers: [
      "Having 150 sides",
      "Characterized by long words",
      "Occurring every 150 years",
      "Having six feet",
    ],
    correctAnswerIndex: 1,
    difficulty: 5,
    category: "verbal",
    explanation: "'Sesquipedalian' literally means 'a foot and a half long' and refers to the use of long words.",
  },
  {
    question: "Choose the word that means 'a departure from the main topic':",
    answers: ["Tangent", "Peregrination", "Excursion", "Digression"],
    correctAnswerIndex: 3,
    difficulty: 5,
    category: "verbal",
    explanation: "'Digression' specifically means a departure from the main subject in speech or writing.",
  },
  {
    question: "What is the meaning of 'defenestration'?",
    answers: [
      "The act of defending a fence",
      "The act of throwing someone out of a window",
      "The removal of a forest",
      "The act of defining boundaries",
    ],
    correctAnswerIndex: 1,
    difficulty: 5,
    category: "verbal",
    explanation: "'Defenestration' literally means throwing someone out of a window (from Latin 'fenestra' = window).",
  },
  {
    question: "Which word means 'pleasantly sharp or pungent in taste'?",
    answers: ["Piquant", "Petulant", "Poignant", "Pedantic"],
    correctAnswerIndex: 0,
    difficulty: 5,
    category: "verbal",
    explanation: "'Piquant' means having a pleasantly sharp taste or appetizingly stimulating.",
  },
  {
    question: "'Her _____ remarks belied the deep passion she felt for the cause.' Choose the best word:",
    answers: ["Effusive", "Phlegmatic", "Vociferous", "Impassioned"],
    correctAnswerIndex: 1,
    difficulty: 5,
    category: "verbal",
    explanation: "'Phlegmatic' means calm and unemotional, which would contrast with ('belie') deep passion.",
  },
  {
    question: "What does 'pulchritudinous' mean?",
    answers: [
      "Extremely ugly",
      "Physically beautiful",
      "Morally corrupt",
      "Intellectually gifted",
    ],
    correctAnswerIndex: 1,
    difficulty: 5,
    category: "verbal",
    explanation: "'Pulchritudinous' means beautiful in appearance, despite its harsh-sounding pronunciation.",
  },
  {
    question: "Choose the correct meaning of 'antediluvian':",
    answers: [
      "Against flooding",
      "Extremely old-fashioned or outdated",
      "Before the introduction of medicine",
      "Opposed to dilution",
    ],
    correctAnswerIndex: 1,
    difficulty: 5,
    category: "verbal",
    explanation: "'Antediluvian' literally means 'before the flood' (Biblical) and figuratively means extremely old or outdated.",
  },
  {
    question: "What is the meaning of 'sycophantic'?",
    answers: [
      "Relating to elephants",
      "Behaving in a servile, flattering manner",
      "Producing musical sounds",
      "Having multiple meanings",
    ],
    correctAnswerIndex: 1,
    difficulty: 5,
    category: "verbal",
    explanation: "'Sycophantic' describes someone who acts in an excessively flattering way to gain advantage.",
  },

  // ═══════════════════════════════════════════════════════════════════════════
  // SPATIAL REASONING (40 questions)
  // ═══════════════════════════════════════════════════════════════════════════

  // Difficulty 1
  {
    question: "If you rotate the letter 'N' 180 degrees, what does it look like?",
    answers: ["N", "Z", "U", "N (same)"],
    correctAnswerIndex: 0,
    difficulty: 1,
    category: "spatial",
    explanation: "Rotating 'N' 180 degrees produces the same letter 'N' (it has rotational symmetry).",
  },
  {
    question: "How many sides does a hexagon have?",
    answers: ["4", "5", "6", "8"],
    correctAnswerIndex: 2,
    difficulty: 1,
    category: "spatial",
    explanation: "A hexagon has 6 sides. The prefix 'hex-' means six.",
  },
  {
    question: "Which shape has no straight edges?",
    answers: ["Square", "Triangle", "Circle", "Rectangle"],
    correctAnswerIndex: 2,
    difficulty: 1,
    category: "spatial",
    explanation: "A circle has no straight edges; it is a continuous curve.",
  },
  {
    question: "If you fold a square piece of paper diagonally, what shape do you get?",
    answers: ["Rectangle", "Triangle", "Pentagon", "Smaller square"],
    correctAnswerIndex: 1,
    difficulty: 1,
    category: "spatial",
    explanation: "Folding a square along its diagonal creates a triangle.",
  },
  {
    question: "Which direction is opposite to North?",
    answers: ["East", "West", "South", "Northeast"],
    correctAnswerIndex: 2,
    difficulty: 1,
    category: "spatial",
    explanation: "South is directly opposite to North on a compass.",
  },
  {
    question: "How many faces does a cube have?",
    answers: ["4", "6", "8", "12"],
    correctAnswerIndex: 1,
    difficulty: 1,
    category: "spatial",
    explanation: "A cube has 6 faces (top, bottom, front, back, left, right).",
  },
  {
    question: "If you look in a mirror, which hand appears to be raised if you raise your left hand?",
    answers: ["Left", "Right", "Both", "Neither"],
    correctAnswerIndex: 1,
    difficulty: 1,
    category: "spatial",
    explanation: "A mirror reverses left and right. Your left hand appears as the right hand in the reflection.",
  },
  {
    question: "What 3D shape does a can of soup resemble?",
    answers: ["Sphere", "Cube", "Cylinder", "Cone"],
    correctAnswerIndex: 2,
    difficulty: 1,
    category: "spatial",
    explanation: "A soup can is shaped like a cylinder -- a circular base with straight sides.",
  },

  // Difficulty 2
  {
    question: "If you unfold a cube, how many squares do you see?",
    answers: ["4", "5", "6", "8"],
    correctAnswerIndex: 2,
    difficulty: 2,
    category: "spatial",
    explanation: "A cube has 6 faces. Unfolding it reveals 6 connected squares (a net).",
  },
  {
    question: "Which shape has the most lines of symmetry?",
    answers: ["Equilateral triangle", "Square", "Regular pentagon", "Circle"],
    correctAnswerIndex: 3,
    difficulty: 2,
    category: "spatial",
    explanation: "A circle has infinite lines of symmetry -- any diameter is a line of symmetry.",
  },
  {
    question: "If a clock shows 9:00 and you rotate it 90 degrees clockwise, what time does it appear to show?",
    answers: ["12:00", "6:00", "3:00", "12:15"],
    correctAnswerIndex: 0,
    difficulty: 2,
    category: "spatial",
    explanation: "Rotating 90 degrees clockwise moves the 9 o'clock position to where 12 should be.",
  },
  {
    question: "How many edges does a rectangular prism (box) have?",
    answers: ["8", "10", "12", "14"],
    correctAnswerIndex: 2,
    difficulty: 2,
    category: "spatial",
    explanation: "A rectangular prism has 12 edges: 4 on top, 4 on bottom, and 4 vertical.",
  },
  {
    question: "If you cut a cone horizontally (parallel to the base), what shape is the cross-section?",
    answers: ["Triangle", "Circle", "Oval", "Rectangle"],
    correctAnswerIndex: 1,
    difficulty: 2,
    category: "spatial",
    explanation: "A horizontal cross-section of a cone is always a circle.",
  },
  {
    question: "Which of these is NOT a net of a cube?",
    answers: [
      "T-shape with 6 squares",
      "Cross shape with 6 squares",
      "L-shape with 6 squares in a row",
      "Straight line of 4 squares with 1 on each side",
    ],
    correctAnswerIndex: 2,
    difficulty: 2,
    category: "spatial",
    explanation: "6 squares in an L-shaped row cannot fold into a cube. Squares in a straight line of more than 4 will overlap.",
  },
  {
    question: "How many vertices does a triangular pyramid (tetrahedron) have?",
    answers: ["3", "4", "5", "6"],
    correctAnswerIndex: 1,
    difficulty: 2,
    category: "spatial",
    explanation: "A tetrahedron has 4 vertices (3 at the base + 1 at the apex).",
  },
  {
    question: "If you look at a building from the top, this is called a:",
    answers: ["Elevation view", "Plan view", "Perspective view", "Cross-section"],
    correctAnswerIndex: 1,
    difficulty: 2,
    category: "spatial",
    explanation: "A view from directly above is called a plan view (or bird's-eye view).",
  },

  // Difficulty 3
  {
    question: "How many small cubes are in a 3x3x3 Rubik's Cube?",
    answers: ["9", "18", "26", "27"],
    correctAnswerIndex: 3,
    difficulty: 3,
    category: "spatial",
    explanation: "A 3x3x3 cube contains 3 x 3 x 3 = 27 small cubes.",
  },
  {
    question: "If you rotate a 2D right triangle 360 degrees around one of its legs, what 3D shape do you get?",
    answers: ["Cylinder", "Cone", "Sphere", "Pyramid"],
    correctAnswerIndex: 1,
    difficulty: 3,
    category: "spatial",
    explanation: "Rotating a right triangle around one leg sweeps out a cone shape.",
  },
  {
    question: "A cube is painted red on all faces and then cut into 27 smaller cubes. How many small cubes have exactly 2 red faces?",
    answers: ["6", "8", "12", "16"],
    correctAnswerIndex: 2,
    difficulty: 3,
    category: "spatial",
    explanation: "Edge cubes (not corners) have 2 painted faces. A cube has 12 edges, each with 1 edge cube in a 3x3x3 = 12.",
  },
  {
    question: "What is the maximum number of pieces you can get by making 3 straight cuts through a circle?",
    answers: ["4", "6", "7", "8"],
    correctAnswerIndex: 2,
    difficulty: 3,
    category: "spatial",
    explanation: "With 3 non-parallel, non-concurrent cuts through a circle, maximum pieces = 7.",
  },
  {
    question: "If a regular octahedron has 8 faces, how many vertices does it have?",
    answers: ["4", "6", "8", "12"],
    correctAnswerIndex: 1,
    difficulty: 3,
    category: "spatial",
    explanation: "A regular octahedron has 6 vertices, 12 edges, and 8 triangular faces.",
  },
  {
    question: "How many diagonals does a hexagon have?",
    answers: ["6", "8", "9", "12"],
    correctAnswerIndex: 2,
    difficulty: 3,
    category: "spatial",
    explanation: "Diagonals = n(n-3)/2 = 6(3)/2 = 9 for a hexagon.",
  },
  {
    question: "If you look at a cylinder from directly above, what shape do you see?",
    answers: ["Rectangle", "Circle", "Oval", "Square"],
    correctAnswerIndex: 1,
    difficulty: 3,
    category: "spatial",
    explanation: "The top view (plan view) of a cylinder is a circle.",
  },
  {
    question: "Two identical cubes are glued face-to-face. How many faces does the resulting shape have?",
    answers: ["8", "10", "12", "14"],
    correctAnswerIndex: 1,
    difficulty: 3,
    category: "spatial",
    explanation: "Each cube has 6 faces. Gluing removes 2 faces (1 from each). Total = 12 - 2 = 10 faces.",
  },

  // Difficulty 4
  {
    question: "A 4x4x4 cube is painted on all sides and cut into 64 unit cubes. How many have NO paint?",
    answers: ["0", "4", "8", "16"],
    correctAnswerIndex: 2,
    difficulty: 4,
    category: "spatial",
    explanation: "Interior cubes have no paint. Interior is 2x2x2 = 8 cubes.",
  },
  {
    question: "How many planes of symmetry does a regular tetrahedron have?",
    answers: ["3", "4", "6", "12"],
    correctAnswerIndex: 2,
    difficulty: 4,
    category: "spatial",
    explanation: "A regular tetrahedron has 6 planes of symmetry, each passing through one edge and the midpoint of the opposite edge.",
  },
  {
    question: "If you connect all vertices of a regular hexagon to the center, how many triangles are formed?",
    answers: ["3", "4", "6", "12"],
    correctAnswerIndex: 2,
    difficulty: 4,
    category: "spatial",
    explanation: "Connecting all 6 vertices to the center creates 6 equilateral triangles.",
  },
  {
    question: "A right circular cone is cut by a plane that passes through the apex and the base. What is the cross-section?",
    answers: ["Circle", "Triangle", "Parabola", "Ellipse"],
    correctAnswerIndex: 1,
    difficulty: 4,
    category: "spatial",
    explanation: "A plane through the apex and cutting through the base creates a triangular cross-section.",
  },
  {
    question: "An icosahedron has 20 faces. How many edges does it have?",
    answers: ["12", "20", "30", "40"],
    correctAnswerIndex: 2,
    difficulty: 4,
    category: "spatial",
    explanation: "By Euler's formula: V - E + F = 2. Icosahedron: 12 - E + 20 = 2, so E = 30.",
  },
  {
    question: "A 3D shape has 5 faces, 8 edges, and 5 vertices. What is it?",
    answers: [
      "Triangular prism",
      "Square pyramid",
      "Pentagonal prism",
      "Rectangular pyramid",
    ],
    correctAnswerIndex: 1,
    difficulty: 4,
    category: "spatial",
    explanation: "A square pyramid has 5 faces (4 triangles + 1 square base), 8 edges, and 5 vertices.",
  },
  {
    question: "If you slice a torus (donut) with a vertical plane through its center, what shape is the cross-section?",
    answers: [
      "One circle",
      "Two circles",
      "An oval",
      "A figure-eight",
    ],
    correctAnswerIndex: 1,
    difficulty: 4,
    category: "spatial",
    explanation: "A vertical cut through the center of a torus produces two separate circles.",
  },
  {
    question: "How many unit cubes are visible on the outside of a 5x5x5 cube?",
    answers: ["98", "117", "125", "150"],
    correctAnswerIndex: 0,
    difficulty: 4,
    category: "spatial",
    explanation: "Total cubes = 125. Interior cubes = 3x3x3 = 27. Visible = 125 - 27 = 98.",
  },

  // Difficulty 5
  {
    question: "A dodecahedron has 12 pentagonal faces. How many vertices does it have?",
    answers: ["12", "16", "20", "30"],
    correctAnswerIndex: 2,
    difficulty: 5,
    category: "spatial",
    explanation: "A dodecahedron has 20 vertices, 30 edges, and 12 faces. (Euler: 20 - 30 + 12 = 2).",
  },
  {
    question: "What is the fourth spatial dimension analogue of a cube called?",
    answers: ["Hypercube", "Tesseract", "Both A and B", "Hexeract"],
    correctAnswerIndex: 2,
    difficulty: 5,
    category: "spatial",
    explanation: "A 4D cube is called both a 'hypercube' and a 'tesseract'. Both terms are correct.",
  },
  {
    question: "How many edges does a tesseract (4D hypercube) have?",
    answers: ["16", "24", "32", "48"],
    correctAnswerIndex: 2,
    difficulty: 5,
    category: "spatial",
    explanation: "A tesseract has 16 vertices, 32 edges, 24 square faces, and 8 cubic cells.",
  },
  {
    question: "If you project a 3D cube onto a 2D surface along its body diagonal, what shape do you see?",
    answers: ["Square", "Regular hexagon", "Rectangle", "Octagon"],
    correctAnswerIndex: 1,
    difficulty: 5,
    category: "spatial",
    explanation: "Projecting a cube along its body diagonal onto a perpendicular plane gives a regular hexagon.",
  },
  {
    question: "A 10x10x10 cube is painted on all faces. How many unit cubes have exactly 1 painted face?",
    answers: ["384", "386", "488", "600"],
    correctAnswerIndex: 0,
    difficulty: 5,
    category: "spatial",
    explanation: "Face-center cubes (not on edges): 6 faces x (10-2)^2 = 6 x 64 = 384.",
  },
  {
    question: "How many distinct nets can a cube have (excluding rotations and reflections)?",
    answers: ["6", "8", "11", "16"],
    correctAnswerIndex: 2,
    difficulty: 5,
    category: "spatial",
    explanation: "A cube has exactly 11 distinct nets (proven by exhaustive enumeration).",
  },
  {
    question: "In topology, a Mobius strip has how many surfaces?",
    answers: ["0", "1", "2", "3"],
    correctAnswerIndex: 1,
    difficulty: 5,
    category: "spatial",
    explanation: "A Mobius strip is a non-orientable surface with only 1 side and 1 boundary curve.",
  },
  {
    question: "What is the Euler characteristic (V - E + F) for any convex polyhedron?",
    answers: ["0", "1", "2", "3"],
    correctAnswerIndex: 2,
    difficulty: 5,
    category: "spatial",
    explanation: "Euler's formula states V - E + F = 2 for any convex polyhedron.",
  },
];

// ─────────────────────────────────────────────────────────────────────────────
// EQ Statements (80+ across 5 categories)
// ─────────────────────────────────────────────────────────────────────────────

const EQ_STATEMENTS = [
  // ═══════════════════════════════════════════════════════════════════════════
  // SELF-AWARENESS (16 statements)
  // ═══════════════════════════════════════════════════════════════════════════
  {
    statement: "I can accurately identify what I am feeling at any given moment.",
    category: "selfAwareness",
    isReversed: false,
    weight: 1.0,
  },
  {
    statement: "I understand how my emotions influence my decisions.",
    category: "selfAwareness",
    isReversed: false,
    weight: 1.0,
  },
  {
    statement: "I am aware of my strengths and weaknesses.",
    category: "selfAwareness",
    isReversed: false,
    weight: 1.0,
  },
  {
    statement: "I often act without understanding why I feel a certain way.",
    category: "selfAwareness",
    isReversed: true,
    weight: 1.0,
  },
  {
    statement: "I can tell when my mood is about to change.",
    category: "selfAwareness",
    isReversed: false,
    weight: 1.0,
  },
  {
    statement: "I find it difficult to describe my feelings to others.",
    category: "selfAwareness",
    isReversed: true,
    weight: 1.0,
  },
  {
    statement: "I recognize how my behavior affects the people around me.",
    category: "selfAwareness",
    isReversed: false,
    weight: 1.0,
  },
  {
    statement: "I regularly reflect on what matters most to me in life.",
    category: "selfAwareness",
    isReversed: false,
    weight: 1.0,
  },
  {
    statement: "I am confident in my abilities even when facing challenges.",
    category: "selfAwareness",
    isReversed: false,
    weight: 1.0,
  },
  {
    statement: "I have a hard time recognizing when I am stressed.",
    category: "selfAwareness",
    isReversed: true,
    weight: 1.0,
  },
  {
    statement: "I know what triggers my strongest emotional reactions.",
    category: "selfAwareness",
    isReversed: false,
    weight: 1.2,
  },
  {
    statement: "I can separate my feelings from my thoughts in difficult situations.",
    category: "selfAwareness",
    isReversed: false,
    weight: 1.2,
  },
  {
    statement: "I am often surprised by my own emotional reactions.",
    category: "selfAwareness",
    isReversed: true,
    weight: 1.0,
  },
  {
    statement: "I understand how my past experiences shape my current emotions.",
    category: "selfAwareness",
    isReversed: false,
    weight: 1.0,
  },
  {
    statement: "I am open to feedback about my behavior from others.",
    category: "selfAwareness",
    isReversed: false,
    weight: 1.0,
  },
  {
    statement: "I tend to ignore or suppress uncomfortable feelings.",
    category: "selfAwareness",
    isReversed: true,
    weight: 1.0,
  },

  // ═══════════════════════════════════════════════════════════════════════════
  // SELF-REGULATION (16 statements)
  // ═══════════════════════════════════════════════════════════════════════════
  {
    statement: "I can calm myself down when I feel angry or frustrated.",
    category: "selfRegulation",
    isReversed: false,
    weight: 1.0,
  },
  {
    statement: "I think before I act, even when I feel strong emotions.",
    category: "selfRegulation",
    isReversed: false,
    weight: 1.0,
  },
  {
    statement: "I often say things I regret when I am upset.",
    category: "selfRegulation",
    isReversed: true,
    weight: 1.0,
  },
  {
    statement: "I can manage my anxiety in stressful situations.",
    category: "selfRegulation",
    isReversed: false,
    weight: 1.0,
  },
  {
    statement: "I adapt well to changing circumstances.",
    category: "selfRegulation",
    isReversed: false,
    weight: 1.0,
  },
  {
    statement: "I have difficulty controlling my impulses.",
    category: "selfRegulation",
    isReversed: true,
    weight: 1.0,
  },
  {
    statement: "I remain composed under pressure.",
    category: "selfRegulation",
    isReversed: false,
    weight: 1.2,
  },
  {
    statement: "I can delay gratification to achieve long-term goals.",
    category: "selfRegulation",
    isReversed: false,
    weight: 1.0,
  },
  {
    statement: "When things go wrong, I tend to spiral into negative thinking.",
    category: "selfRegulation",
    isReversed: true,
    weight: 1.0,
  },
  {
    statement: "I bounce back quickly from setbacks and disappointments.",
    category: "selfRegulation",
    isReversed: false,
    weight: 1.0,
  },
  {
    statement: "I can redirect my negative emotions into productive activities.",
    category: "selfRegulation",
    isReversed: false,
    weight: 1.2,
  },
  {
    statement: "I find it hard to let go of grudges.",
    category: "selfRegulation",
    isReversed: true,
    weight: 1.0,
  },
  {
    statement: "I maintain my integrity and values even under social pressure.",
    category: "selfRegulation",
    isReversed: false,
    weight: 1.0,
  },
  {
    statement: "I handle ambiguity and uncertainty with relative ease.",
    category: "selfRegulation",
    isReversed: false,
    weight: 1.0,
  },
  {
    statement: "I tend to overreact to minor inconveniences.",
    category: "selfRegulation",
    isReversed: true,
    weight: 1.0,
  },
  {
    statement: "I can express my emotions appropriately in different contexts.",
    category: "selfRegulation",
    isReversed: false,
    weight: 1.0,
  },

  // ═══════════════════════════════════════════════════════════════════════════
  // MOTIVATION (16 statements)
  // ═══════════════════════════════════════════════════════════════════════════
  {
    statement: "I am driven to achieve my goals regardless of external rewards.",
    category: "motivation",
    isReversed: false,
    weight: 1.0,
  },
  {
    statement: "I remain optimistic even when facing significant obstacles.",
    category: "motivation",
    isReversed: false,
    weight: 1.0,
  },
  {
    statement: "I give up easily when tasks become difficult.",
    category: "motivation",
    isReversed: true,
    weight: 1.0,
  },
  {
    statement: "I set high standards for myself in everything I do.",
    category: "motivation",
    isReversed: false,
    weight: 1.0,
  },
  {
    statement: "I view failures as learning opportunities rather than defeats.",
    category: "motivation",
    isReversed: false,
    weight: 1.2,
  },
  {
    statement: "I lack the energy to pursue my personal goals consistently.",
    category: "motivation",
    isReversed: true,
    weight: 1.0,
  },
  {
    statement: "I take initiative and act on opportunities without being asked.",
    category: "motivation",
    isReversed: false,
    weight: 1.0,
  },
  {
    statement: "I am committed to continuous self-improvement.",
    category: "motivation",
    isReversed: false,
    weight: 1.0,
  },
  {
    statement: "I find it hard to motivate myself without external pressure.",
    category: "motivation",
    isReversed: true,
    weight: 1.0,
  },
  {
    statement: "I persist with tasks even when progress is slow.",
    category: "motivation",
    isReversed: false,
    weight: 1.0,
  },
  {
    statement: "I am passionate about what I do and find meaning in my work.",
    category: "motivation",
    isReversed: false,
    weight: 1.0,
  },
  {
    statement: "I often procrastinate on important tasks.",
    category: "motivation",
    isReversed: true,
    weight: 1.0,
  },
  {
    statement: "I look forward to challenges as chances to grow.",
    category: "motivation",
    isReversed: false,
    weight: 1.2,
  },
  {
    statement: "I can maintain focus on long-term objectives despite distractions.",
    category: "motivation",
    isReversed: false,
    weight: 1.0,
  },
  {
    statement: "I tend to focus on what could go wrong rather than what could go right.",
    category: "motivation",
    isReversed: true,
    weight: 1.0,
  },
  {
    statement: "I celebrate small victories on the way to larger goals.",
    category: "motivation",
    isReversed: false,
    weight: 1.0,
  },

  // ═══════════════════════════════════════════════════════════════════════════
  // EMPATHY (16 statements)
  // ═══════════════════════════════════════════════════════════════════════════
  {
    statement: "I can easily sense how other people are feeling.",
    category: "empathy",
    isReversed: false,
    weight: 1.0,
  },
  {
    statement: "I listen attentively when someone is sharing their problems.",
    category: "empathy",
    isReversed: false,
    weight: 1.0,
  },
  {
    statement: "I find it hard to understand why people get upset about certain things.",
    category: "empathy",
    isReversed: true,
    weight: 1.0,
  },
  {
    statement: "I can see situations from other people's perspectives.",
    category: "empathy",
    isReversed: false,
    weight: 1.2,
  },
  {
    statement: "I am moved by the suffering of others.",
    category: "empathy",
    isReversed: false,
    weight: 1.0,
  },
  {
    statement: "I struggle to connect emotionally with people from different backgrounds.",
    category: "empathy",
    isReversed: true,
    weight: 1.0,
  },
  {
    statement: "I can tell when someone is uncomfortable even if they don't say so.",
    category: "empathy",
    isReversed: false,
    weight: 1.2,
  },
  {
    statement: "I consider how my actions will make others feel before I act.",
    category: "empathy",
    isReversed: false,
    weight: 1.0,
  },
  {
    statement: "I find it difficult to put myself in someone else's shoes.",
    category: "empathy",
    isReversed: true,
    weight: 1.0,
  },
  {
    statement: "I notice subtle changes in other people's moods.",
    category: "empathy",
    isReversed: false,
    weight: 1.0,
  },
  {
    statement: "I am genuinely interested in understanding other people's experiences.",
    category: "empathy",
    isReversed: false,
    weight: 1.0,
  },
  {
    statement: "People often come to me when they need someone to talk to.",
    category: "empathy",
    isReversed: false,
    weight: 1.0,
  },
  {
    statement: "I sometimes dismiss other people's feelings as overreactions.",
    category: "empathy",
    isReversed: true,
    weight: 1.0,
  },
  {
    statement: "I feel happy when good things happen to the people I care about.",
    category: "empathy",
    isReversed: false,
    weight: 1.0,
  },
  {
    statement: "I can understand viewpoints that differ significantly from my own.",
    category: "empathy",
    isReversed: false,
    weight: 1.0,
  },
  {
    statement: "I tend to focus on my own concerns rather than noticing how others feel.",
    category: "empathy",
    isReversed: true,
    weight: 1.0,
  },

  // ═══════════════════════════════════════════════════════════════════════════
  // SOCIAL SKILLS (16 statements)
  // ═══════════════════════════════════════════════════════════════════════════
  {
    statement: "I find it easy to build rapport with new people.",
    category: "socialSkills",
    isReversed: false,
    weight: 1.0,
  },
  {
    statement: "I can effectively resolve conflicts between people.",
    category: "socialSkills",
    isReversed: false,
    weight: 1.2,
  },
  {
    statement: "I struggle to express my ideas clearly in group settings.",
    category: "socialSkills",
    isReversed: true,
    weight: 1.0,
  },
  {
    statement: "I work well as part of a team.",
    category: "socialSkills",
    isReversed: false,
    weight: 1.0,
  },
  {
    statement: "I can persuade others to see things from a different perspective.",
    category: "socialSkills",
    isReversed: false,
    weight: 1.0,
  },
  {
    statement: "I find networking and social events draining and unproductive.",
    category: "socialSkills",
    isReversed: true,
    weight: 1.0,
  },
  {
    statement: "I give constructive feedback in a way that motivates rather than discourages.",
    category: "socialSkills",
    isReversed: false,
    weight: 1.2,
  },
  {
    statement: "I am effective at managing and leading group activities.",
    category: "socialSkills",
    isReversed: false,
    weight: 1.0,
  },
  {
    statement: "I avoid difficult conversations whenever possible.",
    category: "socialSkills",
    isReversed: true,
    weight: 1.0,
  },
  {
    statement: "I can read the social dynamics of a group quickly.",
    category: "socialSkills",
    isReversed: false,
    weight: 1.0,
  },
  {
    statement: "I maintain strong, healthy relationships with the people in my life.",
    category: "socialSkills",
    isReversed: false,
    weight: 1.0,
  },
  {
    statement: "I tend to dominate conversations without realizing it.",
    category: "socialSkills",
    isReversed: true,
    weight: 1.0,
  },
  {
    statement: "I can inspire and motivate others toward a shared goal.",
    category: "socialSkills",
    isReversed: false,
    weight: 1.0,
  },
  {
    statement: "I handle criticism gracefully without becoming defensive.",
    category: "socialSkills",
    isReversed: false,
    weight: 1.0,
  },
  {
    statement: "I find it hard to cooperate with people who think differently than I do.",
    category: "socialSkills",
    isReversed: true,
    weight: 1.0,
  },
  {
    statement: "I communicate clearly and adjust my style depending on my audience.",
    category: "socialSkills",
    isReversed: false,
    weight: 1.0,
  },
];

// ─────────────────────────────────────────────────────────────────────────────
// Seeding Logic
// ─────────────────────────────────────────────────────────────────────────────

const BATCH_SIZE = 450; // Firestore batch limit is 500; leave margin

/**
 * Seeds a Firestore collection with documents in efficient batches.
 *
 * @param {string} collectionName - Firestore collection path.
 * @param {Array<Object>} documents - Documents to write.
 * @param {string} idPrefix - Prefix for generated document IDs.
 * @returns {number} Count of documents written.
 */
async function seedCollection(collectionName, documents, idPrefix) {
  let totalWritten = 0;
  let batchCount = 0;
  let batch = db.batch();

  for (let i = 0; i < documents.length; i++) {
    const doc = documents[i];
    const docId = `${idPrefix}_${String(i + 1).padStart(4, "0")}`;
    const ref = db.collection(collectionName).doc(docId);

    batch.set(ref, {
      ...doc,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    batchCount++;
    totalWritten++;

    if (batchCount >= BATCH_SIZE) {
      await batch.commit();
      console.log(`  Committed batch (${totalWritten} documents so far...)`);
      batch = db.batch();
      batchCount = 0;
    }
  }

  // Commit any remaining documents
  if (batchCount > 0) {
    await batch.commit();
  }

  return totalWritten;
}

/**
 * Deletes all documents in a collection (used with --clear flag).
 */
async function clearCollection(collectionName) {
  const snapshot = await db.collection(collectionName).get();

  if (snapshot.empty) {
    console.log(`  ${collectionName}: already empty.`);
    return;
  }

  let batch = db.batch();
  let count = 0;

  for (const doc of snapshot.docs) {
    batch.delete(doc.ref);
    count++;

    if (count % BATCH_SIZE === 0) {
      await batch.commit();
      batch = db.batch();
    }
  }

  if (count % BATCH_SIZE !== 0) {
    await batch.commit();
  }

  console.log(`  ${collectionName}: deleted ${count} documents.`);
}

/**
 * Main entry point.
 */
async function main() {
  console.log("======================================");
  console.log("  Lumoni Firestore Seed Script");
  console.log("======================================");
  console.log();

  const seedIQ = !eqOnly;
  const seedEQ = !iqOnly;

  // ── Clear existing data if requested ────────────────────────────────────
  if (clearFirst) {
    console.log("Clearing existing data...");
    if (seedIQ) await clearCollection("iq_questions");
    if (seedEQ) await clearCollection("eq_questions");
    console.log("Clear complete.");
    console.log();
  }

  // ── Seed IQ Questions ───────────────────────────────────────────────────
  if (seedIQ) {
    console.log(`Seeding IQ questions (${IQ_QUESTIONS.length} questions)...`);

    // Print distribution summary
    const categories = {};
    const difficulties = {};
    for (const q of IQ_QUESTIONS) {
      categories[q.category] = (categories[q.category] || 0) + 1;
      difficulties[q.difficulty] = (difficulties[q.difficulty] || 0) + 1;
    }

    console.log("  Category distribution:");
    Object.entries(categories)
      .sort()
      .forEach(([k, v]) => console.log(`    ${k}: ${v}`));

    console.log("  Difficulty distribution:");
    Object.entries(difficulties)
      .sort()
      .forEach(([k, v]) => console.log(`    Level ${k}: ${v}`));

    const iqCount = await seedCollection("iq_questions", IQ_QUESTIONS, "iq");
    console.log(`  Done! Seeded ${iqCount} IQ questions.`);
    console.log();
  }

  // ── Seed EQ Statements ──────────────────────────────────────────────────
  if (seedEQ) {
    console.log(`Seeding EQ statements (${EQ_STATEMENTS.length} statements)...`);

    // Print distribution summary
    const categories = {};
    let reversedCount = 0;
    for (const s of EQ_STATEMENTS) {
      categories[s.category] = (categories[s.category] || 0) + 1;
      if (s.isReversed) reversedCount++;
    }

    console.log("  Category distribution:");
    Object.entries(categories)
      .sort()
      .forEach(([k, v]) => console.log(`    ${k}: ${v}`));
    console.log(`  Reversed items: ${reversedCount}`);

    const eqCount = await seedCollection("eq_questions", EQ_STATEMENTS, "eq");
    console.log(`  Done! Seeded ${eqCount} EQ statements.`);
    console.log();
  }

  // ── Summary ─────────────────────────────────────────────────────────────
  console.log("======================================");
  console.log("  Seeding complete!");
  console.log("======================================");
  console.log();
  console.log("Next steps:");
  console.log("  1. Deploy Firestore security rules:  firebase deploy --only firestore:rules");
  console.log("  2. Deploy Firestore indexes:         firebase deploy --only firestore:indexes");
  console.log("  3. Deploy Cloud Functions:            firebase deploy --only functions");
  console.log();

  process.exit(0);
}

main().catch((error) => {
  console.error("Seed script failed:", error);
  process.exit(1);
});
