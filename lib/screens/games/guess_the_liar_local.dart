import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/firebase_service.dart';
import '../../logic/liar_engine.dart';

class LocalGuessTheLiarScreen extends StatefulWidget {
  final List<String> players;
  const LocalGuessTheLiarScreen({super.key, required this.players});

  @override
  State<LocalGuessTheLiarScreen> createState() => _LocalGuessTheLiarScreenState();
}

class _LocalGuessTheLiarScreenState extends State<LocalGuessTheLiarScreen> {
  late LiarEngine engine;
  final TextEditingController _inputController = TextEditingController();
  bool _isScanning = false;
  bool _hideInput = true;
  String? _selectedVote;

  @override
  void initState() {
    super.initState();
    engine = LiarEngine(
      players: widget.players,
      allQuestions: firebaseService.guessTheLiarQuestionPairs,
    );
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020408),
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: _buildPhaseUI(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseUI() {
    switch (engine.phase) {
      case LiarPhase.setup: return _buildSetup();
      case LiarPhase.scanning: return _buildScanner();
      case LiarPhase.secret: return _buildSecretInput();
      case LiarPhase.pass: return _buildPassScreen();
      case LiarPhase.interrogation: return _buildInterrogation();
      case LiarPhase.voting: return _buildVotingGrid();
      case LiarPhase.results: return _buildRoundResults();
      default: return const CircularProgressIndicator();
    }
  }

  // --- 💎 PREMIUM GLASS COMPONENTS ---

  Widget _buildScanner() {
    return Column(children: [
      _buildGlassCard(child: Column(children: [
        const Text("NEURAL CHECK", style: TextStyle(color: Colors.blueAccent, fontSize: 10, letterSpacing: 2)),
        const SizedBox(height: 15),
        Text(widget.players[engine.currentPlayerIndex].toUpperCase(), 
          style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 2)),
      ])),
      const SizedBox(height: 60),
      GestureDetector(
        onLongPressStart: (_) {
          HapticFeedback.heavyImpact();
          setState(() => _isScanning = true);
        },
        onLongPressEnd: (_) {
          setState(() {
            _isScanning = false;
            engine.nextState();
          });
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (_isScanning) 
              const SizedBox(width: 100, height: 100, child: CircularProgressIndicator(color: Colors.blueAccent, strokeWidth: 2)),
            Icon(Icons.fingerprint, color: _isScanning ? Colors.blueAccent : Colors.white24, size: 80),
          ],
        ),
      ),
      const SizedBox(height: 20),
      const Text("HOLD TO AUTHENTICATE", style: TextStyle(color: Colors.white24, fontSize: 10, fontFamily: 'monospace')),
    ]);
  }

  Widget _buildSecretInput() {
    bool isLiar = engine.currentPlayerIndex == engine.liarIndex;
    return Column(children: [
      _buildGlassCard(
        child: Column(children: [
          const Text("MISSION DATA", style: TextStyle(color: Colors.blueAccent, fontSize: 10, letterSpacing: 2)),
          const SizedBox(height: 20),
          Text(isLiar ? engine.currentPair.liar.toUpperCase() : engine.currentPair.original.toUpperCase(), 
            textAlign: TextAlign.center, 
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        ]),
      ),
      const SizedBox(height: 30),
      TextField(
        controller: _inputController,
        obscureText: _hideInput,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white, fontSize: 20, letterSpacing: 2),
        decoration: InputDecoration(
          hintText: "TYPE YOUR ALIBI",
          hintStyle: const TextStyle(color: Colors.white10),
          suffixIcon: IconButton(
            icon: Icon(_hideInput ? Icons.visibility : Icons.visibility_off, color: Colors.white24),
            onPressed: () => setState(() => _hideInput = !_hideInput),
          ),
        ),
      ),
      const SizedBox(height: 40),
      _buildButton("ENCRYPT & PURGE", () {
        if (_inputController.text.trim().isEmpty) return;
        engine.playerAnswers[widget.players[engine.currentPlayerIndex]] = _inputController.text.trim();
        _inputController.clear();
        _hideInput = true;
        setState(() => engine.nextState());
      }),
    ]);
  }

  Widget _buildPassScreen() {
    // Determine who is next safely
    String nextPlayer = widget.players[engine.currentPlayerIndex + 1];

    return Column(children: [
      const Icon(Icons.security, color: Colors.amber, size: 60),
      const SizedBox(height: 30),
      _buildGlassCard(
        child: Column(children: [
          const Text("SECURE HANDOVER", style: TextStyle(color: Colors.amber, letterSpacing: 4, fontWeight: FontWeight.bold, fontSize: 10)),
          const SizedBox(height: 20),
          Text(nextPlayer.toUpperCase(), 
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 2)),
          const SizedBox(height: 10),
          const Text("ENSURE NO ONE ELSE IS WATCHING", style: TextStyle(color: Colors.white24, fontSize: 9)),
        ]),
      ),
      const SizedBox(height: 40),
      _buildButton("I AM $nextPlayer", () {
        HapticFeedback.mediumImpact();
        setState(() => engine.nextState());
      }),
    ]);
  }

  Widget _buildVotingGrid() {
    String voter = widget.players[engine.currentPlayerIndex];
    return Column(children: [
      const Text("ANONYMOUS BALLOT", style: TextStyle(color: Colors.amber, letterSpacing: 4, fontWeight: FontWeight.bold, fontSize: 10)),
      const SizedBox(height: 20),
      _buildGlassCard(child: Text("VOTER: ${voter.toUpperCase()}", style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold))),
      const SizedBox(height: 20),
      GridView.count(
        shrinkWrap: true,
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        physics: const NeverScrollableScrollPhysics(),
        children: widget.players.where((p) => p != voter).map((p) => GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _selectedVote = p);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: _selectedVote == p ? Colors.blueAccent.withOpacity(0.2) : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _selectedVote == p ? Colors.blueAccent : Colors.white10),
            ),
            child: Center(child: Text(p.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          ),
        )).toList(),
      ),
      const SizedBox(height: 40),
      _buildButton("CONFIRM VOTE", () {
        if (_selectedVote == null) return;
        engine.votes[voter] = _selectedVote!;
        _selectedVote = null;
        setState(() => engine.nextState());
      }),
    ]);
  }

  // --- REUSED HELPERS ---

  Widget _buildSetup() {
    return _buildGlassCard(
      child: Column(children: [
        const Text("MISSION DEPTH", style: TextStyle(color: Colors.blueAccent, letterSpacing: 4, fontWeight: FontWeight.bold, fontSize: 11)),
        const SizedBox(height: 20),
        Text("${engine.totalRounds} ROUNDS", style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
        Slider(
          value: engine.totalRounds.toDouble(),
          min: 1, max: 10, divisions: 9,
          activeColor: Colors.blueAccent,
          onChanged: (v) => setState(() => engine.totalRounds = v.toInt()),
        ),
        const SizedBox(height: 30),
        _buildButton("ESTABLISH LINK", () => setState(() => engine.startNewRound())),
      ]),
    );
  }

  Widget _buildInterrogation() {
    return Column(children: [
      const Text("NEURAL DISCORD DETECTED", style: TextStyle(color: Colors.redAccent, letterSpacing: 4, fontWeight: FontWeight.bold, fontSize: 10)),
      const SizedBox(height: 30),
      _buildGlassCard(child: Column(children: [
        const Text("OPERATIVE REFERENCE QUESTION:", style: TextStyle(color: Colors.white24, fontSize: 9)),
        const SizedBox(height: 10),
        Text(engine.currentPair.original.toUpperCase(), textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      ])),
      const SizedBox(height: 20),
      ...widget.players.map((p) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: _buildGlassCard(child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(p, style: const TextStyle(color: Colors.white38)),
            Text(engine.playerAnswers[p]?.toUpperCase() ?? "---", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        )),
      )),
      const SizedBox(height: 30),
      _buildButton("INITIATE BALLOT", () => setState(() => engine.nextState())),
    ]);
  }

  Widget _buildRoundResults() {
    String liar = widget.players[engine.liarIndex];
    return Column(children: [
      const Icon(Icons.radar, color: Colors.blueAccent, size: 60),
      const SizedBox(height: 20),
      _buildGlassCard(child: Column(children: [
        const Text("INFILTRATOR IDENTIFIED", style: TextStyle(color: Colors.blueAccent, fontSize: 10, letterSpacing: 4)),
        const SizedBox(height: 15),
        Text(liar.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
      ])),
      const SizedBox(height: 40),
      _buildButton("NEXT MISSION", () {
        if (engine.currentRound < engine.totalRounds) {
          engine.currentRound++;
          setState(() => engine.startNewRound());
        } else {
          Navigator.pop(context);
        }
      }),
    ]);
  }

  Widget _buildGlassCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03), 
        borderRadius: BorderRadius.circular(25), 
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: child,
    );
  }

  Widget _buildButton(String text, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.blueAccent.withOpacity(0.1), blurRadius: 20)],
      ),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent.withOpacity(0.1), 
          side: const BorderSide(color: Colors.blueAccent),
          minimumSize: const Size(double.infinity, 65),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2)),
      ),
    );
  }

  Widget _buildBackground() {
    return Positioned.fill(
      child: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topLeft, radius: 1.5, 
            colors: [Color(0xFF0A0E21), Color(0xFF020408)],
          ),
        ),
      ),
    );
  }
}