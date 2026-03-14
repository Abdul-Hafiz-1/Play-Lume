import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart'; 
import 'dart:ui'; // Required for ImageFilter

import '../../services/firebase_service.dart';
import '../../models/game_model.dart';

class SyncGameScreen extends StatefulWidget {
  final String roomCode;
  final String gameId;

  const SyncGameScreen({super.key, required this.roomCode, required this.gameId});

  @override
  State<SyncGameScreen> createState() => _SyncGameScreenState();
}

class _SyncGameScreenState extends State<SyncGameScreen> {
  final TextEditingController _answerController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentGame = games.firstWhere((g) => g.id == widget.gameId, orElse: () => games.first);
    
    return Scaffold(
      backgroundColor: const Color(0xFF04060E),
      body: Stack(
        children: [
          // Ambient Glows for the "Neural Link" vibe
          Positioned(top: -150, left: -50, child: _glowOrb(400, Colors.blueAccent.withOpacity(0.1))),
          Positioned(bottom: -150, right: -50, child: _glowOrb(400, Colors.purpleAccent.withOpacity(0.05))),

          SafeArea(
            child: StreamBuilder<DocumentSnapshot>(
              stream: firebaseService.getRoomStream(widget.roomCode),
              builder: (context, snapshot) {
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(child: CircularProgressIndicator(color: Colors.blue));
                }

                final roomData = snapshot.data!.data() as Map<String, dynamic>;
                final String currentUserId = firebaseService.userId ?? '';
                final String gamePhase = roomData['gamePhase'] ?? 'answering'; 

                final List<dynamic> players = roomData['players'] ?? [];
                final Map<String, dynamic>? currentPlayer = players.firstWhereOrNull((p) => p['userId'] == currentUserId);

                if (currentPlayer == null) return const Center(child: Text("Reconnecting...", style: TextStyle(color: Colors.white)));

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      _buildHeader(currentGame.name.toUpperCase()),
                      const SizedBox(height: 20),
                      _buildTopStats(widget.roomCode, currentPlayer['score'] ?? 0),
                      const SizedBox(height: 24),
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 500),
                          child: _buildPhaseUI(gamePhase, roomData, currentPlayer),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.wifi_tethering, color: Colors.blueAccent, size: 20),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 4, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildPhaseUI(String phase, Map<String, dynamic> roomData, Map<String, dynamic> currentPlayer) {
    switch (phase) {
      case 'answering':
        return _buildAnsweringSyncUI(roomData, currentPlayer);
      case 'revealingAnswersSync':
        return _buildRevealingAnswersSyncUI(roomData, currentPlayer);
      case 'roundResults':
        return _buildRoundResultsSyncUI(roomData, currentPlayer);
      case 'gameOver':
        return _buildGameOverUI(context, roomData);
      default:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Colors.blueAccent),
              const SizedBox(height: 20),
              Text("Establishing Link: '$phase'...", style: const TextStyle(color: Colors.white38)),
            ],
          ),
        );
    }
  }

  // --- STATS HEADER ---
  Widget _buildTopStats(String code, int score) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("DATA STREAM", style: TextStyle(color: Colors.white24, fontSize: 9, letterSpacing: 1.5)),
                  Text(code, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.white)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text("SYNC RATE", style: TextStyle(color: Colors.white24, fontSize: 9, letterSpacing: 1.5)),
                  Text('$score', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.blueAccent)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- PHASE 1: ANSWERING (Neural Link Design) ---
  Widget _buildAnsweringSyncUI(Map<String, dynamic> roomData, Map<String, dynamic> currentPlayer) {
    String currentQuestion = roomData['currentQuestionText'] ?? 'INITIALIZING CATEGORY...';
    bool hasAnswered = currentPlayer['isReadyInSyncPhase'] ?? false;

    return SingleChildScrollView(
      child: Column(
        children: [
          _buildMinimalProgressBar(roomData['currentRound'] ?? 1, roomData['totalRounds'] ?? 5),
          const SizedBox(height: 40),
          
          // Glass-morphic Question Card
          ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  children: [
                    const Text("INPUT CATEGORY", 
                        style: TextStyle(color: Colors.blueAccent, letterSpacing: 4, fontSize: 10, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 24),
                    Text(
                      currentQuestion.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 28, 
                        fontWeight: FontWeight.w900, 
                        color: Colors.white,
                        letterSpacing: 1.2,
                        shadows: [Shadow(color: Colors.blueAccent, blurRadius: 15)]
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 50),

          if (!hasAnswered) ...[
            _buildNeuralTextField(),
            const SizedBox(height: 24),
            _buildNeonButton("SUBMIT TO NEURAL LINK", _submitAnswerSync),
          ] else 
            _buildLockedInState(),
        ],
      ),
    );
  }

  Widget _buildMinimalProgressBar(int current, int total) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (index) {
        bool isCurrent = index == current - 1;
        bool isPast = index < current - 1;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 4,
          width: isCurrent ? 30 : 12,
          decoration: BoxDecoration(
            color: isCurrent ? Colors.blueAccent : (isPast ? Colors.blueAccent.withOpacity(0.4) : Colors.white10),
            borderRadius: BorderRadius.circular(2),
            boxShadow: isCurrent ? [const BoxShadow(color: Colors.blueAccent, blurRadius: 8)] : [],
          ),
        );
      }),
    );
  }

  Widget _buildNeuralTextField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: TextField(
        controller: _answerController,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white, fontSize: 20, letterSpacing: 2),
        decoration: const InputDecoration(
          hintText: "TYPE YOUR RESPONSE...",
          hintStyle: TextStyle(color: Colors.white10, fontSize: 14, letterSpacing: 2),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 24),
        ),
      ),
    );
  }

  Widget _buildNeonButton(String text, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: _isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 65),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 10,
        shadowColor: Colors.blueAccent.withOpacity(0.5),
      ),
      child: _isLoading 
        ? const CircularProgressIndicator(color: Colors.white) 
        : Text(text, style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)),
    );
  }

  Widget _buildLockedInState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.greenAccent.withOpacity(0.02),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.greenAccent.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 40),
          const SizedBox(height: 16),
          const Text("RESPONSE ENCRYPTED", 
            style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.w900, letterSpacing: 3, fontSize: 12)),
          const SizedBox(height: 8),
          const Text("WAITING FOR OTHER DATA NODES...", 
            style: TextStyle(color: Colors.white24, fontSize: 10, letterSpacing: 1)),
        ],
      ),
    );
  }

  // --- PHASE 2: REVEALING ---
  Widget _buildRevealingAnswersSyncUI(Map<String, dynamic> roomData, Map<String, dynamic> currentPlayer) {
    List<dynamic> players = List<dynamic>.from(roomData['players'] ?? []);
    bool isHost = roomData['hostId'] == firebaseService.userId;

    Map<String, List<String>> groups = {};
    for (var p in players) {
      String ans = (p['answerSync'] ?? "No Answer").toString().toLowerCase().trim();
      if(ans.isNotEmpty) groups.putIfAbsent(ans, () => []).add(p['nickname']);
    }

    return Column(
      children: [
        const Text("NEURAL COHERENCE", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueAccent, letterSpacing: 4)),
        const SizedBox(height: 24),
        Expanded(
          child: ListView(
            children: groups.entries.map((entry) {
              bool isMatch = entry.value.length > 1;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isMatch ? Colors.green.withOpacity(0.08) : Colors.white.withOpacity(0.02),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isMatch ? Colors.greenAccent.withOpacity(0.3) : Colors.white10),
                ),
                child: Row(
                  children: [
                    Expanded(child: Text('"${entry.key.toUpperCase()}"', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.white, letterSpacing: 1))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isMatch ? Colors.greenAccent.withOpacity(0.1) : Colors.white10,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text("${entry.value.length} NODES", style: TextStyle(color: isMatch ? Colors.greenAccent : Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        if (isHost)
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: _buildNeonButton("CONTINUE TO LOGS", () => firebaseService.nextPhase(widget.roomCode, 'roundResults')),
          ),
      ],
    );
  }

  // --- PHASE 3: ROUND RESULTS ---
  Widget _buildRoundResultsSyncUI(Map<String, dynamic> roomData, Map<String, dynamic> currentPlayer) {
    List<dynamic> players = List<dynamic>.from(roomData['players'] ?? []);
    bool isHost = roomData['hostId'] == firebaseService.userId;
    players.sort((a, b) => (b['score'] ?? 0).compareTo(a['score'] ?? 0));

    return Column(
      children: [
        const Text("SYNC RANKINGS", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueAccent, letterSpacing: 4)),
        const SizedBox(height: 24),
        Expanded(
          child: ListView.builder(
            itemCount: players.length,
            itemBuilder: (context, index) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.02),
                borderRadius: BorderRadius.circular(15),
              ),
              child: ListTile(
                leading: Text("#${index + 1}", style: const TextStyle(color: Colors.white24, fontWeight: FontWeight.bold)),
                title: Text(players[index]['nickname'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                trailing: Text("${players[index]['score']} PTS", style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.w900)),
              ),
            ),
          ),
        ),
        if (isHost)
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: _buildNeonButton(
              (roomData['currentRound'] ?? 1) >= (roomData['totalRounds'] ?? 3) ? "FINAL RESULTS" : "NEXT ROUND",
              () {
                if ((roomData['currentRound'] ?? 1) >= (roomData['totalRounds'] ?? 3)) {
                  firebaseService.nextPhase(widget.roomCode, 'gameOver');
                } else {
                  firebaseService.nextRound(widget.roomCode, widget.gameId);
                }
              },
            ),
          ),
      ],
    );
  }

  // --- PHASE 4: GAME OVER ---
  Widget _buildGameOverUI(BuildContext context, Map<String, dynamic> roomData) {
    List<dynamic> players = List<dynamic>.from(roomData['players'] ?? []);
    players.sort((a, b) => (b['score'] ?? 0).compareTo(a['score'] ?? 0));
    final winner = players.first;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.emoji_events_outlined, size: 80, color: Colors.amber),
        const SizedBox(height: 24),
        const Text("NEURAL SYNC COMPLETE", style: TextStyle(color: Colors.white38, letterSpacing: 4, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(winner['nickname'].toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.w900, letterSpacing: 2)),
        const Text("HIGHEST COHERENCE RATE", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(height: 60),
        _buildNeonButton("DISCONNECT LINK", () => Navigator.popUntil(context, ModalRoute.withName('/home'))),
      ],
    );
  }

  // Helper for the ambient glow effect
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

  Future<void> _submitAnswerSync() async {
    if (_answerController.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await firebaseService.submitAnswerSync(
        widget.roomCode,
        firebaseService.userId ?? '',
        _answerController.text.trim(),
      );
      _answerController.clear();
    } catch (e) {
      print("Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}