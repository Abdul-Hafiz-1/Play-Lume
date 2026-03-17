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
    "A Roomba (Robot Vacuum)",
  "A Venus Flytrap",
  "A Sizzling Fajita Plate",
  "A Polaroid Camera",
  "An Electric Eel",
  "A Lava Lamp",
  "A Rickshaw (Auto)",
  "A Durian Fruit",
  "A Time Capsule",
  "A Weighted Blanket",
  "A Popcorn Machine",
  "A VR Headset",
  "A Pufferfish",
  "A Hot Air Balloon",
  "A Leaky Faucet",
  "A Magic Lamp",
  "A Rubik's Cube",
  "A Solar Panel",
  "A Squeaky Floorboard",
  "A Bermuda Triangle",
  "A Trojan Horse",
  "A Crystal Ball",
  "A Stick of Cotton Candy",
  "An Origami Crane",
  "A Sourdough Starter",
  "A Pothole",
  "A Trampoline",
  "A Cuckoo Clock",
  "A Wind Chime",
  "A Hammerhead Shark",
  "A Megaphone",
  "A Firefly",
  "A Cactus",
  "A Sloth",
  "A Venus de Milo",
  "A Sarcophagus",
  "A Newton's Cradle",
  "A Kaleidoscope",
  "A Hoverboard",
  "A Mechanical Pencil",
  "A Fidget Spinner",
  "A Walkie-Talkie",
  "A Metal Detector",
  "A Smoke Machine",
  "A Disco Ball",
  "A Jack-in-the-Box",
  "A Pogo Stick",
  "A Gumball Machine",
  "A Harmonica",
  "A Swiss Army Knife",
  "A Sandcastle",
  "A Giant Sequoia Tree",
  "A Glacier",
  "A Coral Reef",
  "A Black Hole",
  "A Satellite Dish",
  "A Morse Code Key",
  "A Typewriter",
  "A Sundial",
  "A Hourglass",
  "A Compass",
  "A Weather Vane",
  "A Lightning Rod",
  "A Tesla Coil",
  "A Microscope",
  "A Stethoscope",
  "A Geiger Counter",
  "A 3D Printer",
  "A Drone",
  "A Spaceship Console",
  "A Submarine Periscope",
  "A Vault Door",
  "A Guillotine (Paper Cutter)",
  "A Mechanical Bull",
  "A Water Fountain",
  "A Treadmill",
  "A Pinball Machine",
  "A Claw Machine",
  "A Jukebox",
  "A Grand Piano",
  "A Bagpipe",
  "A Didgeridoo",
  "A Boombox",
  "A Record Player",
  "A Megaphone",
  "A Flare Gun",
  "A Smoke Signal",
  "A carrier Pigeon",
  "A Message in a Bottle",
  "A Scarecrow",
  "A Totem Pole",
  "A Gargoyle",
  "A Moai Statue (Easter Island)",
  "A Great Wall",
  "A Drawbridge",
  "A Portcullis",
  "A Guillotine",
  "A Guillotine (Paper Cutter)",
  "A Swiss Army Knife",
  "A Pocket Watch",
  "A Fountain Pen",
  "A Wax Seal",
  "A Quill",
  "A Parchment Scroll",
  "A Rosetta Stone",
  "A Fossil",
  "A Meteorite",
  "A Moon Rock"
  ];

  final List<String> _tells = [
    "You must cough slightly every time someone says the word 'Liar'.",
  "You must check your watch (or wrist) at least three times in one minute.",
  "You must slowly rotate your phone on the table until it's perfectly straight.",
  "You must lean back and put both hands behind your head for ten seconds.",
  "You must yawn, but try to hide it poorly with your hand.",
  "You must nod aggressively while someone is giving a really bad explanation.",
  "You must wipe your phone screen on your shirt very intensely.",
  "You must squint at one player like you can't see them clearly.",
  "You must fix your hair using the phone screen as a mirror.",
  "You must tap a rhythm on the table with your fingers until someone looks at you.",
  "You must take a very long, loud sip of your drink.",
  "You must suddenly sit up very straight as if you just remembered something.",
  "You must point at someone else's shoes and then quickly look away.",
  "You must pick up an object near you and inspect it like it's a museum artifact.",
  "You must clear your throat loudly before you start speaking.",

  // --- VERBAL GLITCHES ---
  "You must end one of your sentences by saying '...allegedly'.",
  "You must repeat the last three words of whatever the person before you said.",
  "You must start your explanation with 'To be perfectly honest with you...'",
  "You must use a person's full name (e.g., 'Okay, Salman...') instead of just a nickname.",
  "You must say 'Interesting...' after every time the Informant speaks.",
  "You must answer a question by saying 'That is a very technical question.'",
  "You must try to fit the word 'Pineapple' into a sentence without it sounding weird.",
  "You must whisper your answer first, then say it at normal volume.",
  "You must sigh deeply before answering any question.",
  "You must say 'Wait, what was the question again?' at least twice.",
  "You must laugh at a joke that wasn't actually funny.",
  "You must use a very fancy word that doesn't quite fit the conversation.",
  "You must start a sentence with 'Back in my day...' (even if you're a kid).",
  "You must say 'I read about this online' to justify one of your hints.",

  // --- SOCIAL CHAOS ---
  "You must high-five the person next to you for no reason.",
  "You must mirror the exact sitting posture of the person sitting opposite you.",
  "You must look at the door every time you hear a faint noise.",
  "You must clap your hands once and say 'Right then!' before you speak.",
  "You must give a 'thumbs up' to the Informant after they give a hint.",
  "You must whisper something to the person next to you that is totally irrelevant.",
  "You must act like you have a very itchy eyebrow for the whole round.",
  "You must try to get everyone to do a 'fist bump' at some point.",
  "You must pretend to forget the name of the game you are currently playing.",
  "You must look at someone's forehead instead of their eyes while talking to them.",
  "You must mention a specific Gulf city (Dubai/Riyadh/Jeddah) in a hint.",
  "You must complain about the 'Mangalore heat' regardless of where you actually are.",
  "You must ask someone else if they can smell something burning.",
  "You must stand up for 5 seconds to 'stretch' and then sit back down.",
  "You must hum a tiny bit of a song while you are 'thinking'.",
  "You must close one eye while listening to someone else's alibi.",

  // --- THE "SUSPICIOUS" SET ---
  "You must look at the ceiling and count to three out loud.",
  "You must touch both your ears at the exact same time.",
  "You must tuck your chin into your shirt for a second.",
  "You must pretend to have a sudden, silent sneeze.",
  "You must adjust your chair loudly.",
  "You must say 'That's exactly what a Liar would say' to the person on your left.",
  "You must blink very rapidly for five seconds.",
  "You must try to count how many buttons are on someone else's shirt.",
  "You must cover your mouth with both hands while someone else is talking.",
  "You must snap your fingers and say 'I knew it!'",
  "You must ask 'Is it my turn?' even when it clearly isn't.",
  "You must pretend to be out of breath for one sentence.",
  "You must use your hands to describe the size of something invisible.",
  "You must mention a 'friend of a friend' who told you a secret.",
  "You must finish your turn by saying 'Over and out.'"
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