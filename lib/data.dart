/// Seed data for the Flashcard Quiz App (CodeAlpha Task 1).
///
/// The 10 study cards bundled with the app.

class Flashcard {
  const Flashcard({required this.question, required this.answer});

  final String question;
  final String answer;

  Map<String, String> toJson() => {'question': question, 'answer': answer};

  factory Flashcard.fromJson(Map<String, dynamic> json) {
    return Flashcard(
      question: (json['question'] as String?)?.trim() ?? '',
      answer: (json['answer'] as String?)?.trim() ?? '',
    );
  }

  bool get isValid => question.isNotEmpty && answer.isNotEmpty;
}

const List<Flashcard> defaultCards = [
  Flashcard(
    question: 'What is the capital of France?',
    answer: 'Paris',
  ),
  Flashcard(
    question: 'What planet is known as the Red Planet?',
    answer: 'Mars',
  ),
  Flashcard(
    question: 'What is the chemical symbol for water?',
    answer: 'H₂O',
  ),
  Flashcard(
    question: 'Who wrote the play "Romeo and Juliet"?',
    answer: 'William Shakespeare',
  ),
  Flashcard(
    question: 'What is the largest ocean on Earth?',
    answer: 'The Pacific Ocean',
  ),
  Flashcard(
    question: 'What is 9 × 8?',
    answer: '72',
  ),
  Flashcard(
    question:
        'Which gas do plants absorb from the air for photosynthesis?',
    answer: 'Carbon dioxide (CO₂)',
  ),
  Flashcard(
    question: 'What is the capital of Japan?',
    answer: 'Tokyo',
  ),
  Flashcard(
    question: 'How many continents are there on Earth?',
    answer:
        'Seven — Africa, Antarctica, Asia, Europe, North America, Australia (Oceania), and South America',
  ),
  Flashcard(
    question:
        'What force keeps us on the ground and pulls objects toward Earth?',
    answer: 'Gravity',
  ),
];
