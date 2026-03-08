import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';

class InterrogationScreen extends StatefulWidget {
  final List<String> players;
  const InterrogationScreen({super.key, required this.players});

  @override
  State<InterrogationScreen> createState() => _InterrogationScreenState();
}

class _InterrogationScreenState extends State<InterrogationScreen> {
  String _gamePhase = 'setup'; 
  late String _detective;
  late String _suspect;
  String? _sidekick; 
  
  List<String> _prepQueue = [];
  int _prepIndex = 0;

  late Map<String, dynamic> _currentCase;
  List<String> _secretWords = []; 
  List<String> _civilianWords = []; 
  List<String> _allWords = []; 
  List<String> _selectedWords = []; 
  String? _guessedSuspect;
  Timer? _timer;
  int _timeLeft = 180;

  final List<Map<String, dynamic>> _caseDatabase = [
  {
    "crime": "Someone hacked the city billboards to show cat videos.",
    "category": "Digital Heist",
    "pairs": [
      ["Laptop", "Desktop"], ["Password", "Passcode"], ["Server", "Database"], 
      ["Router", "Modem"], ["Encryption", "Coding"], ["Software", "Hardware"], 
      ["Monitor", "Screen"], ["Firewall", "Antivirus"], ["Algorithm", "Script"]
    ]
  },
  {
    "crime": "A thief stole the gold trophy from the sports club.",
    "category": "Athletic Theft",
    "pairs": [
      ["Soccer", "Rugby"], ["Tennis", "Badminton"], ["Medal", "Trophy"], 
      ["Coach", "Trainer"], ["Jersey", "Uniform"], ["Stadium", "Arena"], 
      ["Sprint", "Relay"], ["Helmet", "Goggles"], ["Whistle", "Timer"]
    ]
  },
  {
    "crime": "Someone swapped all the bakery's sugar with salt.",
    "category": "Bakery Blunder",
    "pairs": [
      ["Bread", "Pastry"], ["Oven", "Stove"], ["Flour", "Dough"], 
      ["Cookie", "Brownie"], ["Cake", "Cupcake"], ["Apron", "Hat"], 
      ["Kitchen", "Pantry"], ["Butter", "Cream"], ["Whisk", "Beater"]
    ]
  },
  {
    "crime": "A rogue scientist turned the local swimming pool into green jello.",
    "category": "Lab Leak",
    "pairs": [
      ["Microscope", "Telescope"], ["Beaker", "Flask"], ["Acid", "Base"],
      ["Atom", "Molecule"], ["Formula", "Equation"], ["Liquid", "Solid"],
      ["Robot", "Android"], ["Magnet", "Battery"], ["Gravity", "Inertia"]
    ]
  },
  {
    "crime": "A bandit replaced all the bank's cash with monopoly money.",
    "category": "Financial Fraud",
    "pairs": [
      ["Wallet", "Purse"], ["Credit", "Debit"], ["Vault", "Safe"],
      ["Dollar", "Coin"], ["Stock", "Bond"], ["Check", "Receipt"],
      ["ATM", "Teller"], ["Loan", "Debt"], ["Gold", "Silver"]
    ]
  },
  {
    "crime": "Someone painted the police station bright neon pink overnight.",
    "category": "Vandalism",
    "pairs": [
      ["Brush", "Roller"], ["Canvas", "Wall"], ["Spray", "Bucket"],
      ["Stencil", "Sketch"], ["Color", "Shade"], ["Ladder", "Scaffold"],
      ["Art", "Design"], ["Artist", "Painter"], ["Gloss", "Matte"]
    ]
  },
  {
    "crime": "A mystery person released 500 penguins into the local library.",
    "category": "Animal Chaos",
    "pairs": [
      ["Book", "Novel"], ["Shelf", "Rack"], ["Page", "Chapter"],
      ["Paper", "Scroll"], ["Zookeeper", "Guard"], ["Feather", "Fur"],
      ["Ice", "Snow"], ["Library", "Archive"], ["Ink", "Pen"]
    ]
  },
  {
    "crime": "Someone stole every single 'left' shoe in the neighborhood.",
    "category": "Bizarre Burglary",
    "pairs": [
      ["Sneaker", "Boot"], ["Sock", "Sandal"], ["Heel", "Sole"],
      ["Leather", "Fabric"], ["Closet", "Shelf"], ["Lace", "Strap"],
      ["Foot", "Toe"], ["Walker", "Runner"], ["Size", "Width"]
    ]
  },
  {
    "crime": "A prankster replaced the school's bells with duck quacks.",
    "category": "Campus Chaos",
    "pairs": [
      ["Class", "Lesson"], ["Teacher", "Professor"], ["Desk", "Table"],
      ["Pencil", "Crayon"], ["Recess", "Break"], ["Locker", "Cubby"],
      ["Grade", "Score"], ["Hallway", "Stairs"], ["Homework", "Project"]
    ]
  },
  {
    "crime": "Someone towed the town's statue to the middle of a lake.",
    "category": "Heavy Lifting",
    "pairs": [
      ["Truck", "Tractor"], ["Rope", "Chain"], ["Engine", "Motor"],
      ["Boat", "Raft"], ["Anchor", "Hook"], ["Driver", "Pilot"],
      ["Steel", "Iron"], ["Bridge", "Dock"], ["Wheels", "Tires"]
    ]
  },
  {
    "crime": "A bandit stole all the remote controls from every home.",
    "category": "Home Invasion",
    "pairs": [
      ["Television", "Cinema"], ["Sofa", "Couch"], ["Channel", "Station"],
      ["Volume", "Mute"], ["Battery", "Power"], ["Antenna", "Cable"],
      ["Living Room", "Lounge"], ["Movie", "Show"], ["Speaker", "Audio"]
    ]
  },
  {
    "crime": "Someone replaced the park's grass with green carpet.",
    "category": "Landscaping Lie",
    "pairs": [
      ["Flower", "Plant"], ["Tree", "Bush"], ["Garden", "Yard"],
      ["Dirt", "Soil"], ["Water", "Hose"], ["Mower", "Shears"],
      ["Park", "Forest"], ["Leaf", "Branch"], ["Nature", "Eco"]
    ]
  },
  {
    "crime": "A thief stole all the coffee beans from the city's cafes.",
    "category": "Caffeine Caper",
    "pairs": [
      ["Espresso", "Latte"], ["Sugar", "Syrup"], ["Cup", "Mug"],
      ["Barista", "Waiter"], ["Morning", "Night"], ["Filter", "Press"],
      ["Steam", "Foam"], ["Roast", "Blend"], ["Cafe", "Bistro"]
    ]
  },
  {
    "crime": "Someone filled the local fountain with bubble bath soap.",
    "category": "Sudsy Situation",
    "pairs": [
      ["Water", "Liquid"], ["Bubble", "Foam"], ["Scent", "Smell"],
      ["Clean", "Wash"], ["Soap", "Suds"], ["Towel", "Sponge"],
      ["Bath", "Shower"], ["Sink", "Tub"], ["Drain", "Pipe"]
    ]
  },
  {
    "crime": "A tech-thief stole all the smartphones during a wedding.",
    "category": "Celebration Sabotage",
    "pairs": [
      ["Photo", "Video"], ["Ring", "Jewel"], ["Dress", "Suit"],
      ["Music", "Dance"], ["Cake", "Desert"], ["Guest", "Host"],
      ["Camera", "Lens"], ["Flash", "Light"], ["Phone", "Mobile"]
    ]
  },
  {
    "crime": "Someone rewired the traffic lights to turn purple and orange.",
    "category": "Traffic Trouble",
    "pairs": [
      ["Street", "Road"], ["Car", "Vehicle"], ["Signal", "Sign"],
      ["Speed", "Limit"], ["Brake", "Stop"], ["Tire", "Wheel"],
      ["Drive", "Ride"], ["Police", "Sheriff"], ["Lane", "Track"]
    ]
  },
  {
    "crime": "A mystery bandit stole the hands off the town square clock.",
    "category": "Time Theft",
    "pairs": [
      ["Minute", "Second"], ["Hour", "Time"], ["Watch", "Clock"],
      ["Morning", "Evening"], ["Early", "Late"], ["Alarm", "Timer"],
      ["History", "Future"], ["Gear", "Spring"], ["Wrist", "Hand"]
    ]
  },
  {
    "crime": "Someone sneaked into the cinema and swapped the movies.",
    "category": "Movie Mixup",
    "pairs": [
      ["Actor", "Star"], ["Director", "Producer"], ["Ticket", "Seat"],
      ["Popcorn", "Candy"], ["Sound", "Audio"], ["Screen", "Projector"],
      ["Action", "Drama"], ["Comedy", "Horror"], ["Script", "Plot"]
    ]
  },
  {
    "crime": "A thief stole all the umbrellas during a massive rainstorm.",
    "category": "Weather Crime",
    "pairs": [
      ["Cloud", "Fog"], ["Rain", "Drizzle"], ["Wet", "Dry"],
      ["Storm", "Wind"], ["Sky", "Air"], ["Coat", "Jacket"],
      ["Handle", "Cover"], ["Shadow", "Shade"], ["Sun", "Heat"]
    ]
  },
  {
    "crime": "Someone replaced the zoo's lions with giant stuffed toys.",
    "category": "Zoo Bamboozle",
    "pairs": [
      ["Tiger", "Leopard"], ["Cage", "Fence"], ["Safari", "Tour"],
      ["Jungle", "Forest"], ["Wild", "Tame"], ["Meat", "Food"],
      ["Roar", "Growl"], ["Tail", "Paw"], ["Animal", "Beast"]
    ]
  },
  {
    "crime": "A prankster superglued all the library books shut.",
    "category": "Literary Lockdown",
    "pairs": [
      ["Reading", "Study"], ["Page", "Leaf"], ["Cover", "Binding"],
      ["Ink", "Print"], ["Author", "Writer"], ["Story", "Tale"],
      ["Word", "Sentence"], ["Paper", "Sheet"], ["Shelf", "Stand"]
    ]
  },
  {
    "crime": "Someone stole the entire inventory of a luxury watch shop.",
    "category": "Luxury Larceny",
    "pairs": [
      ["Diamond", "Jewel"], ["Gold", "Platinum"], ["Band", "Strap"],
      ["Store", "Shop"], ["Buyer", "Seller"], ["Price", "Value"],
      ["Brand", "Label"], ["Glass", "Crystal"], ["Box", "Case"]
    ]
  },
  {
    "crime": "A high-tech bandit used a drone to steal a pizza delivery.",
    "category": "Food Flight",
    "pairs": [
      ["Cheese", "Sauce"], ["Box", "Carton"], ["Warm", "Hot"],
      ["Order", "Menu"], ["Kitchen", "Cook"], ["Chef", "Baker"],
      ["Bike", "Scooter"], ["Fly", "Hover"], ["Crust", "Dough"]
    ]
  },
  {
    "crime": "Someone painted a fake tunnel on a wall and cars crashed.",
    "category": "Illusion Injury",
    "pairs": [
      ["Road", "Highway"], ["Brick", "Stone"], ["Paint", "Dye"],
      ["Dark", "Light"], ["Safety", "Danger"], ["Drive", "Steer"],
      ["Crash", "Impact"], ["Fake", "Real"], ["View", "Vision"]
    ]
  },
  {
    "crime": "A thief stole all the strings off every guitar in the shop.",
    "category": "Musical Mute",
    "pairs": [
      ["Guitar", "Bass"], ["Music", "Sound"], ["Song", "Tune"],
      ["Player", "Artist"], ["Pick", "Strum"], ["Case", "Bag"],
      ["Acoustic", "Electric"], ["Note", "Chord"], ["Stage", "Performance"]
    ]
  },
  {
    "crime": "Someone filled the grocery store's milk bottles with orange juice.",
    "category": "Dairy Disturbance",
    "pairs": [
      ["Glass", "Plastic"], ["Breakfast", "Lunch"], ["Fruit", "Veggie"],
      ["Sweet", "Sour"], ["Bottle", "Jug"], ["Drink", "Beverage"],
      ["Shelf", "Fridge"], ["Cart", "Basket"], ["Buy", "Sell"]
    ]
  },
  {
    "crime": "A bandit stole the lenses out of everyone's eyeglasses.",
    "category": "Vision Void",
    "pairs": [
      ["Glasses", "Frame"], ["See", "Look"], ["Eye", "Sight"],
      ["Lens", "Glass"], ["Blurry", "Clear"], ["Reading", "Distance"],
      ["Focus", "View"], ["Case", "Cloth"], ["Face", "Nose"]
    ]
  },
  {
    "crime": "Someone replaced the gym's weights with hollow plastic ones.",
    "category": "Fitness Fraud",
    "pairs": [
      ["Muscle", "Strength"], ["Heavy", "Light"], ["Lift", "Push"],
      ["Training", "Workout"], ["Gym", "Club"], ["Iron", "Steel"],
      ["Coach", "Player"], ["Sweat", "Heat"], ["Run", "Walk"]
    ]
  },
  {
    "crime": "A prankster set all the shop's alarms to go off at once.",
    "category": "Noisy Night",
    "pairs": [
      ["Sound", "Noise"], ["Alert", "Signal"], ["Loud", "Quiet"],
      ["Bell", "Siren"], ["Security", "Guard"], ["Shop", "Store"],
      ["Night", "Dark"], ["Door", "Gate"], ["Lock", "Key"]
    ]
  },
  {
    "crime": "Someone stole the lighthouse bulb during a foggy night.",
    "category": "Maritime Mystery",
    "pairs": [
      ["Ocean", "Sea"], ["Ship", "Boat"], ["Light", "Lamp"],
      ["Fog", "Mist"], ["Island", "Shore"], ["Wave", "Current"],
      ["Captain", "Sailor"], ["Fish", "Whale"], ["Sand", "Rock"]
    ]
  }
];

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  void _initializeGame() {
    final random = Random();
    List<String> shuffledPlayers = List.from(widget.players)..shuffle(random);
    
    _detective = shuffledPlayers[0];
    _suspect = shuffledPlayers[1];
    _sidekick = widget.players.length >= 5 ? shuffledPlayers[2] : null;
    
    _prepQueue = List.from(widget.players)..remove(_detective)..shuffle(random);
    _prepIndex = 0;

    _currentCase = _caseDatabase[random.nextInt(_caseDatabase.length)];
    List<List<String>> availablePairs = List<List<String>>.from(_currentCase['pairs'])..shuffle(random);
    List<List<String>> selectedPairs = availablePairs.sublist(0, 3);
    
    _secretWords = selectedPairs.map((p) => p[0]).toList();
    _civilianWords = selectedPairs.map((p) => p[1]).toList();
    
    List<String> decoys = availablePairs.sublist(3).expand((p) => p).toList()..shuffle(random);
    _allWords = (_secretWords + _civilianWords + decoys.sublist(0, 4))..shuffle(random);

    _gamePhase = 'setup';
    _selectedWords = [];
    _timeLeft = 180;
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_timeLeft > 0) _timeLeft--;
        else { _timer?.cancel(); _gamePhase = 'deduction_who'; }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF04060E),
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: const Text('The Interrogation'), automaticallyImplyLeading: _gamePhase == 'setup'),
      body: Container(
        width: double.infinity, height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(center: Alignment(-0.8, -0.6), radius: 1.2, colors: [Color(0xFF162252), Color(0xFF04060E)], stops: [0.0, 1.0]),
        ),
        child: SafeArea(child: Padding(padding: const EdgeInsets.all(24.0), child: _buildCurrentPhase())),
      ),
    );
  }

  Widget _buildCurrentPhase() {
    switch (_gamePhase) {
      case 'setup': return _buildSetupPhase();
      case 'prep_pass': return _buildPrepPassPhase();
      case 'prep_view': return _buildPrepViewPhase();
      case 'interrogation': return _buildInterrogationPhase();
      case 'deduction_who': return _buildDeductionWhoPhase();
      case 'deduction_words': return _buildDeductionWordsPhase();
      case 'result': return _buildResultPhase();
      default: return const Center(child: CircularProgressIndicator());
    }
  }

  Widget _buildSetupPhase() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text("CASE FILE OPENED", style: TextStyle(color: Color(0xFF8E95A3), letterSpacing: 2.0, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        const SizedBox(height: 10),
        Card(
          color: const Color(0xFF0E1329),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: Color(0xFF1F2947))),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const Icon(Icons.gavel_rounded, size: 48, color: Color(0xFF3B82F6)),
                const SizedBox(height: 16),
                Text(_currentCase['crime'], style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, height: 1.4), textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
        const SizedBox(height: 30),
        Card(
          color: const Color(0xFF0E1329),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0xFF3B82F6), width: 2)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                const Text("LEAD DETECTIVE", style: TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(_detective, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
        const Spacer(),
        const Text("Detective, look away!", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: () => setState(() => _gamePhase = 'prep_pass'), child: const Text('Start Role Briefing')),
      ],
    );
  }

  Widget _buildPrepPassPhase() {
    String nextPlayer = _prepQueue[_prepIndex];
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text("Pass phone to:", style: TextStyle(color: Color(0xFF8E95A3)), textAlign: TextAlign.center),
        Text(nextPlayer, style: const TextStyle(fontSize: 32, color: Color(0xFF3B82F6), fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        const SizedBox(height: 40),
        const Icon(Icons.visibility_off_outlined, size: 80, color: Colors.white24),
        const SizedBox(height: 40),
        ElevatedButton(onPressed: () => setState(() => _gamePhase = 'prep_view'), child: Text("I am $nextPlayer")),
      ],
    );
  }

  Widget _buildPrepViewPhase() {
    String currentPlayer = _prepQueue[_prepIndex];
    bool isSuspect = currentPlayer == _suspect;
    bool isSidekick = currentPlayer == _sidekick;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(isSuspect ? "YOU ARE THE SUSPECT" : (isSidekick ? "YOU ARE THE SIDEKICK" : "YOU ARE INNOCENT"), 
          style: TextStyle(color: isSuspect ? Colors.redAccent : const Color(0xFF00FF88), fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1.5), textAlign: TextAlign.center),
        const SizedBox(height: 30),
        Card(
          color: const Color(0xFF0E1329),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: isSuspect ? Colors.redAccent : const Color(0xFF1F2947), width: 2)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Text(isSuspect ? "Hide these words in your alibi:" : "Include these 'Safe Words' in your story:"),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 10, runSpacing: 10, alignment: WrapAlignment.center,
                  children: (isSuspect ? _secretWords : _civilianWords).map((w) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(color: const Color(0xFF2563EB).withOpacity(0.2), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF3B82F6))),
                    child: Text(w, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  )).toList(),
                ),
                if (isSidekick) ...[
                  const Divider(height: 40, color: Colors.white24),
                  const Text("SECRET INTEL:", style: TextStyle(color: Colors.amber)),
                  Text("The Suspect is $_suspect", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                ]
              ],
            ),
          ),
        ),
        const Spacer(),
        ElevatedButton(onPressed: () {
            setState(() {
              _prepIndex++;
              if (_prepIndex < _prepQueue.length) _gamePhase = 'prep_pass';
              else { _gamePhase = 'interrogation'; _startTimer(); }
            });
          }, child: const Text('Confirm & Pass')),
      ],
    );
  }

  Widget _buildInterrogationPhase() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text("QUESTIONING THE LINEUP", style: TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.bold, letterSpacing: 1.5), textAlign: TextAlign.center),
        const SizedBox(height: 20),
        Text("${_timeLeft ~/ 60}:${(_timeLeft % 60).toString().padLeft(2, '0')}", style: const TextStyle(fontSize: 80, fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center),
        const Spacer(),
        Card(
          color: const Color(0xFF0E1329),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFF1F2947))),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text("Case: ${_currentCase['crime']}", style: const TextStyle(color: Colors.white70, fontStyle: FontStyle.italic), textAlign: TextAlign.center),
          ),
        ),
        const Spacer(),
        ElevatedButton(onPressed: () { _timer?.cancel(); setState(() => _gamePhase = 'deduction_who'); }, child: const Text('Make Arrest')),
      ],
    );
  }

  Widget _buildDeductionWhoPhase() {
    List<String> suspects = widget.players.where((p) => p != _detective).toList();
    return Column(
      children: [
        const Text("DIGITAL LINEUP", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 20)),
        const SizedBox(height: 24),
        Expanded(
          child: GridView.count(
            crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 1.3,
            children: suspects.map((p) => InkWell(
              onTap: () => setState(() {
                _guessedSuspect = p;
                _gamePhase = (_guessedSuspect == _suspect) ? 'deduction_words' : 'result';
              }),
              child: Container(
                decoration: BoxDecoration(color: const Color(0xFF0E1329), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF1F2947))),
                alignment: Alignment.center,
                child: Text(p, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            )).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDeductionWordsPhase() {
    return Column(
      children: [
        const Text("NEURAL DECRYPTION", style: TextStyle(color: Color(0xFF00FF88), fontWeight: FontWeight.bold, letterSpacing: 2.0)),
        const SizedBox(height: 20),
        LinearProgressIndicator(value: _selectedWords.length / 4, backgroundColor: Colors.white10, color: const Color(0xFF3B82F6), minHeight: 8),
        const SizedBox(height: 24),
        Expanded(
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 12, runSpacing: 12, alignment: WrapAlignment.center,
              children: _allWords.map((w) {
                bool isSelected = _selectedWords.contains(w);
                return FilterChip(
                  label: Text(w), selected: isSelected, selectedColor: const Color(0xFF3B82F6),
                  onSelected: (s) => setState(() {
                    if (s && _selectedWords.length < 4) _selectedWords.add(w);
                    else if (!s) _selectedWords.remove(w);
                  }),
                );
              }).toList(),
            ),
          ),
        ),
        ElevatedButton(onPressed: _selectedWords.length == 4 ? () => setState(() => _gamePhase = 'result') : null, child: const Text("Finalize Case")),
      ],
    );
  }

  Widget _buildResultPhase() {
    bool caught = _guessedSuspect == _suspect;
    int wordsFound = _selectedWords.where((w) => _secretWords.contains(w)).length;
    bool detectiveWin = caught && wordsFound == 3;

    return TweenAnimationBuilder(
      duration: const Duration(seconds: 1),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, double value, child) {
        return Opacity(
          opacity: value,
          child: Transform.scale(
            scale: 0.8 + (0.2 * value),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Animated Icon with Glow
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: detectiveWin ? const Color(0xFF00FF88).withOpacity(0.3) : Colors.redAccent.withOpacity(0.3),
                          blurRadius: 40,
                          spreadRadius: 10,
                        )
                      ],
                    ),
                    child: Icon(
                      detectiveWin ? Icons.verified_user_rounded : Icons.cancel_rounded,
                      size: 100,
                      color: detectiveWin ? const Color(0xFF00FF88) : Colors.redAccent,
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // Animated Title
                Text(
                  detectiveWin ? "CASE CLOSED" : "CASE FAILED",
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4.0,
                    color: detectiveWin ? const Color(0xFF00FF88) : Colors.redAccent,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  caught 
                    ? "Suspect $_suspect apprehended." 
                    : "Wrongful arrest of $_guessedSuspect.",
                  style: const TextStyle(color: Color(0xFF8E95A3), fontSize: 16),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 40),

                // THE REVEAL CARD
                Card(
                  color: const Color(0xFF0E1329),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                    side: BorderSide(color: detectiveWin ? const Color(0xFF00FF88) : Colors.redAccent, width: 2),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        const Text("EVIDENCE REVEALED", style: TextStyle(color: Color(0xFF8E95A3), letterSpacing: 1.5, fontSize: 12)),
                        const Divider(height: 30, color: Colors.white12),
                        
                        // Suspect Words
                        const Text("SUSPECT'S WORDS", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          children: _secretWords.map((w) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _selectedWords.contains(w) ? const Color(0xFF00FF88).withOpacity(0.2) : Colors.white10,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: _selectedWords.contains(w) ? const Color(0xFF00FF88) : Colors.white24),
                            ),
                            child: Text(w, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          )).toList(),
                        ),

                        const SizedBox(height: 24),

                        // Civilian Safe Words
                        const Text("CIVILIAN SAFE WORDS", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          children: _civilianWords.map((w) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white10,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: Text(w, style: const TextStyle(color: Colors.white)),
                          )).toList(),
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(),
                
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: detectiveWin ? const Color(0xFF1F2947) : Colors.transparent,
                    side: BorderSide(color: detectiveWin ? Colors.transparent : Colors.white24),
                  ),
                  child: const Text('Return to HQ'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}