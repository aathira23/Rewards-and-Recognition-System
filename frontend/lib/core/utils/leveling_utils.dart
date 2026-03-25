
class LevelingUtils {
  /// Defines level thresholds.
  /// Level 1: 0 - 99
  /// Level 2: 100 - 249
  /// Level 3: 250 - 499
  /// Level 4: 500 - 999
  /// Level 5: 1000 - 1999
  /// ...and so on.
  static const List<int> _thresholds = [0, 100, 250, 500, 1000, 2000, 5000];

  /// Calculates the current level based on total points.
  static int getLevel(int totalPoints) {
    for (int i = _thresholds.length - 1; i >= 0; i--) {
      if (totalPoints >= _thresholds[i]) {
        return i + 1;
      }
    }
    return 1;
  }

  /// Calculates the points required for the next level.
  /// Returns null if user is at max level.
  static int? getPointsToNextLevel(int totalPoints) {
    int currentLevel = getLevel(totalPoints);
    if (currentLevel >= _thresholds.length) {
      return null;
    }
    return _thresholds[currentLevel] - totalPoints;
  }

  /// Calculates progress (0.0 to 1.0) towards the next level.
  static double getProgress(int totalPoints) {
    int currentLevel = getLevel(totalPoints);
    if (currentLevel >= _thresholds.length) {
      return 1.0;
    }
    int currentThreshold = _thresholds[currentLevel - 1];
    int nextThreshold = _thresholds[currentLevel];
    
    int pointsInCurrentLevel = totalPoints - currentThreshold;
    int pointsNeededForLevel = nextThreshold - currentThreshold;
    
    return (pointsInCurrentLevel / pointsNeededForLevel).clamp(0.0, 1.0);
  }
}
