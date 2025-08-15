import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:play_lumee/firebase_options.dart'; // Assuming this file exists and is correct
import 'dart:async';
import 'dart:math';
import 'package:collection/collection.dart'; // For .firstWhereOrNull
import 'package:flutter/services.dart'; // For PlatformException
import 'package:firebase_auth/firebase_auth.dart'; // For Auth, though not directly used for user management here
// import 'package:uuid/uuid.dart'; // Not directly used in the provided snippet, keep if needed elsewhere

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

  // Add this method to fix the missing nextRoundOrEndGame error for Sync Game
  Future<void> nextRoundOrEndGame(String roomCode) async {
  final roomRef = _firestore.collection('rooms').doc(roomCode);
  await _firestore.runTransaction((transaction) async {
    final roomSnapshot = await transaction.get(roomRef);
    if (!roomSnapshot.exists) throw Exception("Room does not exist!");

    int currentRound = roomSnapshot.data()?['currentRound'] ?? 1;
    int maxRounds = roomSnapshot.data()?['totalRounds'] ?? 3;
    String gameId = roomSnapshot.data()?['gameId'] ?? '';

    // Only start next round if currentRound < maxRounds
    if (currentRound < maxRounds) {
      await nextRound(roomCode, gameId); // This increments currentRound
    } else {
      // End game only if all rounds are complete
      await transaction.update(roomRef, {'gamePhase': 'gameOver'});
    }
  });
}

  // Add this method to fix the missing endRound error for Sync Game
  Future<void> endRound(String roomCode) async {
    final roomRef = _firestore.collection('rooms').doc(roomCode);
    await _firestore.runTransaction((transaction) async {
      final roomSnapshot = await transaction.get(roomRef);
      if (!roomSnapshot.exists) throw Exception("Room does not exist!");

      List<dynamic> players = List.from(roomSnapshot.data()?['players'] ?? []);
      // Sync game scoring is already handled by calculateAndApplyScoresSync before this phase
      // This method primarily handles advancing to the next round/game over

      transaction.update(roomRef, {
        'gamePhase': 'roundResults', // Move to round results phase
        // Players list is already updated with scores from calculateAndApplyScoresSync
      });
    });
  }

  // Add this method to fix the missing voteForAnswer error (though Sync doesn't use it directly)
  // Keeping this as it was in the user's provided FirebaseService
  Future<void> voteForAnswer(String roomCode, String userId, String answerId) async {
    DocumentReference roomRef = _firestore.collection('rooms').doc(roomCode);
    await _firestore.runTransaction((transaction) async {
      DocumentSnapshot roomSnap = await transaction.get(roomRef);
      if (!roomSnap.exists) throw Exception("Room does not exist!");

      List<dynamic> answers = List.from(roomSnap.get('answers') ?? []);
      List<dynamic> players = List.from(roomSnap.get('players') ?? []);

      // Mark player as having voted
      int playerIndex = players.indexWhere((p) => p['userId'] == userId); // Changed 'id' to 'userId'
      if (playerIndex != -1) {
        players[playerIndex]['hasVoted'] = true;
      }

      // Add userId to the answer's voters list
      int answerIndex = answers.indexWhere((a) => a['id'] == answerId);
      if (answerIndex != -1) {
        List<String> voters = List<String>.from(answers[answerIndex]['voters'] ?? []);
        if (!voters.contains(userId)) {
          voters.add(userId);
          answers[answerIndex]['voters'] = voters;
        }
      }

      transaction.update(roomRef, {
        'answers': answers,
        'players': players,
      });
    });
  }

  String getCurrentUserId() {
    return userId ?? '';
  }

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
        liar: "What's a place you visited that was exactly as you expected?"),
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

  // List of questions for the 'Sync' game
  final List<String> _syncQuestions = [
    "Name a type of fruit.",
    "Name a popular sport.",
    "Name a color.",
    "Name an animal you'd see at a zoo.",
    "Name a famous landmark.",
    "Name a common household item.",
    "Name a type of weather.",
    "Name a musical instrument.",
    "Name a type of drink.",
    "Name a fast food item.",
    "Name a mode of transportation.",
    "Name a subject taught in school.",
    "Name something you do on vacation.",
    "Name a type of tree.",
    "Name a piece of clothing.",
    "Name a popular social media platform.",
    "Name a type of dessert.",
    "Name a kitchen utensil.",
    "Name a country in Europe.",
    "Name a type of fish.",
    "Name a common pet.",
    "Name something you'd find in a park.",
    "Name a type of flower.",
    "Name a body of water.",
    "Name a profession.",
    "Name a type of bird.",
    "Name a board game.",
    "Name a type of cheese.",
    "Name a primary color.",
    "Name something associated with good luck."
    "Name a cartoon character you loved as a kid."

  "Name a game we always ended up playing together."

  "Name a food we always have at family dinners."

  "Name a song that reminds you of a holiday party."

  "Name a video game everyone played at some point."

  "Name a classic movie we all watched on repeat."

  "Name a place we went on a family vacation."

  "Name a chore you always tried to avoid."

  "Name a type of pizza topping."

  "Name a well-known superhero."

  "Name a candy bar you would buy at a movie theater."

  "Name a subject we all struggled with in school."

  "Name a store we would always go to on a trip."

  "Name something you'd find in a kitchen cabinet."

  "Name a type of soda."

  "Name a piece of playground equipment."

  "Name a popular social media platform."

  "Name a type of ice cream flavor."

  "Name a board game that took forever to finish."

  "Name a fast food restaurant."

  "Name a holiday tradition our family has."

  "Name a TV show we all watched growing up."

  "Name a type of shoe."

  "Name an animal you'd see at a zoo."

  "Name a musical instrument."

  "Name something you do on vacation."

  "Name a common household item."

  "Name a kind of soup."

  "Name a mode of transportation."

  "Name a subject taught in school."

  "Name a type of tree."

  "Name a type of dessert."

  "Name a kitchen utensil."

  "Name a type of drink."

  "Name a color."

  "Name a type of fruit."

  "Name a popular sport."

  "Name a famous fictional character."

  "Name a type of snack food."

  "Name a kind of bread."

  "Name something you can bake."

  "Name a type of dance."

  "Name a famous singer."

  "Name a common house plant."

  "Name a type of cookie."

  "Name a type of vegetable."

  "Name a well-known movie genre."

  "Name a sound an animal makes."

  "Name a type of car."

  "Name a famous monument."

  "Name a type of salad dressing."

  "Name a type of nut."

  "Name a body of water."

  "Name a type of flower."

  "Name a profession."

  "Name a type of bird."

  "Name a type of cheese."

  "Name a primary color."

  "Name something associated with good luck."

  "Name a piece of technology we can't live without."

  "Name a type of breakfast cereal."

  "Name a type of puzzle game."

  "Name something you'd find in a library."

  "Name a type of toy you had as a kid."

  "Name a type of berry."

  "Name a famous actor."

  "Name a kind of sandwich."

  "Name a type of sauce."

  "Name a type of bean."

  "Name a place you went for dinner in the UAE."

  "Name something you'd pack for a camping trip."

  "Name a type of animal."

  "Name a type of music genre."

  "Name a famous river."

  "Name a type of exercise."

  "Name a type of building."

  "Name a well-known fairy tale."

  "Name a type of pizza."

  "Name something you'd find in a refrigerator."

  "Name a common emotion."

  "Name a type of juice."

  "Name a type of cloud."

  "Name something you eat for breakfast."

  "Name a type of hat."

  "Name a character from a Disney movie."

  "Name something you'd find on a beach."

  "Name a type of insect."

  "Name a part of the human body."

  "Name a type of clothing item."

  "Name a famous historical figure."

  "Name a type of musical."

  "Name a kind of salad."

  "Name something you use to write with."

  "Name a type of dog breed."

  "Name a type of cat breed."

  "Name a type of fish you'd eat."

  "Name a piece of furniture."

  "Name a type of bird."

  "Name a type of flower."

  "Name a type of soup."

  "Name a popular hobby."

  "Name a type of tree."

  "Name a type of berry."

  "Name a country in Asia."

  "Name something you use to cook."

  "Name a type of game that uses a controller."

  "Name a type of dessert."

  "Name a brand of car."

  "Name a type of pasta."

  "Name something you can bake."

  "Name a body of water."

  "Name a profession."

  "Name a type of weather."

  "Name a common household item."

  "Name a type of book genre."

  "Name a type of drink."

  "Name a famous cartoon character."

  "Name a type of candy."

  "Name a subject taught in school."

  "Name something you'd find in a park."

  "Name a type of cheese."

  "Name a popular sport."

  "Name a type of bird."

  "Name a board game."

  "Name a type of puzzle."

  "Name a common pet."

  "Name a kind of cake."

  "Name a type of seafood."

  "Name a type of dance."

  "Name a famous song."

  "Name a type of sandwich."

  "Name a type of sauce."

  "Name a type of vegetable."

  "Name a place you'd go on vacation."

  "Name a type of game that uses dice."

  "Name a famous athlete."

  "Name a type of holiday."

  "Name a type of shoe."

  "Name a popular snack brand."

  "Name a mythological creature."

  "Name something associated with being a kid."

  "Name a type of nut."

  "Name a famous scientist."

  "Name a piece of technology."

  "Name a popular social media app."

  "Name a type of ice cream."

  "Name a type of pasta dish."

  "Name a common household appliance."

  "Name a piece of furniture you had as a kid."

  "Name a type of board game."

  "Name a type of animal you'd see on a farm."

  "Name a mode of transportation."

  "Name a color."

  "Name a specific memory from a family dinner."

  "Name a song that reminds you of a specific cousin."

  "Name a food we ate that was different from home."

  "Name a specific memory from playing a game together."

  "Name a specific inside joke we all share."

  "Name a type of game we played when the power went out."

  "Name a character from a game we all know."

  "Name a type of game that involves drawing."

  "Name a type of game that involves music."

  "Name a memory from one of our favorite games."

  "Name a kind of sandwich."

  "Name a common household item."

  "Name a place you'd find in your neighborhood."
  "Most memorable family time (Happy Home)"
  ];


  static Future<void> initializeFirebase() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("FirebaseService: Initialized");
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
            'hasGuessed': false, // For Don't Get Me Started
            'guesses': [], // For Don't Get Me Started
            'isRantingPlayer': false, // For Don't Get Me Started
            'isReadyInSetupPhase': false, // New flag for DGMS setup phase
            'answerSync': null, // For Sync game
            'isReadyInSyncPhase': false, // For Sync game
          }
        ],
        'currentRound': 0, // Initialize round
        'totalRounds': totalRounds, // Set total number of rounds from host input
        'currentQuestionIndex': -1, // For Guess the Liar (reused for Sync question index)
        'gamePhase': '',
        'liarCaught': null, // For Guess the Liar
        'currentRantingPlayerId': null, // For Don't Get Me Started
        'topic': null, // For Don't Get Me Started
        'rantText': null, // For Don't Get Me Started
        'timerEndTime': null, // For Don't Get Me Started
        'questionsUsedSync': [], // To keep track of used questions in Sync
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
            'hasGuessed': false, // For Don't Get Me Started
            'guesses': [], // For Don't Get Me Started
            'isRantingPlayer': false, // For Don't Get Me Started
            'isReadyInSetupPhase': false, // New flag for DGMS setup phase
            'answerSync': null, // For Sync game
            'isReadyInSyncPhase': false, // For Sync game
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

  // Helper to assign liar and questions for a new round (Guess the Liar)
  void _assignRolesAndQuestionsGTL(DocumentSnapshot roomSnap, String gameId, Function(Map<String, dynamic>) onUpdate) {
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

  // Helper to assign ranting player for a new round (Don't Get Me Started)
  Future<void> _assignRantingPlayerDGMS(String roomCode, DocumentSnapshot roomSnap) async {
    List<dynamic> playersList = List<dynamic>.from(roomSnap.get('players') ?? []);

    // Find previous ranting player if any
    String? previousRantingPlayerId = roomSnap.get('currentRantingPlayerId');

    // Filter out the previous ranting player if possible, to pick a new one
    List<Map<String, dynamic>> eligiblePlayers = playersList
        .map((p) => Map<String, dynamic>.from(p))
        .where((p) => p['userId'] != previousRantingPlayerId)
        .toList();

    // If only one player left or all other players have played, pick randomly from all
    if (eligiblePlayers.isEmpty && playersList.isNotEmpty) {
      eligiblePlayers = playersList.map((p) => Map<String, dynamic>.from(p)).toList();
    }

    if (eligiblePlayers.isEmpty) {
      print("FirebaseService: No eligible players to select a ranting player.");
      return;
    }

    int randomIndex = Random().nextInt(eligiblePlayers.length);
    String newRantingPlayerId = eligiblePlayers[randomIndex]['userId'];

    List<Map<String, dynamic>> updatedPlayers = [];
    for (var player in playersList) {
      var p = Map<String, dynamic>.from(player as Map);
      p['isRantingPlayer'] = (p['userId'] == newRantingPlayerId);
      p['hasGuessed'] = false; // Reset guess status for new round
      p['guesses'] = []; // Reset guesses for new round
      p['rantText'] = null; // Clear old rant text from player object (though stored in room too)
      p['isReadyInSetupPhase'] = false; // Reset setup readiness for new round
      updatedPlayers.add(p);
    }

    await _firestore.collection('rooms').doc(roomCode).update({
      'status': 'playing',
      'gamePhase': 'waitingForTopicSelection', // Initial phase for DGMS round
      'currentRantingPlayerId': newRantingPlayerId,
      'players': updatedPlayers,
      'topic': null, // Reset topic for new round
      'rantText': null, // Reset rant text for new round
      'timerEndTime': null, // Reset timer
      'liarCaught': null, // Ensure irrelevant GTL fields are clear
      'originalQuestion': null, // Ensure irrelevant GTL fields are clear
      'liarQuestion': null, // Ensure irrelevant GTL fields are clear
    });
    print('FirebaseService: New ranting player selected: $newRantingPlayerId for room $roomCode.');
  }

  // Helper to assign a question for a new round (Sync)
  Future<void> _assignQuestionSync(String roomCode, DocumentSnapshot roomSnap) async {
    List<dynamic> playersList = List<dynamic>.from(roomSnap.get('players') ?? []);
    List<int> questionsUsed = List<int>.from(roomSnap.get('questionsUsedSync') ?? []);

    // Select a question not used yet
    int questionIndex;
    if (questionsUsed.length >= _syncQuestions.length) {
      // If all questions used, reset the list to allow new cycle of questions or end game
      questionsUsed = []; // Reset for next cycle of rounds
    }

    Random random = Random();
    do {
      questionIndex = random.nextInt(_syncQuestions.length);
    } while (questionsUsed.contains(questionIndex));

    questionsUsed.add(questionIndex);

    List<Map<String, dynamic>> updatedPlayers = [];
    for (var player in playersList) {
      var p = Map<String, dynamic>.from(player as Map);
      p['answerSync'] = null; // Reset answer for sync
      p['isReadyInSyncPhase'] = false; // Reset ready flag for sync
      updatedPlayers.add(p);
    }

    await _firestore.collection('rooms').doc(roomCode).update({
      'status': 'playing',
      'gamePhase': 'answeringSync', // The phase where players submit their sync answer
      'players': updatedPlayers,
      'currentQuestionIndex': questionIndex,
      'questionsUsedSync': questionsUsed,
    });
    print('FirebaseService: New question assigned for Sync round in room $roomCode. Question index: $questionIndex');
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
          snackbarKey.currentState?.showSnackBar(
            const SnackBar(content: Text('Guess the Liar needs at least 3 players to start.')),
          );
          print("FirebaseService: Not enough players to start Guess the Liar (min 3). Found: ${playersList.length}");
          return;
        }
        await roomRef.update({'currentRound': 1}); // Start first round
        _assignRolesAndQuestionsGTL(roomSnap, gameId, (updateData) async {
          await roomRef.update(updateData);
        });
      } else if (gameId == 'dont_get_me_started') {
        if (playersList.length < 2) { // DGMS needs at least 2 players (1 ranter, 1 guesser)
          snackbarKey.currentState?.showSnackBar(
            const SnackBar(content: Text("Don't Get Me Started needs at least 2 players to start.")),
          );
          print("FirebaseService: Not enough players to start Don't Get Me Started (min 2). Found: ${playersList.length}");
          return;
        }
        await roomRef.update({'currentRound': 1}); // Start first round
        await _assignRantingPlayerDGMS(roomCode, roomSnap); // Assign initial ranting player
      } else if (gameId == 'sync') {
          if (playersList.length < 2) { // Sync needs at least 2 players
          snackbarKey.currentState?.showSnackBar(
            const SnackBar(content: Text("Sync needs at least 2 players to start.")),
          );
          print("FirebaseService: Not enough players to start Sync (min 2). Found: ${playersList.length}");
          return;
        }
        await roomRef.update({'currentRound': 1}); // Start first round
        await _assignQuestionSync(roomCode, roomSnap);
      }
      else {
        await roomRef.update({'status': 'playing'}); // Generic start
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

      if (gameId == 'guess_the_liar') {
        _assignRolesAndQuestionsGTL(roomSnap, gameId, (updateData) async {
          await roomRef.update(updateData);
        });
      } else if (gameId == 'dont_get_me_started') {
        await _assignRantingPlayerDGMS(roomCode, roomSnap);
      } else if (gameId == 'sync') {
        await _assignQuestionSync(roomCode, roomSnap);
      }
      print('FirebaseService: Game $gameId advanced to round $newRound in room $roomCode');
    } catch (e) {
      print('FirebaseService: Error advancing to next round: $e');
    }
  }

  // DGMS Specific methods
  // Called by Ranter to submit topic and move from `waitingForTopicSelection` to `rantingPlayerSetup`
  Future<void> setRanterTopic(String roomCode, String playerId, String topic) async {
    try {
      DocumentReference roomRef = _firestore.collection('rooms').doc(roomCode);
      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot roomSnap = await transaction.get(roomRef);
        if (!roomSnap.exists) throw Exception("Room does not exist!");

        Map<String, dynamic> roomData = roomSnap.data() as Map<String, dynamic>;
        String currentRantingPlayerId = roomData['currentRantingPlayerId'];

        if (currentRantingPlayerId == playerId) {
          transaction.update(roomRef, {
            'topic': topic,
            'gamePhase': 'rantingPlayerSetup', // Move to the setup/input phase
          });
          print("FirebaseService: Ranter ($playerId) submitted topic and moved to rantingPlayerSetup.");
        }
      });
    } on FirebaseException catch (e) {
      print("FirebaseService Error (FirebaseException) in setRanterTopic: Code: ${e.code}, Message: ${e.message}");
      rethrow;
    } on PlatformException catch (e) {
      print("FirebaseService Error (PlatformException) in setRanterTopic: Code: ${e.code}, Message: ${e.message}");
      rethrow;
    } catch (e, st) {
      print("FirebaseService Generic Error in setRanterTopic: $e");
      print("Stack trace: $st");
      rethrow;
    }
  }

  // Called by Ranter in `rantingPlayerSetup` phase to submit personal reference and set ready flag
  Future<void> setRanterPersonalReferenceAndReady(String roomCode, String playerId, String rantText) async {
    try {
      DocumentReference roomRef = _firestore.collection('rooms').doc(roomCode);
      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot roomSnap = await transaction.get(roomRef);
        if (!roomSnap.exists) throw Exception("Room does not exist!");

        List<dynamic> players = List.from(roomSnap.get('players') ?? []);
        Map<String, dynamic>? ranter = players.firstWhereOrNull((p) => p['userId'] == playerId);

        if (ranter != null && ranter['isRantingPlayer'] == true) {
          ranter['isReadyInSetupPhase'] = true;
          // Update the player list in the transaction
          for (int i = 0; i < players.length; i++) {
            if ((players[i] as Map)['userId'] == playerId) {
              players[i] = ranter;
              break;
            }
          }

          transaction.update(roomRef, {
            'rantText': rantText,
            'players': players,
          });

          // Pass the modified players list directly
          await _checkAllPlayersReadyForRant(roomCode, transaction, roomRef, players);
          print("FirebaseService: Ranter set personal reference and ready flag.");
        }
      });
    } on FirebaseException catch (e) {
      print("FirebaseService Error (FirebaseException) in setRanterPersonalReferenceAndReady: Code: ${e.code}, Message: ${e.message}");
      rethrow;
    } on PlatformException catch (e) {
      print("FirebaseService Error (PlatformException) in setRanterPersonalReferenceAndReady: Code: ${e.code}, Message: ${e.message}");
      rethrow;
    } catch (e, st) {
      print("FirebaseService Generic Error in setRanterPersonalReferenceAndReady: $e");
      print("Stack trace: $st");
      rethrow;
    }
  }

  // Called by Guessing Players in `rantingPlayerSetup` phase
  Future<void> submitGuessesAndSetReady(String roomCode, String guessingPlayerId, List<String> guesses) async {
    try {
      DocumentReference roomRef = _firestore.collection('rooms').doc(roomCode);
      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot roomSnap = await transaction.get(roomRef);
        if (!roomSnap.exists) {
          print("FirebaseService: Room $roomCode does not exist during submitGuessesAndSetReady transaction.");
          throw Exception("Room does not exist!");
        }

        List<dynamic> players = List<dynamic>.from(roomSnap.get('players') ?? []);
        Map<String, dynamic>? guessingPlayer = players.firstWhereOrNull((p) => p['userId'] == guessingPlayerId);

        if (guessingPlayer != null) {
          List<Map<String, dynamic>> playerGuesses = [];
          for (String guessText in guesses) {
            if (guessText.isNotEmpty) {
              playerGuesses.add({'text': guessText, 'isCorrect': false}); // Default to false
            }
          }

          guessingPlayer['guesses'] = playerGuesses;
          guessingPlayer['hasGuessed'] = true;
          guessingPlayer['isReadyInSetupPhase'] = true;

          // DEBUG LOGGING: Print data before update
          print("FirebaseService (DEBUG): Player ${guessingPlayer['nickname']} prepared for update:");
          print("   - guesses: ${guessingPlayer['guesses']}");
          print("   - hasGuessed: ${guessingPlayer['hasGuessed']}");
          print("   - isReadyInSetupPhase: ${guessingPlayer['isReadyInSetupPhase']}");


          // Update the player list in the transaction
          for (int i = 0; i < players.length; i++) {
            if ((players[i] as Map)['userId'] == guessingPlayerId) { // Cast to Map to access 'userId'
              players[i] = guessingPlayer;
              break;
            }
          }

          // DEBUG LOGGING: Print entire updated players list
          print("FirebaseService (DEBUG): Entire 'players' list prepared for Firestore update:");
          players.forEach((p) => print("   - ${p}"));

          transaction.update(roomRef, {'players': players});

          // Pass the modified players list directly
          await _checkAllPlayersReadyForRant(roomCode, transaction, roomRef, players);
          print("FirebaseService: Guessing player submitted guesses and set ready flag successfully.");
        } else {
          print("FirebaseService: Guessing player with ID $guessingPlayerId not found in room $roomCode.");
          throw Exception("Player not found in room.");
        }
      });
    } on FirebaseException catch (e) {
      print("FirebaseService Error (FirebaseException) in submitGuessesAndSetReady: Code: ${e.code}, Message: ${e.message}");
      rethrow;
    } on PlatformException catch (e) {
      print("FirebaseService Error (PlatformException) in submitGuessesAndSetReady: Code: ${e.code}, Message: ${e.message}");
      rethrow;
    } catch (e, st) {
      print("FirebaseService Generic Error in submitGuessesAndSetReady: $e");
      print("Stack trace: $st");
      rethrow;
    }
  }

  // New internal method to check if all players are ready and advance phase
  // Now accepts the currentPlayers list directly to avoid re-reading within the same transaction.
  Future<void> _checkAllPlayersReadyForRant(String roomCode, Transaction transaction, DocumentReference roomRef, List<dynamic> currentPlayers) async {
    try {
      // Use the provided currentPlayers list instead of re-reading from Firestore
      List<dynamic> players = currentPlayers; // This is now the locally updated list
      bool allReady = true;

      for (var player in players) {
        if (! (player is Map<String, dynamic> && (player['isReadyInSetupPhase'] == true))) { // Ensure it's a Map and check property safely
          allReady = false;
          break;
        }
      }
      if (allReady) {
        print("FirebaseService: All players are ready for ranting. Advancing to guessingAndRanting phase and starting timer.");
        transaction.update(roomRef, {
          'gamePhase': 'guessingAndRanting',
          'timerEndTime': FieldValue.serverTimestamp(),
        });
      } else {
        print("FirebaseService: Not all players ready yet. Current ready count: ${players.where((p) => p is Map && p['isReadyInSetupPhase'] == true).length}/${players.length}");
      }
    } on FirebaseException catch (e) {
      print("FirebaseService Error (FirebaseException) in _checkAllPlayersReadyForRant: Code: ${e.code}, Message: ${e.message}");
      rethrow;
    } on PlatformException catch (e) {
      print("FirebaseService Error (PlatformException) in _checkAllPlayersReadyForRant: Code: ${e.code}, Message: ${e.message}");
      rethrow;
    } catch (e, st) {
      print("FirebaseService Generic Error in _checkAllPlayersReadyForRant: $e");
      print("Stack trace: $st");
      rethrow;
    }
  }

  // Sync Game: Submit Answer
  Future<void> submitAnswerSync(String roomCode, String playerId, String answer) async {
    try {
      DocumentReference roomRef = _firestore.collection('rooms').doc(roomCode);
      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot roomSnap = await transaction.get(roomRef);
        if (!roomSnap.exists) throw Exception("Room does not exist!");

        List<dynamic> players = List.from(roomSnap.get('players') ?? []);
        Map<String, dynamic>? currentPlayer = players.firstWhereOrNull((p) => p['userId'] == playerId);

        if (currentPlayer != null) {
          currentPlayer['answerSync'] = answer.trim();
          currentPlayer['isReadyInSyncPhase'] = true;

          for (int i = 0; i < players.length; i++) {
            if ((players[i] as Map)['userId'] == playerId) {
              players[i] = currentPlayer;
              break;
            }
          }

          transaction.update(roomRef, {'players': players});
          await _checkAllPlayersReadyForSync(roomCode, transaction, roomRef, players);
          print("FirebaseService: Player $playerId submitted answer for Sync.");
        } else {
          print("FirebaseService: Player $playerId not found in room $roomCode for Sync answer submission.");
        }
      });
    } on FirebaseException catch (e) {
      print("FirebaseService Error (FirebaseException) in submitAnswerSync: Code: ${e.code}, Message: ${e.message}");
      rethrow;
    } on PlatformException catch (e) {
      print("FirebaseService Error (PlatformException) in submitAnswerSync: Code: ${e.code}, Message: ${e.message}");
      rethrow;
    } catch (e, st) {
      print("FirebaseService Generic Error in submitAnswerSync: $e");
      print("Stack trace: $st");
      rethrow;
    }
  }

  // Sync Game: Check if all players are ready for scoring
  Future<void> _checkAllPlayersReadyForSync(String roomCode, Transaction transaction, DocumentReference roomRef, List<dynamic> currentPlayers) async {
    try {
      List<dynamic> players = currentPlayers;
      bool allReady = true;

      for (var player in players) {
        if (! (player is Map<String, dynamic> && (player['isReadyInSyncPhase'] == true))) {
          allReady = false;
          break;
        }
      }

      if (allReady) {
        print("FirebaseService: All players are ready for Sync. Advancing to revealingAnswersSync phase and calculating scores.");
        // The phase change and score calculation happens immediately after all are ready.
        await calculateAndApplyScoresSync(roomCode, transaction, roomRef, players);
      } else {
        print("FirebaseService: Not all players ready yet for Sync. Current ready count: ${players.where((p) => p is Map && p['isReadyInSyncPhase'] == true).length}/${players.length}");
      }
    } on FirebaseException catch (e) {
      print("FirebaseService Error (FirebaseException) in _checkAllPlayersReadyForSync: Code: ${e.code}, Message: ${e.message}");
      rethrow;
    } on PlatformException catch (e) {
      print("FirebaseService Error (PlatformException) in _checkAllPlayersReadyForSync: Code: ${e.code}, Message: ${e.message}");
      rethrow;
    } catch (e, st) {
      print("FirebaseService Generic Error in _checkAllPlayersReadyForSync: $e");
      print("Stack trace: $st");
      rethrow;
    }
  }

  // Sync Game: Calculate and apply scores based on similar answers
  Future<void> calculateAndApplyScoresSync(String roomCode, Transaction transaction, DocumentReference roomRef, List<dynamic> currentPlayers) async {
    try {
      List<Map<String, dynamic>> players = List<Map<String, dynamic>>.from(currentPlayers.map((p) => Map<String, dynamic>.from(p)));

      // Group answers and normalize them
      Map<String, List<String>> normalizedAnswersMap = {}; // Key: normalized answer, Value: List of playerIds who gave it
      Map<String, String> playerOriginalAnswerMapping = {}; // Key: playerId, Value: original answer (before normalization)

      for (var player in players) {
        String? answer = player['answerSync'] as String?;
        if (answer != null && answer.isNotEmpty) {
          String normalizedAnswer = _normalizeAnswer(answer);
          if (!normalizedAnswersMap.containsKey(normalizedAnswer)) {
            normalizedAnswersMap[normalizedAnswer] = [];
          }
          normalizedAnswersMap[normalizedAnswer]!.add(player['userId']);
          playerOriginalAnswerMapping[player['userId']] = answer; // Store original answer
        }
      }

      List<Map<String, dynamic>> updatedPlayers = [];
      for (var player in players) {
        int currentScore = player['score'] ?? 0;
        // Reset matchedPlayers for the current round display purposes
        player['matchedPlayers'] = []; 

        String? originalAnswer = playerOriginalAnswerMapping[player['userId']];
        if (originalAnswer != null) {
          String normalizedAnswer = _normalizeAnswer(originalAnswer);
          List<String>? matchedUserIds = normalizedAnswersMap[normalizedAnswer];

          if (matchedUserIds != null && matchedUserIds.length > 1) {
            // Score = number of people in the group (including self)
            int pointsEarned = matchedUserIds.length;
            player['score'] = currentScore + pointsEarned;
            // Store which other players they matched with (excluding self)
            player['matchedPlayers'] = matchedUserIds.where((id) => id != player['userId']).toList();
            print("Sync Score: Player ${player['nickname']} got $pointsEarned points for answer '$originalAnswer'. Matched with: ${player['matchedPlayers']}");
          }
        }
        updatedPlayers.add(player);
      }

      transaction.update(roomRef, {
        'players': updatedPlayers,
        'gamePhase': 'revealingAnswersSync', // Move to reveal answers phase
      });
      print("FirebaseService: Sync scores calculated and updated.");
    } on FirebaseException catch (e) {
      print("FirebaseService Error (FirebaseException) in calculateAndApplyScoresSync: Code: ${e.code}, Message: ${e.message}");
      rethrow;
    } on PlatformException catch (e) {
      print("FirebaseService Error (PlatformException) in calculateAndApplyScoresSync: Code: ${e.code}, Message: ${e.message}");
      rethrow;
    } catch (e, st) {
      print("FirebaseService Generic Error in calculateAndApplyScoresSync: $e");
      print("Stack trace: $st");
      rethrow;
    }
  }

  // Helper function to normalize answers for comparison
  String _normalizeAnswer(String answer) {
    // Convert to lowercase
    String normalized = answer.toLowerCase();

    // Remove all non-alphanumeric characters (keeps spaces for now, will handle later)
    normalized = normalized.replaceAll(RegExp(r'[^\p{L}\p{N}\s]', unicode: true), ''); // Keeps letters, numbers, spaces

    // Normalize multiple spaces to a single space, then trim
    normalized = normalized.replaceAll(RegExp(r'\s+'), ' ').trim();

    // Basic plural 's' removal, be careful not to remove 's' from words like 'chess'
    // This logic operates on the whole string, which is fine if we've removed extra spaces
    if (normalized.endsWith('es')) {
      normalized = normalized.substring(0, normalized.length - 2);
    } else if (normalized.endsWith('s') && normalized.length > 1 && !normalized.endsWith('ss')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    
    // Remove all spaces for final comparison (as per previous behavior for "red apple" vs "redapple")
    normalized = normalized.replaceAll(' ', '');

    return normalized;
  }


  Future<void> toggleGuessCorrectness(String roomCode, String guesserId, int guessIndex, bool isCorrect) async {
    try {
      DocumentReference roomRef = _firestore.collection('rooms').doc(roomCode);
      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot roomSnap = await transaction.get(roomRef);
        if (!roomSnap.exists) throw Exception("Room does not exist!");

        List<dynamic> players = List<dynamic>.from(roomSnap.get('players') ?? []);
        Map<String, dynamic>? currentRantingPlayer = players.firstWhereOrNull((p) => p['userId'] == userId);

        if (currentRantingPlayer == null || currentRantingPlayer['isRantingPlayer'] != true) {
          print("FirebaseService: Only the ranting player can toggle correctness.");
          return; // Only ranting player can do this
        }

        Map<String, dynamic>? guesserPlayer = players.firstWhereOrNull((p) => p['userId'] == guesserId);

        if (guesserPlayer != null && guesserPlayer['guesses'] != null && guesserPlayer['guesses'].length > guessIndex) {
          guesserPlayer['guesses'][guessIndex]['isCorrect'] = isCorrect;

          // Update player list in transaction
          for (int i = 0; i < players.length; i++) {
            if ((players[i] as Map)['userId'] == guesserId) {
              players[i] = guesserPlayer;
              break;
            }
          }
          transaction.update(roomRef, {'players': players});
          print("FirebaseService: Toggled correctness for guess $guessIndex of $guesserId to $isCorrect.");
        }
      });
    } on FirebaseException catch (e) {
      print("FirebaseService Error (FirebaseException) in toggleGuessCorrectness: Code: ${e.code}, Message: ${e.message}");
      rethrow;
    } on PlatformException catch (e) {
      print("FirebaseService Error (PlatformException) in toggleGuessCorrectness: Code: ${e.code}, Message: ${e.message}");
      rethrow;
    } catch (e, st) {
      print("FirebaseService Generic Error in toggleGuessCorrectness: $e");
      print("Stack trace: $st");
      rethrow;
    }
  }

  Future<void> calculateAndApplyScoresDGMS(String roomCode) async {
    try {
      DocumentReference roomRef = _firestore.collection('rooms').doc(roomCode);
      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot roomSnap = await transaction.get(roomRef);
        if (!roomSnap.exists) throw Exception("Room does not exist!");

        List<dynamic> players = List<dynamic>.from(roomSnap.get('players') ?? []);
        String? currentRantingPlayerId = roomSnap.get('currentRantingPlayerId');

        List<Map<String, dynamic>> updatedPlayers = [];
        for (var player in players) {
          var p = Map<String, dynamic>.from(player as Map);
          int currentScore = p['score'] ?? 0;

          if (p['userId'] == currentRantingPlayerId) {
            // Ranting player gets points for each correct guess by others
            int correctGuessesByOthers = players.where((otherPlayer) {
              if ((otherPlayer as Map)['userId'] == currentRantingPlayerId) return false; // Don't count own guesses
              List<dynamic> guesses = (otherPlayer as Map)['guesses'] ?? [];
              return guesses.any((guess) => (guess as Map)['isCorrect'] == true);
            }).length;
            p['score'] = currentScore + correctGuessesByOthers; // 1 point per correct guess found
            print("FirebaseService: Ranting player ${p['nickname']} gets $correctGuessesByOthers points.");
          } else {
            // Guessing player gets points for their own correct guesses
            List<dynamic> guesses = p['guesses'] ?? [];
            int myCorrectGuesses = guesses.where((guess) => (guess as Map)['isCorrect'] == true).length;
            p['score'] = currentScore + myCorrectGuesses; // 1 point per correct guess they made
            print("FirebaseService: Player ${p['nickname']} gets $myCorrectGuesses points for their guesses.");
          }
          updatedPlayers.add(p);
        }

        transaction.update(roomRef, {
          'players': updatedPlayers,
          'gamePhase': 'roundResults', // Move to round results phase
        });
        print("FirebaseService: Scores calculated and updated for DGMS round.");
      });
    } on FirebaseException catch (e) {
      print("FirebaseService Error (FirebaseException) in calculateAndApplyScoresDGMS: Code: ${e.code}, Message: ${e.message}");
      rethrow;
    } on PlatformException catch (e) {
      print("FirebaseService Error (PlatformException) in calculateAndApplyScoresDGMS: Code: ${e.code}, Message: ${e.message}");
      rethrow;
    } catch (e, st) {
      print("FirebaseService Generic Error in calculateAndApplyScoresDGMS: $e");
      print("Stack trace: $st");
      rethrow;
    }
  }

  Future<void> skipRantingPlayer(String roomCode) async {
    if (userId == null) {
      print("FirebaseService: Error: userId is null when trying to skip player.");
      return;
    }
    try {
      DocumentReference roomRef = _firestore.collection('rooms').doc(roomCode);
      DocumentSnapshot roomSnap = await roomRef.get();
      if (!roomSnap.exists) return;

      Map<String, dynamic> roomData = roomSnap.data() as Map<String, dynamic>;
      List<dynamic> players = List<dynamic>.from(roomData['players'] ?? []);
      Map<String, dynamic>? hostPlayer = players.firstWhereOrNull((p) => p['userId'] == userId);

      if (hostPlayer == null || hostPlayer['isHost'] != true) {
        print("FirebaseService: Only the host can skip a player.");
        return;
      }

      // This will increment the round and reassign the ranting player
      await nextRound(roomCode, roomData['gameId']);

      print("FirebaseService: Host skipped current ranting player. Starting new round.");
    } on FirebaseException catch (e) {
      print("FirebaseService Error (FirebaseException) in skipRantingPlayer: Code: ${e.code}, Message: ${e.message}");
      rethrow;
    } on PlatformException catch (e) {
      print("FirebaseService Error (PlatformException) in skipRantingPlayer: Code: ${e.code}, Message: ${e.message}");
      rethrow;
    } catch (e, st) {
      print("FirebaseService Generic Error in skipRantingPlayer: $e");
      print("Stack trace: $st");
      rethrow;
    }
  }


  Future<void> submitAnswer(String roomCode, String playerId, String answer) async {
    if (userId == null) {
      print("FirebaseService: Error: userId is null when trying to submit answer (GTL).");
      return;
    }
    try {
      DocumentReference roomRef = _firestore.collection('rooms').doc(roomCode);
      DocumentSnapshot roomSnap = await roomRef.get();
      if (!roomSnap.exists) {
        print("FirebaseService: Room $roomCode does not exist for submitting answer (GTL).");
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
        // Check if all players (excluding liar) have answered. Liar's answer is predefined.
        // Also, ensure 'answer' field exists or is not empty.
        if (player['isLiar'] == false && (player['answer'] == null || (player['answer'] as String).isEmpty)) {
            allHaveAnswered = false;
        }
      }

      Map<String, dynamic> updateData = {'players': players};
      if (allHaveAnswered) {
        updateData['gamePhase'] = 'discussing';
        print("FirebaseService: All players (GTL) answered. Moving to discussing phase.");
      }

      await roomRef.update(updateData);
    } on FirebaseException catch (e) {
      print("FirebaseService Error (FirebaseException) in submitAnswer: Code: ${e.code}, Message: ${e.message}");
      rethrow;
    } on PlatformException catch (e) {
      print("FirebaseService Error (PlatformException) in submitAnswer: Code: ${e.code}, Message: ${e.message}");
      rethrow;
    } catch (e, st) {
      print("FirebaseService Generic Error in submitAnswer: $e");
      print("Stack trace: $st");
      rethrow;
    }
  }

  Future<void> submitVote(String roomCode, String voterId, String votedPlayerId) async {
    if (userId == null) {
      print("FirebaseService: Error: userId is null when trying to submit vote (GTL).");
      return;
    }
    print("FirebaseService: submitVote (GTL) initiated for room $roomCode by $voterId, voting for $votedPlayerId.");
    DocumentReference roomRef = _firestore.collection('rooms').doc(roomCode);
    try {
      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot roomSnap = await transaction.get(roomRef);
        if (!roomSnap.exists) {
          print("FirebaseService: Transaction Error (GTL) - Room $roomCode does not exist!");
          throw Exception("Room does not exist!");
        }

        List<dynamic> players = List<dynamic>.from(roomSnap.get('players') ?? []);
        bool allHaveVoted = true;
        print("FirebaseService: Players (GTL) before vote processing: ${players.map((p) => "${(p as Map)['nickname']} (votedFor: ${(p as Map)['votedFor']})").toList()}");

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
        print("FirebaseService: Players (GTL) after current vote recorded: ${players.map((p) => "${(p as Map)['nickname']} (votedFor: ${(p as Map)['votedFor']}, votesReceived: ${(p as Map)['votesReceived']})").toList()}");

        // Then, check if all players have cast their vote
        for (var p_check in players) {
          var playerMap = p_check as Map<String, dynamic>;
          if (playerMap['votedFor'] == null) {
            allHaveVoted = false;
            break;
          }
        }
        print("FirebaseService: All players (GTL) have voted? $allHaveVoted");

        Map<String, dynamic> updateData = {'players': players};
        if (allHaveVoted) {
          updateData['gamePhase'] = 'reveal';
          print("FirebaseService: All players (GTL) voted. Setting gamePhase to 'reveal'.");

          // Calculate if the liar was caught AND update scores
          Map<String, dynamic>? liar = players.firstWhereOrNull(
            (p) => (p as Map)['isLiar'] == true,
          ) as Map<String, dynamic>?;

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
        print("FirebaseService: Firestore transaction for submitVote (GTL) completed successfully.");
      });
    } on FirebaseException catch (e) {
      print("FirebaseService Error (FirebaseException) in submitVote: Code: ${e.code}, Message: ${e.message}");
      rethrow;
    } on PlatformException catch (e) {
      print("FirebaseService Error (PlatformException) in submitVote: Code: ${e.code}, Message: ${e.message}");
      rethrow;
    } catch (e, st) {
      print('FirebaseService Generic Error during submitVote transaction (GTL): $e');
      print("Stack trace: $st");
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
    } on FirebaseException catch (e) {
      print("FirebaseService Error (FirebaseException) in nextPhase: Code: ${e.code}, Message: ${e.message}");
      rethrow;
    } on PlatformException catch (e) {
      print("FirebaseService Error (PlatformException) in nextPhase: Code: ${e.code}, Message: ${e.message}");
      rethrow;
    } catch (e, st) {
      print("FirebaseService Generic Error in nextPhase: $e");
      print("Stack trace: $st");
      rethrow;
    }
  }

  bool get isLoggedIn => userId != null && nickname != null;
}

// GlobalKey for accessing ScaffoldMessenger from FirebaseService
final GlobalKey<ScaffoldMessengerState> snackbarKey = GlobalKey<ScaffoldMessengerState>();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

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
        // Removed explicit font family to use system default, which handles Chinese symbols better.
        // fontFamily: 'Arial', 
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
      navigatorKey: navigatorKey, // Assign navigatorKey here
      scaffoldMessengerKey: snackbarKey, // Assign snackbarKey here
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
        '/play/dont_get_me_started': (context) {
          final routeArgs = ModalRoute.of(context)?.settings.arguments;
          if (routeArgs is Map<String, dynamic>) {
            final String? roomCode = routeArgs['roomCode'] as String?;final String? gameId = routeArgs['gameId'] as String?;
            if (roomCode != null && gameId != null) {
              return DontGetMeStartedGameScreen(roomCode: roomCode, gameId: gameId);
            }
          }
          print("AppRoutes: Error: Invalid arguments for /play/dont_get_me_started. Navigating to home.");
          return const HomeScreen(); // Fallback
        },
        '/play/sync': (context) {
          final routeArgs = ModalRoute.of(context)?.settings.arguments;
          if (routeArgs is Map<String, dynamic>) {
            final String? roomCode = routeArgs['roomCode'] as String?;
            final String? gameId = routeArgs['gameId'] as String?;
            if (roomCode != null && gameId != null) {
              return SyncGameScreen(roomCode: roomCode, gameId: gameId);
            }
          }
          print("AppRoutes: Error: Invalid arguments for /play/sync. Navigating to home.");
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
      snackbarKey.currentState?.showSnackBar( // Use snackbarKey for consistent access
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
    name: "Sync", // Changed from "Coming Soon!"
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
          if (isComingSoon || game.id == 'dont_get_caught') { // Exclude 'sync' and 'dont_get_me_started' from coming soon check
            snackbarKey.currentState?.showSnackBar(
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
                child: Icon(Icons.videogame_asset, size: 50, color: Colors.grey[400]),
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
      snackbarKey.currentState?.showSnackBar(const SnackBar(content: Text('Error: User not logged in.')));
      return;
    }

    // Show dialog to choose number of rounds
    int? selectedRounds = await showDialog<int>(
      context: context,
      builder: (BuildContext dialogContext) {
        // Use a local stateful builder for the dialog's slider
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            double tempRounds = 3.0; // Default rounds for slider, needs to be within StatefulBuilder or a stateful widget

            return AlertDialog(
              title: const Text('Choose Number of Rounds'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Rounds: ${tempRounds.round()}', style: Theme.of(context).textTheme.titleMedium),
                  Slider(
                    value: tempRounds,
                    min: 1,
                    max: 10,
                    divisions: 9, // 1 to 10 has 9 divisions
                    label: tempRounds.round().toString(),
                    onChanged: (double value) {
                      setState(() { // Update the local state of the dialog immediately
                        tempRounds = value;
                      });
                    },
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text('Start Game'),
                  onPressed: () {
                    Navigator.of(context).pop(tempRounds.round());
                  },
                ),
              ],
            );
          }
        );
      },
    );

    if (selectedRounds == null || selectedRounds < 1) {
      snackbarKey.currentState?.showSnackBar(const SnackBar(content: Text('Please select a valid number of rounds.')));
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
      snackbarKey.currentState?.showSnackBar(const SnackBar(content: Text('Failed to create room. Try again.')));
    }
  }

  void _joinGame() async {
    if (!firebaseService.isLoggedIn) {
      snackbarKey.currentState?.showSnackBar(const SnackBar(content: Text('Error: User not logged in.')));
      return;
    }
    final roomCode = _roomCodeController.text.trim();
    if (roomCode.isEmpty) {
      snackbarKey.currentState?.showSnackBar(const SnackBar(content: Text('Please enter a room code.')));
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
      snackbarKey.currentState?.showSnackBar(const SnackBar(content: Text('Failed to join room. Check code or try again.')));
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
              // Removed mounted check for StatelessWidget. Context is typically valid for navigation from builder.
              if (ModalRoute.of(context)?.isCurrent == true) {
                Navigator.popUntil(context, ModalRoute.withName('/home'));
              }
            });
            return const Center(child: Text('Room not found. Returning to home...'));
          }

          Map<String, dynamic> roomData = snapshot.data!.data() as Map<String, dynamic>;
          List<dynamic> players = List<dynamic>.from(roomData['players'] ?? []);
          String gameStatus = roomData['status'] ?? 'waiting';

          print("WaitingLobby Stream Update: Status: $gameStatus, Players: ${players.map((p) => (p as Map)['nickname']).toList()}");

          final currentGame = games.firstWhere((g) => g.id == gameId, orElse: () {
            print("Error: Game with ID $gameId not found in games list. Defaulting.");
            return games.first; // Fallback, should ideally not happen
          });

          if (gameStatus == 'playing') {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              // Removed mounted check for StatelessWidget. Context is typically valid for navigation from builder.
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
                        snackbarKey.currentState?.showSnackBar(
                          const SnackBar(content: Text('Guess the Liar needs at least 3 players to start.')),
                        );
                        return;
                      } else if (gameId == 'dont_get_me_started' && players.length < 2) {
                          snackbarKey.currentState?.showSnackBar(
                          const SnackBar(content: Text("Don't Get Me Started needs at least 2 players to start.")),
                        );
                        return;
                      } else if (gameId == 'sync' && players.length < 2) {
                          snackbarKey.currentState?.showSnackBar(
                          const SnackBar(content: Text("Sync needs at least 2 players to start.")),
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
            print('DEBUG: ConnectionState: Waiting'); // Added debug
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            print("GTLGS(Stream): Error: ${snapshot.error}");
            return Center(child: Text('Error loading game data: ${snapshot.error}'));
          }
          if (snapshot.data == null || !snapshot.data!.exists) {
            print("GTLGS(Stream): Data is null or does not exist. Navigating home."); // Added debug
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && ModalRoute.of(context)?.isCurrent == true) {
                Navigator.popUntil(context, ModalRoute.withName('/home'));
              }
            });
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Room not found or no game data.', textAlign: TextAlign.center,),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.popUntil(context, ModalRoute.withName('/home')),
                    child: const Text('Return to Home'),
                  )
                ],
              ),
            );
          }

          // Data exists, extract room data
          final roomData = snapshot.data!.data() as Map<String, dynamic>;
          final String currentUserId = firebaseService.getCurrentUserId();

          // --- START DEBUG PRINTS ---
          print('DEBUG: --- GuessTheLiarGameScreen Debug Info ---');
          print('DEBUG: currentUserId from FirebaseService: $currentUserId');
          print('DEBUG: Room Code: ${widget.roomCode}');
          print('DEBUG: Raw roomData from Firestore: $roomData');
          print('DEBUG: Room gamePhase: ${roomData['gamePhase']}');

          List<dynamic> playersInRoom = List<dynamic>.from(roomData['players'] ?? []);
          print('DEBUG: Players array from roomData: $playersInRoom');
          print('DEBUG: Attempting to find current user in players list...');
          for (var playerEntry in playersInRoom) {
            if (playerEntry is Map<String, dynamic>) {
              print('DEBUG:   - Player entry ID: ${playerEntry['userId']}, Nickname: ${playerEntry['nickname']}'); // Corrected 'id' to 'userId'
            } else {
              print('DEBUG:   - Invalid player entry found (not a Map): $playerEntry');
            }
          }
          // --- END DEBUG PRINTS ---

          final Map<String, dynamic>? currentPlayer = playersInRoom
              .firstWhereOrNull((p) => p['userId'] == currentUserId); // Corrected 'id' to 'userId'

          if (currentPlayer == null) {
            print('DEBUG: currentPlayer is NULL. currentUserId ($currentUserId) was NOT found in the players list from Firestore.'); // Added debug
            // This should ideally not happen if the user is in the room
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && ModalRoute.of(context)?.isCurrent == true) {
                Navigator.popUntil(context, ModalRoute.withName('/home'));
              }
            });
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('You are not a player in this room. Returning to Home.', textAlign: TextAlign.center,),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.popUntil(context, ModalRoute.withName('/home')),
                    child: const Text('Return to Home'),
                  )
                ],
              ),
            );
          }

          // --- START DEBUG PRINTS (after finding current player) ---
          print('DEBUG: Current player successfully found! Nickname: ${currentPlayer['nickname']}');
          print('DEBUG: --- End GuessTheLiarGameScreen Debug Info ---');
          // --- END DEBUG PRINTS ---

          final String gamePhase = roomData['gamePhase'] as String? ?? '';
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Room Code: ${widget.roomCode}',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'Your Score: ${currentPlayer['score'] ?? 0}',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: Builder(
                    builder: (context) {
                      switch (gamePhase) {
                        case 'answering':
                          return _buildAnsweringPhaseUI(context, roomData);
                        case 'discussing':
                          return _buildDiscussingPhaseUI(context, roomData);
                        case 'voting':
                          return _buildVotingPhaseUI(context, roomData);
                        case 'reveal':
                          return _buildRevealPhaseUI(context, roomData);
                        case 'roundResults':
                          return _buildRoundResultsUI(context, roomData, currentPlayer);
                        case 'gameOver':
                          return _buildGameOverUI(context, roomData);
                        default:
                          return Center(
                            child: Text('Waiting for game to start or unknown phase: $gamePhase'),
                          );
                      }
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRoundResultsUI(BuildContext context, Map<String, dynamic> roomData, Map<String, dynamic> currentPlayer) {
    List<dynamic> players = List<dynamic>.from(roomData['players'] ?? []);
    // Sort players by score descending
    players.sort((a, b) => (b['score'] ?? 0).compareTo(a['score'] ?? 0));
    int currentRound = roomData['currentRound'] as int? ?? 0;
    int totalRounds = roomData['totalRounds'] as int? ?? 1;
    bool isHost = currentPlayer['isHost'] ?? false;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Round $currentRound Results!', style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
          const SizedBox(height: 20),
          Text('Scores:', style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
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
              },
            ),
          ),
          const SizedBox(height: 20),
          if (isHost)
            ElevatedButton(
              onPressed: () {
                if (currentRound >= totalRounds) {
                  firebaseService.nextPhase(widget.roomCode, 'gameOver');
                } else {
                  firebaseService.nextRound(widget.roomCode, widget.gameId);
                }
              },
              child: Text(currentRound >= totalRounds ? 'Show Final Results' : 'Start Next Round'),
            )
          else
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Text("Waiting for host to continue...", textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
            )
        ],
      ),
    );
  }


  Widget _buildAnsweringPhaseUI(BuildContext context, Map<String, dynamic> roomData) {
      List<dynamic> players = List<dynamic>.from(roomData['players'] ?? []);
      Map<String, dynamic>? me = players.firstWhereOrNull((p) => (p as Map)['userId'] == firebaseService.userId) as Map<String, dynamic>?;
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
                  snackbarKey.currentState?.showSnackBar(
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
                  snackbarKey.currentState?.showSnackBar(SnackBar(content: Text("Failed to submit answer: $e")));
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
    Map<String, dynamic>? me = players.firstWhereOrNull((p) => (p as Map)['userId'] == firebaseService.userId) as Map<String, dynamic>?;
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
    Map<String, dynamic>? me = players.firstWhereOrNull((p) => (p as Map)['userId'] == firebaseService.userId) as Map<String, dynamic>?;
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
        .where((p) => (p as Map)['userId'] != firebaseService.userId)
        .map((p) => Map<String, dynamic>.from(p as Map)).toList();

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
                  print("GTLGS(Voting) Error: $e");
                  snackbarKey.currentState?.showSnackBar(SnackBar(content: Text("Failed to submit vote: $e")));
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
                        (players.firstWhereOrNull((p) => (p as Map)['userId'] == _selectedPlayerToVote) // Corrected 'id' to 'userId'
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
    Map<String, dynamic>? me = players.firstWhereOrNull((p) => (p as Map)['userId'] == firebaseService.userId) as Map<String, dynamic>?; // Corrected 'id' to 'userId'
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
                child: Text("Waiting for host to continue...", textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
              )
          ],
        ),
    );
  }

  Widget _buildGameOverUI(BuildContext context, Map<String, dynamic> roomData) {
    List<dynamic> players = List<dynamic>.from(roomData['players'] ?? []);
    // Sort players by score descending
    players.sort((a, b) => (b['score'] ?? 0).compareTo(a['score'] ?? 0));

    print("GTLGS(GameOver): Building UI. Final scores: ${players.map((p) => "${(p as Map)['nickname']}: ${(p as Map)['score']}").toList()}");

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

// --- Don't Get Me Started Game Screen ---
class DontGetMeStartedGameScreen extends StatefulWidget {
  final String roomCode;
  final String gameId;

  const DontGetMeStartedGameScreen({super.key, required this.roomCode, required this.gameId});

  @override
  State<DontGetMeStartedGameScreen> createState() => _DontGetMeStartedGameScreenState();
}

class _DontGetMeStartedGameScreenState extends State<DontGetMeStartedGameScreen> {
  // Controllers for guessing players
  final List<TextEditingController> _guessControllers = List.generate(3, (_) => TextEditingController());

  // Controller for ranting player - used for personal reference now
  final TextEditingController _rantTextController = TextEditingController();
  final TextEditingController _topicController = TextEditingController();

  Timer? _timer;
  int _secondsRemaining = 0;
  bool _isLoading = false; // For submit buttons

  // Constant for the ranting phase timer
  static const int _rantingTimeSeconds = 75;

  @override
  void initState() {
    super.initState();
    // Start listening to the room stream to update timer and phases
    firebaseService.getRoomStream(widget.roomCode).listen((snapshot) {
      if (snapshot.exists) {
        Map<String, dynamic> roomData = snapshot.data() as Map<String, dynamic>;
        String gamePhase = roomData['gamePhase'] as String? ?? '';
        Timestamp? timerStartTimeStamp = roomData['timerEndTime'] as Timestamp?; // Using timerEndTime to store START time

        // The timer is active ONLY in the 'guessingAndRanting' phase
        if (gamePhase == 'guessingAndRanting' && timerStartTimeStamp != null) {
          // Calculate the actual end time based on the start timestamp + 75 seconds
          DateTime timerEndTime = timerStartTimeStamp.toDate().add(const Duration(seconds: _rantingTimeSeconds));
          _startTimer(timerEndTime);
        } else {
          _stopTimer(); // Ensure timer is stopped in other phases
          // If timer is not running, ensure _secondsRemaining is 0 (or some default like N/A)
          if (_secondsRemaining != 0) { // Optimize setState calls
            setState(() { _secondsRemaining = 0; });
          }
        }
      }
    });
  }

  void _startTimer(DateTime endTime) {
    _stopTimer(); // Stop any existing timer first
    final now = DateTime.now();
    int initialSeconds = endTime.difference(now).inSeconds;
    if (initialSeconds < 0) initialSeconds = 0; // If timer already expired

    if (_secondsRemaining != initialSeconds) { // Only update state if value changed to reduce rebuilds
      setState(() {
        _secondsRemaining = initialSeconds;
      });
    }

    // Only start periodic timer if there are seconds to count down
    if (_secondsRemaining > 0) {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        // Only call setState if the value actually changes to avoid unnecessary rebuilds
        if (_secondsRemaining > 0) {
          setState(() {
            _secondsRemaining--;
          });
        }

        if (_secondsRemaining <= 0) {
          _stopTimer();
          // If the timer ends, and we are still in guessingAndRanting,
          // automatically move to the reviewingGuesses phase if I am the ranting player
          _handleTimerEnd();
        }
      });
    } else {
      // If timer is already 0, immediately handle its end.
      _handleTimerEnd();
    }
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _handleTimerEnd() async {
    // Only the ranting player should trigger phase change automatically on timer end
    // Use a transaction to ensure we read the latest state and only update if conditions are met
    try {
      await firebaseService._firestore.runTransaction((transaction) async {
        DocumentReference roomRef = firebaseService._firestore.collection('rooms').doc(widget.roomCode);
        DocumentSnapshot roomSnap = await transaction.get(roomRef);

        if (!roomSnap.exists) {
          print("DGMS: Timer end handler: Room does not exist.");
          return;
        }

        Map<String, dynamic> roomData = roomSnap.data() as Map<String, dynamic>;
        List<dynamic> players = List<dynamic>.from(roomData['players'] ?? []);
        Map<String, dynamic>? me = players.firstWhereOrNull((p) => (p as Map)['userId'] == firebaseService.userId) as Map<String, dynamic>?;

        // Check if I am the ranting player AND the current phase is still 'guessingAndRanting'
        if (me != null && (me['isRantingPlayer'] == true) && roomData['gamePhase'] == 'guessingAndRanting') {
          print("DGMS: Ranter's client: Rant/Guess timer ended. Moving game to reviewingGuesses.");
          transaction.update(roomRef, {'gamePhase': 'reviewingGuesses'});
        } else {
          print("DGMS: Timer end handler: Not ranting player or phase changed, no action.");
        }
      });
    } catch (e) {
      print("DGMS: Error in _handleTimerEnd transaction: $e");
    }
  }

  @override
  void dispose() {
    _stopTimer();
    for (var controller in _guessControllers) {
      controller.dispose();
    }
    _rantTextController.dispose();
    _topicController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentGame = games.firstWhere((g) => g.id == widget.gameId, orElse: () => games.first);
    return Scaffold(
      appBar: AppBar(title: Text(currentGame.name)),
      body: StreamBuilder<DocumentSnapshot>(
        stream: firebaseService.getRoomStream(widget.roomCode),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            print("DGMS(Stream): Error: ${snapshot.error}");
            return Center(child: Text('Error loading game data: ${snapshot.error}'));
          }
          if (snapshot.data == null || !snapshot.data!.exists) {
            print("DGMS(Stream): Data is null or does not exist. Navigating home.");
            WidgetsBinding.instance.addPostFrameCallback((_) {
               if (mounted && ModalRoute.of(context)?.isCurrent == true) { // Kept for safety in Stateful widget
                 Navigator.popUntil(context, ModalRoute.withName('/home'));
               }
             });
            return const Center(child: Text("Game room not found or ended."));
          }

          Map<String, dynamic> roomData = snapshot.data!.data() as Map<String, dynamic>;
          String gamePhase = roomData['gamePhase'] as String? ?? 'loading';

          List<dynamic> players = List<dynamic>.from(roomData['players'] ?? []); // Define players here
          Map<String, dynamic>? me = players.firstWhereOrNull((p) => (p as Map)['userId'] == firebaseService.userId) as Map<String, dynamic>?;

          if (me == null) {
              print("DGMS(Stream): Current player (firebaseService.userId: ${firebaseService.userId}) not found in players list. Returning to home.");
              WidgetsBinding.instance.addPostFrameCallback((_) {
                 if (mounted && ModalRoute.of(context)?.isCurrent == true) { // Kept for safety in Stateful widget
                   Navigator.popUntil(context, ModalRoute.withName('/home'));
                 }
               });
              return const Center(child: Text("Player data not found. Returning to home..."));
          }

          print("DGMS(Stream): Current gamePhase: $gamePhase. IsRantingPlayer: ${me['isRantingPlayer']}");

          switch (gamePhase) {
            case 'waitingForTopicSelection':
              return _buildWaitingForTopicSelectionUI(context, roomData, me, players);
            case 'rantingPlayerSetup': // This is the "input page" phase
              return _buildRantingPlayerSetupUI(context, roomData, me, players);
            case 'guessingAndRanting': // This is the "ranting phase" with timer
              return _buildGuessingAndRantingUI(context, roomData, me, players);
            case 'reviewingGuesses':
              return _buildReviewingGuessesUI(context, roomData, me, players);
            case 'roundResults':
              return _buildRoundResultsUI(context, roomData, me, players);
            case 'gameOver':
              // Pass the full players list to _buildGameOverUI
              return _buildGameOverUI(context, roomData, players);
            default:
              return Center(child: Text('Loading game state ($gamePhase)...'));
          }
        },
      ),
    );
  }

  Widget _buildWaitingForTopicSelectionUI(BuildContext context, Map<String, dynamic> roomData, Map<String, dynamic> me, List<dynamic> allPlayers) {
    bool isRantingPlayer = me['isRantingPlayer'] ?? false;
    String currentRantingPlayerNickname = allPlayers.firstWhereOrNull((p) => (p as Map)['userId'] == roomData['currentRantingPlayerId'])?['nickname'] ?? 'Someone';
    bool isHost = me['isHost'] ?? false;

    // Pre-fill topic controller if already set in Firestore (e.g., after hot restart)
    if (isRantingPlayer) {
      _topicController.text = roomData['topic'] ?? '';
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Round ${roomData['currentRound'] ?? 1} / ${roomData['totalRounds'] ?? 1}', style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
          const SizedBox(height: 20),
          if (isRantingPlayer) ...[
            Text('You have been chosen to rant this round!', style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            TextField(
              controller: _topicController,
              decoration: const InputDecoration(hintText: 'Enter your rant topic'),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : () async {
                if (_topicController.text.trim().isEmpty) {
                  snackbarKey.currentState?.showSnackBar(const SnackBar(content: Text("Please enter a topic.")));
                  return;
                }
                setState(() => _isLoading = true);
                await firebaseService.setRanterTopic(widget.roomCode, firebaseService.userId!, _topicController.text.trim());
                setState(() => _isLoading = false);
              },
              child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Submit Topic'),
            ),
          ] else ...[
            Text('$currentRantingPlayerNickname is choosing a topic...', style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            Text('Waiting for $currentRantingPlayerNickname to submit their topic.', style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
          ],
          const SizedBox(height: 30),
          if (isHost)
            ElevatedButton(
              onPressed: _isLoading ? null : () async {
                setState(() => _isLoading = true);
                await firebaseService.skipRantingPlayer(widget.roomCode);
                setState(() => _isLoading = false);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Skip Current Player (Host Only)'),
            ),
        ],
      ),
    );
  }

  // NEW PHASE: ranter sets personal reference, others input guesses - NO TIMER
  Widget _buildRantingPlayerSetupUI(BuildContext context, Map<String, dynamic> roomData, Map<String, dynamic> me, List<dynamic> allPlayers) {
    bool isRantingPlayer = me['isRantingPlayer'] ?? false;
    String topic = roomData['topic'] ?? 'No topic chosen yet.'; // Topic is now set
    String currentRantingPlayerNickname = allPlayers.firstWhereOrNull((p) => (p as Map)['userId'] == roomData['currentRantingPlayerId'])?['nickname'] ?? 'Someone';
    bool myIsReadyInSetupPhase = me['isReadyInSetupPhase'] ?? false;

    // Pre-fill rantText controller for ranter if already set in Firestore
    if (isRantingPlayer) {
      _rantTextController.text = roomData['rantText'] ?? '';
    } else {
      // For guessers, clear guess controllers if they haven't submitted yet
      if (!(me['hasGuessed'] ?? false)) { // Only clear if not already submitted in this phase
        for (var controller in _guessControllers) {
          controller.clear();
        }
      }
    }

    // Determine how many players are ready
    int readyPlayersCount = allPlayers.where((p) => (p as Map)['isReadyInSetupPhase'] == true).length;
    int totalPlayers = allPlayers.length;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Round ${roomData['currentRound'] ?? 1} / ${roomData['totalRounds'] ?? 1}', style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
          const SizedBox(height: 20),
          Text('Topic: "$topic"', style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
          const SizedBox(height: 20),

          if (isRantingPlayer) ...[
            Text('Enter Your Personal Rant Reference (Only you see this):', style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 10),
            Expanded( // Allows rant text field to expand
              child: TextField(
                controller: _rantTextController,
                enabled: !myIsReadyInSetupPhase, // Disable once ranter is ready
                decoration: const InputDecoration(hintText: 'Type your personal reference here'),
                maxLines: null, // Allows multiple lines
                expands: true, // Takes up available vertical space
                keyboardType: TextInputType.multiline,
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 20),
            if (!myIsReadyInSetupPhase)
              ElevatedButton(
                onPressed: _isLoading ? null : () async {
                  setState(() => _isLoading = true);
                  try {
                    await firebaseService.setRanterPersonalReferenceAndReady(
                      widget.roomCode,
                      firebaseService.userId!,
                      _rantTextController.text.trim(),
                    );
                    snackbarKey.currentState?.showSnackBar(const SnackBar(content: Text("Personal reference submitted! Waiting for others...")));
                  } catch (e) {
                    print("DGMS(Setup): Error submitting personal reference and ready: $e");
                    snackbarKey.currentState?.showSnackBar(SnackBar(content: Text("Failed to submit personal reference. Please try again or check the console for details.")));
                  } finally {
                    if (mounted) {
                      setState(() => _isLoading = false);
                    }
                  }
                },
                child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Ready to Rant'),
              )
            else
              Text("Waiting for all players to be ready... ($readyPlayersCount/$totalPlayers ready)", style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
          ] else ...[ // Not the ranting player, but a guesser
            Text('Player $currentRantingPlayerNickname is preparing their rant. Enter Your Guesses:', style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            Text('Your Guesses (What do you think they will rant about?):', style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 10),
            if (!myIsReadyInSetupPhase) // Only show input fields if not yet ready
              ...List.generate(3, (index) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: TextField(
                  controller: _guessControllers[index],
                  decoration: InputDecoration(
                    hintText: 'Guess ${index + 1}',
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
              )),
            if (!myIsReadyInSetupPhase)
              ElevatedButton(
                onPressed: _isLoading ? null : () async {
                  List<String> submittedGuesses = [];
                  for (int i = 0; i < _guessControllers.length; i++) {
                    if (_guessControllers[i].text.trim().isNotEmpty) {
                      submittedGuesses.add(_guessControllers[i].text.trim());
                    }
                  }

                  if (submittedGuesses.isEmpty) {
                    snackbarKey.currentState?.showSnackBar(const SnackBar(content: Text("Please enter at least one guess.")));
                    return;
                  }

                  setState(() => _isLoading = true);
                  try {
                    await firebaseService.submitGuessesAndSetReady(widget.roomCode, firebaseService.userId!, submittedGuesses);
                    snackbarKey.currentState?.showSnackBar(const SnackBar(content: Text("Guesses submitted! Waiting for others...")));
                  } catch (e) {
                    // Keep original console log for full error object
                    print("DGMS(Setup): Error submitting guesses and ready: $e");
                    // Provide a more user-friendly message, guiding to console for details
                    snackbarKey.currentState?.showSnackBar(SnackBar(content: Text("Failed to submit guesses. Please try again or check the console for details.")));
                  } finally {
                    if (mounted) {
                      setState(() => _isLoading = false);
                    }
                  }
                },
                child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Submit My Guesses & Ready'),
              )
            else
              Text("Your guesses are submitted. Waiting for all players to be ready... ($readyPlayersCount/$totalPlayers ready)", style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
          ],
        ],
      ),
    );
  }


  Widget _buildGuessingAndRantingUI(BuildContext context, Map<String, dynamic> roomData, Map<String, dynamic> me, List<dynamic> allPlayers) {
    bool isRantingPlayer = me['isRantingPlayer'] ?? false;
    String topic = roomData['topic'] ?? 'No topic chosen yet.';
    String currentRantingPlayerNickname = allPlayers.firstWhereOrNull((p) => (p as Map)['userId'] == roomData['currentRantingPlayerId'])?['nickname'] ?? 'Someone';

    // Ranter's private text for reference
    String rantersPersonalRantText = roomData['rantText'] ?? '';

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Round ${roomData['currentRound'] ?? 1} / ${roomData['totalRounds'] ?? 1}', style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
          const SizedBox(height: 10),
          Text('Topic: "$topic"', style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
          const SizedBox(height: 20),
          // Timer is now active in this phase
          Text('Time Left: $_secondsRemaining seconds', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: _secondsRemaining < 10 ? Colors.redAccent : Colors.white70), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          if (isRantingPlayer) ...[
            Text('Your Rant Time! (Rant verbally based on the topic. This text is for your personal reference.):', style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 10),
            Expanded(
              child: Card(
                color: Theme.of(context).cardColor,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: SingleChildScrollView( // Allow scrolling for long reference text
                    child: Text(rantersPersonalRantText, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic, color: Colors.white)),
                  ),
                ),
              ),
            ),
              // No button needed for ranter here, timer governs transition.
          ] else ...[
            Text('Player $currentRantingPlayerNickname is ranting about: "$topic"', style: Theme.of(context).textTheme.bodyLarge, textAlign: TextAlign.center),
            const SizedBox(height: 10),
            Text('Your Submitted Guesses (Check them against the rant!):', style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: 1, // Only show current player's guesses
                itemBuilder: (context, _) {
                  List<dynamic> myGuesses = List<dynamic>.from(me['guesses'] ?? []);
                  if (myGuesses.isEmpty) return const Center(child: Text("You submitted no guesses for this round."));

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Your guesses:', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          // Display each guess in its own rounded rectangle (read-only)
                          ...myGuesses.asMap().entries.map((entry) {
                            Map<String, dynamic> guess = Map<String, dynamic>.from(entry.value);
                            return Card(
                              color: Theme.of(context).cardColor, // Always default color here
                              margin: const EdgeInsets.symmetric(vertical: 4.0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                                child: Text(guess['text'] ?? '', style: Theme.of(context).textTheme.bodyMedium),
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Text("Waiting for the ranting time to end...", style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
          ],
        ],
      ),
    );
  }

  Widget _buildReviewingGuessesUI(BuildContext context, Map<String, dynamic> roomData, Map<String, dynamic> me, List<dynamic> allPlayers) {
    bool isRantingPlayer = me['isRantingPlayer'] ?? false;
    String topic = roomData['topic'] ?? 'Unknown Topic';
    String rantersPersonalRantText = roomData['rantText'] ?? 'No rant text provided.'; // Only for ranter's display
    String currentRantingPlayerNickname = allPlayers.firstWhereOrNull((p) => (p as Map)['userId'] == roomData['currentRantingPlayerId'])?['nickname'] ?? 'Someone';

    // Ensure timer is stopped as this phase has no time limit
    _stopTimer();
    if (_secondsRemaining != 0) { // Optimize setState calls
      setState(() { _secondsRemaining = 0; });
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Round ${roomData['currentRound'] ?? 1} / ${roomData['totalRounds'] ?? 1}', style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
          const SizedBox(height: 10),
          Text('Topic: "$topic"', style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
          const SizedBox(height: 20),
          // No timer display in this phase

          if (isRantingPlayer) ...[
            Text("Your Rant (for personal reference):", style: Theme.of(context).textTheme.bodyLarge),
            Card(
              color: Theme.of(context).cardColor,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: SingleChildScrollView( // Allow scrolling for long reference text
                  child: Text(rantersPersonalRantText, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic, color: Colors.white)),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Review Player Guesses:', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: allPlayers.length,
                itemBuilder: (context, playerIndex) {
                  var player = allPlayers[playerIndex] as Map<String, dynamic>;
                  if (player['isRantingPlayer'] == true) return const SizedBox.shrink(); // Don't show ranter's own "guesses" for review

                  List<dynamic> guesses = List<dynamic>.from(player['guesses'] ?? []);
                  if (guesses.isEmpty) return const SizedBox.shrink(); // Hide players who didn't guess

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${player['nickname'] ?? 'Player'} guessed:', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          // Display each guess in its own rounded rectangle
                          ...guesses.asMap().entries.map((entry) {
                            int guessIndex = entry.key;
                            Map<String, dynamic> guess = Map<String, dynamic>.from(entry.value);
                            bool isCorrect = guess['isCorrect'] ?? false;

                            return Card( // Individual card for each guess
                              color: isCorrect ? Colors.green.withOpacity(0.2) : Theme.of(context).cardColor,
                              margin: const EdgeInsets.symmetric(vertical: 4.0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.0),
                                side: BorderSide(color: isCorrect ? Colors.greenAccent : Colors.transparent, width: 1.5),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(guess['text'] ?? '', style: Theme.of(context).textTheme.bodyMedium),
                                    ),
                                    // Only ranting player can toggle correctness
                                    IconButton(
                                      icon: Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: isCorrect ? Colors.greenAccent : Colors.grey,
                                            width: 2.0,
                                          ),
                                        ),
                                        child: Icon(isCorrect ? Icons.check : Icons.circle_outlined, // Checkmark for selected, outline for unselected
                                          color: isCorrect ? Colors.greenAccent : Colors.grey,
                                          size: 24,
                                        ),
                                      ),
                                      onPressed: _isLoading ? null : () async {
                                        setState(() => _isLoading = true);
                                        await firebaseService.toggleGuessCorrectness(widget.roomCode, player['userId'], guessIndex, !isCorrect);
                                        setState(() => _isLoading = false);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            // Host (who is also the ranter here) can confirm results
            ElevatedButton(
              onPressed: _isLoading ? null : () async {
                setState(() => _isLoading = true);
                await firebaseService.calculateAndApplyScoresDGMS(widget.roomCode); // Calculate scores and move to results
                setState(() => _isLoading = false);
              },
              child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Confirm Results & Continue'),
            ),
          ] else ...[ // Not the ranting player, just a guesser
            Text('Rant by $currentRantingPlayerNickname:', style: Theme.of(context).textTheme.bodyLarge),
            Card(
              color: Theme.of(context).cardColor,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                // No rant text displayed for non-ranters as it's for personal reference
                child: Text('This is where $currentRantingPlayerNickname ranted.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic, color: Colors.white54)),
              ),
            ),
            const SizedBox(height: 20),
            Text('All Guesses:', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: allPlayers.length,
                itemBuilder: (context, playerIndex) {
                  var player = allPlayers[playerIndex] as Map<String, dynamic>;
                  if (player['isRantingPlayer'] == true) return const SizedBox.shrink(); // Don't show ranter's own "guesses" for review

                  List<dynamic> guesses = List<dynamic>.from(player['guesses'] ?? []);
                  if (guesses.isEmpty) return const SizedBox.shrink(); // Hide players who didn't guess
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${player['nickname'] ?? 'Player'} guessed:', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          // Display each guess in its own rounded rectangle
                          ...guesses.asMap().entries.map((entry) {
                            Map<String, dynamic> guess = Map<String, dynamic>.from(entry.value);
                            bool isCorrect = guess['isCorrect'] ?? false;

                            return Card( // Individual card for each guess
                              color: isCorrect ? Colors.green.withOpacity(0.2) : Theme.of(context).cardColor,
                              margin: const EdgeInsets.symmetric(vertical: 4.0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.0),
                                side: BorderSide(color: isCorrect ? Colors.greenAccent : Colors.transparent, width: 1.5),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(guess['text'] ?? '', style: Theme.of(context).textTheme.bodyMedium),
                                    ),
                                    // Non-ranting players just see the status, cannot interact
                                    Icon(isCorrect ? Icons.check_circle : Icons.radio_button_off, color: isCorrect ? Colors.greenAccent : Colors.grey),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Text("Waiting for $currentRantingPlayerNickname to confirm results...", textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
            )
          ],
        ],
      ),
    );
  }

  Widget _buildRoundResultsUI(BuildContext context, Map<String, dynamic> roomData, Map<String, dynamic> me, List<dynamic> allPlayers) {
    List<dynamic> players = List<dynamic>.from(roomData['players'] ?? []);
    bool isHost = me['isHost'] ?? false;
    int currentRound = roomData['currentRound'] as int? ?? 0;
    int totalRounds = roomData['totalRounds'] as int? ?? 1;

    // Sort players by score descending
    players.sort((a, b) => (b['score'] ?? 0).compareTo(a['score'] ?? 0));

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Round $currentRound Results!', style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
          const SizedBox(height: 20),
          Text('Current Scores:', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: players.length,
              itemBuilder: (context, index) {
                var player = players[index] as Map<String, dynamic>;
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4.0),
                  child: ListTile(
                    title: Text(player['nickname'] ?? 'Player'),
                    trailing: Text("Score: ${player['score'] ?? 0}", style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.lightGreenAccent)),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          if (isHost)
            ElevatedButton(
              onPressed: _isLoading ? null : () {
                if (currentRound >= totalRounds) {
                  firebaseService.nextPhase(widget.roomCode, 'gameOver');
                } else {
                  firebaseService.nextRound(widget.roomCode, widget.gameId);
                }
              },
              child: Text(currentRound >= totalRounds ? 'Show Final Results' : 'Start Next Round'),
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

  Widget _buildGameOverUI(BuildContext context, Map<String, dynamic> roomData, List<dynamic> allPlayers) {
    List<dynamic> players = List<dynamic>.from(roomData['players'] ?? []);
    // Sort players by score descending
    players.sort((a, b) => (b['score'] ?? 0).compareTo(a['score'] ?? 0));

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
              onPressed: () => Navigator.popUntil(context, ModalRoute.withName('/home')),
              child: const Text('Return to Home'),
            )
          ],
      ),
    );
  }
}

// --- Sync Game Screen ---
class SyncGameScreen extends StatefulWidget {
  final String roomCode;
  final String gameId;

  const SyncGameScreen({super.key, required this.roomCode, required this.gameId});

  @override
  State<SyncGameScreen> createState() => _SyncGameScreenState();
}

class _SyncGameScreenState extends State<SyncGameScreen> {
  final TextEditingController _answerController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  // --- Helper methods for different game phases for SYNC game ---

  @override
  Widget build(BuildContext context) {
    final currentGame = games.firstWhere((g) => g.id == widget.gameId, orElse: () => games.first);
    return Scaffold(
      appBar: AppBar(title: Text(currentGame.name)),
      body: StreamBuilder<DocumentSnapshot>(
        stream: firebaseService.getRoomStream(widget.roomCode),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            print("SyncGS(Stream): Error: ${snapshot.error}");
            return Center(child: Text('Error loading game data: ${snapshot.error}'));
          }
          if (snapshot.data == null || !snapshot.data!.exists) {
            print("SyncGS(Stream): Data is null or does not exist. Navigating home.");
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && ModalRoute.of(context)?.isCurrent == true) {
                Navigator.popUntil(context, ModalRoute.withName('/home'));
              }
            });
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Room not found or no game data.', textAlign: TextAlign.center,),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.popUntil(context, ModalRoute.withName('/home')),
                    child: const Text('Return to Home'),
                  )
                ],
              ),
            );
          }

          // Data exists, extract room data
          final roomData = snapshot.data!.data() as Map<String, dynamic>;
          final String currentUserId = firebaseService.getCurrentUserId();
          final String gamePhase = roomData['gamePhase'] ?? 'waitingForPlayers'; // Default to waiting

          final Map<String, dynamic>? currentPlayer = (roomData['players'] as List<dynamic>?)
              ?.firstWhereOrNull((p) => p['userId'] == currentUserId);

          if (currentPlayer == null) {
            // This should ideally not happen if the user is in the room
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && ModalRoute.of(context)?.isCurrent == true) {
                Navigator.popUntil(context, ModalRoute.withName('/home'));
              }
            });
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('You are not a player in this room. Returning to Home.', textAlign: TextAlign.center,),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.popUntil(context, ModalRoute.withName('/home')),
                    child: const Text('Return to Home'),
                  )
                ],
              ),
            );
          }

          List<dynamic> allPlayers = List<dynamic>.from(roomData['players'] ?? []);

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Room Code: ${widget.roomCode}',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'Your Score: ${currentPlayer['score'] ?? 0}',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: Builder(
                    builder: (context) {
                      switch (gamePhase) {
                        case 'answeringSync':
                          return _buildAnsweringSyncUI(roomData, currentPlayer);
                        case 'revealingAnswersSync':
                          return _buildRevealingAnswersSyncUI(roomData, currentPlayer);
                        case 'roundResults': // Sync game transitions to this after revealing answers
                          return _buildRoundResultsSyncUI(roomData, currentPlayer);
                        case 'gameOver':
                          return _buildGameOverUI(context, roomData, allPlayers);
                        default:
                          // Fallback for initial loading or unexpected phases
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Game State: ${roomData['status'] ?? 'Unknown'}', style: Theme.of(context).textTheme.titleMedium),
                                Text('Phase: $gamePhase', style: Theme.of(context).textTheme.titleMedium),
                                const SizedBox(height: 20),
                                const CircularProgressIndicator(),
                                const SizedBox(height: 20),
                                Text('Waiting for host to start the game...', style: Theme.of(context).textTheme.bodyMedium),
                              ],
                            ),
                          );
                      }
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnsweringSyncUI(Map<String, dynamic> roomData, Map<String, dynamic> currentPlayer) {
    List<String> syncQuestions = firebaseService._syncQuestions;
    int currentQuestionIndex = roomData['currentQuestionIndex'] as int? ?? -1;
    String currentQuestion = currentQuestionIndex != -1 && currentQuestionIndex < syncQuestions.length
        ? syncQuestions[currentQuestionIndex]
        : 'Loading question...';

    bool hasAnswered = currentPlayer['isReadyInSyncPhase'] ?? false; // In Sync, 'isReadyInSyncPhase' indicates if answer is submitted

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Round ${roomData['currentRound'] ?? 1} / ${roomData['totalRounds'] ?? 1}',
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        Text(
          'Question:',
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              currentQuestion,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
          ),
        ),
        const SizedBox(height: 20),
        if (!hasAnswered)
          TextField(
            controller: _answerController,
            decoration: const InputDecoration(
              labelText: 'Your Answer',
              hintText: 'Type your answer here to sync!',
              border: OutlineInputBorder(),
            ),
            maxLines: 1, // Sync answers are usually short
          )
        else
          Text(
            'Your Answer: "${currentPlayer['answerSync'] ?? ''}"',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.lightGreenAccent),
            textAlign: TextAlign.center,
          ),
        const SizedBox(height: 20),
        if (!hasAnswered)
          ElevatedButton(
            onPressed: _isLoading ? null : () => _submitAnswerSync(),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Submit Answer'),
          )
        else
          Text(
            'Answer submitted! Waiting for other players...',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
      ],
    );
  }

  Widget _buildRevealingAnswersSyncUI(Map<String, dynamic> roomData, Map<String, dynamic> currentPlayer) {
    List<dynamic> players = List<dynamic>.from(roomData['players'] ?? []);
    bool isHost = roomData['hostId'] == firebaseService.getCurrentUserId();

    // Group answers using the normalized form as the key
    Map<String, List<Map<String, dynamic>>> groupedAnswers = {};
    Map<String, String> normalizedToRepresentativeOriginal = {}; // To pick one original for display

    for (var p in players) {
      final player = Map<String, dynamic>.from(p);
      String? answer = player['answerSync'] as String?;
      if (answer != null && answer.isNotEmpty) {
        String normalizedAnswer = firebaseService._normalizeAnswer(answer);

        if (!groupedAnswers.containsKey(normalizedAnswer)) {
          groupedAnswers[normalizedAnswer] = [];
          normalizedToRepresentativeOriginal[normalizedAnswer] = answer; // Store this original as the representative
        }
        groupedAnswers[normalizedAnswer]!.add(player);
      }
    }

    List<MapEntry<String, List<Map<String, dynamic>>>> sortedGroups = groupedAnswers.entries.toList();
    sortedGroups.sort((a, b) => b.value.length.compareTo(a.value.length)); // Sort by group size

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Round ${roomData['currentRound'] ?? 1} Answers & Matches!',
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        Expanded(
          child: ListView.builder(
            itemCount: sortedGroups.length,
            itemBuilder: (context, index) {
              final entry = sortedGroups[index];
              final normalizedAnswerKey = entry.key; // This is the normalized answer used for grouping
              final displayAnswer = normalizedToRepresentativeOriginal[normalizedAnswerKey] ?? normalizedAnswerKey; // Use representative original if exists, else normalized
              final playersInGroup = entry.value;
              bool isMatchedGroup = playersInGroup.length > 1;

              return Card(
                color: isMatchedGroup ? Colors.blueAccent.withOpacity(0.3) : Theme.of(context).cardColor,
                margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '"$displayAnswer"', // Display the representative original answer
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: isMatchedGroup ? Colors.lightBlueAccent : Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Players who said this (${playersInGroup.length} matched):',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8.0, // gap between adjacent chips
                        runSpacing: 4.0, // gap between lines
                        children: playersInGroup.map((player) {
                          return Chip(
                            label: Text(player['nickname'], style: const TextStyle(color: Colors.white)),
                            backgroundColor: player['userId'] == firebaseService.getCurrentUserId()
                                ? Colors.deepPurpleAccent
                                : Colors.grey[700],
                          );
                        }).toList(),
                      ),
                      if (isMatchedGroup)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            'Each player in this group gets ${playersInGroup.length} points!',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.greenAccent),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        if (isHost)
  ElevatedButton(
    onPressed: _isLoading ? null : () async {
      setState(() => _isLoading = true);
      await firebaseService.nextPhase(widget.roomCode, 'roundResults');
      setState(() => _isLoading = false);
    },
    child: _isLoading
        ? const CircularProgressIndicator(color: Colors.white)
        : const Text('Continue to Scores'),
  )
else
  Text(
    'Waiting for host to continue...',
    style: Theme.of(context).textTheme.titleMedium,
    textAlign: TextAlign.center,
  ),
      ],
    );
  }

  Widget _buildRoundResultsSyncUI(Map<String, dynamic> roomData, Map<String, dynamic> currentPlayer) {
    List<dynamic> players = List<dynamic>.from(roomData['players'] ?? []);
    bool isHost = roomData['hostId'] == firebaseService.getCurrentUserId();
    int currentRound = roomData['currentRound'] as int? ?? 0;
    int totalRounds = roomData['totalRounds'] as int? ?? 1;

    // Sort players by total score descending
    players.sort((a, b) => (b['score'] ?? 0).compareTo(a['score'] ?? 0));

    // Debug prints to confirm round values
    print("SyncGameScreen: _buildRoundResultsSyncUI: currentRound=$currentRound, totalRounds=$totalRounds");


    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Round $currentRound Results!',
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        Text(
          'Total Scores:',
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Expanded(
          child: ListView.builder(
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
            },
          ),
        ),
        const SizedBox(height: 20),
        if (isHost)
          ElevatedButton(
            onPressed: _isLoading ? null : () {
              if (currentRound >= totalRounds) {
                firebaseService.nextPhase(widget.roomCode, 'gameOver');
              } else {
                // This calls the general nextRound, which for 'sync' will
                // trigger _assignQuestionSync
                firebaseService.nextRound(widget.roomCode, widget.gameId);
              }
            },
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(currentRound >= totalRounds ? 'Show Final Results' : 'Start Next Round'),
          )
        else
          Text(
            'Waiting for host to continue...',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
      ],
    );
  }

  // Placeholder for voting phase if it's distinct from showing answers (not applicable for basic Sync)
  Widget _buildVotingPhaseUI(Map<String, dynamic> roomData, Map<String, dynamic> currentPlayer) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Voting in progress...',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          CircularProgressIndicator(),
          SizedBox(height: 20),
          Text(
            'Waiting for all players to vote or host to advance.',
            textAlign: TextAlign.center,
          )
        ],
      ),
    );
  }

  // --- Original _buildGameOverUI method, now correctly placed inside _SyncGameScreenState ---
  Widget _buildGameOverUI(BuildContext context, Map<String, dynamic> roomData, List<dynamic> allPlayers) {
    List<dynamic> players = List<dynamic>.from(roomData['players'] ?? []);
    // Sort players by score descending
    players.sort((a, b) => (b['score'] ?? 0).compareTo(a['score'] ?? 0));

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
              onPressed: () => Navigator.popUntil(context, ModalRoute.withName('/home')),
              child: const Text('Return to Home'),
            )
          ],
      ),
    );
  }

  // --- Firebase Interactions for Sync Game ---

  Future<void> _submitAnswerSync() async {
    if (_answerController.text.trim().isEmpty) {
      snackbarKey.currentState?.showSnackBar(
        const SnackBar(content: Text('Please enter an answer.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await firebaseService.submitAnswerSync(
        widget.roomCode,
        firebaseService.getCurrentUserId(),
        _answerController.text.trim(),
      );
      _answerController.clear(); // Clear the input field after submission
    } catch (e) {
      print("Error submitting Sync answer: $e");
      snackbarKey.currentState?.showSnackBar(
        SnackBar(content: Text('Error submitting answer: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _nextRoundOrEndGame() async {
    setState(() {
      _isLoading = true;
    });
    try {
      await firebaseService.nextRoundOrEndGame(widget.roomCode);
    } catch (e) {
      print("Error advancing game: $e");
      snackbarKey.currentState?.showSnackBar(
        SnackBar(content: Text('Error advancing game: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
