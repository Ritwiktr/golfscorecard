import 'dart:convert';
import 'package:equatable/equatable.dart';
import 'player.dart';

class PlayerStatistics extends Equatable {
  final Player player;
  final int totalGames;
  final int totalHoles;
  final double averageScore;
  final int bestScore;
  final int worstScore;
  final Map<int, int> scoresByHole; // hole number -> total score

  const PlayerStatistics({
    required this.player,
    required this.totalGames,
    required this.totalHoles,
    required this.averageScore,
    required this.bestScore,
    required this.worstScore,
    required this.scoresByHole,
  });

  // Convert scoresByHole map to JSON string for storage
  String get scoresByHoleJson => jsonEncode(
    scoresByHole.map((k, v) => MapEntry(k.toString(), v)),
  );

  // Create from JSON string
  static Map<int, int> scoresByHoleFromJson(String json) {
    final map = jsonDecode(json) as Map<String, dynamic>;
    return map.map((k, v) => MapEntry(int.parse(k), v as int));
  }

  @override
  List<Object?> get props => [
        player,
        totalGames,
        totalHoles,
        averageScore,
        bestScore,
        worstScore,
        scoresByHole,
      ];
}

