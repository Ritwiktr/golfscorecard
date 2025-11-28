import 'package:sqflite/sqflite.dart';
import '../../domain/game.dart';
import '../../domain/player.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/error/failures.dart';

class GameRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<List<Game>> getAllGames() async {
    try {
      final db = await _dbHelper.database;
      final maps = await db.query(
        AppConstants.gamesTable,
        orderBy: 'date DESC',
      );
      return maps.map((map) => Game.fromMap(map)).toList();
    } catch (e) {
      throw DatabaseFailure('Failed to fetch games: $e');
    }
  }

  Future<Game> createGame(Game game) async {
    try {
      final db = await _dbHelper.database;
      final id = await db.insert(
        AppConstants.gamesTable,
        game.toMap(),
      );
      // Invalidate statistics cache when a new game is created
      await invalidateStatisticsCache();
      return game.copyWith(id: id);
    } catch (e) {
      throw DatabaseFailure('Failed to create game: $e');
    }
  }

  Future<void> saveScores(int gameId, Map<int, Map<int, int>> scores) async {
    try {
      final db = await _dbHelper.database;
      final batch = db.batch();

      // Delete existing scores for this game
      batch.delete(
        AppConstants.scoresTable,
        where: 'game_id = ?',
        whereArgs: [gameId],
      );

      // Insert new scores
      scores.forEach((playerId, holeScores) {
        holeScores.forEach((holeNumber, score) {
          batch.insert(
            AppConstants.scoresTable,
            {
              'game_id': gameId,
              'player_id': playerId,
              'hole_number': holeNumber,
              'score': score,
            },
          );
        });
      });

      await batch.commit(noResult: true);
      
      // Invalidate cache for affected players
      for (final playerId in scores.keys) {
        await invalidateStatisticsCache(playerId: playerId);
      }
    } catch (e) {
      throw DatabaseFailure('Failed to save scores: $e');
    }
  }

  Future<GameWithPlayers> getGameWithPlayers(int gameId) async {
    try {
      final db = await _dbHelper.database;
      
      // Get game
      final gameMaps = await db.query(
        AppConstants.gamesTable,
        where: 'id = ?',
        whereArgs: [gameId],
        limit: 1,
      );
      if (gameMaps.isEmpty) {
        throw DatabaseFailure('Game not found');
      }
      final game = Game.fromMap(gameMaps.first);

      // Get scores
      final scoreMaps = await db.query(
        AppConstants.scoresTable,
        where: 'game_id = ?',
        whereArgs: [gameId],
      );

      final scores = <int, Map<int, int>>{};
      for (final scoreMap in scoreMaps) {
        final playerId = scoreMap['player_id'] as int;
        final holeNumber = scoreMap['hole_number'] as int;
        final score = scoreMap['score'] as int;

        scores.putIfAbsent(playerId, () => {})[holeNumber] = score;
      }

      // Get players
      final playerIds = scores.keys.toList();
      if (playerIds.isEmpty) {
        return GameWithPlayers(
          id: game.id!,
          date: game.date,
          holes: game.holes,
          notes: game.notes,
          createdAt: game.createdAt,
          scores: scores,
          players: [],
        );
      }

      final placeholders = List.filled(playerIds.length, '?').join(',');
      final playerMaps = await db.query(
        AppConstants.playersTable,
        where: 'id IN ($placeholders)',
        whereArgs: playerIds,
      );

      final players = playerMaps.map((map) => Player.fromMap(map)).toList();

      return GameWithPlayers(
        id: game.id!,
        date: game.date,
        holes: game.holes,
        notes: game.notes,
        createdAt: game.createdAt,
        scores: scores,
        players: players,
      );
    } catch (e) {
      throw DatabaseFailure('Failed to fetch game: $e');
    }
  }

  Future<void> deleteGame(int gameId) async {
    try {
      final db = await _dbHelper.database;
      
      // Get player IDs from scores before deleting (for cache invalidation)
      final scoreMaps = await db.query(
        AppConstants.scoresTable,
        where: 'game_id = ?',
        whereArgs: [gameId],
      );
      final playerIds = scoreMaps.map((s) => s['player_id'] as int).toSet();
      
      await db.delete(
        AppConstants.gamesTable,
        where: 'id = ?',
        whereArgs: [gameId],
      );
      
      // Invalidate cache for affected players
      for (final playerId in playerIds) {
        await invalidateStatisticsCache(playerId: playerId);
      }
    } catch (e) {
      throw DatabaseFailure('Failed to delete game: $e');
    }
  }

  Future<Map<int, Map<int, int>>> getScoresForGame(int gameId) async {
    try {
      final db = await _dbHelper.database;
      final scoreMaps = await db.query(
        AppConstants.scoresTable,
        where: 'game_id = ?',
        whereArgs: [gameId],
      );

      final scores = <int, Map<int, int>>{};
      for (final scoreMap in scoreMaps) {
        final playerId = scoreMap['player_id'] as int;
        final holeNumber = scoreMap['hole_number'] as int;
        final score = scoreMap['score'] as int;

        scores.putIfAbsent(playerId, () => {})[holeNumber] = score;
      }
      return scores;
    } catch (e) {
      throw DatabaseFailure('Failed to fetch scores: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getPlayerStatistics(int playerId) async {
    try {
      final db = await _dbHelper.database;
      final result = await db.rawQuery('''
        SELECT 
          g.id as game_id,
          g.date,
          g.holes,
          SUM(s.score) as total_score
        FROM ${AppConstants.gamesTable} g
        INNER JOIN ${AppConstants.scoresTable} s ON g.id = s.game_id
        WHERE s.player_id = ?
        GROUP BY g.id, g.date, g.holes
        ORDER BY g.date DESC
      ''', [playerId]);

      return result;
    } catch (e) {
      throw DatabaseFailure('Failed to fetch statistics: $e');
    }
  }

  // Statistics cache methods
  Future<Map<String, dynamic>?> getCachedStatistics(int playerId) async {
    try {
      final db = await _dbHelper.database;
      final result = await db.query(
        AppConstants.statisticsCacheTable,
        where: 'player_id = ?',
        whereArgs: [playerId],
        limit: 1,
      );

      if (result.isEmpty) return null;
      return result.first;
    } catch (e) {
      // If table doesn't exist yet, return null
      return null;
    }
  }

  Future<void> saveCachedStatistics(
    int playerId,
    int totalGames,
    int totalHoles,
    double averageScore,
    int bestScore,
    int worstScore,
    String scoresByHoleJson,
  ) async {
    try {
      final db = await _dbHelper.database;
      await db.insert(
        AppConstants.statisticsCacheTable,
        {
          'player_id': playerId,
          'total_games': totalGames,
          'total_holes': totalHoles,
          'average_score': averageScore,
          'best_score': bestScore,
          'worst_score': worstScore,
          'scores_by_hole': scoresByHoleJson,
          'last_updated': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      // Silently fail if cache save fails
    }
  }

  Future<void> invalidateStatisticsCache({int? playerId}) async {
    try {
      final db = await _dbHelper.database;
      if (playerId != null) {
        await db.delete(
          AppConstants.statisticsCacheTable,
          where: 'player_id = ?',
          whereArgs: [playerId],
        );
      } else {
        // Clear all cache
        await db.delete(AppConstants.statisticsCacheTable);
      }
    } catch (e) {
      // Silently fail if cache clear fails
    }
  }
}

