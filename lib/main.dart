import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/themes/app_theme.dart';
import 'core/themes/theme_cubit.dart';
import 'core/routes/app_routes.dart';
import 'features/presentation/screens/home_screen.dart';
import 'features/presentation/screens/new_game_screen.dart';
import 'features/presentation/screens/game_detail_screen.dart';
import 'features/presentation/screens/players_screen.dart';
import 'features/presentation/screens/statistics_screen.dart';
import 'features/presentation/screens/game_history_screen.dart';
import 'features/presentation/screens/settings_screen.dart';
import 'features/presentation/bloc/player/player_bloc.dart';
import 'features/presentation/bloc/player/player_event.dart';
import 'features/presentation/bloc/game/game_bloc.dart';
import 'features/presentation/bloc/game/game_event.dart';

void main() {
  runApp(const GolfScorecardApp());
}

class GolfScorecardApp extends StatelessWidget {
  const GolfScorecardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => ThemeCubit(),
          lazy: false,
        ),
        BlocProvider(
          create: (_) => PlayerBloc()..add(const LoadPlayers()),
          lazy: false,
        ),
        BlocProvider(
          create: (_) => GameBloc()..add(const LoadGames()),
          lazy: false,
        ),
      ],
      child: BlocBuilder<ThemeCubit, AppThemeMode>(
        builder: (context, themeMode) {
          return MaterialApp(
            title: 'Golf Scorecard',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: context.read<ThemeCubit>().themeMode,
            initialRoute: AppRoutes.home,
            routes: {
              AppRoutes.home: (context) => const HomeScreen(),
              AppRoutes.newGame: (context) => const NewGameScreen(),
              AppRoutes.gameDetail: (context) {
                final gameId = ModalRoute.of(context)!.settings.arguments as int;
                return GameDetailScreen(gameId: gameId);
              },
              AppRoutes.players: (context) => const PlayersScreen(),
              AppRoutes.statistics: (context) => const StatisticsScreen(),
              AppRoutes.gameHistory: (context) => const GameHistoryScreen(),
              AppRoutes.settings: (context) => const SettingsScreen(),
            },
          );
        },
      ),
    );
  }
}
