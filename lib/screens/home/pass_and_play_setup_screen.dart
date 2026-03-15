import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'dart:ui';
import '../../models/game_model.dart';

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
  late AnimationController _interferenceController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    
    _interferenceController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _interferenceController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _addPlayer() {
    if (_players.length >= 8) return; 
    String name = _nameController.text.trim();
    if (name.isNotEmpty && !_players.contains(name)) {
      HapticFeedback.heavyImpact();
      setState(() => _players.add(name));
      _nameController.clear();
    }
  }

  void _startGame() {
    setState(() => _isLoading = true);
    HapticFeedback.vibrate();
    Navigator.pushNamed(context, widget.game.actualGameRouteName, arguments: {
      'players': _players,
    });
  }

  @override
  Widget build(BuildContext context) {
    bool canProceed = _players.length >= (widget.game.id == 'interrogation' ? 2 : 3);
    Color themeColor = canProceed ? Colors.blueAccent : Colors.orangeAccent;

    return Scaffold(
      backgroundColor: const Color(0xFF04060E),
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // 1. SIGNAL INTERFERENCE BACKGROUND
          _buildInterferenceOverlay(),
          _buildTacticalGrid(),
          
          // 2. THERMAL HUB
          Center(child: _buildThermalHub(themeColor)),

          // 3. NEURAL NODES (Orbiting with Dendrites)
          ..._players.asMap().entries.map((entry) => _NeuralNode(
                index: entry.key,
                total: _players.length,
                name: entry.value,
                color: themeColor,
                onRemove: () => setState(() => _players.removeAt(entry.key)),
              )),

          // 4. UI OVERLAY
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Column(
                children: [
                  _buildHeader(),
                  const Spacer(),
                  _buildInputConsole(themeColor),
                  const SizedBox(height: 24),
                  _buildPrimaryButton(canProceed),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInterferenceOverlay() {
    return AnimatedBuilder(
      animation: _interferenceController,
      builder: (context, child) {
        return Opacity(
          opacity: 0.03,
          child: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: const AssetImage("assets/images/noise.png"), // Ensure you have a tiny noise grain texture
                repeat: ImageRepeat.repeat,
                colorFilter: ColorFilter.mode(Colors.blueAccent.withOpacity(0.1), BlendMode.screen),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: const Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 16),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text("SIGNAL ACQUISITION", 
              style: TextStyle(color: Colors.white.withOpacity(0.4), letterSpacing: 2, fontSize: 10, fontWeight: FontWeight.bold)),
            Text(widget.game.name.toUpperCase(), 
              style: const TextStyle(color: Colors.blueAccent, fontSize: 12, fontWeight: FontWeight.w900, fontFamily: 'monospace')),
          ],
        ),
      ],
    );
  }

  Widget _buildThermalHub(Color color) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          width: 200, height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color.withOpacity(0.15 + (0.05 * _pulseController.value)),
                Colors.transparent
              ],
            ),
          ),
          child: Icon(Icons.radar, color: color.withOpacity(0.3), size: 100),
        );
      },
    );
  }

  Widget _buildInputConsole(Color themeColor) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: themeColor.withOpacity(0.2)),
          ),
          child: TextField(
            controller: _nameController,
            style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
            cursorColor: themeColor,
            decoration: InputDecoration(
              hintText: "CONNECT_OPERATIVE...",
              hintStyle: const TextStyle(color: Colors.white12, fontSize: 14),
              border: InputBorder.none,
              prefixIcon: Icon(Icons.settings_input_antenna, color: themeColor, size: 18),
              contentPadding: const EdgeInsets.symmetric(vertical: 18),
              suffixIcon: IconButton(
                icon: Icon(Icons.add_circle_outline, color: themeColor, size: 28),
                onPressed: _addPlayer,
              ),
            ),
            onSubmitted: (_) => _addPlayer(),
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton(bool active) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: active ? [BoxShadow(color: Colors.blueAccent.withOpacity(0.2), blurRadius: 30)] : null,
      ),
      child: ElevatedButton(
        onPressed: active ? _startGame : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: active ? Colors.blueAccent : Colors.white.withOpacity(0.05),
          minimumSize: const Size(double.infinity, 64),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: _isLoading 
          ? const CircularProgressIndicator(color: Colors.white)
          : Text("EXECUTE DEPLOYMENT", 
              style: TextStyle(color: active ? Colors.white : Colors.white24, letterSpacing: 2, fontWeight: FontWeight.w900)),
      ),
    );
  }

  Widget _buildTacticalGrid() {
    return CustomPaint(size: Size.infinite, painter: GridPainter());
  }
}

class _NeuralNode extends StatefulWidget {
  final int index;
  final int total;
  final String name;
  final Color color;
  final VoidCallback onRemove;

  const _NeuralNode({required this.index, required this.total, required this.name, required this.color, required this.onRemove});

  @override
  State<_NeuralNode> createState() => _NeuralNodeState();
}

class _NeuralNodeState extends State<_NeuralNode> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: Duration(seconds: 10 + (widget.index * 2)))..repeat();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        double angle = (_ctrl.value * 2 * pi) + (widget.index * (2 * pi / max(1, widget.total)));
        Offset nodePos = Offset(cos(angle) * 140, sin(angle) * 140);
        
        return Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 🧠 NEURAL DENDRITE (Line to core)
              CustomPaint(
                painter: DendritePainter(nodePos, widget.color.withOpacity(0.2)),
              ),
              Transform.translate(
                offset: nodePos,
                child: GestureDetector(
                  onTap: widget.onRemove,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0E1329).withOpacity(0.8),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: widget.color.withOpacity(0.5)),
                        ),
                        child: Text(widget.name.toUpperCase(), 
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class DendritePainter extends CustomPainter {
  final Offset endPoint;
  final Color color;
  DendritePainter(this.endPoint, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeWidth = 1.0..style = PaintingStyle.stroke;
    final path = Path();
    path.moveTo(0, 0); // Center of screen
    // Create a slight "jagged" neural look
    path.lineTo(endPoint.dx * 0.5, endPoint.dy * 0.4);
    path.lineTo(endPoint.dx, endPoint.dy);
    canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(DendritePainter oldDelegate) => true;
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.02)..strokeWidth = 0.5;
    for (double i = 0; i < size.width; i += 50) canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    for (double i = 0; i < size.height; i += 50) canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}