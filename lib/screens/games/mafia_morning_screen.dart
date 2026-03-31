import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../logic/mafia_engine.dart';
import 'mafia_day_sceen.dart'; // Ensure filename matches exactly

class MafiaMorningScreen extends StatefulWidget {
  final MafiaSession session;
  const MafiaMorningScreen({super.key, required this.session});

  @override
  State<MafiaMorningScreen> createState() => _MafiaMorningScreenState();
}

class _MafiaMorningScreenState extends State<MafiaMorningScreen> with TickerProviderStateMixin {
  bool _isRevealed = false;
  late AnimationController _revealController;
  
  // Track specific outcomes for cinematic branching
  late bool _anySaved;
  late List<String> _killedPlayers;
  String? _winner;

  @override
  void initState() {
    super.initState();
    _revealController = AnimationController(vsync: this, duration: const Duration(seconds: 4));
    
    _processNightResults();

    _winner = widget.session.checkWinner();

    // Start reveal sequence
    Future.delayed(const Duration(milliseconds: 500), () => _revealController.forward());
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) setState(() => _isRevealed = true);
    });
  }

  void _processNightResults() {
    _killedPlayers = [];
    _anySaved = false;

    final targets = widget.session.lastMafiaTargets;
    final doctorTarget = widget.session.lastDoctorTarget;

    // Logic: If multiple Mafia hit different people, check each against the Doctor
    for (var target in targets) {
      if (target == doctorTarget) {
        _anySaved = true;
      } else {
        _killedPlayers.add(target);
        widget.session.deceased.add(target);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF02040A),
      body: Stack(
        children: [
          // 💎 THE CINEMATIC BRANCHED BACKGROUND
          _buildCinematicBackground(),

          // 💎 FOG OVERLAY (Animated)
          _buildMistOverlay(),

          SafeArea(
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(seconds: 1),
                child: _isRevealed 
                  ? _buildMorningOutcomeUI() 
                  : _buildSuspenseUI(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCinematicBackground() {
    // Branching Logic: If someone was killed, show the Crime Scene. 
    // If EVERYONE was saved (and targets existed), show the Miracle.
    String imageAsset = 'assets/murder_scene.jpg';
    if (_killedPlayers.isEmpty && _anySaved) {
      imageAsset = 'assets/medical_miracle.jpg';
    } else if (_killedPlayers.isEmpty && !_anySaved) {
      // Default foggy morning if no actions were taken
      imageAsset = 'assets/morning_mist.jpg'; 
    }
    
    return AnimatedBuilder(
      animation: _revealController,
      builder: (context, _) {
        return ImageFiltered(
          imageFilter: ImageFilter.blur(
            sigmaX: (1 - _revealController.value) * 40,
            sigmaY: (1 - _revealController.value) * 40,
          ),
          child: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(imageAsset),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.5 * (1 - _revealController.value)),
                  BlendMode.darken,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMistOverlay() {
    return AnimatedBuilder(
      animation: _revealController,
      builder: (context, _) => Opacity(
        opacity: 1 - _revealController.value,
        child: Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [Colors.white.withOpacity(0.1), Colors.transparent],
              radius: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMorningOutcomeUI() {
    bool tragedy = _killedPlayers.isNotEmpty;

    return Column(
      key: const ValueKey("outcome"),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.all(30),
              width: 320,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                border: Border.all(
                  color: tragedy ? Colors.redAccent.withOpacity(0.2) : Colors.tealAccent.withOpacity(0.2)
                ),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Column(
                children: [
                  Text(tragedy ? "A TRAGEDY STRUCK" : "A MEDICAL MIRACLE", 
                    style: TextStyle(
                      fontSize: 12, 
                      letterSpacing: 8, 
                      color: tragedy ? Colors.redAccent : Colors.tealAccent, 
                      fontWeight: FontWeight.bold
                    )),
                  const SizedBox(height: 20),
                  
                  if (_anySaved) 
                    const Padding(
                      padding: EdgeInsets.only(bottom: 10),
                      child: Text("THE DOCTOR SAVED THE TARGET", 
                        style: TextStyle(color: Colors.tealAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  
                  Text(
                    tragedy ? "${_killedPlayers.join(", ")} ELIMINATED" : "NO ONE DIED IN THE NIGHT",
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)
                  ),

                  if (tragedy) ...[
                    const SizedBox(height: 15),
                    ..._killedPlayers.map((p) => Text(
                      "$p WAS THE ${widget.session.roles[p]!.toUpperCase()}",
                      style: const TextStyle(color: Colors.white38, fontSize: 11, letterSpacing: 2)
                    )),
                  ]
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 60),
        
        _buildGlassButton(
          _winner != null ? "FINAL VERDICT" : "PROCEED TO TOWN SQUARE", 
          () {
            // Reset temporary Night-targets before day starts
            widget.session.lastMafiaTargets.clear();
            widget.session.lastDoctorTarget = null;
            
            if (_winner != null) {
              Navigator.pop(context); 
            } else {
              Navigator.pushReplacement(context, MaterialPageRoute(
                builder: (context) => MafiaDayScreen(session: widget.session)
              ));
            }
          }
        ),
      ],
    );
  }

  Widget _buildSuspenseUI() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("WAKING THE VILLAGE...", 
          style: TextStyle(color: Colors.white24, letterSpacing: 10, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 30),
        SizedBox(
          width: 40, height: 40,
          child: CircularProgressIndicator(
            strokeWidth: 1, 
            color: Colors.white.withOpacity(0.2)
          ),
        ),
      ],
    );
  }

  Widget _buildGlassButton(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 280, height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white10),
            ),
            child: Center(
              child: Text(text, 
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2))
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _revealController.dispose();
    super.dispose();
  }
}