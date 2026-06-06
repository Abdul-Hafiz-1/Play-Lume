import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/navigation.dart';

class ChameleonScreen extends StatefulWidget {
  final List<String> players;
  const ChameleonScreen({super.key, required this.players});

  @override
  State<ChameleonScreen> createState() => _ChameleonScreenState();
}

class _ChameleonScreenState extends State<ChameleonScreen> {
  static const Color _base = Color(0xFF04060E);
  static const Color _surface = Color(0xFF0E1329);
  static const Color _surfaceAlt = Color(0xFF151C36);
  static const Color _ink = Colors.white;
  static const Color _danger = Color(0xFFFF5C7A);
  static const Color _accent = Color(0xFF3B82F6);
  static const Color _accentTwo = Color(0xFF22D3EE);
  static const Color _gold = Color(0xFFFFB84D);

  String _gamePhase = 'setup';
  int _currentPlayerIndex = 0;
  bool _isRoleRevealed = false;

  String? _selectedCategory;
  late String _chameleonPlayer;
  late int _diceA;
  late int _diceB;
  late int _targetRow;
  late int _targetCol;
  late String _secretWord;
  String? _votedPlayer;
  String? _chameleonGuessWord;
  bool _chameleonGuessedRight = false;
  bool _isChameleonCaught = false;

  Timer? _timer;
  int _timeLeft = 120;

  final Map<String, List<String>> _categories = const {
    'Animals': [
      'Dog', 'Cat', 'Lion', 'Tiger',
      'Elephant', 'Monkey', 'Rabbit', 'Bear',
      'Dolphin', 'Shark', 'Frog', 'Duck',
      'Bird', 'Horse', 'Cow', 'Sheep',
    ],
    'Food': [
      'Pizza', 'Burger', 'Pasta', 'Cake',
      'Ice Cream', 'Cookie', 'Apple', 'Banana',
      'Strawberry', 'Fries', 'Taco', 'Bread',
      'Cheese', 'Egg', 'Candy', 'Donut',
    ],
    'School': [
      'Pen', 'Pencil', 'Book', 'Ruler',
      'Eraser', 'Desk', 'Chair', 'Paper',
      'Bag', 'Board', 'Clock', 'Computer',
      'Teacher', 'Student', 'School', 'Glue',
    ],
    'Colors & Shapes': [
      'Red', 'Blue', 'Green', 'Yellow',
      'Orange', 'Purple', 'Pink', 'Brown',
      'Circle', 'Square', 'Triangle', 'Star',
      'Heart', 'Rectangle', 'Diamond', 'Oval',
    ],
    'Outer Space': [
      'Sun', 'Moon', 'Earth', 'Mars',
      'Star', 'Rocket', 'Alien', 'Spaceship',
      'Planet', 'Orbit', 'Comet', 'Galaxy',
      'Astronaut', 'Jupiter', 'Saturn', 'Telescope',
    ],
    'Under the Sea': [
      'Fish', 'Crab', 'Octopus', 'Starfish',
      'Whale', 'Shark', 'Seahorse', 'Turtle',
      'Coral', 'Shell', 'Submarine', 'Seaweed',
      'Jellyfish', 'Lobster', 'Diver', 'Sand',
    ],
  };

  late List<List<String>> _decoderMatrix;

  @override
  void initState() {
    super.initState();
    _initializeDecoderMatrix();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _initializeDecoderMatrix() {
    final coords = <String>[];
    for (int row = 1; row <= 4; row++) {
      for (final col in ['A', 'B', 'C', 'D']) {
        coords.add('$col$row');
      }
    }
    coords.shuffle();
    _decoderMatrix = List.generate(
      4,
      (row) => List.generate(4, (col) => coords[row * 4 + col]),
    );
  }

  void _setupGame(String categoryName) {
    if (widget.players.length < 3) return;

    final random = Random();
    _initializeDecoderMatrix();
    _selectedCategory = categoryName;
    _chameleonPlayer = widget.players[random.nextInt(widget.players.length)];
    _diceA = random.nextInt(6) + 1;
    _diceB = random.nextInt(6) + 1;
    _targetRow = (_diceA - 1) % 4;
    _targetCol = (_diceB - 1) % 4;

    final coord = _decoderMatrix[_targetRow][_targetCol];
    final colIndex = ['A', 'B', 'C', 'D'].indexOf(coord[0]);
    final rowIndex = int.parse(coord[1]) - 1;
    _secretWord = _categories[categoryName]![rowIndex * 4 + colIndex];

    setState(() {
      _gamePhase = 'reveal';
      _currentPlayerIndex = 0;
      _isRoleRevealed = false;
      _votedPlayer = null;
      _chameleonGuessWord = null;
      _chameleonGuessedRight = false;
      _isChameleonCaught = false;
      _timeLeft = 120;
    });
  }

  void _startTimer() {
    _timer?.cancel();
    _timeLeft = 120;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() => _timeLeft--);
      } else {
        timer.cancel();
        HapticFeedback.vibrate();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _base,
      appBar: AppBar(
        title: const Text('The Chameleon'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading:
            _gamePhase == 'setup' || (_gamePhase == 'reveal' && _currentPlayerIndex == 0),
      ),
      body: Container(
        decoration: const BoxDecoration(color: _base),
        child: Stack(
          children: [
            Positioned(top: -150, left: -80, child: _glowOrb(360, _accent.withOpacity(0.14))),
            Positioned(bottom: -160, right: -90, child: _glowOrb(420, Colors.purpleAccent.withOpacity(0.1))),
            SafeArea(
              top: false,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 20),
                    child: _buildCurrentPhase(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentPhase() {
    if (widget.players.length < 3) {
      return _buildTooFewPlayers();
    }

    switch (_gamePhase) {
      case 'setup':
        return _buildSetupPhase();
      case 'reveal':
        return _buildRevealPhase();
      case 'discuss':
        return _buildDiscussPhase();
      case 'vote':
        return _buildVotePhase();
      case 'guess':
        return _buildGuessPhase();
      case 'result':
        return _buildResultPhase();
      default:
        return const Center(child: CircularProgressIndicator());
    }
  }

  Widget _buildTooFewPlayers() {
    return _tableCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.group_off_rounded, color: _danger, size: 64),
          const SizedBox(height: 14),
          const Text(
            'Need at least 3 players',
            style: TextStyle(color: _ink, fontSize: 26, fontWeight: FontWeight.w900),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          const Text(
            'The Chameleon works best when one player can hide inside a group.',
            style: TextStyle(color: Colors.white60, height: 1.4),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 22),
          _paperButton('Return Home', () => AppNavigation.goHome(context)),
        ],
      ),
    );
  }

  Widget _buildSetupPhase() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionTitle('Choose a Topic Card', 'Pick a deck, roll the dice, and pass the device around.'),
        const SizedBox(height: 14),
        Expanded(
          child: GridView.builder(
            physics: const BouncingScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 240,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 0.86,
            ),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final category = _categories.keys.elementAt(index);
              return _categoryCard(category);
            },
          ),
        ),
      ],
    );
  }

  Widget _categoryCard(String category) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        HapticFeedback.mediumImpact();
        _setupGame(category);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _surface.withOpacity(0.82),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _accent.withOpacity(0.35), width: 1.4),
          boxShadow: [BoxShadow(color: _accent.withOpacity(0.08), blurRadius: 28, offset: const Offset(0, 12))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [_accent.withOpacity(0.9), _accentTwo.withOpacity(0.65)]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                category.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _miniWordGrid(_categories[category]!),
            ),
            const SizedBox(height: 10),
            const Text(
              'DRAW THIS CARD',
              style: TextStyle(color: _accentTwo, fontWeight: FontWeight.w900, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevealPhase() {
    final currentPlayer = widget.players[_currentPlayerIndex];
    final isChameleon = currentPlayer == _chameleonPlayer;
    final coord = _decoderMatrix[_targetRow][_targetCol];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionTitle('Pass The Device', 'Only $currentPlayer should look at this card.'),
          const SizedBox(height: 18),
          if (!_isRoleRevealed)
            _tableCard(
              child: Column(
                children: [
                  const Icon(Icons.style_rounded, color: _accentTwo, size: 70),
                  const SizedBox(height: 16),
                  Text(
                    currentPlayer.toUpperCase(),
                    style: const TextStyle(color: _ink, fontSize: 34, fontWeight: FontWeight.w900),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Tap when this player is holding the device.',
                    style: TextStyle(color: Colors.white60),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  _paperButton('View My Card', () {
                    HapticFeedback.heavyImpact();
                    setState(() => _isRoleRevealed = true);
                  }),
                ],
              ),
            )
          else
            _roleCard(currentPlayer, isChameleon, coord),
        ],
      ),
    );
  }

  Widget _roleCard(String currentPlayer, bool isChameleon, String coord) {
    return _tableCard(
      accent: isChameleon ? _danger : _accentTwo,
      child: Column(
        children: [
          Text(
            isChameleon ? 'YOU ARE THE CHAMELEON' : 'CODE CARD',
            style: TextStyle(
              color: isChameleon ? _danger : _accentTwo,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          if (isChameleon) ...[
            const Icon(Icons.visibility_off_rounded, color: _danger, size: 76),
            const SizedBox(height: 16),
            const Text(
              'You do not know the secret word. Listen carefully, give one clue, and blend in.',
              style: TextStyle(color: Colors.white70, height: 1.45, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ] else ...[
            _diceTray(),
            const SizedBox(height: 14),
            _decoderCard(coord),
            const SizedBox(height: 16),
            const Text('Secret Word', style: TextStyle(color: Colors.white38, fontWeight: FontWeight.bold)),
            Text(
              _secretWord,
              style: const TextStyle(color: _ink, fontSize: 34, fontWeight: FontWeight.w900),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 24),
          _paperButton('Hide Card And Pass', () {
            HapticFeedback.mediumImpact();
            setState(() {
              _isRoleRevealed = false;
              if (_currentPlayerIndex < widget.players.length - 1) {
                _currentPlayerIndex++;
              } else {
                _gamePhase = 'discuss';
                _startTimer();
              }
            });
          }),
        ],
      ),
    );
  }

  Widget _buildDiscussPhase() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionTitle('One-Word Clues', 'Go around the table. Everyone says one clue.'),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _diceTray()),
              const SizedBox(width: 12),
              _timerBadge(),
            ],
          ),
          const SizedBox(height: 14),
          _topicCard(interactive: false),
          const SizedBox(height: 14),
          _paperButton('Accuse The Chameleon', () {
            _timer?.cancel();
            HapticFeedback.mediumImpact();
            setState(() => _gamePhase = 'vote');
          }),
          const SizedBox(height: 10),
          _outlineButton('I Am The Chameleon - Reveal And Guess', () {
            _timer?.cancel();
            HapticFeedback.heavyImpact();
            setState(() {
              _isChameleonCaught = true;
              _gamePhase = 'guess';
            });
          }),
        ],
      ),
    );
  }

  Widget _buildVotePhase() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionTitle('Vote Token', 'Choose who the group is accusing.'),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: widget.players.map((player) {
              final selected = _votedPlayer == player;
              return ChoiceChip(
                selected: selected,
                label: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Text(player),
                ),
                selectedColor: _accent,
                backgroundColor: _surfaceAlt,
                labelStyle: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
                side: BorderSide(color: selected ? _accentTwo : Colors.white24, width: 1.5),
                onSelected: (_) => setState(() => _votedPlayer = player),
              );
            }).toList(),
          ),
          const SizedBox(height: 22),
          _paperButton(
            'Lock Accusation',
            _votedPlayer == null
                ? null
                : () {
                    HapticFeedback.heavyImpact();
                    _isChameleonCaught = _votedPlayer == _chameleonPlayer;
                    setState(() {
                      if (_isChameleonCaught) {
                        _gamePhase = 'guess';
                      } else {
                        _chameleonGuessedRight = false;
                        _gamePhase = 'result';
                      }
                    });
                  },
          ),
        ],
      ),
    );
  }

  Widget _buildGuessPhase() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionTitle('Final Guess', 'The Chameleon can still win by naming the secret word.'),
          const SizedBox(height: 14),
          _topicCard(
            interactive: true,
            onTap: (word) => setState(() => _chameleonGuessWord = word),
          ),
          const SizedBox(height: 14),
          _paperButton(
            'Submit Final Guess',
            _chameleonGuessWord == null
                ? null
                : () {
                    HapticFeedback.heavyImpact();
                    _chameleonGuessedRight = _chameleonGuessWord == _secretWord;
                    setState(() => _gamePhase = 'result');
                  },
          ),
        ],
      ),
    );
  }

  Widget _buildResultPhase() {
    final chameleonWins = !_isChameleonCaught || _chameleonGuessedRight;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _tableCard(
            accent: chameleonWins ? _danger : _accentTwo,
            child: Column(
              children: [
                Icon(
                  chameleonWins ? Icons.visibility_off_rounded : Icons.task_alt_rounded,
                  color: chameleonWins ? _danger : _accentTwo,
                  size: 76,
                ),
                const SizedBox(height: 12),
                Text(
                  chameleonWins ? 'Chameleon Wins' : 'Players Win',
                  style: TextStyle(
                    color: chameleonWins ? _danger : _accentTwo,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                _resultLine('Chameleon', _chameleonPlayer),
                _resultLine('Secret Word', _secretWord),
                if (_chameleonGuessWord != null)
                  _resultLine('Final Guess', _chameleonGuessWord!),
                const SizedBox(height: 12),
                Text(
                  chameleonWins
                      ? (_isChameleonCaught
                          ? 'They were caught, but guessed the word correctly.'
                          : 'The group accused the wrong player.')
                      : 'The group found the Chameleon and protected the secret word.',
                  style: TextStyle(color: Colors.white70, height: 1.4),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _paperButton('Play Again', () {
            HapticFeedback.mediumImpact();
            setState(() {
              _gamePhase = 'setup';
              _selectedCategory = null;
            });
          }),
          const SizedBox(height: 10),
          _outlineButton('Return Home', () => AppNavigation.goHome(context)),
        ],
      ),
    );
  }

  Widget _topicCard({required bool interactive, ValueChanged<String>? onTap}) {
    final words = _categories[_selectedCategory!]!;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface.withOpacity(0.88),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _accent.withOpacity(0.38), width: 1.5),
        boxShadow: [
          BoxShadow(color: _accent.withOpacity(0.12), blurRadius: 30, offset: const Offset(0, 12)),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [_accent.withOpacity(0.9), _accentTwo.withOpacity(0.65)]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              _selectedCategory!.toUpperCase(),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.18,
            ),
            itemCount: 16,
            itemBuilder: (context, index) {
              final row = index ~/ 4;
              final col = index % 4;
              final coord = '${['A', 'B', 'C', 'D'][col]}${row + 1}';
              final word = words[index];
              final selected = _chameleonGuessWord == word;

              return InkWell(
                borderRadius: BorderRadius.circular(9),
                onTap: interactive ? () => onTap?.call(word) : null,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: selected ? _accent.withOpacity(0.22) : _surfaceAlt.withOpacity(0.86),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: selected ? _accentTwo : Colors.white.withOpacity(0.1), width: 1.4),
                  ),
                  child: Stack(
                    children: [
                      Text(
                        coord,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.28),
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Center(
                        child: Text(
                          word,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _decoderCard(String targetCoord) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _surfaceAlt.withOpacity(0.82),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _accent.withOpacity(0.28), width: 1.4),
      ),
      child: Column(
        children: [
          const Text(
            'CODE GRID',
            style: TextStyle(color: _accentTwo, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              childAspectRatio: 1.35,
            ),
            itemCount: 16,
            itemBuilder: (context, index) {
              final row = index ~/ 4;
              final col = index % 4;
              final coord = _decoderMatrix[row][col];
              final selected = coord == targetCoord;
              return Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? _accent.withOpacity(0.4) : _surface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: selected ? _accentTwo : Colors.white.withOpacity(0.1)),
                ),
                child: Text(
                  coord,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _diceTray() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _accent.withOpacity(0.24)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _die(_diceA, _accentTwo),
          const SizedBox(width: 12),
          _die(_diceB, _accent),
        ],
      ),
    );
  }

  Widget _die(int value, Color color) {
    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _surfaceAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color, width: 4),
        boxShadow: [BoxShadow(color: color.withOpacity(0.18), blurRadius: 18, offset: const Offset(0, 5))],
      ),
      child: Text(
        '$value',
        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
      ),
    );
  }

  Widget _timerBadge() {
    final text = _timeLeft == 0
        ? 'TIME'
        : '${_timeLeft ~/ 60}:${(_timeLeft % 60).toString().padLeft(2, '0')}';
    return Container(
      width: 92,
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        color: _timeLeft == 0 ? _danger.withOpacity(0.18) : _surfaceAlt.withOpacity(0.9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _timeLeft == 0 ? _danger : _accent.withOpacity(0.35), width: 1.5),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: _timeLeft == 0 ? _danger : Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 18,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _miniWordGrid(List<String> words) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 3,
        crossAxisSpacing: 3,
        childAspectRatio: 1,
      ),
      itemCount: 16,
      itemBuilder: (context, index) => Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _surfaceAlt.withOpacity(0.8),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          words[index],
          style: const TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _tableCard({required Widget child, Color accent = _gold}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _surface.withOpacity(0.68),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withOpacity(0.45), width: 1.5),
        boxShadow: [
          BoxShadow(color: accent.withOpacity(0.12), blurRadius: 28, offset: const Offset(0, 14)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: child,
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          style: TextStyle(color: Colors.white.withOpacity(0.7), height: 1.35),
        ),
      ],
    );
  }

  Widget _paperButton(String label, VoidCallback? onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: _accent,
        disabledBackgroundColor: Colors.black26,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 8,
        shadowColor: _accent.withOpacity(0.4),
      ),
      child: Text(label.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900)),
    );
  }

  Widget _outlineButton(String label, VoidCallback onTap) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 54),
        side: BorderSide(color: Colors.white.withOpacity(0.45), width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(label.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900)),
    );
  }

  Widget _resultLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: Colors.white38, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
              textAlign: TextAlign.right,
            ),
          ),
        ],
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
