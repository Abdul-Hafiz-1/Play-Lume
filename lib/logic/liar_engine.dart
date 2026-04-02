import 'dart:math';
import '../models/question_model.dart';

enum LiarPhase { setup, scanning, secret, pass, interrogation, voting, results }

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

  void nextState() {
    switch (phase) {
      case LiarPhase.scanning:
        phase = LiarPhase.secret;
        break;
      case LiarPhase.secret:
        // After seeing the secret, we either pass to the next player or start discussing
        if (currentPlayerIndex < players.length - 1) {
          phase = LiarPhase.pass;
        } else {
          phase = LiarPhase.interrogation;
        }
        break;
      case LiarPhase.pass:
        // The index only increments here, when the new player confirms they have the device
        currentPlayerIndex++;
        phase = LiarPhase.scanning;
        break;
      case LiarPhase.interrogation:
        // Reset index for the voting loop
        currentPlayerIndex = 0; 
        phase = LiarPhase.voting; 
        break;
      case LiarPhase.voting:
        // After a vote is cast, we either move to the next voter's pass screen or show results
        if (currentPlayerIndex < players.length - 1) {
          phase = LiarPhase.pass; // Re-use pass screen for voting handover
        } else {
          phase = LiarPhase.results;
        }
        break;
      default:
        break;
    }
  }
}