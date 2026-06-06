import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme.dart';
import '../../models/game_model.dart';
import 'game_briefing_screen.dart';

class HomeScreen extends StatelessWidget {
  final String nickname;
  const HomeScreen({super.key, required this.nickname});

  static const Map<String, IconData> _gameIcons = {
    'sync': Icons.sync,
    'guess_the_liar': Icons.psychology,
    'most_likely_to': Icons.people,
    'dont_get_me_started': Icons.forum,
    'glitch': Icons.bug_report,
    'mafia': Icons.security,
    'heads_up': Icons.smartphone,
    'interrogation': Icons.mic,
    'spy': Icons.search,
    'undercover': Icons.visibility_off,
    'informant': Icons.support_agent,
    'dont_get_caught': Icons.camera,
    'chameleon': Icons.grid_view,
  };

  static const Map<String, Color> _gameAccents = {
    'sync': Color(0xFF38BDF8),
    'guess_the_liar': Color(0xFFF472B6),
    'most_likely_to': Color(0xFF22D3EE),
    'dont_get_me_started': Color(0xFFF97316),
    'glitch': Color(0xFFEF4444),
    'mafia': Color(0xFFDC2626),
    'heads_up': Color(0xFF60A5FA),
    'interrogation': Color(0xFF818CF8),
    'spy': Color(0xFFFBBF24),
    'undercover': Color(0xFFA855F7),
    'informant': Color(0xFF14B8A6),
    'dont_get_caught': Color(0xFF22C55E),
    'chameleon': Color(0xFF8BC34A),
  };

  void _showJoinCommsDialog(BuildContext context) {
    final codeController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0B1226),
        title: const Text(
          'ENTER 8-DIGIT CODE',
          style: TextStyle(color: Colors.white, fontSize: 14),
        ),
        content: TextField(
          controller: codeController,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white, letterSpacing: 4),
          decoration: const InputDecoration(
            hintText: '0000 0000',
            hintStyle: TextStyle(color: Colors.white24),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              final code = codeController.text.replaceAll(' ', '');
              if (code.length == 8) {
                Navigator.pop(context);
                Navigator.pushNamed(
                  context,
                  '/comm_room',
                  arguments: {'roomCode': code},
                );
              }
            },
            child: const Text('CONNECT'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final columns = width > 900 ? 5 : (width > 600 ? 4 : 2);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          Positioned(
            top: -100,
            left: -50,
            child: _glowOrb(250, Theme.of(context).colorScheme.primary.withOpacity(0.2)),
          ),
          Positioned(
            bottom: -70,
            right: -50,
            child: _glowOrb(300, Theme.of(context).colorScheme.secondary.withOpacity(0.16)),
          ),
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                  sliver: SliverToBoxAdapter(
                    child: _buildHeader(context),
                  ),
                ),
                SliverToBoxAdapter(child: _buildCommRoomEntry(context)),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      'AVAILABLE MISSIONS',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.28),
                        fontSize: 12,
                        letterSpacing: 2,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverGrid.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.82,
                    ),
                    itemCount: games.length,
                    itemBuilder: (context, index) => _buildGameCard(context, games[index]),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome back, $nickname',
          style: TextStyle(
            color: Colors.white.withOpacity(0.62),
            fontSize: 16,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: Text(
                'Choose Your Mission',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            _buildThemeSelector(context),
          ],
        ),
      ],
    );
  }

  Widget _buildThemeSelector(BuildContext context) {
    return ValueListenableBuilder<AppThemePreset>(
      valueListenable: ThemeController.preset,
      builder: (context, currentPreset, _) {
        return PopupMenuButton<AppThemePreset>(
          tooltip: 'Change UI style',
          icon: Icon(Icons.palette_outlined, color: Theme.of(context).colorScheme.primary),
          color: Theme.of(context).colorScheme.surface,
          onSelected: (preset) {
            HapticFeedback.selectionClick();
            ThemeController.setPreset(preset);
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: AppThemePreset.lumeGlass, child: Text('Lume Glass')),
            PopupMenuItem(value: AppThemePreset.neonTabletop, child: Text('Neon Tabletop')),
            PopupMenuItem(value: AppThemePreset.caseFile, child: Text('Case File')),
          ],
        );
      },
    );
  }

  Widget _buildCommRoomEntry(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _buildActionBtn(
              context,
              'CREATE',
              Icons.add_moderator,
              () {
                final code = (10000000 + (DateTime.now().millisecondsSinceEpoch % 90000000)).toString();
                Navigator.pushNamed(
                  context,
                  '/comm_room',
                  arguments: {'roomCode': code, 'isHost': true},
                );
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildActionBtn(
              context,
              'JOIN',
              Icons.qr_code_scanner,
              () => _showJoinCommsDialog(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBtn(BuildContext context, String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameCard(BuildContext context, Game game) {
    final accent = _gameAccents[game.id] ?? Theme.of(context).colorScheme.primary;
    final icon = _gameIcons[game.id] ?? Icons.extension;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => GameBriefingScreen(game: game)),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  game.imageAsset,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      Container(color: Theme.of(context).colorScheme.surface),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.08),
                        Colors.black.withOpacity(0.82),
                      ],
                    ),
                    border: Border.all(color: Colors.white.withOpacity(0.12), width: 1.2),
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: accent.withOpacity(0.18),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, color: accent, size: 22),
                        ),
                        _buildModePill(game.isOnline),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      game.name.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        height: 1.1,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      game.description,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 10,
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.people_outline, color: accent, size: 13),
                        const SizedBox(width: 5),
                        Text(
                          '${game.minPlayers}-${game.maxPlayers} players',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.72),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModePill(bool isOnline) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.45),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(
        isOnline ? 'ONLINE' : 'LOCAL',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.8,
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
        boxShadow: [BoxShadow(color: color, blurRadius: 100, spreadRadius: 50)],
      ),
    );
  }
}
