// lib/models/game_model.dart

class Game {
  final String id;
  final String name;
  final String description; // Briefing shown on the card
  final String instructions; // Detailed instructions for the Briefing Screen
  final String imageAsset;
  final bool isOnline;
  final String selectionLobbyRouteName;
  final String actualGameRouteName;

  Game({
    required this.id,
    required this.name,
    required this.description,
    required this.instructions,
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
    description: "One report contains fabricated data. Identify the anomaly.",
    instructions: "All operatives will receive a question. Most will answer truthfully based on the same topic, but one operative is fed a different prompt. Cross-examine the answers and vote to terminate the liar's link.",
    imageAsset: 'assets/guess_the_liar_banner.jpg',
    isOnline: true,
    selectionLobbyRouteName: '/game_lobby',
    actualGameRouteName: '/play/guess_the_liar',
  ),
  Game(
    id: 'sync',
    name: "Sync",
    description: "Neural synchronization required. Match your frequency.",
    instructions: "A prompt will appear on all terminals. Operatives must enter the most logical response. Score points by achieving a neural match with other players. The highest synchronization level wins.",
    imageAsset: 'assets/sync_banner.jpg',
    isOnline: true,
    selectionLobbyRouteName: '/game_lobby',
    actualGameRouteName: '/play/sync',
  ),
  Game(
    id: 'dont_get_me_started',
    name: "Don't Get Me Started",
    description: "Analyze the rant. Decipher the hidden key phrases.",
    instructions: "One operative is chosen to go on a verbal rant about a specific topic. The other operatives must listen closely and guess the secret key phrases hidden within the monologue to gain intel.",
    imageAsset: 'assets/dont_get_me_started_banner.jpg',
    isOnline: true,
    selectionLobbyRouteName: '/game_lobby',
    actualGameRouteName: '/play/dont_get_me_started',
  ),
  Game(
    id: 'most_likely_to',
    name: "Most Likely To...",
    description: "The system predicts a risk. Assign it to an operative.",
    instructions: "A scenario is presented. All operatives must vote on which person in the room is most likely to fit that profile. High-contrast social deduction where the majority vote rules the day.",
    imageAsset: 'assets/most_likely_to_banner.jpg',
    isOnline: true,
    selectionLobbyRouteName: '/game_lobby',
    actualGameRouteName: '/play/most_likely_to',
  ),
  Game(
    id: 'undercover',
    name: "Undercover",
    description: "The signal is compromised. Find the rogue element.",
    instructions: "Operatives receive a secret keyword. The 'Undercover' receives a slightly different word, and the 'Mr. White' receives nothing. Use one-word descriptions to find the rogue before they decipher the real signal.",
    imageAsset: 'assets/undercover_banner.jpg',
    isOnline: false,
    selectionLobbyRouteName: '/setup/pass_and_play',
    actualGameRouteName: '/play/undercover',
  ),
  Game(
    id: 'dont_get_caught',
    name: "Don't Get Caught",
    description: "Surveillance mission active. Maintain absolute stealth.",
    instructions: "One operative is the 'Guard' and must keep their eyes closed. Other operatives must complete physical tasks or 'snap' photos of the guard. If the guard detects movement and opens their eyes, the mission is compromised.",
    imageAsset: 'assets/dont_get_caught_banner.jpg',
    isOnline: false,
    selectionLobbyRouteName: '/setup/pass_and_play',
    actualGameRouteName: '/play/dont_get_caught',
  ),
  Game(
    id: 'informant',
    name: "The Informant",
    description: "Guess the code, then expose the double agent.",
    instructions: "Operatives must guess a secret word through clues. However, one 'Informant' already knows the word. After the word is guessed, you must look back at the clues to expose who knew too much.",
    imageAsset: 'assets/informant_banner.jpg',
    isOnline: false,
    selectionLobbyRouteName: '/setup/pass_and_play',
    actualGameRouteName: '/play/informant',
  ),
  Game(
    id: 'interrogation',
    name: "The Interrogation",
    description: "Weave the code into your alibi. Evade detection.",
    instructions: "Operatives are given secret keywords. The Detective will interrogate each subject. You must weave your keywords into your answers naturally. If the Detective flags a word, your cover is blown.",
    imageAsset: 'assets/interrogation_banner.jpg',
    isOnline: false,
    selectionLobbyRouteName: '/setup/pass_and_play',
    actualGameRouteName: '/play/interrogation',
  ),
  Game(
    id: 'spy',
    name: "Spy",
    description: "Intercept the location before your cover is blown.",
    instructions: "Everyone knows the mission location except the Spy. By asking subtle questions, the operatives must find the Spy. The Spy must figure out the location before they are identified.",
    imageAsset: 'assets/spy_banner.jpg',
    isOnline: false,
    selectionLobbyRouteName: '/setup/pass_and_play',
    actualGameRouteName: '/play/spy',
  ),
  Game(
    id: 'glitch',
    name: "The Glitch",
    description: "The logic stream is corrupted. Fix the system.",
    instructions: "Operatives are given a secret 'Logic Rule' to follow. One 'Glitch' is operating on corrupted data and doesn't know the rule. Identify who is breaking the logic pattern before the system crashes.",
    imageAsset: 'assets/glitch_banner.jpg',
    isOnline: false,
    selectionLobbyRouteName: '/setup/pass_and_play',
    actualGameRouteName: '/play/glitch',
  ),
  Game(
    id: 'mafia',
    name: "Mafia",
    description: "The shadows are moving. Purge the infiltration.",
    instructions: "Night falls on the town. The Mafia selects a target to eliminate. During the day, the survivors must discuss, cross-examine, and vote to exile the suspected Mafia members before they outnumber the citizens.",
    imageAsset: 'assets/mafia_banner.jpg',
    isOnline: false,
    selectionLobbyRouteName: '/setup/pass_and_play',
    actualGameRouteName: '/play/mafia',
  ),
];