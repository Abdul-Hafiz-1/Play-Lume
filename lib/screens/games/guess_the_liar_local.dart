import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/firebase_service.dart';
import '../../logic/liar_engine.dart';
import '../../core/theme.dart';

class LocalGuessTheLiarScreen extends StatefulWidget {
  final List<String> players;
  const LocalGuessTheLiarScreen({super.key, required this.players});

  @override
  State<LocalGuessTheLiarScreen> createState() => _LocalGuessTheLiarScreenState();
}

class _LocalGuessTheLiarScreenState extends State<LocalGuessTheLiarScreen> with TickerProviderStateMixin {
  late LiarEngine engine;
  final TextEditingController _alibiController = TextEditingController();
  late AnimationController _pulseController;
  bool _isScanning = false;
  String? _selectedVote;

  @override
  void initState() {
    super.initState();
    engine = LiarEngine(players: widget.players, allQuestions: firebaseService.guessTheLiarQuestionPairs);
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _alibiController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _advance() {
    HapticFeedback.mediumImpact();
    setState(() => engine.nextState());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBase,
      resizeToAvoidBottomInset: false,
      body: Stack(children: [
        _buildDynamicBackground(),
        SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 600),
            switchInCurve: Curves.easeOutCubic,
            child: _buildPhaseUI(),
          ),
        ),
      ]),
    );
  }

  Widget _buildPhaseUI() {
    // FIX: Exhaustively match all LiarPhase values
    switch (engine.phase) {
      case LiarPhase.setup: return _buildSetup(key: const ValueKey("setup"));
      case LiarPhase.scanning: return _buildScanner(key: const ValueKey("scan"));
      case LiarPhase.secret: return _buildAlibiInput(key: const ValueKey("input"));
      case LiarPhase.pass: return _buildPassScreen(key: const ValueKey("pass"));
      case LiarPhase.interrogation: return _buildInterrogation(key: const ValueKey("interrogation"));
      case LiarPhase.voting: return _buildVotingGrid(key: const ValueKey("vote"));
      case LiarPhase.results: return _buildResults(key: const ValueKey("results"));
      case LiarPhase.finalLeaderboard: return _buildFinalLeaderboard(key: const ValueKey("final"));
    }
  }

  // --- 🏆 FINAL LEADERBOARD (WINNER REVEAL) ---
  Widget _buildFinalLeaderboard({required Key key}) {
    var sortedPlayers = List.from(widget.players);
    sortedPlayers.sort((a, b) => (engine.scores[b] ?? 0).compareTo(engine.scores[a] ?? 0));
    String winner = sortedPlayers.first;

    return Padding(
      key: key,
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        _buildHeader("CAMPAIGN COMPLETE", "ULTIMATE OPERATIVE"),
        const SizedBox(height: 40),
        _buildTacticalCard(
          glowColor: Colors.amber,
          child: Column(children: [
            const Icon(Icons.emoji_events, color: Colors.amber, size: 60),
            const SizedBox(height: 16),
            Text(winner.toUpperCase(), style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w900, color: Colors.white)),
            Text("${engine.scores[winner]} TOTAL POINTS", style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
          ]),
        ),
        const SizedBox(height: 30),
        Expanded(
          child: ListView.builder(
            itemCount: sortedPlayers.length,
            itemBuilder: (context, i) {
              String p = sortedPlayers[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildTacticalCard(
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text("${i + 1}. ${p.toUpperCase()}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    Text("${engine.scores[p]} PTS", style: const TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.w900))
                  ]),
                ),
              );
            },
          ),
        ),
        _buildLumeButton("RETURN TO HQ", () => Navigator.pop(context)),
      ]),
    );
  }

  // --- 🛠️ SETUP ---
  Widget _buildSetup({required Key key}) {
    return Center(key: key, child: Padding(
      padding: const EdgeInsets.all(24.0),
      child: _buildTacticalCard(
        glowColor: AppTheme.primaryBlue,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          _buildSubtitle("NEURAL LINK INITIALIZATION"),
          const SizedBox(height: 30),
          Text("${engine.totalRounds} ROUNDS", style: AppTheme.darkTheme.textTheme.displaySmall),
          Slider(
            value: engine.totalRounds.toDouble(),
            min: 1, max: 10, divisions: 9,
            activeColor: AppTheme.primaryBlue,
            onChanged: (v) => setState(() => engine.totalRounds = v.toInt()),
          ),
          const SizedBox(height: 40),
          _buildLumeButton("ESTABLISH CONNECTION", () => setState(() => engine.startNewRound())),
        ]),
      ),
    ));
  }

  // --- 👁️ SCANNER ---
  Widget _buildScanner({required Key key}) {
    return Center(key: key, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      _buildSubtitle("AUTHENTICATE OPERATIVE"),
      const SizedBox(height: 20),
      Text(widget.players[engine.currentPlayerIndex].toUpperCase(), 
        style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2)),
      const SizedBox(height: 80),
      GestureDetector(
        onLongPressStart: (_) => setState(() => _isScanning = true),
        onLongPressEnd: (_) { setState(() => _isScanning = false); _advance(); },
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (context, _) => Container(
            padding: const EdgeInsets.all(45),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _isScanning ? AppTheme.primaryBlue : Colors.white10, width: 2),
              boxShadow: [
                if (_isScanning) BoxShadow(color: AppTheme.primaryBlue.withOpacity(0.4 * _pulseController.value), blurRadius: 50, spreadRadius: 15)
              ],
            ),
            child: Icon(Icons.fingerprint, size: 90, color: _isScanning ? AppTheme.primaryBlue : Colors.white10),
          ),
        ),
      ),
    ]));
  }

  // --- 📝 ALIBI INPUT ---
  Widget _buildAlibiInput({required Key key}) {
    bool isLiar = engine.currentPlayerIndex == engine.liarIndex;
    return Padding(key: key, padding: const EdgeInsets.all(24), child: Column(children: [
      _buildHeader("MISSION BRIEF", "ENCRYPTED DATA"),
      const SizedBox(height: 30),
      _buildTacticalCard(
        glowColor: isLiar ? Colors.redAccent : AppTheme.primaryBlue,
        child: Column(children: [
          _buildSubtitle(isLiar ? "INFILTRATOR OBJECTIVE" : "INTEL SUBJECT"),
          const SizedBox(height: 12),
          Text(isLiar ? engine.currentPair.liar.toUpperCase() : engine.currentPair.original.toUpperCase(), 
            textAlign: TextAlign.center, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
        ]),
      ),
      const SizedBox(height: 40),
      TextField(
        controller: _alibiController,
        style: const TextStyle(color: Colors.white, fontSize: 18),
        decoration: InputDecoration(
          hintText: "TYPE YOUR ALIBI...",
          filled: true,
          fillColor: Colors.white.withOpacity(0.05),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
        ),
      ),
      const SizedBox(height: 30),
      _buildLumeButton("UPLOAD & PURGE", () {
        if (_alibiController.text.isEmpty) return;
        engine.playerAnswers[widget.players[engine.currentPlayerIndex]] = _alibiController.text;
        _alibiController.clear();
        _advance();
      }),
    ]));
  }

  // --- 🕵️ INTERROGATION ---
  Widget _buildInterrogation({required Key key}) {
    return Padding(key: key, padding: const EdgeInsets.all(24), child: Column(children: [
      _buildHeader("FIELD REPORT", "VOTING COMMENCES SOON"),
      const SizedBox(height: 20),
      Expanded(
        child: ListView(
          children: engine.playerAnswers.entries.map((e) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildTacticalCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(e.key.toUpperCase(), style: const TextStyle(color: AppTheme.primaryBlue, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)),
                  const SizedBox(height: 6),
                  Text(e.value, style: const TextStyle(color: Colors.white, fontSize: 16)),
                ]),
              ),
            );
          }).toList(),
        ),
      ),
      const SizedBox(height: 20),
      _buildLumeButton("INITIATE VOTE", _advance),
    ]));
  }

  // --- 🗳️ VOTING GRID ---
  Widget _buildVotingGrid({required Key key}) {
    return Padding(key: key, padding: const EdgeInsets.all(24), child: Column(children: [
      _buildHeader("IDENTIFY TARGET", "VOTER: ${widget.players[engine.currentPlayerIndex]}"),
      const SizedBox(height: 24),
      Expanded(
        child: GridView.count(
          crossAxisCount: 2, mainAxisSpacing: 16, crossAxisSpacing: 16,
          children: widget.players.where((p) => p != widget.players[engine.currentPlayerIndex]).map((p) => GestureDetector(
            onTap: () => setState(() => _selectedVote = p),
            child: _buildTacticalCard(
              glowColor: _selectedVote == p ? AppTheme.primaryBlue : Colors.transparent,
              child: Center(child: Text(p.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12))),
            ),
          )).toList(),
        ),
      ),
      _buildLumeButton("CAST VOTE", () { if (_selectedVote != null) { engine.votes[widget.players[engine.currentPlayerIndex]] = _selectedVote!; _selectedVote = null; _advance(); } }),
    ]));
  }

  // --- 📊 ROUND RESULTS ---
  Widget _buildResults({required Key key}) {
    return Padding(key: key, padding: const EdgeInsets.all(24), child: Column(children: [
      _buildHeader("DEBRIEFING", "THE LIAR WAS ${widget.players[engine.liarIndex]}"),
      const SizedBox(height: 30),
      Expanded(
        child: ListView(
          children: widget.players.map((p) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildTacticalCard(
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(p.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  Text("${engine.scores[p]} PTS", style: const TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.w900))
                ]),
              ),
            );
          }).toList(),
        ),
      ),
      _buildLumeButton(engine.currentRound < engine.totalRounds ? "NEXT MISSION" : "VIEW FINAL STANDINGS", () { 
        if (engine.currentRound < engine.totalRounds) { 
          setState(() { engine.currentRound++; engine.startNewRound(); }); 
        } else { setState(() => engine.phase = LiarPhase.finalLeaderboard); } 
      }),
    ]),
  );
}

  // --- ✋ PASS SCREEN ---
  Widget _buildPassScreen({required Key key}) => Center(key: key, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    const Icon(Icons.security, color: Colors.amber, size: 70),
    const SizedBox(height: 30),
    _buildSubtitle("SECURE HANDOVER"),
    Text(widget.players[engine.currentPlayerIndex + 1].toUpperCase(), style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Colors.white)),
    const SizedBox(height: 60),
    _buildLumeButton("I AM THE OPERATIVE", _advance),
  ]));

  // --- 💎 UI ATOMS ---
  Widget _buildHeader(String title, String sub) => Column(children: [
    _buildSubtitle(title),
    const SizedBox(height: 8),
    Text(sub, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1)),
    const SizedBox(height: 4),
    Container(width: 40, height: 3, decoration: BoxDecoration(color: AppTheme.primaryBlue, borderRadius: BorderRadius.circular(10))),
  ]);

  Widget _buildSubtitle(String text) => Text(text, style: const TextStyle(color: AppTheme.primaryBlue, letterSpacing: 4, fontSize: 10, fontWeight: FontWeight.bold));

  Widget _buildTacticalCard({required Widget child, Color? glowColor, double blur = 15.0}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: (glowColor ?? Colors.white).withOpacity(0.12), width: 1.5),
            boxShadow: [if (glowColor != null) BoxShadow(color: glowColor.withOpacity(0.05), blurRadius: 40, spreadRadius: -10)],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildLumeButton(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity, height: 65,
        decoration: BoxDecoration(
          color: AppTheme.primaryBlue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.primaryBlue, width: 1.5),
          boxShadow: [BoxShadow(color: AppTheme.primaryBlue.withOpacity(0.2), blurRadius: 20, spreadRadius: -5)],
        ),
        child: Center(child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 14))),
      ),
    );
  }

  Widget _buildDynamicBackground() {
    return Stack(children: [
      Positioned(top: -100, left: -50, child: _orb(400, AppTheme.primaryBlue.withOpacity(0.12))),
      Positioned(bottom: -150, right: -50, child: _orb(500, Colors.purple.withOpacity(0.08))),
      Container(color: AppTheme.darkBase.withOpacity(0.8)),
    ]);
  }

  Widget _orb(double size, Color color) => Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: color));
}