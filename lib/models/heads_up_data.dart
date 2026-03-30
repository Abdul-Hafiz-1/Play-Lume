class HeadsUpDeck {
  final String category;
  final String icon;
  final List<String> words;
  HeadsUpDeck({required this.category, required this.icon, required this.words});
}

class HeadsUpData {
  static final List<HeadsUpDeck> decks = [
    HeadsUpDeck(
  category: "ACT IT OUT", 
  icon: "🎭", 
  words: [
    // --- EVERYDAY ACTIONS ---
    "Washing a Cat", "Pizza Maker", "Broken Robot", "Sumo Wrestler", "Rockstar", 
    "Mime", "Chef", "Astronaut", "Lumberjack", "Scuba Diver", "Dentist", "Ninja", 
    "Zombie", "Pirate", "Supermodel", "Toddler", "Parachute Jumper", "Yoga Instructor", 
    "Building a Fire", "Fishing", "Playing Cello", "Surfing", "Operating a Crane", 
    "Taming a Lion", "Mixing a Potion", "Walking on the Moon", "Stuck in Traffic",
    
    // --- SPORTS & HOBBIES ---
    "Basketball Player", "Weightlifter", "Bowler", "Tennis Pro", "Figure Skater", 
    "Archery", "Karate Kid", "Skateboarding", "Playing Drums", "Conducting an Orchestra",
    "Photography", "Gardening", "Painting a Masterpiece", "Knitting a Sweater",
    
    // --- FUNNY / CHALLENGING ---
    "Being a Statue", "Ice Skating for the First Time", "Walking through Mud", 
    "Eating a Sour Lemon", "Seeing a Ghost", "Winning the Lottery", "Walking a Dog",
    "Changing a Flat Tire", "Folding a Fitted Sheet", "Trying to Catch a Fly",
    "Walking on Hot Sand", "Baking a Giant Cake", "Searching for Lost Keys"
    "Magician", "Race Car Driver", "Flight Attendant", "Blacksmith", "Park Ranger", 
    "Mad Scientist", "Knight in Armor", "Matador", "Trapeze Artist", "Clockmaker", 
    "Secret Agent", "Librarian", "Viking", "Construction Worker", "Farmer",
    "Detective", "Ballet Dancer", "Judge", "Soldier", "Flight Pilot", 
    "Opera Singer", "Lifeguard", "Scientist", "News Anchor", "Archaeologist",
    "Bodyguard", "Street Performer", "Butcher", "Tailor", "Janitor",
    "Plumber", "Electrician", "Surveyor", "Groomer", "Tour Guide",
    "Hairdresser", "Artist", "Bank Robber", "Cowboy", "Gladiator",
    "Pantomime", "Postman", "Chef de Cuisine", "Bus Driver", "Astronomy Professor",
    "Fortune Teller", "Referee", "Zookeeper", "Puppeteer", "Toy Maker",

    // --- ACTION & ADVENTURE ---
    "Escaping a Giant Boulder", "Defusing a Bomb", "Climbing an Ice Wall", 
    "Wrestling an Alligator", "Walking a Tightrope", "Finding a Treasure Map", 
    "Avoiding Laser Beams", "Paddling a Canoe", "Flying a Kite", "Riding a Bull",
    "Skydiving", "Deep Sea Diving", "Sword Fighting", "Jungle Trekking", "Space Walk",
    "Escaping a Sinking Ship", "Bungee Jumping", "Spelunking", "Horseback Riding", "Dog Sledding",
    "Chasing a Thief", "Being a Superhero", "Teleporting", "Fighting a Dragon", "Invisibility Cloak",
    "Stealing a Diamond", "Running from a Swarm of Bees", "Surviving a Desert", "Rappelling", "Whitewater Rafting",
    "Searching for El Dorado", "Hunting a Ghost", "Dodging Arrows", "Sailing a Storm", "Crossing a Rickety Bridge",
    "Taming a Griffin", "Exploring a Pyramid", "Escaping a Lab", "Rescuing a Princess", "Fighting an Alien",

    // --- SPORTS & HOBBIES ---
    "Fencing Pro", "Kayaking", "High Jumper", "Golfing", "Baking Bread", 
    "Playing Electric Guitar", "Pottery Throwing", "Birdwatching", "Hula Hooping", 
    "Playing Chess", "Scrapbooking", "Yoga Warrior Pose", "Synchronized Swimming",
    "Badminton Player", "Ping Pong Champ", "Cricket Batter", "American Footballer", "Rugby Tackle",
    "Hockey Goalie", "Lacrosse Player", "Curling", "Darts Player", "Pool Shark",
    "Snorkeling", "Mountain Biking", "Rock Climbing", "Zumba Dancing", "Breakdancing",
    "Playing Saxophone", "Playing Violin", "Playing Trumpet", "Playing Bagpipes", "DJ Spinning",
    "Origami Folding", "Calligraphy", "Flower Arranging", "Stamp Collecting", "Model Plane Building",
    "Woodworking", "Jewelry Making", "Cooking a Soufflé", "Wine Tasting", "Taxidermy",

    // --- FUNNY / CHALLENGING SITUATIONS ---
    "Putting on Skinny Jeans", "Walking Against Strong Wind", "Assembling IKEA Furniture", 
    "Getting a Haircut", "Washing a Grumpy Dog", "Being a Jack-in-the-Box", 
    "Trying to Be Silent with a Squeaky Floor", "Walking in Deep Snow", 
    "Losing a Sneeze", "Being a Cuckoo Clock", "Getting a Popcorn Kernel Stuck",
    "Stepping on a Lego", "Walking Through a Spiderweb", "Eating Spicy Chili", "Brain Freeze",
    "Waking Up a Sleeping Baby", "Applying Makeup in a Moving Car", "Getting a Bad Sunburn", "Stuck in a Chimney",
    "Trying to Lick Your Elbow", "Pantomiming a Glass Box", "Running Underwater", "Melting Snowman",
    "Being a Wind-up Toy", "Getting a Static Shock", "Opening a Stuck Jar", "Parallel Parking",
    "Trying to Whistle", "Sneezing While Hiding", "Losing a Contact Lens", "Being a Toaster",
    "Walking with One Shoe", "Ironing a Shirt", "Threading a Needle", "Typing on a Broken Keyboard",

    // --- NATURE & ANIMALS ---
    "Kangaroo", "Flamingo", "Crab Walking", "Peacock", "Gorilla", 
    "Elephant", "Snake Charmer", "Bee in a Flower", "Butterfly Emerging",
    "Chameleon Camouflaging", "Ostrich Burying Head", "Penguin Slide", "Giraffe Eating Leaves", "Lion Roaring",
    "Cat Chasing Laser", "Dog Chasing Tail", "Squirrel Stashing Nuts", "Monkey Swinging", "Frog Catching Fly",
    "Shark Hunting", "Owl Rotating Head", "Bear Hibernating", "Woodpecker Pecking", "Spider Spinning Web",
    "Rooster Crowing", "Cow Being Milked", "Horse Galloping", "Jellyfish Drifting", "Octopus Squirt Ink",
    "Lobster Snapping", "Sloth Moving", "Bat Hanging", "Eagle Soaring", "Turtle Hiding",
    "Seahorse Swimming", "Camel in a Sandstorm", "Hedgehog Rolling", "Skunk Spraying", "Walrus Tusk Fight"
    // Tip: You can easily expand this list to 500 by adding more household chores or sports!
  ]
),
    HeadsUpDeck(
      category: "HOUSEHOLD", 
      icon: "🏠", 
      words: [
        "Toaster", "Slippers", "Washing Machine", "Vacuum Cleaner", "Remote Control", "Toothbrush", 
        "Refrigerator", "Microwave", "Curtains", "Doorbell", "Dustpan", "Ironing Board", "Kettle",
        "Coffee Mug", "Ceiling Fan", "Bookshelf", "Alarm Clock", "Soap Dispenser", "Hair Dryer",
        "Garden Hose", "Mailbox", "Chopping Board", "Pizza Cutter", "Laundry Basket", "Flashlight",
        "Batteries", "Lightbulb", "Measuring Tape", "Screwdriver", "Hammer", "Paint Brush",
        "Step Ladder", "Extension Cord", "Colander", "Whisk", "Spatula", "Oven Mitt", "Dish Soap",
        "Sponge", "Paper Towels", "Broom", "Mop", "Bucket", "Trash Can", "Keyring", "Wallet"
        // ... Continue adding to 500
      ]
    ),
    HeadsUpDeck(
      category: "FOODIE", 
      icon: "🍕", 
      words: [
        "Hamburger", "French Fries", "Sushi", "Taco", "Burrito", "Spaghetti", "Meatballs",
        "Hot Dog", "Popcorn", "Cotton Candy", "Ice Cream Cone", "Pancakes", "Waffles",
        "Blueberry Muffins", "Chocolate Cake", "Apple Pie", "Donut", "Croissant", "Bagel",
        "Fried Chicken", "Omelet", "Lasagna", "Dim Sum", "Ramen", "Pad Thai", "Guacamole",
        "Nachos", "Pretzel", "Cheese Fondue", "Smoothie", "Milkshake", "Lemonade", "Green Tea",
        "Marshmallow", "Gummy Bears", "Licorice", "Watermelon", "Pineapple", "Mango", "Avocado",
        "Broccoli", "Corn on the Cob", "Baked Potato", "Eggplant", "Pumpkin", "Asparagus"
        // ... Continue adding to 500
      ]
    ),
    HeadsUpDeck(
      category: "ANIMALS", 
      icon: "🦁", 
      words: [
        "Lion", "Tiger", "Elephant", "Giraffe", "Zebra", "Kangaroo", "Panda", "Koala", "Penguin",
        "Polar Bear", "Great White Shark", "Dolphin", "Blue Whale", "Octopus", "Seahorse",
        "Chameleon", "Komodo Dragon", "Golden Retriever", "Persian Cat", "Hamster", "Guinea Pig",
        "Rabbit", "Horse", "Cow", "Pig", "Chicken", "Goat", "Sheep", "Donkey", "Duck", "Goose",
        "Bald Eagle", "Owl", "Parrot", "Flamingo", "Peacock", "Hummingbird", "Butterfly", 
        "Honey Bee", "Ladybug", "Scorpion", "Spider", "Grasshopper", "Caterpillar", "Ant","Cheetah", "Leopard", "Jaguar", "Snow Leopard", "Panther", "Cougar", "Lynx", "Bobcat", "Serval", "Ocelot",
    "Silverback Gorilla", "Chimpanzee", "Orangutan", "Bonobo", "Lemur", "Baboon", "Mandrill", "Gibbon", "Marmoset", "Tamarin",
    "Red Panda", "Raccoon", "Skunk", "Badger", "Wolverine", "Otter", "Sea Otter", "Honey Badger", "Stoat", "Weasel",
    "Platypus", "Echidna", "Wombat", "Tasmanian Devil", "Wallaby", "Quokka", "Tree Kangaroo", "Sugar Glider", "Opossum", "Bandicoot",
    "Hippopotamus", "Rhinoceros", "Warthog", "Wild Boar", "Tapir", "Anteater", "Sloth", "Armadillo", "Pangolin", "Meerkat",
    "Mongoose", "Hyena", "Aardvark", "Fennec Fox", "Arctic Fox", "Red Fox", "Gray Wolf", "Coyote", "Jackal", "Dingo",
    "Grizzly Bear", "Black Bear", "Sun Bear", "Spectacled Bear", "Moose", "Elk", "Reindeer", "Caribou", "Gazelle", "Impala",
    "Wildebeest", "Bison", "Water Buffalo", "Yak", "Llama", "Alpaca", "Vicuña", "Guanaco", "Camel", "Dromedary",
    "Hedgehog", "Mole", "Shrew", "Bat", "Fruit Bat", "Vampire Bat", "Flying Fox", "Walrus", "Elephant Seal", "Sea Lion",
    "Harbor Seal", "Manatee", "Dugong", "Narwhal", "Beluga Whale", "Orca", "Humpback Whale", "Sperm Whale", "Minke Whale", "Porpoise",

    // --- BIRDS ---
    "Ostrich", "Emu", "Cassowary", "Rhea", "Kiwi", "Toucan", "Macaw", "Cockatoo", "African Gray Parrot", "Lovebird",
    "Falcon", "Hawk", "Vulture", "Condor", "Osprey", "Kestrel", "Barn Owl", "Snowy Owl", "Great Horned Owl", "Puffin",
    "Albatross", "Pelican", "Cormorant", "Heron", "Egret", "Stork", "Ibis", "Spoonbill", "Crane", "Woodpecker",
    "Kingfisher", "Blue Jay", "Cardinal", "Robin", "Sparrow", "Starling", "Crow", "Raven", "Magpie", "Nightingale",
    "Swan", "Black Swan", "Mallard", "Teal", "Wood Duck", "Mandarin Duck", "Turkey", "Pheasant", "Quail", "Partridge",
    "Roadrunner", "Cuckoo", "Swift", "Swallow", "Wren", "Thrush", "Mockingbird", "Finch", "Goldfinch", "Canary",

    // --- REPTILES & AMPHIBIANS ---
    "Alligator", "Caiman", "Gharial", "Leatherback Turtle", "Green Sea Turtle", "Box Turtle", "Tortoise", "Galapagos Tortoise", "Snapping Turtle", "Terrapin",
    "King Cobra", "Black Mamba", "Rattlesnake", "Python", "Boa Constrictor", "Anaconda", "Coral Snake", "Viper", "Garter Snake", "Sea Snake",
    "Iguana", "Gecko", "Monitor Lizard", "Gila Monster", "Frilled Lizard", "Anole", "Skink", "Bearded Dragon", "Newt", "Salamander",
    "Axolotl", "Bullfrog", "Tree Frog", "Poison Dart Frog", "Toad", "Cane Toad", "Fire-bellied Toad", "Caecilian", "Mudpuppy", "Hellbender",

    // --- FISH & MARINE INVERTEBRATES ---
    "Hammerhead Shark", "Tiger Shark", "Whale Shark", "Bull Shark", "Manta Ray", "Stingray", "Electric Eel", "Moray Eel", "Barracuda", "Piranha",
    "Swordfish", "Marlin", "Tuna", "Salmon", "Trout", "Cod", "Catfish", "Goldfish", "Koi", "Betta Fish",
    "Angelfish", "Clownfish", "Boxfish", "Pufferfish", "Lionfish", "Anglerfish", "Blobfish", "Stonefish", "Leafy Seadragon", "Pipefish",
    "Giant Squid", "Colossal Squid", "Cuttlefish", "Nautilus", "Starfish", "Brittle Star", "Sea Urchin", "Sand Dollar", "Sea Cucumber", "Anemone",
    "Coral", "Jellyfish", "Box Jellyfish", "Man o' War", "Portuguese Man o' War", "Sponge", "Barnacle", "Clam", "Oyster", "Mussel",
    "Scallop", "Abalone", "Slug", "Sea Slug", "Nudibranch", "Conch", "Hermit Crab", "King Crab", "Blue Crab", "Fiddler Crab",

    // --- INSECTS & ARACHNIDS ---
    "Dragonfly", "Damselfly", "Praying Mantis", "Walking Stick", "Katydid", "Cricket", "Cicada", "Aphid", "Termite", "Earwig",
    "Firefly", "Stag Beetle", "Scarab Beetle", "Dung Beetle", "Hercules Beetle", "Ladybird", "Weevil", "Click Beetle", "Fire Ant", "Army Ant",
    "Leafcutter Ant", "Carpenter Ant", "Wasper", "Hornet", "Yellowjacket", "Bumblebee", "Carpenter Bee", "Moth", "Luna Moth", "Atlas Moth",
    "Monarch Butterfly", "Swallowtail Butterfly", "Flea", "Tick", "Louse", "Bedbug", "Mosquito", "Fruit Fly", "Horse Fly", "Tsetse Fly",
    "Tarantula", "Black Widow", "Brown Recluse", "Wolf Spider", "Jumping Spider", "Trapdoor Spider", "Harvestman", "Water Strider", "Centipede", "Millipede",

    // --- EXOTIC, ARCHAIC & MISC ---
    "Okapi", "Saiga Antelope", "Addax", "Oryx", "Kudu", "Nilgai", "Bongo", "Markhor", "Ibex", "Chamois",
    "Barbary Sheep", "Mouflon", "Wild Ass", "Quagga", "Zebroid", "Liger", "Tigon", "Civet", "Genet", "Fossa",
    "Coati", "Kinkajou", "Binturong", "Tayra", "Grison", "Polecat", "Fisher", "Ermine", "Mink", "Sable",
    "Vole", "Lemming", "Gerbil", "Dormouse", "Jerboa", "Capybara", "Nutria", "Agouti", "Paca", "Chinchilla",
    "Rock Hyrax", "Elephant Shrew", "Tenrec", "Solenodon", "Desman", "Star-nosed Mole", "Flying Squirrel", "Groundhog", "Prairie Dog", "Chipmunk",
    "Gopher", "Beaver", "Porcupine", "Cavy", "Mara", "Viscacha", "Tuco-tuco", "Gundi", "Degus", "Springhare",
    "Sifaka", "Indri", "Aye-aye", "Bushbaby", "Potto", "Loris", "Tarsier", "Capuchin", "Spider Monkey", "Howler Monkey",
    "Squirrel Monkey", "Saki", "Uakari", "Titi Monkey", "Drill", "Gelada", "Colobus", "Langur", "Proboscis Monkey", "Macaque",
    "Wandering Albatross", "Frigatebird", "Booby", "Gannet", "Skua", "Tern", "Guillemot", "Razorbill", "Auk", "Murre",
    "Sandpiper", "Plover", "Snipe", "Curlew", "Godwit", "Avocet", "Stilt", "Jacana", "Hoatzin", "Turaco",
    "Cuckoo-roller", "Trogon", "Quetzal", "Motmot", "Bee-eater", "Roller", "Hoopoe", "Hornbill", "Barbet", "Honeyguide",
    "Pitta", "Lyrebird", "Scrub-bird", "Bowerbird", "Fairywren", "Honeyeater", "Flowerpecker", "Sunbird", "White-eye", "Oriole",
    "Drongo", "Fantail", "Shrike", "Vireo", "Tanager", "Grosbeak", "Bunting", "Meadowlark", "Grackle", "Cowbird",
    "Gharial", "False Gharial", "Tomistoma", "Snapping Turtle", "Softshell Turtle", "Sideneck Turtle", "Matamata", "Tuatara", "Slow Worm", "Glass Lizard",
    "Whiptail", "Tegu", "Wall Lizard", "Rock Lizard", "Lace Monitor", "Perentie", "Water Monitor", "Tree Monitor", "Blind Snake", "Sunbeam Snake",
    "Pipe Snake", "Shieldtail Snake", "Filesnake", "Slug-eater", "Wolf Snake", "Vine Snake", "Cat Snake", "Tree Snake", "Flying Snake", "Water Snake",
    "Crayfish", "Prawn", "Shrimp", "Krill", "Mantid Shrimp", "Ostracod", "Copepod", "Water Flea", "Triops", "Fairy Shrimp",
    "Tadpole Shrimp", "Clam Shrimp", "Seed Shrimp", "Isopod", "Woodlouse", "Amphipod", "Sand Hopper", "Sea Spider", "Horseshoe Crab", "Tarantula Hawk",
    "Velvet Ant", "Mud Dauber", "Potter Wasp", "Gall Wasp", "Ichneumon Wasp", "Chalcid Wasp", "Sawfly", "Stonefly", "Mayfly", "Dobsonfly",
    "Alderfly", "Snakefly", "Lacewing", "Antlion", "Owlfly", "Scorpionfly", "Caddisfly", "Skipper", "Birdwing Butterfly", "Morpho Butterfly",
    "Owl Butterfly", "Glasswing Butterfly", "Clothes Moth", "Hawkmoth", "Sphinx Moth", "Silk Moth", "Emperor Moth", "Tiger Moth", "Underwing Moth", "Geometer Moth",
    "Crane Fly", "Gnat", "Midges", "Sand Fly", "Blow Fly", "Bot Fly", "Hover Fly", "Robber Fly", "Bee Fly", "Deer Fly",
    "Bed Bug", "Assassin Bug", "Water Boatman", "Backswimmer", "Giant Water Bug", "Stink Bug", "Shield Bug", "Leafhopper", "Treehopper", "Froghopper",
    "Planthopper", "Scale Insect", "Mealybug", "Whitefly", "Psyllid", "Thrips", "Silverfish", "Firebrat", "Springtail", "Bristletail",
    "Dipluran", "Proturan", "Garden Centipede", "Symphylan", "Pauropod", "Pill Bug", "Sowbug", "Water Slater", "Sea Louse", "Whale Louse",
    "Land Snail", "Garden Snail", "Giant African Snail", "Apple Snail", "Ramshorn Snail", "Limpet", "Whelk", "Periwinkle", "Cowrie", "Cone Snail",
    "Sea Hare", "Sea Butterfly", "Nautilus", "Paper Nautilus", "Squid", "Sepia", "Bobtail Squid", "Vampire Squid", "Dumbo Octopus", "Blue-ringed Octopus",
    "Giant Pacific Octopus", "Mimic Octopus", "Seven-arm Octopus", "Argonaut", "Lamp Shell", "Moss Animal", "Entoproct", "Horseshoe Worm", "Ribbon Worm", "Peanut Worm",
    "Spoon Worm", "Arrow Worm", "Velvet Worm", "Water Bear", "Tardigrade", "Beard Worm", "Acorn Worm", "Lancelet", "Sea Squirt", "Salp"
        // ... Continue adding to 500
      ]
    ),
    HeadsUpDeck(
      category: "ICONS", 
      icon: "✨", 
      words: [
        "🍎", "🚗", "🐶", "🍕", "🚀", "🍦", "⚽", "🏠", "🎁", "🦋", "🦁", "🚲", "🎸", "🍩", "🛸", 
        "🦖", "🦄", "🌈", "🍭", "🧸", "🍌", "🐘", "☀️", "🌙", "🎨", "🧩", "🍪", "🐝", "🦉", "🦒",
        "🚁", "🚢", "🚜", "⏰", "🥪", "🍓", "🏀", "🎺", "💡", "🔑", "💎", "🌋", "🏖️", "⛄", "🔥"
        // --- OCCUPATIONS & CHARACTERS ---
    "🪄", "🏎️", "✈️", "⚒️", "🥾", "🧪", "🛡️", "🐂", "🎪", "🕰️", 
    "🕵️‍♂️", "📚", "🪓", "🏗️", "👨‍🌾", "🔍", "🩰", "👨‍⚖️", "🪖", "👩‍✈️", 
    "🎼", "🛟", "🔬", "🎤", "🏺", "🕶️", "🎸", "🔪", "🪡", "🧹",
    "🔧", "⚡", "📏", "✂️", "🚩", "💈", "🎨", "💰", "🤠", "⚔️",
    "🤡", "📬", "👨‍🍳", "🚌", "🔭", "🔮", "🏁", "🦁", "🎭", "🧸",

    // --- ACTION & ADVENTURE ---
    "🪨", "💣", "🧊", "🐊", "🧗", "🗺️", "🚨", "🛶", "🪁", "🐂",
    "🪂", "🤿", "🤺", "🌳", "👨‍🚀", "🚢", "🏗️", "🔦", "🐎", "🛷",
    "🏃‍♂️", "🦸‍♂️", "✨", "🐉", "👻", "💎", "🐝", "🏜️", "🧗‍♀️", "🌊",
    "🔱", "🔦", "🏹", "⛵", "🌉", "🦅", "📐", "🧪", "👸", "👽",

    // --- SPORTS & HOBBIES ---
    "🤺", "🚣", "🏃‍♂️", "⛳", "🍞", "🎸", "🏺", "🔭", "⭕", "♟️", 
    "✂️", "🧘", "🏊‍♀️", "🏸", "🏓", "🏏", "🏈", "🏉", "🏒", "🥍", 
    "🥌", "🎯", "🎱", "🤿", "🚲", "🧗", "💃", "🤸‍♂️", "🎷", "🎻", 
    "🎺", "🪗", "🎧", "📄", "🖋️", "🌸", "📮", "✈️", "🪵", "💍",
    "🍮", "🍷", "🦌", "🏀", "🏋️‍♂️", "🎳", "🎾", "⛸️", "🏹", "🥋",

    // --- FUNNY / CHALLENGING ---
    "👖", "🌬️", "🔧", "💇", "🐕", "📦", "🤫", "❄️", "🤧", "🐦", 
    "🍿", "🧱", "🕸️", "🌶️", "🥶", "👶", "💄", "☀️", "🏠", "💪", 
    "📦", "🏃‍♂️", "⛄", "🧸", "⚡", "🍯", "🅿️", "😙", "🙈", "👁️", 
    "🍞", "👟", "💨", "🧵", "⌨️", "🥘", "🧴", "🧳", "📷", "🧤",

    // --- NATURE & ANIMALS ---
    "🦘", "🦩", "🦀", "🦚", "🦍", "🐘", "🐍", "🐝", "🦋", "🦎", 
    "🦩", "🐧", "🦒", "🦁", "🐈", "🐕", "🐿️", "🐒", "🐸", "🦈", 
    "🦉", "🐻", "🪵", "🕸️", "🐓", "🐄", "🐎", "🪼", "🐙", "🦞", 
    "🦥", "🦇", "🦅", "🐢", "🐴", "🐪", "🦔", "🦨", "🦭", "🦆"
        // ... Continue adding to 500 emojis
      ]
    ),
    HeadsUpDeck(
      category: "RANDOM", 
      icon: "🎲", 
      words: [
        "Toaster", "Slippers", "Washing Machine", "Vacuum Cleaner", "Remote Control", "Toothbrush", 
        "Refrigerator", "Microwave", "Curtains", "Doorbell", "Dustpan", "Ironing Board", "Kettle",
        "Coffee Mug", "Ceiling Fan", "Bookshelf", "Alarm Clock", "Soap Dispenser", "Hair Dryer",
        "Garden Hose", "Mailbox", "Chopping Board", "Pizza Cutter", "Laundry Basket", "Flashlight",
        "Batteries", "Lightbulb", "Measuring Tape", "Screwdriver", "Hammer", "Paint Brush",
        "Step Ladder", "Extension Cord", "Colander", "Whisk", "Spatula", "Oven Mitt", "Dish Soap",
        "Sponge", "Paper Towels", "Broom", "Mop", "Bucket", "Trash Can", "Keyring", "Wallet",
        "Hamburger", "French Fries", "Sushi", "Taco", "Burrito", "Spaghetti", "Meatballs",
        "Hot Dog", "Popcorn", "Cotton Candy", "Ice Cream Cone", "Pancakes", "Waffles",
        "Blueberry Muffins", "Chocolate Cake", "Apple Pie", "Donut", "Croissant", "Bagel",
        "Fried Chicken", "Omelet", "Lasagna", "Dim Sum", "Ramen", "Pad Thai", "Guacamole",
        "Nachos", "Pretzel", "Cheese Fondue", "Smoothie", "Milkshake", "Lemonade", "Green Tea",
        "Marshmallow", "Gummy Bears", "Licorice", "Watermelon", "Pineapple", "Mango", "Avocado",
        "Broccoli", "Corn on the Cob", "Baked Potato", "Eggplant", "Pumpkin", "Asparagus",
        "Lion", "Tiger", "Elephant", "Giraffe", "Zebra", "Kangaroo", "Panda", "Koala", "Penguin",
        "Polar Bear", "Great White Shark", "Dolphin", "Blue Whale", "Octopus", "Seahorse",
        "Chameleon", "Komodo Dragon", "Golden Retriever", "Persian Cat", "Hamster", "Guinea Pig",
        "Rabbit", "Horse", "Cow", "Pig", "Chicken", "Goat", "Sheep", "Donkey", "Duck", "Goose",
        "Bald Eagle", "Owl", "Parrot", "Flamingo", "Peacock", "Hummingbird", "Butterfly", 
        "Honey Bee", "Ladybug", "Scorpion", "Spider", "Grasshopper", "Caterpillar", "Ant",
        "🍎", "🚗", "🐶", "🍕", "🚀", "🍦", "⚽", "🏠", "🎁", "🦋", "🦁", "🚲", "🎸", "🍩", "🛸", 
        "🦖", "🦄", "🌈", "🍭", "🧸", "🍌", "🐘", "☀️", "🌙", "🎨", "🧩", "🍪", "🐝", "🦉", "🦒",
        "🚁", "🚢", "🚜", "⏰", "🥪", "🍓", "🏀", "🎺", "💡", "🔑", "💎", "🌋", "🏖️", "⛄", "🔥","Magician", "Race Car Driver", "Flight Attendant", "Blacksmith", "Park Ranger", 
    "Mad Scientist", "Knight in Armor", "Matador", "Trapeze Artist", "Clockmaker", 
    "Secret Agent", "Librarian", "Viking", "Construction Worker", "Farmer",
    "Detective", "Ballet Dancer", "Judge", "Soldier", "Flight Pilot", 
    "Opera Singer", "Lifeguard", "Scientist", "News Anchor", "Archaeologist",
    "Bodyguard", "Street Performer", "Butcher", "Tailor", "Janitor",
    "Plumber", "Electrician", "Surveyor", "Groomer", "Tour Guide",
    "Hairdresser", "Artist", "Bank Robber", "Cowboy", "Gladiator",
    "Pantomime", "Postman", "Chef de Cuisine", "Bus Driver", "Astronomy Professor",
    "Fortune Teller", "Referee", "Zookeeper", "Puppeteer", "Toy Maker",

    // --- ACTION & ADVENTURE ---
    "Escaping a Giant Boulder", "Defusing a Bomb", "Climbing an Ice Wall", 
    "Wrestling an Alligator", "Walking a Tightrope", "Finding a Treasure Map", 
    "Avoiding Laser Beams", "Paddling a Canoe", "Flying a Kite", "Riding a Bull",
    "Skydiving", "Deep Sea Diving", "Sword Fighting", "Jungle Trekking", "Space Walk",
    "Escaping a Sinking Ship", "Bungee Jumping", "Spelunking", "Horseback Riding", "Dog Sledding",
    "Chasing a Thief", "Being a Superhero", "Teleporting", "Fighting a Dragon", "Invisibility Cloak",
    "Stealing a Diamond", "Running from a Swarm of Bees", "Surviving a Desert", "Rappelling", "Whitewater Rafting",
    "Searching for El Dorado", "Hunting a Ghost", "Dodging Arrows", "Sailing a Storm", "Crossing a Rickety Bridge",
    "Taming a Griffin", "Exploring a Pyramid", "Escaping a Lab", "Rescuing a Princess", "Fighting an Alien",

    // --- SPORTS & HOBBIES ---
    "Fencing Pro", "Kayaking", "High Jumper", "Golfing", "Baking Bread", 
    "Playing Electric Guitar", "Pottery Throwing", "Birdwatching", "Hula Hooping", 
    "Playing Chess", "Scrapbooking", "Yoga Warrior Pose", "Synchronized Swimming",
    "Badminton Player", "Ping Pong Champ", "Cricket Batter", "American Footballer", "Rugby Tackle",
    "Hockey Goalie", "Lacrosse Player", "Curling", "Darts Player", "Pool Shark",
    "Snorkeling", "Mountain Biking", "Rock Climbing", "Zumba Dancing", "Breakdancing",
    "Playing Saxophone", "Playing Violin", "Playing Trumpet", "Playing Bagpipes", "DJ Spinning",
    "Origami Folding", "Calligraphy", "Flower Arranging", "Stamp Collecting", "Model Plane Building",
    "Woodworking", "Jewelry Making", "Cooking a Soufflé", "Wine Tasting", "Taxidermy",

    // --- FUNNY / CHALLENGING SITUATIONS ---
    "Putting on Skinny Jeans", "Walking Against Strong Wind", "Assembling IKEA Furniture", 
    "Getting a Haircut", "Washing a Grumpy Dog", "Being a Jack-in-the-Box", 
    "Trying to Be Silent with a Squeaky Floor", "Walking in Deep Snow", 
    "Losing a Sneeze", "Being a Cuckoo Clock", "Getting a Popcorn Kernel Stuck",
    "Stepping on a Lego", "Walking Through a Spiderweb", "Eating Spicy Chili", "Brain Freeze",
    "Waking Up a Sleeping Baby", "Applying Makeup in a Moving Car", "Getting a Bad Sunburn", "Stuck in a Chimney",
    "Trying to Lick Your Elbow", "Pantomiming a Glass Box", "Running Underwater", "Melting Snowman",
    "Being a Wind-up Toy", "Getting a Static Shock", "Opening a Stuck Jar", "Parallel Parking",
    "Trying to Whistle", "Sneezing While Hiding", "Losing a Contact Lens", "Being a Toaster",
    "Walking with One Shoe", "Ironing a Shirt", "Threading a Needle", "Typing on a Broken Keyboard",

    // --- NATURE & ANIMALS ---
    "Kangaroo", "Flamingo", "Crab Walking", "Peacock", "Gorilla", 
    "Elephant", "Snake Charmer", "Bee in a Flower", "Butterfly Emerging",
    "Chameleon Camouflaging", "Ostrich Burying Head", "Penguin Slide", "Giraffe Eating Leaves", "Lion Roaring",
    "Cat Chasing Laser", "Dog Chasing Tail", "Squirrel Stashing Nuts", "Monkey Swinging", "Frog Catching Fly",
    "Shark Hunting", "Owl Rotating Head", "Bear Hibernating", "Woodpecker Pecking", "Spider Spinning Web",
    "Rooster Crowing", "Cow Being Milked", "Horse Galloping", "Jellyfish Drifting", "Octopus Squirt Ink",
    "Lobster Snapping", "Sloth Moving", "Bat Hanging", "Eagle Soaring", "Turtle Hiding",
    "Seahorse Swimming", "Camel in a Sandstorm", "Hedgehog Rolling", "Skunk Spraying", "Walrus Tusk Fight", "Cheetah", "Leopard", "Jaguar", "Snow Leopard", "Panther", "Cougar", "Lynx", "Bobcat", "Serval", "Ocelot",
    "Silverback Gorilla", "Chimpanzee", "Orangutan", "Bonobo", "Lemur", "Baboon", "Mandrill", "Gibbon", "Marmoset", "Tamarin",
    "Red Panda", "Raccoon", "Skunk", "Badger", "Wolverine", "Otter", "Sea Otter", "Honey Badger", "Stoat", "Weasel",
    "Platypus", "Echidna", "Wombat", "Tasmanian Devil", "Wallaby", "Quokka", "Tree Kangaroo", "Sugar Glider", "Opossum", "Bandicoot",
    "Hippopotamus", "Rhinoceros", "Warthog", "Wild Boar", "Tapir", "Anteater", "Sloth", "Armadillo", "Pangolin", "Meerkat",
    "Mongoose", "Hyena", "Aardvark", "Fennec Fox", "Arctic Fox", "Red Fox", "Gray Wolf", "Coyote", "Jackal", "Dingo",
    "Grizzly Bear", "Black Bear", "Sun Bear", "Spectacled Bear", "Moose", "Elk", "Reindeer", "Caribou", "Gazelle", "Impala",
    "Wildebeest", "Bison", "Water Buffalo", "Yak", "Llama", "Alpaca", "Vicuña", "Guanaco", "Camel", "Dromedary",
    "Hedgehog", "Mole", "Shrew", "Bat", "Fruit Bat", "Vampire Bat", "Flying Fox", "Walrus", "Elephant Seal", "Sea Lion",
    "Harbor Seal", "Manatee", "Dugong", "Narwhal", "Beluga Whale", "Orca", "Humpback Whale", "Sperm Whale", "Minke Whale", "Porpoise",

    // --- BIRDS ---
    "Ostrich", "Emu", "Cassowary", "Rhea", "Kiwi", "Toucan", "Macaw", "Cockatoo", "African Gray Parrot", "Lovebird",
    "Falcon", "Hawk", "Vulture", "Condor", "Osprey", "Kestrel", "Barn Owl", "Snowy Owl", "Great Horned Owl", "Puffin",
    "Albatross", "Pelican", "Cormorant", "Heron", "Egret", "Stork", "Ibis", "Spoonbill", "Crane", "Woodpecker",
    "Kingfisher", "Blue Jay", "Cardinal", "Robin", "Sparrow", "Starling", "Crow", "Raven", "Magpie", "Nightingale",
    "Swan", "Black Swan", "Mallard", "Teal", "Wood Duck", "Mandarin Duck", "Turkey", "Pheasant", "Quail", "Partridge",
    "Roadrunner", "Cuckoo", "Swift", "Swallow", "Wren", "Thrush", "Mockingbird", "Finch", "Goldfinch", "Canary",

    // --- REPTILES & AMPHIBIANS ---
    "Alligator", "Caiman", "Gharial", "Leatherback Turtle", "Green Sea Turtle", "Box Turtle", "Tortoise", "Galapagos Tortoise", "Snapping Turtle", "Terrapin",
    "King Cobra", "Black Mamba", "Rattlesnake", "Python", "Boa Constrictor", "Anaconda", "Coral Snake", "Viper", "Garter Snake", "Sea Snake",
    "Iguana", "Gecko", "Monitor Lizard", "Gila Monster", "Frilled Lizard", "Anole", "Skink", "Bearded Dragon", "Newt", "Salamander",
    "Axolotl", "Bullfrog", "Tree Frog", "Poison Dart Frog", "Toad", "Cane Toad", "Fire-bellied Toad", "Caecilian", "Mudpuppy", "Hellbender",

    // --- FISH & MARINE INVERTEBRATES ---
    "Hammerhead Shark", "Tiger Shark", "Whale Shark", "Bull Shark", "Manta Ray", "Stingray", "Electric Eel", "Moray Eel", "Barracuda", "Piranha",
    "Swordfish", "Marlin", "Tuna", "Salmon", "Trout", "Cod", "Catfish", "Goldfish", "Koi", "Betta Fish",
    "Angelfish", "Clownfish", "Boxfish", "Pufferfish", "Lionfish", "Anglerfish", "Blobfish", "Stonefish", "Leafy Seadragon", "Pipefish",
    "Giant Squid", "Colossal Squid", "Cuttlefish", "Nautilus", "Starfish", "Brittle Star", "Sea Urchin", "Sand Dollar", "Sea Cucumber", "Anemone",
    "Coral", "Jellyfish", "Box Jellyfish", "Man o' War", "Portuguese Man o' War", "Sponge", "Barnacle", "Clam", "Oyster", "Mussel",
    "Scallop", "Abalone", "Slug", "Sea Slug", "Nudibranch", "Conch", "Hermit Crab", "King Crab", "Blue Crab", "Fiddler Crab",

    // --- INSECTS & ARACHNIDS ---
    "Dragonfly", "Damselfly", "Praying Mantis", "Walking Stick", "Katydid", "Cricket", "Cicada", "Aphid", "Termite", "Earwig",
    "Firefly", "Stag Beetle", "Scarab Beetle", "Dung Beetle", "Hercules Beetle", "Ladybird", "Weevil", "Click Beetle", "Fire Ant", "Army Ant",
    "Leafcutter Ant", "Carpenter Ant", "Wasper", "Hornet", "Yellowjacket", "Bumblebee", "Carpenter Bee", "Moth", "Luna Moth", "Atlas Moth",
    "Monarch Butterfly", "Swallowtail Butterfly", "Flea", "Tick", "Louse", "Bedbug", "Mosquito", "Fruit Fly", "Horse Fly", "Tsetse Fly",
    "Tarantula", "Black Widow", "Brown Recluse", "Wolf Spider", "Jumping Spider", "Trapdoor Spider", "Harvestman", "Water Strider", "Centipede", "Millipede",

    // --- EXOTIC, ARCHAIC & MISC ---
    "Okapi", "Saiga Antelope", "Addax", "Oryx", "Kudu", "Nilgai", "Bongo", "Markhor", "Ibex", "Chamois",
    "Barbary Sheep", "Mouflon", "Wild Ass", "Quagga", "Zebroid", "Liger", "Tigon", "Civet", "Genet", "Fossa",
    "Coati", "Kinkajou", "Binturong", "Tayra", "Grison", "Polecat", "Fisher", "Ermine", "Mink", "Sable",
    "Vole", "Lemming", "Gerbil", "Dormouse", "Jerboa", "Capybara", "Nutria", "Agouti", "Paca", "Chinchilla",
    "Rock Hyrax", "Elephant Shrew", "Tenrec", "Solenodon", "Desman", "Star-nosed Mole", "Flying Squirrel", "Groundhog", "Prairie Dog", "Chipmunk",
    "Gopher", "Beaver", "Porcupine", "Cavy", "Mara", "Viscacha", "Tuco-tuco", "Gundi", "Degus", "Springhare",
    "Sifaka", "Indri", "Aye-aye", "Bushbaby", "Potto", "Loris", "Tarsier", "Capuchin", "Spider Monkey", "Howler Monkey",
    "Squirrel Monkey", "Saki", "Uakari", "Titi Monkey", "Drill", "Gelada", "Colobus", "Langur", "Proboscis Monkey", "Macaque",
    "Wandering Albatross", "Frigatebird", "Booby", "Gannet", "Skua", "Tern", "Guillemot", "Razorbill", "Auk", "Murre",
    "Sandpiper", "Plover", "Snipe", "Curlew", "Godwit", "Avocet", "Stilt", "Jacana", "Hoatzin", "Turaco",
    "Cuckoo-roller", "Trogon", "Quetzal", "Motmot", "Bee-eater", "Roller", "Hoopoe", "Hornbill", "Barbet", "Honeyguide",
    "Pitta", "Lyrebird", "Scrub-bird", "Bowerbird", "Fairywren", "Honeyeater", "Flowerpecker", "Sunbird", "White-eye", "Oriole",
    "Drongo", "Fantail", "Shrike", "Vireo", "Tanager", "Grosbeak", "Bunting", "Meadowlark", "Grackle", "Cowbird",
    "Gharial", "False Gharial", "Tomistoma", "Snapping Turtle", "Softshell Turtle", "Sideneck Turtle", "Matamata", "Tuatara", "Slow Worm", "Glass Lizard",
    "Whiptail", "Tegu", "Wall Lizard", "Rock Lizard", "Lace Monitor", "Perentie", "Water Monitor", "Tree Monitor", "Blind Snake", "Sunbeam Snake",
    "Pipe Snake", "Shieldtail Snake", "Filesnake", "Slug-eater", "Wolf Snake", "Vine Snake", "Cat Snake", "Tree Snake", "Flying Snake", "Water Snake",
    "Crayfish", "Prawn", "Shrimp", "Krill", "Mantid Shrimp", "Ostracod", "Copepod", "Water Flea", "Triops", "Fairy Shrimp",
    "Tadpole Shrimp", "Clam Shrimp", "Seed Shrimp", "Isopod", "Woodlouse", "Amphipod", "Sand Hopper", "Sea Spider", "Horseshoe Crab", "Tarantula Hawk",
    "Velvet Ant", "Mud Dauber", "Potter Wasp", "Gall Wasp", "Ichneumon Wasp", "Chalcid Wasp", "Sawfly", "Stonefly", "Mayfly", "Dobsonfly",
    "Alderfly", "Snakefly", "Lacewing", "Antlion", "Owlfly", "Scorpionfly", "Caddisfly", "Skipper", "Birdwing Butterfly", "Morpho Butterfly",
    "Owl Butterfly", "Glasswing Butterfly", "Clothes Moth", "Hawkmoth", "Sphinx Moth", "Silk Moth", "Emperor Moth", "Tiger Moth", "Underwing Moth", "Geometer Moth",
    "Crane Fly", "Gnat", "Midges", "Sand Fly", "Blow Fly", "Bot Fly", "Hover Fly", "Robber Fly", "Bee Fly", "Deer Fly",
    "Bed Bug", "Assassin Bug", "Water Boatman", "Backswimmer", "Giant Water Bug", "Stink Bug", "Shield Bug", "Leafhopper", "Treehopper", "Froghopper",
    "Planthopper", "Scale Insect", "Mealybug", "Whitefly", "Psyllid", "Thrips", "Silverfish", "Firebrat", "Springtail", "Bristletail",
    "Dipluran", "Proturan", "Garden Centipede", "Symphylan", "Pauropod", "Pill Bug", "Sowbug", "Water Slater", "Sea Louse", "Whale Louse",
    "Land Snail", "Garden Snail", "Giant African Snail", "Apple Snail", "Ramshorn Snail", "Limpet", "Whelk", "Periwinkle", "Cowrie", "Cone Snail",
    "Sea Hare", "Sea Butterfly", "Nautilus", "Paper Nautilus", "Squid", "Sepia", "Bobtail Squid", "Vampire Squid", "Dumbo Octopus", "Blue-ringed Octopus",
    "Giant Pacific Octopus", "Mimic Octopus", "Seven-arm Octopus", "Argonaut", "Lamp Shell", "Moss Animal", "Entoproct", "Horseshoe Worm", "Ribbon Worm", "Peanut Worm",
    "Spoon Worm", "Arrow Worm", "Velvet Worm", "Water Bear", "Tardigrade", "Beard Worm", "Acorn Worm", "Lancelet", "Sea Squirt", "Salp"
      ]..shuffle(),
    ),
  ];

  static List<String> getAllWords() {
    return decks.expand((deck) => deck.words).toList()..shuffle();
  }
}