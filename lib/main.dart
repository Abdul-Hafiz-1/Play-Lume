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

// THE ONLY GAME IMPORT YOU NEED
import 'screens/games/all_games.dart';

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
      initialRoute: '/', 
      
      // Static routes for core screens
      routes: {
        '/': (context) => const NicknameScreen(),
      },

      onGenerateRoute: (settings) {
        // Dynamic Home Route
        if (settings.name == '/home') {
          final nickname = settings.arguments as String? ?? "Guest";
          return MaterialPageRoute(builder: (_) => HomeScreen(nickname: nickname));
        }

        // Dynamic Lobby Route
        if (settings.name == '/game_lobby') {
          final game = settings.arguments as Game?;
          return MaterialPageRoute(builder: (_) => game != null ? GameSelectionLobbyScreen(game: game) : const NicknameScreen());
        }

        // Dynamic Waiting Lobby
        if (settings.name == '/waiting_lobby') {
          final args = settings.arguments as Map<String, dynamic>?;
          return MaterialPageRoute(builder: (_) => WaitingLobbyScreen(
            roomCode: args?['roomCode']?.toString() ?? "",
            gameId: args?['gameId']?.toString() ?? "",
            isHost: args?['isHost'] ?? false,
          ));
        }

        // --- THE UNIVERSAL GAME ROUTER ---
        if (settings.name!.startsWith('/play/')) {
          final String gameKey = settings.name!.replaceFirst('/play/', '');
          final Map<String, dynamic> args = (settings.arguments as Map<String, dynamic>?) ?? {};

          return MaterialPageRoute(
            builder: (context) => GameFactory.build(gameKey, args),
          );
        }

        return null;
      },
    );
  }
}