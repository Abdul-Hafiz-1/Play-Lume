import 'package:flutter/material.dart';
import '../../core/navigation.dart';
import 'chameleon_screen.dart';
import 'dont_get_caught_screen.dart';
import 'dont_get_me_started_offline.dart';
import 'dont_get_me_started_screen.dart';
import 'glitch_screen.dart';
import 'guess_the_liar_local.dart';
import 'guess_the_liar_screen.dart';
import 'heads_up_game_screen.dart';
import 'informant_screen.dart';
import 'interrogation_screen.dart';
import 'mafia_game_screen.dart';
import 'most_likely_to_screen.dart';
import 'spy_screen.dart';
import 'sync_game_screen.dart';
import 'sync_local.dart';
import 'undercover_screen.dart';

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
export 'heads_up_game_screen.dart';
export 'mafia_game_screen.dart';
export 'sync_local.dart';
export 'guess_the_liar_local.dart';
export 'dont_get_me_started_offline.dart';
export 'chameleon_screen.dart';
// export 'clocktower_screen.dart'; // Uncomment once you create the file!

class GameFactory {
  static Widget build(String key, Map<String, dynamic> args) {
    final List<String> p = args['players'] is List 
        ? List<String>.from(args['players']) 
        : [];
    final String rc = args['roomCode']?.toString() ?? "";
    final String gi = args['gameId']?.toString() ?? key;

    switch (key) {
      // ONLINE GAMES
      case 'sync':
      case 'sync_game':
        if (p.isNotEmpty) {
          // If players exist, launch the Local version
          return LocalSyncGameScreen(players: p);
        }
        // Otherwise, launch the Online version
        if (rc.isEmpty) return MissionUnavailableScreen(gameKey: key);
        return SyncGameScreen(roomCode: rc, gameId: gi);
      case 'guess_the_liar':
        if (p.isNotEmpty) {
            // If players exist, launch the Local version
            return LocalGuessTheLiarScreen(players: p);
          }
        if (rc.isEmpty) return MissionUnavailableScreen(gameKey: key);
        return GuessTheLiarGameScreen(roomCode: rc, gameId: gi);
      case 'most_likely_to':
        if (rc.isEmpty) return MissionUnavailableScreen(gameKey: key);
        return MostLikelyToScreen(roomCode: rc, gameId: gi);
      case 'dont_get_me_started':
      if (p.isNotEmpty) {
          // If players exist, launch the Local version
          return LocalRantScreen(players: p);
        }
        if (rc.isEmpty) return MissionUnavailableScreen(gameKey: key);
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
      case 'heads_up':
        final List<String> p = args['players'] is List ? List<String>.from(args['players']) : [];
        return HeadsUpGameScreen(players: p);
      case 'mafia':
        final List<String> p = args['players'] is List 
            ? List<String>.from(args['players']) 
            : [];
        return MafiaGameScreen(players: p);
      case 'chameleon':
        final List<String> p = args['players'] is List 
            ? List<String>.from(args['players']) 
            : [];
        return ChameleonScreen(players: p);

      default:
        return MissionUnavailableScreen(gameKey: key);
    }
  }
}

class MissionUnavailableScreen extends StatelessWidget {
  final String gameKey;
  const MissionUnavailableScreen({super.key, required this.gameKey});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF04060E),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 72),
                const SizedBox(height: 18),
                const Text(
                  'MISSION UNAVAILABLE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  "The route '$gameKey' is missing required setup data or is not registered.",
                  style: const TextStyle(color: Colors.white60, height: 1.4),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                ElevatedButton.icon(
                  onPressed: () => AppNavigation.goHome(context),
                  icon: const Icon(Icons.home_rounded),
                  label: const Text('RETURN HOME'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
