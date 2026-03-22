import 'package:flutter/material.dart';

// --- STEP 1: EXPORTS ---
// This allows other files to see your games by only importing this one file.
export 'sync_game_screen.dart';
export 'guess_the_liar_screen.dart';
export 'most_likely_to_screen.dart';
export 'dont_get_me_started_screen.dart';
export 'glitch_screen.dart';
export 'interrogation_screen.dart';
export 'spy_screen.dart';
export 'undercover_screen.dart';
export 'informant_screen.dart';
export 'dont_get_caught_screen.dart';
// export 'clocktower_screen.dart'; // Uncomment once you create the file!

// --- STEP 2: THE FACTORY ---
// This map connects a "String ID" to the actual "Widget Screen"
import 'all_games.dart';

class GameFactory {
  static Widget build(String key, Map<String, dynamic> args) {
    final String rc = args['roomCode']?.toString() ?? "";
    final String gi = args['gameId']?.toString() ?? key;
    final bool ih = args['isHost'] ?? false;
    final List<String> p = List<String>.from(args['players'] ?? []);

    switch (key) {
      // ONLINE GAMES
      case 'sync_game':
        return SyncGameScreen(roomCode: rc, gameId: gi);
      case 'guess_the_liar':
        return GuessTheLiarGameScreen(roomCode: rc, gameId: gi);
      case 'most_likely_to':
        return MostLikelyToScreen(roomCode: rc, gameId: gi);
      case 'dont_get_me_started':
        return DontGetMeStartedGameScreen(roomCode: rc, gameId: gi);
      
      // Add your new game here:
      // case 'clocktower':
      //   return ClocktowerGameScreen(roomCode: rc, gameId: gi, isHost: ih);

      // LOCAL GAMES
      case 'glitch':
        return GlitchScreen(players: p);
      case 'interrogation':
        return InterrogationScreen(players: p);
      case 'spy':
        return SpyScreen(players: p);
      case 'undercover':
        return UndercoverScreen(players: p);
      case 'informant':
        return InformantScreen(players: p);
      case 'dont_get_caught':
        return DontGetCaughtScreen(players: p);

      default:
        return Scaffold(
          body: Center(child: Text("Game '$key' not found in Factory", style: const TextStyle(color: Colors.white))),
        );
    }
  }
}