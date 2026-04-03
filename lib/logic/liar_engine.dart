import 'dart:math';
import '../models/question_model.dart';

enum LiarPhase { setup, scanning, secret, pass, interrogation, voting, results, finalLeaderboard }

class LiarEngine {
  final List<String> players;
  final List<QuestionPair> allQuestions;
  
  int currentRound = 1;
  int totalRounds = 3; 
  int currentPlayerIndex = 0;
  int liarIndex = 0;
  LiarPhase phase = LiarPhase.setup;

  late QuestionPair currentPair;
  final Map<String, int> scores = {};
  final Map<String, String> playerAnswers = {};
  final Map<String, String> votes = {};

  LiarEngine({required this.players, required this.allQuestions}) {
    for (var p in players) scores[p] = 0;
  }

  void startNewRound() {
    liarIndex = Random().nextInt(players.length);
    currentPair = (List<QuestionPair>.from(allQuestions)..shuffle()).first;
    playerAnswers.clear();
    votes.clear();
    currentPlayerIndex = 0;
    phase = LiarPhase.scanning;
  }

  void calculatePoints() {
    String liar = players[liarIndex];
    Map<String, int> voteCounts = {};
    for (var v in votes.values) voteCounts[v] = (voteCounts[v] ?? 0) + 1;

    int votesAgainstLiar = voteCounts[liar] ?? 0;
    bool caught = votesAgainstLiar > (players.length - 1) / 2;

    if (caught) {
      for (var p in players) {
        if (p != liar) scores[p] = (scores[p] ?? 0) + 1;
      }
    } else {
      scores[liar] = (scores[liar] ?? 0) + 1;
    }
  }

  void nextState() {
    switch (phase) {
      case LiarPhase.scanning: phase = LiarPhase.secret; break;
      case LiarPhase.secret:
        if (currentPlayerIndex < players.length - 1) phase = LiarPhase.pass;
        else phase = LiarPhase.interrogation;
        break;
      case LiarPhase.pass:
        currentPlayerIndex++;
        phase = (playerAnswers.length < players.length) ? LiarPhase.scanning : LiarPhase.voting;
        break;
      case LiarPhase.interrogation: currentPlayerIndex = 0; phase = LiarPhase.voting; break;
      case LiarPhase.voting:
        if (currentPlayerIndex < players.length - 1) phase = LiarPhase.pass;
        else { calculatePoints(); phase = LiarPhase.results; }
        break;
      default: break;
    }
  }
}