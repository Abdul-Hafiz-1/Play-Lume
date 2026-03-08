import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart'; // For .firstWhereOrNull

// Import your centralized services and models
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
      appBar: AppBar(title: Text(currentGame.name), elevation: 0, backgroundColor: Colors.transparent,),
      body: StreamBuilder<DocumentSnapshot>(
        stream: firebaseService.getRoomStream(widget.roomCode),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            print("SyncGS(Stream): Error: ${snapshot.error}");
            return Center(child: Text('Error loading game data: ${snapshot.error}'));
          }
          if (snapshot.data == null || !snapshot.data!.exists) {
            print("SyncGS(Stream): Data is null or does not exist. Navigating home.");
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && ModalRoute.of(context)?.isCurrent == true) {
                Navigator.popUntil(context, ModalRoute.withName('/home'));
              }
            });
            return const Center(child: Text("Room not found or no game data. Returning..."));
          }

          // Data exists, extract room data
          final roomData = snapshot.data!.data() as Map<String, dynamic>;
          final String currentUserId = firebaseService.getCurrentUserId();
          final String gamePhase = roomData['gamePhase'] ?? 'loading'; 

          final Map<String, dynamic>? currentPlayer = (roomData['players'] as List<dynamic>?)
              ?.firstWhereOrNull((p) => p['userId'] == currentUserId);

          if (currentPlayer == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && ModalRoute.of(context)?.isCurrent == true) {
                Navigator.popUntil(context, ModalRoute.withName('/home'));
              }
            });
            return const Center(child: Text('Player data not found. Returning...'));
          }

          List<dynamic> allPlayers = List<dynamic>.from(roomData['players'] ?? []);

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Score and Info Panel
                Card(
                  color: Theme.of(context).cardColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(children: [Text("ROOM CODE", style: TextStyle(color: Colors.white54, letterSpacing: 1)), SelectableText(widget.roomCode, style: Theme.of(context).textTheme.titleLarge?.copyWith(letterSpacing: 2, fontWeight: FontWeight.bold),)]),
                        Column(children: [Text("SCORE", style: TextStyle(color: Colors.white54, letterSpacing: 1)), Text('${currentPlayer['score'] ?? 0}', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.lightGreenAccent, fontWeight: FontWeight.bold),)])
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: Builder(
                    builder: (context) {
                      switch (gamePhase) {
                        case 'answeringSync':
                          return _buildAnsweringSyncUI(roomData, currentPlayer);
                        case 'revealingAnswersSync':
                          return _buildRevealingAnswersSyncUI(roomData, currentPlayer);
                        case 'roundResults': 
                          return _buildRoundResultsSyncUI(roomData, currentPlayer);
                        case 'gameOver':
                          return _buildGameOverUI(context, roomData, allPlayers);
                        default:
                          return const Center(child: Text('Loading phase...'));
                      }
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnsweringSyncUI(Map<String, dynamic> roomData, Map<String, dynamic> currentPlayer) {
    // Logical Fix: Fetching the actual question text from the document
    String currentQuestion = roomData['currentQuestionText'] ?? 'Loading question...';
    bool hasAnswered = currentPlayer['isReadyInSyncPhase'] ?? false; 

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Round ${roomData['currentRound'] ?? 1} / ${roomData['totalRounds'] ?? 1}',
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        Text(
          'Name something that fits this category...',
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        // Question Panel with depth
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(colors: [Color(0xFF231454), Color(0xFF130A24)], begin: Alignment.topLeft, end: Alignment.bottomRight) // Subtle card gradient
            ),
            child: Text(
              currentQuestion,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Theme.of(context).colorScheme.secondary),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        const SizedBox(height: 30),
        if (!hasAnswered)
          TextField(
            controller: _answerController,
            decoration: const InputDecoration(
              hintText: 'Type your answer here to sync!',
              border: OutlineInputBorder(),
            ),
            style: const TextStyle(color: Colors.white, fontSize: 18),
            maxLines: 1, 
          )
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10)),
            child: Text(
              'Your Answer: "${currentPlayer['answerSync'] ?? ''}"',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.lightGreenAccent),
              textAlign: TextAlign.center,
            ),
          ),
        const SizedBox(height: 30),
        if (!hasAnswered)
          ElevatedButton(
            onPressed: _isLoading ? null : () => _submitAnswerSync(),
            child: _isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white))
                : const Text('Submit Answer'),
          )
        else
          Text(
            'Answer submitted! Waiting for others...',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
      ],
    );
  }

  Widget _buildRevealingAnswersSyncUI(Map<String, dynamic> roomData, Map<String, dynamic> currentPlayer) {
    List<dynamic> players = List<dynamic>.from(roomData['players'] ?? []);
    bool isHost = roomData['hostId'] == firebaseService.getCurrentUserId();

    // Group answers using the normalized form as the key
    Map<String, List<Map<String, dynamic>>> groupedAnswers = {};
    Map<String, String> normalizedToRepresentativeOriginal = {}; 

    for (var p in players) {
      final player = Map<String, dynamic>.from(p);
      String? answer = player['answerSync'] as String?;
      if (answer != null && answer.isNotEmpty) {
        String normalizedAnswer = _normalizeAnswer(answer);
        if (!groupedAnswers.containsKey(normalizedAnswer)) {
          groupedAnswers[normalizedAnswer] = [];
          normalizedToRepresentativeOriginal[normalizedAnswer] = answer; 
        }
        groupedAnswers[normalizedAnswer]!.add(player);
      }
    }

    List<MapEntry<String, List<Map<String, dynamic>>>> sortedGroups = groupedAnswers.entries.toList();
    sortedGroups.sort((a, b) => b.value.length.compareTo(a.value.length)); // Sort by group size

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Round ${roomData['currentRound'] ?? 1} Matches!',
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        Expanded(
          child: ListView.builder(
            itemCount: sortedGroups.length,
            itemBuilder: (context, index) {
              final entry = sortedGroups[index];
              final normalizedAnswerKey = entry.key; 
              final displayAnswer = normalizedToRepresentativeOriginal[normalizedAnswerKey] ?? normalizedAnswerKey; 
              final playersInGroup = entry.value;
              bool isMatchedGroup = playersInGroup.length > 1;

              return Card(
                color: isMatchedGroup ? Colors.blueAccent.withOpacity(0.2) : Theme.of(context).cardColor,
                margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.0),
                  side: BorderSide(color: isMatchedGroup ? Colors.blueAccent : Colors.transparent, width: 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '"$displayAnswer"', 
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: isMatchedGroup ? Theme.of(context).colorScheme.secondary : Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10.0, 
                        runSpacing: 6.0, 
                        children: playersInGroup.map((player) {
                          return Chip(
                            backgroundColor: player['userId'] == firebaseService.getCurrentUserId()
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey[800],
                            label: Text(player['nickname'], style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          );
                        }).toList(),
                      ),
                      if (isMatchedGroup)
                        Padding(
                          padding: const EdgeInsets.only(top: 12.0),
                          child: Text(
                            'Each player gets ${playersInGroup.length} points!',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.greenAccent, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        if (isHost)
          ElevatedButton(
            onPressed: _isLoading ? null : () async {
              setState(() => _isLoading = true);
              await firebaseService.nextPhase(widget.roomCode, 'roundResults');
              setState(() => _isLoading = false);
            },
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Continue to Scores'),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(30)),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white54)),
                SizedBox(width: 12),
                Text('Waiting for host to continue...', style: TextStyle(color: Colors.white70, fontSize: 16)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildRoundResultsSyncUI(Map<String, dynamic> roomData, Map<String, dynamic> currentPlayer) {
    List<dynamic> players = List<dynamic>.from(roomData['players'] ?? []);
    bool isHost = roomData['hostId'] == firebaseService.getCurrentUserId();
    int currentRound = roomData['currentRound'] as int? ?? 0;
    int totalRounds = roomData['totalRounds'] as int? ?? 1;

    // Sort players by total score descending
    players.sort((a, b) => (b['score'] ?? 0).compareTo(a['score'] ?? 0));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Round $currentRound Results!',
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        Text(
          'Total Scores:',
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Expanded(
          child: ListView.builder(
            itemCount: players.length,
            itemBuilder: (context, index) {
              var player = players[index] as Map<String, dynamic>;
              return Card(
                color: index == 0 ? Colors.amber[800] : Theme.of(context).cardColor,
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  leading: Text("#${index + 1}", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  title: Text(player['nickname'] as String? ?? 'Player', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  trailing: Text("Score: ${player['score'] ?? 0}", style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.lightGreenAccent, fontWeight: FontWeight.bold)),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        if (isHost)
          ElevatedButton(
            onPressed: _isLoading ? null : () {
              if (currentRound >= totalRounds) {
                firebaseService.nextPhase(widget.roomCode, 'gameOver');
              } else {
                firebaseService.nextRound(widget.roomCode, widget.gameId);
              }
            },
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(currentRound >= totalRounds ? 'Show Final Results' : 'Start Next Round'),
          )
        else
           Container(
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(30)),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white54)),
                SizedBox(width: 12),
                Text('Waiting for host to continue...', style: TextStyle(color: Colors.white70, fontSize: 16)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildGameOverUI(BuildContext context, Map<String, dynamic> roomData, List<dynamic> allPlayers) {
    List<dynamic> players = List<dynamic>.from(roomData['players'] ?? []);
    players.sort((a, b) => (b['score'] ?? 0).compareTo(a['score'] ?? 0));

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Game Over!', style: Theme.of(context).textTheme.displaySmall, textAlign: TextAlign.center,),
            const SizedBox(height: 20),
            Text('Final Scores:', style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center,),
            const SizedBox(height: 10),
            Expanded(child: ListView.builder(
                itemCount: players.length,
                itemBuilder: (context, index) {
                    var player = players[index] as Map<String, dynamic>;
                    return Card(
                        color: index == 0 ? Colors.amber[800] : Theme.of(context).cardColor,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                            leading: Text("#${index + 1}", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                            title: Text(player['nickname'] as String? ?? 'Player', style: TextStyle(fontWeight: FontWeight.bold)),
                            trailing: Text("Score: ${player['score'] ?? 0}", style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.lightGreenAccent, fontWeight: FontWeight.bold)),
                        ),
                    );
                }
            )),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.popUntil(context, ModalRoute.withName('/home')),
              child: const Text('Return to Home'),
            )
          ],
      ),
    );
  }

  String _normalizeAnswer(String answer) {
    String normalized = answer.toLowerCase();
    normalized = normalized.replaceAll(RegExp(r'[^\p{L}\p{N}\s]', unicode: true), ''); 
    normalized = normalized.replaceAll(RegExp(r'\s+'), ' ').trim();

    if (normalized.endsWith('es')) {
      normalized = normalized.substring(0, normalized.length - 2);
    } else if (normalized.endsWith('s') && normalized.length > 1 && !normalized.endsWith('ss')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    
    normalized = normalized.replaceAll(' ', '');
    return normalized;
  }

  Future<void> _submitAnswerSync() async {
    if (_answerController.text.trim().isEmpty) {
      snackbarKey.currentState?.showSnackBar(
        const SnackBar(content: Text('Please enter an answer.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await firebaseService.submitAnswerSync(
        widget.roomCode,
        firebaseService.getCurrentUserId(),
        _answerController.text.trim(),
      );
      _answerController.clear(); 
    } catch (e) {
      print("Error submitting Sync answer: $e");
      snackbarKey.currentState?.showSnackBar(
        SnackBar(content: Text('Error submitting answer: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}