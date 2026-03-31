import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../logic/mafia_engine.dart';
import '../../core/theme.dart';
import 'mafia_night_screen.dart';

enum DayPhase { discussion, voting, execution }

class MafiaMorningScreen extends StatefulWidget {
  final MafiaSession session;
  const MafiaMorningScreen({super.key, required this.session});

  @override
  State<MafiaMorningScreen> createState() => _MafiaMorningScreenState();
}

class _MafiaMorningScreenState extends State<MafiaMorningScreen> with TickerProviderStateMixin {
  DayPhase _phase = DayPhase.discussion;
  int _secondsRemaining = 180; // 3 Minutes
  Timer? _timer;
  String? _selectedForExecution;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
        if (_secondsRemaining <= 10) HapticFeedback.heavyImpact();
      } else {
        _timer?.cancel();
        setState(() => _phase = DayPhase.voting);
      }
    });
  }

  void _confirmExecution(String player) {
    _timer?.cancel();
    setState(() {
      if (player != "NONE") {
        widget.session.deceased.add(player);
      }
      _selectedForExecution = player;
      _phase = DayPhase.execution;
    });
    HapticFeedback.vibrate();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF02040A),
      body: Stack(
        children: [
          _buildTacticalBackground(),
          SafeArea(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 600),
              child: _buildBody(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_phase) {
      case DayPhase.discussion: return _buildDiscussion();
      case DayPhase.voting: return _buildVoting();
      case DayPhase.execution: return _buildExecutionResult();
    }
  }

  // --- 1. DISCUSSION ---
  Widget _buildDiscussion() {
    double progress = _secondsRemaining / 180;
    Color timerColor = _secondsRemaining < 30 ? Colors.redAccent : (_secondsRemaining < 60 ? Colors.orangeAccent : AppTheme.primaryBlue);

    return Center(
      key: const ValueKey("disc"),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("TOWN DISCUSSION", style: TextStyle(color: Colors.white24, letterSpacing: 8, fontSize: 12)),
          const SizedBox(height: 60),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 240, height: 240,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 8,
                  color: timerColor,
                  backgroundColor: Colors.white10,
                ),
              ),
              Text(
                "${(_secondsRemaining ~/ 60)}:${(_secondsRemaining % 60).toString().padLeft(2, '0')}",
                style: const TextStyle(fontSize: 64, fontWeight: FontWeight.w900, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 80),
          _buildLumeButton("PROCEED TO VOTE", () {
            _timer?.cancel();
            setState(() => _phase = DayPhase.voting);
          }, AppTheme.primaryBlue),
        ],
      ),
    );
  }

  // --- 2. VOTING ---
  Widget _buildVoting() {
    return Column(
      key: const ValueKey("vote"),
      children: [
        const SizedBox(height: 40),
        const Text("THE TRIBUNAL", style: TextStyle(color: Colors.white24, letterSpacing: 8)),
        const Text("IDENTIFY THE SUSPECT", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 30),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            children: widget.session.survivors.map((p) => _buildVoteTile(p)).toList(),
          ),
        ),
        _buildLumeButton("NO ONE EXILED", () => _confirmExecution("NONE"), Colors.white10),
        const SizedBox(height: 30),
      ],
    );
  }

  // --- 3. EXECUTION ---
  Widget _buildExecutionResult() {
    String? winner = widget.session.checkWinner();
    bool isMafia = _selectedForExecution != "NONE" && widget.session.roles[_selectedForExecution] == "MAFIA";

    return Center(
      key: const ValueKey("exec"),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("THE VERDICT", style: TextStyle(color: Colors.white24, letterSpacing: 8)),
          const SizedBox(height: 40),
          Text(
            _selectedForExecution == "NONE" ? "THE TOWN STAYS THEIR HAND" : "${_selectedForExecution!.toUpperCase()} WAS EXILED",
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white),
          ),
          if (_selectedForExecution != "NONE") ...[
            const SizedBox(height: 10),
            Text(
              "THEY WERE THE ${widget.session.roles[_selectedForExecution]!.toUpperCase()}",
              style: TextStyle(color: isMafia ? Colors.greenAccent : Colors.redAccent, fontWeight: FontWeight.bold, letterSpacing: 2),
            ),
          ],
          const SizedBox(height: 80),
          if (winner != null)
            _buildLumeButton("VIEW FINAL RESULTS", () => Navigator.pop(context), Colors.amber)
          else
            _buildLumeButton("NIGHT FALLS", () {
              Navigator.pushReplacement(context, MaterialPageRoute(
                builder: (context) => MafiaNightScreen(session: widget.session),
              ));
            }, AppTheme.primaryBlue),
        ],
      ),
    );
  }

  // --- UI ATOMICS ---

  Widget _buildVoteTile(String name) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => _confirmExecution(name),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                border: Border.all(color: Colors.white10),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(name.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2)),
                  const Icon(Icons.gavel_rounded, color: Colors.white24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLumeButton(String text, VoidCallback onTap, Color color) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 280, height: 60,
        decoration: BoxDecoration(
          color: color.withOpacity(0.8),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: color.withOpacity(0.2), blurRadius: 20)],
        ),
        child: Center(child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2))),
      ),
    );
  }

  Widget _buildTacticalBackground() {
    return Stack(
      children: [
        // Using the same tactical map but with a warmer morning tint
        Positioned.fill(
          child: Opacity(
            opacity: 0.3,
            child: Image.asset('lib/assets/images/tactical_map.jpg', fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container()),
          ),
        ),
        Positioned.fill(child: Container(color: Colors.black.withOpacity(0.6))),
      ],
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }
}