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
import 'screens/comms/comm_room_screen.dart'; 

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
      
      routes: {
        '/': (context) => const NicknameScreen(),
      },

      onGenerateRoute: (settings) {
        // 1. Dynamic Home Route
        if (settings.name == '/home') {
          final nickname = settings.arguments as String? ?? "Guest";
          return MaterialPageRoute(builder: (_) => HomeScreen(nickname: nickname));
        }

        // 2. Dynamic Lobby Route (DEFENSIVE FIX)
        if (settings.name == '/game_lobby') {
          Game? game;
          if (settings.arguments is Game) {
            game = settings.arguments as Game;
          } else if (settings.arguments is Map<String, dynamic>) {
            final args = settings.arguments as Map<String, dynamic>;
            game = args['game'] as Game?;
          }
          
          return MaterialPageRoute(
            builder: (_) => game != null 
                ? GameSelectionLobbyScreen(game: game) 
                : const NicknameScreen(),
          );
        }

        // 3. Dynamic Waiting Lobby
        if (settings.name == '/waiting_lobby') {
          final args = settings.arguments as Map<String, dynamic>?;
          return MaterialPageRoute(builder: (_) => WaitingLobbyScreen(
            roomCode: args?['roomCode']?.toString() ?? "",
            gameId: args?['gameId']?.toString() ?? "",
            isHost: args?['isHost'] ?? false,
          ));
        }

        // 4. Communication Room
        if (settings.name == '/comm_room') {
          final args = settings.arguments as Map<String, dynamic>?;
          return MaterialPageRoute(
            builder: (_) => CommRoomScreen(
              roomCode: args?['roomCode']?.toString() ?? "000000",
            ),
          );
        }

        // 5. Pass and Play Setup (DEFENSIVE FIX)
        if (settings.name == '/setup/pass_and_play') {
          Game? game;
          if (settings.arguments is Game) {
            game = settings.arguments as Game;
          } else if (settings.arguments is Map<String, dynamic>) {
            final args = settings.arguments as Map<String, dynamic>;
            game = args['game'] as Game?;
          }

          return MaterialPageRoute(
            builder: (_) => game != null 
                ? PassAndPlaySetupScreen(game: game) 
                : const NicknameScreen(),
          );
        }

        // 6. Universal Game Router
        if (settings.name!.startsWith('/play/')) {
          final gameKey = settings.name!.replaceFirst('/play/', '');
          // Using a safe cast here
          final args = settings.arguments is Map<String, dynamic> 
              ? settings.arguments as Map<String, dynamic> 
              : <String, dynamic>{};

          return MaterialPageRoute(
            builder: (context) => GameFactory.build(gameKey, args),
          );
        }

        return null;
      },
    );
  }
}