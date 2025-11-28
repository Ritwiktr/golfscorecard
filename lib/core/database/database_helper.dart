import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../constants/app_constants.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(AppConstants.databaseName);
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: AppConstants.databaseVersion,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
    );
  }

  Future<void> _onConfigure(Database db) async {
    // Enable foreign key constraints
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add statistics cache table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS ${AppConstants.statisticsCacheTable} (
          player_id INTEGER PRIMARY KEY,
          total_games INTEGER NOT NULL,
          total_holes INTEGER NOT NULL,
          average_score REAL NOT NULL,
          best_score INTEGER NOT NULL,
          worst_score INTEGER NOT NULL,
          scores_by_hole TEXT NOT NULL,
          last_updated INTEGER NOT NULL,
          FOREIGN KEY (player_id) REFERENCES ${AppConstants.playersTable} (id) ON DELETE CASCADE
        )
      ''');
      
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_statistics_cache_player 
        ON ${AppConstants.statisticsCacheTable} (player_id)
      ''');
    }
  }

  Future<void> _createDB(Database db, int version) async {
    // Players table
    await db.execute('''
      CREATE TABLE ${AppConstants.playersTable} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        photo_path TEXT,
        created_at INTEGER NOT NULL
      )
    ''');

    // Games table
    await db.execute('''
      CREATE TABLE ${AppConstants.gamesTable} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date INTEGER NOT NULL,
        holes INTEGER NOT NULL DEFAULT ${AppConstants.defaultHoles},
        notes TEXT,
        created_at INTEGER NOT NULL
      )
    ''');

    // Scores table
    await db.execute('''
      CREATE TABLE ${AppConstants.scoresTable} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        game_id INTEGER NOT NULL,
        player_id INTEGER NOT NULL,
        hole_number INTEGER NOT NULL,
        score INTEGER NOT NULL,
        FOREIGN KEY (game_id) REFERENCES ${AppConstants.gamesTable} (id) ON DELETE CASCADE,
        FOREIGN KEY (player_id) REFERENCES ${AppConstants.playersTable} (id) ON DELETE CASCADE
      )
    ''');

    // Indexes for better performance
    await db.execute('''
      CREATE INDEX idx_scores_game_player ON ${AppConstants.scoresTable} (game_id, player_id)
    ''');

    // Statistics cache table
    await db.execute('''
      CREATE TABLE ${AppConstants.statisticsCacheTable} (
        player_id INTEGER PRIMARY KEY,
        total_games INTEGER NOT NULL,
        total_holes INTEGER NOT NULL,
        average_score REAL NOT NULL,
        best_score INTEGER NOT NULL,
        worst_score INTEGER NOT NULL,
        scores_by_hole TEXT NOT NULL,
        last_updated INTEGER NOT NULL,
        FOREIGN KEY (player_id) REFERENCES ${AppConstants.playersTable} (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_statistics_cache_player 
      ON ${AppConstants.statisticsCacheTable} (player_id)
    ''');
  }

  Future<void> close() async {
    final db = await instance.database;
    await db.close();
  }
}

