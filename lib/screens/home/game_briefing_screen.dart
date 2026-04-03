import 'dart:ui';
import 'package:flutter/material.dart';
import '../../models/game_model.dart';

class GameBriefingScreen extends StatefulWidget {
  final Game game;

  const GameBriefingScreen({super.key, required this.game});

  @override
  State<GameBriefingScreen> createState() => _GameBriefingScreenState();
}

class _GameBriefingScreenState extends State<GameBriefingScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  // 🎨 REFINED COLOR LOGIC: Desaturated Neons
  Color _getThemeColor() {
    switch (widget.game.id) {
      case 'sync':
      case 'undercover':
        return const Color(0xFFB300FF); 
      case 'spy':
        return const Color(0xFF00E5FF); 
      case 'interrogation':
        return Colors.white; 
      case 'the_glitch':
        return const Color(0xFFFC7B77); 
      case 'heads_up':
        return const Color(0xFF00E5FF); 
      case 'guess_the_liar':
        return const Color(0xFFB300FF); 
      case 'glitch':
      case 'mafia':
        return const Color(0xFFFF3D00); 
      case 'dont_get_caught':
        return const Color.fromARGB(255, 174, 58, 54); 
      case 'dont_get_me_started':
        return const Color(0xFFF86A05); 
      case 'informant':
        return const Color(0xFF09AE64); 
      case 'most_likely_to':
        return Colors.white; 
      default:
        return const Color(0xFF00E5FF);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color themeColor = _getThemeColor();

    return Scaffold(
      backgroundColor: const Color(0xFF020408),
      body: Stack(
        children: [
          // 💎 THE FULL-BLEED BANNER
          Positioned(
            top: 0, left: 0, right: 0,
            height: MediaQuery.of(context).size.height * 0.70,
            child: ShaderMask(
              shaderCallback: (rect) => const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black, Colors.transparent],
                stops: [0.6, 1.0],
              ).createShader(rect),
              blendMode: BlendMode.dstIn,
              child: Image.asset(
                'assets/${widget.game.id}_banner.jpg',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(color: Colors.black),
              ),
            ),
          ),

          // 💎 INTERACTIVE HUD
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopNav(),
                const Spacer(),
                
                // MISSION PROTOCOL MARKER
                _buildMissionMarker(themeColor),

                // CONTENT BLOCK
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.game.name.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white, fontSize: 42, fontWeight: FontWeight.w900,
                          letterSpacing: 2, height: 1.0
                        )),
                      const SizedBox(height: 15),
                      Text(widget.game.description,
                        style: const TextStyle(
                          color: Colors.white54, fontSize: 14, height: 1.6, 
                          fontFamily: 'Quicksand'
                        )),
                    ],
                  ),
                ),

                // 💎 THE DUAL-STATE ACTION DECK
                _buildActionDeck(themeColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopNav() {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white24, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildMissionMarker(Color theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 30),
      child: Row(
        children: [
          Container(width: 3, height: 20, color: theme),
          const SizedBox(width: 15),
          Text("PROTOCOL: ${widget.game.id.toUpperCase()}", 
            style: TextStyle(
              color: theme.withOpacity(0.8), fontSize: 10, letterSpacing: 4, 
              fontWeight: FontWeight.bold, fontFamily: 'monospace'
            )),
        ],
      ),
    );
  }

  Widget _buildActionDeck(Color theme) {
    bool supportsOnline = widget.game.isOnline; 
    bool nooffline = !widget.game.isOnline;
    // Force "Don't Get Caught" to be offline only if not already set
    // OFFLINE
    if (widget.game.id == 'dont_get_caught') supportsOnline = false;
    if (widget.game.id == 'the_glitch') nooffline = false;
    if (widget.game.id == 'interrogation') nooffline = false;
    if (widget.game.id == 'spy') nooffline = false;
    if (widget.game.id == 'undercover') nooffline = false;
    if (widget.game.id == 'informant') nooffline = false;
    if (widget.game.id == 'dont_get_caught') nooffline = false;
    if (widget.game.id == 'heads_up') nooffline = false;
    if (widget.game.id == 'mafia') nooffline = false;

    //ONLINE
    if (widget.game.id == 'guess_the_liar') nooffline = false;
    if (widget.game.id == 'most_likely_to') nooffline = true;
    if (widget.game.id == 'dont_get_me_started') nooffline = false;



    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(30, 20, 30, 40),
      child: Row(
        children: [
          if (nooffline == false) ...[
          Expanded(child: _buildTacticalButton("OFFLINE", theme, false)),
          ],
          
          if (supportsOnline) ...[
          const SizedBox(width: 20),
          Expanded(child: _buildTacticalButton("ONLINE", theme, true)),
          ],
        ],
      ),
    );
  }

  Widget _buildTacticalButton(String label, Color theme, bool isPrimary) {
    return GestureDetector(
      onTap: () {
        if (isPrimary) {
          // Pass the game object directly
          Navigator.pushNamed(context, '/game_lobby', arguments: widget.game);
        } else {
          // ✅ FIXED: Pass the game object as the argument so 'main.dart' doesn't receive null
          Navigator.pushNamed(
            context, 
            '/setup/pass_and_play', 
            arguments: widget.game,
          );
        }
      },
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) => Container(
          height: 65,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: isPrimary ? theme.withOpacity(0.03) : Colors.white.withOpacity(0.01),
            border: Border.all(
              color: isPrimary 
                ? theme.withOpacity(0.4 + (0.4 * _pulseController.value)) 
                : Colors.white10,
              width: 1.5,
            ),
            boxShadow: isPrimary ? [
              BoxShadow(
                color: theme.withOpacity(0.15 * _pulseController.value),
                blurRadius: 15, spreadRadius: -5,
              )
            ] : [],
          ),
          child: Center(
            child: Text(label,
              style: TextStyle(
                color: isPrimary ? Colors.white : Colors.white24,
                fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 3,
                fontFamily: 'monospace'
              )),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }
}