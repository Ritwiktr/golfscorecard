class AppConstants {
  // Database
  static const String databaseName = 'minigolf_scorer.db';
  static const int databaseVersion = 2;
  
  // Tables
  static const String playersTable = 'players';
  static const String gamesTable = 'games';
  static const String scoresTable = 'scores';
  static const String statisticsCacheTable = 'statistics_cache';
  
  // Default values
  static const int defaultHoles = 18;
  static const int minHoles = 9;
  static const int maxHoles = 36;
  
  // App info
  static const String appName = 'Minigolf Scorer';
  static const String appTagline = 'Track your scores, improve your game';
}

