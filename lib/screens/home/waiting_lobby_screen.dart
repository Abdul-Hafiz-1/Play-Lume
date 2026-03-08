import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Import your centralized services and models
import '../../services/firebase_service.dart';
import '../../models/game_model.dart';

class WaitingLobbyScreen extends StatelessWidget {
  final String roomCode;
  final String gameId;
  final bool isHost;

  const WaitingLobbyScreen({
    super.key,
    required this.roomCode,
    required this.gameId,
    required this.isHost,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Game Lobby'),
        centerTitle: true,
        automaticallyImplyLeading: false, // Prevent back button 
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: firebaseService.getRoomStream(roomCode),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            print("WaitingLobby Stream Error: ${snapshot.error}");
            return Center(child: Text('Error loading room data: ${snapshot.error}'));
          }
          if (snapshot.data == null || !snapshot.data!.exists) {
            Future.delayed(const Duration(seconds: 3), () {
              if (ModalRoute.of(context)?.isCurrent == true) {
                Navigator.popUntil(context, ModalRoute.withName('/home'));
              }
            });
            return const Center(child: Text('Room not found. Returning to home...'));
          }

          Map<String, dynamic> roomData = snapshot.data!.data() as Map<String, dynamic>;
          List<dynamic> players = List<dynamic>.from(roomData['players'] ?? []);
          String gameStatus = roomData['status'] ?? 'waiting';

          final currentGame = games.firstWhere((g) => g.id == gameId, orElse: () => games.first);

          // Fix: Logic for navigating to game screen
          if (gameStatus == 'playing') {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (ModalRoute.of(context)?.isCurrent == true) {
                Navigator.pushReplacementNamed(
                  context,
                  currentGame.actualGameRouteName,
                  arguments: {'roomCode': roomCode, 'gameId': gameId},
                );
              }
            });
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Theme.of(context).colorScheme.secondary),
                  const SizedBox(height: 20),
                  const Text("Starting game...", style: TextStyle(fontSize: 18, color: Colors.white)),
                ],
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Sculpted Info Card
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  color: Theme.of(context).colorScheme.surface,
                  child: Container(
                    padding: const EdgeInsets.all(24.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(colors: [Color(0xFF231454), Color(0xFF130A24)], begin: Alignment.topLeft, end: Alignment.bottomRight) // Card gradient
                    ),
                    child: Column(
                      children: [
                        Text(
                          currentGame.name, 
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Theme.of(context).colorScheme.secondary,
                            fontWeight: FontWeight.bold
                          )
                        ),
                        const SizedBox(height: 16),
                        const Text('ROOM CODE', style: TextStyle(color: Colors.white54, letterSpacing: 1.2)),
                        const SizedBox(height: 4),
                        SelectableText(
                          roomCode, 
                          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 4.0
                          )
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isHost ? Colors.amber.withOpacity(0.2) : Colors.white10,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isHost ? 'You are the Host' : 'You are a Player (${firebaseService.nickname})', 
                            style: TextStyle(
                              color: isHost ? Colors.amberAccent : Colors.white70,
                              fontWeight: FontWeight.bold
                            )
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                
                // Players List with Dimensionality
                Text(
                  'Players Joined (${players.length})', 
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    itemCount: players.length,
                    itemBuilder: (context, index) {
                      var player = players[index] as Map<String, dynamic>;
                      bool isMe = player['userId'] == firebaseService.userId;
                      
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                          side: BorderSide(
                            color: isMe ? Theme.of(context).colorScheme.secondary : Colors.transparent,
                            width: 1.5
                          )
                        ),
                        color: Theme.of(context).cardColor,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: player['isHost'] == true ? Colors.amber.withOpacity(0.2) : Theme.of(context).colorScheme.primary.withOpacity(0.2),
                            child: Icon(
                              player['isHost'] == true ? Icons.star : Icons.person, 
                              color: player['isHost'] == true ? Colors.amber : Theme.of(context).colorScheme.secondary
                            ),
                          ),
                          title: Text(
                            player['nickname'] ?? 'Unknown', 
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)
                          ),
                          trailing: isMe ? const Text('(You)', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)) : null,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                
                // Sculpted Action Area
                if (isHost)
                  ElevatedButton(
                    onPressed: () {
                      if (gameId == 'guess_the_liar' && players.length < 3) {
                        snackbarKey.currentState?.showSnackBar(const SnackBar(content: Text('Guess the Liar needs at least 3 players to start.')));
                        return;
                      } else if (gameId == 'dont_get_me_started' && players.length < 2) {
                        snackbarKey.currentState?.showSnackBar(const SnackBar(content: Text("Don't Get Me Started needs at least 2 players to start.")));
                        return;
                      } else if (gameId == 'sync' && players.length < 2) {
                        snackbarKey.currentState?.showSnackBar(const SnackBar(content: Text("Sync needs at least 2 players to start.")));
                        return;
                      }
                      firebaseService.startGame(roomCode, gameId);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.greenAccent[700], 
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                    ),
                    child: const Text('Start Game'),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(30)),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white54)),
                        SizedBox(width: 16),
                        Text('Waiting for host to start...', style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}