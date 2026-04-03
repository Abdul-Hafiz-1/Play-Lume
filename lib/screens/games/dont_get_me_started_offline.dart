import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../logic/dont_get_me_started_engine.dart';
import '../../core/theme.dart';

class LocalRantScreen extends StatefulWidget {
  final List<String> players;
  const LocalRantScreen({super.key, required this.players});

  @override
  State<LocalRantScreen> createState() => _LocalRantScreenState();
}

class _LocalRantScreenState extends State<LocalRantScreen> with TickerProviderStateMixin {
  late RantEngine engine;
  final TextEditingController _topicController = TextEditingController();
  final List<TextEditingController> _guessControllers = List.generate(3, (_) => TextEditingController());
  
  Timer? _timer;
  int _secondsRemaining = 75;
  int _currentGuesserIndex = 0;

  @override
  void initState() {
    super.initState();
    engine = RantEngine(players: widget.players);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _topicController.dispose();
    for (var c in _guessControllers) c.dispose();
    super.dispose();
  }

  void _startTimer() {
    _secondsRemaining = 75;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_secondsRemaining > 0) {
            _secondsRemaining--;
          } else {
            _timer?.cancel();
            _advance();
          }
        });
      }
    });
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
        _buildDeepSpaceBackground(),
        SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 600),
            child: _buildPhaseUI(),
          ),
        ),
      ]),
    );
  }

  Widget _buildPhaseUI() {
    switch (engine.phase) {
      case RantPhase.setup: return _buildSetup(key: const ValueKey("setup"));
      case RantPhase.topicInput: return _buildTopicInput(key: const ValueKey("topic"));
      case RantPhase.groupGuessing: return _buildGuessingLoop(key: const ValueKey("guess"));
      case RantPhase.ranting: return _buildRantTimer(key: const ValueKey("rant"));
      case RantPhase.ranterReview: return _buildRanterReview(key: const ValueKey("review"));
      case RantPhase.results: return _buildResults(key: const ValueKey("results"));
    }
  }

  // --- 1. SETUP (ROUND SELECTION) ---
  Widget _buildSetup({required Key key}) {
    return Center(
      key: key,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: _buildTacticalCard(
          glowColor: AppTheme.primaryBlue,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _buildSubtitle("MISSION PARAMETERS"),
            const SizedBox(height: 24),
            Text("${engine.totalRounds} ROUNDS", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white)),
            const SizedBox(height: 10),
            Slider(
              value: engine.totalRounds.toDouble(),
              min: 1, max: 10, divisions: 9,
              activeColor: AppTheme.primaryBlue,
              onChanged: (v) => setState(() => engine.totalRounds = v.toInt()),
            ),
            const SizedBox(height: 30),
            _buildLumeButton("INITIALIZE LINK", () => setState(() => engine.startNewRound())),
          ]),
        ),
      ),
    );
  }

  // --- 2. TOPIC INPUT ---
  Widget _buildTopicInput({required Key key}) {
    return Padding(key: key, padding: const EdgeInsets.all(24), child: Column(children: [
      _buildHeader("SECRET PROTOCOL", "RANTER: ${widget.players[engine.ranterIndex]}"),
      const SizedBox(height: 40),
      _buildTacticalCard(
        glowColor: Colors.orangeAccent,
        child: TextField(
          controller: _topicController,
          style: const TextStyle(color: Colors.white, fontSize: 18),
          decoration: const InputDecoration(hintText: "WHAT IS THE TOPIC?", border: InputBorder.none, hintStyle: TextStyle(color: Colors.white24)),
        ),
      ),
      const Spacer(),
      _buildLumeButton("CONFIRM TOPIC", () {
        if (_topicController.text.isEmpty) return;
        engine.currentTopic = _topicController.text;
        _advance();
      }),
    ]));
  }

  // --- 3. GUESSING LOOP ---
  Widget _buildGuessingLoop({required Key key}) {
    List<String> guessers = widget.players.where((p) => p != widget.players[engine.ranterIndex]).toList();
    String currentGuesser = guessers[_currentGuesserIndex];

    return Padding(key: key, padding: const EdgeInsets.all(24), child: Column(children: [
      _buildHeader("GUESSING PHASE", "GUESSER: $currentGuesser"),
      _buildTacticalCard(child: Text("TOPIC: ${engine.currentTopic}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
      const SizedBox(height: 24),
      ...List.generate(3, (i) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _buildTacticalCard(
          child: TextField(
            controller: _guessControllers[i],
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(hintText: "GUESS ${i+1}", border: InputBorder.none, hintStyle: const TextStyle(color: Colors.white10)),
          ),
        ),
      )),
      const Spacer(),
      _buildLumeButton("ENCRYPT GUESSES", () {
        engine.playerGuesses[currentGuesser] = _guessControllers.map((c) => c.text).toList();
        for (var c in _guessControllers) c.clear();
        if (_currentGuesserIndex < guessers.length - 1) {
          setState(() => _currentGuesserIndex++);
        } else {
          _currentGuesserIndex = 0;
          _startTimer(); // Timer starts AFTER everyone guesses
          _advance();
        }
      }),
    ]));
  }

  // --- 4. RANT TIMER ---
  Widget _buildRantTimer({required Key key}) {
    return Center(key: key, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      _buildSubtitle("LIVE RANT"),
      const SizedBox(height: 10),
      Text(widget.players[engine.ranterIndex].toUpperCase(), style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Colors.white)),
      const SizedBox(height: 50),
      _buildTacticalCard(
        glowColor: Colors.redAccent,
        child: Column(children: [
          Text("$_secondsRemaining", style: const TextStyle(fontSize: 80, fontWeight: FontWeight.bold, color: Colors.redAccent)),
          const Text("SECONDS REMAINING", style: TextStyle(color: Colors.redAccent, letterSpacing: 2, fontSize: 10, fontWeight: FontWeight.bold)),
        ]),
      ),
      const SizedBox(height: 60),
      _buildLumeButton("STOP & REVIEW", () {
        _timer?.cancel();
        _advance();
      }),
    ]));
  }

  // --- 5. RANTER REVIEW ---
  Widget _buildRanterReview({required Key key}) {
    return Padding(key: key, padding: const EdgeInsets.all(24), child: Column(children: [
      _buildHeader("JUDGMENT PHASE", "JUDGE: ${widget.players[engine.ranterIndex]}"),
      _buildTacticalCard(glowColor: Colors.orangeAccent, child: Text("TOPIC: ${engine.currentTopic}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
      const SizedBox(height: 20),
      Expanded(
        child: ListView(
          children: engine.playerGuesses.entries.map((entry) {
            engine.correctGuesses.putIfAbsent(entry.key, () => [false, false, false]);
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildTacticalCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(entry.key.toUpperCase(), style: const TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold, fontSize: 10)),
                  ...List.generate(3, (i) => CheckboxListTile(
                    title: Text(entry.value[i].isEmpty ? "NO GUESS" : entry.value[i], style: const TextStyle(color: Colors.white70, fontSize: 14)),
                    value: engine.correctGuesses[entry.key]![i],
                    activeColor: AppTheme.primaryBlue,
                    onChanged: (val) => setState(() => engine.correctGuesses[entry.key]![i] = val!),
                  )),
                ]),
              ),
            );
          }).toList(),
        ),
      ),
      _buildLumeButton("FINALIZE ROUND", _advance),
    ]));
  }

  // --- 6. RESULTS ---
  Widget _buildResults({required Key key}) {
    return Padding(key: key, padding: const EdgeInsets.all(24), child: Column(children: [
      _buildHeader("ROUND DEBRIEF", "STANDINGS"),
      const SizedBox(height: 20),
      Expanded(
        child: ListView(
          children: widget.players.map((p) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildTacticalCard(child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(p.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              Text("${engine.scores[p]} PTS", style: const TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.w900)),
            ])),
          )).toList(),
        ),
      ),
      _buildLumeButton(engine.currentRound < engine.totalRounds ? "NEXT MISSION" : "TERMINATE", () {
        if (engine.currentRound < engine.totalRounds) {
          engine.currentRound++;
          engine.startNewRound();
          setState(() {});
        } else {
          Navigator.pop(context);
        }
      }),
    ]));
  }

  // --- 💎 GLASS UI ATOMS ---

  Widget _buildTacticalCard({required Widget child, Color? glowColor}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: (glowColor ?? Colors.white).withOpacity(0.15), width: 1.5),
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
          boxShadow: [BoxShadow(color: AppTheme.primaryBlue.withOpacity(0.3), blurRadius: 20, spreadRadius: -5)],
        ),
        child: Center(child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2))),
      ),
    );
  }

  Widget _buildHeader(String title, String sub) => Column(children: [
    _buildSubtitle(title),
    const SizedBox(height: 8),
    Text(sub, textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white)),
    const SizedBox(height: 12),
  ]);

  Widget _buildSubtitle(String text) => Text(text, style: const TextStyle(color: AppTheme.primaryBlue, letterSpacing: 4, fontSize: 10, fontWeight: FontWeight.bold));

  Widget _buildDeepSpaceBackground() => Stack(children: [
    Positioned(top: -150, right: -100, child: _orb(500, AppTheme.primaryBlue.withOpacity(0.15))),
    Positioned(bottom: -150, left: -100, child: _orb(500, Colors.purple.withOpacity(0.1))),
    Container(color: AppTheme.darkBase.withOpacity(0.85)),
  ]);

  Widget _orb(double size, Color color) => Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: color));
}