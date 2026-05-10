class UserStats {
  final int totalWorkouts;
  final int activeDays;
  final int totalDurationSeconds;
  final int currentStreak;

  UserStats({
    required this.totalWorkouts,
    required this.activeDays,
    required this.totalDurationSeconds,
    required this.currentStreak,
  });

  factory UserStats.empty() {
    return UserStats(
      totalWorkouts: 0,
      activeDays: 0,
      totalDurationSeconds: 0,
      currentStreak: 0,
    );
  }
}
