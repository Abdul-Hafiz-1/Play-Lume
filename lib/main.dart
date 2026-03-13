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
      // Uses initialRoute to prevent conflict with 'home' property
      initialRoute: '/', 
      routes: {
        // 1. Core Navigation
        '/': (context) => const NicknameScreen(),
        
        '/home': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args == null || args is! String) {
            return const NicknameScreen();
          }
          return HomeScreen(nickname: args);
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
              roomCode: args['roomCode'].toString(), 
              gameId: args['gameId'].toString(), 
              isHost: args['isHost'] ?? false,
            );
          }
          return const NicknameScreen();
        },

        // 2. Setup Routes (Local Games)
        '/setup/pass_and_play': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is Game) return PassAndPlaySetupScreen(game: args);
          return const NicknameScreen();
        },

        // 3. Online Play Routes (Matched to Database IDs)
        '/play/sync_game': (context) => _buildOnline(context, (rc, gi) => SyncGameScreen(roomCode: rc, gameId: gi)),
  
        // Do the same for your other games if they have "_game" in the ID
        '/play/guess_the_liar': (context) => _buildOnline(context, (rc, gi) => GuessTheLiarGameScreen(roomCode: rc, gameId: gi)),
        '/play/most_likely_to': (context) => _buildOnline(context, (rc, gi) => MostLikelyToScreen(roomCode: rc, gameId: gi)),
        '/play/dont_get_me_started': (context) => _buildOnline(context, (rc, gi) => DontGetMeStartedGameScreen(roomCode: rc, gameId: gi)),

        // 4. Local Play Routes
        '/play/glitch': (context) => _buildLocal(context, (p) => GlitchScreen(players: p)),
        '/play/interrogation': (context) => _buildLocal(context, (p) => InterrogationScreen(players: p)),
        '/play/spy': (context) => _buildLocal(context, (p) => SpyScreen(players: p)),
        '/play/undercover': (context) => _buildLocal(context, (p) => UndercoverScreen(players: p)),
        '/play/informant': (context) => _buildLocal(context, (p) => InformantScreen(players: p)),
        '/play/dont_get_caught': (context) => _buildLocal(context, (p) => DontGetCaughtScreen(players: p)),
      },
    );
  }

  // --- HELPER: ONLINE GAMES ---
  Widget _buildOnline(BuildContext context, Widget Function(String, String) builder) {
    final settings = ModalRoute.of(context)?.settings;
    final args = settings?.arguments as Map<String, dynamic>?;
    
    if (args != null && args.containsKey('roomCode')) {
      print("ROUTER: Success! Launching ${settings?.name} for Room ${args['roomCode']}");
      // Force toString() to prevent TypeErrors if IDs are passed as ints
      return builder(args['roomCode'].toString(), args['gameId'].toString());
    }
    
    print("ROUTER ERROR: Missing arguments for ${settings?.name}. Redirecting to Nickname.");
    // Fallback to avoid a black screen
    return const Scaffold(
      backgroundColor: Color(0xFF04060E),
      body: Center(child: CircularProgressIndicator(color: Colors.blue)),
    );
  }

  // --- HELPER: LOCAL GAMES ---
  Widget _buildLocal(BuildContext context, Widget Function(List<String>) builder) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args.containsKey('players')) {
      return builder(List<String>.from(args['players']));
    }
    return const NicknameScreen();
  }
}