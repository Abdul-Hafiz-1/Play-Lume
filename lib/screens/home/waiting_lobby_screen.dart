import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui';
import '../../services/firebase_service.dart' hide snackbarKey;
import '../../main.dart';

class WaitingLobbyScreen extends StatefulWidget {
  final String roomCode;
  final String gameId;
  final bool isHost;

  const WaitingLobbyScreen({
    super.key,
    required this.roomCode,
    required this.gameId,
    required this.isHost,
  });

  @override
  State<WaitingLobbyScreen> createState() => _WaitingLobbyScreenState();
}

class _WaitingLobbyScreenState extends State<WaitingLobbyScreen> {
  bool _hasExited = false;

  // --- 1. THE AUTO-NAVIGATOR ---
  void _handleNavigation(Map<String, dynamic> data) {
    // STOPS THE LOOP: If we already started exiting, stop everything
    if (_hasExited || !mounted) return;

    final String status = data['status'] ?? 'waiting';
    final String gamePhase = data['gamePhase'] ?? '';
    final List<dynamic> players = data['players'] ?? [];

    // Check if I was kicked
    bool iAmStillInRoom = players.any((p) => p['userId'] == firebaseService.userId);

    if (!iAmStillInRoom) {
      _hasExited = true; 
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
          snackbarKey.currentState?.showSnackBar(
            const SnackBar(content: Text("You were removed from the room.")),
          );
        }
      });
      return;
    }

    // Check if Game Started
    if (status == 'playing' && gamePhase.isNotEmpty) {
      // CRITICAL: Set this to true BEFORE the Navigator call to stop the loop
      _hasExited = true; 
      
      print("NAVIGATOR: Launching /play/${widget.gameId}...");

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          // Use pushNamedAndRemoveUntil to clear lobby from stack but keep Home
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/play/${widget.gameId}',
            (route) => route.settings.name == '/home',
            arguments: {'roomCode': widget.roomCode, 'gameId': widget.gameId},
          );
        }
      });
    }
  }

  // --- 2. THE KICK DIALOG ---
  void _showKickConfirmation(String targetUserId, String nickname) {
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: AlertDialog(
          backgroundColor: const Color(0xFF0E1329),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text("KICK $nickname?", 
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: const Text("They will be disconnected from the neural link.", 
            style: TextStyle(color: Colors.white60)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), 
              child: const Text("CANCEL")
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () {
                Navigator.pop(context);
                firebaseService.kickPlayer(widget.roomCode, targetUserId);
                HapticFeedback.vibrate();
              },
              child: const Text("KICK PLAYER"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF04060E),
      body: Stack(
        children: [
          // Ambient Glows
          Positioned(top: -100, left: -50, child: _glowOrb(300, Colors.blue.withOpacity(0.15))),
          Positioned(bottom: -100, right: -50, child: _glowOrb(300, Colors.purple.withOpacity(0.1))),

          SafeArea(
            child: StreamBuilder<DocumentSnapshot>(
              stream: firebaseService.getRoomStream(widget.roomCode.trim()),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.white)));
                
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(child: CircularProgressIndicator(color: Colors.blue));
                }

                final data = snapshot.data!.data() as Map<String, dynamic>;
                
                // Debug log status
                print("LOBBY_WATCHER: Status=${data['status']}, Phase=${data['gamePhase']}");

                // Trigger navigation check
                _handleNavigation(data); 

                final players = data['players'] as List<dynamic>;

                return Column(
                  children: [
                    _buildHeader(),
                    _buildRoomCodeDisplay(),
                    
                    const SizedBox(height: 40),
                    const Text(
                      "SYNCHRONIZING PLAYERS...",
                      style: TextStyle(
                        color: Colors.white24, 
                        fontSize: 10, 
                        letterSpacing: 3, 
                        fontWeight: FontWeight.bold
                      ),
                    ),

                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.all(24),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 1.1,
                        ),
                        itemCount: players.length,
                        itemBuilder: (context, index) {
                          final player = players[index] as Map<String, dynamic>;
                          return _buildPlayerCard(player);
                        },
                      ),
                    ),

                    _buildActionArea(players.length),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- UI COMPONENTS ---

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          Text(
            widget.gameId.replaceAll('_', ' ').toUpperCase(),
            style: const TextStyle(
              color: Colors.white, 
              fontWeight: FontWeight.bold, 
              fontSize: 18, 
              letterSpacing: 2
            ),
          ),
          const Icon(Icons.wifi_tethering, color: Colors.blueAccent, size: 24),
        ],
      ),
    );
  }

  Widget _buildRoomCodeDisplay() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            children: [
              const Text("INVITE CODE", 
                style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 2)),
              const SizedBox(height: 5),
              Text(
                widget.roomCode,
                style: const TextStyle(
                  color: Colors.white, 
                  fontSize: 38, 
                  fontWeight: FontWeight.w900, 
                  letterSpacing: 8
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerCard(Map<String, dynamic> player) {
    bool isPlayerHost = player['isHost'] ?? false;
    
    return GestureDetector(
      onLongPress: () {
        if (widget.isHost && !isPlayerHost) {
          HapticFeedback.heavyImpact();
          _showKickConfirmation(player['userId'], player['nickname']);
        }
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: isPlayerHost ? Colors.blue.withOpacity(0.15) : Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isPlayerHost ? Colors.blue.withOpacity(0.4) : Colors.white.withOpacity(0.08),
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isPlayerHost)
                   const Padding(
                     padding: EdgeInsets.only(bottom: 8.0),
                     child: Icon(Icons.stars, color: Colors.blue, size: 16),
                   ),
                CircleAvatar(
                  radius: 25,
                  backgroundColor: isPlayerHost ? Colors.blue : Colors.white10,
                  child: Text(
                    player['nickname'][0].toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  player['nickname'].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white, 
                    fontSize: 12, 
                    fontWeight: FontWeight.w800, 
                    letterSpacing: 1
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  isPlayerHost ? "CAPTAIN" : "PLAYER",
                  style: TextStyle(
                    color: isPlayerHost ? Colors.blue : Colors.white24, 
                    fontSize: 8, 
                    fontWeight: FontWeight.bold
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionArea(int playerCount) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: widget.isHost
          ? ElevatedButton(
              onPressed: () async {
                print("DEBUG: Initialize Button Pressed!");
                HapticFeedback.mediumImpact();
                
                if (firebaseService.userId == null) {
                  print("DEBUG: Firebase userId is NULL!");
                  return;
                }

                try {
                  print("DEBUG: Calling startGame for room: ${widget.roomCode}");
                  await firebaseService.startGame(widget.roomCode, widget.gameId);
                  print("DEBUG: startGame execution finished.");
                } catch (e) {
                  print("DEBUG: Catch block caught: $e");
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                minimumSize: const Size(double.infinity, 64),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 10,
                shadowColor: Colors.blue.withOpacity(0.5),
              ),
              child: const Text(
                "INITIALIZE MISSION",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2),
              ),
            )
          : Column(
              children: [
                const SizedBox(width: 20, height: 20, 
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white24)),
                const SizedBox(height: 15),
                Text(
                  "WAITING FOR CAPTAIN TO START ($playerCount PLAYERS CONNECTED)",
                  style: const TextStyle(
                    color: Colors.white24, 
                    fontSize: 9, 
                    letterSpacing: 1.5, 
                    fontWeight: FontWeight.bold
                  ),
                  textAlign: TextAlign.center,
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
        boxShadow: [BoxShadow(color: color, blurRadius: 100, spreadRadius: 40)],
      ),
    );
  }
}