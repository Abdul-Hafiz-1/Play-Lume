// lib/models/question_model.dart
/// Represents a pair of questions: one for normal players and a similar one for the liar.
class QuestionPair {
  final String original;
  final String liar;

  const QuestionPair({required this.original, required this.liar});
}