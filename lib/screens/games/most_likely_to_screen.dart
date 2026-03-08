import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart'; 

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
    final currentGame = games.firstWhere((g) => g.id == widget.gameId, orElse: () => games.first);
    
    return Scaffold(
      backgroundColor: const Color(0xFF04060E),
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: Text(currentGame.name)),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.8, -0.6),
            radius: 1.2,
            colors: [Color(0xFF162252), Color(0xFF04060E)],
            stops: [0.0, 1.0],
          ),
        ),
        child: SafeArea(
          child: StreamBuilder<DocumentSnapshot>(
            stream: firebaseService.getRoomStream(widget.roomCode),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (!snapshot.hasData || !snapshot.data!.exists) return const Center(child: Text("Game Ended."));

              Map<String, dynamic> roomData = snapshot.data!.data() as Map<String, dynamic>;
              String gamePhase = roomData['gamePhase'] ?? 'loading';
              List<dynamic> allPlayers = List<dynamic>.from(roomData['players'] ?? []);
              
              Map<String, dynamic>? me = allPlayers.firstWhereOrNull((p) => (p as Map)['userId'] == firebaseService.userId) as Map<String, dynamic>?;
              if (me == null) return const Center(child: Text("Player not found."));

              return Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Glassmorphism Score Header
                    Card(
                      color: const Color(0xFF0E1329),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: Color(0xFF1F2947), width: 1.2),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(children: [const Text("ROOM", style: TextStyle(color: Color(0xFF8E95A3), fontSize: 12)), Text(widget.roomCode, style: const TextStyle(fontWeight: FontWeight.bold))]),
                            Column(children: [const Text("SCORE", style: TextStyle(color: Color(0xFF8E95A3), fontSize: 12)), Text('${me['score'] ?? 0}', style: const TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.bold, fontSize: 18))]),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Game Phases
                    Expanded(
                      child: Builder(builder: (context) {
                        switch (gamePhase) {
                          case 'votingMLT':
                            return _buildVotingPhase(roomData, me, allPlayers);
                          case 'revealMLT':
                            return _buildRevealPhase(roomData, me, allPlayers);
                          case 'gameOver':
                            return _buildGameOver(roomData, allPlayers);
                          default:
                            return const Center(child: CircularProgressIndicator());
                        }
                      }),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildVotingPhase(Map<String, dynamic> roomData, Map<String, dynamic> me, List<dynamic> allPlayers) {
    bool hasVoted = me['votedFor'] != null;
    String question = roomData['currentQuestionText'] ?? 'Loading...';

    if (hasVoted) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.how_to_vote, size: 80, color: Color(0xFF3B82F6)),
            const SizedBox(height: 20),
            Text("Vote Locked In!", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            const Text("Waiting for others...", style: TextStyle(color: Color(0xFF8E95A3))),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Round ${roomData['currentRound']} / ${roomData['totalRounds']}', style: const TextStyle(color: Color(0xFF8E95A3)), textAlign: TextAlign.center),
        const SizedBox(height: 16),
        
        // Glowing Question Card
        Card(
          color: const Color(0xFF0E1329),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: Color(0xFF3B82F6), width: 1.5), // Blue accent border
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(question, style: Theme.of(context).textTheme.titleLarge?.copyWith(height: 1.4), textAlign: TextAlign.center),
          ),
        ),
        const SizedBox(height: 24),
        
        // Player List
        Expanded(
          child: ListView.builder(
            itemCount: allPlayers.length,
            itemBuilder: (context, index) {
              var player = allPlayers[index] as Map<String, dynamic>;
              bool isSelected = _selectedPlayerId == player['userId'];

              return Card(
                color: isSelected ? const Color(0xFF2563EB).withOpacity(0.3) : const Color(0xFF0E1329),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFF1F2947), width: 1.5),
                ),
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  title: Text(player['nickname'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  trailing: isSelected ? const Icon(Icons.check_circle, color: Color(0xFF3B82F6)) : const Icon(Icons.circle_outlined, color: Colors.white24),
                  onTap: () => setState(() => _selectedPlayerId = player['userId']),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: (_selectedPlayerId == null || _isLoading) ? null : () async {
            setState(() => _isLoading = true);
            await firebaseService.submitVoteMLT(widget.roomCode, firebaseService.userId!, _selectedPlayerId!);
            if (mounted) setState(() => _isLoading = false);
          },
          child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white)) : const Text('Lock in Vote'),
        ),
      ],
    );
  }

  Widget _buildRevealPhase(Map<String, dynamic> roomData, Map<String, dynamic> me, List<dynamic> allPlayers) {
    bool isHost = me['isHost'] ?? false;
    String question = roomData['currentQuestionText'] ?? '';
    
    // Sort players by votes received to find the winner
    List<Map<String, dynamic>> sortedByVotes = List<Map<String, dynamic>>.from(allPlayers.map((p) => Map<String, dynamic>.from(p)));
    sortedByVotes.sort((a, b) => (b['votesReceived'] ?? 0).compareTo(a['votesReceived'] ?? 0));
    
    int maxVotes = sortedByVotes.first['votesReceived'] ?? 0;
    List<Map<String, dynamic>> winners = sortedByVotes.where((p) => (p['votesReceived'] ?? 0) == maxVotes).toList();
    int currentRound = roomData['currentRound'] ?? 1;
    int totalRounds = roomData['totalRounds'] ?? 3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Round $currentRound Results', style: const TextStyle(color: Color(0xFF8E95A3)), textAlign: TextAlign.center),
        const SizedBox(height: 16),
        Text(question, style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
        const SizedBox(height: 24),

        // Display Winner
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: const Color(0xFF2563EB).withOpacity(0.2), // Light blue tint
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF3B82F6), width: 2),
          ),
          child: Column(
            children: [
              const Text("The Group Decided:", style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 12),
              Text(
                winners.map((w) => w['nickname']).join(" & "), 
                style: Theme.of(context).textTheme.displaySmall?.copyWith(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text("with $maxVotes votes", style: const TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        
        const SizedBox(height: 30),
        const Text("Current Standings:", style: TextStyle(color: Color(0xFF8E95A3)), textAlign: TextAlign.center),
        const SizedBox(height: 10),
        
        Expanded(
          child: ListView.builder(
            itemCount: allPlayers.length,
            itemBuilder: (context, index) {
              // Sort by actual score for standings
              List<Map<String, dynamic>> standings = List<Map<String, dynamic>>.from(allPlayers.map((p) => Map<String, dynamic>.from(p)));
              standings.sort((a, b) => (b['score'] ?? 0).compareTo(a['score'] ?? 0));
              var player = standings[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("${index + 1}. ${player['nickname']}", style: const TextStyle(color: Colors.white, fontSize: 16)),
                    Text("${player['score'] ?? 0} pts", style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            }
          ),
        ),

        if (isHost)
          ElevatedButton(
            onPressed: _isLoading ? null : () async {
              setState(() => _isLoading = true);
              if (currentRound >= totalRounds) {
                await firebaseService.nextPhase(widget.roomCode, 'gameOver');
              } else {
                await firebaseService.nextRound(widget.roomCode, widget.gameId);
              }
              if (mounted) setState(() => _isLoading = false);
            },
            child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Text(currentRound >= totalRounds ? 'End Game' : 'Start Next Round'),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(30)),
            child: const Center(child: Text('Waiting for host to continue...', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold))),
          ),
      ],
    );
  }

  Widget _buildGameOver(Map<String, dynamic> roomData, List<dynamic> allPlayers) {
    List<Map<String, dynamic>> standings = List<Map<String, dynamic>>.from(allPlayers.map((p) => Map<String, dynamic>.from(p)));
    standings.sort((a, b) => (b['score'] ?? 0).compareTo(a['score'] ?? 0));

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text("Final Results", style: Theme.of(context).textTheme.displaySmall, textAlign: TextAlign.center),
        const SizedBox(height: 30),
        Expanded(
          child: ListView.builder(
            itemCount: standings.length,
            itemBuilder: (context, index) {
              var player = standings[index];
              return Card(
                color: index == 0 ? Colors.amber.withOpacity(0.2) : const Color(0xFF0E1329),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: index == 0 ? Colors.amber : const Color(0xFF1F2947), width: 1.2),
                ),
                child: ListTile(
                  leading: Text("#${index + 1}", style: TextStyle(fontSize: 20, color: index == 0 ? Colors.amber : Colors.white)),
                  title: Text(player['nickname'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  trailing: Text("${player['score']} pts", style: const TextStyle(fontSize: 18, color: Color(0xFF3B82F6))),
                ),
              );
            }
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.popUntil(context, ModalRoute.withName('/home')),
          child: const Text("Return to Lobby"),
        )
      ],
    );
  }
}