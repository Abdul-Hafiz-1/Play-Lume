import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ChameleonScreen extends StatefulWidget {
  final List<String> players;
  const ChameleonScreen({super.key, required this.players});

  @override
  State<ChameleonScreen> createState() => _ChameleonScreenState();
}

class _ChameleonScreenState extends State<ChameleonScreen> {
  // Game Phases: 'setup', 'reveal', 'discuss', 'vote', 'guess', 'result'
  String _gamePhase = 'setup';
  int _currentPlayerIndex = 0;
  bool _isRoleRevealed = false;
  
  // Game Setup Variables
  String? _selectedCategory;
  late String _chameleonPlayer;
  late int _diceA; // 1-6
  late int _diceB; // 1-6
  late int _targetRow; // 0-3
  late int _targetCol; // 0-3
  late String _secretWord;
  String? _votedPlayer;
  String? _chameleonGuessWord;
  bool _chameleonGuessedRight = false;
  bool _isChameleonCaught = false;

  // Timer for discussion
  Timer? _timer;
  int _timeLeft = 120; // 2 minutes standard

  // Categories and kid-friendly words
  final Map<String, List<String>> _categories = {
    "Animals 🦁": [
      "Dog", "Cat", "Lion", "Tiger",
      "Elephant", "Monkey", "Rabbit", "Bear",
      "Dolphin", "Shark", "Frog", "Duck",
      "Bird", "Horse", "Cow", "Sheep"
    ],
    "Food 🍕": [
      "Pizza", "Burger", "Pasta", "Cake",
      "Ice Cream", "Cookie", "Apple", "Banana",
      "Strawberry", "Fries", "Taco", "Bread",
      "Cheese", "Egg", "Candy", "Donut"
    ],
    "School 🎒": [
      "Pen", "Pencil", "Book", "Ruler",
      "Eraser", "Desk", "Chair", "Paper",
      "Bag", "Board", "Clock", "Computer",
      "Teacher", "Student", "School", "Glue"
    ],
    "Colors & Shapes 🎨": [
      "Red", "Blue", "Green", "Yellow",
      "Orange", "Purple", "Pink", "Brown",
      "Circle", "Square", "Triangle", "Star",
      "Heart", "Rectangle", "Diamond", "Oval"
    ],
    "Outer Space 🚀": [
      "Sun", "Moon", "Earth", "Mars",
      "Star", "Rocket", "Alien", "Spaceship",
      "Planet", "Orbit", "Comet", "Galaxy",
      "Astronaut", "Jupiter", "Saturn", "Telescope"
    ],
    "Under the Sea 🌊": [
      "Fish", "Crab", "Octopus", "Starfish",
      "Whale", "Shark", "Seahorse", "Turtle",
      "Coral", "Shell", "Submarine", "Seaweed",
      "Jellyfish", "Lobster", "Diver", "Sand"
    ]
  };

  // Randomized Decoder Matrix generated for the round (maps outcomes to coordinates)
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
    final List<String> coords = [];
    for (int r = 1; r <= 4; r++) {
      for (final char in ['A', 'B', 'C', 'D']) {
        coords.add("$char$r");
      }
    }
    coords.shuffle();
    
    // Create a 4x4 matrix from shuffled coordinates
    _decoderMatrix = List.generate(4, (r) {
      return List.generate(4, (c) {
        return coords[r * 4 + c];
      });
    });
  }

  void _setupGame(String categoryName) {
    final random = Random();
    _selectedCategory = categoryName;
    _chameleonPlayer = widget.players[random.nextInt(widget.players.length)];
    
    // Roll virtual dice
    _diceA = random.nextInt(6) + 1;
    _diceB = random.nextInt(6) + 1;
    
    // Choose secret target B2 etc from the dice outcome
    _targetRow = (_diceA - 1) % 4;
    _targetCol = (_diceB - 1) % 4;
    
    // Get target coordinate e.g. "B2"
    final coordStr = _decoderMatrix[_targetRow][_targetCol];
    final colChar = coordStr[0];
    final rowNum = int.parse(coordStr[1]);

    final colIndex = ['A', 'B', 'C', 'D'].indexOf(colChar);
    final rowIndex = rowNum - 1;
    
    _secretWord = _categories[categoryName]![rowIndex * 4 + colIndex];
    
    setState(() {
      _gamePhase = 'reveal';
      _currentPlayerIndex = 0;
      _isRoleRevealed = false;
      _votedPlayer = null;
      _chameleonGuessWord = null;
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
        _timer?.cancel();
        HapticFeedback.vibrate();
        // Informative time-up: does not auto-transition to keep control manual in offline play!
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF04060E),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("The Chameleon", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        automaticallyImplyLeading: _gamePhase == 'setup' || (_gamePhase == 'reveal' && _currentPlayerIndex == 0),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.8, -0.6),
            radius: 1.2,
            colors: [Color(0xFF162252), Color(0xFF04060E)],
            stops: [0.0, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            // Centered layout limits width on Web for a clean console/arcade view
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 650),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                child: _buildCurrentPhase(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentPhase() {
    switch (_gamePhase) {
      case 'setup': return _buildSetupPhase();
      case 'reveal': return _buildRevealPhase();
      case 'discuss': return _buildDiscussPhase();
      case 'vote': return _buildVotePhase();
      case 'guess': return _buildChameleonGuessPhase();
      case 'result': return _buildResultPhase();
      default: return const Center(child: CircularProgressIndicator());
    }
  }

  // --- PHASE 1: CATEGORY SELECTION ---
  Widget _buildSetupPhase() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          "CHOOSE A CATEGORY",
          style: TextStyle(color: Color(0xFF8E95A3), fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView(
            physics: const BouncingScrollPhysics(),
            shrinkWrap: true,
            children: _categories.keys.map((catName) {
              return Card(
                color: const Color(0xFF0E1329),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: Color(0xFF1F2947), width: 1.5),
                ),
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    _setupGame(catName);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          catName,
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, color: Colors.blueAccent, size: 16),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // --- PHASE 2: ROLE REVEAL ---
  Widget _buildRevealPhase() {
    String currentPlayer = widget.players[_currentPlayerIndex];
    bool isChameleon = currentPlayer == _chameleonPlayer;
    String coordStr = _decoderMatrix[_targetRow][_targetCol];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          const Icon(Icons.fingerprint_rounded, color: Colors.blueAccent, size: 80),
          const SizedBox(height: 20),
          const Text(
            "SECURITY CLEARANCE REQUIRED",
            style: TextStyle(color: Color(0xFF8E95A3), letterSpacing: 3, fontWeight: FontWeight.bold, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            currentPlayer.toUpperCase(),
            style: const TextStyle(fontSize: 36, color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          const Text(
            "Pass the device to this player. Only they should view the decrypted transmission.",
            style: TextStyle(color: Colors.white38, fontSize: 13, height: 1.4),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),

          if (!_isRoleRevealed)
            ElevatedButton(
              onPressed: () {
                HapticFeedback.heavyImpact();
                setState(() => _isRoleRevealed = true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                minimumSize: const Size(double.infinity, 70),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text("DECRYPT MY ROLE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            )
          else ...[
            // Revealed card details
            ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: const Color(0xFF0E1329),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: isChameleon ? Colors.redAccent : Colors.blueAccent,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isChameleon ? Colors.redAccent : Colors.blueAccent).withOpacity(0.2),
                      blurRadius: 30,
                    )
                  ],
                ),
                child: Column(
                  children: [
                    if (isChameleon) ...[
                      const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 50),
                      const SizedBox(height: 20),
                      const Text(
                        "YOU ARE THE CHAMELEON",
                        style: TextStyle(color: Colors.redAccent, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 1),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "You do not know the secret word. Keep your eyes on other players, listen to their clues, and blend in perfectly to escape detection!",
                        style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
                        textAlign: TextAlign.center,
                      ),
                    ] else ...[
                      const Icon(Icons.lock_open_rounded, color: Colors.blueAccent, size: 50),
                      const SizedBox(height: 20),
                      const Text(
                        "ROLE: DETECTIVE",
                        style: TextStyle(color: Colors.blueAccent, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        "Secret Word is:\n'$_secretWord'",
                        style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Grid Coordinate: $coordStr",
                        style: const TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 18),
                      const Divider(color: Colors.white10),
                      const SizedBox(height: 10),
                      // Rolling dice visual
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildDie(_diceA),
                          const SizedBox(width: 14),
                          _buildDie(_diceB),
                        ],
                      ),
                    ]
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
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
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1F2947),
                minimumSize: const Size(double.infinity, 64),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text("I AM READY", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDie(int val) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white24),
      ),
      child: Center(
        child: Text(
          "$val",
          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // --- PHASE 3: THE WORD GRID & CLUES DISCUSSION ---
  Widget _buildDiscussPhase() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedCategory!.toUpperCase(),
                    style: const TextStyle(color: Colors.blueAccent, fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.bold),
                  ),
                  const Text("PUBLIC DECRYPTION GRID", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              // Timer Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: _timeLeft == 0 
                      ? Colors.redAccent.withOpacity(0.15) 
                      : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: _timeLeft == 0 ? Colors.redAccent : Colors.white12,
                  ),
                ),
                child: Text(
                  _timeLeft == 0 
                      ? "TIME'S UP" 
                      : "${_timeLeft ~/ 60}:${(_timeLeft % 60).toString().padLeft(2, '0')}",
                  style: TextStyle(
                    color: _timeLeft == 0 ? Colors.redAccent : Colors.white, 
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              )
            ],
          ),
          const SizedBox(height: 16),
          
          // 4x4 public word matrix grid
          _build4x4WordGrid(false, null),
          
          const SizedBox(height: 16),
          const Text(
            "Take turns physically stating exactly ONE word describing the secret item. The Chameleon must fake a clue to blend in!",
            style: TextStyle(color: Colors.white38, fontSize: 12, height: 1.4),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // CONFESS BUTTON: The Chameleon can confessionally step up, reveal themselves, and guess to win!
          ElevatedButton(
            onPressed: () {
              _timer?.cancel();
              HapticFeedback.heavyImpact();
              setState(() {
                _isChameleonCaught = true;
                _gamePhase = 'guess';
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
              minimumSize: const Size(double.infinity, 54),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text("I AM THE CHAMELEON (CONFESS & GUESS)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5)),
          ),
          const SizedBox(height: 12),

          ElevatedButton(
            onPressed: () {
              _timer?.cancel();
              HapticFeedback.mediumImpact();
              setState(() => _gamePhase = 'vote');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              minimumSize: const Size(double.infinity, 60),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text("PROCEED TO SUSPECT VOTE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _build4x4WordGrid(bool interactive, Function(int, int)? onTap) {
    final List<String> words = _categories[_selectedCategory!]!;
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.0,
      ),
      itemCount: 16,
      itemBuilder: (context, index) {
        int r = index ~/ 4;
        int c = index % 4;
        
        String colChar = ['A', 'B', 'C', 'D'][c];
        String rowNumStr = "${r + 1}";
        String coordStr = "$colChar$rowNumStr";
        
        String word = words[index];
        bool isSelectedInGuess = _chameleonGuessWord == word;
        
        return Card(
          color: isSelectedInGuess ? Colors.amber.withOpacity(0.3) : const Color(0xFF0E1329),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: BorderSide(
              color: isSelectedInGuess 
                  ? Colors.amber 
                  : const Color(0xFF1F2947),
              width: 1.5,
            ),
          ),
          margin: EdgeInsets.zero,
          child: InkWell(
            onTap: interactive ? () => onTap?.call(r, c) : null,
            borderRadius: BorderRadius.circular(15),
            child: Stack(
              children: [
                Positioned(
                  top: 6, left: 8,
                  child: Text(
                    coordStr,
                    style: const TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Text(
                      word,
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  // --- PHASE 4: VOTE FOR THE CHAMELEON ---
  Widget _buildVotePhase() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            "ACCUSE SUSPECT",
            style: TextStyle(color: Colors.blueAccent, fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          const Text(
            "Discuss and vote together: Who is the Chameleon?",
            style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.players.length,
            itemBuilder: (context, index) {
              String p = widget.players[index];
              bool isSelected = _votedPlayer == p;
              
              return Card(
                color: isSelected ? const Color(0xFF3B82F6).withOpacity(0.2) : const Color(0xFF0E1329),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected ? Colors.blueAccent : const Color(0xFF1F2947),
                    width: 1.5,
                  ),
                ),
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  title: Text(p, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  trailing: isSelected ? const Icon(Icons.how_to_vote, color: Colors.blueAccent) : null,
                  onTap: () => setState(() => _votedPlayer = p),
                ),
              );
            },
          ),
          
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _votedPlayer == null ? null : () {
              HapticFeedback.heavyImpact();
              // Check if Chameleon was successfully identified
              _isChameleonCaught = _votedPlayer == _chameleonPlayer;
              
              setState(() {
                if (_isChameleonCaught) {
                  // Chameleon gets a chance to guess!
                  _gamePhase = 'guess';
                } else {
                  // Chameleon escaped and wins!
                  _chameleonGuessedRight = false;
                  _gamePhase = 'result';
                }
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              minimumSize: const Size(double.infinity, 60),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text("CONFIRM ELIMINATION VOTE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // --- PHASE 5: CHAMELEON GUESS CLIMAX ---
  Widget _buildChameleonGuessPhase() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),
          const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 60),
          const SizedBox(height: 10),
          const Text(
            "CHAMELEON'S RETALIATION",
            style: TextStyle(color: Colors.amber, fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            "Operatives identified $_chameleonPlayer!\nHowever, the Chameleon can still WIN by guessing the secret word from the grid.",
            style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          
          _build4x4WordGrid(true, (r, c) {
            final List<String> words = _categories[_selectedCategory!]!;
            setState(() {
              _chameleonGuessWord = words[r * 4 + c];
            });
          }),
          
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _chameleonGuessWord == null ? null : () {
              HapticFeedback.heavyImpact();
              _chameleonGuessedRight = _chameleonGuessWord == _secretWord;
              setState(() => _gamePhase = 'result');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
              minimumSize: const Size(double.infinity, 60),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text("SUBMIT FINAL GUESS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // --- PHASE 6: FINAL GAME RESULTS ---
  Widget _buildResultPhase() {
    bool chameleonWins = !_isChameleonCaught || _chameleonGuessedRight;
    
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),
          Icon(
            chameleonWins ? Icons.warning_amber_rounded : Icons.task_alt_rounded,
            size: 90,
            color: chameleonWins ? Colors.amber : const Color(0xFF00FF88),
          ),
          const SizedBox(height: 20),
          Text(
            chameleonWins ? "Chameleon Wins!" : "Operatives Win!",
            style: TextStyle(
              color: chameleonWins ? Colors.amber : const Color(0xFF00FF88),
              fontSize: 36,
              fontWeight: FontWeight.w900,
              letterSpacing: 1
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            chameleonWins 
                ? (_isChameleonCaught 
                    ? "Chameleon was caught, but correctly guessed the secret word!" 
                    : "Chameleon completely escaped and fooled the operatives!")
                : "Operatives caught the Chameleon, and the Chameleon failed to guess the secret word!",
            style: const TextStyle(color: Colors.white60, fontSize: 14, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF0E1329),
                border: Border.all(color: const Color(0xFF1F2947)),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  const Text("Chameleon Identity:", style: TextStyle(color: Color(0xFF8E95A3))),
                  Text(_chameleonPlayer, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 18),
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 10),
                  const Text("Secret Word:", style: TextStyle(color: Color(0xFF8E95A3))),
                  Text(_secretWord, style: const TextStyle(color: Colors.blueAccent, fontSize: 26, fontWeight: FontWeight.w900)),
                  if (_chameleonGuessWord != null) ...[
                    const SizedBox(height: 18),
                    const Text("Chameleon Guess:", style: TextStyle(color: Color(0xFF8E95A3))),
                    Text(
                      _chameleonGuessWord!,
                      style: TextStyle(
                        color: _chameleonGuessedRight ? const Color(0xFF00FF88) : Colors.redAccent,
                        fontSize: 22,
                        fontWeight: FontWeight.bold
                      ),
                    ),
                  ]
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              setState(() {
                _gamePhase = 'setup';
                _selectedCategory = null;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              minimumSize: const Size(double.infinity, 60),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text("PLAY AGAIN", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.popUntil(context, ModalRoute.withName('/home')),
            child: const Text("Return to Home", style: TextStyle(color: Color(0xFF8E95A3))),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
