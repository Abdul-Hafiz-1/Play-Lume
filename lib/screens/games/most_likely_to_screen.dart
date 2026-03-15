import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart'; 
import 'package:flutter/services.dart';

import '../../services/firebase_service.dart';
import '../../models/game_model.dart';

class MostLikelyToScreen extends StatefulWidget {
  final String roomCode;
  final String gameId;

  const MostLikelyToScreen({super.key, required this.roomCode, required this.gameId});

  @override
  State<MostLikelyToScreen> createState() => _MostLikelyToScreenState();
}

class _MostLikelyToScreenState extends State<MostLikelyToScreen> {
  String? _selectedPlayerId;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF04060E),
      body: Stack(
        children: [
          // Ambient Glows (Consistent with Sync/Liar games)
          Positioned(top: -150, left: -50, child: _glowOrb(400, Colors.blueAccent.withOpacity(0.1))),
          Positioned(bottom: -150, right: -50, child: _glowOrb(400, Colors.purpleAccent.withOpacity(0.05))),
          
          SafeArea(
            child: StreamBuilder<DocumentSnapshot>(
              stream: firebaseService.getRoomStream(widget.roomCode),
              builder: (context, snapshot) {
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
                }

                final roomData = snapshot.data!.data() as Map<String, dynamic>;
                final String currentUserId = firebaseService.userId ?? '';
                final List<dynamic> players = roomData['players'] ?? [];
                final Map<String, dynamic>? me = players.firstWhereOrNull((p) => p['userId'] == currentUserId);

                if (me == null) return const Center(child: Text("RECONNECTING...", style: TextStyle(color: Colors.white24)));

                final String phase = roomData['gamePhase'] ?? 'votingMLT';

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      _buildHeader(roomData['currentRound'] ?? 1, roomData['totalRounds'] ?? 5, me['score'] ?? 0),
                      const SizedBox(height: 20),
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 500),
                          child: _buildPhaseUI(phase, roomData, me, players),
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

  Widget _buildHeader(int round, int total, int score) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("SOCIAL PROFILING", style: TextStyle(color: Colors.white24, fontSize: 10, letterSpacing: 2)),
            Text("ROUND $round/$total", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text("CREDITS", style: TextStyle(color: Colors.white24, fontSize: 10, letterSpacing: 2)),
            Text("$score", style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.w900, fontSize: 18)),
          ],
        ),
      ],
    );
  }

  Widget _buildPhaseUI(String phase, Map<String, dynamic> roomData, Map<String, dynamic> me, List<dynamic> players) {
    switch (phase) {
      case 'votingMLT': return _buildVotingPhase(roomData, me, players);
      case 'revealMLT': return _buildRevealPhase(roomData, players);
      case 'gameOver': return _buildGameOver(players);
      default: return const Center(child: CircularProgressIndicator());
    }
  }

  // --- PHASE 1: VOTING (Neural Select) ---
  Widget _buildVotingPhase(Map<String, dynamic> roomData, Map<String, dynamic> me, List<dynamic> players) {
    bool hasVoted = me['votedFor'] != null;
    int round = roomData['currentRound'] ?? 1;

    if (hasVoted) return _buildStatusCard("VOTE ENCRYPTED", "WAITING FOR SOCIAL CONSENSUS...", Icons.radar, Colors.blueAccent);

    return Column(
      key: ValueKey("MLT_Input_Round_$round"), // Auto-reset selection every round
      children: [
        const SizedBox(height: 20),
        // Glassmorphism Question Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            children: [
              const Text("INQUIRY", style: TextStyle(color: Colors.blueAccent, letterSpacing: 4, fontSize: 10, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Text(
                roomData['currentQuestionText']?.toUpperCase() ?? "LOADING...",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.2),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
        Expanded(
          child: ListView.builder(
            itemCount: players.length,
            itemBuilder: (context, index) {
              final p = players[index];
              bool isSelected = _selectedPlayerId == p['userId'];
              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _selectedPlayerId = p['userId']);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blueAccent.withOpacity(0.1) : Colors.white.withOpacity(0.02),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: isSelected ? Colors.blueAccent : Colors.white.withOpacity(0.05)),
                  ),
                  child: Row(
                    children: [
                      Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_off, 
                           color: isSelected ? Colors.blueAccent : Colors.white24, size: 20),
                      const SizedBox(width: 16),
                      Text(p['nickname'].toUpperCase(), 
                           style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, letterSpacing: 1)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        _buildActionBtn("LOCK IN NOMINATION", () async {
          if (_selectedPlayerId == null) return;
          setState(() => _isLoading = true);
          await firebaseService.submitVoteMLT(widget.roomCode, firebaseService.userId!, _selectedPlayerId!);
          setState(() => _isLoading = false);
        }),
      ],
    );
  }

  // --- PHASE 2: REVEAL (Data Breakdown) ---
  Widget _buildRevealPhase(Map<String, dynamic> roomData, List<dynamic> players) {
    bool isHost = roomData['hostId'] == firebaseService.userId;
    var sorted = List.from(players);
    sorted.sort((a, b) => (b['votesReceived'] ?? 0).compareTo(a['votesReceived'] ?? 0));
    int maxVotes = sorted.first['votesReceived'] ?? 0;
    String winnerNames = sorted.where((p) => p['votesReceived'] == maxVotes).map((p) => p['nickname']).join(" & ");

    return Column(
      children: [
        const SizedBox(height: 20),
        const Text("GROUP CONSENSUS", style: TextStyle(color: Colors.white24, letterSpacing: 4, fontSize: 10)),
        const SizedBox(height: 30),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.blueAccent.withOpacity(0.05),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.blueAccent.withOpacity(0.3), width: 2),
          ),
          child: Column(
            children: [
              Text(winnerNames.toUpperCase(), textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 1)),
              const SizedBox(height: 12),
              Text("$maxVotes VOTES RECEIVED", style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 2)),
            ],
          ),
        ),
        const SizedBox(height: 40),
        const Text("DISTRIBUTION LOGS", style: TextStyle(color: Colors.white24, fontSize: 10, letterSpacing: 2)),
        const SizedBox(height: 20),
        Expanded(
          child: ListView.builder(
            itemCount: players.length,
            itemBuilder: (context, index) {
              final p = players[index];
              double percent = players.length == 0 ? 0 : (p['votesReceived'] ?? 0) / players.length;
              return Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(p['nickname'].toUpperCase(), style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                        Text("${p['votesReceived'] ?? 0}", style: const TextStyle(color: Colors.blueAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: percent,
                        backgroundColor: Colors.white.withOpacity(0.05),
                        color: Colors.blueAccent,
                        minHeight: 4,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        if (isHost) _buildActionBtn("CONTINUE", () async {
          if ((roomData['currentRound'] ?? 1) >= (roomData['totalRounds'] ?? 5)) {
            await firebaseService.nextPhase(widget.roomCode, 'gameOver');
          } else {
            await firebaseService.nextRound(widget.roomCode, widget.gameId);
          }
        }),
      ],
    );
  }

  // --- UI HELPERS ---

  Widget _buildActionBtn(String label, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: _isLoading ? null : onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueAccent,
        minimumSize: const Size(double.infinity, 60),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Text(label, style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.white)),
    );
  }

  Widget _buildStatusCard(String title, String sub, IconData icon, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 60),
        const SizedBox(height: 20),
        Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, letterSpacing: 2)),
        const SizedBox(height: 8),
        Text(sub, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white24, fontSize: 10)),
      ],
    );
  }

  Widget _glowOrb(double size, Color color) {
    return Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: color, boxShadow: [BoxShadow(color: color, blurRadius: 100, spreadRadius: 40)]));
  }

  Widget _buildGameOver(List<dynamic> players) {
    players.sort((a, b) => (b['score'] ?? 0).compareTo(a['score'] ?? 0));
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.emoji_events, color: Colors.amber, size: 80),
        const SizedBox(height: 20),
        const Text("FINAL PROFILE", style: TextStyle(color: Colors.white24, letterSpacing: 4)),
        const SizedBox(height: 20),
        Expanded(
          child: ListView.builder(
            itemCount: players.length,
            itemBuilder: (context, index) => ListTile(
              title: Text(players[index]['nickname'].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              trailing: Text("${players[index]['score']} PTS", style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
        _buildActionBtn("TERMINATE SESSION", () => Navigator.popUntil(context, ModalRoute.withName('/home'))),
      ],
    );
  }
}