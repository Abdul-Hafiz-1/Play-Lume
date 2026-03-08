import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'services/firebase_service.dart';
import 'models/game_model.dart';

// Screen Imports
import 'screens/home/nickname_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/home/game_selection_lobby.dart';
import 'screens/home/waiting_lobby_screen.dart';
import 'screens/home/pass_and_play_setup_screen.dart';
import 'screens/games/guess_the_liar_screen.dart';
import 'screens/games/dont_get_me_started_screen.dart';
import 'screens/games/sync_game_screen.dart';
import 'screens/games/most_likely_to_screen.dart';
import 'screens/games/undercover_screen.dart';
import 'screens/games/dont_get_caught_screen.dart';
import 'screens/games/informant_screen.dart';
import 'screens/games/interrogation_screen.dart';
import 'screens/games/spy_screen.dart';
import 'screens/games/glitch_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> snackbarKey = GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseService.initializeFirebase();
  runApp(const PlayLumeApp());
}

class PlayLumeApp extends StatelessWidget {
  const PlayLumeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Play Lume',
      theme: AppTheme.darkTheme,
      navigatorKey: navigatorKey,
      scaffoldMessengerKey: snackbarKey,
      debugShowCheckedModeBanner: false,
      home: const NicknameScreen(),
      routes: {
        // 1. Core Navigation
        '/home': (context) {
          final nickname = ModalRoute.of(context)!.settings.arguments as String;
          return HomeScreen(nickname: nickname);
        },
        '/game_lobby': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is Game) return GameSelectionLobbyScreen(game: args);
          return const NicknameScreen();
        },
        '/waiting_lobby': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          if (args != null) {
            return WaitingLobbyScreen(
              roomCode: args['roomCode'], 
              gameId: args['gameId'], 
              isHost: args['isHost']
            );
          }
          return const NicknameScreen();
        },

        // 2. Setup Routes (Mapping for all 10 games)
        '/setup/pass_and_play': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is Game) return PassAndPlaySetupScreen(game: args);
          return const NicknameScreen();
        },

        // 3. Online Play Routes (Require RoomCode/GameID)
        '/play/sync': (context) => _buildOnline(context, (rc, gi) => SyncGameScreen(roomCode: rc, gameId: gi)),
        '/play/guess_the_liar': (context) => _buildOnline(context, (rc, gi) => GuessTheLiarGameScreen(roomCode: rc, gameId: gi)),
        '/play/most_likely_to': (context) => _buildOnline(context, (rc, gi) => MostLikelyToScreen(roomCode: rc, gameId: gi)),
        '/play/dont_get_me_started': (context) => _buildOnline(context, (rc, gi) => DontGetMeStartedGameScreen(roomCode: rc, gameId: gi)),

        // 4. Local Play Routes (Require Player List)
        '/play/glitch': (context) => _buildLocal(context, (p) => GlitchScreen(players: p)),
        '/play/interrogation': (context) => _buildLocal(context, (p) => InterrogationScreen(players: p)),
        '/play/spy': (context) => _buildLocal(context, (p) => SpyScreen(players: p)),
        '/play/undercover': (context) => _buildLocal(context, (p) => UndercoverScreen(players: p)),
        '/play/informant': (context) => _buildLocal(context, (p) => InformantScreen(players: p)),
        '/play/dont_get_caught': (context) => _buildLocal(context, (p) => DontGetCaughtScreen(players: p)),
      },
    );
  }

  // Helper for Online Firebase Games
  Widget _buildOnline(BuildContext context, Widget Function(String, String) builder) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) return builder(args['roomCode'], args['gameId']);
    return const NicknameScreen();
  }

  // Helper for Local Pass-and-Play Games
  Widget _buildLocal(BuildContext context, Widget Function(List<String>) builder) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args.containsKey('players')) {
      return builder(List<String>.from(args['players']));
    }
    return const NicknameScreen();
  }
}