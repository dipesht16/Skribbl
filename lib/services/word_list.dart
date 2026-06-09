import 'dart:math';

class WordList {
  static const List<String> defaultWords = [
    "house", "sun", "car", "tree", "flower", "smiley", "cloud", "star", "umbrella", "balloon",
    "face", "apple", "banana", "cat", "dog", "elephant", "guitar", "jacket", "lemon", "monkey",
    "notebook", "orange", "pencil", "rabbit", "sunflower", "telephone", "violin", "watermelon",
    "airplane", "castle", "dolphin", "earth", "forest", "ghost", "helicopter", "island",
    "jungle", "kangaroo", "lighthouse", "mountain", "ocean", "penguin", "rainbow", "spaceship",
    "train", "volcano", "wizard", "pizza", "burger", "cookie", "cheese", "clock", "computer",
    "keyboard", "hammer", "scissors", "screwdriver", "ladder", "window", "door", "chair",
    "table", "bed", "sofa", "pillow", "blanket", "mirror", "candle", "bucket", "shovel",
    "bicycle", "motorcycle", "truck", "tractor", "rocket", "submarine", "bridge", "tower",
    "pyramid", "church", "hospital", "school", "library", "stadium", "market", "bakery",
    "restaurant", "hotel", "cinema", "museum", "park", "garden", "beach", "desert", "cave",
    "river", "lake", "waterfall", "moon", "rain", "snow", "wind", "thunder", "lightning",
    "fire", "smoke", "gold", "silver", "diamond", "ring", "necklace", "crown", "sword",
    "shield", "bow", "arrow", "axe", "helmet", "flag", "map", "compass", "key", "lock",
    "chest", "coin", "wallet", "bag", "box", "bottle", "cup", "plate", "bowl", "fork",
    "spoon", "knife", "pot", "pan", "oven", "fridge", "sink", "shower", "bath", "toilet",
    "soap", "towel", "brush", "comb", "toothbrush", "glasses", "hat", "cap", "scarf",
    "gloves", "coat", "shirt", "pants", "socks", "shoes", "boots", "belt", "tie", "backpack"
  ];

  static final Random _random = Random();

  /// Gets 3 random words for choice.
  static List<String> getWordChoices([String customWords = '']) {
    List<String> pool = [...defaultWords];
    if (customWords.isNotEmpty) {
      final customList = customWords
          .split(',')
          .map((s) => s.trim().toLowerCase())
          .where((s) => s.isNotEmpty)
          .toList();
      if (customList.isNotEmpty) {
        pool.addAll(customList);
      }
    }

    final Set<String> choices = {};
    // Ensure we don't loop infinitely if pool is very small
    while (choices.length < 3 && choices.length < pool.length) {
      choices.add(pool[_random.nextInt(pool.length)]);
    }

    // Fallback if we don't have 3
    while (choices.length < 3) {
      choices.add("apple");
      choices.add("house");
      choices.add("sun");
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
