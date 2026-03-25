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
    // --- THE GULF-MANGALORE LIFE ---
    "Who is most likely to try and pay a Mangalore rickshaw driver in Dirhams or Riyals?",
    "Who is most likely to complain about the Mangalore humidity within 5 minutes of landing?",
    "Who is most likely to bring an entire suitcase filled only with chocolates and perfumes?",
    "Who is most likely to forget which side of the road to drive on after coming back from the Gulf?",
    "Who is most likely to spend their entire salary at Pabba’s or a local juice center in one week?",
    "Who is most likely to get stopped at airport security for having too much 'Zatar' or 'Dates' in their bag?",
    "Who is most likely to say 'In the Gulf, it’s better' during every single meal?",
    "Who is most likely to convert every price to Dirhams before deciding if something is 'cheap'?",

    // --- DIGITAL & GROUP CHAT CHAOS ---
    "Who is most likely to send a 5-minute voice note that could have been a 3-word text?",
    "Who is most likely to 'Ghost' the group chat for a month and then reply with just a sticker?",
    "Who is most likely to accidentally share a private rant in the family WhatsApp group?",
    "Who is most likely to believe a fake 'Forwarded' news message without checking Google?",
    "Who is most likely to be 'Typing...' for 20 minutes only to send a single 'Ok'?",
    "Who is most likely to have 5,000 unread emails and 100 open tabs on their phone?",
    "Who is most likely to start a YouTube channel by accident while trying to record a voice note?",

    // --- SOCIAL & FAMILY DYNAMICS ---
    "Who is most likely to argue with the GPS even when it’s clearly right?",
    "Who is most likely to be '5 minutes away' when they haven't even taken a shower yet?",
    "Who is most likely to finish everyone else's leftovers at a restaurant?",
    "Who is most likely to get lost in a mall they have visited a hundred times?",
    "Who is most likely to start a debate at a wedding just to keep things 'interesting'?",
    "Who is most likely to stay in their pajamas for three days straight during the monsoon?",
    "Who is most likely to be the 'Favorite' child but also the one who causes the most trouble?",
    "Who is most likely to forget the name of a relative they’ve known for 10 years?",

    // --- QUIRKY & CHAOTIC HABITS ---
    "Who is most likely to try and fix a broken appliance and make it explode?",
    "Who is most likely to walk into a room and completely forget why they went there?",
    "Who is most likely to laugh at their own joke before they even finish telling it?",
    "Who is most likely to keep a 'secret' snack stash that everyone already knows about?",
    "Who is most likely to wear two different socks and not notice all day?",
    "Who is most likely to fall asleep while sitting upright in a loud room?",
    "Who is most likely to win a debate they know absolutely nothing about?",
    "Who is most likely to accidentally wear their shirt inside out in public?",
    "Who is most likely to become a 'conspiracy theorist' about why the internet is slow?",

    // --- KID & FAMILY FRIENDLY ---
    "Who is most likely to be the first one to dive into a birthday cake?",
    "Who is most likely to stay up all night playing games and regret it at 7:00 AM?",
    "Who is most likely to cry during a cartoon movie?",
    "Who is most likely to become a professional sleeper if it was a real job?",
    "Who is most likely to eat the most spice and pretend it doesn't burn?",
    "Who is most likely to lose their phone while they are actually talking on it?",
    "Who is most likely to be the first person to get sunburnt at the beach?",
    "Who is most likely to try and pet a stray animal that looks dangerous?",

    // --- TRAVEL & SURVIVAL ---
    "Who is most likely to pack for a 2-day trip like they are moving away forever?",
    "Who is most likely to forget their passport on the way to the airport?",
    "Who is most likely to survive a zombie apocalypse just by being too lazy to leave the house?",
    "Who is most likely to get 'stuck' in an elevator and start a podcast while waiting?",
    "Who is most likely to accidentally join the wrong tour group while on holiday?",
    "Who is most likely to find a 'shortcut' that adds 2 hours to the trip?",
    "Who is most likely to be the loudest person in a quiet library?",
    "Who is most likely to buy something totally useless just because it was 'On Sale'?",

    // --- ADDING 30 MORE FOR THE 80+ COUNT ---
    "Who is most likely to memorize the entire menu of their favorite restaurant?",
    "Who is most likely to give the worst advice with the most confidence?",
    "Who is most likely to be caught talking to themselves in the mirror?",
    "Who is most likely to accidentally like a photo from 3 years ago while stalking someone?",
    "Who is most likely to forget where they parked the car every single time?",
    "Who is most likely to bring a power bank but forget the charging cable?",
    "Who is most likely to tell a story that lasts 30 minutes but has no ending?",
    "Who is most likely to try and 'negotiate' the price at a fixed-rate supermarket?",
    "Who is most likely to have the loudest sneeze in the entire family?",
    "Who is most likely to become a meme without trying?",
    "Who is most likely to order a salad and then eat half of your fries?",
    "Who is most likely to keep their New Year’s resolution for exactly two days?",
    "Who is most likely to accidentally send an emoji that makes a serious situation funny?",
    "Who is most likely to be the first one to start dancing at a party with no music?",
    "Who is most likely to spend their last 10 Dirhams/Riyals on a snack instead of a bus ticket?",
    "Who is most likely to claim they 'don't like drama' while being the source of it?",
    "Who is most likely to take a 'nap' that lasts for 14 hours?",
    "Who is most likely to own 50 pairs of shoes but only wear the same 2 pairs?",
    "Who is most likely to accidentally trigger Siri or Google Assistant during a quiet moment?",
    "Who is most likely to be the first one to complain that the food is 'not spicy enough'?",
    "Who is most likely to win an Olympic medal for 'Procrastination'?",
    "Who is most likely to try and use a coupon that expired in 2019?",
    "Who is most likely to be the designated 'spider remover' in the house?",
    "Who is most likely to ask 'Is it over yet?' 10 minutes into a 2-hour movie?",
    "Who is most likely to get their head stuck in something they shouldn't have put it in?",
    "Who is most likely to think they are being 'stealthy' while being extremely loud?",
    "Who is most likely to forget why they are mad at someone in the middle of an argument?",
    "Who is most likely to treat their pet like a human and their humans like pets?",
    "Who is most likely to be the first person to ask 'What's for dinner?' after finishing lunch?",
    "Who is most likely to survive purely on tea/coffee and snacks for a whole day?"
  ];

  // --- GUESS THE LIAR QUESTIONS (ALL PRESERVED) ---
  final List<QuestionPair> _guessTheLiarQuestionPairs = [
    // --- DAILY HABITS & QUIRKS ---
    QuestionPair(original: "What’s the first thing you do when you wake up?", liar: "What’s the last thing you do before going to sleep?"),
    QuestionPair(original: "What’s a chore you actually find satisfying?", liar: "What’s a chore you would pay someone else to do?"),
    QuestionPair(original: "What’s your go-to excuse for being late?", liar: "What’s your go-to excuse for leaving a party early?"),
    QuestionPair(original: "How many alarms do you set in the morning?", liar: "How many hours of sleep do you ideally need?"),
    QuestionPair(original: "What’s the most useless thing you keep in your room?", liar: "What’s the most expensive thing you keep in your room?"),
    QuestionPair(original: "What’s a sound that instantly annoys you?", liar: "What’s a sound that you find very relaxing?"),
    QuestionPair(original: "What’s the weirdest thing you’ve seen a neighbor do?", liar: "What’s the weirdest thing you’ve done in your own backyard?"),
    QuestionPair(original: "What’s your favorite way to spend a rainy afternoon?", liar: "What’s your favorite way to spend a snowy afternoon?"),
    QuestionPair(original: "What’s something you always forget to pack for a trip?", liar: "What’s something you always pack but never use?"),
    QuestionPair(original: "Which app on your phone has the most screen time?", liar: "Which app on your phone do you want to delete?"),

    // --- FOOD & TASTE ---
    QuestionPair(original: "What’s a food you hated as a kid but love now?", liar: "What’s a food you loved as a kid but hate now?"),
    QuestionPair(original: "If you could only eat one snack for the rest of your life, what is it?", liar: "If you had to ban one snack from the world, what would it be?"),
    QuestionPair(original: "What’s the best thing your mom or dad cooks?", liar: "What’s the worst thing you’ve ever tried to cook?"),
    QuestionPair(original: "What’s a topping that should NEVER be on a pizza?", liar: "What’s a topping that every pizza MUST have?"),
    QuestionPair(original: "If you were a flavor of ice cream, what would you be?", liar: "If you were a type of vegetable, what would you be?"),
    QuestionPair(original: "What’s the spiciest thing you’ve ever eaten?", liar: "What’s the sourest thing you’ve ever eaten?"),
    QuestionPair(original: "What’s your favorite thing to eat for breakfast?", liar: "What’s your favorite thing to eat for a midnight snack?"),
    QuestionPair(original: "What’s a drink you find absolutely disgusting?", liar: "What’s a drink you could have every single day?"),
    QuestionPair(original: "If you could design a new candy, what would it taste like?", liar: "If you could invent a new soda flavor, what would it be?"),
    QuestionPair(original: "What’s the most expensive meal you’ve ever had?", liar: "What’s the best 'cheap' meal you’ve ever had?"),

    // --- IMAGINATION & SUPERPOWERS ---
    QuestionPair(original: "If you could talk to one species of animal, which would it be?", liar: "If you could transform into one animal, which would it be?"),
    QuestionPair(original: "What superpower would be the most useful for school?", liar: "What superpower would be the most fun for a vacation?"),
    QuestionPair(original: "If you were a ghost, who is the first person you would haunt?", liar: "If you were a ghost, where would be your favorite place to hide?"),
    QuestionPair(original: "What would you do if you were invisible for one hour?", liar: "What would you do if you could stop time for one hour?"),
    QuestionPair(original: "If you found a genie, what would your first wish be?", liar: "If you found a genie, what is the one thing you’d be afraid to wish for?"),
    QuestionPair(original: "Which fictional world would you want to live in?", liar: "Which historical time period would you want to visit?"),
    QuestionPair(original: "If you could breathe underwater, where would you go first?", liar: "If you could fly, what is the first building you’d stand on?"),
    QuestionPair(original: "If you were a superhero, what would your logo look like?", liar: "If you were a villain, what would your secret base look like?"),
    QuestionPair(original: "If you could grow a third arm, where would you put it?", liar: "If you could have an extra eye, where would you want it?"),
    QuestionPair(original: "What’s the first thing you’d buy if you won a billion dollars?", liar: "What’s the first thing you’d do if you became the President/Prime Minister?"),

    // --- FEARS & BRAVERY ---
    QuestionPair(original: "What’s a common animal that secretly scares you?", liar: "What’s a mythical creature you wish was real?"),
    QuestionPair(original: "What’s the scariest movie you’ve ever seen?", liar: "What’s the funniest movie you’ve ever seen?"),
    QuestionPair(original: "Would you rather spend a night in a cemetery or a dark forest?", liar: "Would you rather spend a night in a haunted house or an abandoned hospital?"),
    QuestionPair(original: "What’s a 'kid' thing that you are still afraid of?", liar: "What’s a 'grown-up' thing that seems really scary to you?"),
    QuestionPair(original: "What is the bravest thing you have ever done?", liar: "What is the most embarrassing thing that has happened to you in public?"),
    QuestionPair(original: "If you saw a spider in your room, what’s your first move?", liar: "If you saw a snake in your garden, what’s your first move?"),
    QuestionPair(original: "What’s a dream you’ve had that felt 100% real?", liar: "What’s a nightmare that you still remember clearly?"),
    QuestionPair(original: "Would you ever go skydiving if it was free?", liar: "Would you ever go deep-sea diving if it was free?"),

    // --- SCHOOL & WORK ---
    QuestionPair(original: "What’s a subject you’re surprisingly good at?", liar: "What’s a subject you wish you never had to study?"),
    QuestionPair(original: "Who was your most favorite teacher ever?", liar: "Who was the strictest teacher you’ve ever had?"),
    QuestionPair(original: "If you could change one school rule, what would it be?", liar: "If you could add one new class to your school, what would it be?"),
    QuestionPair(original: "What’s the most embarrassing thing you did in a classroom?", liar: "What’s the funniest thing that ever happened during lunch break?"),
    QuestionPair(original: "If you could have any job in the world, what would it be?", liar: "If you had to do the most boring job in the world, what would it be?"),
    QuestionPair(original: "What’s something you’ve won a trophy or medal for?", liar: "What’s something you’ve worked hard at but never won an award for?"),
    QuestionPair(original: "Describe your dream school or office building.", liar: "Describe a building that you think looks really ugly."),

    // --- TRAVEL & PLACES ---
    QuestionPair(original: "Where is the most beautiful place you have ever been?", liar: "Where is the most crowded place you have ever been?"),
    QuestionPair(original: "If you could move to any country tomorrow, where would it be?", liar: "If you had to live on a boat for a year, where would you sail?"),
    QuestionPair(original: "What’s the longest car ride you’ve ever taken?", liar: "What’s the scariest plane ride you’ve ever taken?"),
    QuestionPair(original: "What is one city you never want to visit again?", liar: "What is one city that is at the top of your bucket list?"),
    QuestionPair(original: "If you could build a house anywhere, where would it be?", liar: "If you had to live in a treehouse, what features would it have?"),
    QuestionPair(original: "What’s the best souvenir you’ve ever bought?", liar: "What’s the most useless thing you’ve ever bought while on holiday?"),

    // --- HOBBIES & TALENTS ---
    QuestionPair(original: "What’s a skill you’ve spent a lot of time practicing?", liar: "What’s a skill you wish you could learn instantly?"),
    QuestionPair(original: "What is your secret talent that not many people know about?", liar: "What is a talent you wish you had so you could show off?"),
    QuestionPair(original: "What’s your favorite board game to play with family?", liar: "What’s a board game that always ends in an argument?"),
    QuestionPair(original: "If you could be an expert at any musical instrument, what would it be?", liar: "If you could be a famous athlete, what sport would you play?"),
    QuestionPair(original: "What’s the most difficult puzzle or game you’ve ever finished?", liar: "What’s a game you played once and then immediately uninstalled?"),

    // --- RANDOM CHAOS ---
    QuestionPair(original: "What’s the weirdest thing you’ve ever found on the ground?", liar: "What’s the most valuable thing you’ve ever lost?"),
    QuestionPair(original: "If you had to rename yourself, what name would you pick?", liar: "If you had to give a nickname to your best friend, what would it be?"),
    QuestionPair(original: "What’s something that everyone else loves but you hate?", liar: "What’s something that everyone else hates but you love?"),
    QuestionPair(original: "If you could talk to your 5-year-old self, what would you say?", liar: "If you could ask your 80-year-old self one question, what would it be?"),
    QuestionPair(original: "What’s the best gift you’ve ever received?", liar: "What’s the worst gift you’ve ever received?"),
    QuestionPair(original: "If you could be a character in any video game, who would you be?", liar: "If you could be a character in any cartoon, who would you be?"),
    QuestionPair(original: "What’s a fashion trend you think is totally ridiculous?", liar: "What’s a fashion trend from the past you want to bring back?"),
    QuestionPair(original: "What would you do if you found a door in the middle of a forest?", liar: "What would you do if you found a treasure map in your attic?"),
    QuestionPair(original: "What’s the most productive thing you did today?", liar: "What’s the most fun thing you did today?"),
    QuestionPair(original: "If you could invent a new holiday, what would we celebrate?", liar: "If you could cancel one existing holiday, which one would it be?"),

    // --- MORE SOCIAL & PERSONAL ---
    QuestionPair(original: "Who is the funniest person you know?", liar: "Who is the most serious person you know?"),
    QuestionPair(original: "What is your favorite family tradition?", liar: "What is a family tradition you find a bit annoying?"),
    QuestionPair(original: "If you could change the color of the sky, what color would it be?", liar: "If you could change the color of grass, what color would it be?"),
    QuestionPair(original: "What’s something you’re always complaining about?", liar: "What’s something you’re always bragging about?"),
    QuestionPair(original: "What is your favorite smell in the whole world?", liar: "What is a smell that makes you want to leave the room?"),
    QuestionPair(original: "If you were a king or queen, what would be your first law?", liar: "If you were a pirate captain, what would your ship be named?"),
    QuestionPair(original: "What is the most adventurous thing you’ve ever done?", liar: "What is the most 'boring' thing you actually enjoy doing?"),
    QuestionPair(original: "What’s a word you can never remember how to spell?", liar: "What’s a word you think sounds really funny when said aloud?"),
    QuestionPair(original: "What’s the best surprise you’ve ever had?", liar: "What’s a secret you kept for a really long time?"),
    QuestionPair(original: "If you could stay one age forever, what age would it be?", liar: "If you could jump 10 years into the future, would you do it?"),

    // (Adding more to reach 150...)
    QuestionPair(original: "What’s your favorite type of weather for a long walk?", liar: "What’s your favorite type of weather for staying indoors?"),
    QuestionPair(original: "What’s the most unusual pet you’ve ever seen?", liar: "What animal are you most glad is extinct?"),
    QuestionPair(original: "If you could design a theme park, what would the main ride be?", liar: "If you could design a zoo, which animal would have the biggest area?"),
    QuestionPair(original: "What’s a song you can’t help but dance to?", liar: "What’s a song you never want to hear again?"),
    QuestionPair(original: "What’s the best piece of advice you’ve ever gotten?", liar: "What’s the worst piece of advice someone actually took?"),
    QuestionPair(original: "What’s something you’re really looking forward to this year?", liar: "What’s something you did last year that you’ll never do again?"),
    QuestionPair(original: "If you could meet any famous person, who would it be?", liar: "If you could bring any historical figure back to life, who would it be?"),
    QuestionPair(original: "What’s your favorite thing about your house?", liar: "What’s one thing you would fix about your house?"),
    QuestionPair(original: "If you had a robot assistant, what’s the first task you’d give it?", liar: "If you were a robot, what would be your primary function?"),
    QuestionPair(original: "What is your favorite time of the day?", liar: "What is your favorite day of the week?"),
    QuestionPair(original: "What’s the most interesting fact you know?", liar: "What’s a total lie that sounds like it could be a fact?"),
    QuestionPair(original: "What’s something you always have in your pockets?", liar: "What’s something you always keep in your school bag/work bag?"),
    QuestionPair(original: "If you could paint a giant mural, what would you paint?", liar: "If you could design a new flag, what colors would you use?"),
    QuestionPair(original: "What’s your favorite thing to do with your best friend?", liar: "What’s a game you and your friends play most often?"),
    QuestionPair(original: "What’s the longest time you’ve gone without your phone?", liar: "What’s the longest you’ve ever stayed awake?"),
    QuestionPair(original: "What is a sound that makes you feel happy?", liar: "What is a sound that makes you feel sleepy?"),
    QuestionPair(original: "If you could spend a day as a zookeeper, which animal would you feed?", liar: "If you could spend a day as a pilot, where would you fly?"),
    QuestionPair(original: "What’s the most daring thing you’ve ever eaten?", liar: "What’s a food you think looks disgusting but tastes okay?"),
    QuestionPair(original: "If you could live in a museum, which one would it be?", liar: "If you could live in a library, what section would you sleep in?"),
    QuestionPair(original: "What’s your favorite type of tree or flower?", liar: "What’s a plant you find really annoying (like weeds or thorns)?"),
    QuestionPair(original: "What’s the first thing you look at in a toy store?", liar: "What’s the first thing you look at in a gadget store?"),
    QuestionPair(original: "If you had to wear one color for a whole month, what would it be?", liar: "If you could never wear one specific color again, what would it be?"),
    QuestionPair(original: "What’s a movie you’ve watched more than five times?", liar: "What’s a movie you turned off after only ten minutes?"),
    QuestionPair(original: "What’s the coolest thing you’ve ever built?", liar: "What’s something you tried to fix but made it worse?"),
    QuestionPair(original: "If you could talk to plants, what would you ask them?", liar: "If you could talk to the moon, what would you ask it?"),
    QuestionPair(original: "What’s the best way to cheer you up when you’re sad?", liar: "What’s the best way to calm you down when you’re angry?"),
    QuestionPair(original: "If you were a professional athlete, what would be your entrance song?", liar: "If you were a famous actor, what kind of movies would you star in?"),
    QuestionPair(original: "What is the most beautiful sunset you’ve ever seen?", liar: "What is the most beautiful building you’ve ever seen?"),
    QuestionPair(original: "If you could have any car, what would it look like?", liar: "If you could have a spaceship, what would you name it?"),
    QuestionPair(original: "What’s the best part about being your age?", liar: "What’s the hardest part about being your age?"),
    QuestionPair(original: "If you could have any creature as a loyal pet, what would it be?", liar: "If you could shrink any animal to the size of a cat, which would it be?"),
    QuestionPair(original: "What’s the most important thing to bring to a picnic?", liar: "What’s the most important thing to bring to a beach day?"),
    QuestionPair(original: "If you could travel to the bottom of the ocean, what would you look for?", liar: "If you could travel to Mars, what’s the first thing you’d do?"),
    QuestionPair(original: "What’s your favorite holiday food?", liar: "What’s your favorite birthday food?"),
    QuestionPair(original: "If you could instantly play any sport perfectly, which would it be?", liar: "If you could instantly master any language, which would it be?"),
    QuestionPair(original: "What’s a skill you think everyone should have?", liar: "What’s a skill that is totally overrated?"),
    QuestionPair(original: "If you could meet your future self, what one thing would you ask?", liar: "If you could see a video of any moment in your past, which one would it be?"),
    QuestionPair(original: "What’s the best thing about your hometown?", liar: "What’s one thing your hometown is famous for?"),
    QuestionPair(original: "If you were a magician, what would be your signature trick?", liar: "If you were a circus performer, what would you do?"),
    QuestionPair(original: "What’s the best prank you’ve ever pulled (or had pulled on you)?", liar: "What’s the funniest joke you know by heart?"),
    QuestionPair(original: "What’s something you’re really proud of achieving recently?", liar: "What’s a big goal you have for next year?"),
    QuestionPair(original: "If you could have any famous painting in your house, which one?", liar: "If you could design a new piece of furniture, what would it be?"),
    QuestionPair(original: "What’s the most relaxing place you’ve ever been?", liar: "What’s the most exciting place you’ve ever been?"),
    QuestionPair(original: "If you could listen to only one singer for a week, who?", liar: "If you could watch only one TV show for a week, what?"),
    QuestionPair(original: "What’s a hobby you’d like to start if you had more time?", liar: "What’s a hobby you tried but didn’t really like?"),
    QuestionPair(original: "What is your favorite type of dessert?", liar: "What is your favorite type of savory snack?"),
    QuestionPair(original: "If you could be a character in a book, which book?", liar: "If you could write a book, what would it be about?"),
    QuestionPair(original: "What’s something you do to help the environment?", liar: "What’s something you do to help other people?"),
    QuestionPair(original: "If you could have any view from your bedroom window, what?", liar: "If you could change the color of your house, what?"),
    QuestionPair(original: "What is the most interesting museum you’ve visited?", liar: "What is the most interesting park you’ve visited?"),
    QuestionPair(original: "If you could be a professional at any game, which one?", liar: "If you could win a world record, what would it be for?"),
    QuestionPair(original: "What is your favorite way to spend time with your family?", liar: "What is your favorite way to spend time alone?"),
    QuestionPair(original: "What’s a sound that makes you think of summer?", liar: "What’s a sound that makes you think of winter?"),
    QuestionPair(original: "If you could talk to a historical figure, who?", liar: "If you could see into the future, what would you look for?"),
    QuestionPair(original: "What’s your favorite part of a typical school/work day?", liar: "What’s the part of the day you find most boring?"),
    QuestionPair(original: "If you could design your own clothes, what style would they be?", liar: "If you could design a new pair of shoes, what would they look like?"),
    QuestionPair(original: "What is the best thing about your best friend?", liar: "What is the funniest memory you have with a friend?"),
    QuestionPair(original: "If you could have any mythical weapon, what?", liar: "If you could have any magical item, what?"),
    QuestionPair(original: "What’s something you’re always losing, like keys or socks?", liar: "What’s something you have a surprisingly large collection of?"),
    QuestionPair(original: "If you could go to any planet, which one?", liar: "If you could visit any moon in the solar system, which?"),
    QuestionPair(original: "What’s your favorite way to travel – train, plane, or car?", liar: "What’s the most unusual vehicle you’ve ever been in?"),
    QuestionPair(original: "If you could create a new flavor of chips, what?", liar: "If you could create a new flavor of juice, what?"),
    QuestionPair(original: "What is the most brave thing you’ve seen someone else do?", liar: "What is the most kind thing you’ve seen someone else do?"),
    QuestionPair(original: "If you could have any animal as a sidekick, which?", liar: "If you were an animal sidekick, who would your hero be?"),
    QuestionPair(original: "What’s the most beautiful garden you’ve ever seen?", liar: "What’s the most beautiful forest you’ve ever seen?"),
    QuestionPair(original: "If you could solve one mystery in the world, what?", liar: "If you could discover a new animal species, what?"),
    QuestionPair(original: "What is your favorite thing about your favorite season?", liar: "What is your least favorite thing about your favorite season?"),
    QuestionPair(original: "If you could be a voice actor for a movie, what kind of character?", liar: "If you could be a stunt double, what kind of stunt?"),
    QuestionPair(original: "What’s something that always makes you feel better when you’re sick?", liar: "What’s the worst thing about being sick?"),
    QuestionPair(original: "If you could live in a castle or a high-tech penthouse, which?", liar: "If you could live in a cabin or a cottage, which?"),
    QuestionPair(original: "What’s the most interesting thing you’ve learned this week?", liar: "What’s something you learned recently that surprised you?"),
    QuestionPair(original: "If you could be any age for a day, what?", liar: "If you could stay your current age for five extra years, would you?"),
    QuestionPair(original: "What is your favorite type of cloud to look at?", liar: "What is your favorite type of star or planet to look at?"),
    QuestionPair(original: "If you could have any scent as a candle, what?", liar: "If you could have any scent as a perfume/cologne, what?"),
    QuestionPair(original: "What is the best thing you’ve ever built with LEGO or blocks?", liar: "What is the best thing you’ve ever drawn?"),
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
    "Name a yellow fruit.",
    "Name a common pet.",
    "Name a scary animal.",
    "Name a green vegetable.",
    "Name a high school subject.",
    "Name a cold drink.",
    "Name a hot drink.",
    "Name a pizza topping.",
    "Name a superhero.",
    "Name a fast food chain.",
    "Name a cartoon animal.",
    "Name a planet.",
    "Name a type of shoe.",
    "Name a farm animal.",
    "Name a sport played with a ball.",
    "Name a school supply.",
    "Name a breakfast food.",
    "Name a loud instrument.",
    "Name a kitchen appliance.",
    "Name a piece of furniture.",
    "Name a common phobia.",
    "Name a sea creature.",
    "Name a holiday month.",
    "Name a clothing brand.",
    "Name a social media app.",
    "Name a type of candy.",
    "Name a citrus fruit.",
    "Name a shape.",
    "Name a flower name.",
    "Name a weather condition.",
    "Name a mode of transport.",
    "Name a common hobby.",
    "Name a board game.",
    "Name a garden tool.",
    "Name a type of bird.",
    "Name a famous city.",
    "Name a hair color.",
    "Name a sandwich ingredient.",
    "Name a movie genre.",
    "Name a classic toy.",
    "Name a spice.",
    "Name a professional job.",
    "Name a body part.",
    "Name a shiny metal.",
    "Name a breakfast cereal.",
    "Name a tree type.",
    "Name a dog breed.",
    "Name a cat breed.",
    "Name a bathroom item.",
    "Name a dessert.",
    "Name a sport played on grass.",
    "Name a language.",
    "Name a type of pasta.",
    "Name a sour food.",
    "Name a sweet food.",
    "Name a heavy animal.",
    "Name a fast animal.",
    "Name a slow animal.",
    "Name a stinging insect.",
    "Name a nocturnal animal.",
    "Name a place to go on a date.",
    "Name a winter accessory.",
    "Name a summer accessory.",
    "Name a superhero power.",
    "Name a famous singer.",
    "Name a musical genre.",
    "Name a soda brand.",
    "Name a pizza brand.",
    "Name a snack food.",
    "Name a nut type.",
    "Name a berry type.",
    "Name a common first name.",
    "Name a tech brand.",
    "Name a video game.",
    "Name a card game.",
    "Name a household chore.",
    "Name a place to go for a walk.",
    "Name a type of jewelry.",
    "Name a primary color.",
    "Name a baked good.",
    "Name a condiment.",
    "Name a cooking method.",
    "Name a type of cheese.",
    "Name a breakfast beverage.",
    "Name a type of bread.",
    "Name a car part.",
    "Name a tool found in a shed.",
    "Name a wild cat.",
    "Name a reptile.",
    "Name a school sport.",
    "Name a popular website.",
    "Name a movie theater snack.",
    "Name a theme park ride.",
    "Name a laundry item.",
    "Name a camping item.",
    "Name a sport with a net.",
    "Name a flavor of chips.",
    "Name a flavor of ice cream.",
    "Name a soup type.",
    "Name a salad ingredient.",
    "Name a type of dinosaur.",
    "Name a historical figure.",
    "Name a famous landmark.",
    "Name a type of fish.",
    "Name a constellation.",
    "Name a recurring dream.",
    "Name a smell from the kitchen.",
    "Name a sound in the city.",
    "Name a sound in the forest.",
    "Name a type of hat.",
    "Name a piece of luggage.",
    "Name a wedding gift.",
    "Name a birthday gift.",
    "Name a messy food.",
    "Name a crunchy snack.",
    "Name a soft texture.",
    "Name a sharp object.",
    "Name a round object.",
    "Name a square object.",
    "Name a type of currency.",
    "Name a famous bridge.",
    "Name a type of insect.",
    "Name a zoo animal.",
    "Name a circus act.",
    "Name a magic trick.",
    "Name a baby animal name.",
    "Name a place to keep money.",
    "Name a reason to be late.",
    "Name a reason to celebrate.",
    "Name a way to say hello.",
    "Name a way to say goodbye.",
    "Name a type of fabric.",
    "Name a school subject you hate.",
    "Name a school subject you love.",
    "Name a part of a house.",
    "Name a piece of software.",
    "Name a famous scientist.",
    "Name a mythical creature.",
    "Name a type of rock.",
    "Name a famous painting.",
    "Name a classic book.",
    "Name a type of tea.",
    "Name a fruit with a pit.",
    "Name a root vegetable.",
    "Name a jungle animal.",
    "Name a desert animal.",
    "Name a type of cloud.",
    "Name a sport with no ball.",
    "Name a household pest.",
    "Name a feeling you have now."
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
      'gamePhase': 'answering', 
      'players': updatedPlayers,
      'currentQuestionIndex': questionIndex,
      'currentQuestionText': syncQuestions[questionIndex], 
      'questionsUsedSync': questionsUsed,
    });
  }

  // FIX: Added {int totalRounds = 5} as a named parameter


// Add this to FirebaseService class
// lib/services/firebase_service.dart

// lib/services/firebase_service.dart

Future<void> joinCommRoom(String roomCode) async {
  if (userId == null) {
    debugPrint("Firebase: Cannot join comms, userId is null");
    return;
  }
  
  final roomRef = _firestore.collection('rooms').doc(roomCode);
  
  try {
    // We use a transaction or a merge set to add the player
    await roomRef.set({
      'status': 'comms_active',
      'lastUpdate': FieldValue.serverTimestamp(),
      'players': FieldValue.arrayUnion([
        {
          'userId': userId,
          'nickname': nickname ?? "Operative",
          'isTalking': false,
          'joinedAt': DateTime.now().toIso8601String(),
        }
      ])
    }, SetOptions(merge: true));
    debugPrint("Firebase: Successfully checked into room $roomCode");
  } catch (e) {
    debugPrint("Firebase Error joining comm room: $e");
    rethrow;
  }
}
  // 1. Rename the parameter to hostChosenRounds to avoid shadowing/conflicts
Future<void> startGame(String roomCode, String gameId, {int hostChosenRounds = 5}) async {
  if (userId == null) return;

  try {
    DocumentReference roomRef = _firestore.collection('rooms').doc(roomCode);
    
    // 1. GET FRESH DATA
    DocumentSnapshot roomSnap = await roomRef.get();
    if (!roomSnap.exists) return;

    // 🚨 THE STALEMATE PROTECTOR:
    // If status is already 'playing', it means the first call worked.
    // We ABORT here so the second (default 5) call can't ruin the data.
    if (roomSnap.get('status') == 'playing') {
      print("⚠️ BLOCK: Game is already initialized. Ignoring duplicate call to save your rounds.");
      return;
    }

    print("🔥 SERVICE_ENTRY: Valid start request received. Rounds: $hostChosenRounds");

    // 2. Prepare Player Reset
    List<dynamic> playersList = List<dynamic>.from(roomSnap.get('players') ?? []);
    for (var player in playersList) {
      player['score'] = 0;
      player['answerSync'] = "";
      player['isReadyInSyncPhase'] = false;
      player['isReady'] = false;
    }

    // 3. Define the update map
    Map<String, dynamic> updateData = {
      'status': 'playing',
      'currentRound': 1,
      'totalRounds': hostChosenRounds, 
      'players': playersList,
    };

    // Set Phase and Update based on Game ID
    if (gameId == 'sync_game') {
      if (playersList.length < 2) return;
      updateData['gamePhase'] = 'answering';
      await roomRef.update(updateData);
      await _assignQuestionSync(roomCode, roomSnap);
      
    } else if (gameId == 'guess_the_liar') {
      if (playersList.length < 3) return;
      updateData['gamePhase'] = 'answering';
      await roomRef.update(updateData);
      _assignRolesAndQuestionsGTL(roomSnap, gameId, (gtlData) async {
        await roomRef.update(gtlData);
      });

    } else if (gameId == 'dont_get_me_started') {
      updateData['gamePhase'] = 'ranting';
      await roomRef.update(updateData);
      await _assignRantingPlayerDGMS(roomCode, roomSnap);

    } else if (gameId == 'most_likely_to') {
      updateData['gamePhase'] = 'voting';
      await roomRef.update(updateData);
      await _assignQuestionMLT(roomCode, roomSnap);
    }

    print("✅ START_GAME SUCCESS: Mission initialized with $hostChosenRounds rounds.");

  } catch (e) {
    print('❌ START_GAME_ERROR: $e');
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

  Future<void> nextRound(String roomCode, String gameId) async {
    final roomRef = _firestore.collection('rooms').doc(roomCode);
    DocumentSnapshot roomSnap = await roomRef.get();
    if (!roomSnap.exists) return;

    int currentRound = roomSnap.get('currentRound') ?? 1;
    int totalRounds = roomSnap.get('totalRounds') ?? 3;

    if (currentRound >= totalRounds) {
      await roomRef.update({'gamePhase': 'gameOver'});
      return;
    }

    print("DEBUG: Checking currentRound ($currentRound) against totalRounds ($totalRounds)");

    await roomRef.update({'currentRound': currentRound + 1});

    // Assign new question or phase based on gameId
    if (gameId == 'sync_game') {
      await _assignQuestionSync(roomCode, roomSnap);
    } else if (gameId == 'guess_the_liar') {
      _assignRolesAndQuestionsGTL(roomSnap, gameId, (updateData) async {
        await roomRef.update(updateData);
      });
    } else if (gameId == 'dont_get_me_started') {
      await _assignRantingPlayerDGMS(roomCode, roomSnap);
    } else if (gameId == 'most_likely_to') {
      await _assignQuestionMLT(roomCode, roomSnap);
    } else {
      await roomRef.update({'gamePhase': 'started'});
    }
  }

  bool get isLoggedIn => userId != null && nickname != null;
}

final GlobalKey<ScaffoldMessengerState> snackbarKey = GlobalKey<ScaffoldMessengerState>();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final FirebaseService firebaseService = FirebaseService();