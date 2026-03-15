import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'dart:async';
import 'package:flutter/services.dart';

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
  final List<TextEditingController> _guessControllers = List.generate(3, (_) => TextEditingController());
  final TextEditingController _rantTextController = TextEditingController();
  final TextEditingController _topicController = TextEditingController();

  Timer? _timer;
  int _secondsRemaining = 0;
  bool _isLoading = false;
  static const int _rantingTimeSeconds = 75;

  @override
  void initState() {
    super.initState();
    firebaseService.getRoomStream(widget.roomCode).listen((snapshot) {
      if (snapshot.exists) {
        Map<String, dynamic> roomData = snapshot.data() as Map<String, dynamic>;
        String gamePhase = roomData['gamePhase'] as String? ?? '';
        Timestamp? timerStartTimeStamp = roomData['timerEndTime'] as Timestamp?;

        if (gamePhase == 'guessingAndRanting' && timerStartTimeStamp != null) {
          DateTime timerEndTime = timerStartTimeStamp.toDate().add(const Duration(seconds: _rantingTimeSeconds));
          _startTimer(timerEndTime);
        } else {
          _stopTimer();
          if (_secondsRemaining != 0) setState(() => _secondsRemaining = 0);
        }
      }
    });
  }

  void _startTimer(DateTime endTime) {
    _stopTimer();
    final now = DateTime.now();
    int initialSeconds = endTime.difference(now).inSeconds;
    if (initialSeconds < 0) initialSeconds = 0;

    if (_secondsRemaining != initialSeconds) setState(() => _secondsRemaining = initialSeconds);

    if (_secondsRemaining > 0) {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) { timer.cancel(); return; }
        if (_secondsRemaining > 0) setState(() => _secondsRemaining--);
        if (_secondsRemaining <= 0) { _stopTimer(); _handleTimerEnd(); }
      });
    } else {
      _handleTimerEnd();
    }
  }

  void _stopTimer() => _timer?.cancel();

  Future<void> _handleTimerEnd() async {
    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentReference roomRef = FirebaseFirestore.instance.collection('rooms').doc(widget.roomCode);
        DocumentSnapshot roomSnap = await transaction.get(roomRef);
        if (!roomSnap.exists) return;

        Map<String, dynamic> roomData = roomSnap.data() as Map<String, dynamic>;
        List<dynamic> players = List<dynamic>.from(roomData['players'] ?? []);
        Map<String, dynamic>? me = players.firstWhereOrNull((p) => (p as Map)['userId'] == firebaseService.userId) as Map<String, dynamic>?;

        if (me != null && (me['isRantingPlayer'] == true) && roomData['gamePhase'] == 'guessingAndRanting') {
          transaction.update(roomRef, {'gamePhase': 'reviewingGuesses'});
        }
      });
    } catch (e) {
      print("DGMS: Timer Error: $e");
    }
  }

  @override
  void dispose() {
    _stopTimer();
    for (var c in _guessControllers) { c.dispose(); }
    _rantTextController.dispose();
    _topicController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF04060E),
      body: Stack(
        children: [
          Positioned(top: -100, right: -50, child: _glowOrb(300, Colors.orangeAccent.withOpacity(0.05))),
          Positioned(bottom: -100, left: -50, child: _glowOrb(300, Colors.redAccent.withOpacity(0.05))),
          
          SafeArea(
            child: StreamBuilder<DocumentSnapshot>(
              stream: firebaseService.getRoomStream(widget.roomCode),
              builder: (context, snapshot) {
                if (!snapshot.hasData || !snapshot.data!.exists) return const Center(child: CircularProgressIndicator());

                Map<String, dynamic> roomData = snapshot.data!.data() as Map<String, dynamic>;
                String phase = roomData['gamePhase'] ?? 'loading';
                List<dynamic> players = List<dynamic>.from(roomData['players'] ?? []);
                Map<String, dynamic>? me = players.firstWhereOrNull((p) => p['userId'] == firebaseService.userId);

                if (me == null) return const Center(child: Text("RECONNECTING..."));

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      _buildHeader(roomData['currentRound'] ?? 1, roomData['totalRounds'] ?? 5, me['score'] ?? 0),
                      const SizedBox(height: 20),
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
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
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text("BROADCAST SESSION", style: TextStyle(color: Colors.white24, fontSize: 10, letterSpacing: 2)),
          Text("ROUND $round/$total", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
        ]),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          const Text("PASSION PTS", style: TextStyle(color: Colors.white24, fontSize: 10, letterSpacing: 2)),
          Text("$score", style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.w900, fontSize: 18)),
        ]),
      ],
    );
  }

  Widget _buildPhaseUI(String phase, Map<String, dynamic> roomData, Map<String, dynamic> me, List<dynamic> players) {
    switch (phase) {
      case 'waitingForTopicSelection': return _buildTopicSelectionUI(roomData, me, players);
      case 'rantingPlayerSetup': return _buildSetupUI(roomData, me, players);
      case 'guessingAndRanting': return _buildRantingUI(roomData, me, players);
      case 'reviewingGuesses': return _buildReviewUI(roomData, me, players);
      case 'roundResults': return _buildRoundResultsUI(roomData, me, players);
      case 'gameOver': return _buildGameOverUI(roomData, players);
      default: return const Center(child: CircularProgressIndicator());
    }
  }

  // --- PHASE 1: TOPIC SELECTION ---
  Widget _buildTopicSelectionUI(Map<String, dynamic> roomData, Map<String, dynamic> me, List<dynamic> players) {
    bool isRanter = me['isRantingPlayer'] ?? false;
    String ranterName = players.firstWhereOrNull((p) => p['userId'] == roomData['currentRantingPlayerId'])?['nickname'] ?? 'Someone';

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(isRanter ? Icons.settings_voice : Icons.hearing, size: 60, color: Colors.orangeAccent),
        const SizedBox(height: 30),
        if (isRanter) ...[
          const Text("YOU ARE ON THE SOAPBOX", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const Text("WHAT IS GRINDING YOUR GEARS?", style: TextStyle(color: Colors.white38, fontSize: 12, letterSpacing: 2)),
          const SizedBox(height: 30),
          _buildTextField(_topicController, "ENTER RANT TOPIC...", key: "topic_${roomData['currentRound']}"),
          const SizedBox(height: 20),
          _buildActionBtn("ANNOUNCE TOPIC", () async {
             if (_topicController.text.isEmpty) return;
             await firebaseService.setRanterTopic(widget.roomCode, firebaseService.userId!, _topicController.text.trim());
          }, color: Colors.orangeAccent),
        ] else ...[
          Text("$ranterName IS CHOOSING...", style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const Text("PREPARE YOUR GUESSES", style: TextStyle(color: Colors.white24, letterSpacing: 2)),
        ],
      ],
    );
  }

  // --- PHASE 2: SETUP (GUESSES & REFERENCE) ---
  Widget _buildSetupUI(Map<String, dynamic> roomData, Map<String, dynamic> me, List<dynamic> players) {
    bool isRanter = me['isRantingPlayer'] ?? false;
    bool isReady = me['isReadyInSetupPhase'] ?? false;

    if (isReady) return _buildStatusCard("DATA TRANSMITTED", "WAITING FOR OTHERS...", Icons.cloud_done, Colors.blueAccent);

    return Column(
      children: [
        _buildTopicBanner(roomData['topic'] ?? "UNKNOWN"),
        const SizedBox(height: 20),
        if (isRanter) ...[
          const Text("PERSONAL RANT NOTES", style: TextStyle(color: Colors.white24, fontSize: 10, letterSpacing: 2)),
          const SizedBox(height: 10),
          Expanded(child: _buildTextField(_rantTextController, "BULLET POINTS FOR YOUR RANT...", expands: true)),
          const SizedBox(height: 20),
          _buildActionBtn("READY TO BROADCAST", () async {
            await firebaseService.setRanterPersonalReferenceAndReady(widget.roomCode, firebaseService.userId!, _rantTextController.text.trim());
          }),
        ] else ...[
          const Text("PREDICT THEIR RANT", style: TextStyle(color: Colors.white24, fontSize: 10, letterSpacing: 2)),
          const SizedBox(height: 20),
          ...List.generate(3, (i) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildTextField(_guessControllers[i], "GUESS ${i+1}...", key: "guess_${i}_${roomData['currentRound']}"),
          )),
          const Spacer(),
          _buildActionBtn("LOCK IN GUESSES", () async {
            List<String> g = _guessControllers.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList();
            if (g.isEmpty) return;
            await firebaseService.submitGuessesAndSetReady(widget.roomCode, firebaseService.userId!, g);
          }),
        ]
      ],
    );
  }

  // --- PHASE 3: RANTING (THE LIVE BROADCAST) ---
  Widget _buildRantingUI(Map<String, dynamic> roomData, Map<String, dynamic> me, List<dynamic> players) {
    bool isRanter = me['isRantingPlayer'] ?? false;
    String ranterName = players.firstWhereOrNull((p) => p['userId'] == roomData['currentRantingPlayerId'])?['nickname'] ?? 'Someone';

    return Column(
      children: [
        _buildTopicBanner(roomData['topic'] ?? "UNKNOWN"),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildPulseDot(),
            const SizedBox(width: 8),
            Text(_secondsRemaining > 0 ? "LIVE: $_secondsRemaining S" : "SIGNAL LOST", 
              style: TextStyle(color: _secondsRemaining < 10 ? Colors.redAccent : Colors.greenAccent, fontWeight: FontWeight.bold, letterSpacing: 2)),
          ],
        ),
        const SizedBox(height: 30),
        if (isRanter) ...[
          const Text("YOUR NOTES:", style: TextStyle(color: Colors.white24, fontSize: 10)),
          const SizedBox(height: 10),
          Expanded(
            child: Container(
              width: double.infinity, padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.02), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)),
              child: SingleChildScrollView(child: Text(roomData['rantText'] ?? "", style: const TextStyle(color: Colors.white70, fontSize: 18, fontStyle: FontStyle.italic))),
            ),
          ),
        ] else ...[
          Text("$ranterName IS ON THE AIR", style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          const Text("CROSS-REFERENCE YOUR GUESSES:", style: TextStyle(color: Colors.white24, fontSize: 10)),
          const SizedBox(height: 10),
          Expanded(child: _buildGuessList(me['guesses'] ?? [])),
        ],
        const SizedBox(height: 20),
      ],
    );
  }

  // --- PHASE 4: REVIEW (SCORING) ---
  Widget _buildReviewUI(Map<String, dynamic> roomData, Map<String, dynamic> me, List<dynamic> players) {
    bool isRanter = me['isRantingPlayer'] ?? false;
    String ranterName = players.firstWhereOrNull((p) => p['userId'] == roomData['currentRantingPlayerId'])?['nickname'] ?? 'Someone';

    return Column(
      children: [
        const Text("POST-BROADCAST REVIEW", style: TextStyle(color: Colors.white24, fontSize: 10, letterSpacing: 2)),
        const SizedBox(height: 20),
        Expanded(
          child: ListView.builder(
            itemCount: players.length,
            itemBuilder: (context, i) {
              final p = players[i];
              if (p['isRantingPlayer'] == true) return const SizedBox.shrink();
              List<dynamic> guesses = p['guesses'] ?? [];
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.02), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p['nickname'].toUpperCase(), style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 12),
                    ...guesses.asMap().entries.map((entry) {
                      bool isCorrect = entry.value['isCorrect'] ?? false;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(entry.value['text'], style: TextStyle(color: isCorrect ? Colors.greenAccent : Colors.white70)),
                        trailing: isRanter ? IconButton(
                          icon: Icon(isCorrect ? Icons.check_circle : Icons.circle_outlined, color: isCorrect ? Colors.greenAccent : Colors.white24),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            firebaseService.toggleGuessCorrectness(widget.roomCode, p['userId'], entry.key, !isCorrect);
                          },
                        ) : Icon(isCorrect ? Icons.check_circle : Icons.circle_outlined, color: isCorrect ? Colors.greenAccent : Colors.white24),
                      );
                    }).toList(),
                  ],
                ),
              );
            },
          ),
        ),
        if (isRanter) _buildActionBtn("FINALIZE DEBRIEF", () => firebaseService.calculateAndApplyScoresDGMS(widget.roomCode)),
      ],
    );
  }

  // --- UI COMPONENTS ---

  Widget _buildTopicBanner(String topic) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.redAccent.withOpacity(0.3))),
      child: Column(children: [
        const Text("TOPIC DETECTED", style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 4)),
        const SizedBox(height: 8),
        Text(topic.toUpperCase(), textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {bool expands = false, String? key}) {
    return Container(
      key: key != null ? ValueKey(key) : null,
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white10)),
      child: TextField(
        controller: controller, maxLines: expands ? null : 1, expands: expands,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(hintText: hint, hintStyle: const TextStyle(color: Colors.white10, fontSize: 14), border: InputBorder.none, contentPadding: const EdgeInsets.all(16)),
      ),
    );
  }

  Widget _buildPulseDot() {
    return Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.redAccent, blurRadius: 10)]));
  }

  Widget _buildGuessList(List<dynamic> guesses) {
    return ListView.builder(
      itemCount: guesses.length,
      itemBuilder: (context, i) => Container(
        margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(12)),
        child: Text(guesses[i]['text'], style: const TextStyle(color: Colors.white70)),
      ),
    );
  }

  Widget _buildActionBtn(String label, VoidCallback onTap, {Color color = Colors.blueAccent}) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(backgroundColor: color, minimumSize: const Size(double.infinity, 60), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2, color: Colors.white)),
    );
  }

  Widget _buildStatusCard(String title, String sub, IconData icon, Color color) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, color: color, size: 60), const SizedBox(height: 20),
      Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, letterSpacing: 2)),
      Text(sub, style: const TextStyle(color: Colors.white24, fontSize: 10)),
    ]));
  }

  Widget _glowOrb(double size, Color color) {
    return Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: color, boxShadow: [BoxShadow(color: color, blurRadius: 100, spreadRadius: 40)]));
  }

  // --- RESULTS PLACEHOLDERS ---
  Widget _buildRoundResultsUI(Map<String, dynamic> roomData, Map<String, dynamic> me, List<dynamic> players) {
     players.sort((a, b) => (b['score'] ?? 0).compareTo(a['score'] ?? 0));
     return Column(children: [
       const Text("ROUND DEBRIEF", style: TextStyle(color: Colors.white24, letterSpacing: 2)),
       const SizedBox(height: 20),
       Expanded(child: ListView.builder(itemCount: players.length, itemBuilder: (context, i) => ListTile(title: Text(players[i]['nickname'], style: const TextStyle(color: Colors.white)), trailing: Text("${players[i]['score']}", style: const TextStyle(color: Colors.orangeAccent))))),
       if (me['isHost'] == true) _buildActionBtn("NEXT ROUND", () => firebaseService.nextRound(widget.roomCode, widget.gameId)),
     ]);
  }

  Widget _buildGameOverUI(Map<String, dynamic> roomData, List<dynamic> players) {
     players.sort((a, b) => (b['score'] ?? 0).compareTo(a['score'] ?? 0));
     return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
       const Icon(Icons.emoji_events, color: Colors.amber, size: 80),
       const Text("BROADCAST OVER", style: TextStyle(color: Colors.white24)),
       Text(players.first['nickname'].toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
       const SizedBox(height: 40),
       _buildActionBtn("EXIT", () => Navigator.popUntil(context, ModalRoute.withName('/home'))),
     ]);
  }
}