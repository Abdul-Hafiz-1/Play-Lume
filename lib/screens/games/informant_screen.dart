import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';

class InformantScreen extends StatefulWidget {
  final List<String> players;

  const InformantScreen({super.key, required this.players});

  @override
  State<InformantScreen> createState() => _InformantScreenState();
}

class _InformantScreenState extends State<InformantScreen> {
  // Game State
  String _gamePhase = 'reveal'; // reveal, interrogation, vote, result
  int _currentPlayerIndex = 0;
  bool _isRoleRevealed = false;
  
  // Roles & Secrets
  late String _witness;
  late String _informant;
  late String _secretWord;
  late String _secretTell;
  String? _selectedPlayerToArrest;
  bool _wordWasGuessed = false;

  // Timer
  Timer? _timer;
  int _timeLeft = 180; // 3 minutes

  final List<String> _words = [
    "A Submarine", "The Pyramids of Giza", "A Black Hole", "A Wi-Fi Router",
    "A Boomerang", "Frankenstein's Monster", "A Vending Machine", "A Parachute",
    "A Telescope", "A Chameleon", "The Mona Lisa", "A Volcano",
    "A Metronome", "A Snowglobe", "A Magnet", "A Compass"
  ];

  final List<String> _tells = [
    "You must scratch your nose at least twice.",
    "You must stretch your arms over your head once.",
    "You must cross your arms while someone else is talking.",
    "You must start one of your sentences with 'Ummm...'",
    "You must tap your chin like you are thinking hard.",
    "You must adjust your shirt or collar.",
    "You must look up at the ceiling for a few seconds."
  ];

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _initializeGame() {
    if (widget.players.length < 4) {
      // Safety check, though the setup screen handles this
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("The Informant requires at least 4 players!")));
        Navigator.pop(context);
      });
      return;
    }

    final random = Random();
    
    // Assign Roles
    List<String> shuffledPlayers = List.from(widget.players)..shuffle(random);
    _witness = shuffledPlayers[0];
    _informant = shuffledPlayers[1];
    
    // Assign Secrets
    _secretWord = _words[random.nextInt(_words.length)];
    _secretTell = _tells[random.nextInt(_tells.length)];

    _gamePhase = 'reveal';
    _currentPlayerIndex = 0;
    _isRoleRevealed = false;
    _selectedPlayerToArrest = null;
    _wordWasGuessed = false;
    _timeLeft = 180;
  }

  void _nextPlayerOrPhase() {
    setState(() {
      _isRoleRevealed = false;
      if (_currentPlayerIndex < widget.players.length - 1) {
        _currentPlayerIndex++;
      } else {
        _gamePhase = 'interrogation';
        _startTimer();
      }
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_timeLeft > 0) {
          _timeLeft--;
        } else {
          _timer?.cancel();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF04060E),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('The Informant'),
        automaticallyImplyLeading: _gamePhase == 'reveal' && _currentPlayerIndex == 0,
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
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: _buildCurrentPhase(),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentPhase() {
    switch (_gamePhase) {
      case 'reveal': return _buildRevealPhase();
      case 'interrogation': return _buildInterrogationPhase();
      case 'vote': return _buildVotePhase();
      case 'result': return _buildResultPhase();
      default: return const Center(child: CircularProgressIndicator());
    }
  }

  Widget _buildRevealPhase() {
    String currentPlayer = widget.players[_currentPlayerIndex];
    
    String roleName = "Detective";
    String roleDescription = "You do not know the secret word. Ask the Witness questions to guess it. Watch out for the Informant trying to guide you!";
    Color roleColor = Colors.white;

    if (currentPlayer == _witness) {
      roleName = "The Witness";
      roleDescription = "The Secret Word is:\n\n'$_secretWord'\n\nYou can only answer 'Yes', 'No', or 'I don't know' to the Detectives' questions.";
      roleColor = const Color(0xFF3B82F6);
    } else if (currentPlayer == _informant) {
      roleName = "The Informant";
      roleDescription = "The Secret Word is:\n\n'$_secretWord'\n\nSubtly help the Detectives guess it. BUT you must do this secret action during the round:\n\n$_secretTell\n\nDon't get caught!";
      roleColor = Colors.redAccent;
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text("Pass the phone to", style: Theme.of(context).textTheme.titleMedium?.copyWith(color: const Color(0xFF8E95A3)), textAlign: TextAlign.center),
        const SizedBox(height: 10),
        Text(currentPlayer, style: Theme.of(context).textTheme.displaySmall?.copyWith(color: const Color(0xFF3B82F6), fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        const SizedBox(height: 40),

        if (!_isRoleRevealed) ...[
          const Icon(Icons.fingerprint, size: 80, color: Colors.white24),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () => setState(() => _isRoleRevealed = true),
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 60)),
            child: const Text('Reveal My Identity'),
          ),
        ] else ...[
          Card(
            color: const Color(0xFF0E1329),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(color: roleColor, width: 2),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 30.0, horizontal: 20.0),
              child: Column(
                children: [
                  Text(roleName, style: TextStyle(color: roleColor, fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  Text(roleDescription, style: const TextStyle(color: Colors.white, fontSize: 18, height: 1.5), textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: _nextPlayerOrPhase,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1F2947),
              minimumSize: const Size(double.infinity, 60),
            ),
            child: const Text('Hide Identity & Continue'),
          ),
        ]
      ],
    );
  }

  Widget _buildInterrogationPhase() {
    int minutes = _timeLeft ~/ 60;
    int seconds = _timeLeft % 60;
    String timeString = "$minutes:${seconds.toString().padLeft(2, '0')}";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text("Interrogation Phase", style: TextStyle(color: Color(0xFF8E95A3), fontSize: 18), textAlign: TextAlign.center),
        const SizedBox(height: 10),
        Text(timeString, style: TextStyle(color: _timeLeft <= 30 ? Colors.redAccent : const Color(0xFF00FF88), fontSize: 64, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        const SizedBox(height: 20),
        
        Card(
          color: const Color(0xFF0E1329),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFF1F2947))),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Text("$_witness is The Witness.", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                const SizedBox(height: 10),
                const Text("Detectives: Ask them Yes/No questions to figure out the secret word!", style: TextStyle(color: Color(0xFF8E95A3), height: 1.4), textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
        
        const Spacer(),
        
        if (_timeLeft > 0)
          ElevatedButton(
            onPressed: () {
              _timer?.cancel();
              setState(() {
                _wordWasGuessed = true;
                _gamePhase = 'vote';
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              minimumSize: const Size(double.infinity, 60),
            ),
            child: const Text('We Guessed The Word!'),
          )
        else
          ElevatedButton(
            onPressed: () {
              setState(() {
                _wordWasGuessed = false;
                _gamePhase = 'result';
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              minimumSize: const Size(double.infinity, 60),
            ),
            child: const Text('Time is Up!'),
          ),
      ],
    );
  }

  Widget _buildVotePhase() {
    List<String> suspects = widget.players.where((p) => p != _witness).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text("Who was The Informant?", style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
        const SizedBox(height: 10),
        const Text("The word was guessed! Now the Detectives must discuss and vote. Who was secretly guiding you?", style: TextStyle(color: Color(0xFF8E95A3), height: 1.4), textAlign: TextAlign.center),
        const SizedBox(height: 20),
        
        Expanded(
          child: ListView.builder(
            itemCount: suspects.length,
            itemBuilder: (context, index) {
              String player = suspects[index];
              bool isSelected = _selectedPlayerToArrest == player;

              return Card(
                color: isSelected ? Colors.redAccent.withOpacity(0.3) : const Color(0xFF0E1329),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: isSelected ? Colors.redAccent : const Color(0xFF1F2947), width: 1.5),
                ),
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  title: Text(player, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  trailing: isSelected ? const Icon(Icons.local_police, color: Colors.redAccent) : null,
                  onTap: () => setState(() => _selectedPlayerToArrest = player),
                ),
              );
            },
          ),
        ),
        
        ElevatedButton(
          onPressed: _selectedPlayerToArrest == null ? null : () {
            setState(() => _gamePhase = 'result');
          },
          style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 60), backgroundColor: Colors.redAccent),
          child: const Text('Arrest Suspect'),
        ),
      ],
    );
  }

  Widget _buildResultPhase() {
    bool informantCaught = _selectedPlayerToArrest == _informant;
    
    String titleText = "";
    Color titleColor = Colors.white;
    String subtitleText = "";

    if (!_wordWasGuessed) {
      titleText = "Detectives Failed!";
      titleColor = Colors.redAccent;
      subtitleText = "You ran out of time. The secret word was '$_secretWord'.";
    } else if (informantCaught) {
      titleText = "Informant Caught!";
      titleColor = const Color(0xFF00FF88);
      subtitleText = "The Detectives successfully guessed the word AND caught the Informant!";
    } else {
      titleText = "The Perfect Heist!";
      titleColor = Colors.redAccent;
      subtitleText = "The Detectives arrested $_selectedPlayerToArrest, an innocent civilian!\n\nThe Informant escapes!";
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          _wordWasGuessed && informantCaught ? Icons.task_alt : Icons.warning_amber_rounded, 
          size: 80, 
          color: titleColor
        ),
        const SizedBox(height: 20),
        Text(titleText, style: Theme.of(context).textTheme.displaySmall?.copyWith(color: titleColor), textAlign: TextAlign.center),
        const SizedBox(height: 20),
        
        Card(
          color: const Color(0xFF0E1329),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0xFF1F2947))),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Text(subtitleText, style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.4), textAlign: TextAlign.center),
                const Divider(color: Color(0xFF1F2947), height: 30),
                const Text("The Informant was:", style: TextStyle(color: Color(0xFF8E95A3))),
                const SizedBox(height: 8),
                Text(_informant, style: const TextStyle(color: Colors.redAccent, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                const Text("Their Secret Tell was:", style: TextStyle(color: Color(0xFF8E95A3))),
                const SizedBox(height: 8),
                Text(_secretTell, style: const TextStyle(color: Colors.white, fontSize: 16, fontStyle: FontStyle.italic), textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 40),
        ElevatedButton(
          onPressed: () => setState(() => _initializeGame()),
          style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 60)),
          child: const Text('Play Again'),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => Navigator.popUntil(context, ModalRoute.withName('/home')),
          child: const Text('Return to Home', style: TextStyle(color: Color(0xFF8E95A3))),
        )
      ],
    );
  }
}