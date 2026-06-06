import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui';
import '../../services/firebase_service.dart' hide snackbarKey;
import '../../main.dart';
import '../../models/game_model.dart';
import '../../core/navigation.dart';

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

  
  bool _isStarting = false; // Add this at the top with your rounds variable
  static int _selectedRounds = 5; // Default value

  // --- 1. THE AUTO-NAVIGATOR ---
  void _handleNavigation(Map<String, dynamic> data) {
  // 1. HARD STOP: Check the gatekeeper immediately
  if (_hasExited || !mounted) return;

  final String status = data['status'] ?? 'waiting';
  final String gamePhase = data['gamePhase'] ?? '';
  final List<dynamic> players = data['players'] ?? [];

  // Check if I was kicked
  bool iAmStillInRoom = players.any((p) => p['userId'] == firebaseService.userId);

  if (!iAmStillInRoom) {
    _hasExited = true; // Lock navigation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        AppNavigation.goHome(context);
        snackbarKey.currentState?.showSnackBar(
          const SnackBar(content: Text("You were removed from the room.")),
        );
      }
    });
    return;
  }

  // 2. CHECK STATUS: Only move if status is 'playing' AND we have a phase
  if (status == 'playing' && gamePhase.isNotEmpty) {
    
    // 🚨 THE FIX: Double-lock before the async gap
    _hasExited = true; 
    
    print("NAVIGATOR: Redirecting to game... Rounds logic should be locked now.");

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Ensure we are using the correct route path
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
    double screenWidth = MediaQuery.of(context).size.width;
  int crossAxisCount = (screenWidth / 160).floor().clamp(2, 6);
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

                    _buildRoundPicker(),
                    
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
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount, // Use the dynamic variable here
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 1.0, // Keeps the tiles square
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



Widget _buildRoundPicker() {
  if (!widget.isHost) return const SizedBox.shrink();

  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.05),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white10),
    ),
    child: Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("TOTAL ROUNDS", style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 2)),
            Text("$_selectedRounds", style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        Slider(
          value: _selectedRounds.toDouble(),
          min: 3,
          max: 15,
          divisions: 12,
          activeColor: Colors.blueAccent,
          inactiveColor: Colors.white10,
          onChanged: (value) {
            setState(() {
              _selectedRounds = value.toInt();
            });
            HapticFeedback.selectionClick();
          },
        ),
      ],
    ),
  );
}

  void _showInfoBottomSheet(BuildContext context, Game game) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.75,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF0E1329).withOpacity(0.9),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              border: Border.all(color: Colors.blueAccent.withOpacity(0.3), width: 1.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 16),
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.info_outline_rounded, color: Colors.blueAccent, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "MISSION BRIEFING",
                              style: TextStyle(
                                color: Colors.blueAccent,
                                fontSize: 10,
                                letterSpacing: 3,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace'
                              ),
                            ),
                            Text(
                              game.name.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white54),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(color: Colors.white10, height: 1),
                Flexible(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "OBJECTIVE",
                          style: TextStyle(
                            color: Colors.blueAccent,
                            fontSize: 12,
                            letterSpacing: 2,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace'
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          game.description,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          "OPERATIONAL MANUAL & RULES",
                          style: TextStyle(
                            color: Colors.blueAccent,
                            fontSize: 12,
                            letterSpacing: 2,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace'
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.02),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withOpacity(0.05)),
                          ),
                          child: Text(
                            game.instructions,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              height: 1.6,
                              fontFamily: 'Quicksand',
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            const Icon(Icons.people_outline_rounded, color: Colors.blueAccent, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              "PERSONNEL REQUIRED: ${game.minPlayers}-${game.maxPlayers} OPERATIVES",
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 11,
                                letterSpacing: 1.5,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace'
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    final Game? game = games.any((g) => g.id == widget.gameId) ? games.firstWhere((g) => g.id == widget.gameId) : null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
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
          IconButton(
            icon: const Icon(Icons.info_outline_rounded, color: Colors.blueAccent, size: 24),
            onPressed: () {
              if (game != null) {
                _showInfoBottomSheet(context, game);
              }
            },
          ),
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
    final Game? game = games.any((g) => g.id == widget.gameId) ? games.firstWhere((g) => g.id == widget.gameId) : null;
    final int minP = game?.minPlayers ?? 3;
    final int maxP = game?.maxPlayers ?? 8;
    final bool canStart = playerCount >= minP && playerCount <= maxP;

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: widget.isHost
          ? ElevatedButton(
              onPressed: (_isStarting || !canStart) ? null : () async {
              setState(() => _isStarting = true);
              HapticFeedback.mediumImpact();
              
              try {
                print("🚀 INITIALIZING: Room ${widget.roomCode} with $_selectedRounds rounds");
                
                // ONLY CALL THIS ONCE and pass the rounds variable
                await firebaseService.startGame(
                  widget.roomCode, 
                  widget.gameId, 
                  hostChosenRounds: _selectedRounds
                );
                
                print("✅ START_GAME command sent successfully.");
              } catch (e) {
                print("❌ LOBBY_ERROR: $e");
                if (mounted) setState(() => _isStarting = false);
              }
            },
              style: ElevatedButton.styleFrom(
                backgroundColor: canStart ? const Color(0xFF3B82F6) : Colors.white.withOpacity(0.05),
                disabledBackgroundColor: Colors.white.withOpacity(0.05),
                minimumSize: const Size(double.infinity, 64),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: canStart ? 10 : 0,
                shadowColor: canStart ? Colors.blue.withOpacity(0.5) : Colors.transparent,
              ),
              child: Text(
                canStart 
                    ? "INITIALIZE MISSION" 
                    : "LOBBY REQ: $playerCount/$minP PLAYERS",
                style: TextStyle(
                  color: canStart ? Colors.white : Colors.white30, 
                  fontWeight: FontWeight.bold, 
                  letterSpacing: 2
                ),
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
