import '../../domain/player.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/error/failures.dart';

class PlayerRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<List<Player>> getAllPlayers() async {
    try {
      final db = await _dbHelper.database;
      final maps = await db.query(
        AppConstants.playersTable,
        orderBy: 'name ASC',
      );
      return maps.map((map) => Player.fromMap(map)).toList();
    } catch (e) {
      throw DatabaseFailure('Failed to fetch players: $e');
    }
  }

  Future<Player> createPlayer(Player player) async {
    try {
      final db = await _dbHelper.database;
      final id = await db.insert(
        AppConstants.playersTable,
        player.toMap(),
      );
      return player.copyWith(id: id);
    } catch (e) {
      throw DatabaseFailure('Failed to create player: $e');
    }
  }

  Future<Player> updatePlayer(Player player) async {
    try {
      final db = await _dbHelper.database;
      await db.update(
        AppConstants.playersTable,
        player.toMap(),
        where: 'id = ?',
        whereArgs: [player.id],
      );
      return player;
    } catch (e) {
      throw DatabaseFailure('Failed to update player: $e');
    }
  }

  Future<void> deletePlayer(int id) async {
    try {
      final db = await _dbHelper.database;
      await db.delete(
        AppConstants.playersTable,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw DatabaseFailure('Failed to delete player: $e');
    }
  }

  Future<Player?> getPlayerById(int id) async {
    try {
      final db = await _dbHelper.database;
      final maps = await db.query(
        AppConstants.playersTable,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (maps.isEmpty) return null;
      return Player.fromMap(maps.first);
    } catch (e) {
      throw DatabaseFailure('Failed to fetch player: $e');
    }
  }
}

