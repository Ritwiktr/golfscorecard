import 'package:share_plus/share_plus.dart';
import '../../domain/game.dart';

class ShareService {
  static Future<void> shareGameResults(GameWithPlayers game) async {
    final rankings = game.getRankings();
    
    final buffer = StringBuffer();
    buffer.writeln('🏌️ Minigolf Game Results');
    buffer.writeln('Date: ${game.date.toString().split(' ')[0]}');
    buffer.writeln('Holes: ${game.holes}');
    buffer.writeln('');
    buffer.writeln('🏆 Rankings:');
    
    for (int i = 0; i < rankings.length; i++) {
      final entry = rankings[i];
      final position = i + 1;
      final emoji = position == 1 ? '🥇' : position == 2 ? '🥈' : position == 3 ? '🥉' : '$position.';
      buffer.writeln('$emoji ${entry.key.name}: ${entry.value} strokes');
    }
    
    if (game.notes != null && game.notes!.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('Notes: ${game.notes}');
    }

    await Share.share(buffer.toString());
  }
}

