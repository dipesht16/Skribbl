import 'dart:math';

class WordList {
  static const List<String> defaultWords = [
    "actor", "airplane", "angry", "apple", "arm", "arrow", "artist", "axe", "backpack", "bag",
    "bakery", "ball", "balloon", "banana", "baseball", "basketball", "bath", "beach", "bear", "bed",
    "bee", "belt", "bicycle", "blanket", "boat", "book", "boots", "bored", "bottle", "bow",
    "bowl", "bowling", "box", "boxing", "bracelet", "bread", "bridge", "broccoli", "brush", "bucket",
    "burger", "bus", "butterfly", "cake", "camera", "candle", "cap", "car", "cards", "carrot",
    "castle", "cat", "cave", "chair", "cheese", "chef", "chess", "chest", "chocolate", "church",
    "cinema", "climbing", "clock", "cloud", "cloudy", "coat", "coffee", "coin", "comb", "compass",
    "computer", "cookie", "cooking", "crown", "cry", "cup", "dancer", "dancing", "deer", "desert",
    "diamond", "dice", "doctor", "dog", "dolphin", "donut", "door", "drawing", "dress", "drinking",
    "driving", "drum", "eagle", "ear", "earring", "earth", "eating", "elephant", "engineer", "excited",
    "eye", "face", "farmer", "finger", "fire", "firefighter", "fishing", "flag", "flamingo", "flower",
    "flying", "fog", "foot", "forest", "fork", "fox", "fridge", "frog", "garden", "ghost",
    "giraffe", "glasses", "gloves", "gold", "golf", "grape", "guitar", "hair", "hammer", "hand",
    "happy", "hat", "head", "heart", "helicopter", "helmet", "hockey", "hopscotch", "hospital", "hotdog",
    "hotel", "house", "ice cream", "island", "jacket", "juice", "jumping", "jungle", "kangaroo", "key",
    "keyboard", "kite", "knife", "koala", "ladder", "lake", "lamp", "laugh", "leg", "lemon",
    "library", "lighthouse", "lightning", "lion", "lock", "love", "map", "market", "milk", "mirror",
    "monkey", "moon", "motorcycle", "mountain", "mouth", "museum", "musician", "necklace", "noodles", "nose",
    "notebook", "nurse", "ocean", "octopus", "orange", "oven", "owl", "painting", "pan", "panda",
    "pants", "park", "parrot", "pasta", "pen", "pencil", "penguin", "phone", "piano", "pillow",
    "pilot", "pizza", "plane", "plate", "police", "popcorn", "pot", "purse", "pyramid", "rabbit",
    "rain", "rainbow", "rainy", "reading", "restaurant", "ring", "river", "rocket", "running", "sad",
    "sailing", "sandwich", "scared", "scarf", "school", "scientist", "scissors", "screwdriver", "seesaw", "shark",
    "shield", "shirt", "shoe", "shoes", "shovel", "shadow", "shower", "sick", "silver", "singer", "singing",
    "sink", "skateboard", "skating", "skiing", "skirt", "sleeping", "slide", "smile", "smiley", "smoke",
    "snake", "snow", "snowy", "soap", "soccer", "socks", "soda", "sofa", "spaceship", "spider",
    "spoon", "stadium", "star", "storm", "strawberry", "submarine", "sun", "sunflower", "sunny", "surfing",
    "surprised", "sushi", "sweater", "swimming", "swing", "sword", "table", "taco", "tea", "teacher",
    "telephone", "tennis", "thunder", "tie", "tiger", "tired", "toe", "toilet", "tomato", "tooth",
    "toothbrush", "tornado", "towel", "tower", "toy", "tractor", "train", "tree", "truck", "trumpet",
    "turtle", "umbrella", "violin", "volcano", "volleyball", "walking", "wallet", "waterfall", "watermelon", "wave",
    "whale", "wind", "windmill", "window", "windy", "wink", "wizard", "wolf", "writing", "zebra"
  ];

  static final Random _random = Random();

  /// Gets 4 random words for choice.
  static List<String> getWordChoices([String customWords = '']) {
    List<String> pool = [...defaultWords];
    if (customWords.isNotEmpty) {
      final customList = customWords
          .split(',')
          .map((s) => s.trim().toLowerCase())
          .where((s) => s.isNotEmpty && s.length <= 12)
          .toList();
      if (customList.isNotEmpty) {
        pool.addAll(customList);
      }
    }

    final Set<String> choices = {};
    while (choices.length < 4 && choices.length < pool.length) {
      choices.add(pool[_random.nextInt(pool.length)]);
    }

    while (choices.length < 4) {
      choices.addAll(["apple", "house", "sun", "car"].take(4 - choices.length));
    }

    return choices.toList();
  }

  /// Formats hint string, e.g., "apple" -> "_ _ _ _ _"
  /// If [revealedIndices] is provided, reveals characters at those positions, e.g., "_ p _ l _"
  static String getHint(String word, Set<int> revealedIndices) {
    List<String> chars = [];
    for (int i = 0; i < word.length; i++) {
      final char = word[i];
      if (char == ' ') {
        chars.add(' ');
      } else if (revealedIndices.contains(i)) {
        chars.add(char.toUpperCase());
      } else {
        chars.add('_');
      }
    }
    return chars.join(' ');
  }

  /// Calculates Levenshtein distance between two strings
  static int getLevenshteinDistance(String s1, String s2) {
    s1 = s1.trim().toLowerCase();
    s2 = s2.trim().toLowerCase();

    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    List<int> v0 = List<int>.generate(s2.length + 1, (i) => i);
    List<int> v1 = List<int>.filled(s2.length + 1, 0);

    for (int i = 0; i < s1.length; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < s2.length; j++) {
        int cost = (s1[i] == s2[j]) ? 0 : 1;
        v1[j + 1] = min(v1[j] + 1, min(v0[j + 1] + 1, v0[j] + cost));
      }
      for (int j = 0; j < v0.length; j++) {
        v0[j] = v1[j];
      }
    }
    return v0[s2.length];
  }

  /// Checks if a guess is close to the target word (Levenshtein distance == 1)
  static bool isClose(String guess, String target) {
    guess = guess.trim().toLowerCase();
    target = target.trim().toLowerCase();
    if (guess == target) return false;
    final dist = getLevenshteinDistance(guess, target);
    return dist == 1;
  }
}
