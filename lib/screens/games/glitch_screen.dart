import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'dart:ui';

class GlitchScreen extends StatefulWidget {
  final List<String> players;
  const GlitchScreen({super.key, required this.players});

  @override
  State<GlitchScreen> createState() => _GlitchScreenState();
}

class _GlitchScreenState extends State<GlitchScreen> {
  String _phase = 'reveal'; 
  int _playerIndex = 0;
  bool _isDataVisible = false;
  
  late String _glitchPlayer;
  late Map<String, String> _currentLogic;
  String? _votedPlayer;

  // Broad categories to keep the Glitch hidden longer
  final List<Map<String, String>> _logicBank = [
    {"cat": "NATURE", "rule": "Must be able to survive underwater"},
    {"cat": "FOOD", "rule": "Typically served hot"},
    {"cat": "OBJECTS", "rule": "Made primarily of metal"},
    {"cat": "ACTION", "rule": "Something you do at a gym"},
    {"cat": "BRANDS", "rule": "They sell food or drinks"},
    {"cat": "PLACES", "rule": "Places where you must be quiet"},
    {"cat": "CLOTHING", "rule": "Items worn on your feet"},
    {"cat": "TECH", "rule": "Devices that have a screen"},
  ];

  @override
  void initState() {
    super.initState();
    _initGame();
  }

  void _initGame() {
    final rand = Random();
    _glitchPlayer = widget.players[rand.nextInt(widget.players.length)];
    _currentLogic = _logicBank[rand.nextInt(_logicBank.length)];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF04060E),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Background Gradient
          Container(
            width: double.infinity, height: double.infinity,
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(-0.8, -0.6), radius: 1.5,
                colors: [Color(0xFF162252), Color(0xFF04060E)],
              ),
            ),
          ),
          // Floating Glow Orbs
          Positioned(top: -50, right: -50, child: _glowOrb(150, Colors.blue.withOpacity(0.1))),
          Positioned(bottom: 100, left: -50, child: _glowOrb(200, Colors.purple.withOpacity(0.05))),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: _buildCurrentPhase(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _glowOrb(double size, Color color) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color, boxShadow: [BoxShadow(color: color, blurRadius: 100, spreadRadius: 50)]),
    );
  }

  Widget _buildCurrentPhase() {
    switch (_phase) {
      case 'reveal': return _buildRevealPhase();
      case 'action': return _buildActionPhase();
      case 'result': return _buildResultPhase();
      default: return const Center(child: CircularProgressIndicator());
    }
  }

  Widget _buildRevealPhase() {
    String currentPlayer = widget.players[_playerIndex];
    bool isGlitch = currentPlayer == _glitchPlayer;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("NEURAL LINK", style: TextStyle(color: Color(0xFF3B82F6), letterSpacing: 5, fontWeight: FontWeight.w900, fontSize: 12)),
        const SizedBox(height: 10),
        Text(currentPlayer.toUpperCase(), style: const TextStyle(fontSize: 36, color: Colors.white, fontWeight: FontWeight.w200, letterSpacing: 2)),
        const SizedBox(height: 60),
        
        ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: _isDataVisible ? (isGlitch ? Colors.redAccent : const Color(0xFF00FF88)) : Colors.white10, width: 1.5),
              ),
              child: _isDataVisible ? _buildSecretData(isGlitch) : _buildHiddenState(),
            ),
          ),
        ),
        
        const SizedBox(height: 60),
        ElevatedButton(
          onPressed: () {
            HapticFeedback.mediumImpact();
            if (!_isDataVisible) {
              setState(() => _isDataVisible = true);
            } else {
              setState(() {
                _isDataVisible = false;
                if (_playerIndex < widget.players.length - 1) _playerIndex++;
                else _phase = 'action';
              });
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: _isDataVisible ? const Color(0xFF1F2947) : const Color(0xFF3B82F6),
            minimumSize: const Size(double.infinity, 70),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          child: Text(_isDataVisible ? "ENCRYPT & NEXT" : "DECRYPT LOGIC"),
        ),
      ],
    );
  }

  Widget _buildHiddenState() {
    return const Column(
      children: [
        Icon(Icons.fingerprint, size: 60, color: Colors.white24),
        SizedBox(height: 20),
        Text("SCANNING IDENTITY...", style: TextStyle(color: Colors.white24, letterSpacing: 2)),
      ],
    );
  }

  Widget _buildSecretData(bool isGlitch) {
    return Column(
      children: [
        Text("CATEGORY: ${_currentLogic['cat']}", style: TextStyle(color: isGlitch ? Colors.redAccent : const Color(0xFF00FF88), fontWeight: FontWeight.bold, letterSpacing: 2)),
        const SizedBox(height: 20),
        Text(
          isGlitch ? "CORRUPTED\nYOU ARE THE GLITCH" : "LOGIC: ${_currentLogic['rule']}",
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildActionPhase() {
    return Column(
      children: [
        const SizedBox(height: 40),
        const Text("GLITCH IS ACTIVE", style: TextStyle(color: Colors.redAccent, letterSpacing: 5, fontWeight: FontWeight.bold)),
        const SizedBox(height: 40),
        const Icon(Icons.radar, size: 100, color: Colors.white10),
        const SizedBox(height: 20),
        const Text(
          "All Systems share your data word.\nIdentify the anomaly.",
          textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
        const Spacer(),
        Expanded(
          flex: 3,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 15, mainAxisSpacing: 15, childAspectRatio: 1.8),
            itemCount: widget.players.length,
            itemBuilder: (context, index) => GestureDetector(
              onTap: () => setState(() { _votedPlayer = widget.players[index]; _phase = 'result'; }),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0E1329),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                alignment: Alignment.center,
                child: Text(widget.players[index], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Replace the top of your Result Phase with this synchronized builder
Widget _buildResultPhase() {
  bool win = _votedPlayer == _glitchPlayer;
  Color resultColor = win ? const Color(0xFF00FF88) : Colors.redAccent;

  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      // Signature Static Icon with Glow
      Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: resultColor.withOpacity(0.1),
            boxShadow: [
              BoxShadow(
                color: resultColor.withOpacity(0.2),
                blurRadius: 40,
                spreadRadius: 5,
              )
            ],
          ),
          child: Icon(
            win ? Icons.verified_user_rounded : Icons.cancel_rounded,
            size: 100,
            color: resultColor,
          ),
        ),
      ),
      const SizedBox(height: 30),

      // Result Title
      Text(
        win ? "GLITCH PURGED" : "SYSTEM CRASH",
        style: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          letterSpacing: 2.0,
          color: Colors.white,
        ),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 8),
      Text(
        win ? "The corrupted player has been isolated." : "The Glitch successfully bypassed the system.",
        textAlign: TextAlign.center,
        style: const TextStyle(color: Color(0xFF8E95A3), fontSize: 16),
      ),
      
      const SizedBox(height: 40),

      // Evidence Card
      Container(
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: const Color(0xFF0E1329), 
          borderRadius: BorderRadius.circular(24), 
          border: Border.all(color: Colors.white.withOpacity(0.05))
        ),
        child: Column(
          children: [
            const Text("DECRYPTED DATA", style: TextStyle(color: Color(0xFF8E95A3), fontSize: 12, letterSpacing: 2)),
            const SizedBox(height: 15),
            Text(
              "THE GLITCH: $_glitchPlayer", 
              style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 18)
            ),
            const Divider(height: 30, color: Colors.white10),
            Text(
              "THE RULE: ${_currentLogic['rule']}", 
              style: const TextStyle(color: Color(0xFF00FF88), fontWeight: FontWeight.bold, fontSize: 18)
            ),
          ],
        ),
      ),
      
      const SizedBox(height: 50),

      // Footer Button
      ElevatedButton(
        onPressed: () => Navigator.pop(context), 
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 70),
          backgroundColor: const Color(0xFF1F2947),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: const Text("RETURN TO HQ"),
      ),
    ],
  );
}
}
