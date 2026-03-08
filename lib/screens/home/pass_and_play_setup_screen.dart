import 'package:flutter/material.dart';
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
  final int _maxPlayers = 15;

  int get _minPlayers {
    if (widget.game.id == 'interrogation') return 2;
    if (widget.game.id == 'informant') return 4;
    return 3;
  }

  void _addPlayer() {
    if (_players.length >= _maxPlayers) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Maximum of $_maxPlayers players reached!")));
      return;
    }

    String name = _nameController.text.trim();
    if (name.isNotEmpty && !_players.contains(name)) {
      setState(() {
        _players.add(name);
        _nameController.clear();
      });
    } else if (_players.contains(name)) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("That name is already taken!")));
    }
  }

  void _removePlayer(int index) {
    setState(() => _players.removeAt(index));
  }

  void _startGame() {
    if (_players.length < _minPlayers) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("You need at least $_minPlayers players for this game!")));
      return;
    }
    Navigator.pushNamed(context, widget.game.actualGameRouteName, arguments: {'players': _players});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: Text('${widget.game.name} Setup')),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text("Who is playing? (${_players.length}/$_maxPlayers)", style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
                const SizedBox(height: 10),
                Text("Pass the phone around or let one person enter all the names. (Minimum $_minPlayers players).", style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _nameController,
                        decoration: InputDecoration(hintText: _players.length >= _maxPlayers ? 'Lobby Full' : 'Enter player name...'),
                        enabled: _players.length < _maxPlayers,
                        onSubmitted: (_) => _addPlayer(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _players.length >= _maxPlayers ? null : _addPlayer,
                      style: ElevatedButton.styleFrom(shape: const CircleBorder(), padding: const EdgeInsets.all(16)),
                      child: const Icon(Icons.add, color: Colors.white),
                    )
                  ],
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView.builder(
                    itemCount: _players.length,
                    itemBuilder: (context, index) {
                      return Card(
                        color: const Color(0xFF0E1329),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFF1F2947), width: 1.2)),
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          leading: CircleAvatar(backgroundColor: const Color(0xFF3B82F6).withOpacity(0.2), child: Text('${index + 1}', style: const TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.bold))),
                          title: Text(_players[index], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                          trailing: IconButton(icon: const Icon(Icons.close, color: Colors.redAccent), onPressed: () => _removePlayer(index)),
                        ),
                      );
                    },
                  ),
                ),
                ElevatedButton(
                  onPressed: _players.length >= _minPlayers ? _startGame : null,
                  style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 56)),
                  child: Text('Start Game (${_players.length}/$_maxPlayers)'),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}