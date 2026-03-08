import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart'; // For .firstWhereOrNull

// Import your centralized services and models
import '../../services/firebase_service.dart';
import '../../models/game_model.dart';

class GuessTheLiarGameScreen extends StatefulWidget {
  final String roomCode;
  final String gameId;

  const GuessTheLiarGameScreen({super.key, required this.roomCode, required this.gameId});

  @override
  State<GuessTheLiarGameScreen> createState() => _GuessTheLiarGameScreenState();
}

class _GuessTheLiarGameScreenState extends State<GuessTheLiarGameScreen> {
  final TextEditingController _answerController = TextEditingController();
  bool _isLoading = false;
  String? _selectedPlayerToVote;

  @override
  Widget build(BuildContext context) {
    final currentGame = games.firstWhere((g) => g.id == widget.gameId, orElse: () => games.first);
    return Scaffold(
      appBar: AppBar(title: Text(currentGame.name)),
      body: StreamBuilder<DocumentSnapshot>(
        stream: firebaseService.getRoomStream(widget.roomCode),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            print('DEBUG: ConnectionState: Waiting'); // Added debug
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            print("GTLGS(Stream): Error: ${snapshot.error}");
            return Center(child: Text('Error loading game data: ${snapshot.error}'));
          }
          if (snapshot.data == null || !snapshot.data!.exists) {
            print("GTLGS(Stream): Data is null or does not exist. Navigating home."); // Added debug
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && ModalRoute.of(context)?.isCurrent == true) {
                Navigator.popUntil(context, ModalRoute.withName('/home'));
              }
            });
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Room not found or no game data.', textAlign: TextAlign.center,),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.popUntil(context, ModalRoute.withName('/home')),
                    child: const Text('Return to Home'),
                  )
                ],
              ),
            );
          }

          // Data exists, extract room data
          final roomData = snapshot.data!.data() as Map<String, dynamic>;
          final String currentUserId = firebaseService.getCurrentUserId();

          List<dynamic> playersInRoom = List<dynamic>.from(roomData['players'] ?? []);
          
          final Map<String, dynamic>? currentPlayer = playersInRoom
              .firstWhereOrNull((p) => p['userId'] == currentUserId);

          if (currentPlayer == null) {
            print('DEBUG: currentPlayer is NULL. currentUserId ($currentUserId) was NOT found in the players list from Firestore.');
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && ModalRoute.of(context)?.isCurrent == true) {
                Navigator.popUntil(context, ModalRoute.withName('/home'));
              }
            });
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('You are not a player in this room. Returning to Home.', textAlign: TextAlign.center,),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.popUntil(context, ModalRoute.withName('/home')),
                    child: const Text('Return to Home'),
                  )
                ],
              ),
            );
          }

          final String gamePhase = roomData['gamePhase'] as String? ?? '';
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Room Code: ${widget.roomCode}',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'Your Score: ${currentPlayer['score'] ?? 0}',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: Builder(
                    builder: (context) {
                      switch (gamePhase) {
                        case 'answering':
                          return _buildAnsweringPhaseUI(context, roomData);
                        case 'discussing':
                          return _buildDiscussingPhaseUI(context, roomData);
                        case 'voting':
                          return _buildVotingPhaseUI(context, roomData);
                        case 'reveal':
                          return _buildRevealPhaseUI(context, roomData);
                        case 'roundResults':
                          return _buildRoundResultsUI(context, roomData, currentPlayer);
                        case 'gameOver':
                          return _buildGameOverUI(context, roomData);
                        default:
                          return Center(
                            child: Text('Waiting for game to start or unknown phase: $gamePhase'),
                          );
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

  Widget _buildRoundResultsUI(BuildContext context, Map<String, dynamic> roomData, Map<String, dynamic> currentPlayer) {
    List<dynamic> players = List<dynamic>.from(roomData['players'] ?? []);
    // Sort players by score descending
    players.sort((a, b) => (b['score'] ?? 0).compareTo(a['score'] ?? 0));
    int currentRound = roomData['currentRound'] as int? ?? 0;
    int totalRounds = roomData['totalRounds'] as int? ?? 1;
    bool isHost = currentPlayer['isHost'] ?? false;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Round $currentRound Results!', style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
          const SizedBox(height: 20),
          Text('Scores:', style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: players.length,
              itemBuilder: (context, index) {
                var player = players[index] as Map<String, dynamic>;
                return Card(
                  color: index == 0 ? Colors.amber[800] : Theme.of(context).cardColor,
                  child: ListTile(
                    leading: Text("#${index + 1}", style: Theme.of(context).textTheme.titleLarge),
                    title: Text(player['nickname'] as String? ?? 'Player'),
                    trailing: Text("Score: ${player['score'] ?? 0}", style: Theme.of(context).textTheme.titleMedium),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          if (isHost)
            ElevatedButton(
              onPressed: () {
                if (currentRound >= totalRounds) {
                  firebaseService.nextPhase(widget.roomCode, 'gameOver');
                } else {
                  firebaseService.nextRound(widget.roomCode, widget.gameId);
                }
              },
              child: Text(currentRound >= totalRounds ? 'Show Final Results' : 'Start Next Round'),
            )
          else
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Text("Waiting for host to continue...", textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
            )
        ],
      ),
    );
  }

  Widget _buildAnsweringPhaseUI(BuildContext context, Map<String, dynamic> roomData) {
      List<dynamic> players = List<dynamic>.from(roomData['players'] ?? []);
      Map<String, dynamic>? me = players.firstWhereOrNull((p) => (p as Map)['userId'] == firebaseService.userId) as Map<String, dynamic>?;
      if (me == null) return const Center(child: Text("Error finding your player data."));
      bool hasAnswered = (me['answer'] as String? ?? '').isNotEmpty;

      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Round ${roomData['currentRound'] ?? 1} / ${roomData['totalRounds'] ?? 1}', style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
          const SizedBox(height:10),
          Text('Your Question:', style: Theme.of(context).textTheme.bodyLarge, textAlign: TextAlign.center),
          const SizedBox(height: 10),
          Card( child: Padding( padding: const EdgeInsets.all(16.0), child: Text(me['question'] ?? "Loading...", style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),),),
          const SizedBox(height: 30),
          if (!hasAnswered) ...[
            TextField( controller: _answerController, decoration: const InputDecoration(hintText: 'Type your answer here'), maxLines: 3, style: const TextStyle(color: Colors.white),),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : () async {
                if (_answerController.text.trim().isEmpty) {
                  snackbarKey.currentState?.showSnackBar(
                    const SnackBar(content: Text("Please enter an answer before submitting."))
                  );
                  return;
                }
                setState(() {
                  _isLoading = true;
                });
                try {
                  await firebaseService.submitAnswer(widget.roomCode, firebaseService.userId!, _answerController.text.trim());
                } catch (e) {
                  snackbarKey.currentState?.showSnackBar(SnackBar(content: Text("Failed to submit answer: $e")));
                } finally {
                  if (mounted) {
                    setState(() {
                      _isLoading = false;
                    });
                  }
                }
              },
              child: _isLoading ? const SizedBox(width:20, height:20, child:CircularProgressIndicator(color: Colors.white)) : const Text('Submit Answer'),),
          ] else ...[
            Text("Answer Submitted!", style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.greenAccent), textAlign: TextAlign.center),
            const SizedBox(height: 10),
            Text("Waiting for other players...", style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
          ],
        ],
      ),
    );
  }

  Widget _buildDiscussingPhaseUI(BuildContext context, Map<String, dynamic> roomData) {
    List<dynamic> players = List<dynamic>.from(roomData['players'] ?? []);
    Map<String, dynamic>? me = players.firstWhereOrNull((p) => (p as Map)['userId'] == firebaseService.userId) as Map<String, dynamic>?;
    if (me == null) return const Center(child: Text("Error finding your player data."));
    bool isHost = me['isHost'] ?? false;

    return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Discuss!', style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: 10),
            Card(
              color: const Color(0xFF4A3780), // Purple color from screenshot
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  "The Original Question Was: ${roomData['originalQuestion'] ?? ''}",
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Answers:', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: players.length,
                itemBuilder: (context, index) {
                  var player = players[index] as Map<String, dynamic>;
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4.0),
                    child: ListTile(
                      title: Text(player['nickname'] as String? ?? 'Player', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("Answer: ${player['answer'] as String? ?? '...'}", style: TextStyle(color: Colors.white70)),
                    ),
                  );
                },
              ),
            ),
            if (isHost)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: ElevatedButton(
                  onPressed: () {
                    firebaseService.nextPhase(widget.roomCode, 'voting');
                  },
                  child: const Text('Start Voting Now'),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text("Waiting for host to start voting...", textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
              )
          ],
        ),
      );
  }

  Widget _buildVotingPhaseUI(BuildContext context, Map<String, dynamic> roomData) {
    List<dynamic> players = List<dynamic>.from(roomData['players'] ?? []);
    Map<String, dynamic>? me = players.firstWhereOrNull((p) => (p as Map)['userId'] == firebaseService.userId) as Map<String, dynamic>?;
    if (me == null) {
      return const Center(child: Text("Error finding your player data."));
    }
    bool hasVoted = me['votedFor'] != null;

    if (hasVoted) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text("You voted!", style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.greenAccent)),
          const SizedBox(height: 10),
          Text("Waiting for other players to vote...", style: Theme.of(context).textTheme.bodyMedium),
        ]),
      );
    }

    // Filter out the current user from the list of voteable players
    List<Map<String, dynamic>> voteablePlayers = players
        .where((p) => (p as Map)['userId'] != firebaseService.userId)
        .map((p) => Map<String, dynamic>.from(p as Map)).toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Vote for the Liar!', style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: voteablePlayers.length,
              itemBuilder: (context, index) {
                var player = voteablePlayers[index];
                final bool isSelected = _selectedPlayerToVote == player['userId'];
                return Card(
                  color: isSelected ? Colors.deepPurpleAccent : Theme.of(context).cardColor,
                  child: ListTile(
                    title: Text(player['nickname'] as String? ?? 'Player'),
                    subtitle: Text("Answer: ${player['answer'] as String? ?? ''}", maxLines: 1, overflow: TextOverflow.ellipsis),
                    onTap: () {
                      setState(() {
                        _selectedPlayerToVote = player['userId'] as String?;
                      });
                    },
                  ),
                );
              },
            ),
          ),
          ElevatedButton(
            onPressed: (_selectedPlayerToVote == null || _isLoading) ? null : () async {
                setState(() {
                  _isLoading = true;
                });
                try {
                  await firebaseService.submitVote(widget.roomCode, firebaseService.userId!, _selectedPlayerToVote!);
                } catch (e) {
                  snackbarKey.currentState?.showSnackBar(SnackBar(content: Text("Failed to submit vote: $e")));
                } finally {
                  if(mounted) {
                    setState(() {
                      _isLoading = false;
                    });
                  }
                }
            },
            child: _isLoading
                ? const SizedBox(width:20, height:20, child: CircularProgressIndicator(color:Colors.white))
                : Text(_selectedPlayerToVote == null
                    ? "Select a Player to Vote"
                    : 'Vote for ${
                        (players.firstWhereOrNull((p) => (p as Map)['userId'] == _selectedPlayerToVote) 
                            as Map<String, dynamic>?)?['nickname'] ?? 'Player'
                      }'
                  ),
          )
        ],
      ),
    );
  }

  Widget _buildRevealPhaseUI(BuildContext context, Map<String, dynamic> roomData) {
    List<dynamic> players = List<dynamic>.from(roomData['players'] ?? []);
    Map<String, dynamic>? me = players.firstWhereOrNull((p) => (p as Map)['userId'] == firebaseService.userId) as Map<String, dynamic>?; 
    if (me == null) return const Center(child: Text("Error finding your player data."));
    bool isHost = me['isHost'] ?? false;
    bool? liarCaught = roomData['liarCaught'] as bool?;
    int currentRound = roomData['currentRound'] as int? ?? 0;
    int totalRounds = roomData['totalRounds'] as int? ?? 1;

    if (liarCaught == null) {
      return const Center(child: Text("Calculating results..."));
    }

    Map<String, dynamic>? liar = players.firstWhereOrNull((p) => (p as Map)['isLiar'] == true) as Map<String, dynamic>?;

    return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Round $currentRound Results!', style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            Card(
              color: liarCaught ? Colors.green[800] : Colors.red[800],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  liarCaught
                      ? "${liar?['nickname'] ?? 'The Liar'} was caught! Normal players get 1 point."
                      : "${liar?['nickname'] ?? 'The Liar'} got away! The Liar gets 1 point.",
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text("Your Role: ${me['isLiar'] == true ? 'You are the LIAR!' : 'You are a NORMAL PLAYER'}", 
                 style: Theme.of(context).textTheme.titleMedium?.copyWith(color: me['isLiar'] == true ? Colors.redAccent : Colors.lightGreenAccent),
                 textAlign: TextAlign.center),
            const SizedBox(height: 10),
            Text('All Players & Scores:', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            Expanded(child: ListView.builder(
                itemCount: players.length,
                itemBuilder: (context, index) {
                    var player = players[index] as Map<String, dynamic>;
                    Color cardColor;
                    if (player['isLiar'] == true) {
                      cardColor = liarCaught ? Colors.red[700]! : Colors.green[700]!; 
                    } else {
                      cardColor = liarCaught ? Colors.green[700]! : Colors.red[700]!; 
                    }
                    return Card(
                      color: cardColor,
                      child: ListTile(
                        leading: Icon(player['isLiar'] == true ? Icons.theater_comedy : Icons.person_search, color: Colors.white),
                        title: Text('${player['nickname'] as String? ?? 'Player'} (Votes: ${player['votesReceived'] ?? 0})', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        trailing: Text("Score: ${player['score'] ?? 0}", style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white)),
                      ));
                }
            )),
            if (isHost)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: ElevatedButton(
                  onPressed: () {
                    if (currentRound >= totalRounds) {
                      firebaseService.nextPhase(widget.roomCode, 'gameOver');
                    } else {
                      firebaseService.nextRound(widget.roomCode, widget.gameId);
                    }
                  },
                  child: Text(currentRound >= totalRounds ? 'Show Final Results' : 'Start Next Round'),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text("Waiting for host to continue...", textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
              )
          ],
        ),
    );
  }

  Widget _buildGameOverUI(BuildContext context, Map<String, dynamic> roomData) {
    List<dynamic> players = List<dynamic>.from(roomData['players'] ?? []);
    // Sort players by score descending
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
                        child: ListTile(
                            leading: Text("#${index + 1}", style: Theme.of(context).textTheme.titleLarge),
                            title: Text(player['nickname'] as String? ?? 'Player'),
                            trailing: Text("Score: ${player['score'] ?? 0}", style: Theme.of(context).textTheme.titleMedium),
                        ),
                    );
                }
            )),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.popUntil(context, ModalRoute.withName('/home'));
              },
              child: const Text('Return to Home'),
            )
          ],
      ),
    );
  }
}