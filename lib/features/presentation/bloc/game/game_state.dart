import 'package:equatable/equatable.dart';
import '../../../domain/game.dart';

abstract class GameState extends Equatable {
  const GameState();

  @override
  List<Object> get props => [];
}

class GameInitial extends GameState {}

class GameLoading extends GameState {}

class GamesLoaded extends GameState {
  final List<Game> games;

  const GamesLoaded(this.games);

  @override
  List<Object> get props => [games];
}

class GameDetailLoaded extends GameState {
  final GameWithPlayers game;

  const GameDetailLoaded(this.game);

  @override
  List<Object> get props => [game];
}

class GameError extends GameState {
  final String message;

  const GameError(this.message);

  @override
  List<Object> get props => [message];
}

