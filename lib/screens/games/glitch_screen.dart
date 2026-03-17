import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'dart:ui';

class GlitchScreen extends StatefulWidget {
  final List<String> players;
  const GlitchScreen({super.key, required this.players});

  @override
  State<GlitchScreen> createState() => _GlitchScreenState();
}

class _GlitchScreenState extends State<GlitchScreen> {
  String _phase = 'reveal'; 
  int _playerIndex = 0;
  bool _isDataVisible = false;
  
  late String _glitchPlayer;
  late Map<String, String> _currentLogic;
  String? _votedPlayer;

  // Broad categories to keep the Glitch hidden longer
  final List<Map<String, String>> _logicBank = [
{"cat": "NATURE", "rule": "Must be able to survive underwater"},
    {"cat": "FOOD", "rule": "Typically served hot"},
    {"cat": "OBJECTS", "rule": "Made primarily of metal"},
    {"cat": "ACTION", "rule": "Something you do at a gym"},
    {"cat": "BRANDS", "rule": "They sell food or drinks"},
    {"cat": "PLACES", "rule": "Places where you must be quiet"},
    {"cat": "CLOTHING", "rule": "Items worn on your feet"},
    {"cat": "TECH", "rule": "Devices that have a screen"},
    {"cat": "EXCUSES", "rule": "Something people say when they are running late"},
    {"cat": "SOCIAL MEDIA", "rule": "Something people do just to look cool in photos"},
    {"cat": "PETTY", "rule": "Something that isn't illegal but is very annoying"},
    {"cat": "AWKWARD", "rule": "Something you do when you forget someone's name"},
    {"cat": "LIES", "rule": "A 'white lie' people tell to avoid hurting feelings"},
    {"cat": "MORNINGS", "rule": "The first thing you do when you wake up"},
    {"cat": "LAZINESS", "rule": "Something you do to avoid cleaning your room"},
    {"cat": "FORGOTTEN", "rule": "Something you always lose inside your own house"},
    {"cat": "GROCERIES", "rule": "Something you always buy but never finish eating"},
    {"cat": "FRIDGE", "rule": "Something that stays in the fridge way too long"},
    {"cat": "CHORES", "rule": "The most boring household task"},
    {"cat": "BEDTIME", "rule": "Something that keeps you awake when you should be sleeping"},
    {"cat": "BATTERY", "rule": "Something you do when your phone hits 5%"},
    {"cat": "GUILTY PLEASURES", "rule": "A food you love that others think is weird"},
    {"cat": "FAST FOOD", "rule": "Something you eat when you are in a rush"},
    {"cat": "SPICY", "rule": "A food that makes your eyes water"},
    {"cat": "DINING OUT", "rule": "Something that makes a restaurant great"},
    {"cat": "SNACKS", "rule": "Something you can't stop eating once you start"},
    {"cat": "BREAKFAST", "rule": "Something you only eat in the morning"},
    {"cat": "CHEAP EATS", "rule": "Something that tastes amazing even if it's cheap"},
    {"cat": "VACATION", "rule": "The first thing you do when you get to a hotel"},
    {"cat": "AIRPORTS", "rule": "Something that always causes a delay at security"},
    {"cat": "ROAD TRIPS", "rule": "The most annoying habit of a passenger"},
    {"cat": "SIGHTSEEING", "rule": "A place tourists go that is actually a bit boring"},
    {"cat": "SOUVENIRS", "rule": "Something you buy on holiday that stays on a shelf forever"},
    {"cat": "PACKING", "rule": "Something you always pack but never actually use"},
    {"cat": "MOVIES", "rule": "A movie trope that everyone is tired of"},
    {"cat": "SPOILERS", "rule": "A movie that has a very famous surprise ending"},
    {"cat": "CONCERTS", "rule": "Something people do at a live show that is annoying"},
    {"cat": "VILLAINS", "rule": "A movie villain that is actually kind of cool"},
    {"cat": "NOSTALGIA", "rule": "A toy from your childhood that you still have"},
    {"cat": "CELEBRITIES", "rule": "Someone who is famous for a very specific talent"},
    {"cat": "USELESS", "rule": "A gadget that was a total waste of money"},
    {"cat": "SMARTPHONES", "rule": "An app that you use every single day"},
    {"cat": "OFFICE", "rule": "Something you keep on a desk for decoration"},
    {"cat": "LUXURY", "rule": "Something people buy just to show off"},
    {"cat": "RETRO", "rule": "Something your parents used that is now 'old school'"},
    {"cat": "SUPERPOWERS", "rule": "A superpower that would actually be very inconvenient"},
    {"cat": "NIGHTMARES", "rule": "A common fear like spiders or heights"},
    {"cat": "WEALTH", "rule": "The first thing you would buy if you won the lottery"},
    {"cat": "TIME TRAVEL", "rule": "A time period you would hate to live in"},
    {"cat": "SURVIVAL", "rule": "The most important item for a desert island"},
    {"cat": "WISHES", "rule": "Something you would ask a genie for that isn't money"},
    {"cat": "FASHION", "rule": "A clothing trend that looks ridiculous now"},
    {"cat": "SCHOOL", "rule": "A subject you think is actually useful in real life"},
    {"cat": "SKILLS", "rule": "Something you wish you could learn instantly"},
    {"cat": "DEBATES", "rule": "A topic that will divide a room of friends in seconds"},
    {"cat": "DREAMS", "rule": "A job that sounds fun but is actually hard work"},
    {"cat": "MYSTERY", "rule": "Something that is still a secret to most people"},
    {"cat": "WEATHER", "rule": "Something you do only when it's raining outside"},
    {"cat": "HOBBIES", "rule": "A hobby that is very expensive to start"},
    {"cat": "TRANSPORT", "rule": "The most uncomfortable way to travel"},
    {"cat": "ANIMALS", "rule": "An animal that would make a terrible pet"},
    {"cat": "SPACE", "rule": "Something you would find on another planet"},
    {"cat": "CELEBRATIONS", "rule": "Something that happens at every birthday party"},
    {"cat": "KITCHEN", "rule": "The most dangerous tool in the kitchen"},
    {"cat": "MESSY", "rule": "Something that is impossible to keep clean"},
    {"cat": "SOUNDS", "rule": "A noise that is extremely satisfying to hear"},
    {"cat": "SMELLS", "rule": "A smell that reminds you of your childhood"},
    {"cat": "STATIONERY", "rule": "Something you find in a pencil case"},
    {"cat": "GAMES", "rule": "A game that always ends in an argument"},
    {"cat": "GIFTS", "rule": "The worst gift you could receive for your birthday"},
    {"cat": "WINTER", "rule": "Something you wear only when it's freezing"},
    {"cat": "SUMMER", "rule": "The best way to stay cool on a hot day"},
    {"cat": "FEARS", "rule": "Something people are afraid of for no reason"},
    {"cat": "TALENTS", "rule": "A party trick that always impresses people"},
    {"cat": "DESSERT", "rule": "A sweet treat that is better than the main meal"},
    {"cat": "SHOPPING", "rule": "Something you buy and immediately regret"},
    {"cat": "CLEANING", "rule": "Something you only clean when guests are coming"},
    {"cat": "RELAXING", "rule": "The best way to spend a Sunday afternoon"},
    {"cat": "LUCK", "rule": "Something people do for good luck"},
    {"cat": "BOTTLES", "rule": "Something you would find a message in"},
    {"cat": "COLLECTIONS", "rule": "Something people collect as a hobby"},
    {"cat": "DANGER", "rule": "Something you are told 'never to touch'"},
    {"cat": "MUSIC", "rule": "A musical instrument that is very hard to play"},
    {"cat": "FRUITS", "rule": "A fruit that is very hard to peel"},
    {"cat": "VEGETABLES", "rule": "A vegetable that kids usually hate"},
    {"cat": "DENTIST", "rule": "Something you do to avoid going to the dentist"},
    {"cat": "LIBRARY", "rule": "Something you are not allowed to do in a library"},
    {"cat": "MUSEUM", "rule": "Something you would see in a history museum"},
    {"cat": "CAMPING", "rule": "The most important thing to bring on a camping trip"},
    {"cat": "STREETS", "rule": "Something you see in a busy city center"},
    {"cat": "GARDEN", "rule": "Something you find under a rock"},
    {"cat": "PICNIC", "rule": "A food that is perfect for a picnic"},
    {"cat": "FAIRYTALES", "rule": "A character found in most bedtime stories"},
    {"cat": "CIRCUS", "rule": "Something you would see at a circus performance"},
    {"cat": "RECORDS", "rule": "A world record that sounds impossible to break"},
    {"cat": "INVENTIONS", "rule": "An invention that changed the world forever"},
    {"cat": "DREAMS", "rule": "Something that only happens in your dreams"},
    {"cat": "OCEAN", "rule": "Something you find at the very bottom of the sea"},
    {"cat": "ART", "rule": "Something a famous painter would use"},
    {"cat": "ROBOTS", "rule": "A task you wish a robot could do for you"}
  ];

  @override
  void initState() {
    super.initState();
    _initGame();
  }

  void _initGame() {
    final rand = Random();
    _glitchPlayer = widget.players[rand.nextInt(widget.players.length)];
    _currentLogic = _logicBank[rand.nextInt(_logicBank.length)];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF04060E),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Background Gradient
          Container(
            width: double.infinity, height: double.infinity,
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(-0.8, -0.6), radius: 1.5,
                colors: [Color(0xFF162252), Color(0xFF04060E)],
              ),
            ),
          ),
          // Floating Glow Orbs
          Positioned(top: -50, right: -50, child: _glowOrb(150, Colors.blue.withOpacity(0.1))),
          Positioned(bottom: 100, left: -50, child: _glowOrb(200, Colors.purple.withOpacity(0.05))),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: _buildCurrentPhase(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _glowOrb(double size, Color color) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color, boxShadow: [BoxShadow(color: color, blurRadius: 100, spreadRadius: 50)]),
    );
  }

  Widget _buildCurrentPhase() {
    switch (_phase) {
      case 'reveal': return _buildRevealPhase();
      case 'action': return _buildActionPhase();
      case 'result': return _buildResultPhase();
      default: return const Center(child: CircularProgressIndicator());
    }
  }

  Widget _buildRevealPhase() {
    String currentPlayer = widget.players[_playerIndex];
    bool isGlitch = currentPlayer == _glitchPlayer;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("NEURAL LINK", style: TextStyle(color: Color(0xFF3B82F6), letterSpacing: 5, fontWeight: FontWeight.w900, fontSize: 12)),
        const SizedBox(height: 10),
        Text(currentPlayer.toUpperCase(), style: const TextStyle(fontSize: 36, color: Colors.white, fontWeight: FontWeight.w200, letterSpacing: 2)),
        const SizedBox(height: 60),
        
        ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: _isDataVisible ? (isGlitch ? Colors.redAccent : const Color(0xFF00FF88)) : Colors.white10, width: 1.5),
              ),
              child: _isDataVisible ? _buildSecretData(isGlitch) : _buildHiddenState(),
            ),
          ),
        ),
        
        const SizedBox(height: 60),
        ElevatedButton(
          onPressed: () {
            HapticFeedback.mediumImpact();
            if (!_isDataVisible) {
              setState(() => _isDataVisible = true);
            } else {
              setState(() {
                _isDataVisible = false;
                if (_playerIndex < widget.players.length - 1) _playerIndex++;
                else _phase = 'action';
              });
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: _isDataVisible ? const Color(0xFF1F2947) : const Color(0xFF3B82F6),
            minimumSize: const Size(double.infinity, 70),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          child: Text(_isDataVisible ? "ENCRYPT & NEXT" : "DECRYPT LOGIC"),
        ),
      ],
    );
  }

  Widget _buildHiddenState() {
    return const Column(
      children: [
        Icon(Icons.fingerprint, size: 60, color: Colors.white24),
        SizedBox(height: 20),
        Text("SCANNING IDENTITY...", style: TextStyle(color: Colors.white24, letterSpacing: 2)),
      ],
    );
  }

  Widget _buildSecretData(bool isGlitch) {
    return Column(
      children: [
        Text("CATEGORY: ${_currentLogic['cat']}", style: TextStyle(color: isGlitch ? Colors.redAccent : const Color(0xFF00FF88), fontWeight: FontWeight.bold, letterSpacing: 2)),
        const SizedBox(height: 20),
        Text(
          isGlitch ? "CORRUPTED\nYOU ARE THE GLITCH" : "LOGIC: ${_currentLogic['rule']}",
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildActionPhase() {
    return Column(
      children: [
        const SizedBox(height: 40),
        const Text("GLITCH IS ACTIVE", style: TextStyle(color: Colors.redAccent, letterSpacing: 5, fontWeight: FontWeight.bold)),
        const SizedBox(height: 40),
        const Icon(Icons.radar, size: 100, color: Colors.white10),
        const SizedBox(height: 20),
        const Text(
          "All Systems share your data word.\nIdentify the anomaly.",
          textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
        const Spacer(),
        Expanded(
          flex: 3,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 15, mainAxisSpacing: 15, childAspectRatio: 1.8),
            itemCount: widget.players.length,
            itemBuilder: (context, index) => GestureDetector(
              onTap: () => setState(() { _votedPlayer = widget.players[index]; _phase = 'result'; }),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0E1329),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                alignment: Alignment.center,
                child: Text(widget.players[index], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Replace the top of your Result Phase with this synchronized builder
Widget _buildResultPhase() {
  bool win = _votedPlayer == _glitchPlayer;
  Color resultColor = win ? const Color(0xFF00FF88) : Colors.redAccent;

  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      // Signature Static Icon with Glow
      Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: resultColor.withOpacity(0.1),
            boxShadow: [
              BoxShadow(
                color: resultColor.withOpacity(0.2),
                blurRadius: 40,
                spreadRadius: 5,
              )
            ],
          ),
          child: Icon(
            win ? Icons.verified_user_rounded : Icons.cancel_rounded,
            size: 100,
            color: resultColor,
          ),
        ),
      ),
      const SizedBox(height: 30),

      // Result Title
      Text(
        win ? "GLITCH PURGED" : "SYSTEM CRASH",
        style: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          letterSpacing: 2.0,
          color: Colors.white,
        ),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 8),
      Text(
        win ? "The corrupted player has been isolated." : "The Glitch successfully bypassed the system.",
        textAlign: TextAlign.center,
        style: const TextStyle(color: Color(0xFF8E95A3), fontSize: 16),
      ),
      
      const SizedBox(height: 40),

      // Evidence Card
      Container(
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: const Color(0xFF0E1329), 
          borderRadius: BorderRadius.circular(24), 
          border: Border.all(color: Colors.white.withOpacity(0.05))
        ),
        child: Column(
          children: [
            const Text("DECRYPTED DATA", style: TextStyle(color: Color(0xFF8E95A3), fontSize: 12, letterSpacing: 2)),
            const SizedBox(height: 15),
            Text(
              "THE GLITCH: $_glitchPlayer", 
              style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 18)
            ),
            const Divider(height: 30, color: Colors.white10),
            Text(
              "THE RULE: ${_currentLogic['rule']}", 
              style: const TextStyle(color: Color(0xFF00FF88), fontWeight: FontWeight.bold, fontSize: 18)
            ),
          ],
        ),
      ),
      
      const SizedBox(height: 50),

      // Footer Button
      ElevatedButton(
        onPressed: () => Navigator.pop(context), 
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 70),
          backgroundColor: const Color(0xFF1F2947),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: const Text("RETURN TO HQ"),
      ),
    ],
  );
}
}
