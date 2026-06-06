import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme.dart';
import '../../models/game_model.dart';

class PassAndPlaySetupScreen extends StatefulWidget {
  final Game game;
  const PassAndPlaySetupScreen({super.key, required this.game});

  @override
  State<PassAndPlaySetupScreen> createState() => _PassAndPlaySetupScreenState();
}

class _PassAndPlaySetupScreenState extends State<PassAndPlaySetupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final List<String> _players = [];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _addPlayer() {
    if (_players.length >= widget.game.maxPlayers) return;
    final name = _nameController.text.trim();
    if (name.isNotEmpty && !_players.contains(name)) {
      HapticFeedback.mediumImpact();
      setState(() => _players.add(name));
      _nameController.clear();
    }
  }

  void _removePlayer(int index) {
    HapticFeedback.selectionClick();
    setState(() => _players.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    final canProceed = _players.length >= widget.game.minPlayers &&
        _players.length <= widget.game.maxPlayers;
    final accent = canProceed ? AppTheme.glowBlue : const Color(0xFFFFB300);
    final progress = (_players.length / widget.game.minPlayers).clamp(0.0, 1.0).toDouble();

    return Scaffold(
      backgroundColor: AppTheme.darkBase,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              widget.game.imageAsset,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(color: AppTheme.darkBase),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.darkBase.withOpacity(0.68),
                    AppTheme.darkBase.withOpacity(0.92),
                    AppTheme.darkBase,
                  ],
                ),
              ),
            ),
          ),
          Positioned(top: -120, left: -80, child: _glowOrb(300, accent.withOpacity(0.18))),
          Positioned(bottom: -140, right: -80, child: _glowOrb(360, Colors.purpleAccent.withOpacity(0.12))),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 12, 22, 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(accent),
                      const SizedBox(height: 18),
                      _buildStatusCard(accent, progress, canProceed),
                      const SizedBox(height: 16),
                      _buildInput(accent),
                      const SizedBox(height: 16),
                      Expanded(child: _buildRoster(accent)),
                      const SizedBox(height: 16),
                      _buildStartButton(canProceed, accent),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(Color accent) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.game.name.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.4,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'PASS & PLAY SETUP',
                style: TextStyle(
                  color: accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard(Color accent, double progress, bool canProceed) {
    return _glassPanel(
      borderColor: accent.withOpacity(0.35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.14),
                  shape: BoxShape.circle,
                  border: Border.all(color: accent.withOpacity(0.4)),
                ),
                child: Icon(canProceed ? Icons.check_rounded : Icons.groups_rounded, color: accent),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      canProceed ? 'Roster Ready' : 'Add ${widget.game.minPlayers - _players.length} More',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_players.length}/${widget.game.maxPlayers} players joined • minimum ${widget.game.minPlayers}',
                      style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white.withOpacity(0.08),
              color: accent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput(Color accent) {
    return _glassPanel(
      padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
      borderColor: Colors.white.withOpacity(0.12),
      child: Row(
        children: [
          Icon(Icons.badge_outlined, color: accent),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                hintText: 'Add player name',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.25)),
                border: InputBorder.none,
              ),
              onSubmitted: (_) => _addPlayer(),
            ),
          ),
          IconButton(
            onPressed: _addPlayer,
            icon: Icon(Icons.add_circle_rounded, color: accent, size: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildRoster(Color accent) {
    if (_players.isEmpty) {
      return _glassPanel(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.group_add_outlined, color: Colors.white.withOpacity(0.24), size: 64),
              const SizedBox(height: 14),
              const Text(
                'No players added yet',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              Text(
                'Build the roster, then start the mission.',
                style: TextStyle(color: Colors.white.withOpacity(0.45)),
              ),
            ],
          ),
        ),
      );
    }

    return _glassPanel(
      padding: const EdgeInsets.all(12),
      child: ListView.separated(
        physics: const BouncingScrollPhysics(),
        itemCount: _players.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final player = _players[index];
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.045),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 19,
                  backgroundColor: accent.withOpacity(0.16),
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(color: accent, fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    player,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  tooltip: 'Remove player',
                  onPressed: () => _removePlayer(index),
                  icon: const Icon(Icons.close_rounded, color: Colors.white38),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStartButton(bool active, Color accent) {
    return GestureDetector(
      onTap: active
          ? () {
              HapticFeedback.vibrate();
              Navigator.pushNamed(
                context,
                widget.game.actualGameRouteName,
                arguments: {'players': _players},
              );
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        height: 62,
        decoration: BoxDecoration(
          color: active ? accent : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: active ? accent : Colors.white.withOpacity(0.1)),
          boxShadow: active ? [BoxShadow(color: accent.withOpacity(0.34), blurRadius: 24)] : [],
        ),
        child: Center(
          child: Text(
            active ? 'START MISSION' : 'ADD ${widget.game.minPlayers} PLAYERS TO START',
            style: TextStyle(
              color: active ? Colors.white : Colors.white30,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _glassPanel({
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(18),
    Color? borderColor,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: const Color(0xFF0E1329).withOpacity(0.62),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: borderColor ?? Colors.white.withOpacity(0.1), width: 1.2),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _glowOrb(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [BoxShadow(color: color, blurRadius: 140, spreadRadius: 42)],
      ),
    );
  }
}
