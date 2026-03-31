import 'dart:ui';
import 'package:flutter/material.dart';
import '../../logic/mafia_engine.dart';
import '../../core/theme.dart';

class MafiaResultScreen extends StatelessWidget {
  final String winner; // "MAFIA", "TOWN", or "JESTER"
  final MafiaSession session;

  const MafiaResultScreen({
    super.key, 
    required this.winner, 
    required this.session
  });

  @override
  Widget build(BuildContext context) {
    final Color themeColor = _getThemeColor();
    final String bgImage = _getBackgroundImage();
    final String victorySubtitle = _getSubtitle();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 💎 1. THE CINEMATIC BACKGROUND
          Positioned.fill(
            child: Image.asset(
              'assets/$bgImage',
              fit: BoxFit.cover,
              color: Colors.black.withOpacity(0.6),
              colorBlendMode: BlendMode.darken,
              errorBuilder: (context, error, stackTrace) => Container(color: Colors.black),
            ),
          ),

          // 💎 2. VIGNETTE OVERLAY
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                  stops: const [0.4, 1.0],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 60),
                
                // 💎 3. VICTORY HEADER
                _buildVictoryHeader(themeColor, victorySubtitle),

                const SizedBox(height: 40),

                // 💎 4. FINAL ROSTER (Scrollable Glass Card)
                Expanded(child: _buildFinalDossier(themeColor)),

                const SizedBox(height: 30),

                // 💎 5. ACTION BUTTON
                _buildReturnButton(context, themeColor),
                
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVictoryHeader(Color themeColor, String subtitle) {
    return Column(
      children: [
        const Text(
          "SESSION TERMINATED",
          style: TextStyle(
            color: Colors.white24,
            letterSpacing: 8,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 15),
        Text(
          "$winner VICTORY",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.w900,
            color: themeColor,
            letterSpacing: 4,
            shadows: [
              Shadow(color: themeColor.withOpacity(0.5), blurRadius: 40),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            subtitle.toUpperCase(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 12,
              letterSpacing: 2,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFinalDossier(Color themeColor) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 30),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("FINAL ROSTER", 
                      style: TextStyle(color: Colors.white24, fontSize: 10, letterSpacing: 4)),
                    Icon(Icons.folder_shared_outlined, color: themeColor.withOpacity(0.5), size: 16),
                  ],
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    itemCount: session.allPlayers.length,
                    separatorBuilder: (context, index) => const Divider(color: Colors.white10, height: 20),
                    itemBuilder: (context, index) {
                      String name = session.allPlayers[index];
                      String role = session.roles[name]!;
                      bool isDead = session.deceased.contains(name);
                      
                      return Row(
                        children: [
                          Container(
                            width: 4,
                            height: 30,
                            decoration: BoxDecoration(
                              color: isDead ? Colors.white10 : _getRoleColor(role),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Text(
                              name.toUpperCase(),
                              style: TextStyle(
                                color: isDead ? Colors.white24 : Colors.white,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                                decoration: isDead ? TextDecoration.lineThrough : null,
                              ),
                            ),
                          ),
                          Text(
                            role,
                            style: TextStyle(
                              color: isDead ? Colors.white10 : _getRoleColor(role).withOpacity(0.7),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReturnButton(BuildContext context, Color themeColor) {
    return GestureDetector(
      onTap: () => Navigator.of(context).popUntil((route) => route.isFirst),
      child: Container(
        width: 280,
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: themeColor.withOpacity(0.3)),
          gradient: LinearGradient(
            colors: [themeColor.withOpacity(0.1), Colors.transparent],
          ),
        ),
        child: const Center(
          child: Text(
            "BACK TO LOBBY",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
            ),
          ),
        ),
      ),
    );
  }

  // --- LOGIC HELPERS ---

  Color _getThemeColor() {
    switch (winner) {
      case "MAFIA": return const Color(0xFFEF4444);
      case "TOWN": return const Color(0xFF10B981);
      case "JESTER": return const Color(0xFFF59E0B);
      default: return Colors.white;
    }
  }

  String _getBackgroundImage() {
    switch (winner) {
      case "MAFIA": return "mafia_win.jpg";
      case "TOWN": return "town_win.jpg";
      default: return "jester_win.jpg";
    }
  }

  String _getSubtitle() {
    switch (winner) {
      case "MAFIA": return "The shadows have consumed the village.\nOrder is dead.";
      case "TOWN": return "The fog clears at last.\nPeace is restored to the valley.";
      default: return "The world is a stage,\nand you were all just puppets.";
    }
  }

  Color _getRoleColor(String role) {
    if (role == "MAFIA") return const Color(0xFFEF4444);
    if (role == "DOCTOR") return const Color(0xFF3B82F6);
    if (role == "DETECTIVE") return const Color(0xFF06B6D4);
    if (role == "JESTER") return const Color(0xFFA855F7);
    return Colors.white54;
  }
}