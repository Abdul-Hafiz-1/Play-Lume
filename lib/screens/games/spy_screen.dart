import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';

class SpyScreen extends StatefulWidget {
  final List<String> players;
  const SpyScreen({super.key, required this.players});

  @override
  State<SpyScreen> createState() => _SpyScreenState();
}

class _SpyScreenState extends State<SpyScreen> {
  String _gamePhase = 'reveal'; 
  int _currentPlayerIndex = 0;
  bool _isRoleRevealed = false;
  
  late String _spy;
  late String _location;
  String? _votedPlayer;
  
  Timer? _timer;
  int _timeLeft = 480;

  final List<String> _locations = [
    "Restaurant", "Hospital", "Space Station", "School", "Beach", "Airplane", 
  "Submarine", "Movie Studio", "Police Station", "Cruise Ship", "Museum", "Zoo",
  "Military Base", "Library", "Bank Vault", "Casino", "Embassy", "Subway Station",
  "Amusement Park", "Hotel Lobby", "Airport Hangar", "Skyscraper Roof", "Underground Lab",
  "Ski Resort", "Train Station", "Opera House", "Art Gallery", "Fire Station",
  "Construction Site", "Shopping Mall", "Harbor", "Desert Oasis", "Rainforest",
  "Volcano Observatory", "Nuclear Power Plant", "Football Stadium", "Concert Hall",
  "Recording Studio", "Data Center", "Prison", "Courthouse", "Farm", "Vineyard",
  "Lighthouse", "Aquarium", "Ice Rink", "Nightclub", "Bowling Alley", "Hardware Store",
  "Flower Shop", "Bakery", "Gym", "Gas Station", "Post Office", "Cemetery",
  "Castle", "Temple", "Monastery", "Treehouse", "Penthouse", "Basement",
  "Attic", "Garage", "Workshop", "Secret Tunnel", "Sewer", "Junkyard",
  "Car Wash", "Dentist Office", "Pharmacy", "Cyber Cafe", "Bowling Alley",
  "Tattoo Parlor", "Bus Depot", "Ferry Terminal", "Clock Tower", "Windmill",
  "Oil Rig", "Safari Park", "National Park", "Golf Course", "Tennis Court",
  "University", "Observatory", "Weather Station", "Satellite Dish", "Dockyard",
  "Cargo Ship", "Private Jet", "Blimp", "Cable Car", "Farris Wheel",
  "Bazaar", "Fish Market", "Textile Factory", "Steel Mill", "Coal Mine",
  "Diamond Mine", "Gold Mine", "Hidden Temple", "Ancient Ruins", "Pyramid",
  "Sphinx", "Stonehenge", "Colosseum", "Eiffel Tower", "Big Ben",
  "Statue of Liberty", "Great Wall", "Taj Mahal", "Cathedral", "Mosque",
  "Synagogue", "Capitol Building", "City Hall", "Embassy", "Consulate",
  "Safe House", "Hideout", "Bunker", "War Room", "Control Room",
  "Launch Pad", "Space Shuttle", "Mars Colony", "Moon Base", "International Space Station",
  "Submarine Base", "Aircraft Carrier", "Destroyer", "Frigate", "Patrol Boat",
  "Lifeboat", "Raft", "Canoe", "Kayak", "Houseboat",
  "Camper Van", "Motorhome", "Trailer Park", "Campsite", "Boy Scout Camp",
  "Summer Camp", "Water Park", "Theme Park", "Circus Tent", "Carnival",
  "Puppet Theater", "Drive-in Cinema", "Newsroom", "Radio Station", "TV Studio",
  "Printing Press", "Library of Congress", "National Archives", "High School", "Elementary School",
  "Kindergarten", "University Campus", "Dormitory", "Cafeteria", "Lecture Hall",
  "Science Lab", "Chemistry Lab", "Physics Lab", "Biology Lab", "Computer Lab",
  "Operating Room", "Emergency Room", "Waiting Room", "Doctor's Office", "Physical Therapy",
  "X-ray Room", "Pharmacy", "Blood Bank", "Morgue", "Funeral Home",
  "Jewelry Store", "Toy Store", "Candy Shop", "Ice Cream Parlor", "Coffee Shop",
  "Juice Bar", "Steakhouse", "Pizzeria", "Sushi Bar", "Diner",
  "Food Court", "Market Stall", "Grocery Store", "Supermarket", "Warehouse",
  "Storage Unit", "Shipping Container", "Customs Office", "Passport Control", "Border Crossing",
  "Checkpoint", "Guard Post", "Watchtower", "Brig", "Armory"
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
    final random = Random();
    
    // Create a copy of the players and shuffle them thoroughly
    List<String> shuffledList = List.from(widget.players)..shuffle(random);
    
    // The first person in the scrambled list is now the Spy
    _spy = shuffledList.first; 
    
    _location = _locations[random.nextInt(_locations.length)];
    _gamePhase = 'reveal';
    _timeLeft = 480;
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_timeLeft > 0) _timeLeft--;
        else _timer?.cancel();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF04060E),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Spy'),
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
          child: Center( // Fixes the left-cropping glitch [cite: 2026-03-02]
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: _buildCurrentPhase(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentPhase() {
    switch (_gamePhase) {
      case 'reveal': return _buildRevealPhase();
      case 'gameplay': return _buildGameplayPhase();
      case 'vote': return _buildVotePhase();
      case 'result': return _buildResultPhase();
      default: return const CircularProgressIndicator();
    }
  }

  Widget _buildRevealPhase() {
    String currentPlayer = widget.players[_currentPlayerIndex];
    bool isSpy = currentPlayer == _spy;
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text("IDENTITY CHECK", style: TextStyle(color: Color(0xFF8E95A3), letterSpacing: 3, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        const SizedBox(height: 10),
        Text(currentPlayer, style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        const SizedBox(height: 60),
        
        if (!_isRoleRevealed) 
          ElevatedButton(
            onPressed: () => setState(() => _isRoleRevealed = true),
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 70)),
            child: const Text("SEE MY ROLE"),
          )
        else ...[
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: const Color(0xFF0E1329), 
              borderRadius: BorderRadius.circular(30), 
              border: Border.all(color: isSpy ? Colors.redAccent : const Color(0xFF3B82F6), width: 2),
              boxShadow: [
                BoxShadow(color: (isSpy ? Colors.redAccent : const Color(0xFF3B82F6)).withOpacity(0.2), blurRadius: 20)
              ]
            ),
            child: Column(
              children: [
                Icon(isSpy ? Icons.warning_amber_rounded : Icons.location_on_rounded, size: 50, color: isSpy ? Colors.redAccent : const Color(0xFF3B82F6)),
                const SizedBox(height: 20),
                Text(
                  isSpy ? "YOU ARE THE SPY" : _location, 
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: isSpy ? Colors.redAccent : Colors.white), 
                  textAlign: TextAlign.center
                ),
                if (!isSpy) const Text("\nKeep this location secret!", style: TextStyle(color: Colors.white38, fontSize: 14)),
              ],
            ),
          ),
          const SizedBox(height: 60),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _isRoleRevealed = false;
                if (_currentPlayerIndex < widget.players.length - 1) {
                  _currentPlayerIndex++;
                } else {
                  _gamePhase = 'gameplay';
                  _startTimer();
                }
              });
            }, 
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1F2947), minimumSize: const Size(double.infinity, 70)),
            child: const Text("I AM READY")
          )
        ]
      ],
    );
  }

  Widget _buildGameplayPhase() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "${_timeLeft ~/ 60}:${(_timeLeft % 60).toString().padLeft(2, '0')}", 
          style: TextStyle(fontSize: 90, fontWeight: FontWeight.bold, color: _timeLeft < 60 ? Colors.redAccent : Colors.white)
        ),
        const Text("INTERROGATION IN PROGRESS", style: TextStyle(color: Color(0xFF3B82F6), letterSpacing: 2, fontWeight: FontWeight.bold)),
        const SizedBox(height: 60),
        const Icon(Icons.record_voice_over_outlined, size: 100, color: Colors.white10),
        const Spacer(),
        ElevatedButton(
          onPressed: () => setState(() => _gamePhase = 'vote'), 
          style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 70)),
          child: const Text("EXPOSE THE SPY")
        ),
      ],
    );
  }

  Widget _buildVotePhase() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text("WHO IS THE SPY?", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.redAccent), textAlign: TextAlign.center),
        const SizedBox(height: 20),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 1.5),
            itemCount: widget.players.length,
            itemBuilder: (context, index) {
              return InkWell(
                onTap: () => setState(() { _votedPlayer = widget.players[index]; _gamePhase = 'result'; }),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF0E1329), 
                    borderRadius: BorderRadius.circular(20), 
                    border: Border.all(color: const Color(0xFF1F2947))
                  ),
                  alignment: Alignment.center,
                  child: Text(widget.players[index], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildResultPhase() {
    bool win = _votedPlayer == _spy;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(win ? Icons.verified_user_rounded : Icons.cancel_rounded, size: 120, color: win ? const Color(0xFF00FF88) : Colors.redAccent),
        const SizedBox(height: 20),
        Text(win ? "SPY EXPOSED" : "MISSION FAILED", style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center),
        const SizedBox(height: 40),
        Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(color: const Color(0xFF0E1329), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white12)),
          child: Column(
            children: [
              const Text("IDENTITY REVEAL", style: TextStyle(color: Color(0xFF8E95A3), fontSize: 12, letterSpacing: 2)),
              const SizedBox(height: 10),
              Text("THE SPY WAS: $_spy", style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 20)),
              const Divider(height: 30, color: Colors.white10),
              Text("LOCATION: $_location", style: const TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.bold, fontSize: 20)),
            ],
          ),
        ),
        const SizedBox(height: 60),
        ElevatedButton(
          onPressed: () => Navigator.pop(context), 
          style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 70), backgroundColor: const Color(0xFF1F2947)),
          child: const Text("RETURN TO HQ")
        ),
      ],
    );
  }
}