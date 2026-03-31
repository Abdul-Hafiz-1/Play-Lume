// lib/models/game_model.dart

class Game {
  final String id;
  final String name;
  final String description;
  final String imageAsset;
  final bool isOnline;
  final String selectionLobbyRouteName;
  final String actualGameRouteName;

  Game({
    required this.id,
    required this.name,
    required this.description,
    required this.imageAsset,
    required this.isOnline,
    required this.selectionLobbyRouteName,
    required this.actualGameRouteName,
  });
}

final List<Game> games = [
  Game(
    id: 'guess_the_liar',
    name: "Guess the Liar",
    description: "Everyone answers a question, but one is different. Find the liar!",
    imageAsset: 'assets/placeholder_gtl.png',
    isOnline: true,
    selectionLobbyRouteName: '/game_lobby',
    actualGameRouteName: '/play/guess_the_liar',
  ),
  Game(
    id: 'sync',
    name: "Sync",
    description: "Think alike! Match answers to score points.",
    imageAsset: 'assets/placeholder_sync.png',
    isOnline: true,
    selectionLobbyRouteName: '/game_lobby',
    actualGameRouteName: '/play/sync',
  ),
  Game(
    id: 'dont_get_me_started',
    name: "Don't Get Me Started",
    description: "One player rants on a topic, others guess key phrases!",
    imageAsset: 'lib/assets/DGMS.png',
    isOnline: true,
    selectionLobbyRouteName: '/game_lobby',
    actualGameRouteName: '/play/dont_get_me_started',
  ),
  Game(
    id: 'most_likely_to',
    name: "Most Likely To...",
    description: "Vote on who in the room is most likely to do something crazy!",
    imageAsset: 'assets/placeholder_mlt.png',
    isOnline: true, // This one is online/multi-device
    selectionLobbyRouteName: '/game_lobby',
    actualGameRouteName: '/play/most_likely_to',
  ),
  Game(
    id: 'undercover',
    name: "Undercover",
    description: "Everyone gets a secret word, except the Undercover. Find them!",
    imageAsset: 'assets/placeholder_undercover.png',
    isOnline: false, // Pass and Play!
    selectionLobbyRouteName: '/setup/pass_and_play',
    actualGameRouteName: '/play/undercover',
  ),
  Game(
    id: 'dont_get_caught',
    name: "Don't Get Caught",
    description: "Snap pictures of everyone before time runs out! Keep your eyes closed!",
    imageAsset: 'assets/placeholder_dgc.png',
    isOnline: false, // Pass and Play / Local Camera!
    selectionLobbyRouteName: '/setup/pass_and_play',
    actualGameRouteName: '/play/dont_get_caught',
  ),
  Game(
    id: 'informant',
    name: "The Informant",
    description: "Guess the word, then catch the player who secretly knew it all along!",
    imageAsset: 'assets/placeholder_informant.png',
    isOnline: false, // Pass and Play!
    selectionLobbyRouteName: '/setup/pass_and_play',
    actualGameRouteName: '/play/informant',
  ),
  Game(
    id: 'interrogation',
    name: "The Interrogation",
    description: "Weave secret words into your alibi without the Detective noticing!",
    imageAsset: 'assets/images/interrogation.png',
    isOnline: false, // Pass and Play!
    selectionLobbyRouteName: '/setup/pass_and_play',
    actualGameRouteName: '/play/interrogation',
  ),
  Game(
    id: 'spy',
    name: "Spy",
    description: "Find the impostor among you before they figure out where you are!",
    imageAsset: 'assets/images/spy.png',
    isOnline: false,
    selectionLobbyRouteName: '/setup/pass_and_play',
    actualGameRouteName: '/play/spy',
  ),
  Game(
  id: 'glitch',
  name: "The Glitch",
  description: "Everyone follows the secret logic rule except one. Find the corrupted system!",
  imageAsset: 'assets/images/glitch.png', // Ensure you have an icon here
  isOnline: false,
  selectionLobbyRouteName: '/setup/pass_and_play',
  actualGameRouteName: '/play/glitch',
  ),
  Game(
  id: 'mafia',
  name: "Mafia",
  description: "Identify the Mafia before they take over the town! A game of secrets and betrayal.",
  imageAsset: 'assets/images/mafia.png',
  isOnline: false, // Starting with Pass-and-Play
  selectionLobbyRouteName: '/setup/pass_and_play',
  actualGameRouteName: '/play/mafia',
),
];