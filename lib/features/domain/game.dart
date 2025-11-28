import 'package:equatable/equatable.dart';
import 'player.dart';

class Game extends Equatable {
  final int? id;
  final DateTime date;
  final int holes;
  final String? notes;
  final DateTime createdAt;
  final Map<int, Map<int, int>>? scores; // playerId -> holeNumber -> score

  const Game({
    this.id,
    required this.date,
    required this.holes,
    this.notes,
    required this.createdAt,
    this.scores,
  });

  Game copyWith({
    int? id,
    DateTime? date,
    int? holes,
    String? notes,
    DateTime? createdAt,
    Map<int, Map<int, int>>? scores,
  }) {
    return Game(
      id: id ?? this.id,
      date: date ?? this.date,
      holes: holes ?? this.holes,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      scores: scores ?? this.scores,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.millisecondsSinceEpoch,
      'holes': holes,
      'notes': notes,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Game.fromMap(Map<String, dynamic> map) {
    return Game(
      id: map['id'] as int?,
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      holes: map['holes'] as int,
      notes: map['notes'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }

  int? getTotalScoreForPlayer(int playerId) {
    if (scores == null || scores![playerId] == null) return null;
    final playerScores = scores![playerId];
    if (playerScores == null) return null;
    return playerScores.values.fold<int>(0, (sum, score) => sum + score);
  }

  Map<int, int> getScoresForPlayer(int playerId) {
    return scores?[playerId] ?? {};
  }

  @override
  List<Object?> get props => [id, date, holes, notes, createdAt, scores];
}

class GameWithPlayers extends Game {
  final List<Player> players;

  const GameWithPlayers({
    required super.id,
    required super.date,
    required super.holes,
    super.notes,
    required super.createdAt,
    super.scores,
    required this.players,
  });

  Map<int, int> getTotalScores() {
    final totals = <int, int>{};
    for (final player in players) {
      if (player.id != null) {
        final score = getTotalScoreForPlayer(player.id!);
        if (score != null) {
          totals[player.id!] = score;
        }
      }
    }
    return totals;
  }

  List<MapEntry<Player, int>> getRankings() {
    final totals = getTotalScores();
    final entries = totals.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    
    return entries.map((entry) {
      final player = players.firstWhere((p) => p.id == entry.key);
      return MapEntry(player, entry.value);
    }).toList();
  }
}

