import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart'; // For .firstWhereOrNull
import 'dart:async'; // Required for the game timer

// Import your centralized services and models
import '../../services/firebase_service.dart';
import '../../models/game_model.dart';

class DontGetMeStartedGameScreen extends StatefulWidget {
  final String roomCode;
  final String gameId;

  const DontGetMeStartedGameScreen({super.key, required this.roomCode, required this.gameId});

  @override
  State<DontGetMeStartedGameScreen> createState() => _DontGetMeStartedGameScreenState();
}

class _DontGetMeStartedGameScreenState extends State<DontGetMeStartedGameScreen> {
  // Controllers for guessing players
  final List<TextEditingController> _guessControllers = List.generate(3, (_) => TextEditingController());

  // Controller for ranting player - used for personal reference now
  final TextEditingController _rantTextController = TextEditingController();
  final TextEditingController _topicController = TextEditingController();

  Timer? _timer;
  int _secondsRemaining = 0;
  bool _isLoading = false; // For submit buttons

  // Constant for the ranting phase timer
  static const int _rantingTimeSeconds = 75;

  @override
  void initState() {
    super.initState();
    // Start listening to the room stream to update timer and phases
    firebaseService.getRoomStream(widget.roomCode).listen((snapshot) {
      if (snapshot.exists) {
        Map<String, dynamic> roomData = snapshot.data() as Map<String, dynamic>;
        String gamePhase = roomData['gamePhase'] as String? ?? '';
        Timestamp? timerStartTimeStamp = roomData['timerEndTime'] as Timestamp?; // Using timerEndTime to store START time

        // The timer is active ONLY in the 'guessingAndRanting' phase
        if (gamePhase == 'guessingAndRanting' && timerStartTimeStamp != null) {
          // Calculate the actual end time based on the start timestamp + 75 seconds
          DateTime timerEndTime = timerStartTimeStamp.toDate().add(const Duration(seconds: _rantingTimeSeconds));
          _startTimer(timerEndTime);
        } else {
          _stopTimer(); // Ensure timer is stopped in other phases
          // If timer is not running, ensure _secondsRemaining is 0 (or some default like N/A)
          if (_secondsRemaining != 0) { // Optimize setState calls
            setState(() { _secondsRemaining = 0; });
          }
        }
      }
    });
  }

  void _startTimer(DateTime endTime) {
    _stopTimer(); // Stop any existing timer first
    final now = DateTime.now();
    int initialSeconds = endTime.difference(now).inSeconds;
    if (initialSeconds < 0) initialSeconds = 0; // If timer already expired

    if (_secondsRemaining != initialSeconds) { // Only update state if value changed to reduce rebuilds
      setState(() {
        _secondsRemaining = initialSeconds;
      });
    }

    // Only start periodic timer if there are seconds to count down
    if (_secondsRemaining > 0) {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        // Only call setState if the value actually changes to avoid unnecessary rebuilds
        if (_secondsRemaining > 0) {
          setState(() {
            _secondsRemaining--;
          });
        }

        if (_secondsRemaining <= 0) {
          _stopTimer();
          // If the timer ends, and we are still in guessingAndRanting,
          // automatically move to the reviewingGuesses phase if I am the ranting player
          _handleTimerEnd();
        }
      });
    } else {
      // If timer is already 0, immediately handle its end.
      _handleTimerEnd();
    }
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _handleTimerEnd() async {
    // Only the ranting player should trigger phase change automatically on timer end
    // Use a transaction to ensure we read the latest state and only update if conditions are met
    try {
      // Accessing _firestore directly from the global firebaseService might need a small workaround
      // Let's use the actual firebase interaction we extracted. Note: If you made _firestore private, 
      // you may need to expose a method in FirebaseService or expose firestore. 
      // For now, assuming you still have access or we just trigger the phase update.
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentReference roomRef = FirebaseFirestore.instance.collection('rooms').doc(widget.roomCode);
        DocumentSnapshot roomSnap = await transaction.get(roomRef);

        if (!roomSnap.exists) {
          print("DGMS: Timer end handler: Room does not exist.");
          return;
        }

        Map<String, dynamic> roomData = roomSnap.data() as Map<String, dynamic>;
        List<dynamic> players = List<dynamic>.from(roomData['players'] ?? []);
        Map<String, dynamic>? me = players.firstWhereOrNull((p) => (p as Map)['userId'] == firebaseService.userId) as Map<String, dynamic>?;

        // Check if I am the ranting player AND the current phase is still 'guessingAndRanting'
        if (me != null && (me['isRantingPlayer'] == true) && roomData['gamePhase'] == 'guessingAndRanting') {
          print("DGMS: Ranter's client: Rant/Guess timer ended. Moving game to reviewingGuesses.");
          transaction.update(roomRef, {'gamePhase': 'reviewingGuesses'});
        } else {
          print("DGMS: Timer end handler: Not ranting player or phase changed, no action.");
        }
      });
    } catch (e) {
      print("DGMS: Error in _handleTimerEnd transaction: $e");
    }
  }

  @override
  void dispose() {
    _stopTimer();
    for (var controller in _guessControllers) {
      controller.dispose();
    }
    _rantTextController.dispose();
    _topicController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentGame = games.firstWhere((g) => g.id == widget.gameId, orElse: () => games.first);
    return Scaffold(
      appBar: AppBar(title: Text(currentGame.name)),
      body: StreamBuilder<DocumentSnapshot>(
        stream: firebaseService.getRoomStream(widget.roomCode),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            print("DGMS(Stream): Error: ${snapshot.error}");
            return Center(child: Text('Error loading game data: ${snapshot.error}'));
          }
          if (snapshot.data == null || !snapshot.data!.exists) {
            print("DGMS(Stream): Data is null or does not exist. Navigating home.");
            WidgetsBinding.instance.addPostFrameCallback((_) {
               if (mounted && ModalRoute.of(context)?.isCurrent == true) { 
                 Navigator.popUntil(context, ModalRoute.withName('/home'));
               }
             });
            return const Center(child: Text("Game room not found or ended."));
          }

          Map<String, dynamic> roomData = snapshot.data!.data() as Map<String, dynamic>;
          String gamePhase = roomData['gamePhase'] as String? ?? 'loading';

          List<dynamic> players = List<dynamic>.from(roomData['players'] ?? []); 
          Map<String, dynamic>? me = players.firstWhereOrNull((p) => (p as Map)['userId'] == firebaseService.userId) as Map<String, dynamic>?;

          if (me == null) {
              print("DGMS(Stream): Current player (firebaseService.userId: ${firebaseService.userId}) not found in players list. Returning to home.");
              WidgetsBinding.instance.addPostFrameCallback((_) {
                 if (mounted && ModalRoute.of(context)?.isCurrent == true) { 
                   Navigator.popUntil(context, ModalRoute.withName('/home'));
                 }
               });
              return const Center(child: Text("Player data not found. Returning to home..."));
          }

          print("DGMS(Stream): Current gamePhase: $gamePhase. IsRantingPlayer: ${me['isRantingPlayer']}");

          switch (gamePhase) {
            case 'waitingForTopicSelection':
              return _buildWaitingForTopicSelectionUI(context, roomData, me, players);
            case 'rantingPlayerSetup': // This is the "input page" phase
              return _buildRantingPlayerSetupUI(context, roomData, me, players);
            case 'guessingAndRanting': // This is the "ranting phase" with timer
              return _buildGuessingAndRantingUI(context, roomData, me, players);
            case 'reviewingGuesses':
              return _buildReviewingGuessesUI(context, roomData, me, players);
            case 'roundResults':
              return _buildRoundResultsUI(context, roomData, me, players);
            case 'gameOver':
              // Pass the full players list to _buildGameOverUI
              return _buildGameOverUI(context, roomData, players);
            default:
              return Center(child: Text('Loading game state ($gamePhase)...'));
          }
        },
      ),
    );
  }

  Widget _buildWaitingForTopicSelectionUI(BuildContext context, Map<String, dynamic> roomData, Map<String, dynamic> me, List<dynamic> allPlayers) {
    bool isRantingPlayer = me['isRantingPlayer'] ?? false;
    String currentRantingPlayerNickname = allPlayers.firstWhereOrNull((p) => (p as Map)['userId'] == roomData['currentRantingPlayerId'])?['nickname'] ?? 'Someone';
    bool isHost = me['isHost'] ?? false;

    // Pre-fill topic controller if already set in Firestore (e.g., after hot restart)
    if (isRantingPlayer) {
      _topicController.text = roomData['topic'] ?? '';
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Round ${roomData['currentRound'] ?? 1} / ${roomData['totalRounds'] ?? 1}', style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
          const SizedBox(height: 20),
          if (isRantingPlayer) ...[
            Text('You have been chosen to rant this round!', style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            TextField(
              controller: _topicController,
              decoration: const InputDecoration(hintText: 'Enter your rant topic'),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : () async {
                if (_topicController.text.trim().isEmpty) {
                  snackbarKey.currentState?.showSnackBar(const SnackBar(content: Text("Please enter a topic.")));
                  return;
                }
                setState(() => _isLoading = true);
                await firebaseService.setRanterTopic(widget.roomCode, firebaseService.userId!, _topicController.text.trim());
                setState(() => _isLoading = false);
              },
              child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Submit Topic'),
            ),
          ] else ...[
            Text('$currentRantingPlayerNickname is choosing a topic...', style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            Text('Waiting for $currentRantingPlayerNickname to submit their topic.', style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
          ],
          const SizedBox(height: 30),
          if (isHost)
            ElevatedButton(
              onPressed: _isLoading ? null : () async {
                setState(() => _isLoading = true);
                await firebaseService.skipRantingPlayer(widget.roomCode);
                setState(() => _isLoading = false);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Skip Current Player (Host Only)'),
            ),
        ],
      ),
    );
  }

  // NEW PHASE: ranter sets personal reference, others input guesses - NO TIMER
  Widget _buildRantingPlayerSetupUI(BuildContext context, Map<String, dynamic> roomData, Map<String, dynamic> me, List<dynamic> allPlayers) {
    bool isRantingPlayer = me['isRantingPlayer'] ?? false;
    String topic = roomData['topic'] ?? 'No topic chosen yet.'; // Topic is now set
    String currentRantingPlayerNickname = allPlayers.firstWhereOrNull((p) => (p as Map)['userId'] == roomData['currentRantingPlayerId'])?['nickname'] ?? 'Someone';
    bool myIsReadyInSetupPhase = me['isReadyInSetupPhase'] ?? false;

    // Pre-fill rantText controller for ranter if already set in Firestore
    if (isRantingPlayer) {
      _rantTextController.text = roomData['rantText'] ?? '';
    } else {
      // For guessers, clear guess controllers if they haven't submitted yet
      if (!(me['hasGuessed'] ?? false)) { // Only clear if not already submitted in this phase
        for (var controller in _guessControllers) {
          controller.clear();
        }
      }
    }

    // Determine how many players are ready
    int readyPlayersCount = allPlayers.where((p) => (p as Map)['isReadyInSetupPhase'] == true).length;
    int totalPlayers = allPlayers.length;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Round ${roomData['currentRound'] ?? 1} / ${roomData['totalRounds'] ?? 1}', style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
          const SizedBox(height: 20),
          Text('Topic: "$topic"', style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
          const SizedBox(height: 20),

          if (isRantingPlayer) ...[
            Text('Enter Your Personal Rant Reference (Only you see this):', style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 10),
            Expanded( // Allows rant text field to expand
              child: TextField(
                controller: _rantTextController,
                enabled: !myIsReadyInSetupPhase, // Disable once ranter is ready
                decoration: const InputDecoration(hintText: 'Type your personal reference here'),
                maxLines: null, // Allows multiple lines
                expands: true, // Takes up available vertical space
                keyboardType: TextInputType.multiline,
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 20),
            if (!myIsReadyInSetupPhase)
              ElevatedButton(
                onPressed: _isLoading ? null : () async {
                  setState(() => _isLoading = true);
                  try {
                    await firebaseService.setRanterPersonalReferenceAndReady(
                      widget.roomCode,
                      firebaseService.userId!,
                      _rantTextController.text.trim(),
                    );
                    snackbarKey.currentState?.showSnackBar(const SnackBar(content: Text("Personal reference submitted! Waiting for others...")));
                  } catch (e) {
                    print("DGMS(Setup): Error submitting personal reference and ready: $e");
                    snackbarKey.currentState?.showSnackBar(SnackBar(content: Text("Failed to submit personal reference. Please try again or check the console for details.")));
                  } finally {
                    if (mounted) {
                      setState(() => _isLoading = false);
                    }
                  }
                },
                child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Ready to Rant'),
              )
            else
              Text("Waiting for all players to be ready... ($readyPlayersCount/$totalPlayers ready)", style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
          ] else ...[ // Not the ranting player, but a guesser
            Text('Player $currentRantingPlayerNickname is preparing their rant. Enter Your Guesses:', style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            Text('Your Guesses (What do you think they will rant about?):', style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 10),
            if (!myIsReadyInSetupPhase) // Only show input fields if not yet ready
              ...List.generate(3, (index) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: TextField(
                  controller: _guessControllers[index],
                  decoration: InputDecoration(
                    hintText: 'Guess ${index + 1}',
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
              )),
            if (!myIsReadyInSetupPhase)
              ElevatedButton(
                onPressed: _isLoading ? null : () async {
                  List<String> submittedGuesses = [];
                  for (int i = 0; i < _guessControllers.length; i++) {
                    if (_guessControllers[i].text.trim().isNotEmpty) {
                      submittedGuesses.add(_guessControllers[i].text.trim());
                    }
                  }

                  if (submittedGuesses.isEmpty) {
                    snackbarKey.currentState?.showSnackBar(const SnackBar(content: Text("Please enter at least one guess.")));
                    return;
                  }

                  setState(() => _isLoading = true);
                  try {
                    await firebaseService.submitGuessesAndSetReady(widget.roomCode, firebaseService.userId!, submittedGuesses);
                    snackbarKey.currentState?.showSnackBar(const SnackBar(content: Text("Guesses submitted! Waiting for others...")));
                  } catch (e) {
                    print("DGMS(Setup): Error submitting guesses and ready: $e");
                    snackbarKey.currentState?.showSnackBar(SnackBar(content: Text("Failed to submit guesses. Please try again or check the console for details.")));
                  } finally {
                    if (mounted) {
                      setState(() => _isLoading = false);
                    }
                  }
                },
                child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Submit My Guesses & Ready'),
              )
            else
              Text("Your guesses are submitted. Waiting for all players to be ready... ($readyPlayersCount/$totalPlayers ready)", style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
          ],
        ],
      ),
    );
  }

  Widget _buildGuessingAndRantingUI(BuildContext context, Map<String, dynamic> roomData, Map<String, dynamic> me, List<dynamic> allPlayers) {
    bool isRantingPlayer = me['isRantingPlayer'] ?? false;
    String topic = roomData['topic'] ?? 'No topic chosen yet.';
    String currentRantingPlayerNickname = allPlayers.firstWhereOrNull((p) => (p as Map)['userId'] == roomData['currentRantingPlayerId'])?['nickname'] ?? 'Someone';

    // Ranter's private text for reference
    String rantersPersonalRantText = roomData['rantText'] ?? '';

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Round ${roomData['currentRound'] ?? 1} / ${roomData['totalRounds'] ?? 1}', style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
          const SizedBox(height: 10),
          Text('Topic: "$topic"', style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
          const SizedBox(height: 20),
          // Timer is now active in this phase
          Text('Time Left: $_secondsRemaining seconds', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: _secondsRemaining < 10 ? Colors.redAccent : Colors.white70), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          if (isRantingPlayer) ...[
            Text('Your Rant Time! (Rant verbally based on the topic. This text is for your personal reference.):', style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 10),
            Expanded(
              child: Card(
                color: Theme.of(context).cardColor,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: SingleChildScrollView( // Allow scrolling for long reference text
                    child: Text(rantersPersonalRantText, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic, color: Colors.white)),
                  ),
                ),
              ),
            ),
              // No button needed for ranter here, timer governs transition.
          ] else ...[
            Text('Player $currentRantingPlayerNickname is ranting about: "$topic"', style: Theme.of(context).textTheme.bodyLarge, textAlign: TextAlign.center),
            const SizedBox(height: 10),
            Text('Your Submitted Guesses (Check them against the rant!):', style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: 1, // Only show current player's guesses
                itemBuilder: (context, _) {
                  List<dynamic> myGuesses = List<dynamic>.from(me['guesses'] ?? []);
                  if (myGuesses.isEmpty) return const Center(child: Text("You submitted no guesses for this round."));

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Your guesses:', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          // Display each guess in its own rounded rectangle (read-only)
                          ...myGuesses.asMap().entries.map((entry) {
                            Map<String, dynamic> guess = Map<String, dynamic>.from(entry.value);
                            return Card(
                              color: Theme.of(context).cardColor, // Always default color here
                              margin: const EdgeInsets.symmetric(vertical: 4.0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                                child: Text(guess['text'] ?? '', style: Theme.of(context).textTheme.bodyMedium),
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Text("Waiting for the ranting time to end...", style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
          ],
        ],
      ),
    );
  }

  Widget _buildReviewingGuessesUI(BuildContext context, Map<String, dynamic> roomData, Map<String, dynamic> me, List<dynamic> allPlayers) {
    bool isRantingPlayer = me['isRantingPlayer'] ?? false;
    String topic = roomData['topic'] ?? 'Unknown Topic';
    String rantersPersonalRantText = roomData['rantText'] ?? 'No rant text provided.'; // Only for ranter's display
    String currentRantingPlayerNickname = allPlayers.firstWhereOrNull((p) => (p as Map)['userId'] == roomData['currentRantingPlayerId'])?['nickname'] ?? 'Someone';

    // Ensure timer is stopped as this phase has no time limit
    _stopTimer();
    if (_secondsRemaining != 0) { // Optimize setState calls
      setState(() { _secondsRemaining = 0; });
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Round ${roomData['currentRound'] ?? 1} / ${roomData['totalRounds'] ?? 1}', style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
          const SizedBox(height: 10),
          Text('Topic: "$topic"', style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
          const SizedBox(height: 20),

          if (isRantingPlayer) ...[
            Text("Your Rant (for personal reference):", style: Theme.of(context).textTheme.bodyLarge),
            Card(
              color: Theme.of(context).cardColor,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: SingleChildScrollView( 
                  child: Text(rantersPersonalRantText, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic, color: Colors.white)),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Review Player Guesses:', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: allPlayers.length,
                itemBuilder: (context, playerIndex) {
                  var player = allPlayers[playerIndex] as Map<String, dynamic>;
                  if (player['isRantingPlayer'] == true) return const SizedBox.shrink(); // Don't show ranter's own "guesses" for review

                  List<dynamic> guesses = List<dynamic>.from(player['guesses'] ?? []);
                  if (guesses.isEmpty) return const SizedBox.shrink(); // Hide players who didn't guess

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${player['nickname'] ?? 'Player'} guessed:', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          ...guesses.asMap().entries.map((entry) {
                            int guessIndex = entry.key;
                            Map<String, dynamic> guess = Map<String, dynamic>.from(entry.value);
                            bool isCorrect = guess['isCorrect'] ?? false;

                            return Card( // Individual card for each guess
                              color: isCorrect ? Colors.green.withOpacity(0.2) : Theme.of(context).cardColor,
                              margin: const EdgeInsets.symmetric(vertical: 4.0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.0),
                                side: BorderSide(color: isCorrect ? Colors.greenAccent : Colors.transparent, width: 1.5),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(guess['text'] ?? '', style: Theme.of(context).textTheme.bodyMedium),
                                    ),
                                    // Only ranting player can toggle correctness
                                    IconButton(
                                      icon: Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: isCorrect ? Colors.greenAccent : Colors.grey,
                                            width: 2.0,
                                          ),
                                        ),
                                        child: Icon(isCorrect ? Icons.check : Icons.circle_outlined, 
                                          color: isCorrect ? Colors.greenAccent : Colors.grey,
                                          size: 24,
                                        ),
                                      ),
                                      onPressed: _isLoading ? null : () async {
                                        setState(() => _isLoading = true);
                                        await firebaseService.toggleGuessCorrectness(widget.roomCode, player['userId'], guessIndex, !isCorrect);
                                        setState(() => _isLoading = false);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            // Host (who is also the ranter here) can confirm results
            ElevatedButton(
              onPressed: _isLoading ? null : () async {
                setState(() => _isLoading = true);
                await firebaseService.calculateAndApplyScoresDGMS(widget.roomCode); // Calculate scores and move to results
                setState(() => _isLoading = false);
              },
              child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Confirm Results & Continue'),
            ),
          ] else ...[ // Not the ranting player, just a guesser
            Text('Rant by $currentRantingPlayerNickname:', style: Theme.of(context).textTheme.bodyLarge),
            Card(
              color: Theme.of(context).cardColor,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                // No rant text displayed for non-ranters as it's for personal reference
                child: Text('This is where $currentRantingPlayerNickname ranted.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic, color: Colors.white54)),
              ),
            ),
            const SizedBox(height: 20),
            Text('All Guesses:', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: allPlayers.length,
                itemBuilder: (context, playerIndex) {
                  var player = allPlayers[playerIndex] as Map<String, dynamic>;
                  if (player['isRantingPlayer'] == true) return const SizedBox.shrink(); 

                  List<dynamic> guesses = List<dynamic>.from(player['guesses'] ?? []);
                  if (guesses.isEmpty) return const SizedBox.shrink(); 
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${player['nickname'] ?? 'Player'} guessed:', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          ...guesses.asMap().entries.map((entry) {
                            Map<String, dynamic> guess = Map<String, dynamic>.from(entry.value);
                            bool isCorrect = guess['isCorrect'] ?? false;

                            return Card( 
                              color: isCorrect ? Colors.green.withOpacity(0.2) : Theme.of(context).cardColor,
                              margin: const EdgeInsets.symmetric(vertical: 4.0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.0),
                                side: BorderSide(color: isCorrect ? Colors.greenAccent : Colors.transparent, width: 1.5),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(guess['text'] ?? '', style: Theme.of(context).textTheme.bodyMedium),
                                    ),
                                    Icon(isCorrect ? Icons.check_circle : Icons.radio_button_off, color: isCorrect ? Colors.greenAccent : Colors.grey),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Text("Waiting for $currentRantingPlayerNickname to confirm results...", textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
            )
          ],
        ],
      ),
    );
  }

  Widget _buildRoundResultsUI(BuildContext context, Map<String, dynamic> roomData, Map<String, dynamic> me, List<dynamic> allPlayers) {
    List<dynamic> players = List<dynamic>.from(roomData['players'] ?? []);
    bool isHost = me['isHost'] ?? false;
    int currentRound = roomData['currentRound'] as int? ?? 0;
    int totalRounds = roomData['totalRounds'] as int? ?? 1;

    // Sort players by score descending
    players.sort((a, b) => (b['score'] ?? 0).compareTo(a['score'] ?? 0));

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Round $currentRound Results!', style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
          const SizedBox(height: 20),
          Text('Current Scores:', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: players.length,
              itemBuilder: (context, index) {
                var player = players[index] as Map<String, dynamic>;
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4.0),
                  child: ListTile(
                    title: Text(player['nickname'] ?? 'Player'),
                    trailing: Text("Score: ${player['score'] ?? 0}", style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.lightGreenAccent)),
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
              child: Text(currentRound >= totalRounds ? 'Show Final Results' : 'Start Next Round'),
            )
          else
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Text("Waiting for host...", textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
            )
        ],
      ),
    );
  }

  Widget _buildGameOverUI(BuildContext context, Map<String, dynamic> roomData, List<dynamic> allPlayers) {
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
              onPressed: () => Navigator.popUntil(context, ModalRoute.withName('/home')),
              child: const Text('Return to Home'),
            )
          ],
      ),
    );
  }
}