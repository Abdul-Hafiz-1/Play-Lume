import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Added for HapticFeedback
import 'dart:ui';
import '../../models/game_model.dart';

class HomeScreen extends StatelessWidget {
  final String nickname;
  const HomeScreen({super.key, required this.nickname});

  void _showJoinCommsDialog(BuildContext context) {
  TextEditingController codeController = TextEditingController();
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFF0B1226),
      title: const Text("ENTER 8-DIGIT CODE", style: TextStyle(color: Colors.white, fontSize: 14)),
      content: TextField(
        controller: codeController,
        keyboardType: TextInputType.number,
        style: const TextStyle(color: Colors.white, letterSpacing: 4),
        decoration: const InputDecoration(hintText: "0000 0000", hintStyle: TextStyle(color: Colors.white24)),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
        ElevatedButton(
          onPressed: () {
            String code = codeController.text.replaceAll(' ', '');
            if (code.length == 8) {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/comm_room', arguments: {'roomCode': code});
            }
          },
          child: const Text("CONNECT"),
        ),
      ],
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    // On a phone, this will be 2. On a tablet, it could be 4.
    int columns = screenWidth > 600 ? 4 : 2;

    return Scaffold(
      backgroundColor: const Color(0xFF04060E),
      body: Stack(
        children: [
          // Ambient Background Glows
          Positioned(top: -100, left: -50, child: _glowOrb(250, const Color(0xFF1E3A8A).withOpacity(0.3))),
          Positioned(bottom: -50, right: -50, child: _glowOrb(300, const Color(0xFF4C1D95).withOpacity(0.2))),

          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Header Section
                SliverPadding(
                  padding: const EdgeInsets.all(24.0),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Welcome back, $nickname", 
                          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 16, letterSpacing: 1.2)),
                        const SizedBox(height: 8),
                        const Text("Choose Your Mission", 
                          style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),
                ),

                // --- 🎙️ COMMUNICATION ROOM SECTION ---
                SliverToBoxAdapter(
                  child: _buildCommRoomEntry(context),
                ),

                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  sliver: SliverToBoxAdapter(
                    child: Text("AVAILABLE MISSIONS", 
                      style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 12, letterSpacing: 2, fontWeight: FontWeight.bold)),
                  ),
                ),

                // Games Grid
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.85,
                    ),
                    delegate: SliverChildListDelegate([
                      // ONLINE GAMES
                      _buildGameCard(context, "SYNC GAME", "Think as One", Icons.sync, Colors.blue, true, '/play/sync'),
                      _buildGameCard(context, "GUESS THE LIAR", "Find the Storyteller", Icons.psychology, Colors.pink, true, '/play/guess_the_liar'),
                      _buildGameCard(context, "MOST LIKELY TO", "Family Voting", Icons.people, Colors.cyan, true, '/play/most_likely_to'),
                      _buildGameCard(context, "DONT GET ME STARTED", "Rant Master", Icons.forum, Colors.orange, true, '/play/dont_get_me_started'),

                      // LOCAL GAMES
                      _buildGameCard(context, "THE GLITCH", "Find the Corruption", Icons.bug_report, Colors.red, false, '/play/glitch'),
                      _buildGameCard(context, "HEADS UP", "Forehead Guessing", Icons.smartphone, Colors.blue, false, '/play/heads_up'),
                      _buildGameCard(context, "INTERROGATION", "Detective vs Suspect", Icons.mic, Colors.indigo, false, '/play/interrogation'),
                      _buildGameCard(context, "SPY", "Undercover Mission", Icons.search, Colors.amber, false, '/play/spy'),
                      _buildGameCard(context, "UNDERCOVER", "Secret Word Game", Icons.visibility_off, Colors.purple, false, '/play/undercover'),
                      _buildGameCard(context, "INFORMANT", "The Secret Ally", Icons.support_agent, Colors.teal, false, '/play/informant'),
                      _buildGameCard(context, "DONT GET CAUGHT", "Stealth Capture", Icons.camera, Colors.green, false, '/play/dont_get_caught'),
                    ]),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _glowOrb(double size, Color color) {
    return Container(
      width: size, 
      height: size, 
      decoration: BoxDecoration(
        shape: BoxShape.circle, 
        color: color, 
        boxShadow: [BoxShadow(color: color, blurRadius: 100, spreadRadius: 50)]
      )
    );
  }

  // --- NEW: COMMUNICATION ROOM CARD ---
  // Replace _buildCommRoomCard in home_screen.dart with this:
Widget _buildCommRoomEntry(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
    child: Row(
      children: [
        // CREATE BUTTON
        Expanded(
          child: _buildActionBtn(
            context, 
            "CREATE", 
            Icons.add_moderator, 
            () {
              String code = (10000000 + (DateTime.now().millisecondsSinceEpoch % 90000000)).toString();
              Navigator.pushNamed(context, '/comm_room', arguments: {'roomCode': code, 'isHost': true});
            }
          ),
        ),
        const SizedBox(width: 16),
        // JOIN BUTTON
        Expanded(
          child: _buildActionBtn(
  context, 
  "JOIN", 
  Icons.qr_code_scanner, 
  () => _showJoinCommsDialog(context), // 👈 New Dialog
),

// ... Add this method to HomeScreen class ...
        ),
      ],
    ),
  );
}

Widget _buildActionBtn(BuildContext context, String label, IconData icon, VoidCallback onTap) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.blueAccent),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1)),
        ],
      ),
    ),
  );
}

  void _showJoinSheet(BuildContext context) {
      showModalBottomSheet(
        context: context,
        builder: (context) {
          TextEditingController codeController = TextEditingController();
          return Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Enter Room Code', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextField(
                  controller: codeController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Room Code',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    if (codeController.text.isNotEmpty) {
                      Navigator.pushNamed(context, '/comm_room', arguments: {'roomCode': codeController.text, 'isHost': false});
                    }
                  },
                  child: const Text('Join Room'),
                ),
              ],
            ),
          );
        },
      );
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
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03), 
              borderRadius: BorderRadius.circular(28), 
              border: Border.all(color: Colors.white.withOpacity(0.08), width: 1.5)
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12), 
                    decoration: BoxDecoration(color: accentColor.withOpacity(0.15), shape: BoxShape.circle), 
                    child: Icon(icon, color: accentColor, size: 28)
                  ),
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