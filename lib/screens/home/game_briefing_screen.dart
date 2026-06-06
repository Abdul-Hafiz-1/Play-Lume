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
                widget.game.imageAsset,
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

  void _showInfoBottomSheet(BuildContext context) {
    final Color themeColor = _getThemeColor();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.75,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF0E1329).withOpacity(0.9),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              border: Border.all(color: themeColor.withOpacity(0.3), width: 1.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 16),
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: themeColor.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.info_outline_rounded, color: themeColor, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "MISSION BRIEFING",
                              style: TextStyle(
                                color: themeColor.withOpacity(0.8),
                                fontSize: 10,
                                letterSpacing: 3,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace'
                              ),
                            ),
                            Text(
                              widget.game.name.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white54),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(color: Colors.white10, height: 1),
                Flexible(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "OBJECTIVE",
                          style: TextStyle(
                            color: themeColor,
                            fontSize: 12,
                            letterSpacing: 2,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace'
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.game.description,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          "OPERATIONAL MANUAL & RULES",
                          style: TextStyle(
                            color: themeColor,
                            fontSize: 12,
                            letterSpacing: 2,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace'
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.02),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withOpacity(0.05)),
                          ),
                          child: Text(
                            widget.game.instructions,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              height: 1.6,
                              fontFamily: 'Quicksand',
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Icon(Icons.people_outline_rounded, color: themeColor, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              "PERSONNEL REQUIRED: ${widget.game.minPlayers}-${widget.game.maxPlayers} OPERATIVES",
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 11,
                                letterSpacing: 1.5,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace'
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopNav() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white24, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline_rounded, color: Colors.white70, size: 24),
            onPressed: () => _showInfoBottomSheet(context),
          ),
        ],
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
    bool supportsOffline = true;
    bool supportsOnline = widget.game.isOnline;

    if (widget.game.id == 'most_likely_to') {
      supportsOffline = false;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(30, 20, 30, 40),
      child: Row(
        children: [
          if (supportsOffline) ...[
            Expanded(child: _buildTacticalButton("OFFLINE", theme, false)),
          ],
          if (supportsOffline && supportsOnline) ...[
            const SizedBox(width: 20),
          ],
          if (supportsOnline) ...[
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
