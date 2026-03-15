import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'dart:ui';
import 'package:flutter/services.dart';

import '../../services/firebase_service.dart';
import '../../models/game_model.dart';

class GuessTheLiarGameScreen extends StatefulWidget {
  final String roomCode;
  final String gameId;

  const GuessTheLiarGameScreen({super.key, required this.roomCode, required this.gameId});

  @override
  State<GuessTheLiarGameScreen> createState() => _GuessTheLiarGameScreenState();
}

class _GuessTheLiarGameScreenState extends State<GuessTheLiarGameScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _answerController = TextEditingController();
  bool _isLoading = false;
  String? _selectedPlayerToVote;
  bool _isQuestionRevealed = false;

  // Scanner Animation variables
  late AnimationController _scannerController;
  late Animation<double> _scannerAnimation;

  @override
  void initState() {
    super.initState();
    _scannerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _scannerAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _scannerController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _answerController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF04060E),
      body: Stack(
        children: [
          // Ambient Glows
          Positioned(top: -150, left: -50, child: _glowOrb(400, Colors.blueAccent.withOpacity(0.1))),
          Positioned(bottom: -150, right: -50, child: _glowOrb(400, Colors.redAccent.withOpacity(0.05))),
          
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

                final String phase = roomData['gamePhase'] ?? 'answering';

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      _buildHeader(roomData['currentRound'] ?? 1, roomData['totalRounds'] ?? 5),
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

  Widget _buildHeader(int round, int total) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("MISSION STATUS", style: TextStyle(color: Colors.white24, fontSize: 10, letterSpacing: 2)),
            Text("ROUND $round/$total", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
          ],
        ),
        const Icon(Icons.security, color: Colors.redAccent, size: 24),
      ],
    );
  }

  Widget _buildPhaseUI(String phase, Map<String, dynamic> roomData, Map<String, dynamic> me, List<dynamic> players) {
    switch (phase) {
      case 'answering': return _buildAnsweringPhase(roomData, me);
      case 'discussing': return _buildDiscussingPhase(roomData, players);
      case 'voting': return _buildVotingPhase(roomData, players, me);
      case 'reveal': return _buildRevealPhase(roomData, players, me);
      case 'roundResults': return _buildRoundResults(roomData, players, me);
      case 'gameOver': return _buildGameOver(roomData, players);
      default: return const Center(child: CircularProgressIndicator());
    }
  }

  // --- PHASE 1: ANSWERING (Fixed Hold-to-Reveal & Scanner Animation) ---
  Widget _buildAnsweringPhase(Map<String, dynamic> roomData, Map<String, dynamic> me) {
    bool hasAnswered = (me['answer'] as String? ?? '').isNotEmpty;
    int round = roomData['currentRound'] ?? 1;

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 40),
          // HOLD TO VIEW INTEL
          GestureDetector(
            onLongPressStart: (_) {
              HapticFeedback.mediumImpact();
              setState(() => _isQuestionRevealed = true);
            },
            onLongPressEnd: (_) {
              setState(() => _isQuestionRevealed = false);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity,
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: _isQuestionRevealed ? Colors.blueAccent.withOpacity(0.1) : Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _isQuestionRevealed ? Colors.blueAccent : Colors.redAccent.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Text(_isQuestionRevealed ? "ACCESS GRANTED" : "HOLD TO DECRYPT INTEL", 
                    style: TextStyle(color: _isQuestionRevealed ? Colors.blueAccent : Colors.redAccent, letterSpacing: 4, fontSize: 10, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _isQuestionRevealed 
                      ? Text(
                          me['question']?.toUpperCase() ?? "", 
                          key: const ValueKey("intel_visible"),
                          textAlign: TextAlign.center, 
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.5)
                        )
                      : Icon(Icons.security, key: const ValueKey("intel_locked"), color: Colors.redAccent.withOpacity(0.5), size: 40),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
          if (!hasAnswered) ...[
            Container(
              key: ValueKey("GTL_Input_Round_$round"),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(20)),
              child: TextField(
                controller: _answerController,
                maxLines: 2,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(hintText: "TRANSMIT YOUR ALIBI...", hintStyle: TextStyle(color: Colors.white12), border: InputBorder.none, contentPadding: EdgeInsets.all(20)),
              ),
            ),
            const SizedBox(height: 30),
            
            // 🖐️ FINGERPRINT SCANNER SUBMIT
            GestureDetector(
              onLongPressStart: (_) {
                HapticFeedback.heavyImpact();
                _scannerController.repeat(reverse: true);
              },
              onLongPressEnd: (_) async {
                _scannerController.stop();
                _scannerController.reset();
                if (_answerController.text.trim().isEmpty) return;
                
                setState(() => _isLoading = true);
                HapticFeedback.vibrate();
                await firebaseService.submitAnswer(widget.roomCode, firebaseService.userId!, _answerController.text.trim());
                if (mounted) setState(() => _isLoading = false);
              },
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(25),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.blueAccent.withOpacity(0.5), width: 2),
                        ),
                        child: const Icon(Icons.fingerprint, color: Colors.blueAccent, size: 60),
                      ),
                      AnimatedBuilder(
                        animation: _scannerAnimation,
                        builder: (context, child) {
                          return Positioned(
                            top: 25 + (_scannerAnimation.value * 60),
                            child: Opacity(
                              opacity: _scannerController.isAnimating ? 1 : 0,
                              child: Container(
                                height: 2, width: 60,
                                decoration: BoxDecoration(
                                  color: Colors.cyanAccent,
                                  boxShadow: [BoxShadow(color: Colors.cyanAccent.withOpacity(0.8), blurRadius: 10, spreadRadius: 2)],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text("HOLD TO SCAN & TRANSMIT", style: TextStyle(color: Colors.blueAccent, fontSize: 10, letterSpacing: 2)),
                ],
              ),
            ),
          ] else
            _buildStatusCard("DATA SECURED", "SIGNAL ENCRYPTED...", Icons.lock, Colors.blueAccent),
        ],
      ),
    );
  }

  // --- PHASE 2: DISCUSSING (Typewriter Transcript) ---
  Widget _buildDiscussingPhase(Map<String, dynamic> roomData, List<dynamic> players) {
    bool isHost = roomData['hostId'] == firebaseService.userId;

    return Column(
      children: [
        const Text("INTERROGATION TRANSCRIPT", style: TextStyle(color: Colors.white24, letterSpacing: 2, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        Expanded(
          child: ListView.builder(
            itemCount: players.length,
            itemBuilder: (context, index) {
              final p = players[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.02),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("SUBJECT: ${p['nickname'].toUpperCase()}", style: const TextStyle(color: Colors.blueAccent, fontSize: 10, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 6),
                    Text(p['answer'] ?? "NO STATEMENT", style: const TextStyle(color: Colors.white, fontSize: 16)),
                  ],
                ),
              );
            },
          ),
        ),
        if (isHost) _buildActionBtn("INITIATE VOTING", () => firebaseService.nextPhase(widget.roomCode, 'voting')),
      ],
    );
  }

  // --- PHASE 3: VOTING (Suspect Grid) ---
  Widget _buildVotingPhase(Map<String, dynamic> roomData, List<dynamic> players, Map<String, dynamic> me) {
    bool hasVoted = me['votedFor'] != null;
    final otherPlayers = players.where((p) => p['userId'] != firebaseService.userId).toList();

    if (hasVoted) return _buildStatusCard("VOTE CAST", "WAITING FOR JURY...", Icons.how_to_vote, Colors.redAccent);

    return Column(
      children: [
        const Text("IDENTIFY THE EMBREACHER", style: TextStyle(color: Colors.redAccent, letterSpacing: 2, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12),
            itemCount: otherPlayers.length,
            itemBuilder: (context, index) {
              final p = otherPlayers[index];
              bool isSelected = _selectedPlayerToVote == p['userId'];
              return GestureDetector(
                onTap: () => setState(() => _selectedPlayerToVote = p['userId']),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.redAccent.withOpacity(0.1) : Colors.white.withOpacity(0.02),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isSelected ? Colors.redAccent : Colors.white10),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(backgroundColor: isSelected ? Colors.redAccent : Colors.white10, child: const Icon(Icons.person, color: Colors.white)),
                      const SizedBox(height: 12),
                      Text(p['nickname'].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        _buildActionBtn("STAMP AS SUSPECT", () async {
          if (_selectedPlayerToVote == null) return;
          await firebaseService.submitVote(widget.roomCode, firebaseService.userId!, _selectedPlayerToVote!);
        }, color: Colors.redAccent),
      ],
    );
  }

  // --- PHASE 4: REVEAL (Fixed Liar Identification Logic) ---
  Widget _buildRevealPhase(Map<String, dynamic> roomData, List<dynamic> players, Map<String, dynamic> me) {
    bool? liarCaught = roomData['liarCaught'];
    // 🔥 ALWAYS identify the actual embreacher based on the database flag
    final actualLiar = players.firstWhereOrNull((p) => p['isLiar'] == true);
    bool isHost = roomData['hostId'] == firebaseService.userId;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          liarCaught == true ? Icons.gavel : Icons.warning_amber_rounded,
          size: 80,
          color: liarCaught == true ? Colors.greenAccent : Colors.redAccent,
        ),
        const SizedBox(height: 20),
        Text(liarCaught == true ? "TARGET NEUTRALIZED" : "SECURITY BREACH", 
          style: TextStyle(color: liarCaught == true ? Colors.greenAccent : Colors.redAccent, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 2)),
        const SizedBox(height: 30),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)),
          child: Column(
            children: [
              const Text("THE ACTUAL EMBREACHER WAS:", style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 2)),
              const SizedBox(height: 12),
              Text(actualLiar?['nickname']?.toUpperCase() ?? "UNKNOWN", 
                style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const SizedBox(height: 40),
        if (isHost) _buildActionBtn("VIEW MISSION LOGS", () => firebaseService.nextPhase(widget.roomCode, 'roundResults')),
      ],
    );
  }

  // --- PHASE 5: ROUND RESULTS ---
  Widget _buildRoundResults(Map<String, dynamic> roomData, List<dynamic> players, Map<String, dynamic> me) {
    bool isHost = roomData['hostId'] == firebaseService.userId;
    List<dynamic> sortedPlayers = List.from(players);
    sortedPlayers.sort((a, b) => (b['score'] ?? 0).compareTo(a['score'] ?? 0));

    return Column(
      children: [
        const Text("MISSION DEBRIEF", style: TextStyle(color: Colors.white24, letterSpacing: 4, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        Expanded(
          child: ListView.builder(
            itemCount: sortedPlayers.length,
            itemBuilder: (context, index) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.02), borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: Text("#${index + 1}", style: const TextStyle(color: Colors.white24)),
                title: Text(sortedPlayers[index]['nickname'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                trailing: Text("${sortedPlayers[index]['score']} PTS", style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.w900)),
              ),
            ),
          ),
        ),
        if (isHost)
          _buildActionBtn("NEXT MISSION", () {
            if ((roomData['currentRound'] ?? 1) >= (roomData['totalRounds'] ?? 3)) {
              firebaseService.nextPhase(widget.roomCode, 'gameOver');
            } else {
              firebaseService.nextRound(widget.roomCode, widget.gameId);
            }
          }),
      ],
    );
  }

  // --- PHASE 6: GAME OVER ---
  Widget _buildGameOver(Map<String, dynamic> roomData, List<dynamic> players) {
    List<dynamic> sortedPlayers = List.from(players);
    sortedPlayers.sort((a, b) => (b['score'] ?? 0).compareTo(a['score'] ?? 0));
    final winner = sortedPlayers.first;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.stars, color: Colors.amber, size: 80),
        const SizedBox(height: 20),
        const Text("CAMPAIGN COMPLETE", style: TextStyle(color: Colors.white24, letterSpacing: 4, fontSize: 12)),
        Text(winner['nickname'].toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w900)),
        const SizedBox(height: 40),
        _buildActionBtn("RETURN TO BASE", () => Navigator.popUntil(context, ModalRoute.withName('/home'))),
      ],
    );
  }

  // --- UI HELPERS ---

  Widget _buildActionBtn(String label, VoidCallback onTap, {Color color = Colors.blueAccent}) {
    return ElevatedButton(
      onPressed: _isLoading ? null : onTap,
      style: ElevatedButton.styleFrom(backgroundColor: color, minimumSize: const Size(double.infinity, 60), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
      child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Text(label, style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2, color: Colors.white)),
    );
  }

  Widget _buildStatusCard(String title, String sub, IconData icon, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(color: color.withOpacity(0.05), borderRadius: BorderRadius.circular(24), border: Border.all(color: color.withOpacity(0.2))),
      child: Column(children: [Icon(icon, color: color, size: 40), const SizedBox(height: 16), Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, letterSpacing: 2)), const SizedBox(height: 8), Text(sub, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white24, fontSize: 10))]),
    );
  }

  Widget _glowOrb(double size, Color color) {
    return Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: color, boxShadow: [BoxShadow(color: color, blurRadius: 100, spreadRadius: 40)]));
  }
}