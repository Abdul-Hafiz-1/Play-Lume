import 'package:flutter/material.dart';

abstract class GamePlugin {
  String get id;           // e.g., 'heads_up'
  String get name;         // e.g., 'Heads Up'
  IconData get icon;       // For the lobby UI
  
  // This builds the actual game screen
  Widget buildScreen(String roomCode, String gameId, bool isHost);

  // This handles the unique Firestore setup (like shuffling roles)
  Future<void> onGameStart(String roomCode, List<dynamic> players);
}