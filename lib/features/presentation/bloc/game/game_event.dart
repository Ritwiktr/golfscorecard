import 'package:equatable/equatable.dart';
import '../../../domain/game.dart';

abstract class GameEvent extends Equatable {
  const GameEvent();

  @override
  List<Object> get props => [];
}

class LoadGames extends GameEvent {
  const LoadGames();
}

class CreateGame extends GameEvent {
  final Game game;
  final Map<int, Map<int, int>> scores; // playerId -> holeNumber -> score

  const CreateGame(this.game, this.scores);

  @override
  List<Object> get props => [game, scores];
}

class LoadGameDetail extends GameEvent {
  final int gameId;

  const LoadGameDetail(this.gameId);

  @override
  List<Object> get props => [gameId];
}

class DeleteGame extends GameEvent {
  final int gameId;

  const DeleteGame(this.gameId);

  @override
  List<Object> get props => [gameId];
}

