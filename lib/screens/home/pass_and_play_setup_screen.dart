import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'dart:ui';
import '../../models/game_model.dart';
import '../../core/theme.dart';

class PassAndPlaySetupScreen extends StatefulWidget {
  final Game game;
  const PassAndPlaySetupScreen({super.key, required this.game});

  @override
  State<PassAndPlaySetupScreen> createState() => _PassAndPlaySetupScreenState();
}

class _PassAndPlaySetupScreenState extends State<PassAndPlaySetupScreen> with TickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  final List<String> _players = [];
  bool _isLoading = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _addPlayer() {
    if (_players.length >= 8) return;
    String name = _nameController.text.trim();
    if (name.isNotEmpty && !_players.contains(name)) {
      HapticFeedback.mediumImpact();
      setState(() => _players.add(name));
      _nameController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    bool canProceed = _players.length >= (widget.game.id == 'interrogation' ? 2 : 3);
    Color themeColor = canProceed ? AppTheme.glowBlue : const Color(0xFFFFB300);

    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // 1. Ambient Background Orbs
          Positioned(top: -50, left: -50, child: _lightOrb(themeColor.withOpacity(0.15))),
          Positioned(bottom: -50, right: -50, child: _lightOrb(Colors.purpleAccent.withOpacity(0.1))),

          // 2. Animated Neural Network
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                _buildConnections(themeColor),
                _buildCentralHub(themeColor),
                // Map players to animated floating nodes
                ..._players.asMap().entries.map((e) => _FloatingOperativeNode(
                      index: e.key,
                      name: e.value,
                      color: themeColor,
                      onRemove: () => setState(() => _players.removeAt(e.key)),
                    )),
              ],
            ),
          ),

          // 3. UI Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(themeColor),
                  const Spacer(),
                  _buildGlassInput(themeColor),
                  const SizedBox(height: 20),
                  _buildStartButton(canProceed, themeColor),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
        ),
        const SizedBox(height: 10),
        Text(widget.game.name.toUpperCase(), 
          style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 2)),
        Text("NEURAL LINK: ${_players.length}/8 OPERATIVES", 
          style: TextStyle(color: color.withOpacity(0.6), fontSize: 10, letterSpacing: 3, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildCentralHub(Color color) {
    return ScaleTransition(
      scale: Tween(begin: 1.0, end: 1.1).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut)),
      child: Container(
        width: 90, height: 90,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color.withOpacity(0.5), width: 2),
          boxShadow: [BoxShadow(color: color.withOpacity(0.2), blurRadius: 30, spreadRadius: 5)],
        ),
        child: Icon(Icons.radar, color: color, size: 40),
      ),
    );
  }

  Widget _buildConnections(Color color) {
    return CustomPaint(
      size: const Size(400, 400),
      painter: _LinkPainter(playerCount: _players.length, color: color, pulse: _pulseController.value),
    );
  }

  Widget _buildGlassInput(Color color) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A).withOpacity(0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: TextField(
            controller: _nameController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "ENTER CODENAME...",
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 14),
              border: InputBorder.none,
              suffixIcon: IconButton(
                icon: Icon(Icons.add_circle, color: color, size: 28),
                onPressed: _addPlayer,
              ),
            ),
            onSubmitted: (_) => _addPlayer(),
          ),
        ),
      ),
    );
  }

  Widget _buildStartButton(bool active, Color color) {
    return InkWell(
      onTap: active ? () {
        HapticFeedback.vibrate();
        Navigator.pushNamed(context, widget.game.actualGameRouteName, arguments: {'players': _players});
      } : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity, height: 64,
        decoration: BoxDecoration(
          color: active ? color : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(15),
          boxShadow: active ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 20)] : [],
        ),
        child: Center(
          child: Text("ESTABLISH LINK", 
            style: TextStyle(color: active ? Colors.black : Colors.white24, fontWeight: FontWeight.w900, letterSpacing: 2)),
        ),
      ),
    );
  }

  Widget _lightOrb(Color color) {
    return Container(
      width: 400, height: 400,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color, boxShadow: [
        BoxShadow(color: color, blurRadius: 150, spreadRadius: 50)
      ]),
    );
  }
}

class _FloatingOperativeNode extends StatefulWidget {
  final int index;
  final String name;
  final Color color;
  final VoidCallback onRemove;
  const _FloatingOperativeNode({required this.index, required this.name, required this.color, required this.onRemove});

  @override
  State<_FloatingOperativeNode> createState() => _FloatingOperativeNodeState();
}

class _FloatingOperativeNodeState extends State<_FloatingOperativeNode> with SingleTickerProviderStateMixin {
  late AnimationController _floatController;

  @override
  void initState() {
    super.initState();
    // Unique float offset for each node
    _floatController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2 + (widget.index % 3)),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double angle = (widget.index * (2 * pi / 8)) - (pi / 2);
    double radius = 135;
    
    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, child) {
        // Adds a bobbing motion to the radius
        double dynamicRadius = radius + (sin(_floatController.value * pi) * 10);
        double x = cos(angle) * dynamicRadius;
        double y = sin(angle) * dynamicRadius;

        return Transform.translate(
          offset: Offset(x, y),
          child: GestureDetector(
            onTap: widget.onRemove,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF020617).withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: widget.color.withOpacity(0.5)),
                  ),
                  child: Text(widget.name.toUpperCase(), 
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LinkPainter extends CustomPainter {
  final int playerCount;
  final Color color;
  final double pulse;
  _LinkPainter({required this.playerCount, required this.color, required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.15)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final particlePaint = Paint()
      ..color = color.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    for (int i = 0; i < playerCount; i++) {
      double angle = (i * (2 * pi / 8)) - (pi / 2);
      // We match the dynamic radius of the nodes here for the lines
      double radius = 125 + (sin(pulse * pi) * 8);
      Offset nodePos = Offset(center.dx + cos(angle) * radius, center.dy + sin(angle) * radius);
      
      // Draw static line
      canvas.drawLine(center, nodePos, paint);

      // Draw moving data particle along the line
      double particleOffset = (pulse + (i * 0.2)) % 1.0;
      Offset particlePos = Offset.lerp(center, nodePos, particleOffset)!;
      canvas.drawCircle(particlePos, 2, particlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}