import '../../domain/player_statistics.dart';
import '../repositories/game_repository.dart';
import '../repositories/player_repository.dart';

class StatisticsService {
  final GameRepository _gameRepository = GameRepository();
  final PlayerRepository _playerRepository = PlayerRepository();

  Future<PlayerStatistics> getPlayerStatistics(int playerId, {bool useCache = true}) async {
    final player = await _playerRepository.getPlayerById(playerId);
    if (player == null) {
      throw Exception('Player not found');
    }

    // Try to load from cache first
    if (useCache) {
      final cachedStats = await _gameRepository.getCachedStatistics(playerId);
      if (cachedStats != null) {
        return PlayerStatistics(
          player: player,
          totalGames: cachedStats['total_games'] as int,
          totalHoles: cachedStats['total_holes'] as int,
          averageScore: (cachedStats['average_score'] as num).toDouble(),
          bestScore: cachedStats['best_score'] as int,
          worstScore: cachedStats['worst_score'] as int,
          scoresByHole: PlayerStatistics.scoresByHoleFromJson(
            cachedStats['scores_by_hole'] as String,
          ),
        );
      }
    }

    // Calculate statistics from database
    final statsData = await _gameRepository.getPlayerStatistics(playerId);

    if (statsData.isEmpty) {
      final emptyStats = PlayerStatistics(
        player: player,
        totalGames: 0,
        totalHoles: 0,
        averageScore: 0,
        bestScore: 0,
        worstScore: 0,
        scoresByHole: {},
      );
      
      // Cache empty stats
      await _gameRepository.saveCachedStatistics(
        playerId,
        0,
        0,
        0,
        0,
        0,
        emptyStats.scoresByHoleJson,
      );
      
      return emptyStats;
    }

    final totalGames = statsData.length;
    final totalHoles = statsData.fold<int>(
      0,
      (sum, game) => sum + (game['holes'] as int),
    );
    final scores = statsData.map((game) => game['total_score'] as int).toList();
    final totalScore = scores.fold<int>(0, (sum, score) => sum + score);
    final averageScore = totalScore / totalGames;
    final bestScore = scores.reduce((a, b) => a < b ? a : b);
    final worstScore = scores.reduce((a, b) => a > b ? a : b);

    // Get scores by hole (total scores per hole across all games)
    final gameIds = statsData.map((game) => game['game_id'] as int).toList();
    final scoresByHole = <int, int>{};
    
    for (final gameId in gameIds) {
      final gameScores = await _gameRepository.getScoresForGame(gameId);
      final playerScores = gameScores[playerId] ?? {};
      playerScores.forEach((hole, score) {
        scoresByHole[hole] = (scoresByHole[hole] ?? 0) + score;
      });
    }

    final statistics = PlayerStatistics(
      player: player,
      totalGames: totalGames,
      totalHoles: totalHoles,
      averageScore: averageScore,
      bestScore: bestScore,
      worstScore: worstScore,
      scoresByHole: scoresByHole,
    );

    // Save to cache
    await _gameRepository.saveCachedStatistics(
      playerId,
      totalGames,
      totalHoles,
      averageScore,
      bestScore,
      worstScore,
      statistics.scoresByHoleJson,
    );

    return statistics;
  }

  Future<void> invalidateCache({int? playerId}) async {
    await _gameRepository.invalidateStatisticsCache(playerId: playerId);
  }
}

