import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:async';
import 'dart:math';
import 'package:collection/collection.dart'; 
import 'package:flutter/services.dart'; 

import '../firebase_options.dart'; 
import '../models/question_model.dart'; 

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? userId;
  String? nickname;

  Future<void> nextRoundOrEndGame(String roomCode) async {
    final roomRef = _firestore.collection('rooms').doc(roomCode);
    await _firestore.runTransaction((transaction) async {
      final roomSnapshot = await transaction.get(roomRef);
      if (!roomSnapshot.exists) throw Exception("Room does not exist!");

      int currentRound = roomSnapshot.data()?['currentRound'] ?? 1;
      int maxRounds = roomSnapshot.data()?['totalRounds'] ?? 3;
      String gameId = roomSnapshot.data()?['gameId'] ?? '';

      if (currentRound < maxRounds) {
        await nextRound(roomCode, gameId); 
      } else {
        await transaction.update(roomRef, {'gamePhase': 'gameOver'});
      }
    });
  }

  Future<void> endRound(String roomCode) async {
    final roomRef = _firestore.collection('rooms').doc(roomCode);
    await _firestore.runTransaction((transaction) async {
      final roomSnapshot = await transaction.get(roomRef);
      if (!roomSnapshot.exists) throw Exception("Room does not exist!");

      transaction.update(roomRef, {
        'gamePhase': 'roundResults', 
      });
    });
  }

  String getCurrentUserId() {
    return userId ?? '';
  }

  // --- MOST LIKELY TO QUESTIONS ---
  final List<String> mltQuestions = [
    "Who is most likely to accidentally set the kitchen on fire?",
    "Who is most likely to become a millionaire?",
    "Who is most likely to survive a zombie apocalypse?",
    "Who is most likely to forget their own birthday?",
    "Who is most likely to get arrested for something stupid?",
    "Who is most likely to win a reality TV show?",
    "Who is most likely to fall asleep in a movie theater?",
    "Who is most likely to trip on a flat surface?",
    "Who is most likely to adopt 10 cats?",
    "Who is most likely to move to another country on a whim?",
    "Who is most likely to cry during a sad commercial?",
    "Who is most likely to become a famous actor?",
    "Who is most likely to join a cult by accident?",
    "Who is most likely to win the lottery and lose the ticket?",
    "Who is most likely to talk their way out of a speeding ticket?",
    "Who is most likely to laugh at an inappropriate moment?",
    "Who is most likely to eat something off the floor?",
    "Who is most likely to accidentally text their boss something embarrassing?",
    "Who is most likely to survive alone on a deserted island?",
    "Who is most likely to secretly be a spy?"
  ];

  // --- GUESS THE LIAR QUESTIONS (ALL PRESERVED) ---
  final List<QuestionPair> _guessTheLiarQuestionPairs = [
    const QuestionPair(original: "What's your favorite thing to do on a rainy day?", liar: "What's your favorite thing to do on a sunny day?"),
    const QuestionPair(original: "If you could have any superpower, what would it be and why?", liar: "If you could have any animal as a pet, what would it be and why?"),
    const QuestionPair(original: "What's the most unusual food you've ever tried?", liar: "What's the most unusual drink you've ever tried?"),
    const QuestionPair(original: "Describe your ideal vacation.", liar: "Describe your worst vacation."),
    const QuestionPair(original: "What's a skill you've always wanted to learn?", liar: "What's a skill you wish you could unlearn?"),
    const QuestionPair(original: "What's your most memorable childhood toy?", liar: "What's your most regrettable childhood toy?"),
    const QuestionPair(original: "If you could live in any fictional world, where would it be?", liar: "If you could live in any historical era, when and where would it be?"),
    const QuestionPair(original: "What's one thing you're surprisingly good at?", liar: "What's one thing you're surprisingly bad at?"),
    const QuestionPair(original: "What's the best piece of advice you've ever received?", liar: "What's the worst piece of advice you've ever received?"),
    const QuestionPair(original: "If you could invent a new holiday, what would it be about?", liar: "If you could abolish an existing holiday, which one and why?"),
    const QuestionPair(original: "What's your go-to comfort food?", liar: "What's your go-to adventurous food?"),
    const QuestionPair(original: "If you were an animal, what would you be and why?", liar: "If you were a plant, what would you be and why?"),
    const QuestionPair(original: "What's the last book you read that truly captivated you?", liar: "What's the last movie you watched that truly disappointed you?"),
    const QuestionPair(original: "What's your favorite way to relax after a long day?", liar: "What's your favorite way to get energized after a long day?"),
    const QuestionPair(original: "If you could travel anywhere in time, when and where would you go?", liar: "If you could travel anywhere in space, where would you go?"),
    const QuestionPair(original: "What's a small act of kindness that made a big impact on you?", liar: "What's a small mistake that had a big impact on you?"),
    const QuestionPair(original: "What's your favorite season and why?", liar: "What's your least favorite season and why?"),
    const QuestionPair(original: "If you could switch lives with anyone for a day, who would it be?", liar: "If you could switch ages with anyone for a day, who would it be?"),
    const QuestionPair(original: "What's a unique talent or hobby you have?", liar: "What's a common talent or hobby you lack?"),
    const QuestionPair(original: "What's your dream job, regardless of practicality?", liar: "What's your nightmare job, regardless of practicality?"),
    const QuestionPair(original: "What's the most beautiful place you've ever visited?", liar: "What's the most overrated place you've ever visited?"),
    const QuestionPair(original: "If you could meet any historical figure, who would it be?", liar: "If you could meet any future figure, who would it be?"),
    const QuestionPair(original: "What's your favorite type of music?", liar: "What's your least favorite type of music?"),
    const QuestionPair(original: "What's a movie that always makes you laugh?", liar: "What's a movie that always makes you cry?"),
    const QuestionPair(original: "What's something you're passionate about?", liar: "What's something you're indifferent about?"),
    const QuestionPair(original: "If you had a personal theme song, what would it be?", liar: "If you had a personal alarm sound, what would it be?"),
    const QuestionPair(original: "What's your favorite board game or card game?", liar: "What's your least favorite board game or card game?"),
    const QuestionPair(original: "What's a piece of technology you can't live without?", liar: "What's a piece of technology you wish never existed?"),
    const QuestionPair(original: "What's your favorite way to spend a weekend?", liar: "What's your least favorite way to spend a weekend?"),
    const QuestionPair(original: "If you could learn any language instantly, which one would it be?", liar: "If you could unlearn any language instantly, which one would it be?"),
    const QuestionPair(original: "What's the best concert you've ever attended?", liar: "What's the worst concert you've ever attended?"),
    const QuestionPair(original: "What's your favorite type of weather?", liar: "What's your least favorite type of weather?"),
    const QuestionPair(original: "If you could have dinner with three people, living or dead, who would they be?", liar: "If you could avoid dinner with three people, living or dead, who would they be?"),
    const QuestionPair(original: "What's a food you absolutely refuse to eat?", liar: "What's a food you could eat every day and never get tired of?"),
    const QuestionPair(original: "What's your favorite form of exercise?", liar: "What's your least favorite form of exercise?"),
    const QuestionPair(original: "If you could design your own house, what unique feature would it have?", liar: "If you could design your own nightmare house, what unique feature would it have?"),
    const QuestionPair(original: "What's a cause you strongly believe in?", liar: "What's a cause you are completely indifferent to?"),
    const QuestionPair(original: "What's your favorite memory from school?", liar: "What's your most embarrassing memory from school?"),
    const QuestionPair(original: "If you could instantly become an expert in any field, what would it be?", liar: "If you could instantly forget everything about one field, what would it be?"),
    const QuestionPair(original: "What's your favorite fictional character?", liar: "What's your least favorite fictional character?"),
    const QuestionPair(original: "What's a skill you're currently trying to master?", liar: "What's a skill you gave up trying to master?"),
    const QuestionPair(original: "What's your favorite type of art?", liar: "What's a type of art you just don't understand?"),
    const QuestionPair(original: "If you could witness any event in history, what would it be?", liar: "If you could prevent any event in history, what would it be?"),
    const QuestionPair(original: "What's your favorite dessert?", liar: "What's your least favorite dessert?"),
    const QuestionPair(original: "What's something that always brings a smile to your face?", liar: "What's something that always makes you roll your eyes?"),
    const QuestionPair(original: "If you could send a message to your past self, what would it say?", liar: "If you could send a message to your future self, what would it say?"),
    const QuestionPair(original: "What's your favorite animal?", liar: "What's an animal you're secretly afraid of?"),
    const QuestionPair(original: "What's a place you dream of visiting but haven't yet?", liar: "What's a place you visited and would never go back to?"),
    const QuestionPair(original: "What's your favorite childhood memory?", liar: "What's your most cringe-worthy childhood memory?"),
    const QuestionPair(original: "If you had to eat one meal for the rest of your life, what would it be?", liar: "If you had to avoid one meal for the rest of your life, what would it be?"),
    const QuestionPair(original: "What's the most adventurous thing you've ever done?", liar: "What's the most boring thing you've ever done?"),
    const QuestionPair(original: "What's your favorite holiday?", liar: "What's a holiday you find overrated?"),
    const QuestionPair(original: "If you could give one piece of advice to everyone, what would it be?", liar: "If you could un-give one piece of advice to everyone, what would it be?"),
    const QuestionPair(original: "What's your favorite way to travel?", liar: "What's your least favorite way to travel?"),
    const QuestionPair(original: "What's a habit you're trying to break or form?", liar: "What's a habit you secretly enjoy but shouldn't?"),
    const QuestionPair(original: "What's your favorite type of story (book, movie, etc.)?", liar: "What's a type of story you actively avoid?"),
    const QuestionPair(original: "If you could invent a new color, what would it be called?", liar: "If you could eliminate a color from the spectrum, which one would it be?"),
    const QuestionPair(original: "What's your favorite thing about yourself?", liar: "What's one thing you'd change about yourself if you could?"),
    const QuestionPair(original: "What's a challenge you've overcome?", liar: "What's a challenge you're still struggling with?"),
    const QuestionPair(original: "What's your favorite sound?", liar: "What's a sound that instantly annoys you?"),
    const QuestionPair(original: "If you could have any car, what would it be?", liar: "If you had to drive one car for the rest of your life, what would it be?"),
    const QuestionPair(original: "What's your favorite thing to cook or bake?", liar: "What's your least favorite thing to cook or bake?"),
    const QuestionPair(original: "What's a historical period you find most fascinating?", liar: "What's a historical period you find most depressing?"),
    const QuestionPair(original: "What's your favorite scent?", liar: "What's a scent you absolutely hate?"),
    const QuestionPair(original: "If you could instantly solve one world problem, what would it be?", liar: "If you could instantly create one world problem, what would it be?"),
    const QuestionPair(original: "What's your favorite way to express creativity?", liar: "What's a way you're completely uncreative?"),
    const QuestionPair(original: "What's a piece of advice you'd give to your younger self?", liar: "What's a piece of advice your younger self would ignore?"),
    const QuestionPair(original: "What's your ideal way to spend a snow day?", liar: "What's your ideal way to spend a scorching hot day?"),
    const QuestionPair(original: "What's your favorite type of flower?", liar: "What's a type of plant you dislike?"),
    const QuestionPair(original: "If you could have a conversation with any animal, which one would it be?", liar: "If you could swap bodies with any animal, which one would it be?"),
    const QuestionPair(original: "What's your favorite type of weather for sleeping?", liar: "What's your least favorite type of weather for sleeping?"),
    const QuestionPair(original: "What's a small pleasure that makes your day better?", liar: "What's a small annoyance that makes your day worse?"),
    const QuestionPair(original: "If you could live anywhere in the world, where would it be?", liar: "If you had to live in the most remote place on Earth, where would it be?"),
    const QuestionPair(original: "What's your favorite sport to watch or play?", liar: "What's a sport you just don't understand?"),
    const QuestionPair(original: "What's a new skill you're hoping to learn this year?", liar: "What's an old skill you're glad you don't need anymore?"),
    const QuestionPair(original: "What's your favorite way to celebrate a birthday?", liar: "What's your least favorite way to celebrate a birthday?"),
    const QuestionPair(original: "If you could have a personal chef, what cuisine would they specialize in?", liar: "If you had to eat bland food for a month, what would be the first flavorful thing you'd eat?"),
    const QuestionPair(original: "What's your favorite type of tree?", liar: "What's your favorite type of bush?"),
    const QuestionPair(original: "What's a dream you've had that felt incredibly real?", liar: "What's a nightmare you've had that felt incredibly real?"),
    const QuestionPair(original: "If you could change one thing about the world, what would it be?", liar: "If you could make one thing worse about the world, what would it be?"),
    const QuestionPair(original: "What's your favorite type of footwear?", liar: "What's your least favorite type of footwear?"),
    const QuestionPair(original: "What's a piece of art that deeply moved you?", liar: "What's a piece of art that completely confused you?"),
    const QuestionPair(original: "What's your favorite type of cloud?", liar: "What's your favorite type of sky?"),
    const QuestionPair(original: "If you could be a character in a video game, who would you be?", liar: "If you had to be a villain in a video game, who would you be?"),
    const QuestionPair(original: "What's your favorite way to drink coffee or tea?", liar: "What's your least favorite way to drink coffee or tea?"),
    const QuestionPair(original: "What's a historical event you wish you could have witnessed?", liar: "What's a historical event you wish you could prevent?"),
    const QuestionPair(original: "What's your favorite type of bird?", liar: "What's a type of bird you find annoying?"),
    const QuestionPair(original: "If you could instantly master any musical instrument, which would it be?", liar: "If you had to play only one musical instrument for the rest of your life, which would it be?"),
    const QuestionPair(original: "What's your favorite type of cheese?", liar: "What's a cheese you absolutely cannot stand?"),
    const QuestionPair(original: "What's a sound that instantly relaxes you?", liar: "What's a sound that instantly makes you tense?"),
    const QuestionPair(original: "If you could design a new flag for your country, what would it look like?", liar: "If you could design a new currency for your country, what would it look like?"),
    const QuestionPair(original: "What's your favorite type of bread?", liar: "What's a type of bread you avoid?"),
    const QuestionPair(original: "What's a memory that always makes you smile?", liar: "What's a memory that always makes you cringe?"),
    const QuestionPair(original: "If you could have any animal as a pet, what would it be?", liar: "If you had to have a mythical creature as a pet, what would it be?"),
    const QuestionPair(original: "What's your favorite way to spend a quiet evening?", liar: "What's your favorite way to spend a loud evening?"),
    const QuestionPair(original: "What's a piece of advice you'd give to a new parent?", liar: "What's a piece of advice you'd give to a new villain?"),
    const QuestionPair(original: "What's your favorite type of fruit?", liar: "What's a fruit you find disgusting?"),
    const QuestionPair(original: "What's a book you think everyone should read?", liar: "What's a book you think no one should read?"),
    const QuestionPair(original: "If you could have a superpower that only worked on Tuesdays, what would it be?", liar: "If you could have a useless superpower, what would it be?"),
    const QuestionPair(original: "What's your favorite type of pasta?", liar: "What's a pasta shape you find unappealing?"),
    const QuestionPair(original: "What's a place you've visited that exceeded your expectations?", liar: "What's a place you visited that completely underwhelmed you?"),
    const QuestionPair(original: "What's your favorite type of vegetable?", liar: "What's a vegetable you refuse to eat?"),
    const QuestionPair(original: "If you could instantly learn to play any sport, which would it be?", liar: "If you had to play one sport for the rest of your life, which would it be?"),
    const QuestionPair(original: "What's your favorite type of candy?", liar: "What's a candy you would throw away?"),
    const QuestionPair(original: "What's a piece of technology you wish existed?", liar: "What's a piece of technology you wish had never been invented?"),
    const QuestionPair(original: "What's your favorite type of sandwich?", liar: "What's the weirdest sandwich you've ever had?"),
    const QuestionPair(original: "If you could have a conversation with your future self, what would you ask?", liar: "If you could have a conversation with your past self, what would you warn them about?"),
    const QuestionPair(original: "What's your favorite type of soup?", liar: "What's a soup you would never order?"),
    const QuestionPair(original: "What's a historical mystery you'd love to solve?", liar: "What's a historical mystery you wish remained unsolved?"),
    const QuestionPair(original: "What's your favorite type of pizza topping?", liar: "What's a pizza topping you consider an abomination?"),
    const QuestionPair(original: "If you could have any job in the world, what would it be?", liar: "If you had to have the most boring job in the world, what would it be?"),
    const QuestionPair(original: "What's your favorite type of ice cream flavor?", liar: "What's an ice cream flavor you think should be banned?"),
    const QuestionPair(original: "What's a memory that makes you feel nostalgic?", liar: "What's a memory that makes you feel embarrassed?"),
    const QuestionPair(original: "If you could have a personal robot, what would its primary function be?", liar: "If you could have a personal robot that only caused minor annoyances, what would be its primary function?"),
    const QuestionPair(original: "What's your favorite type of cake?", liar: "What's a type of cake you find unappetizing?"),
    const QuestionPair(original: "What's a skill you're glad you learned?", liar: "What's a skill you regret learning?"),
    const QuestionPair(original: "What's your favorite type of cookie?", liar: "What's a cookie you would never eat?"),
    const QuestionPair(original: "If you could bring back any extinct animal, which one would it be?", liar: "If you could make any animal extinct, which one would it be?"),
    const QuestionPair(original: "What's your favorite type of pie?", liar: "What's a pie you would actively avoid?"),
    const QuestionPair(original: "What's a piece of advice you'd give to someone starting a new job?", liar: "What's a piece of advice you'd give to someone trying to get fired?"),
    const QuestionPair(original: "What's your favorite type of salad dressing?", liar: "What's a salad dressing you despise?"),
    const QuestionPair(original: "If you could have a conversation with a fictional character, who would it be?", liar: "If you could have a conversation with a historical villain, who would it be?"),
    const QuestionPair(original: "What's your favorite type of cereal?", liar: "What's a cereal that leaves you disappointed?"),
    const QuestionPair(original: "What's a place you've visited that surprised you?", liar: "What's a place you visited that was exactly as you expected?"),
    const QuestionPair(original: "What's your favorite type of sauce?", liar: "What's a sauce you would never put on anything?"),
    const QuestionPair(original: "If you could instantly learn to dance any style, which would it be?", liar: "If you had to dance one style for the rest of your life, which would it be?"),
    const QuestionPair(original: "What's your favorite type of snack?", liar: "What's a snack you find incredibly unappetizing?"),
    const QuestionPair(original: "What's a piece of advice you'd give to someone moving to a new city?", liar: "What's a piece of advice you'd give to someone trying to get lost in a new city?"),
    const QuestionPair(original: "What's your favorite type of bread for toast?", liar: "What's your favorite type of spread for toast?"),
    const QuestionPair(original: "If you could have a private concert by any artist, who would it be?", liar: "If you had to attend a terrible concert, whose would it be?"),
    const QuestionPair(original: "What's your favorite type of tea?", liar: "What's a type of beverage you never drink?"),
    const QuestionPair(original: "What's a memory that makes you laugh out loud?", liar: "What's a memory that makes you silently chuckle?"),
    const QuestionPair(original: "If you could have a personal stylist, what style would you ask for?", liar: "If you had to wear one outfit for the rest of your life, what would it be?"),
    const QuestionPair(original: "What's your favorite type of nut?", liar: "What's a nut you dislike?"),
    const QuestionPair(original: "What's a piece of advice you'd give to someone learning to code?", liar: "What's a piece of advice you'd give to someone trying to break code?"),
    const QuestionPair(original: "What's your favorite type of cheese for a sandwich?", liar: "What's a cheese you would never put on a sandwich?"),
    const QuestionPair(original: "If you could be a character in a book, who would you be?", liar: "If you had to be a minor character in a book, who would you be?"),
    const QuestionPair(original: "What's your favorite type of cracker?", liar: "What's a cracker you find bland?"),
    const QuestionPair(original: "What's a place you've visited that felt magical?", liar: "What's a place you've visited that felt mundane?"),
    const QuestionPair(original: "What's your favorite type of jam or jelly?", liar: "What's a condiment you find unnecessary?"),
    const QuestionPair(original: "If you could instantly learn to cook any cuisine, which would it be?", liar: "If you had to eat one cuisine for the rest of your life, which would it be?"),
    const QuestionPair(original: "What's your favorite type of chip?", liar: "What's a chip flavor you actively avoid?"),
    const QuestionPair(original: "What's a piece of advice you'd give to someone starting a business?", liar: "What's a piece of advice you'd give to someone trying to fail a business?"),
    const QuestionPair(original: "What's your favorite type of rice dish?", liar: "What's a grain you rarely eat?"),
    const QuestionPair(original: "If you could have a personal masseuse, what type of massage would you prefer?", liar: "If you could have a personal alarm clock, what sound would it make?"),
    const QuestionPair(original: "What's your favorite type of bean?", liar: "What's a legume you dislike?"),
    const QuestionPair(original: "What's a memory that makes you feel grateful?", liar: "What's a memory that makes you feel ungrateful?"),
    const QuestionPair(original: "If you could have a personal assistant, what would be their most important task?", liar: "If you could have a personal nemesis, who would it be?"),
    const QuestionPair(original: "What's your favorite type of grain?", liar: "What's a food group you try to avoid?"),
    const QuestionPair(original: "What's a piece of advice you'd give to someone planning a wedding?", liar: "What's a piece of advice you'd give to someone planning a chaotic event?"),
    const QuestionPair(original: "What's your favorite type of spice?", liar: "What's a spice you never use?"),
    const QuestionPair(original: "If you could instantly learn to speak to animals, which would you talk to first?", liar: "If you could instantly learn to speak to inanimate objects, what would you talk to first?"),
    const QuestionPair(original: "What's your favorite type of herb?", liar: "What's a plant you avoid touching?"),
    const QuestionPair(original: "What's a memory that makes you feel proud?", liar: "What's a memory that makes you feel ashamed?"),
    const QuestionPair(original: "If you could have a personal trainer, what kind of workout would you do?", liar: "If you had to invent a new Olympic sport, what would it be?"),
    const QuestionPair(original: "What's your favorite type of seed?", liar: "What's a topping you always remove?"),
    const QuestionPair(original: "What's a piece of advice you'd give to someone going to college?", liar: "What's a piece of advice you'd give to someone dropping out of college?"),
    const QuestionPair(original: "What's your favorite type of dressing for a chicken salad?", liar: "What's your least favorite ingredient in a chicken salad?"),
    const QuestionPair(original: "If you could have a personal gardener, what kind of garden would you have?", liar: "If you had to live in a jungle for a month, what would you miss most?"),
    const QuestionPair(original: "What's your favorite type of mushroom?", liar: "What's a vegetable you find spooky?"),
    const QuestionPair(original: "What's a memory that makes you feel loved?", liar: "What's a memory that makes you feel misunderstood?"),
  ];

  // --- SYNC QUESTIONS (ALL PRESERVED) ---
  final List<String> syncQuestions = [
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
    "Name something associated with good luck.",
    "Name a cartoon character you loved as a kid.",
    "Name a game we always ended up playing together.",
    "Name a food we always have at family dinners.",
    "Name a song that reminds you of a holiday party.",
    "Name a video game everyone played at some point.",
    "Name a classic movie we all watched on repeat.",
    "Name a place we went on a family vacation.",
    "Name a chore you always tried to avoid.",
    "Name a type of pizza topping.",
    "Name a well-known superhero.",
    "Name a candy bar you would buy at a movie theater.",
    "Name a subject we all struggled with in school.",
    "Name a store we would always go to on a trip.",
    "Name something you'd find in a kitchen cabinet.",
    "Name a type of soda.",
    "Name a piece of playground equipment.",
    "Name a type of ice cream flavor.",
    "Name a board game that took forever to finish.",
    "Name a fast food restaurant.",
    "Name a holiday tradition our family has.",
    "Name a TV show we all watched growing up.",
    "Name a type of shoe.",
    "Name a kind of soup.",
    "Name a famous fictional character.",
    "Name a type of snack food.",
    "Name a kind of bread.",
    "Name something you can bake.",
    "Name a type of dance.",
    "Name a famous singer.",
    "Name a common house plant.",
    "Name a type of cookie.",
    "Name a type of vegetable.",
    "Name a well-known movie genre.",
    "Name a sound an animal makes.",
    "Name a type of car.",
    "Name a famous monument.",
    "Name a type of salad dressing.",
    "Name a type of nut.",
    "Name a piece of technology we can't live without.",
    "Name a type of breakfast cereal.",
    "Name a type of puzzle game.",
    "Name something you'd find in a library.",
    "Name a type of toy you had as a kid.",
    "Name a type of berry.",
    "Name a famous actor.",
    "Name a kind of sandwich.",
    "Name a type of sauce.",
    "Name a type of bean.",
    "Name a place you went for dinner in the UAE.",
    "Name something you'd pack for a camping trip.",
    "Name a type of animal.",
    "Name a type of music genre.",
    "Name a famous river.",
    "Name a type of exercise.",
    "Name a type of building.",
    "Name a well-known fairy tale.",
    "Name a type of pizza.",
    "Name something you'd find in a refrigerator.",
    "Name a common emotion.",
    "Name a type of juice.",
    "Name a type of cloud.",
    "Name something you eat for breakfast.",
    "Name a type of hat.",
    "Name a character from a Disney movie.",
    "Name something you'd find on a beach.",
    "Name a type of insect.",
    "Name a part of the human body.",
    "Name a type of clothing item.",
    "Name a famous historical figure.",
    "Name a type of musical.",
    "Name a kind of salad.",
    "Name something you use to write with.",
    "Name a type of dog breed.",
    "Name a type of cat breed.",
    "Name a type of fish you'd eat.",
    "Name a piece of furniture.",
    "Name a popular hobby.",
    "Name a country in Asia.",
    "Name something you use to cook.",
    "Name a type of game that uses a controller.",
    "Name a brand of car.",
    "Name a type of pasta.",
    "Name a type of book genre.",
    "Name a famous cartoon character.",
    "Name a type of candy.",
    "Name a type of puzzle.",
    "Name a kind of cake.",
    "Name a type of seafood.",
    "Name a famous song.",
    "Name a place you'd go on vacation.",
    "Name a type of game that uses dice.",
    "Name a famous athlete.",
    "Name a type of holiday.",
    "Name a popular snack brand.",
    "Name a mythological creature.",
    "Name something associated with being a kid.",
    "Name a famous scientist.",
    "Name a piece of technology.",
    "Name a popular social media app.",
    "Name a type of ice cream.",
    "Name a type of pasta dish.",
    "Name a common household appliance.",
    "Name a piece of furniture you had as a kid.",
    "Name a type of board game.",
    "Name a type of animal you'd see on a farm.",
    "Name a specific memory from a family dinner.",
    "Name a song that reminds you of a specific cousin.",
    "Name a food we ate that was different from home.",
    "Name a specific memory from playing a game together.",
    "Name a specific inside joke we all share.",
    "Name a type of game we played when the power went out.",
    "Name a character from a game we all know.",
    "Name a type of game that involves drawing.",
    "Name a type of game that involves music.",
    "Name a memory from one of our favorite games.",
    "Name a place you'd find in your neighborhood.",
    "Most memorable family time (Happy Home)"
  ];


  static Future<void> initializeFirebase() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("FirebaseService: Initialized");
  }

  Future<void> loginOrSetNickname(String name) async {
  // Use the name directly if provided, otherwise Guest
  this.nickname = name.trim().isEmpty ? "Guest" : name.trim();
  this.userId = "user_${DateTime.now().millisecondsSinceEpoch}";
}

  Future<String?> createRoom(String gameId) async {
  return await createGameRoom(gameId, nickname ?? "Guest", totalRounds: 3);
}

Future<void> kickPlayer(String roomCode, String userIdToKick) async {
  final roomRef = _firestore.collection('rooms').doc(roomCode);
  
  await _firestore.runTransaction((transaction) async {
    final snapshot = await transaction.get(roomRef);
    if (!snapshot.exists) return;

    List<dynamic> players = List.from(snapshot.get('players') ?? []);
    // Remove the player map that matches the ID
    players.removeWhere((p) => p['userId'] == userIdToKick);
    
    transaction.update(roomRef, {'players': players});
  });
}

  Future<String?> createGameRoom(String gameId, String hostNickname, {required int totalRounds}) async {
    if (userId == null || this.nickname == null) return null;
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
            'score': 0, 
            'hasGuessed': false, 
            'guesses': [], 
            'isRantingPlayer': false, 
            'isReadyInSetupPhase': false, 
            'answerSync': null, 
            'isReadyInSyncPhase': false, 
            // NEW MLT FIELDS
            'votedFor': null, 
            'votesReceived': 0, 
          }
        ],
        'currentRound': 0, 
        'totalRounds': totalRounds, 
        'currentQuestionIndex': -1, 
        'gamePhase': '',
        'liarCaught': null, 
        'currentRantingPlayerId': null, 
        'topic': null, 
        'rantText': null, 
        'timerEndTime': null, 
        'questionsUsedSync': [], 
        'questionsUsedMLT': [], // NEW TRACKER FOR MLT
      });
      return roomCode;
    } catch (e) {
      return null;
    }
  }

  Future<bool> joinGameRoom(String roomCode, String playerJoiningNickname) async {
    if (userId == null || this.nickname == null) return false;
    try {
      DocumentReference roomRef = _firestore.collection('rooms').doc(roomCode);
      DocumentSnapshot roomSnap = await roomRef.get();

      if (!roomSnap.exists) return false;

      List<dynamic> players = List<dynamic>.from(roomSnap.get('players') ?? []);
      if (players.any((player) => player is Map && player['userId'] == userId)) return true;

      await roomRef.update({
        'players': FieldValue.arrayUnion([
          {
            'userId': userId,
            'nickname': this.nickname,
            'isHost': false,
            'score': 0, 
            'hasGuessed': false, 
            'guesses': [], 
            'isRantingPlayer': false, 
            'isReadyInSetupPhase': false, 
            'answerSync': null, 
            'isReadyInSyncPhase': false, 
            // NEW MLT FIELDS
            'votedFor': null,
            'votesReceived': 0,
          }
        ])
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Stream<DocumentSnapshot> getRoomStream(String roomCode) {
    return _firestore.collection('rooms').doc(roomCode).snapshots();
  }

  // --- MOST LIKELY TO ASSIGNMENT & LOGIC ---
  Future<void> _assignQuestionMLT(String roomCode, DocumentSnapshot roomSnap) async {
    List<dynamic> playersList = List<dynamic>.from(roomSnap.get('players') ?? []);
    List<int> questionsUsed = List<int>.from(roomSnap.get('questionsUsedMLT') ?? []);

    int questionIndex;
    if (questionsUsed.length >= mltQuestions.length) questionsUsed = []; 

    Random random = Random();
    do {
      questionIndex = random.nextInt(mltQuestions.length);
    } while (questionsUsed.contains(questionIndex));

    questionsUsed.add(questionIndex);

    List<Map<String, dynamic>> updatedPlayers = [];
    for (var player in playersList) {
      var p = Map<String, dynamic>.from(player as Map);
      p['votedFor'] = null; // Clear votes for new round
      p['votesReceived'] = 0; // Clear votes received for new round
      updatedPlayers.add(p);
    }

    await _firestore.collection('rooms').doc(roomCode).update({
      'status': 'playing',
      'gamePhase': 'votingMLT', 
      'players': updatedPlayers,
      'currentQuestionIndex': questionIndex,
      'currentQuestionText': mltQuestions[questionIndex], 
      'questionsUsedMLT': questionsUsed,
    });
  }

  Future<void> submitVoteMLT(String roomCode, String voterId, String votedPlayerId) async {
    DocumentReference roomRef = _firestore.collection('rooms').doc(roomCode);
    try {
      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot roomSnap = await transaction.get(roomRef);
        if (!roomSnap.exists) throw Exception("Room does not exist!");

        List<dynamic> players = List<dynamic>.from(roomSnap.get('players') ?? []);
        bool allHaveVoted = true;

        // Record the vote
        for (int i = 0; i < players.length; i++) {
          var player = Map<String, dynamic>.from(players[i] as Map);
          if (player['userId'] == voterId) {
            player['votedFor'] = votedPlayerId;
          }
          if (player['userId'] == votedPlayerId) {
            player['votesReceived'] = (player['votesReceived'] ?? 0) + 1;
          }
          players[i] = player; 
        }

        // Check if everyone has voted
        for (var p_check in players) {
          if ((p_check as Map<String, dynamic>)['votedFor'] == null) {
            allHaveVoted = false;
            break;
          }
        }

        Map<String, dynamic> updateData = {'players': players};
        
        // If everyone has voted, reveal the results!
        if (allHaveVoted) {
          updateData['gamePhase'] = 'revealMLT';
          
          // Find out who got the most votes
          int maxVotes = 0;
          for (var p in players) {
            int v = (p as Map)['votesReceived'] ?? 0;
            if (v > maxVotes) maxVotes = v;
          }

          // Award 1 point to the person who was voted "most likely"
          List<Map<String, dynamic>> updatedPlayersWithScores = players.map((p) {
            Map<String, dynamic> player = Map<String, dynamic>.from(p as Map);
            if ((player['votesReceived'] ?? 0) == maxVotes && maxVotes > 0) {
              player['score'] = (player['score'] ?? 0) + 1;
            }
            return player;
          }).toList();
          
          updateData['players'] = updatedPlayersWithScores;
        }
        transaction.update(roomRef, updateData);
      });
    } catch (e, st) {
      print("Error in submitVoteMLT: $e");
      rethrow; 
    }
  }


  // --- EXISTING GAME LOGIC BELOW (UNCHANGED) ---

  void _assignRolesAndQuestionsGTL(DocumentSnapshot roomSnap, String gameId, Function(Map<String, dynamic>) onUpdate) {
    List<dynamic> playersList = List<dynamic>.from(roomSnap.get('players') ?? []);
    int randomPairIndex = Random().nextInt(_guessTheLiarQuestionPairs.length);
    QuestionPair selectedPair = _guessTheLiarQuestionPairs[randomPairIndex];
    int liarIndex = Random().nextInt(playersList.length);
    List<Map<String, dynamic>> updatedPlayers = [];

    for (int i = 0; i < playersList.length; i++) {
      var player = Map<String, dynamic>.from(playersList[i] as Map);
      player['isLiar'] = (i == liarIndex);
      player['question'] = (i == liarIndex) ? selectedPair.liar : selectedPair.original; 
      player['answer'] = ''; 
      player['votedFor'] = null; 
      player['votesReceived'] = 0; 
      updatedPlayers.add(player);
    }

    onUpdate({
      'status': 'playing',
      'gamePhase': 'answering',
      'players': updatedPlayers,
      'originalQuestion': selectedPair.original, 
      'liarQuestion': selectedPair.liar, 
      'currentQuestionIndex': randomPairIndex, 
      'liarCaught': null, 
    });
  }

  Future<void> _assignRantingPlayerDGMS(String roomCode, DocumentSnapshot roomSnap) async {
    List<dynamic> playersList = List<dynamic>.from(roomSnap.get('players') ?? []);
    String? previousRantingPlayerId = roomSnap.get('currentRantingPlayerId');

    List<Map<String, dynamic>> eligiblePlayers = playersList
        .map((p) => Map<String, dynamic>.from(p))
        .where((p) => p['userId'] != previousRantingPlayerId)
        .toList();

    if (eligiblePlayers.isEmpty && playersList.isNotEmpty) {
      eligiblePlayers = playersList.map((p) => Map<String, dynamic>.from(p)).toList();
    }
    if (eligiblePlayers.isEmpty) return;

    int randomIndex = Random().nextInt(eligiblePlayers.length);
    String newRantingPlayerId = eligiblePlayers[randomIndex]['userId'];

    List<Map<String, dynamic>> updatedPlayers = [];
    for (var player in playersList) {
      var p = Map<String, dynamic>.from(player as Map);
      p['isRantingPlayer'] = (p['userId'] == newRantingPlayerId);
      p['hasGuessed'] = false; 
      p['guesses'] = []; 
      p['rantText'] = null; 
      p['isReadyInSetupPhase'] = false; 
      updatedPlayers.add(p);
    }

    await _firestore.collection('rooms').doc(roomCode).update({
      'status': 'playing',
      'gamePhase': 'waitingForTopicSelection', 
      'currentRantingPlayerId': newRantingPlayerId,
      'players': updatedPlayers,
      'topic': null, 
      'rantText': null, 
      'timerEndTime': null, 
      'liarCaught': null, 
      'originalQuestion': null, 
      'liarQuestion': null, 
    });
  }

  Future<void> _assignQuestionSync(String roomCode, DocumentSnapshot roomSnap) async {
    List<dynamic> playersList = List<dynamic>.from(roomSnap.get('players') ?? []);
    List<int> questionsUsed = List<int>.from(roomSnap.get('questionsUsedSync') ?? []);

    int questionIndex;
    if (questionsUsed.length >= syncQuestions.length) questionsUsed = []; 

    Random random = Random();
    do {
      questionIndex = random.nextInt(syncQuestions.length);
    } while (questionsUsed.contains(questionIndex));
    questionsUsed.add(questionIndex);

    List<Map<String, dynamic>> updatedPlayers = [];
    for (var player in playersList) {
      var p = Map<String, dynamic>.from(player as Map);
      p['answerSync'] = null; 
      p['isReadyInSyncPhase'] = false; 
      updatedPlayers.add(p);
    }

    await _firestore.collection('rooms').doc(roomCode).update({
      'status': 'playing',
      'gamePhase': 'answeringSync', 
      'players': updatedPlayers,
      'currentQuestionIndex': questionIndex,
      'currentQuestionText': syncQuestions[questionIndex], 
      'questionsUsedSync': questionsUsed,
    });
  }

  Future<void> startGame(String roomCode, String gameId) async {
  if (userId == null) {
    print("START_GAME: Failed - No User ID found.");
    return;
  }

  try {
    print("START_GAME: Initializing [$gameId] for room [$roomCode]");
    DocumentReference roomRef = _firestore.collection('rooms').doc(roomCode);
    DocumentSnapshot roomSnap = await roomRef.get();

    if (!roomSnap.exists) {
      print("START_GAME: Failed - Room document does not exist.");
      return;
    }

    List<dynamic> playersList = List<dynamic>.from(roomSnap.get('players') ?? []);

    // ---------------------------------------------------------
    // 1. SYNC GAME
    // ---------------------------------------------------------
    if (gameId == 'sync_game') {
      if (playersList.length < 2) {
        snackbarKey.currentState?.showSnackBar(const SnackBar(content: Text("Sync needs at least 2 players.")));
        return;
      }
      await roomRef.update({
        'status': 'playing',
        'gamePhase': 'answering', // Matches SyncGameScreen logic
        'currentRound': 1,
      });
      await _assignQuestionSync(roomCode, roomSnap);
    }

    // ---------------------------------------------------------
    // 2. GUESS THE LIAR
    // ---------------------------------------------------------
    else if (gameId == 'guess_the_liar') {
      if (playersList.length < 3) {
        snackbarKey.currentState?.showSnackBar(const SnackBar(content: Text('Liar game needs at least 3 players.')));
        return;
      }
      await roomRef.update({
        'status': 'playing',
        'gamePhase': 'answering',
        'currentRound': 1,
      });
      _assignRolesAndQuestionsGTL(roomSnap, gameId, (updateData) async {
        await roomRef.update(updateData);
      });
    }

    // ---------------------------------------------------------
    // 3. DONT GET ME STARTED
    // ---------------------------------------------------------
    else if (gameId == 'dont_get_me_started') {
      if (playersList.length < 2) {
        snackbarKey.currentState?.showSnackBar(const SnackBar(content: Text("Needs at least 2 players.")));
        return;
      }
      await roomRef.update({
        'status': 'playing',
        'gamePhase': 'ranting', // Navigation trigger
        'currentRound': 1,
      });
      await _assignRantingPlayerDGMS(roomCode, roomSnap);
    }

    // ---------------------------------------------------------
    // 4. MOST LIKELY TO
    // ---------------------------------------------------------
    else if (gameId == 'most_likely_to') {
      if (playersList.length < 3) {
        snackbarKey.currentState?.showSnackBar(const SnackBar(content: Text("Needs at least 3 players.")));
        return;
      }
      await roomRef.update({
        'status': 'playing',
        'gamePhase': 'voting',
        'currentRound': 1,
      });
      await _assignQuestionMLT(roomCode, roomSnap);
    }

    // ---------------------------------------------------------
    // 5. FALLBACK FOR OTHER GAMES
    // ---------------------------------------------------------
    else {
      await roomRef.update({
        'status': 'playing',
        'gamePhase': 'started',
        'currentRound': 1,
      });
    }

    print("START_GAME: Firestore update successful. Players should auto-navigate.");

  } catch (e) {
    print('START_GAME_ERROR: $e');
    snackbarKey.currentState?.showSnackBar(SnackBar(content: Text("Critical Error: $e")));
  }
}

  Future<void> nextRound(String roomCode, String gameId) async {
    if (userId == null) return;
    try {
      DocumentReference roomRef = _firestore.collection('rooms').doc(roomCode);
      DocumentSnapshot roomSnap = await roomRef.get();
      if (!roomSnap.exists) return;

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
      } else if (gameId == 'most_likely_to') {
        await _assignQuestionMLT(roomCode, roomSnap);
      }
    } catch (e) {
      print('Error advancing to next round: $e');
    }
  }

  Future<void> setRanterTopic(String roomCode, String playerId, String topic) async {
    try {
      DocumentReference roomRef = _firestore.collection('rooms').doc(roomCode);
      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot roomSnap = await transaction.get(roomRef);
        if (!roomSnap.exists) throw Exception("Room does not exist!");
        Map<String, dynamic> roomData = roomSnap.data() as Map<String, dynamic>;
        String currentRantingPlayerId = roomData['currentRantingPlayerId'];
        if (currentRantingPlayerId == playerId) {
          transaction.update(roomRef, {'topic': topic, 'gamePhase': 'rantingPlayerSetup'});
        }
      });
    } catch (e) { rethrow; }
  }

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
          for (int i = 0; i < players.length; i++) {
            if ((players[i] as Map)['userId'] == playerId) {
              players[i] = ranter; break;
            }
          }
          transaction.update(roomRef, {'rantText': rantText, 'players': players});
          await _checkAllPlayersReadyForRant(roomCode, transaction, roomRef, players);
        }
      });
    } catch (e) { rethrow; }
  }

  Future<void> submitGuessesAndSetReady(String roomCode, String guessingPlayerId, List<String> guesses) async {
    try {
      DocumentReference roomRef = _firestore.collection('rooms').doc(roomCode);
      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot roomSnap = await transaction.get(roomRef);
        if (!roomSnap.exists) throw Exception("Room does not exist!");
        List<dynamic> players = List<dynamic>.from(roomSnap.get('players') ?? []);
        Map<String, dynamic>? guessingPlayer = players.firstWhereOrNull((p) => p['userId'] == guessingPlayerId);
        if (guessingPlayer != null) {
          List<Map<String, dynamic>> playerGuesses = [];
          for (String guessText in guesses) {
            if (guessText.isNotEmpty) playerGuesses.add({'text': guessText, 'isCorrect': false}); 
          }
          guessingPlayer['guesses'] = playerGuesses;
          guessingPlayer['hasGuessed'] = true;
          guessingPlayer['isReadyInSetupPhase'] = true;
          for (int i = 0; i < players.length; i++) {
            if ((players[i] as Map)['userId'] == guessingPlayerId) { 
              players[i] = guessingPlayer; break;
            }
          }
          transaction.update(roomRef, {'players': players});
          await _checkAllPlayersReadyForRant(roomCode, transaction, roomRef, players);
        }
      });
    } catch (e) { rethrow; }
  }

  Future<void> _checkAllPlayersReadyForRant(String roomCode, Transaction transaction, DocumentReference roomRef, List<dynamic> currentPlayers) async {
    try {
      List<dynamic> players = currentPlayers; 
      bool allReady = true;
      for (var player in players) {
        if (! (player is Map<String, dynamic> && (player['isReadyInSetupPhase'] == true))) { 
          allReady = false; break;
        }
      }
      if (allReady) transaction.update(roomRef, {'gamePhase': 'guessingAndRanting', 'timerEndTime': FieldValue.serverTimestamp()});
    } catch (e) { rethrow; }
  }

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
              players[i] = currentPlayer; break;
            }
          }
          transaction.update(roomRef, {'players': players});
          await _checkAllPlayersReadyForSync(roomCode, transaction, roomRef, players);
        }
      });
    } catch (e) { rethrow; }
  }

  Future<void> _checkAllPlayersReadyForSync(String roomCode, Transaction transaction, DocumentReference roomRef, List<dynamic> currentPlayers) async {
    try {
      List<dynamic> players = currentPlayers;
      bool allReady = true;
      for (var player in players) {
        if (! (player is Map<String, dynamic> && (player['isReadyInSyncPhase'] == true))) {
          allReady = false; break;
        }
      }
      if (allReady) await calculateAndApplyScoresSync(roomCode, transaction, roomRef, players);
    } catch (e) { rethrow; }
  }

  Future<void> calculateAndApplyScoresSync(String roomCode, Transaction transaction, DocumentReference roomRef, List<dynamic> currentPlayers) async {
    try {
      List<Map<String, dynamic>> players = List<Map<String, dynamic>>.from(currentPlayers.map((p) => Map<String, dynamic>.from(p)));
      Map<String, List<String>> normalizedAnswersMap = {}; 
      Map<String, String> playerOriginalAnswerMapping = {}; 
      for (var player in players) {
        String? answer = player['answerSync'] as String?;
        if (answer != null && answer.isNotEmpty) {
          String normalizedAnswer = _normalizeAnswer(answer);
          if (!normalizedAnswersMap.containsKey(normalizedAnswer)) normalizedAnswersMap[normalizedAnswer] = [];
          normalizedAnswersMap[normalizedAnswer]!.add(player['userId']);
          playerOriginalAnswerMapping[player['userId']] = answer; 
        }
      }
      List<Map<String, dynamic>> updatedPlayers = [];
      for (var player in players) {
        int currentScore = player['score'] ?? 0;
        player['matchedPlayers'] = []; 
        String? originalAnswer = playerOriginalAnswerMapping[player['userId']];
        if (originalAnswer != null) {
          String normalizedAnswer = _normalizeAnswer(originalAnswer);
          List<String>? matchedUserIds = normalizedAnswersMap[normalizedAnswer];
          if (matchedUserIds != null && matchedUserIds.length > 1) {
            int pointsEarned = matchedUserIds.length;
            player['score'] = currentScore + pointsEarned;
            player['matchedPlayers'] = matchedUserIds.where((id) => id != player['userId']).toList();
          }
        }
        updatedPlayers.add(player);
      }
      transaction.update(roomRef, {'players': updatedPlayers, 'gamePhase': 'revealingAnswersSync'});
    } catch (e) { rethrow; }
  }

  String _normalizeAnswer(String answer) {
    String normalized = answer.toLowerCase();
    normalized = normalized.replaceAll(RegExp(r'[^\p{L}\p{N}\s]', unicode: true), ''); 
    normalized = normalized.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.endsWith('es')) {
      normalized = normalized.substring(0, normalized.length - 2);
    } else if (normalized.endsWith('s') && normalized.length > 1 && !normalized.endsWith('ss')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
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
        if (currentRantingPlayer == null || currentRantingPlayer['isRantingPlayer'] != true) return; 
        Map<String, dynamic>? guesserPlayer = players.firstWhereOrNull((p) => p['userId'] == guesserId);
        if (guesserPlayer != null && guesserPlayer['guesses'] != null && guesserPlayer['guesses'].length > guessIndex) {
          guesserPlayer['guesses'][guessIndex]['isCorrect'] = isCorrect;
          for (int i = 0; i < players.length; i++) {
            if ((players[i] as Map)['userId'] == guesserId) {
              players[i] = guesserPlayer; break;
            }
          }
          transaction.update(roomRef, {'players': players});
        }
      });
    } catch (e) { rethrow; }
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
            int correctGuessesByOthers = players.where((otherPlayer) {
              if ((otherPlayer as Map)['userId'] == currentRantingPlayerId) return false; 
              List<dynamic> guesses = (otherPlayer as Map)['guesses'] ?? [];
              return guesses.any((guess) => (guess as Map)['isCorrect'] == true);
            }).length;
            p['score'] = currentScore + correctGuessesByOthers; 
          } else {
            List<dynamic> guesses = p['guesses'] ?? [];
            int myCorrectGuesses = guesses.where((guess) => (guess as Map)['isCorrect'] == true).length;
            p['score'] = currentScore + myCorrectGuesses; 
          }
          updatedPlayers.add(p);
        }
        transaction.update(roomRef, {'players': updatedPlayers, 'gamePhase': 'roundResults'});
      });
    } catch (e) { rethrow; }
  }

  Future<void> skipRantingPlayer(String roomCode) async {
    if (userId == null) return;
    try {
      DocumentReference roomRef = _firestore.collection('rooms').doc(roomCode);
      DocumentSnapshot roomSnap = await roomRef.get();
      if (!roomSnap.exists) return;
      Map<String, dynamic> roomData = roomSnap.data() as Map<String, dynamic>;
      List<dynamic> players = List<dynamic>.from(roomData['players'] ?? []);
      Map<String, dynamic>? hostPlayer = players.firstWhereOrNull((p) => p['userId'] == userId);
      if (hostPlayer == null || hostPlayer['isHost'] != true) return;
      await nextRound(roomCode, roomData['gameId']);
    } catch (e) { rethrow; }
  }

  Future<void> submitAnswer(String roomCode, String playerId, String answer) async {
    if (userId == null) return;
    try {
      DocumentReference roomRef = _firestore.collection('rooms').doc(roomCode);
      DocumentSnapshot roomSnap = await roomRef.get();
      if (!roomSnap.exists) return;
      List<dynamic> players = List<dynamic>.from(roomSnap.get('players') ?? []);
      bool allHaveAnswered = true;
      for (int i = 0; i < players.length; i++) {
        var player = Map<String, dynamic>.from(players[i] as Map);
        if (player['userId'] == playerId) {
          player['answer'] = answer;
          players[i] = player; 
        }
        if (player['isLiar'] == false && (player['answer'] == null || (player['answer'] as String).isEmpty)) {
            allHaveAnswered = false;
        }
      }
      Map<String, dynamic> updateData = {'players': players};
      if (allHaveAnswered) updateData['gamePhase'] = 'discussing';
      await roomRef.update(updateData);
    } catch (e) { rethrow; }
  }

  Future<void> submitVote(String roomCode, String voterId, String votedPlayerId) async {
    if (userId == null) return;
    DocumentReference roomRef = _firestore.collection('rooms').doc(roomCode);
    try {
      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot roomSnap = await transaction.get(roomRef);
        if (!roomSnap.exists) throw Exception("Room does not exist!");
        List<dynamic> players = List<dynamic>.from(roomSnap.get('players') ?? []);
        bool allHaveVoted = true;
        for (int i = 0; i < players.length; i++) {
          var player = Map<String, dynamic>.from(players[i] as Map);
          if (player['userId'] == voterId) player['votedFor'] = votedPlayerId;
          if (player['userId'] == votedPlayerId) player['votesReceived'] = (player['votesReceived'] ?? 0) + 1;
          players[i] = player; 
        }
        for (var p_check in players) {
          if ((p_check as Map<String, dynamic>)['votedFor'] == null) {
            allHaveVoted = false; break;
          }
        }
        Map<String, dynamic> updateData = {'players': players};
        if (allHaveVoted) {
          updateData['gamePhase'] = 'reveal';
          Map<String, dynamic>? liar = players.firstWhereOrNull((p) => (p as Map)['isLiar'] == true) as Map<String, dynamic>?;
          if (liar != null) {
            int liarVotes = liar['votesReceived'] ?? 0;
            int totalPlayers = players.length;
            bool caught = liarVotes > (totalPlayers / 2); 
            updateData['liarCaught'] = caught;
            List<Map<String, dynamic>> updatedPlayersWithScores = players.map((p) {
              Map<String, dynamic> player = Map<String, dynamic>.from(p as Map);
              int currentScore = player['score'] ?? 0;
              if (player['isLiar'] == true) {
                if (!caught) player['score'] = currentScore + 1;
              } else {
                if (caught) player['score'] = currentScore + 1;
              }
              return player;
            }).toList();
            updateData['players'] = updatedPlayersWithScores;
          } else {
            updateData['liarCaught'] = false; 
          }
        }
        transaction.update(roomRef, updateData);
      });
    } catch (e) { rethrow; }
  }

  Future<void> nextPhase(String roomCode, String newPhase) async {
    if (userId == null) return;
    try {
      await _firestore.collection('rooms').doc(roomCode).update({'gamePhase': newPhase});
    } catch (e) { rethrow; }
  }

  bool get isLoggedIn => userId != null && nickname != null;
}

final GlobalKey<ScaffoldMessengerState> snackbarKey = GlobalKey<ScaffoldMessengerState>();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final FirebaseService firebaseService = FirebaseService();