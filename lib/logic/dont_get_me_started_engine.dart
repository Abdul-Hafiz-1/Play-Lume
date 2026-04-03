import 'dart:math';

enum RantPhase { setup, topicInput, groupGuessing, ranting, ranterReview, results }

class RantEngine {
  final List<String> players;
  int currentRound = 1;
  int totalRounds = 3; 
  int ranterIndex = 0;
  RantPhase phase = RantPhase.setup;

  String? currentTopic;
  
  // Local Data persistence (RAM only)
  final Map<String, List<String>> playerGuesses = {};
  final Map<String, List<bool>> correctGuesses = {}; 
  final Map<String, int> scores = {};

  RantEngine({required this.players}) {
    for (var p in players) scores[p] = 0;
  }

  void startNewRound() {
    ranterIndex = (currentRound - 1) % players.length;
    currentTopic = null;
    playerGuesses.clear();
    correctGuesses.clear();
    phase = RantPhase.topicInput;
  }

  void finalizeScores() {
    String ranter = players[ranterIndex];
    correctGuesses.forEach((player, masks) {
      int correctCount = masks.where((m) => m == true).length;
      if (correctCount > 0) {
        // Town gets points for guessing correctly
        scores[player] = (scores[player] ?? 0) + (correctCount * 100);
        // Ranter gets points for being clear enough to be guessed
        scores[ranter] = (scores[ranter] ?? 0) + (correctCount * 50);
      }
    });
  }

  void nextState() {
    switch (phase) {
      case RantPhase.topicInput: phase = RantPhase.groupGuessing; break;
      case RantPhase.groupGuessing: phase = RantPhase.ranting; break;
      case RantPhase.ranting: phase = RantPhase.ranterReview; break;
      case RantPhase.ranterReview: 
        finalizeScores();
        phase = RantPhase.results; 
        break;
      default: break;
    }
  }
}