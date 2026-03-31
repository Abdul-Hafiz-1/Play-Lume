import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';
import '../../logic/mafia_engine.dart';
import '../../core/theme.dart';
import 'mafia_morning_screen.dart';

class MafiaNightScreen extends StatefulWidget {
  final MafiaSession session;
  const MafiaNightScreen({super.key, required this.session});

  @override
  State<MafiaNightScreen> createState() => _MafiaNightScreenState();
}

class _MafiaNightScreenState extends State<MafiaNightScreen> with TickerProviderStateMixin {
  int _index = 0;
  bool _isUnlocked = false;
  bool _showDetectiveResult = false;
  
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    
    // Clear last night's temporary targets at start of new night
    widget.session.lastMafiaTargets.clear();
    widget.session.lastDoctorTarget = null;
    widget.session.lastDetectiveTarget = null;
  }

  void _submitAction(String? target) {
    String name = widget.session.survivors[_index];
    String role = widget.session.roles[name]!;

    setState(() {
      if (role == "MAFIA" && target != null) {
        widget.session.lastMafiaTargets.add(target);
      }
      if (role == "DOCTOR") {
        if (target == name) widget.session.doctorHasSelfSaved = true;
        widget.session.lastDoctorTarget = target;
      }
      
      if (_index < widget.session.survivors.length - 1) {
        _index++;
        _isUnlocked = false;
        _showDetectiveResult = false;
      } else {
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (context) => MafiaMorningScreen(session: widget.session))
        );
      }
    });
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    String name = widget.session.survivors[_index];
    String role = widget.session.roles[name]!;
    
    return Scaffold(
      backgroundColor: const Color(0xFF02040A), 
      body: Stack(
        children: [
          _buildNeutralBackground(), 
          SafeArea(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 600),
              child: !_isUnlocked 
                ? _buildPrivacyStep(name) 
                : _buildActionStep(name, role, _getRoleColor(role)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNeutralBackground() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) => Center(
        child: Container(
          width: 600, height: 600,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                Colors.white.withOpacity(0.03 * _pulseController.value), 
                Colors.transparent
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrivacyStep(String name) {
    return Center(
      key: ValueKey("p_$_index"),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("ENCRYPTED TRANSMISSION", style: TextStyle(color: Colors.white10, letterSpacing: 6, fontSize: 10)),
          const SizedBox(height: 20),
          Text("PASS TO $name", style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2)),
          const SizedBox(height: 60),
          GestureDetector(
            onLongPressStart: (_) {
              Vibration.vibrate(duration: 50);
              HapticFeedback.heavyImpact();
              setState(() => _isUnlocked = true);
            },
            child: _buildScannerUI(),
          ),
          const SizedBox(height: 30),
          const Text("HOLD BIOMETRIC TO UNLOCK", style: TextStyle(color: Colors.white12, letterSpacing: 2, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildActionStep(String name, String role, Color color) {
    return Center(
      key: ValueKey("a_$_index"),
      child: Column(
        children: [
          const SizedBox(height: 40),
          const Text("SATELLITE LINK ESTABLISHED", 
            style: TextStyle(color: Colors.white10, letterSpacing: 4, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _buildTacticalCard(name, role, color),
        ],
      ),
    );
  }

  Widget _buildTacticalCard(String name, String role, Color color) {
    bool isPassive = (role == "VILLAGER" || role == "JESTER");

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) => Container(
        width: 340,
        height: 540,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: color.withOpacity(0.1 + (0.15 * _pulseController.value)), 
            width: 1.5
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Stack(
            children: [
              // 💎 TACTICAL MAP: 0 Opacity at top, 100 Opacity (0.5 max) at bottom
              Positioned.fill(
                child: ShaderMask(
                  shaderCallback: (rect) {
                    return const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black],
                      stops: [0.0, 0.7], 
                    ).createShader(rect);
                  },
                  blendMode: BlendMode.dstIn,
                  child: Image.asset(
                    'lib/assets/images/tactical_map.jpg', 
                    fit: BoxFit.cover,
                    opacity: const AlwaysStoppedAnimation(0.5),
                    errorBuilder: (context, error, stackTrace) => Container(color: Colors.transparent),
                  ),
                ),
              ),

              // 💎 SCANLINE OVERLAY
              _buildScanlineOverlay(),

              // 💎 FROSTED GLASS LAYER
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(color: Colors.black.withOpacity(0.4)),
                ),
              ),

              // 💎 CONTENT
              Padding(
                padding: const EdgeInsets.all(25),
                child: Column(
                  children: [
                    Text("OPERATIVE: ${name.toUpperCase()}", style: const TextStyle(color: Colors.white24, letterSpacing: 2, fontSize: 10)),
                    const SizedBox(height: 5),
                    Text(role, style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: color, letterSpacing: 8)),
                    const SizedBox(height: 10),
                    Container(height: 1, color: color.withOpacity(0.2)),
                    const SizedBox(height: 25),
                    
                    if (role == "DETECTIVE") ...[
                      _buildIntelLog(),
                      const SizedBox(height: 15),
                    ],

                    if (_showDetectiveResult) 
                      _buildDetectiveHUD(color)
                    else 
                      _buildInteractiveList(name, role, color, isPassive),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIntelLog() {
    if (widget.session.detectiveIntel.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.cyan.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.cyan.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("PREVIOUS INTEL", style: TextStyle(color: Colors.cyan, fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ...widget.session.detectiveIntel.entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(e.key.toUpperCase(), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                Text(e.value ? "GUILTY" : "INNOCENT", 
                  style: TextStyle(color: e.value ? Colors.redAccent : Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildInteractiveList(String name, String role, Color color, bool isPassive) {
    final legalTargets = widget.session.survivors.where((p) {
      if (role == "MAFIA" && p == name) return false; 
      return true;
    }).toList();

    return Expanded(
      child: Column(
        children: [
          Text(isPassive ? "STAY VIGILANT" : "SELECT YOUR TARGET", 
            style: const TextStyle(color: Colors.white38, letterSpacing: 2, fontSize: 11)),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              children: legalTargets.map((p) {
                bool isSelf = p == name;
                bool disabled = (role == "DOCTOR" && isSelf && widget.session.doctorHasSelfSaved);
                
                return _buildGlassTile(p, color, disabled, () {
                  if (role == "DETECTIVE") {
                    _checkDetectiveTarget(p);
                  } else {
                    _submitAction(isPassive ? null : p);
                  }
                });
              }).toList(),
            ),
          ),
          if (isPassive) ...[
            const SizedBox(height: 10),
            _buildGlassButton("COMPLETE TURN", () => _submitAction(null), color),
          ],
        ],
      ),
    );
  }

  void _checkDetectiveTarget(String target) {
    bool isMafia = widget.session.roles[target] == "MAFIA";
    setState(() {
      widget.session.detectiveIntel[target] = isMafia;
      widget.session.lastDetectiveTarget = target;
      _showDetectiveResult = true;
    });
  }

  Widget _buildScanlineOverlay() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) => Positioned(
        top: _pulseController.value * 540,
        left: 0,
        right: 0,
        child: Container(
          height: 2,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.transparent, Colors.white.withOpacity(0.15), Colors.transparent],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetectiveHUD(Color color) {
    String target = widget.session.lastDetectiveTarget!;
    bool isMafia = widget.session.detectiveIntel[target]!;
    return Column(
      children: [
        const Text("INTEL ACQUIRED", style: TextStyle(color: Colors.white24, letterSpacing: 4)),
        const SizedBox(height: 30),
        Text(target.toUpperCase(), style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Text(isMafia ? "GUILTY" : "INNOCENT", 
          style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: isMafia ? Colors.red : Colors.green)),
        const SizedBox(height: 60),
        _buildGlassButton("ENCRYPT & PASS", () => _submitAction(null), color),
      ],
    );
  }

  Widget _buildGlassTile(String p, Color color, bool disabled, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: disabled ? null : onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
          decoration: BoxDecoration(
            color: disabled ? Colors.white.withOpacity(0.02) : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(p.toUpperCase(), 
                style: TextStyle(
                  color: disabled ? Colors.white10 : Colors.white, 
                  fontWeight: FontWeight.bold, 
                  letterSpacing: 2
                )),
              Icon(Icons.gps_fixed, size: 16, color: color.withOpacity(0.3)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassButton(String text, VoidCallback onTap, Color color) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 250, height: 55,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Center(child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2))),
      ),
    );
  }

  Widget _buildScannerUI() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) => Container(
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.1 * _pulseController.value)),
          boxShadow: [BoxShadow(color: AppTheme.glowBlue.withOpacity(0.1 * _pulseController.value), blurRadius: 40)],
        ),
        child: Icon(Icons.fingerprint, size: 80, color: Colors.white.withOpacity(0.2 + (0.4 * _pulseController.value))),
      ),
    );
  }

  Color _getRoleColor(String role) {
    if (role == "MAFIA") return const Color(0xFFEF4444);
    if (role == "DOCTOR") return const Color(0xFF3B82F6);
    if (role == "DETECTIVE") return const Color(0xFF00CED1);
    if (role == "JESTER") return const Color(0xFFF59E0B);
    return const Color(0xFF10B981);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }
}