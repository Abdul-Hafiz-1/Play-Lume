import 'package:flutter/material.dart';
import 'dart:math';

class UndercoverScreen extends StatefulWidget {
  final List<String> players;

  const UndercoverScreen({super.key, required this.players});

  @override
  State<UndercoverScreen> createState() => _UndercoverScreenState();
}

class _UndercoverScreenState extends State<UndercoverScreen> {
  // Game State
  String _gamePhase = 'reveal'; // reveal, discuss, vote, result
  int _currentPlayerIndex = 0;
  bool _isWordRevealed = false;
  String? _selectedPlayerToEliminate;

  // Roles & Words
  late int _undercoverIndex;
  late String _civilianWord;
  late String _undercoverWord;

  final List<List<String>> _wordPairs = [
    ["Pizza", "Burger"],
    ["Hospital", "Clinic"],
    ["Movie", "Play"],
    ["Coffee", "Tea"],
    ["Apple", "Pear"],
    ["Sushi", "Sashimi"],
    ["Chocolate", "Vanilla"],
    ["Steak", "Chop"],
    ["Bread", "Toast"],
    ["Milk", "Cream"],
    ["Juice", "Soda"],
    ["Pasta", "Rice"],
    ["Donut", "Bagel"],
    ["Honey", "Syrup"],
    ["Cereal", "Oatmeal"],
    ["Taco", "Burrito"],
    ["Butter", "Cheese"],
    ["Cookie", "Brownie"],
    ["Watermelon", "Melon"],
    ["Mango", "Papaya"],
    ["Onion", "Garlic"],
    ["Salt", "Pepper"],
    ["Cake", "Cupcake"],
    ["Ice Cream", "Sorbet"],
    ["Wine", "Beer"],
    ["Soup", "Stew"],
    ["Strawberry", "Raspberry"],
    ["Ketchup", "Mustard"],
    ["Omelette", "Pancake"],
    ["Muffin", "Scone"],

    // Objects & Tech
    ["Laptop", "Tablet"],
    ["Phone", "Radio"],
    ["Camera", "Video"],
    ["Battery", "Charger"],
    ["Mouse", "Keyboard"],
    ["Clock", "Watch"],
    ["Mirror", "Window"],
    ["Pencil", "Pen"],
    ["Hammer", "Wrench"],
    ["Needle", "Thread"],
    ["Candle", "Lamp"],
    ["Bucket", "Bowl"],
    ["Ladder", "Stairs"],
    ["Bottle", "Flask"],
    ["Briefcase", "Backpack"],
    ["Wallet", "Purse"],
    ["Key", "Lock"],
    ["Soap", "Shampoo"],
    ["Towel", "Blanket"],
    ["Pillow", "Cushion"],
    ["Helmet", "Cap"],
    ["Spoon", "Fork"],
    ["Plate", "Tray"],
    ["Guitar", "Violin"],
    ["Piano", "Organ"],
    ["Trumpet", "Flute"],
    ["Drums", "Cymbals"],
    ["Speaker", "Headphone"],
    ["Remote", "Switch"],
    ["Compass", "Map"],

    // Nature & Animals
    ["Dog", "Wolf"],
    ["Cat", "Tiger"],
    ["Lion", "Leopard"],
    ["Horse", "Zebra"],
    ["Elephant", "Mammoth"],
    ["Eagle", "Falcon"],
    ["Shark", "Dolphin"],
    ["Whale", "Orca"],
    ["Snake", "Lizard"],
    ["Frog", "Toad"],
    ["Bee", "Wasp"],
    ["Spider", "Scorpion"],
    ["Forest", "Jungle"],
    ["Mountain", "Hill"],
    ["Ocean", "Sea"],
    ["River", "Stream"],
    ["Lake", "Pond"],
    ["Desert", "Dunes"],
    ["Rain", "Snow"],
    ["Thunder", "Lightning"],
    ["Sun", "Star"],
    ["Moon", "Planet"],
    ["Flower", "Bush"],
    ["Tree", "Plant"],
    ["Grass", "Moss"],
    ["Cloud", "Fog"],
    ["Wind", "Storm"],
    ["Canyon", "Valley"],
    ["Cave", "Tunnel"],
    ["Island", "Reef"],

    // Places & Buildings
    ["School", "College"],
    ["Library", "Bookstore"],
    ["Office", "Studio"],
    ["Gym", "Stadium"],
    ["Park", "Garden"],
    ["Museum", "Gallery"],
    ["Mall", "Market"],
    ["Bank", "ATM"],
    ["Hotel", "Motel"],
    ["Church", "Temple"],
    ["Castle", "Palace"],
    ["Bridge", "Tower"],
    ["Airport", "Station"],
    ["Garage", "Shed"],
    ["Kitchen", "Pantry"],
    ["Bedroom", "Attic"],
    ["Basement", "Cellar"],
    ["Balcony", "Porch"],
    ["Theater", "Cinema"],
    ["Farm", "Ranch"],

    // Travel & Transport
    ["Car", "Truck"],
    ["Bike", "Scooter"],
    ["Plane", "Jet"],
    ["Boat", "Ship"],
    ["Train", "Metro"],
    ["Rocket", "Shuttle"],
    ["Taxi", "Uber"],
    ["Bus", "Coach"],
    ["Helmet", "Goggles"],
    ["Suitcase", "Trunk"],
    ["Passport", "Visa"],
    ["Ticket", "Token"],
    ["Anchor", "Sail"],
    ["Wheel", "Tire"],
    ["Engine", "Motor"],

    // Clothing & Fashion
    ["Shirt", "Blouse"],
    ["Pants", "Jeans"],
    ["Dress", "Skirt"],
    ["Jacket", "Coat"],
    ["Shoes", "Boots"],
    ["Socks", "Stockings"],
    ["Gloves", "Mittens"],
    ["Scarf", "Tie"],
    ["Belt", "Suspenders"],
    ["Hat", "Beanie"],
    ["Ring", "Bracelet"],
    ["Necklace", "Earring"],
    ["Glasses", "Contacts"],
    ["Suit", "Tuxedo"],
    ["Sneakers", "Sandals"],

    // Sports & Hobbies
    ["Soccer", "Rugby"],
    ["Tennis", "Badminton"],
    ["Baseball", "Cricket"],
    ["Golf", "Hockey"],
    ["Skiing", "Skating"],
    ["Boxing", "Karate"],
    ["Yoga", "Pilates"],
    ["Chess", "Checkers"],
    ["Poker", "Blackjack"],
    ["Painting", "Drawing"],
    ["Dancing", "Singing"],
    ["Fishing", "Hunting"],
    ["Running", "Cycling"],
    ["Surfing", "Sailing"],
    ["Bowling", "Darts"]
  ];

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  void _initializeGame() {
    final random = Random();
    _undercoverIndex = random.nextInt(widget.players.length);
    
    // Pick a random word pair
    final pair = _wordPairs[random.nextInt(_wordPairs.length)];
    // Randomize which one is the civilian word and which is the undercover word
    if (random.nextBool()) {
      _civilianWord = pair[0];
      _undercoverWord = pair[1];
    } else {
      _civilianWord = pair[1];
      _undercoverWord = pair[0];
    }

    _gamePhase = 'reveal';
    _currentPlayerIndex = 0;
    _isWordRevealed = false;
    _selectedPlayerToEliminate = null;
  }

  void _nextPlayerOrPhase() {
    setState(() {
      _isWordRevealed = false;
      if (_currentPlayerIndex < widget.players.length - 1) {
        _currentPlayerIndex++;
      } else {
        _gamePhase = 'discuss'; // Everyone has seen their words!
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF04060E),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Undercover'),
        automaticallyImplyLeading: _gamePhase == 'reveal' && _currentPlayerIndex == 0, // Only allow back at the very start
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
      case 'reveal':
        return _buildRevealPhase();
      case 'discuss':
        return _buildDiscussPhase();
      case 'vote':
        return _buildVotePhase();
      case 'result':
        return _buildResultPhase();
      default:
        return const Center(child: Text("Loading..."));
    }
  }

  Widget _buildRevealPhase() {
    String currentPlayerName = widget.players[_currentPlayerIndex];
    String currentWord = (_currentPlayerIndex == _undercoverIndex) ? _undercoverWord : _civilianWord;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "Pass the phone to",
          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: const Color(0xFF8E95A3)),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          currentPlayerName,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(color: const Color(0xFF3B82F6), fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),

        if (!_isWordRevealed) ...[
          const Icon(Icons.visibility_off, size: 80, color: Colors.white24),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () => setState(() => _isWordRevealed = true),
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 60)),
            child: const Text('Tap to Reveal Secret Word'),
          ),
        ] else ...[
          Card(
            color: const Color(0xFF0E1329),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: const BorderSide(color: Color(0xFF3B82F6), width: 2),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 20.0),
              child: Column(
                children: [
                  const Text("Your Secret Word is:", style: TextStyle(color: Color(0xFF8E95A3))),
                  const SizedBox(height: 10),
                  Text(currentWord, style: Theme.of(context).textTheme.displaySmall?.copyWith(color: Colors.white), textAlign: TextAlign.center),
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
            child: const Text('Hide Word & Continue'),
          ),
        ]
      ],
    );
  }

  Widget _buildDiscussPhase() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.forum, size: 80, color: Color(0xFF3B82F6)),
        const SizedBox(height: 30),
        Text("Discussion Time!", style: Theme.of(context).textTheme.displaySmall, textAlign: TextAlign.center),
        const SizedBox(height: 20),
        Text(
          "Everyone has seen their word.\n\nTake turns saying exactly ONE word to describe your secret word without giving it away completely.",
          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: const Color(0xFF8E95A3), height: 1.5),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        ElevatedButton(
          onPressed: () => setState(() => _gamePhase = 'vote'),
          style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 60)),
          child: const Text('Ready to Vote'),
        ),
      ],
    );
  }

  Widget _buildVotePhase() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text("Who is the Undercover?", style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
        const SizedBox(height: 10),
        const Text("Discuss and agree as a group who to eliminate.", style: TextStyle(color: Color(0xFF8E95A3)), textAlign: TextAlign.center),
        const SizedBox(height: 20),
        
        Expanded(
          child: ListView.builder(
            itemCount: widget.players.length,
            itemBuilder: (context, index) {
              String player = widget.players[index];
              bool isSelected = _selectedPlayerToEliminate == player;

              return Card(
                color: isSelected ? const Color(0xFF2563EB).withOpacity(0.3) : const Color(0xFF0E1329),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFF1F2947), width: 1.5),
                ),
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  title: Text(player, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  trailing: isSelected ? const Icon(Icons.how_to_vote, color: Color(0xFF3B82F6)) : null,
                  onTap: () => setState(() => _selectedPlayerToEliminate = player),
                ),
              );
            },
          ),
        ),
        
        ElevatedButton(
          onPressed: _selectedPlayerToEliminate == null ? null : () {
            setState(() => _gamePhase = 'result');
          },
          style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 60)),
          child: const Text('Eliminate Player'),
        ),
      ],
    );
  }

  Widget _buildResultPhase() {
    String undercoverName = widget.players[_undercoverIndex];
    bool undercoverCaught = _selectedPlayerToEliminate == undercoverName;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          undercoverCaught ? Icons.task_alt : Icons.warning_amber_rounded, 
          size: 80, 
          color: undercoverCaught ? const Color(0xFF00FF88) : Colors.redAccent
        ),
        const SizedBox(height: 20),
        Text(
          undercoverCaught ? "Undercover Caught!" : "Undercover Escaped!", 
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            color: undercoverCaught ? const Color(0xFF00FF88) : Colors.redAccent
          ), 
          textAlign: TextAlign.center
        ),
        const SizedBox(height: 20),
        
        Card(
          color: const Color(0xFF0E1329),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0xFF1F2947))),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Text("The Undercover was: $undercoverName", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const Divider(color: Color(0xFF1F2947), height: 30),
                const Text("Civilians' Word:", style: TextStyle(color: Color(0xFF8E95A3))),
                Text(_civilianWord, style: const TextStyle(color: Color(0xFF3B82F6), fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                const Text("Undercover's Word:", style: TextStyle(color: Color(0xFF8E95A3))),
                Text(_undercoverWord, style: const TextStyle(color: Colors.redAccent, fontSize: 24, fontWeight: FontWeight.bold)),
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