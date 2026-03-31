import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../logic/mafia_engine.dart';
import '../../core/theme.dart';
import 'mafia_night_screen.dart';

enum DayStage { discussion, voting, execution }

class MafiaDayScreen extends StatefulWidget {
  final MafiaSession session;
  const MafiaDayScreen({super.key, required this.session});

  @override
  State<MafiaDayScreen> createState() => _MafiaDayScreenState();
}

class _MafiaDayScreenState extends State<MafiaDayScreen> {
  DayStage _currentStage = DayStage.discussion;
  int _secondsRemaining = 180; // 3 Minutes
  Timer? _timer;
  String? _exiledPlayer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
        if (_secondsRemaining <= 10) HapticFeedback.vibrate();
      } else {
        _timer?.cancel();
        setState(() => _currentStage = DayStage.voting);
      }
    });
  }

  void _handleVote(String name) {
    _timer?.cancel();
    setState(() {
      if (name != "SKIP") {
        widget.session.deceased.add(name);
        _exiledPlayer = name;
      } else {
        _exiledPlayer = "NONE";
      }
      _currentStage = DayStage.execution;
    });
    HapticFeedback.heavyImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF02040A),
      body: Stack(
        children: [
          // 💎 THE TOWN HALL BACKGROUND
          Positioned.fill(
            child: Image.asset('assets/town_hall.jpg', fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: Colors.black)),
          ),
          Positioned.fill(child: Container(color: Colors.black.withOpacity(0.8))),

          SafeArea(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 600),
              child: _buildStageContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStageContent() {
    switch (_currentStage) {
      case DayStage.discussion: return _buildDiscussionUI();
      case DayStage.voting: return _buildVotingUI();
      case DayStage.execution: return _buildExecutionUI();
    }
  }

  // --- STAGE 1: DISCUSSION ---
  Widget _buildDiscussionUI() {
    Color timerColor = _secondsRemaining < 30 ? Colors.redAccent : (_secondsRemaining < 60 ? Colors.orangeAccent : AppTheme.primaryBlue);
    return Center(
      key: const ValueKey("discussion"),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("TOWN DISCUSSION", style: TextStyle(color: Colors.white24, letterSpacing: 8, fontWeight: FontWeight.bold)),
          const SizedBox(height: 60),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(width: 220, height: 220, 
                child: CircularProgressIndicator(value: _secondsRemaining / 180, strokeWidth: 8, color: timerColor, backgroundColor: Colors.white10)),
              Text("${(_secondsRemaining ~/ 60)}:${(_secondsRemaining % 60).toString().padLeft(2, '0')}",
                  style: const TextStyle(fontSize: 60, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 60),
          _buildGlassButton("PROCEED TO VOTE", () {
            _timer?.cancel();
            setState(() => _currentStage = DayStage.voting);
          }),
        ],
      ),
    );
  }

  // --- STAGE 2: VOTING (Filtered for Survivors) ---
  Widget _buildVotingUI() {
    return Column(
      key: const ValueKey("voting"),
      children: [
        const SizedBox(height: 40),
        const Text("THE TRIBUNAL", style: TextStyle(color: Colors.white24, letterSpacing: 4)),
        const Text("CAST YOUR VOTE", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
        const SizedBox(height: 30),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            children: [
              ...widget.session.survivors.map((p) => _buildVoteTile(p)),
              const SizedBox(height: 20),
              _buildVoteTile("SKIP VOTE", isSkip: true),
            ],
          ),
        ),
      ],
    );
  }

  // --- STAGE 3: EXECUTION REVEAL ---
  Widget _buildExecutionUI() {
    bool isMafia = _exiledPlayer != "NONE" && widget.session.roles[_exiledPlayer] == "MAFIA";
    String? winner = widget.session.checkWinner();

    return Center(
      key: const ValueKey("execution"),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(_exiledPlayer == "NONE" ? "NO ONE WAS EXILED" : "${_exiledPlayer!.toUpperCase()} WAS EXILED",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white)),
          if (_exiledPlayer != "NONE" && _exiledPlayer != "NONE") ...[
            const SizedBox(height: 10),
            Text("THEY WERE THE ${widget.session.roles[_exiledPlayer]!.toUpperCase()}",
                style: TextStyle(color: isMafia ? Colors.greenAccent : Colors.redAccent, fontWeight: FontWeight.bold, letterSpacing: 2)),
          ],
          const SizedBox(height: 80),
          _buildGlassButton(winner != null ? "FINAL RESULTS" : "NIGHT FALLS", () {
            if (winner != null) {
              Navigator.pop(context); 
            } else {
              Navigator.pushReplacement(context, MaterialPageRoute(
                builder: (context) => MafiaNightScreen(session: widget.session)
              ));
            }
          }),
        ],
      ),
    );
  }

  // --- UI COMPONENTS ---

  Widget _buildVoteTile(String name, {bool isSkip = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => _handleVote(isSkip ? "NONE" : name),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isSkip ? Colors.white.withOpacity(0.02) : Colors.white.withOpacity(0.05),
                border: Border.all(color: Colors.white10),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(child: Text(name.toUpperCase(), style: TextStyle(color: isSkip ? Colors.white38 : Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2))),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassButton(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            width: 280, height: 60,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), border: Border.all(color: Colors.white10), borderRadius: BorderRadius.circular(20)),
            child: Center(child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2))),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}