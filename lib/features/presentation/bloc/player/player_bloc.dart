import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../application/repositories/player_repository.dart';
import 'player_event.dart';
import 'player_state.dart';

class PlayerBloc extends Bloc<PlayerEvent, PlayerState> {
  final PlayerRepository _repository = PlayerRepository();

  PlayerBloc() : super(PlayerInitial()) {
    on<LoadPlayers>(_onLoadPlayers);
    on<CreatePlayer>(_onCreatePlayer);
    on<UpdatePlayer>(_onUpdatePlayer);
    on<DeletePlayer>(_onDeletePlayer);
  }

  Future<void> _onLoadPlayers(LoadPlayers event, Emitter<PlayerState> emit) async {
    emit(PlayerLoading());
    try {
      final players = await _repository.getAllPlayers();
      emit(PlayerLoaded(players));
    } catch (e) {
      emit(PlayerError(e.toString()));
    }
  }

  Future<void> _onCreatePlayer(CreatePlayer event, Emitter<PlayerState> emit) async {
    try {
      await _repository.createPlayer(event.player);
      final players = await _repository.getAllPlayers();
      emit(PlayerLoaded(players));
    } catch (e) {
      emit(PlayerError(e.toString()));
    }
  }

  Future<void> _onUpdatePlayer(UpdatePlayer event, Emitter<PlayerState> emit) async {
    try {
      await _repository.updatePlayer(event.player);
      final players = await _repository.getAllPlayers();
      emit(PlayerLoaded(players));
    } catch (e) {
      emit(PlayerError(e.toString()));
    }
  }

  Future<void> _onDeletePlayer(DeletePlayer event, Emitter<PlayerState> emit) async {
    try {
      await _repository.deletePlayer(event.playerId);
      final players = await _repository.getAllPlayers();
      emit(PlayerLoaded(players));
    } catch (e) {
      emit(PlayerError(e.toString()));
    }
  }
}

