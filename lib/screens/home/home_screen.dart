import 'package:flutter/material.dart';
import 'dart:ui';
import '../../models/game_model.dart';

class HomeScreen extends StatelessWidget {
  final String nickname; 
  const HomeScreen({super.key, required this.nickname});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF04060E),
      body: Stack(
        children: [
          Positioned(top: -100, left: -50, child: _glowOrb(250, const Color(0xFF1E3A8A).withOpacity(0.3))),
          Positioned(bottom: -50, right: -50, child: _glowOrb(300, const Color(0xFF4C1D95).withOpacity(0.2))),

          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(24.0),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Welcome back, $nickname", style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 16, letterSpacing: 1.2)),
                        const SizedBox(height: 8),
                        const Text("Choose Your Mission", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),
                ),

                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, mainAxisSpacing: 16, crossAxisSpacing: 16, childAspectRatio: 0.85,
                    ),
                    delegate: SliverChildListDelegate([
                      // ONLINE GAMES
                      _buildGameCard(context, "SYNC GAME", "Think as One", Icons.sync, Colors.blue, true, '/play/sync'),
                      _buildGameCard(context, "GUESS THE LIAR", "Find the Storyteller", Icons.psychology, Colors.pink, true, '/play/guess_the_liar'),
                      _buildGameCard(context, "MOST LIKELY TO", "Family Voting", Icons.people, Colors.cyan, true, '/play/most_likely_to'),
                      _buildGameCard(context, "DONT GET ME STARTED", "Rant Master", Icons.forum, Colors.orange, true, '/play/dont_get_me_started'),

                      // LOCAL GAMES
                      _buildGameCard(context, "THE GLITCH", "Find the Corruption", Icons.bug_report, Colors.red, false, '/play/glitch'),
                      _buildGameCard(context, "INTERROGATION", "Detective vs Suspect", Icons.mic, Colors.indigo, false, '/play/interrogation'),
                      _buildGameCard(context, "SPY", "Undercover Mission", Icons.search, Colors.amber, false, '/play/spy'),
                      _buildGameCard(context, "UNDERCOVER", "Secret Word Game", Icons.visibility_off, Colors.purple, false, '/play/undercover'),
                      _buildGameCard(context, "INFORMANT", "The Secret Ally", Icons.support_agent, Colors.teal, false, '/play/informant'),
                      _buildGameCard(context, "DONT GET CAUGHT", "Stealth Capture", Icons.camera, Colors.green, false, '/play/dont_get_caught'),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _glowOrb(double size, Color color) {
    return Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: color, boxShadow: [BoxShadow(color: color, blurRadius: 100, spreadRadius: 50)]));
  }

  Widget _buildGameCard(BuildContext context, String title, String subtitle, IconData icon, Color accentColor, bool isOnline, String playRoute) {
    return GestureDetector(
      onTap: () {
        final game = Game(
          id: title.toLowerCase().replaceAll(' ', '_'),
          name: title,
          description: subtitle,
          imageAsset: '',
          isOnline: isOnline,
          selectionLobbyRouteName: isOnline ? '/game_lobby' : '/setup/pass_and_play',
          actualGameRouteName: playRoute,
        );

        Navigator.pushNamed(context, game.selectionLobbyRouteName, arguments: game);
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(28), border: Border.all(color: Colors.white.withOpacity(0.08), width: 1.5)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: accentColor.withOpacity(0.15), shape: BoxShape.circle), child: Icon(icon, color: accentColor, size: 28)),
                  const Spacer(),
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}