import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../application/repositories/game_repository.dart';
import 'game_event.dart';
import 'game_state.dart';

class GameBloc extends Bloc<GameEvent, GameState> {
  final GameRepository _repository = GameRepository();

  GameBloc() : super(GameInitial()) {
    on<LoadGames>(_onLoadGames);
    on<CreateGame>(_onCreateGame);
    on<LoadGameDetail>(_onLoadGameDetail);
    on<DeleteGame>(_onDeleteGame);
  }

  Future<void> _onLoadGames(LoadGames event, Emitter<GameState> emit) async {
    emit(GameLoading());
    try {
      final games = await _repository.getAllGames();
      emit(GamesLoaded(games));
    } catch (e) {
      emit(GameError(e.toString()));
    }
  }

  Future<void> _onCreateGame(CreateGame event, Emitter<GameState> emit) async {
    try {
      final game = await _repository.createGame(event.game);
      await _repository.saveScores(game.id!, event.scores);
      final games = await _repository.getAllGames();
      emit(GamesLoaded(games));
    } catch (e) {
      emit(GameError(e.toString()));
    }
  }

  Future<void> _onLoadGameDetail(LoadGameDetail event, Emitter<GameState> emit) async {
    emit(GameLoading());
    try {
      final game = await _repository.getGameWithPlayers(event.gameId);
      emit(GameDetailLoaded(game));
    } catch (e) {
      emit(GameError(e.toString()));
    }
  }

  Future<void> _onDeleteGame(DeleteGame event, Emitter<GameState> emit) async {
    try {
      await _repository.deleteGame(event.gameId);
      final games = await _repository.getAllGames();
      emit(GamesLoaded(games));
    } catch (e) {
      emit(GameError(e.toString()));
    }
  }
}

