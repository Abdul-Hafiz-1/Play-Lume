import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../../models/game_model.dart';
import '../../services/firebase_service.dart' hide snackbarKey; // To avoid ambiguity with main.dart
import '../../main.dart'; // To access snackbarKey

class GameSelectionLobbyScreen extends StatefulWidget {
  final Game game;
  const GameSelectionLobbyScreen({super.key, required this.game});

  @override
  State<GameSelectionLobbyScreen> createState() => _GameSelectionLobbyScreenState();
}

class _GameSelectionLobbyScreenState extends State<GameSelectionLobbyScreen> {
  bool _isProcessing = false;

  // 1. HOST LOGIC: Connects to Firebase to create a session
  void _handleHostRoom() async {
    setState(() => _isProcessing = true);
    HapticFeedback.heavyImpact();

    try {
      // Calls your Firebase service to generate a unique room code
      final String? roomCode = await firebaseService.createRoom(widget.game.id);

      if (mounted && roomCode != null) {
        Navigator.pushNamed(context, '/waiting_lobby', arguments: {
          'roomCode': roomCode,
          'gameId': widget.game.id,
          'isHost': true,
        });
      }
    } catch (e) {
      snackbarKey.currentState?.showSnackBar(
        SnackBar(content: Text("Error creating room: $e")),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // 2. JOIN LOGIC: Opens the advanced glassmorphic options sheet
  void _showJoinOptions() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildJoinOptionsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF04060E),
      body: Stack(
        children: [
          // Background Glow
          Positioned(top: -50, right: -50, child: _glowOrb(200, Colors.blue.withOpacity(0.2))),
          Positioned(bottom: -50, left: -50, child: _glowOrb(250, Colors.purple.withOpacity(0.15))),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    widget.game.name.toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 2),
                  ),
                  const Text("MULTIPLAYER LOBBY", style: TextStyle(color: Colors.white38, fontSize: 12, letterSpacing: 4)),
                  
                  const Spacer(),

                  // The "Action Center"
                  _buildLobbyActionCard(
                    title: "HOST SERVER",
                    subtitle: "Generate a room code and wait for players",
                    icon: Icons.hub_rounded,
                    color: const Color(0xFF3B82F6),
                    onTap: _isProcessing ? () {} : _handleHostRoom,
                    showLoading: _isProcessing,
                  ),
                  const SizedBox(height: 20),
                  _buildLobbyActionCard(
                    title: "JOIN SESSION",
                    subtitle: "Scan QR, use NFC, or enter a Code",
                    icon: Icons.qr_code_scanner_rounded,
                    color: const Color(0xFFEC4899),
                    onTap: _showJoinOptions,
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- JOIN OPTIONS SHEET ---
  Widget _buildJoinOptionsSheet() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
          decoration: BoxDecoration(
            color: const Color(0xFF0E1329).withOpacity(0.8),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 25),
              const Text("HOW DO YOU WANT TO JOIN?", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              const SizedBox(height: 30),
              
              _joinOptionTile(Icons.keyboard_rounded, "Manual Code", "Type the 6-digit ID", () {}),
              _joinOptionTile(Icons.qr_code_2_rounded, "QR Scanner", "Point camera at host's screen", () {}),
              _joinOptionTile(Icons.sensors_rounded, "Proximity Join", "Hold phones near each other (NFC)", () {}),
              _joinOptionTile(Icons.wifi_tethering_rounded, "Local Discovery", "Find servers on your Wi-Fi", () {}),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _joinOptionTile(IconData icon, String title, String sub, VoidCallback onTap) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 10),
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white70),
      ),
      title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      subtitle: Text(sub, style: const TextStyle(color: Colors.white38, fontSize: 12)),
      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 14),
      onTap: onTap,
    );
  }

  // --- REUSABLE UI COMPONENTS ---
  Widget _glowOrb(double size, Color color) {
    return Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: color, boxShadow: [BoxShadow(color: color, blurRadius: 100, spreadRadius: 40)]));
  }

  Widget _buildLobbyActionCard({required String title, required String subtitle, required IconData icon, required Color color, required VoidCallback onTap, bool showLoading = false}) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: color.withOpacity(0.3), width: 1.5),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                  child: showLoading 
                    ? const SizedBox(width: 32, height: 32, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Icon(icon, color: color, size: 32),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}