import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:vibration/vibration.dart';
import 'package:wakelock_plus/wakelock_plus.dart'; // 
import '../../models/heads_up_data.dart';
import '../../core/theme.dart';

class HeadsUpGameScreen extends StatefulWidget {
  final List<String> players;
  const HeadsUpGameScreen({super.key, required this.players});

  @override
  State<HeadsUpGameScreen> createState() => _HeadsUpGameScreenState();
}

class _HeadsUpGameScreenState extends State<HeadsUpGameScreen> with TickerProviderStateMixin {
  int _currentPlayerIndex = 0;
  int _selectedDeckIndex = 0;
  String _phase = 'selection'; 
  int _countdown = 3;
  int _timeLeft = 60;
  String _currentWord = "";
  int _score = 0;
  final List<Map<String, dynamic>> _roundLogs = [];
  final Map<String, int> _finalScores = {};

  StreamSubscription? _sensorSub;
  bool _inputLocked = false;
  double _zAxis = 0.0;
  double _yAxis = 0.0;
  late AnimationController _glowController;
  late AnimationController _orbController;
  
  Color _activeGlow = AppTheme.glowBlue;
  final Color _correctColor = const Color(0xFF10B981); 
  final Color _skipColor = const Color(0xFFF59E0B);    
  final Color _criticalColor = const Color(0xFFEF4444);

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
    WakelockPlus.enable(); // 🔥 SCREEN WILL NOT SLEEP
    
    _glowController = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
    _orbController = AnimationController(vsync: this, duration: const Duration(seconds: 15))..repeat();
    _initSensors();
  }

  void _initSensors() {
  _sensorSub = accelerometerEvents.listen((event) {
    if (!mounted) return;
    
    // ONLY listen for tilts if the phase is exactly 'playing'
    if (_phase == 'playing' && !_inputLocked) {
      setState(() { _zAxis = event.z; _yAxis = event.y; });

      if (event.z > 7.0 || event.y > 7.0) {
        _handleAction(true); // Tilt Down
      } else if (event.z < -7.0 || event.y < -7.0) {
        _handleAction(false); // Tilt Up
      }
    }
  });
}

  void _handleAction(bool correct) async {
    setState(() {
      _inputLocked = true; 
      _activeGlow = correct ? _correctColor : _skipColor;
      if (correct) _score++;
      _roundLogs.add({'word': _currentWord, 'correct': correct});
    });

    if (correct) {
      Vibration.vibrate(pattern: [0, 80, 40, 80]); // Success thump
    } else {
      Vibration.vibrate(duration: 350); // Skip buzz
    }

    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) {
        setState(() {
          _activeGlow = _timeLeft <= 3 ? _criticalColor : AppTheme.glowBlue;
          _nextWord();
          _inputLocked = false;
        });
      }
    });
  }

  void _startCountdownPhase() {
    setState(() { _phase = 'countdown'; _countdown = 3; });
    Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      if (_countdown > 1) {
        setState(() => _countdown--);
        Vibration.vibrate(duration: 80); // Tick
      } else {
        t.cancel();
        _startRound();
      }
    });
  }

  void _startRound() {
    setState(() { _phase = 'playing'; _timeLeft = 60; _score = 0; _roundLogs.clear(); _nextWord(); });
    Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      if (_timeLeft > 0) {
        setState(() {
          _timeLeft--;
          if (_timeLeft <= 3) {
            Vibration.vibrate(duration: 400); // Danger Buzz
          }
        });
      } else {
        t.cancel();
        _finalScores[widget.players[_currentPlayerIndex]] = _score;
        setState(() => _phase = 'debrief');
      }
    });
  }

  // Update this in lib/screens/games/heads_up_game_screen.dart

void _moveToNextStep() {
  // Save the current score to the final leaderboard map first
  _finalScores[widget.players[_currentPlayerIndex]] = _score;

  if (_currentPlayerIndex < widget.players.length - 1) {
    // There are more players left
    setState(() {
      _currentPlayerIndex++;
      _phase = 'selection'; // Reset to selection for next operative
      _score = 0; // Reset score for the new player
      _roundLogs.clear(); // Clear logs for new player
    });
  } else {
    // All players have finished
    setState(() => _phase = 'final_leaderboard');
  }
}

  void _nextWord() {
    List<String> deck;
    if (HeadsUpData.decks[_selectedDeckIndex].category == "RANDOM MIX") {
      deck = HeadsUpData.getAllWords();
    } else {
      deck = HeadsUpData.decks[_selectedDeckIndex].words;
    }
    setState(() => _currentWord = (List.from(deck)..shuffle()).first);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF04060E),
      body: Stack(
        children: [
          _buildDynamicMeshBackground(),
          SafeArea(child: _buildPhaseUI()),
        ],
      ),
    );
  }

  Widget _buildPhaseUI() {
    switch (_phase) {
      case 'selection': return _buildDossierSelection();
      case 'countdown': return Center(child: Text("$_countdown", style: const TextStyle(fontSize: 120, fontWeight: FontWeight.bold, color: Colors.white)));
      case 'playing': return _buildGameplay();
      case 'debrief': return _buildDebrief();
      case 'final_leaderboard': return _buildFinalLeaderboard();
      default: return const SizedBox();
    }
  }

  Widget _buildGameplay() {
    bool isCritical = _timeLeft <= 3;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("$_timeLeft", style: TextStyle(fontSize: 30, color: isCritical ? _criticalColor : Colors.white24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _buildGlassCard(
            glow: _activeGlow,
            isGameplay: true,
            child: Center(
              child: Text(_currentWord, textAlign: TextAlign.center, 
                style: TextStyle(
                  fontSize: _currentWord.length > 10 ? 40 : 60, 
                  fontWeight: FontWeight.w900, color: Colors.white,
                  shadows: [Shadow(color: _activeGlow.withOpacity(0.8), blurRadius: 30)],
                )),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDebrief() {
    var correct = _roundLogs.where((l) => l['correct']).toList();
    var skipped = _roundLogs.where((l) => !l['correct']).toList();

    return Column(
      children: [
        _buildHeader("MISSION REPORT: ${widget.players[_currentPlayerIndex]}"),
        const SizedBox(height: 10),
        Text("$_score SECURED", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 15),
        Expanded(
          child: Row(
            children: [
              _buildDebriefColumn("INTEL SECURED", correct, _correctColor),
              _buildDebriefColumn("INTEL LOST", skipped, _skipColor),
            ],
          ),
        ),
        _buildActionBtn(
        (_currentPlayerIndex < widget.players.length - 1) 
          ? "READY NEXT OPERATIVE" 
          : "VIEW FINAL RANKINGS", 
        _moveToNextStep
      ),
      ],
    );
  }

  Widget _buildDebriefColumn(String title, List<Map<String, dynamic>> items, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(title, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, i) => Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(items[i]['word'], style: const TextStyle(color: Colors.white60, fontSize: 13)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassCard({required Widget child, Color glow = Colors.transparent, bool isGameplay = false}) {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, _) => Container(
        width: isGameplay ? MediaQuery.of(context).size.width * 0.8 : 280,
        height: isGameplay ? 180 : 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: glow.withOpacity(0.5), width: 1.5),
          boxShadow: [
            BoxShadow(color: glow.withOpacity(0.4 * _glowController.value), blurRadius: 30, spreadRadius: 2),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(40),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(color: Colors.white.withOpacity(0.08), child: child),
          ),
        ),
      ),
    );
  }

  Widget _buildDynamicMeshBackground() {
    bool isCritical = _timeLeft <= 3 && _phase == 'playing';
    return AnimatedBuilder(
      animation: _orbController,
      builder: (context, _) => Stack(
        children: [
          Positioned(top: -100, left: -100 + (50 * sin(_orbController.value * 2 * pi)), 
            child: _buildOrb(400, (isCritical ? _criticalColor : _correctColor).withOpacity(0.12))),
          Positioned(bottom: -100, right: -100 + (50 * cos(_orbController.value * 2 * pi)), 
            child: _buildOrb(500, (isCritical ? _criticalColor : AppTheme.glowBlue).withOpacity(0.12))),
        ],
      ),
    );
  }

  Widget _buildOrb(double size, Color color) => Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [color, Colors.transparent])));
  Widget _buildHeader(String title) => Padding(padding: const EdgeInsets.all(15), child: Text(title.toUpperCase(), style: const TextStyle(color: AppTheme.glowBlue, letterSpacing: 4, fontSize: 10)));
  Widget _buildActionBtn(String text, VoidCallback onTap) => Padding(padding: const EdgeInsets.all(15), child: GestureDetector(onTap: onTap, child: Container(height: 45, decoration: BoxDecoration(color: AppTheme.primaryBlue, borderRadius: BorderRadius.circular(15)), child: Center(child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))))));

  Widget _buildDossierSelection() {
    return Column(
      children: [
        _buildHeader("SELECT INTEL: ${widget.players[_currentPlayerIndex]}"),
        Expanded(
          child: PageView.builder(
            itemCount: HeadsUpData.decks.length,
            onPageChanged: (i) => setState(() => _selectedDeckIndex = i),
            itemBuilder: (context, i) {
              final deck = HeadsUpData.decks[i];
              bool selected = _selectedDeckIndex == i;
              return AnimatedScale(
                scale: selected ? 1.0 : 0.85,
                duration: const Duration(milliseconds: 400),
                child: _buildGlassCard(
                  glow: selected ? AppTheme.glowBlue : Colors.transparent,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(deck.icon, style: const TextStyle(fontSize: 60)),
                      const SizedBox(height: 10),
                      Text(deck.category, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        _buildActionBtn("INITIALIZE NEURAL LINK", () => _startCountdownPhase()),
      ],
    );
  }

  Widget _buildFinalLeaderboard() {
    final sorted = _finalScores.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return Column(
      children: [
        _buildHeader("FINAL RANKINGS"),
        Expanded(child: ListView.builder(itemCount: sorted.length, itemBuilder: (context, i) => ListTile(title: Text(sorted[i].key, style: const TextStyle(color: Colors.white)), trailing: Text("${sorted[i].value} PTS", style: const TextStyle(color: AppTheme.glowBlue))))),
        _buildActionBtn("TERMINATE SESSION", () => Navigator.pop(context)),
      ],
    );
  }

  @override
  void dispose() {
    _sensorSub?.cancel();
    _glowController.dispose();
    _orbController.dispose();
    WakelockPlus.disable(); // 🔥 RELEASE WAKELOCK
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }
}