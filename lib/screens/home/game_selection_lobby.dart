import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:ui';
import '../../models/game_model.dart';
import '../../services/firebase_service.dart' hide snackbarKey; 
import '../../main.dart';

class GameSelectionLobbyScreen extends StatefulWidget {
  final Game game;
  const GameSelectionLobbyScreen({super.key, required this.game});

  @override
  State<GameSelectionLobbyScreen> createState() => _GameSelectionLobbyScreenState();
}

class _GameSelectionLobbyScreenState extends State<GameSelectionLobbyScreen> {
  bool _isProcessing = false;
  bool _isHostDashboard = false; 
  String? _activeRoomCode;

  // --- 1. HOST LOGIC ---
  void _handleHostRoom() async {
    setState(() => _isProcessing = true);
    HapticFeedback.heavyImpact();

    try {
      final String? roomCode = await firebaseService.createRoom(widget.game.id);
      if (mounted && roomCode != null) {
        setState(() {
          _activeRoomCode = roomCode;
          _isHostDashboard = true;
          _isProcessing = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isProcessing = false);
      snackbarKey.currentState?.showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  // --- 2. JOIN LOGIC (QR SCAN) ---
  void _openQRScanner() {
    Navigator.pop(context); // Close the bottom sheet first
    showDialog(
      context: context,
      builder: (context) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text("Scan Host QR"), 
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: MobileScanner(
          onDetect: (capture) {
            final List<Barcode> barcodes = capture.barcodes;
            if (barcodes.isNotEmpty) {
              final String? code = barcodes.first.rawValue;
              if (code != null) {
                Navigator.pop(context); // Close scanner
                _joinRoomWithCode(code);
              }
            }
          },
        ),
      ),
    );
  }

  void _joinRoomWithCode(String code) async {
    setState(() => _isProcessing = true);
    bool success = await firebaseService.joinGameRoom(code, firebaseService.nickname ?? "Player");
    
    if (success && mounted) {
      Navigator.pushNamed(context, '/waiting_lobby', arguments: {
        'roomCode': code,
        'gameId': widget.game.id,
        'isHost': false,
      });
    } else {
      if (mounted) setState(() => _isProcessing = false);
      snackbarKey.currentState?.showSnackBar(const SnackBar(content: Text("Invalid Room Code")));
    }
  }

  // --- PLAYER MANAGEMENT ---
  void _kickPlayer(String playerUserId) async {
    // This calls the Firebase logic we discussed earlier
    // await firebaseService.kickPlayer(_activeRoomCode!, playerUserId);
    HapticFeedback.vibrate();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF04060E),
      body: Stack(
        children: [
          Positioned(top: -50, right: -50, child: _glowOrb(200, Colors.blue.withOpacity(0.2))),
          Positioned(bottom: -50, left: -50, child: _glowOrb(250, Colors.purple.withOpacity(0.15))),
          
          SafeArea(
            child: _isHostDashboard ? _buildHostDashboard() : _buildInitialSelection(),
          ),
        ],
      ),
    );
  }

  // --- VIEW: INITIAL SELECTION ---
  Widget _buildInitialSelection() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white), onPressed: () => Navigator.pop(context)),
          const SizedBox(height: 20),
          Text(widget.game.name.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 2)),
          const Text("MULTIPLAYER LOBBY", style: TextStyle(color: Colors.white38, fontSize: 12, letterSpacing: 4)),
          const Spacer(),
          _buildLobbyActionCard(
            title: "HOST SERVER",
            subtitle: "Create a room and get a QR code",
            icon: Icons.hub_rounded,
            color: const Color(0xFF3B82F6),
            onTap: _isProcessing ? () {} : _handleHostRoom,
            showLoading: _isProcessing,
          ),
          const SizedBox(height: 20),
          _buildLobbyActionCard(
            title: "JOIN SESSION",
            subtitle: "Scan a QR or enter a code",
            icon: Icons.qr_code_scanner_rounded,
            color: const Color(0xFFEC4899),
            onTap: _showJoinOptions,
          ),
          const Spacer(),
        ],
      ),
    );
  }

  // --- VIEW: HOST DASHBOARD ---
  Widget _buildHostDashboard() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => setState(() => _isHostDashboard = false)),
              const Text("SERVER ACTIVE", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, letterSpacing: 2)),
              const Opacity(opacity: 0, child: Icon(Icons.close)),
            ],
          ),
          const SizedBox(height: 30),
          
          // QR Code Generator - Visual Centerpiece
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05), 
              borderRadius: BorderRadius.circular(32), 
              border: Border.all(color: Colors.white10)
            ),
            child: QrImageView(
              data: _activeRoomCode!,
              version: QrVersions.auto,
              size: 220.0,
              eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.white),
              dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Colors.white),
            ),
          ),
          const SizedBox(height: 20),
          Text("ROOM CODE: $_activeRoomCode", style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: 2)),
          
          const Divider(height: 60, color: Colors.white10),
          const Align(alignment: Alignment.centerLeft, child: Text("PLAYERS JOINING", style: TextStyle(color: Colors.white38, fontSize: 12, letterSpacing: 1.5))),
          
          Expanded(
            child: StreamBuilder(
              stream: firebaseService.getRoomStream(_activeRoomCode!),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                var roomData = snapshot.data!.data() as Map<String, dynamic>;
                var players = roomData['players'] as List<dynamic>;
                
                return ListView.builder(
                  itemCount: players.length,
                  itemBuilder: (context, index) {
                    var player = players[index] as Map<String, dynamic>;
                    bool isHost = player['userId'] == firebaseService.userId;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: isHost ? Colors.blue : Colors.white10, 
                        child: Text(player['nickname'][0].toUpperCase(), style: const TextStyle(color: Colors.white))
                      ),
                      title: Text(player['nickname'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                      trailing: isHost 
                        ? const Text("YOU", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold))
                        : IconButton(icon: const Icon(Icons.person_remove, color: Colors.redAccent, size: 22), onPressed: () => _kickPlayer(player['userId'])),
                    );
                  },
                );
              },
            ),
          ),
          
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/waiting_lobby', arguments: {'roomCode': _activeRoomCode, 'gameId': widget.game.id, 'isHost': true}),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 64), 
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
            ),
            child: const Text("LAUNCH WAITING ROOM", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  void _showJoinOptions() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildJoinOptionsSheet(),
    );
  }

  Widget _buildJoinOptionsSheet() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
          decoration: BoxDecoration(
            color: const Color(0xFF0E1329).withOpacity(0.9), 
            border: Border.all(color: Colors.white.withOpacity(0.1))
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 25),
              const Text("JOIN MISSION", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 30),
              _joinOptionTile(Icons.qr_code_2_rounded, "Scan QR Code", "Point camera at host's device", _openQRScanner),
              _joinOptionTile(Icons.keyboard_rounded, "Manual Entry", "Enter 6-digit room code", _showManualInputDialog),
            ],
          ),
        ),
      ),
    );
  }

  void _showManualInputDialog() {
    Navigator.pop(context); // Close sheet
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          backgroundColor: const Color(0xFF0E1329),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text("Enter Room Code", style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: controller, 
            autofocus: true,
            keyboardType: TextInputType.text,
            style: const TextStyle(color: Colors.white, fontSize: 24, letterSpacing: 4),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: "XXXXXX",
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.1)),
              enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.blue)),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
            ElevatedButton(
              onPressed: () { Navigator.pop(context); _joinRoomWithCode(controller.text.toUpperCase()); }, 
              child: const Text("JOIN"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _joinOptionTile(IconData icon, String title, String sub, VoidCallback onTap) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), shape: BoxShape.circle),
        child: Icon(icon, color: Colors.blueAccent),
      ),
      title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      subtitle: Text(sub, style: const TextStyle(color: Colors.white38, fontSize: 12)),
      onTap: onTap,
    );
  }

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
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(30), border: Border.all(color: color.withOpacity(0.3), width: 1.5)),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                  child: showLoading ? const SizedBox(width: 32, height: 32, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Icon(icon, color: color, size: 32),
                ),
                const SizedBox(width: 20),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)), Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 12))])),
              ],
            ),
          ),
        ),
      ),
    );
  }
}