import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:play_lumee/firebase_options.dart'; // IMPORTANT: Ensure this matches your project name
import 'dart:async';
import 'dart:math';
import 'package:collection/collection.dart'; // IMPORTANT: Added for firstWhereOrNull

// --- Firebase Configuration ---
// IMPORTANT FOR WEB: Ensure you have run `flutterfire configure`
// and `firebase_options.dart` is generated and correctly configured in your project.
// Firebase.initializeApp() below relies on this for web.

/// Represents a pair of questions: one for normal players and a similar one for the liar.
class QuestionPair {
  final String original;
  final String liar;

  const QuestionPair({required this.original, required this.liar});
}

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? userId;
  String? nickname;

  // Expanded list of paired questions for Guess the Liar
  final List<QuestionPair> _guessTheLiarQuestionPairs = [
    QuestionPair(
        original: "What's your favorite thing to do on a rainy day?",
        liar: "What's your favorite thing to do on a sunny day?"),
    QuestionPair(
        original: "If you could have any superpower, what would it be and why?",
        liar: "If you could have any animal as a pet, what would it be and why?"),
    QuestionPair(
        original: "What's the most unusual food you've ever tried?",
        liar: "What's the most unusual drink you've ever tried?"),
    QuestionPair(
        original: "Describe your ideal vacation.",
        liar: "Describe your worst vacation."),
    QuestionPair(
        original: "What's a skill you've always wanted to learn?",
        liar: "What's a skill you wish you could unlearn?"),
    QuestionPair(
        original: "What's your most memorable childhood toy?",
        liar: "What's your most regrettable childhood toy?"),
    QuestionPair(
        original: "If you could live in any fictional world, where would it be?",
        liar: "If you could live in any historical era, when and where would it be?"),
    QuestionPair(
        original: "What's one thing you're surprisingly good at?",
        liar: "What's one thing you're surprisingly bad at?"),
    QuestionPair(
        original: "What's the best piece of advice you've ever received?",
        liar: "What's the worst piece of advice you've ever received?"),
    QuestionPair(
        original: "If you could invent a new holiday, what would it be about?",
        liar: "If you could abolish an existing holiday, which one and why?"),
    QuestionPair(
        original: "What's your go-to comfort food?",
        liar: "What's your go-to adventurous food?"),
    QuestionPair(
        original: "If you were an animal, what would you be and why?",
        liar: "If you were a plant, what would you be and why?"),
    QuestionPair(
        original: "What's the last book you read that truly captivated you?",
        liar: "What's the last movie you watched that truly disappointed you?"),
    QuestionPair(
        original: "What's your favorite way to relax after a long day?",
        liar: "What's your favorite way to get energized after a long day?"),
    QuestionPair(
        original: "If you could travel anywhere in time, when and where would you go?",
        liar: "If you could travel anywhere in space, where would you go?"),
    QuestionPair(
        original: "What's a small act of kindness that made a big impact on you?",
        liar: "What's a small mistake that had a big impact on you?"),
    QuestionPair(
        original: "What's your favorite season and why?",
        liar: "What's your least favorite season and why?"),
    QuestionPair(
        original: "If you could switch lives with anyone for a day, who would it be?",
        liar: "If you could switch ages with anyone for a day, who would it be?"),
    QuestionPair(
        original: "What's a unique talent or hobby you have?",
        liar: "What's a common talent or hobby you lack?"),
    QuestionPair(
        original: "What's your dream job, regardless of practicality?",
        liar: "What's your nightmare job, regardless of practicality?"),
    QuestionPair(
        original: "What's the most beautiful place you've ever visited?",
        liar: "What's the most overrated place you've ever visited?"),
    QuestionPair(
        original: "If you could meet any historical figure, who would it be?",
        liar: "If you could meet any future figure, who would it be?"),
    QuestionPair(
        original: "What's your favorite type of music?",
        liar: "What's your least favorite type of music?"),
    QuestionPair(
        original: "What's a movie that always makes you laugh?",
        liar: "What's a movie that always makes you cry?"),
    QuestionPair(
        original: "What's something you're passionate about?",
        liar: "What's something you're indifferent about?"),
    QuestionPair(
        original: "If you had a personal theme song, what would it be?",
        liar: "If you had a personal alarm sound, what would it be?"),
    QuestionPair(
        original: "What's your favorite board game or card game?",
        liar: "What's your least favorite board game or card game?"),
    QuestionPair(
        original: "What's a piece of technology you can't live without?",
        liar: "What's a piece of technology you wish never existed?"),
    QuestionPair(
        original: "What's your favorite way to spend a weekend?",
        liar: "What's your least favorite way to spend a weekend?"),
    QuestionPair(
        original: "If you could learn any language instantly, which one would it be?",
        liar: "If you could unlearn any language instantly, which one would it be?"),
    QuestionPair(
        original: "What's the best concert you've ever attended?",
        liar: "What's the worst concert you've ever attended?"),
    QuestionPair(
        original: "What's your favorite type of weather?",
        liar: "What's your least favorite type of weather?"),
    QuestionPair(
        original: "If you could have dinner with three people, living or dead, who would they be?",
        liar: "If you could avoid dinner with three people, living or dead, who would they be?"),
    QuestionPair(
        original: "What's a food you absolutely refuse to eat?",
        liar: "What's a food you could eat every day and never get tired of?"),
    QuestionPair(
        original: "What's your favorite form of exercise?",
        liar: "What's your least favorite form of exercise?"),
    QuestionPair(
        original: "If you could design your own house, what unique feature would it have?",
        liar: "If you could design your own nightmare house, what unique feature would it have?"),
    QuestionPair(
        original: "What's a cause you strongly believe in?",
        liar: "What's a cause you are completely indifferent to?"),
    QuestionPair(
        original: "What's your favorite memory from school?",
        liar: "What's your most embarrassing memory from school?"),
    QuestionPair(
        original: "If you could instantly become an expert in any field, what would it be?",
        liar: "If you could instantly forget everything about one field, what would it be?"),
    QuestionPair(
        original: "What's your favorite fictional character?",
        liar: "What's your least favorite fictional character?"),
    QuestionPair(
        original: "What's a skill you're currently trying to master?",
        liar: "What's a skill you gave up trying to master?"),
    QuestionPair(
        original: "What's your favorite type of art?",
        liar: "What's a type of art you just don't understand?"),
    QuestionPair(
        original: "If you could witness any event in history, what would it be?",
        liar: "If you could prevent any event in history, what would it be?"),
    QuestionPair(
        original: "What's your favorite dessert?",
        liar: "What's your least favorite dessert?"),
    QuestionPair(
        original: "What's something that always brings a smile to your face?",
        liar: "What's something that always makes you roll your eyes?"),
    QuestionPair(
        original: "If you could send a message to your past self, what would it say?",
        liar: "If you could send a message to your future self, what would it say?"),
    QuestionPair(
        original: "What's your favorite animal?",
        liar: "What's an animal you're secretly afraid of?"),
    QuestionPair(
        original: "What's a place you dream of visiting but haven't yet?",
        liar: "What's a place you visited and would never go back to?"),
    QuestionPair(
        original: "What's your favorite childhood memory?",
        liar: "What's your most cringe-worthy childhood memory?"),
    QuestionPair(
        original: "If you had to eat one meal for the rest of your life, what would it be?",
        liar: "If you had to avoid one meal for the rest of your life, what would it be?"),
    QuestionPair(
        original: "What's the most adventurous thing you've ever done?",
        liar: "What's the most boring thing you've ever done?"),
    QuestionPair(
        original: "What's your favorite holiday?",
        liar: "What's a holiday you find overrated?"),
    QuestionPair(
        original: "If you could give one piece of advice to everyone, what would it be?",
        liar: "If you could un-give one piece of advice to everyone, what would it be?"),
    QuestionPair(
        original: "What's your favorite way to travel?",
        liar: "What's your least favorite way to travel?"),
    QuestionPair(
        original: "What's a habit you're trying to break or form?",
        liar: "What's a habit you secretly enjoy but shouldn't?"),
    QuestionPair(
        original: "What's your favorite type of story (book, movie, etc.)?",
        liar: "What's a type of story you actively avoid?"),
    QuestionPair(
        original: "If you could invent a new color, what would it be called?",
        liar: "If you could eliminate a color from the spectrum, which one would it be?"),
    QuestionPair(
        original: "What's your favorite thing about yourself?",
        liar: "What's one thing you'd change about yourself if you could?"),
    QuestionPair(
        original: "What's a challenge you've overcome?",
        liar: "What's a challenge you're still struggling with?"),
    QuestionPair(
        original: "What's your favorite sound?",
        liar: "What's a sound that instantly annoys you?"),
    QuestionPair(
        original: "If you could have any car, what would it be?",
        liar: "If you had to drive one car for the rest of your life, what would it be?"),
    QuestionPair(
        original: "What's your favorite thing to cook or bake?",
        liar: "What's your least favorite thing to cook or bake?"),
    QuestionPair(
        original: "What's a historical period you find most fascinating?",
        liar: "What's a historical period you find most depressing?"),
    QuestionPair(
        original: "What's your favorite scent?",
        liar: "What's a scent you absolutely hate?"),
    QuestionPair(
        original: "If you could instantly solve one world problem, what would it be?",
        liar: "If you could instantly create one world problem, what would it be?"),
    QuestionPair(
        original: "What's your favorite way to express creativity?",
        liar: "What's a way you're completely uncreative?"),
    QuestionPair(
        original: "What's a piece of advice you'd give to your younger self?",
        liar: "What's a piece of advice your younger self would ignore?"),
    QuestionPair(
        original: "What's your ideal way to spend a snow day?",
        liar: "What's your ideal way to spend a scorching hot day?"),
    QuestionPair(
        original: "What's your favorite type of flower?",
        liar: "What's a type of plant you dislike?"),
    QuestionPair(
        original: "If you could have a conversation with any animal, which one would it be?",
        liar: "If you could swap bodies with any animal, which one would it be?"),
    QuestionPair(
        original: "What's your favorite type of weather for sleeping?",
        liar: "What's your least favorite type of weather for sleeping?"),
    QuestionPair(
        original: "What's a small pleasure that makes your day better?",
        liar: "What's a small annoyance that makes your day worse?"),
    QuestionPair(
        original: "If you could live anywhere in the world, where would it be?",
        liar: "If you had to live in the most remote place on Earth, where would it be?"),
    QuestionPair(
        original: "What's your favorite sport to watch or play?",
        liar: "What's a sport you just don't understand?"),
    QuestionPair(
        original: "What's a new skill you're hoping to learn this year?",
        liar: "What's an old skill you're glad you don't need anymore?"),
    QuestionPair(
        original: "What's your favorite way to celebrate a birthday?",
        liar: "What's your least favorite way to celebrate a birthday?"),
    QuestionPair(
        original: "If you could have a personal chef, what cuisine would they specialize in?",
        liar: "If you had to eat bland food for a month, what would be the first flavorful thing you'd eat?"),
    QuestionPair(
        original: "What's your favorite type of tree?",
        liar: "What's your favorite type of bush?"),
    QuestionPair(
        original: "What's a dream you've had that felt incredibly real?",
        liar: "What's a nightmare you've had that felt incredibly real?"),
    QuestionPair(
        original: "If you could change one thing about the world, what would it be?",
        liar: "If you could make one thing worse about the world, what would it be?"),
    QuestionPair(
        original: "What's your favorite type of footwear?",
        liar: "What's your least favorite type of footwear?"),
    QuestionPair(
        original: "What's a piece of art that deeply moved you?",
        liar: "What's a piece of art that completely confused you?"),
    QuestionPair(
        original: "What's your favorite type of cloud?",
        liar: "What's your favorite type of sky?"),
    QuestionPair(
        original: "If you could be a character in a video game, who would you be?",
        liar: "If you had to be a villain in a video game, who would you be?"),
    QuestionPair(
        original: "What's your favorite way to drink coffee or tea?",
        liar: "What's your least favorite way to drink coffee or tea?"),
    QuestionPair(
        original: "What's a historical event you wish you could have witnessed?",
        liar: "What's a historical event you wish you could prevent?"),
    QuestionPair(
        original: "What's your favorite type of bird?",
        liar: "What's a type of bird you find annoying?"),
    QuestionPair(
        original: "If you could instantly master any musical instrument, which would it be?",
        liar: "If you had to play only one musical instrument for the rest of your life, which would it be?"),
    QuestionPair(
        original: "What's your favorite type of cheese?",
        liar: "What's a cheese you absolutely cannot stand?"),
    QuestionPair(
        original: "What's a sound that instantly relaxes you?",
        liar: "What's a sound that instantly makes you tense?"),
    QuestionPair(
        original: "If you could design a new flag for your country, what would it look like?",
        liar: "If you could design a new currency for your country, what would it look like?"),
    QuestionPair(
        original: "What's your favorite type of bread?",
        liar: "What's a type of bread you avoid?"),
    QuestionPair(
        original: "What's a memory that always makes you smile?",
        liar: "What's a memory that always makes you cringe?"),
    QuestionPair(
        original: "If you could have any animal as a pet, what would it be?",
        liar: "If you had to have a mythical creature as a pet, what would it be?"),
    QuestionPair(
        original: "What's your favorite way to spend a quiet evening?",
        liar: "What's your favorite way to spend a loud evening?"),
    QuestionPair(
        original: "What's a piece of advice you'd give to a new parent?",
        liar: "What's a piece of advice you'd give to a new villain?"),
    QuestionPair(
        original: "What's your favorite type of fruit?",
        liar: "What's a fruit you find disgusting?"),
    QuestionPair(
        original: "What's a book you think everyone should read?",
        liar: "What's a book you think no one should read?"),
    QuestionPair(
        original: "If you could have a superpower that only worked on Tuesdays, what would it be?",
        liar: "If you could have a useless superpower, what would it be?"),
    QuestionPair(
        original: "What's your favorite type of pasta?",
        liar: "What's a pasta shape you find unappealing?"),
    QuestionPair(
        original: "What's a place you've visited that exceeded your expectations?",
        liar: "What's a place you visited that completely underwhelmed you?"),
    QuestionPair(
        original: "What's your favorite type of vegetable?",
        liar: "What's a vegetable you refuse to eat?"),
    QuestionPair(
        original: "If you could instantly learn to play any sport, which would it be?",
        liar: "If you had to play one sport for the rest of your life, which would it be?"),
    QuestionPair(
        original: "What's your favorite type of candy?",
        liar: "What's a candy you would throw away?"),
    QuestionPair(
        original: "What's a piece of technology you wish existed?",
        liar: "What's a piece of technology you wish had never been invented?"),
    QuestionPair(
        original: "What's your favorite type of sandwich?",
        liar: "What's the weirdest sandwich you've ever had?"),
    QuestionPair(
        original: "If you could have a conversation with your future self, what would you ask?",
        liar: "If you could have a conversation with your past self, what would you warn them about?"),
    QuestionPair(
        original: "What's your favorite type of soup?",
        liar: "What's a soup you would never order?"),
    QuestionPair(
        original: "What's a historical mystery you'd love to solve?",
        liar: "What's a historical mystery you wish remained unsolved?"),
    QuestionPair(
        original: "What's your favorite type of pizza topping?",
        liar: "What's a pizza topping you consider an abomination?"),
    QuestionPair(
        original: "If you could have any job in the world, what would it be?",
        liar: "If you had to have the most boring job in the world, what would it be?"),
    QuestionPair(
        original: "What's your favorite type of ice cream flavor?",
        liar: "What's an ice cream flavor you think should be banned?"),
    QuestionPair(
        original: "What's a memory that makes you feel nostalgic?",
        liar: "What's a memory that makes you feel embarrassed?"),
    QuestionPair(
        original: "If you could have a personal robot, what would its primary function be?",
        liar: "If you could have a personal robot that only caused minor annoyances, what would be its primary function?"),
    QuestionPair(
        original: "What's your favorite type of cake?",
        liar: "What's a type of cake you find unappetizing?"),
    QuestionPair(
        original: "What's a skill you're glad you learned?",
        liar: "What's a skill you regret learning?"),
    QuestionPair(
        original: "What's your favorite type of cookie?",
        liar: "What's a cookie you would never eat?"),
    QuestionPair(
        original: "If you could bring back any extinct animal, which one would it be?",
        liar: "If you could make any animal extinct, which one would it be?"),
    QuestionPair(
        original: "What's your favorite type of pie?",
        liar: "What's a pie you would actively avoid?"),
    QuestionPair(
        original: "What's a piece of advice you'd give to someone starting a new job?",
        liar: "What's a piece of advice you'd give to someone trying to get fired?"),
    QuestionPair(
        original: "What's your favorite type of salad dressing?",
        liar: "What's a salad dressing you despise?"),
    QuestionPair(
        original: "If you could have a conversation with a fictional character, who would it be?",
        liar: "If you could have a conversation with a historical villain, who would it be?"),
    QuestionPair(
        original: "What's your favorite type of cereal?",
        liar: "What's a cereal that leaves you disappointed?"),
    QuestionPair(
        original: "What's a place you've visited that surprised you?",
        liar: "What's a place you've visited that was exactly as you expected?"),
    QuestionPair(
        original: "What's your favorite type of sauce?",
        liar: "What's a sauce you would never put on anything?"),
    QuestionPair(
        original: "If you could instantly learn to dance any style, which would it be?",
        liar: "If you had to dance one style for the rest of your life, which would it be?"),
    QuestionPair(
        original: "What's your favorite type of snack?",
        liar: "What's a snack you find incredibly unappetizing?"),
    QuestionPair(
        original: "What's a piece of advice you'd give to someone moving to a new city?",
        liar: "What's a piece of advice you'd give to someone trying to get lost in a new city?"),
    QuestionPair(
        original: "What's your favorite type of bread for toast?",
        liar: "What's your favorite type of spread for toast?"),
    QuestionPair(
        original: "If you could have a private concert by any artist, who would it be?",
        liar: "If you had to attend a terrible concert, whose would it be?"),
    QuestionPair(
        original: "What's your favorite type of tea?",
        liar: "What's a type of beverage you never drink?"),
    QuestionPair(
        original: "What's a memory that makes you laugh out loud?",
        liar: "What's a memory that makes you silently chuckle?"),
    QuestionPair(
        original: "If you could have a personal stylist, what style would you ask for?",
        liar: "If you had to wear one outfit for the rest of your life, what would it be?"),
    QuestionPair(
        original: "What's your favorite type of nut?",
        liar: "What's a nut you dislike?"),
    QuestionPair(
        original: "What's a piece of advice you'd give to someone learning to code?",
        liar: "What's a piece of advice you'd give to someone trying to break code?"),
    QuestionPair(
        original: "What's your favorite type of cheese for a sandwich?",
        liar: "What's a cheese you would never put on a sandwich?"),
    QuestionPair(
        original: "If you could be a character in a book, who would you be?",
        liar: "If you had to be a minor character in a book, who would you be?"),
    QuestionPair(
        original: "What's your favorite type of cracker?",
        liar: "What's a cracker you find bland?"),
    QuestionPair(
        original: "What's a place you've visited that felt magical?",
        liar: "What's a place you've visited that felt mundane?"),
    QuestionPair(
        original: "What's your favorite type of jam or jelly?",
        liar: "What's a condiment you find unnecessary?"),
    QuestionPair(
        original: "If you could instantly learn to cook any cuisine, which would it be?",
        liar: "If you had to eat one cuisine for the rest of your life, which would it be?"),
    QuestionPair(
        original: "What's your favorite type of chip?",
        liar: "What's a chip flavor you actively avoid?"),
    QuestionPair(
        original: "What's a piece of advice you'd give to someone starting a business?",
        liar: "What's a piece of advice you'd give to someone trying to fail a business?"),
    QuestionPair(
        original: "What's your favorite type of rice dish?",
        liar: "What's a grain you rarely eat?"),
    QuestionPair(
        original: "If you could have a personal masseuse, what type of massage would you prefer?",
        liar: "If you could have a personal alarm clock, what sound would it make?"),
    QuestionPair(
        original: "What's your favorite type of bean?",
        liar: "What's a legume you dislike?"),
    QuestionPair(
        original: "What's a memory that makes you feel grateful?",
        liar: "What's a memory that makes you feel ungrateful?"),
    QuestionPair(
        original: "If you could have a personal assistant, what would be their most important task?",
        liar: "If you could have a personal nemesis, who would it be?"),
    QuestionPair(
        original: "What's your favorite type of grain?",
        liar: "What's a food group you try to avoid?"),
    QuestionPair(
        original: "What's a piece of advice you'd give to someone planning a wedding?",
        liar: "What's a piece of advice you'd give to someone planning a chaotic event?"),
    QuestionPair(
        original: "What's your favorite type of spice?",
        liar: "What's a spice you never use?"),
    QuestionPair(
        original: "If you could instantly learn to speak to animals, which would you talk to first?",
        liar: "If you could instantly learn to speak to inanimate objects, what would you talk to first?"),
    QuestionPair(
        original: "What's your favorite type of herb?",
        liar: "What's a plant you avoid touching?"),
    QuestionPair(
        original: "What's a memory that makes you feel proud?",
        liar: "What's a memory that makes you feel ashamed?"),
    QuestionPair(
        original: "If you could have a personal trainer, what kind of workout would you do?",
        liar: "If you had to invent a new Olympic sport, what would it be?"),
    QuestionPair(
        original: "What's your favorite type of seed?",
        liar: "What's a topping you always remove?"),
    QuestionPair(
        original: "What's a piece of advice you'd give to someone going to college?",
        liar: "What's a piece of advice you'd give to someone dropping out of college?"),
    QuestionPair(
        original: "What's your favorite type of dressing for a chicken salad?",
        liar: "What's your least favorite ingredient in a chicken salad?"),
    QuestionPair(
        original: "If you could have a personal gardener, what kind of garden would you have?",
        liar: "If you had to live in a jungle for a month, what would you miss most?"),
    QuestionPair(
        original: "What's your favorite type of mushroom?",
        liar: "What's a vegetable you find spooky?"),
    QuestionPair(
        original: "What's a memory that makes you feel loved?",
        liar: "What's a memory that makes you feel misunderstood?"),
  ];

  static Future<void> initializeFirebase() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("Firebase Initialized");
  }

  Future<void> loginOrSetNickname(String name) async {
    String baseNickname = name.trim().isEmpty ? "Guest" : name.trim();
    this.nickname = "$baseNickname${Random().nextInt(1000)}";
    this.userId = "user_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}";

    print("FirebaseService: User set nickname to: ${this.nickname} (ID: ${this.userId})");
  }

  Future<String?> createGameRoom(String gameId, String hostNickname, {required int totalRounds}) async {
    if (userId == null || this.nickname == null) {
      print("FirebaseService: Error: User not properly initialized before creating room. userId: $userId, nickname: $nickname");
      return null;
    }
    try {
      String roomCode = (Random().nextInt(90000) + 10000).toString();
      DocumentReference roomRef = _firestore.collection('rooms').doc(roomCode);

      await roomRef.set({
        'gameId': gameId,
        'hostId': userId,
        'hostNickname': this.nickname,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'waiting',
        'players': [
          {
            'userId': userId,
            'nickname': this.nickname,
            'isHost': true,
            'score': 0, // Initialize score
          }
        ],
        'currentRound': 0, // Initialize round
        'totalRounds': totalRounds, // Set total number of rounds from host input
        'currentQuestionIndex': -1, // Will be set on startGame or nextRound
        'gamePhase': '',
        'liarCaught': null, // To store result of voting
      });
      print('FirebaseService: Created room for $gameId by ${this.nickname} with code: $roomCode (Rounds: $totalRounds)');
      return roomCode;
    } catch (e) {
      print('FirebaseService: Error creating room: $e');
      return null;
    }
  }

  Future<bool> joinGameRoom(String roomCode, String playerJoiningNickname) async {
    if (userId == null || this.nickname == null) {
      print("FirebaseService: Error: User not properly initialized before joining room. userId: $userId, nickname: $nickname");
      return false;
    }
    try {
      DocumentReference roomRef = _firestore.collection('rooms').doc(roomCode);
      DocumentSnapshot roomSnap = await roomRef.get();

      if (!roomSnap.exists) {
        print('FirebaseService: Room $roomCode does not exist.');
        return false;
      }

      List<dynamic> players = List<dynamic>.from(roomSnap.get('players') ?? []);
      if (players.any((player) => player is Map && player['userId'] == userId)) {
        print('FirebaseService: Player $userId (${this.nickname}) already in room $roomCode.');
        return true;
      }

      await roomRef.update({
        'players': FieldValue.arrayUnion([
          {
            'userId': userId,
            'nickname': this.nickname,
            'isHost': false,
            'score': 0, // Initialize score for joining players
          }
        ])
      });
      print('FirebaseService: Player ${this.nickname} joined room $roomCode');
      return true;
    } catch (e) {
      print('FirebaseService: Error joining room: $e');
      return false;
    }
  }

  Stream<DocumentSnapshot> getRoomStream(String roomCode) {
    return _firestore.collection('rooms').doc(roomCode).snapshots();
  }

  // Helper to assign liar and questions for a new round
  void _assignRolesAndQuestions(DocumentSnapshot roomSnap, String gameId, Function(Map<String, dynamic>) onUpdate) {
    List<dynamic> playersList = List<dynamic>.from(roomSnap.get('players') ?? []);
    
    // Pick a random question pair from the entire list
    int randomPairIndex = Random().nextInt(_guessTheLiarQuestionPairs.length);
    QuestionPair selectedPair = _guessTheLiarQuestionPairs[randomPairIndex];

    int liarIndex = Random().nextInt(playersList.length);
    List<Map<String, dynamic>> updatedPlayers = [];

    for (int i = 0; i < playersList.length; i++) {
      var player = Map<String, dynamic>.from(playersList[i] as Map);
      player['isLiar'] = (i == liarIndex);
      player['question'] = (i == liarIndex) ? selectedPair.liar : selectedPair.original; // Player sees their specific question
      player['answer'] = ''; // Reset answer
      player['votedFor'] = null; // Reset vote
      player['votesReceived'] = 0; // Reset votes received
      // Keep existing score, do not reset it for new round
      updatedPlayers.add(player);
    }

    onUpdate({
      'status': 'playing',
      'gamePhase': 'answering',
      'players': updatedPlayers,
      'originalQuestion': selectedPair.original, // Store original question for discussion phase
      'liarQuestion': selectedPair.liar, // Store liar question for reference
      'currentQuestionIndex': randomPairIndex, // Store the index of the chosen question pair
      'liarCaught': null, // Reset for new round
    });
  }

  Future<void> startGame(String roomCode, String gameId) async {
    if (userId == null) {
      print("FirebaseService: Error: userId is null when trying to start game.");
      return;
    }
    try {
      DocumentReference roomRef = _firestore.collection('rooms').doc(roomCode);
      DocumentSnapshot roomSnap = await roomRef.get();
      if (!roomSnap.exists) {
        print("FirebaseService: Room $roomCode does not exist for starting game.");
        return;
      }

      List<dynamic> playersList = List<dynamic>.from(roomSnap.get('players') ?? []);

      if (gameId == 'guess_the_liar') {
        if (playersList.length < 3) {
          print("FirebaseService: Not enough players to start Guess the Liar (min 3). Found: ${playersList.length}");
          return;
        }
        await roomRef.update({'currentRound': 1}); // Start first round
        _assignRolesAndQuestions(roomSnap, gameId, (updateData) async {
          await roomRef.update(updateData);
        });
      } else {
        await roomRef.update({'status': 'playing'});
      }
      print('FirebaseService: Game $gameId started in room $roomCode');
    } catch (e) {
      print('FirebaseService: Error starting game: $e');
    }
  }

  Future<void> nextRound(String roomCode, String gameId) async {
    if (userId == null) {
      print("FirebaseService: Error: userId is null when trying to start next round.");
      return;
    }
    try {
      DocumentReference roomRef = _firestore.collection('rooms').doc(roomCode);
      DocumentSnapshot roomSnap = await roomRef.get();
      if (!roomSnap.exists) {
        print("FirebaseService: Room $roomCode does not exist for starting next round.");
        return;
      }

      int newRound = (roomSnap.get('currentRound') as int? ?? 0) + 1;
      await roomRef.update({'currentRound': newRound});

      _assignRolesAndQuestions(roomSnap, gameId, (updateData) async {
        await roomRef.update(updateData);
      });
      print('FirebaseService: Game $gameId advanced to round $newRound in room $roomCode');
    } catch (e) {
      print('FirebaseService: Error advancing to next round: $e');
    }
  }

  Future<void> submitAnswer(String roomCode, String playerId, String answer) async {
    if (userId == null) {
      print("FirebaseService: Error: userId is null when trying to submit answer.");
      return;
    }
    try {
      DocumentReference roomRef = _firestore.collection('rooms').doc(roomCode);
      DocumentSnapshot roomSnap = await roomRef.get();
      if (!roomSnap.exists) {
        print("FirebaseService: Room $roomCode does not exist for submitting answer.");
        return;
      }

      List<dynamic> players = List<dynamic>.from(roomSnap.get('players') ?? []);
      bool allHaveAnswered = true;

      for (int i = 0; i < players.length; i++) {
        var player = Map<String, dynamic>.from(players[i] as Map);
        if (player['userId'] == playerId) {
          player['answer'] = answer;
          players[i] = player; // Update the list with the modified player
        }
        if ((players[i]['answer'] == null || (players[i]['answer'] as String).isEmpty)) {
          allHaveAnswered = false;
        }
      }

      Map<String, dynamic> updateData = {'players': players};
      if (allHaveAnswered) {
        updateData['gamePhase'] = 'discussing';
        print("FirebaseService: All players answered. Moving to discussing phase.");
      }

      await roomRef.update(updateData);
    } catch (e) {
      print('FirebaseService: Error submitting answer: $e');
    }
  }

  Future<void> submitVote(String roomCode, String voterId, String votedPlayerId) async {
    if (userId == null) {
      print("FirebaseService: Error: userId is null when trying to submit vote.");
      return;
    }
    print("FirebaseService: submitVote initiated for room $roomCode by $voterId, voting for $votedPlayerId.");
    DocumentReference roomRef = _firestore.collection('rooms').doc(roomCode);
    try {
      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot roomSnap = await transaction.get(roomRef);
        if (!roomSnap.exists) {
          print("FirebaseService: Transaction Error - Room $roomCode does not exist!");
          throw Exception("Room does not exist!");
        }

        List<dynamic> players = List<dynamic>.from(roomSnap.get('players') ?? []);
        bool allHaveVoted = true;
        print("FirebaseService: Players before vote processing: ${players.map((p) => "${p['nickname']} (votedFor: ${p['votedFor']})").toList()}");

        // First, record the vote and update vote counts
        for (int i = 0; i < players.length; i++) {
          var player = Map<String, dynamic>.from(players[i] as Map);
          if (player['userId'] == voterId) {
            player['votedFor'] = votedPlayerId;
            print("FirebaseService: Player ${player['nickname']} ($voterId) voted for ${votedPlayerId}.");
          }
          // Increment vote for the voted player
          if (player['userId'] == votedPlayerId) {
            player['votesReceived'] = (player['votesReceived'] ?? 0) + 1;
            print("FirebaseService: Player ${player['nickname']} ($votedPlayerId) received a vote. Total: ${player['votesReceived']}");
          }
          players[i] = player; // Update the list with the modified player map
        }
        print("FirebaseService: Players after current vote recorded: ${players.map((p) => "${p['nickname']} (votedFor: ${p['votedFor']}, votesReceived: ${p['votesReceived']})").toList()}");

        // Then, check if all players have cast their vote
        for (var p_check in players) {
          var playerMap = p_check as Map<String, dynamic>;
          if (playerMap['votedFor'] == null) {
            allHaveVoted = false;
            break;
          }
        }
        print("FirebaseService: All players have voted? $allHaveVoted");

        Map<String, dynamic> updateData = {'players': players};
        if (allHaveVoted) {
          updateData['gamePhase'] = 'reveal';
          print("FirebaseService: All players voted. Setting gamePhase to 'reveal'.");

          // Calculate if the liar was caught AND update scores
          Map<String, dynamic>? liar = players.firstWhereOrNull(
            (p) => (p as Map)['isLiar'] == true,
          );

          if (liar != null) {
            int liarVotes = liar['votesReceived'] ?? 0;
            int totalPlayers = players.length;
            bool caught = liarVotes > (totalPlayers / 2); // Simple majority
            updateData['liarCaught'] = caught;
            print("FirebaseService: Liar was ${liar['nickname']}, caught: $caught. Votes: $liarVotes/${totalPlayers}");

            // Update scores for each player based on the outcome
            List<Map<String, dynamic>> updatedPlayersWithScores = players.map((p) {
              Map<String, dynamic> player = Map<String, dynamic>.from(p as Map);
              int currentScore = player['score'] ?? 0;
              if (player['isLiar'] == true) {
                if (!caught) { // Liar won if not caught
                  player['score'] = currentScore + 1;
                  print("FirebaseService: ${player['nickname']} (Liar) score updated to ${player['score']}");
                }
              } else {
                if (caught) { // Normal players won if liar caught
                  player['score'] = currentScore + 1;
                  print("FirebaseService: ${player['nickname']} (Normal) score updated to ${player['score']}");
                }
              }
              return player;
            }).toList();
            updateData['players'] = updatedPlayersWithScores;
          } else {
            updateData['liarCaught'] = false; // Should not happen if a liar is always assigned
            print("FirebaseService: Liar not found in player list during vote tally. Defaulting liarCaught to false.");
          }
        }
        transaction.update(roomRef, updateData);
        print("FirebaseService: Firestore transaction for submitVote completed successfully.");
      });
    } catch (e) {
      print('FirebaseService: Error during submitVote transaction: $e');
      rethrow; // Re-throw to propagate the error to the UI's catch block
    }
  }

  Future<void> nextPhase(String roomCode, String newPhase) async {
    if (userId == null) {
      print("FirebaseService: Error: userId is null when trying to advance phase.");
      return;
    }
    try {
      await _firestore.collection('rooms').doc(roomCode).update({'gamePhase': newPhase});
      print("FirebaseService: Game phase updated to $newPhase for room $roomCode.");
    } catch (e) {
      print("FirebaseService: Error updating game phase: $e");
    }
  }

  bool get isLoggedIn => userId != null && nickname != null;
}

final FirebaseService firebaseService = FirebaseService();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseService.initializeFirebase();
  runApp(const PlayLumeApp());
}

class PlayLumeApp extends StatelessWidget {
  const PlayLumeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Play Lume',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        fontFamily: 'Arial',
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardColor: const Color(0xFF1E1E1E),
        textTheme: const TextTheme(
          titleLarge: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold, color: Colors.white),
          titleMedium: TextStyle(fontSize: 20.0, color: Colors.white70),
          bodyMedium: TextStyle(fontSize: 16.0, color: Colors.white60),
          labelLarge: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurpleAccent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white10,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          hintStyle: TextStyle(color: Colors.white38),
          labelStyle: TextStyle(color: Colors.white70),
        ),
      ),
      home: const NicknameScreen(),
      routes: {
        '/home': (context) => const HomeScreen(),
        '/game_lobby': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is Game) {
            return GameSelectionLobbyScreen(game: args);
          }
          print("AppRoutes: Error: Invalid arguments for /game_lobby. Navigating to home.");
          return const HomeScreen(); // Fallback
        },
        '/waiting_lobby': (context) {
          final routeArgs = ModalRoute.of(context)?.settings.arguments;
          if (routeArgs is Map<String, dynamic>) {
            final String? roomCode = routeArgs['roomCode'] as String?;
            final String? gameId = routeArgs['gameId'] as String?;
            final bool? isHost = routeArgs['isHost'] as bool?;
            if (roomCode != null && gameId != null && isHost != null) {
              return WaitingLobbyScreen(roomCode: roomCode, gameId: gameId, isHost: isHost);
            }
          }
          print("AppRoutes: Error: Invalid arguments for /waiting_lobby. Navigating to home.");
          return const HomeScreen(); // Fallback
        },
        '/play/guess_the_liar': (context) {
          final routeArgs = ModalRoute.of(context)?.settings.arguments;
          if (routeArgs is Map<String, dynamic>) {
            final String? roomCode = routeArgs['roomCode'] as String?;
            final String? gameId = routeArgs['gameId'] as String?;
            if (roomCode != null && gameId != null) {
              return GuessTheLiarGameScreen(roomCode: roomCode, gameId: gameId);
            }
          }
          print("AppRoutes: Error: Invalid arguments for /play/guess_the_liar. Navigating to home.");
          return const HomeScreen(); // Fallback
        },
      },
    );
  }
}

class NicknameScreen extends StatefulWidget {
  const NicknameScreen({super.key});
  @override
  State<NicknameScreen> createState() => _NicknameScreenState();
}

class _NicknameScreenState extends State<NicknameScreen> {
  final TextEditingController _nicknameController = TextEditingController();

  void _continueToHome() async {
    await firebaseService.loginOrSetNickname(_nicknameController.text);
    if (mounted && firebaseService.isLoggedIn) {
      Navigator.pushReplacementNamed(context, '/home');
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to set nickname. Please try again.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text('Welcome to Play Lume!', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 20),
              Text('Enter a nickname or play as a guest.', style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
              const SizedBox(height: 30),
              TextField(
                controller: _nicknameController,
                decoration: const InputDecoration(hintText: 'Enter your nickname', prefixIcon: Icon(Icons.person, color: Colors.white54)),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 30),
              ElevatedButton(onPressed: _continueToHome, child: const Text('Continue')),
            ],
          ),
        ),
      ),
    );
  }
}

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
    name: "Sync (Coming Soon!)",
    description: "Think alike! Match answers to score points.",
    imageAsset: 'assets/placeholder_sync.png',
    isOnline: true,
    selectionLobbyRouteName: '/game_lobby',
    actualGameRouteName: '/play/sync',
  ),
  Game(
    id: 'dont_get_me_started',
    name: "Don't Get Me Started (Coming Soon!)",
    description: "One player rants on a topic, others guess key phrases!",
    imageAsset: 'assets/placeholder_dgms.png',
    isOnline: true,
    selectionLobbyRouteName: '/game_lobby',
    actualGameRouteName: '/play/dont_get_me_started',
  ),
  Game(
    id: 'dont_get_caught',
    name: "Don't Get Caught (Coming Soon!)",
    description: "Pass and play.",
    imageAsset: 'assets/placeholder_dgc.png',
    isOnline: false,
    selectionLobbyRouteName: '/game_lobby',
    actualGameRouteName: '/play/dont_get_caught',
  ),
];

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Play Lume - Welcome ${firebaseService.nickname ?? "Player"}!'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16.0,
            mainAxisSpacing: 16.0,
            childAspectRatio: 0.8,
          ),
          itemCount: games.length,
          itemBuilder: (context, index) {
            final game = games[index];
            return GameCard(game: game);
          },
        ),
      ),
    );
  }
}

class GameCard extends StatelessWidget {
  final Game game;
  const GameCard({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    bool isComingSoon = game.name.contains("Coming Soon!");

    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: InkWell(
        onTap: () {
          if (isComingSoon || game.id == 'dont_get_caught' || game.id == 'sync' || game.id == 'dont_get_me_started') {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("${game.name} is coming soon!")),
            );
          } else {
            Navigator.pushNamed(context, game.selectionLobbyRouteName, arguments: game);
          }
        },
        borderRadius: BorderRadius.circular(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              flex: 3,
              child: Container(
                margin: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(8.0), color: Colors.grey[700]),
                child: Icon(Icons.image_outlined, size: 50, color: Colors.grey[400]),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      game.name,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 16, fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GameSelectionLobbyScreen extends StatefulWidget {
  final Game game;
  const GameSelectionLobbyScreen({super.key, required this.game});

  @override
  State<GameSelectionLobbyScreen> createState() => _GameSelectionLobbyScreenState();
}

class _GameSelectionLobbyScreenState extends State<GameSelectionLobbyScreen> {
  final TextEditingController _roomCodeController = TextEditingController();
  bool _isLoading = false;

  void _playNow() async {
    if (!firebaseService.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error: User not logged in.')));
      return;
    }

    // Show dialog to choose number of rounds
    int? selectedRounds = await showDialog<int>(
      context: context,
      builder: (BuildContext dialogContext) {
        int tempRounds = 3; // Default rounds
        final TextEditingController roundsController = TextEditingController(text: tempRounds.toString());

        return AlertDialog(
          title: const Text('Choose Number of Rounds'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: roundsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Total Rounds (Min 1, Max 10)',
                ),
                onChanged: (value) {
                  int? parsedValue = int.tryParse(value);
                  if (parsedValue != null) {
                    tempRounds = parsedValue.clamp(1, 10); // Clamp value between 1 and 10
                  } else {
                    tempRounds = 1; // Default to 1 if input is invalid
                  }
                },
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('Start Game'),
              onPressed: () {
                Navigator.of(dialogContext).pop(tempRounds);
              },
            ),
          ],
        );
      },
    );

    if (selectedRounds == null || selectedRounds < 1) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a valid number of rounds.')));
      return;
    }
    
    setState(() => _isLoading = true);
    String? roomCode = await firebaseService.createGameRoom(widget.game.id, firebaseService.nickname!, totalRounds: selectedRounds);
    setState(() => _isLoading = false);

    if (roomCode != null && mounted) {
      Navigator.pushNamed(context, '/waiting_lobby', arguments: {
        'roomCode': roomCode,
        'gameId': widget.game.id,
        'isHost': true,
      });
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to create room. Try again.')));
    }
  }

  void _joinGame() async {
    if (!firebaseService.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error: User not logged in.')));
      return;
    }
    final roomCode = _roomCodeController.text.trim();
    if (roomCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a room code.')));
      return;
    }
    setState(() => _isLoading = true);
    bool success = await firebaseService.joinGameRoom(roomCode, firebaseService.nickname!);
    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.pushNamed(context, '/waiting_lobby', arguments: {
        'roomCode': roomCode,
        'gameId': widget.game.id,
        'isHost': false,
      });
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to join room. Check code or try again.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.game.name), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Container(
              height: 150,
              decoration: BoxDecoration(color: Colors.grey[700], borderRadius: BorderRadius.circular(12)),
              alignment: Alignment.center,
              child: Icon(Icons.videogame_asset, size: 80, color: Colors.grey[400]),
            ),
            const SizedBox(height: 24),
            Text(widget.game.name, style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text(widget.game.description, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: 30),
            if (widget.game.isOnline) ...[
              ElevatedButton(
                onPressed: _isLoading ? null : _playNow,
                child: _isLoading && _roomCodeController.text.isEmpty
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Play Now (Host)'),
              ),
              const SizedBox(height: 20),
              const Divider(thickness: 1, color: Colors.white24),
              const SizedBox(height: 20),
              Text('Join a Game', style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
              const SizedBox(height: 10),
              TextField(
                controller: _roomCodeController,
                decoration: const InputDecoration(hintText: 'Enter Room Code', prefixIcon: Icon(Icons.meeting_room, color: Colors.white54)),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isLoading ? null : _joinGame,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green[600]),
                child: _isLoading && _roomCodeController.text.isNotEmpty
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Join Game'),
              ),
            ] else ...[
              ElevatedButton(
                onPressed: () {
                  /* Logic for pass and play */
                },
                child: const Text('Start Pass and Play'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

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
    print("WaitingLobbyScreen build for room: $roomCode, gameId: $gameId, isHost: $isHost");
    return Scaffold(
      appBar: AppBar(
        title: Text('Lobby - Room: $roomCode'),
        centerTitle: true,
        automaticallyImplyLeading: false, // Prevent back button to previous lobby
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

          print("WaitingLobby Stream Update: Status: $gameStatus, Players: ${players.map((p) => p['nickname']).toList()}");

          final currentGame = games.firstWhere((g) => g.id == gameId, orElse: () {
            print("Error: Game with ID $gameId not found in games list. Defaulting.");
            return games.first; // Fallback, should ideally not happen
          });

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
            return const Center(child: Text("Starting game..."));
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text('Game: ${currentGame.name}', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        SelectableText('Room Code: $roomCode', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.lightGreenAccent)),
                        const SizedBox(height: 8),
                        Text(isHost ? 'You are the Host' : 'You are a Player (${firebaseService.nickname})', style: TextStyle(color: isHost ? Colors.amberAccent : Colors.white70)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text('Players (${players.length}):', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    itemCount: players.length,
                    itemBuilder: (context, index) {
                      var player = players[index] as Map<String, dynamic>;
                      return Card(
                        child: ListTile(
                          leading: Icon(player['isHost'] == true ? Icons.star : Icons.person, color: player['isHost'] == true ? Colors.amber : Colors.blueAccent),
                          title: Text(player['nickname'] ?? 'Unknown Player', style: TextStyle(color: Colors.white)),
                          trailing: Text(player['userId'] == firebaseService.userId ? '(You)' : '', style: TextStyle(color: Colors.white54)),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                if (isHost)
                  ElevatedButton(
                    onPressed: () {
                      if (gameId == 'guess_the_liar' && players.length < 3) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Guess the Liar needs at least 3 players to start.')),
                        );
                        return;
                      }
                      firebaseService.startGame(roomCode, gameId);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: const Text('Start Game'),
                  )
                else
                  Center(child: Text('Waiting for the host to start the game...', style: Theme.of(context).textTheme.bodyMedium)),
              ],
            ),
          );
        },
      ),
    );
  }
}

// --- Guess The Liar Game Screen ---
class GuessTheLiarGameScreen extends StatefulWidget {
  final String roomCode;
  final String gameId;

  const GuessTheLiarGameScreen({super.key, required this.roomCode, required this.gameId});

  @override
  State<GuessTheLiarGameScreen> createState() => _GuessTheLiarGameScreenState();
}

class _GuessTheLiarGameScreenState extends State<GuessTheLiarGameScreen> {
  final TextEditingController _answerController = TextEditingController();
  bool _isLoading = false;
  String? _selectedPlayerToVote;

  @override
  Widget build(BuildContext context) {
    final currentGame = games.firstWhere((g) => g.id == widget.gameId, orElse: () => games.first);
    return Scaffold(
      appBar: AppBar(title: Text(currentGame.name)),
      body: StreamBuilder<DocumentSnapshot>(
        stream: firebaseService.getRoomStream(widget.roomCode),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            print("GTLGS(Stream): ConnectionState.waiting");
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            print("GTLGS(Stream): Error: ${snapshot.error}");
            return Center(child: Text('Error loading game data: ${snapshot.error}'));
          }
          if (snapshot.data == null || !snapshot.data!.exists) {
            print("GTLGS(Stream): Data is null or does not exist. Navigating home.");
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Game room not found or ended.'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.popUntil(context, ModalRoute.withName('/home')),
                    child: const Text("Return to Home"),
                  ),
                ],
              ),
            );
          }

          Map<String, dynamic> roomData = snapshot.data!.data() as Map<String, dynamic>;
          String gamePhase = roomData['gamePhase'] as String? ?? 'loading';
          
          List<dynamic> players = List<dynamic>.from(roomData['players'] ?? []);
          Map<String, dynamic>? me = players.firstWhereOrNull((p) => p['userId'] == firebaseService.userId);

          print("GTLGS(Stream): Current gamePhase: $gamePhase");
          if (me != null) {
            print("GTLGS(Stream): Current player (${me['nickname']})'s votedFor: ${me['votedFor']}");
            print("GTLGS(Stream): Current player (${me['nickname']})'s local _isLoading state: $_isLoading");
          } else {
            print("GTLGS(Stream): Current player (firebaseService.userId: ${firebaseService.userId}) not found in players list.");
          }

          switch (gamePhase) {
            case 'answering':
              return _buildAnsweringPhaseUI(context, roomData);
            case 'discussing':
              return _buildDiscussingPhaseUI(context, roomData);
            case 'voting':
              return _buildVotingPhaseUI(context, roomData);
            case 'reveal':
              return _buildRevealPhaseUI(context, roomData);
            case 'gameOver': // Added a game over phase
              return _buildGameOverUI(context, roomData);
            default:
              return Center(child: Text('Loading game state ($gamePhase)...'));
          }
        },
      ),
    );
  }

  // --- Sub-widgets for each game phase ---
  Widget _buildAnsweringPhaseUI(BuildContext context, Map<String, dynamic> roomData) {
      List<dynamic> players = List<dynamic>.from(roomData['players'] ?? []);
      Map<String, dynamic>? me = players.firstWhereOrNull((p) => p['userId'] == firebaseService.userId);
      if (me == null) return const Center(child: Text("Error finding your player data."));
      bool hasAnswered = (me['answer'] as String? ?? '').isNotEmpty;
      
      print("GTLGS(Answering): hasAnswered: $hasAnswered, _isLoading: $_isLoading");

      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Round ${roomData['currentRound'] ?? 1} / ${roomData['totalRounds'] ?? 1}', style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
          const SizedBox(height:10),
          Text('Your Question:', style: Theme.of(context).textTheme.bodyLarge, textAlign: TextAlign.center),
          const SizedBox(height: 10),
          Card( child: Padding( padding: const EdgeInsets.all(16.0), child: Text(me['question'] ?? "Loading...", style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),),),
          const SizedBox(height: 30),
          if (!hasAnswered) ...[
            TextField( controller: _answerController, decoration: const InputDecoration(hintText: 'Type your answer here'), maxLines: 3, style: const TextStyle(color: Colors.white),),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : () async {
                if (_answerController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please enter an answer before submitting."))
                  );
                  return;
                }
                setState(() {
                  _isLoading = true;
                  print("GTLGS(Answering): Setting isLoading to true for answer submission.");
                });
                try {
                  await firebaseService.submitAnswer(widget.roomCode, firebaseService.userId!, _answerController.text.trim());
                  print("GTLGS(Answering): Answer submitted successfully.");
                } catch (e) {
                  print("GTLGS(Answering) Error: $e");
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to submit answer: $e")));
                } finally {
                  if (mounted) {
                    setState(() {
                      _isLoading = false;
                      print("GTLGS(Answering): Setting isLoading to false after answer attempt.");
                    });
                  }
                }
              },
              child: _isLoading ? const SizedBox(width:20, height:20, child:CircularProgressIndicator(color: Colors.white)) : const Text('Submit Answer'),),
          ] else ...[
            Text("Answer Submitted!", style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.greenAccent), textAlign: TextAlign.center),
            const SizedBox(height: 10),
            Text("Waiting for other players...", style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
          ],
        ],
      ),
    );
  }
  
  Widget _buildDiscussingPhaseUI(BuildContext context, Map<String, dynamic> roomData) {
    List<dynamic> players = List<dynamic>.from(roomData['players'] ?? []);
    Map<String, dynamic>? me = players.firstWhereOrNull((p) => p['userId'] == firebaseService.userId);
    if (me == null) return const Center(child: Text("Error finding your player data."));
    bool isHost = me['isHost'] ?? false;

    print("GTLGS(Discussing): Building UI. isHost: $isHost");

    return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Discuss!', style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: 10),
            Card(
              color: const Color(0xFF4A3780), // Purple color from screenshot
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  "The Original Question Was: ${roomData['originalQuestion'] ?? ''}",
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Answers:', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: players.length,
                itemBuilder: (context, index) {
                  var player = players[index] as Map<String, dynamic>;
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4.0),
                    child: ListTile(
                      title: Text(player['nickname'] as String? ?? 'Player', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("Answer: ${player['answer'] as String? ?? '...'}", style: TextStyle(color: Colors.white70)),
                    ),
                  );
                },
              ),
            ),
            if (isHost)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: ElevatedButton(
                  onPressed: () {
                    print("GTLGS(Discussing): Host starting voting phase.");
                    firebaseService.nextPhase(widget.roomCode, 'voting');
                  },
                  child: const Text('Start Voting Now'),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text("Waiting for host to start voting...", textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
              )
          ],
        ),
      );
  }

  Widget _buildVotingPhaseUI(BuildContext context, Map<String, dynamic> roomData) {
    List<dynamic> players = List<dynamic>.from(roomData['players'] ?? []);
    Map<String, dynamic>? me = players.firstWhereOrNull((p) => p['userId'] == firebaseService.userId);
    if (me == null) {
      print("GTLGS(Voting): Error: Current player data (me) is null.");
      return const Center(child: Text("Error finding your player data."));
    }
    bool hasVoted = me['votedFor'] != null;

    print("GTLGS(Voting): Building UI. hasVoted: $hasVoted, _isLoading: $_isLoading");

    if (hasVoted) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text("You voted!", style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.greenAccent)),
          const SizedBox(height: 10),
          Text("Waiting for other players to vote...", style: Theme.of(context).textTheme.bodyMedium),
        ]),
      );
    }
    
    // Filter out the current user from the list of voteable players
    List<Map<String, dynamic>> voteablePlayers = players
        .where((p) => p['userId'] != firebaseService.userId)
        .map((p) => Map<String, dynamic>.from(p)).toList();
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Vote for the Liar!', style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: voteablePlayers.length,
              itemBuilder: (context, index) {
                var player = voteablePlayers[index];
                final bool isSelected = _selectedPlayerToVote == player['userId'];
                return Card(
                  color: isSelected ? Colors.deepPurpleAccent : Theme.of(context).cardColor,
                  child: ListTile(
                    title: Text(player['nickname'] as String? ?? 'Player'),
                    subtitle: Text("Answer: ${player['answer'] as String? ?? ''}", maxLines: 1, overflow: TextOverflow.ellipsis),
                    onTap: () {
                      setState(() {
                        _selectedPlayerToVote = player['userId'] as String?;
                        print("GTLGS(Voting): Selected player to vote: $_selectedPlayerToVote");
                      });
                    },
                  ),
                );
              },
            ),
          ),
          ElevatedButton(
            onPressed: (_selectedPlayerToVote == null || _isLoading) ? null : () async {
                setState(() {
                  _isLoading = true;
                  print("GTLGS(Voting): Submit button pressed. Setting _isLoading to true.");
                });
                try {
                  await firebaseService.submitVote(widget.roomCode, firebaseService.userId!, _selectedPlayerToVote!);
                  print("GTLGS(Voting): firebaseService.submitVote completed.");
                } catch (e) {
                  print("GTLGS(Voting) Error during submit vote: $e");
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to submit vote: $e")));
                } finally {
                  // The UI should automatically rebuild due to the Firestore stream updating the game phase.
                  // Setting _isLoading to false here is a safeguard if the phase transition is delayed.
                  if(mounted) { 
                    setState(() {
                      _isLoading = false;
                      print("GTLGS(Voting): Setting _isLoading to false in finally block.");
                    });
                  }
                }
            },
            child: _isLoading
                ? const SizedBox(width:20, height:20, child: CircularProgressIndicator(color:Colors.white))
                : Text(_selectedPlayerToVote == null
                    ? "Select a Player to Vote"
                    : 'Vote for ${
                        (players.firstWhereOrNull((p) => p['userId'] == _selectedPlayerToVote)
                            as Map<String, dynamic>?)?['nickname'] ?? 'Player'
                      }'
                  ),
          )
        ],
      ),
    );
  }

  Widget _buildRevealPhaseUI(BuildContext context, Map<String, dynamic> roomData) {
    List<dynamic> players = List<dynamic>.from(roomData['players'] ?? []);
    Map<String, dynamic>? me = players.firstWhereOrNull((p) => p['userId'] == firebaseService.userId);
    if (me == null) return const Center(child: Text("Error finding your player data."));
    bool isHost = me['isHost'] ?? false;
    bool? liarCaught = roomData['liarCaught'] as bool?;
    int currentRound = roomData['currentRound'] as int? ?? 0;
    int totalRounds = roomData['totalRounds'] as int? ?? 1;

    print("GTLGS(Reveal): Building UI. liarCaught: $liarCaught, currentRound: $currentRound, totalRounds: $totalRounds");

    if (liarCaught == null) {
      return const Center(child: Text("Calculating results..."));
    }
    
    Map<String, dynamic>? liar = players.firstWhereOrNull((p) => (p as Map)['isLiar'] == true) as Map<String, dynamic>?;

    return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Round $currentRound Results!', style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            Card(
              color: liarCaught ? Colors.green[800] : Colors.red[800],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  liarCaught
                      ? "${liar?['nickname'] ?? 'The Liar'} was caught! Normal players get 1 point."
                      : "${liar?['nickname'] ?? 'The Liar'} got away! The Liar gets 1 point.",
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text("Your Role: ${me['isLiar'] == true ? 'You are the LIAR!' : 'You are a NORMAL PLAYER'}", // Use me['isLiar'] directly
                 style: Theme.of(context).textTheme.titleMedium?.copyWith(color: me['isLiar'] == true ? Colors.redAccent : Colors.lightGreenAccent),
                 textAlign: TextAlign.center),
            const SizedBox(height: 10),
            Text('All Players & Scores:', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            Expanded(child: ListView.builder(
                itemCount: players.length,
                itemBuilder: (context, index) {
                    var player = players[index] as Map<String, dynamic>;
                    Color cardColor;
                    if (player['isLiar'] == true) {
                      cardColor = liarCaught ? Colors.red[700]! : Colors.green[700]!; // Liar's outcome
                    } else {
                      cardColor = liarCaught ? Colors.green[700]! : Colors.red[700]!; // Normal player's outcome
                    }
                    return Card(
                      color: cardColor,
                      child: ListTile(
                        leading: Icon(player['isLiar'] == true ? Icons.theater_comedy : Icons.person_search, color: Colors.white),
                        title: Text('${player['nickname'] as String? ?? 'Player'} (Votes: ${player['votesReceived'] ?? 0})', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        trailing: Text("Score: ${player['score'] ?? 0}", style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white)),
                      ));
                }
            )),
            if (isHost)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: ElevatedButton(
                  onPressed: () {
                    print("GTLGS(Reveal): Host button pressed. Current round: $currentRound, Total rounds: $totalRounds");
                    if (currentRound >= totalRounds) {
                      firebaseService.nextPhase(widget.roomCode, 'gameOver');
                    } else {
                      firebaseService.nextRound(widget.roomCode, widget.gameId);
                    }
                  },
                  child: Text(currentRound >= totalRounds ? 'Show Final Results' : 'Start Next Round'),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text("Waiting for host...", textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
              )
          ],
        ),
      );
  }

  Widget _buildGameOverUI(BuildContext context, Map<String, dynamic> roomData) {
    List<dynamic> players = List<dynamic>.from(roomData['players'] ?? []);
    // Sort players by score descending
    players.sort((a, b) => (b['score'] ?? 0).compareTo(a['score'] ?? 0));
    
    print("GTLGS(GameOver): Building UI. Final scores: ${players.map((p) => "${p['nickname']}: ${p['score']}").toList()}");

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Game Over!', style: Theme.of(context).textTheme.displaySmall, textAlign: TextAlign.center,),
            const SizedBox(height: 20),
            Text('Final Scores:', style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center,),
            const SizedBox(height: 10),
            Expanded(child: ListView.builder(
                itemCount: players.length,
                itemBuilder: (context, index) {
                    var player = players[index] as Map<String, dynamic>;
                    return Card(
                        color: index == 0 ? Colors.amber[800] : Theme.of(context).cardColor,
                        child: ListTile(
                            leading: Text("#${index + 1}", style: Theme.of(context).textTheme.titleLarge),
                            title: Text(player['nickname'] as String? ?? 'Player'),
                            trailing: Text("Score: ${player['score'] ?? 0}", style: Theme.of(context).textTheme.titleMedium),
                        ),
                    );
                }
            )),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                print("GTLGS(GameOver): Returning to home.");
                Navigator.popUntil(context, ModalRoute.withName('/home'));
              },
              child: const Text('Return to Home'),
            )
          ],
      ),
    );
  }
}
