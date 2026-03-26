import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../../models/heads_up_data.dart';

class HeadsUpGameScreen extends StatefulWidget {
  final List<String> players;
  const HeadsUpGameScreen({super.key, required this.players});

  @override
  State<HeadsUpGameScreen> createState() => _HeadsUpGameScreenState();
}

class _HeadsUpGameScreenState extends State<HeadsUpGameScreen> {
  int _timeLeft = 60;
  int _startCountdown = 3;
  Timer? _gameTimer;
  Timer? _preTimer;
  bool _isPreparing = false;
  bool _isPlaying = false;
  String _currentWord = "";
  int _score = 0;
  StreamSubscription? _sensorSub;
  bool _canScore = true;
  
  // States: "none", "correct", "skipped", "critical"
  String _gameState = "none"; 

  void _initPreGame() {
    setState(() {
      _isPreparing = true;
      _startCountdown = 3;
    });
    _preTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      HapticFeedback.vibrate(); 
      if (_startCountdown > 1) {
        setState(() => _startCountdown--);
      } else {
        _preTimer?.cancel();
        setState(() => _isPreparing = false);
        _startRound();
      }
    });
  }

  void _startRound() {
    setState(() {
      _isPlaying = true;
      _score = 0;
      _timeLeft = 60;
      _nextWord();
    });

    _gameTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_timeLeft > 0) {
        setState(() {
          _timeLeft--;
          if (_timeLeft <= 5) _gameState = "critical";
        });
        if (_timeLeft <= 5) HapticFeedback.vibrate();
      } else {
        _endRound();
      }
    });

    _sensorSub = accelerometerEvents.listen((event) {
      if (!_canScore || !_isPlaying) return;
      // Tilt detection
      if (event.z > 5.0 || event.y > 5.0) _handleResult(true);
      else if (event.z < -5.0 || event.y < -5.0) _handleResult(false);
    });
  }

  void _handleResult(bool correct) {
    HapticFeedback.vibrate(); // Normal Correct/Skipped vibration
    
    setState(() {
      _canScore = false;
      _gameState = correct ? "correct" : "skipped";
      _currentWord = correct ? "CORRECT!" : "SKIPPED⏩";
      if (correct) _score++;
    });

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() { 
          _nextWord(); 
          _canScore = true; 
          _gameState = (_timeLeft <= 5) ? "critical" : "none";
        });
      }
    });
  }

  void _nextWord() {
    setState(() {
      _currentWord = (List.from(HeadsUpData.words)..shuffle()).first;
    });
  }

  void _endRound() {
    _gameTimer?.cancel();
    _sensorSub?.cancel();
    _showResultDialog();
  }

  @override
  Widget build(BuildContext context) {
    // Get the dynamic glow color
    Color glowColor = Colors.cyanAccent;
    if (_gameState == "correct") glowColor = Colors.greenAccent;
    if (_gameState == "skipped") glowColor = Colors.orangeAccent;
    if (_gameState == "critical") glowColor = Colors.redAccent;

    return Scaffold(
      backgroundColor: const Color(0xFF020617), // Deep Background
      body: Stack(
        children: [
          // Background Light Sources (moving orbs)
          _buildBackgroundOrb(Alignment.topLeft, glowColor),
          _buildBackgroundOrb(Alignment.bottomRight, glowColor),
          
          SafeArea(
            child: Center(
              child: _buildMainContent(glowColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(Color glowColor) {
    if (_isPreparing) {
      return Text("$_startCountdown", 
        style: const TextStyle(fontSize: 160, fontWeight: FontWeight.bold, color: Colors.white));
    }

    if (!_isPlaying) {
      return _neonCard(
        color: Colors.cyanAccent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("HEADS UP", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 4)),
            const SizedBox(height: 40),
            _customButton("START GAME", _initPreGame),
          ],
        ),
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Pulsing Timer (Grows at 5, even BIGGER at 3)
        AnimatedScale(
          scale: (_timeLeft <= 3) ? 2.0 : (_timeLeft <= 5 ? 1.4 : 1.0),
          duration: const Duration(milliseconds: 200),
          child: Text(
            "$_timeLeft", 
            style: TextStyle(
              fontSize: 40, 
              fontWeight: FontWeight.w900,
              color: _timeLeft <= 5 ? Colors.redAccent : Colors.white24,
            )
          ),
        ),
        const SizedBox(height: 50),

        // Main Action Card
        _neonCard(
          color: glowColor,
          isActive: _gameState != "none",
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
            child: Text(
              _currentWord,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 50, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _neonCard({required Widget child, required Color color, bool isActive = false}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: MediaQuery.of(context).size.width * 0.88,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(35),
        border: Border.all(
          color: isActive ? color : Colors.white.withOpacity(0.1), 
          width: isActive ? 3 : 1
        ),
        boxShadow: [
          if (isActive || _gameState == "critical")
            BoxShadow(color: color.withOpacity(0.4), blurRadius: 40, spreadRadius: 5)
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(35),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            color: const Color(0xFF020617).withOpacity(0.8), // Pure dark, no milkiness
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _customButton(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.cyanAccent),
          boxShadow: [BoxShadow(color: Colors.cyanAccent.withOpacity(0.2), blurRadius: 10)],
        ),
        child: Text(text, style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildBackgroundOrb(Alignment align, Color color) {
    return Align(
      alignment: align,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        width: 400, height: 400,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color.withOpacity(0.15), Colors.transparent]),
        ),
      ),
    );
  }

  void _showResultDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: AlertDialog(
          backgroundColor: const Color(0xFF020617),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30), side: const BorderSide(color: Colors.white10)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("FINAL SCORE", style: TextStyle(color: Colors.white54)),
              Text("$_score", style: const TextStyle(fontSize: 100, color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),
              _customButton("REPLAY", () { Navigator.pop(c); _initPreGame(); }),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _gameTimer?.cancel(); _preTimer?.cancel(); _sensorSub?.cancel();
    super.dispose();
  }
}