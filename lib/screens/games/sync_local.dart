import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/firebase_service.dart';

class LocalSyncGameScreen extends StatefulWidget {
  final List<String> players;

  const LocalSyncGameScreen({super.key, required this.players});

  @override
  State<LocalSyncGameScreen> createState() => _LocalSyncGameScreenState();
}

class _LocalSyncGameScreenState extends State<LocalSyncGameScreen> with TickerProviderStateMixin {
  // Game Logic
  int _currentRound = 1;
  double _totalRounds = 3.0;
  int _currentPlayerIndex = 0;
  bool _isSetupPhase = true;
  bool _isRevealed = false;
  bool _isGameOver = false;
  bool _isScanning = false;
  bool _waitingForPass = false;

  final List<String> _currentRoundAnswers = [];
  final Map<String, int> _totalScores = {};
  final TextEditingController _controller = TextEditingController();
  late AnimationController _scanLineController;
  late AnimationController _bgPulseController;
  String _currentCategory = "";

  @override
  void initState() {
    super.initState();
    for (var p in widget.players) _totalScores[p] = 0;
    
    _scanLineController = AnimationController(vsync: this, duration: const Duration(seconds: 1));
    _bgPulseController = AnimationController(vsync: this, duration: const Duration(seconds: 5))..repeat(reverse: true);
    
    _pullCategoryFromService();
  }

  void _pullCategoryFromService() {
    setState(() {
      // Pulling from the shared list in FirebaseService
      _currentCategory = (FirebaseService().syncQuestions..shuffle()).first;
    });
  }

  Future<void> _handleFingerprintScan() async {
    if (_controller.text.trim().isEmpty) return;
    setState(() => _isScanning = true);
    _scanLineController.repeat(reverse: true);
    
    HapticFeedback.heavyImpact(); 
    await Future.delayed(const Duration(milliseconds: 1200)); 
    
    if (mounted) {
      _scanLineController.stop();
      _submitData();
      setState(() => _isScanning = false);
    }
  }

  void _submitData() {
    _currentRoundAnswers.add(_controller.text.trim().toUpperCase());
    _controller.clear();
    
    setState(() {
      if (_currentPlayerIndex < widget.players.length - 1) {
        _waitingForPass = true;
      } else {
        _calculateScores();
        _isRevealed = true;
      }
    });
  }

  void _calculateScores() {
    Map<String, int> counts = {};
    for (var ans in _currentRoundAnswers) counts[ans] = (counts[ans] ?? 0) + 1;
    for (int i = 0; i < widget.players.length; i++) {
      String ans = _currentRoundAnswers[i];
      if (counts[ans]! > 1) {
        _totalScores[widget.players[i]] = (_totalScores[widget.players[i]] ?? 0) + (counts[ans]! * 10);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020408),
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          _buildAnimatedMeshBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 600),
                child: _buildBody(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isSetupPhase) return _buildSetupUI();
    if (_isGameOver) return _buildGameOverUI();
    if (_isRevealed) return _buildRevealUI();
    if (_waitingForPass) return _buildPassScreen();
    return _buildInputUI();
  }

  // --- 🌌 CREATIVE GLASS COMPONENTS ---

  Widget _buildAnimatedMeshBackground() {
    return AnimatedBuilder(
      animation: _bgPulseController,
      builder: (context, child) {
        return Stack(
          children: [
            Positioned.fill(child: Container(color: const Color(0xFF020408))),
            // Moving Neural Orbs
            Positioned(
              top: -100 + (50 * _bgPulseController.value),
              left: -50,
              child: _glowOrb(400, Colors.blueAccent.withOpacity(0.1)),
            ),
            Positioned(
              bottom: -100,
              right: -50 + (50 * _bgPulseController.value),
              child: _glowOrb(350, Colors.purpleAccent.withOpacity(0.08)),
            ),
            // Technical Grid Overlay
            Positioned.fill(
              child: Opacity(
                opacity: 0.02,
                child: CustomPaint(painter: GridPainter()),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCreativeGlassCard({required Widget child, Color? accentColor}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(35),
        // Specular highlight border
        border: Border.all(
          width: 1.5,
          color: (accentColor ?? Colors.white).withOpacity(0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: (accentColor ?? Colors.blueAccent).withOpacity(0.05),
            blurRadius: 30,
            spreadRadius: 5,
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(35),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.08),
                  Colors.white.withOpacity(0.01),
                ],
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  // --- 📟 PHASE UI: SETUP ---
  Widget _buildSetupUI() {
    return Column(
      key: const ValueKey('setup'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("NEURAL INITIALIZATION", 
          style: TextStyle(color: Colors.blueAccent, letterSpacing: 8, fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(height: 40),
        _buildCreativeGlassCard(
          child: Column(
            children: [
              const Text("SESSION DEPTH", style: TextStyle(color: Colors.white24, letterSpacing: 2, fontSize: 10)),
              const SizedBox(height: 20),
              Text("${_totalRounds.toInt()} ROUNDS", style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 4)),
              Slider(
                value: _totalRounds,
                min: 1, max: 10,
                divisions: 9,
                activeColor: Colors.blueAccent,
                onChanged: (v) => setState(() => _totalRounds = v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
        _buildTacticalButton("ESTABLISH LINK", () => setState(() => _isSetupPhase = false)),
      ],
    );
  }

  // --- 📟 PHASE UI: INPUT ---
  Widget _buildInputUI() {
    return Column(
      key: const ValueKey('input'),
      children: [
        const SizedBox(height: 30),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("ROUND ${_currentRound}/${_totalRounds.toInt()}", style: const TextStyle(color: Colors.white24, fontFamily: 'monospace', fontSize: 10)),
            Text("NODE: ${widget.players[_currentPlayerIndex]}", style: const TextStyle(color: Colors.blueAccent, fontFamily: 'monospace', fontSize: 10)),
          ],
        ),
        const SizedBox(height: 40),
        _buildCreativeGlassCard(
          child: Column(
            children: [
              const Text("SYNC TARGET", style: TextStyle(color: Colors.white24, letterSpacing: 4, fontSize: 9)),
              const SizedBox(height: 20),
              Text(_currentCategory, 
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
            ],
          ),
        ),
        const Spacer(),
        _buildDataEntryField(),
        const SizedBox(height: 40),
        _buildFingerprintScanner(),
        const SizedBox(height: 50),
      ],
    );
  }

  Widget _buildDataEntryField() {
    return TextField(
      controller: _controller,
      obscureText: true,
      textAlign: TextAlign.center,
      style: const TextStyle(color: Colors.white, fontSize: 26, letterSpacing: 12),
      decoration: InputDecoration(
        hintText: "TYPE_SECRET",
        hintStyle: const TextStyle(color: Colors.white10, fontSize: 12, letterSpacing: 4, fontFamily: 'monospace'),
        border: InputBorder.none,
        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.blueAccent.withOpacity(0.2))),
        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.blueAccent)),
      ),
    );
  }

  Widget _buildFingerprintScanner() {
    return GestureDetector(
      onLongPressStart: (_) => _handleFingerprintScan(),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer Pulse Ring
          if (_isScanning)
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 1200),
              builder: (context, value, child) => SizedBox(
                width: 120, height: 120,
                child: CircularProgressIndicator(value: value, color: Colors.blueAccent, strokeWidth: 2),
              ),
            ),
          // Scanner Body
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 90, width: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isScanning ? Colors.blueAccent.withOpacity(0.2) : Colors.white.withOpacity(0.05),
              border: Border.all(color: _isScanning ? Colors.blueAccent : Colors.white24, width: 1.5),
              boxShadow: _isScanning ? [BoxShadow(color: Colors.blueAccent.withOpacity(0.3), blurRadius: 30)] : [],
            ),
            child: Icon(Icons.fingerprint, color: _isScanning ? Colors.blueAccent : Colors.white38, size: 45),
          ),
        ],
      ),
    );
  }

  // --- 📟 PHASE UI: PASS SCREEN ---
  Widget _buildPassScreen() {
    return Column(
      key: const ValueKey('pass'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.security, color: Colors.blueAccent, size: 50),
        const SizedBox(height: 30),
        _buildCreativeGlassCard(
          accentColor: Colors.amberAccent,
          child: Column(
            children: [
              const Text("SECURE HANDOVER", style: TextStyle(color: Colors.amberAccent, letterSpacing: 4, fontSize: 10, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),
              Text(widget.players[_currentPlayerIndex + 1].toUpperCase(), 
                style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
              const SizedBox(height: 10),
              const Text("RE-ESTABLISH CONTACT", style: TextStyle(color: Colors.white24, fontSize: 10)),
            ],
          ),
        ),
        const SizedBox(height: 40),
        _buildTacticalButton("I AM ${widget.players[_currentPlayerIndex + 1]}", () {
          setState(() {
            _currentPlayerIndex++;
            _waitingForPass = false;
          });
        }),
      ],
    );
  }

  // --- 📟 PHASE UI: REVEAL ---
  Widget _buildRevealUI() {
    return Column(
      key: const ValueKey('reveal'),
      children: [
        const SizedBox(height: 30),
        const Text("COHERENCE ANALYSIS", style: TextStyle(color: Colors.blueAccent, letterSpacing: 6, fontFamily: 'monospace')),
        const SizedBox(height: 30),
        ..._currentRoundAnswers.asMap().entries.map((e) => _buildCreativeGlassCard(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(widget.players[e.key], style: const TextStyle(color: Colors.white38, fontFamily: 'monospace', fontSize: 12)),
              Text(e.value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2)),
            ],
          ),
        )).toList(),
        const SizedBox(height: 40),
        _buildTacticalButton(
          _currentRound >= _totalRounds.toInt() ? "FINAL SUMMARY" : "NEXT ROUND", 
          () {
            if (_currentRound >= _totalRounds.toInt()) {
              setState(() => _isGameOver = true);
            } else {
              setState(() {
                _currentRound++;
                _currentPlayerIndex = 0;
                _currentRoundAnswers.clear();
                _isRevealed = false;
                _pullCategoryFromService();
              });
            }
          }
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  // --- 📟 PHASE UI: GAME OVER ---
  Widget _buildGameOverUI() {
    var sortedPlayers = widget.players.toList()..sort((a, b) => _totalScores[b]!.compareTo(_totalScores[a]!));
    return Column(
      key: const ValueKey('over'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.emoji_events, color: Colors.amber, size: 60),
        const SizedBox(height: 30),
        const Text("NEURAL MASTERY", style: TextStyle(color: Colors.blueAccent, letterSpacing: 8, fontWeight: FontWeight.bold)),
        const SizedBox(height: 30),
        ...sortedPlayers.map((p) => _buildCreativeGlassCard(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(p, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              Text("${_totalScores[p]} SYNC", style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.w900)),
            ],
          ),
        )).toList(),
        const SizedBox(height: 40),
        _buildTacticalButton("TERMINATE LINK", () => Navigator.pop(context)),
      ],
    );
  }

  // --- HELPERS ---

  Widget _buildTacticalButton(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 65, width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.blueAccent.withOpacity(0.1),
          border: Border.all(color: Colors.blueAccent.withOpacity(0.5)),
        ),
        child: Center(child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2))),
      ),
    );
  }

  Widget _glowOrb(double size, Color color) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color, boxShadow: [BoxShadow(color: color, blurRadius: 100, spreadRadius: 40)]),
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.5)..strokeWidth = 0.5;
    for (double i = 0; i < size.width; i += 40) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += 40) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}