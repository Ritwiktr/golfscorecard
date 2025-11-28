import 'package:equatable/equatable.dart';
import '../../../domain/player.dart';

abstract class PlayerEvent extends Equatable {
  const PlayerEvent();

  @override
  List<Object> get props => [];
}

class LoadPlayers extends PlayerEvent {
  const LoadPlayers();
}

class CreatePlayer extends PlayerEvent {
  final Player player;

  const CreatePlayer(this.player);

  @override
  List<Object> get props => [player];
}

class UpdatePlayer extends PlayerEvent {
  final Player player;

  const UpdatePlayer(this.player);

  @override
  List<Object> get props => [player];
}

class DeletePlayer extends PlayerEvent {
  final int playerId;

  const DeletePlayer(this.playerId);

  @override
  List<Object> get props => [playerId];
}

