import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:play_lumee/logic/mafia_engine.dart';
import 'package:play_lumee/screens/games/mafia_night_screen.dart';
import 'package:vibration/vibration.dart';
import '../../core/theme.dart';

class MafiaGameScreen extends StatefulWidget {
  final List<String> players;
  const MafiaGameScreen({super.key, required this.players});

  @override
  State<MafiaGameScreen> createState() => _MafiaGameScreenState();
}

class _MafiaGameScreenState extends State<MafiaGameScreen> with TickerProviderStateMixin {
  int _currentPlayerIndex = 0;
  bool _isRevealed = false;
  bool _intelSecured = false; 
  late Map<String, String> _playerRoles;
  
  late AnimationController _bgController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _assignRoles();
    _bgController = AnimationController(vsync: this, duration: const Duration(seconds: 20))..repeat();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
  }

  void _assignRoles() {
    List<String> roles = [];
    int count = widget.players.length;
    
    // Balanced Scaling Logic ensuring Jester presence
    int mafiaCount = (count >= 6) ? 2 : 1;
    int doctorCount = 1;
    int detectiveCount = (count >= 5) ? 1 : 0;
    int jesterCount = (count >= 6) ? 1 : 0;

    for (int i = 0; i < mafiaCount; i++) roles.add("MAFIA");
    for (int i = 0; i < doctorCount; i++) roles.add("DOCTOR");
    if (detectiveCount > 0) roles.add("DETECTIVE");
    if (jesterCount > 0) roles.add("JESTER");
    
    while (roles.length < count) roles.add("VILLAGER");
    roles.shuffle();
    _playerRoles = Map.fromIterables(widget.players, roles);
  }

  String _getRoleImage(String role) {
    switch (role) {
      case "MAFIA": return "assets/Mafia.jpg";
      case "DOCTOR": return "assets/Doctor.jpg";
      case "DETECTIVE": return "assets/Detective.jpg";
      case "JESTER": return "assets/Jester.jpg";
      default: return "assets/Villager.jpg";
    }
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case "MAFIA": return const Color(0xFFEF4444);
      case "DOCTOR": return const Color(0xFF3B82F6);
      case "DETECTIVE": return const Color(0xFF00CED1);
      case "JESTER": return const Color(0xFFF59E0B);
      default: return const Color(0xFF10B981);
    }
  }

  @override
  Widget build(BuildContext context) {
    String currentPlayer = widget.players[_currentPlayerIndex];
    String role = _playerRoles[currentPlayer]!;
    Color roleColor = _getRoleColor(role);

    return Scaffold(
      backgroundColor: const Color(0xFF04060E),
      body: Stack(
        children: [
          _buildLivingBackground(roleColor),
          SafeArea(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 800),
              switchInCurve: Curves.easeInOutCubic,
              switchOutCurve: Curves.easeInOutCubic,
              child: _intelSecured 
                ? _buildTransferScreen(roleColor) 
                : _buildRevealStep(currentPlayer, role, roleColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevealStep(String name, String role, Color color) {
    return Center(
      key: const ValueKey("reveal_step"),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildSubtitle("IDENTITY SECURED FOR"),
          const SizedBox(height: 8),
          Text(name.toUpperCase(), style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2)),
          const SizedBox(height: 40),
          GestureDetector(
            onLongPressStart: (_) {
              setState(() => _isRevealed = true);
              Vibration.vibrate(duration: 40);
              HapticFeedback.mediumImpact();
            },
            onLongPressEnd: (_) => setState(() => _isRevealed = false),
            child: _buildRoleCard(role, color, _isRevealed),
          ),
          const SizedBox(height: 50),
          AnimatedOpacity(
            opacity: _isRevealed ? 0 : 1,
            duration: const Duration(milliseconds: 400),
            child: _buildCreativeButton("SECURE INTEL", () => setState(() => _intelSecured = true), color),
          ),
        ],
      ),
    );
  }

  Widget _buildTransferScreen(Color roleColor) {
    bool isLast = _currentPlayerIndex == widget.players.length - 1;
    String nextPlayer = isLast ? "EVERYONE" : widget.players[_currentPlayerIndex + 1];

    return Center(
      key: const ValueKey("transfer_step"),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildGlowingIcon(Icons.swap_horizontal_circle_outlined),
          const SizedBox(height: 30),
          _buildSubtitle("INTEL ENCRYPTED"),
          const SizedBox(height: 12),
          Text("HAND TO $nextPlayer", textAlign: TextAlign.center, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1)),
          const SizedBox(height: 60),
          _buildCreativeButton(
            "I AM ${nextPlayer.toUpperCase()}", 
            () {
              if (isLast) {
                // 🚀 THE FIX: This is the bridge you were missing
                // We create the session and move to the Night Screen
                final session = MafiaSession(
                  allPlayers: widget.players,
                  roles: _playerRoles,
                );

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MafiaNightScreen(session: session),
                  ),
                );
              } else {
                // Logic for middle players
                setState(() {
                  _currentPlayerIndex++;
                  _intelSecured = false;
                  _isRevealed = false;
                });
              }
            }, 
            AppTheme.primaryBlue
          ),
        ],
      ),
    );
  }

  Widget _buildSubtitle(String text) {
    return Text(text, style: TextStyle(color: Colors.white.withOpacity(0.3), letterSpacing: 4, fontSize: 10, fontWeight: FontWeight.bold));
  }

  Widget _buildGlowingIcon(IconData icon) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: AppTheme.glowBlue.withOpacity(0.2 * _pulseController.value), blurRadius: 40, spreadRadius: 10)],
        ),
        child: Icon(icon, size: 80, color: Colors.white.withOpacity(0.6)),
      ),
    );
  }

  Widget _buildCreativeButton(String text, VoidCallback onTap, Color themeColor) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, _) => Container(
              width: 220, height: 30,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(50),
                boxShadow: [BoxShadow(color: themeColor.withOpacity(0.3 * _pulseController.value), blurRadius: 25, spreadRadius: 2)],
              ),
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                width: 280, height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(color: Colors.white.withOpacity(0.1), width: 1.2),
                ),
                child: Center(
                  child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 13)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleCard(String role, Color color, bool revealed) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutQuint,
      width: 310, height: 460,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(45),
        border: Border.all(color: revealed ? color.withOpacity(0.5) : Colors.white10, width: 2),
        boxShadow: [if (revealed) BoxShadow(color: color.withOpacity(0.3), blurRadius: 40, spreadRadius: 10)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(45),
        child: Stack(
          children: [
            Positioned.fill(child: Image.asset(_getRoleImage(role), fit: BoxFit.cover)),
            BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: revealed ? 0.0 : 30.0, 
                sigmaY: revealed ? 0.0 : 30.0,
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                color: revealed ? Colors.black.withOpacity(0.55) : Colors.white.withOpacity(0.05),
                padding: const EdgeInsets.all(35),
                child: revealed 
                    ? _buildCardText(role, color) 
                    : Center(child: Icon(Icons.fingerprint, size: 90, color: Colors.white.withOpacity(0.15))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardText(String role, Color color) {
    String desc = "";
    if (role == "MAFIA") desc = "Eliminate the town without being caught. Coordinate at night.";
    else if (role == "DOCTOR") desc = "Protect one person each night. You can save yourself once.";
    else if (role == "DETECTIVE") desc = "Check one player's alignment each night.";
    else if (role == "JESTER") desc = "Tricking the town into voting you out is your only goal!";
    else desc = "Find the Mafia and vote them out during the day.";

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: double.infinity,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(role, style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: color, letterSpacing: 6, shadows: [Shadow(color: Colors.black.withOpacity(0.8), blurRadius: 20)])),
          ),
        ),
        const SizedBox(height: 12),
        Container(height: 3, width: 50, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10))),
        const SizedBox(height: 30),
        Text(desc, textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withOpacity(0.95), fontSize: 16, height: 1.5, shadows: [Shadow(color: Colors.black, blurRadius: 15)])),
      ],
    );
  }

  Widget _buildLivingBackground(Color roleColor) {
    return AnimatedBuilder(
      animation: _bgController,
      builder: (context, _) => Stack(
        children: [
          Positioned(top: -100 + (60 * sin(_bgController.value * 2 * pi)), left: -50, child: _buildOrb(500, roleColor.withOpacity(0.12))),
          Positioned(bottom: -50, right: -100 + (50 * sin(_bgController.value * 2 * pi)), child: _buildOrb(600, AppTheme.glowBlue.withOpacity(0.1))),
          BackdropFilter(filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100), child: Container(color: Colors.transparent)),
        ],
      ),
    );
  }

  Widget _buildOrb(double size, Color color) => Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [color, Colors.transparent])));

  @override
  void dispose() { 
    _bgController.dispose(); 
    _pulseController.dispose();
    super.dispose(); 
  }
}