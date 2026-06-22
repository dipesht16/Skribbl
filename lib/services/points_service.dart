import 'dart:math';

class PointsService {
  // Constants
  static const int maxPoints = 150;
  static const int minPoints = 100;
  static const int defaultRoundTime = 80; // seconds
  static const int drawerPointsPerGuesser = 10;
  static const int speedBonusThreshold = 20; // seconds
  static const int speedBonusPoints = 20;
  
  /// Calculate points for a correct guess
  /// 
  /// [secondsElapsed] - Time since round started
  /// [totalSeconds] - Total round duration (default: 80)
  /// [streak] - Current correct guess streak (optional)
  static int calculateGuesserPoints({
    required int secondsElapsed,
    int totalSeconds = defaultRoundTime,
    int streak = 0,
  }) {
    // Ensure elapsed time doesn't exceed total
    secondsElapsed = min(secondsElapsed, totalSeconds);
    
    // Time-based points (150 at start, 100 at end)
    double timeRemaining = (totalSeconds - secondsElapsed).toDouble();
    double timePercentage = timeRemaining / totalSeconds;
    int basePoints = (minPoints + ((maxPoints - minPoints) * timePercentage)).round();
    
    // Streak bonus
    int streakBonus = _calculateStreakBonus(streak);
    
    // Total points
    int totalPoints = basePoints + streakBonus;
    
    return totalPoints;
  }
  
  /// Calculate points for the drawer
  /// 
  /// [correctGuessers] - Number of players who guessed correctly
  /// [firstGuessTime] - Time when first player guessed (in seconds)
  /// [totalPlayers] - Total number of players (excluding drawer)
  static int calculateDrawerPoints({
    required int correctGuessers,
    required int firstGuessTime,
    int totalPlayers = 0,
  }) {
    if (correctGuessers == 0) return 0;
    
    // Base points: 10 per correct guesser
    int basePoints = correctGuessers * drawerPointsPerGuesser;
    
    // Speed bonus if first guess was quick
    int speedBonus = 0;
    if (firstGuessTime <= speedBonusThreshold) {
      speedBonus = speedBonusPoints;
    }
    
    // Bonus for getting everyone to guess
    int perfectBonus = 0;
    if (totalPlayers > 0 && correctGuessers == totalPlayers) {
      perfectBonus = 30; // Everyone guessed!
    }
    
    int totalPoints = basePoints + speedBonus + perfectBonus;
    
    // Cap at 100 points
    return min(totalPoints, 100);
  }
  
  /// Calculate streak bonus
  static int _calculateStreakBonus(int streak) {
    if (streak >= 5) return 50;
    if (streak >= 3) return 25;
    if (streak >= 2) return 10;
    return 0;
  }
  
  /// Check if guess is close (for partial credit)
  static bool isCloseGuess(String guess, String answer) {
    guess = guess.toLowerCase().trim();
    answer = answer.toLowerCase().trim();
    
    // Exact match
    if (guess == answer) return true;
    
    // Contains check (for plural/singular)
    final int lenDiff = (guess.length - answer.length).abs();
    if (lenDiff <= 2 && guess.length >= 3 && answer.length >= 3) {
      if (answer.contains(guess) || guess.contains(answer)) {
        return true;
      }
    }
    
    // Levenshtein distance (typo tolerance)
    int distance = _levenshteinDistance(guess, answer);
    return distance <= 2; // Allow 2 character difference
  }
  
  /// Calculate Levenshtein distance (edit distance)
  static int _levenshteinDistance(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;
    
    List<int> v0 = List<int>.generate(s2.length + 1, (i) => i);
    List<int> v1 = List<int>.filled(s2.length + 1, 0);
    
    for (int i = 0; i < s1.length; i++) {
      v1[0] = i + 1;
      
      for (int j = 0; j < s2.length; j++) {
        int cost = (s1[i] == s2[j]) ? 0 : 1;
        v1[j + 1] = min(min(v1[j] + 1, v0[j + 1] + 1), v0[j] + cost);
      }
      
      List<int> temp = v0;
      v0 = v1;
      v1 = temp;
    }
    
    return v0[s2.length];
  }
  
  /// Calculate rank change based on points
  static String getRankEmoji(int rank) {
    switch (rank) {
      case 1: return '🥇';
      case 2: return '🥈';
      case 3: return '🥉';
      default: return '#$rank';
    }
  }
  
  /// Get point tier description
  static String getPointTier(int points) {
    if (points >= 140) return 'PERFECT!';
    if (points >= 120) return 'EXCELLENT!';
    if (points >= 110) return 'GREAT!';
    if (points >= 100) return 'GOOD!';
    return 'NICE TRY!';
  }
}
