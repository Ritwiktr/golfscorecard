import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/game/game_bloc.dart';
import '../bloc/game/game_event.dart';
import '../bloc/game/game_state.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/utils/date_utils.dart' as app_date_utils;

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Modern App Bar
          SliverAppBar(
            expandedHeight: 160,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: colorScheme.background,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Golf Scorecard',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [
                            colorScheme.primary.withOpacity(0.2),
                            colorScheme.secondary.withOpacity(0.1),
                          ]
                        : [
                            colorScheme.primary.withOpacity(0.1),
                            colorScheme.secondary.withOpacity(0.05),
                          ],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.history_rounded),
                onPressed: () async {
                  await Navigator.pushNamed(context, AppRoutes.gameHistory);
                  // Reload games when returning
                  if (context.mounted) {
                    context.read<GameBloc>().add(const LoadGames());
                  }
                },
                tooltip: 'Game History',
              ),
              IconButton(
                icon: const Icon(Icons.people_rounded),
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.players);
                },
                tooltip: 'Players',
              ),
              IconButton(
                icon: const Icon(Icons.bar_chart_rounded),
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.statistics);
                },
                tooltip: 'Statistics',
              ),
              IconButton(
                icon: const Icon(Icons.settings_rounded),
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.settings);
                },
                tooltip: 'Settings',
              ),
            ],
          ),

          // Content
          SliverToBoxAdapter(
            child: BlocBuilder<GameBloc, GameState>(
              builder: (context, state) {
                if (state is GameLoading) {
                  return Container(
                    height: MediaQuery.of(context).size.height * 0.7,
                    alignment: Alignment.center,
                    child: CircularProgressIndicator(
                      color: colorScheme.primary,
                    ),
                  );
                }

                if (state is GameError) {
                  return Container(
                    height: MediaQuery.of(context).size.height * 0.7,
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          size: 64,
                          color: colorScheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error: ${state.message}',
                          style: theme.textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            context.read<GameBloc>().add(const LoadGames());
                          },
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (state is GamesLoaded) {
                  // Store isEmpty state for FAB visibility
                  final isEmpty = state.games.isEmpty;
                  
                  if (isEmpty) {
                    return SizedBox(
                      height: MediaQuery.of(context).size.height * 0.7,
                      child: EmptyState(
                        icon: Icons.golf_course_rounded,
                        title: 'No Games Yet',
                        message: 'Start tracking your golf scores by creating a new game!',
                        action: ElevatedButton.icon(
                          onPressed: () async {
                            await Navigator.pushNamed(context, AppRoutes.newGame);
                            if (context.mounted) {
                              context.read<GameBloc>().add(const LoadGames());
                            }
                          },
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('New Game'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: state.games.length,
                    itemBuilder: (context, index) {
                      final game = state.games[index];
                      return TweenAnimationBuilder(
                        duration: Duration(milliseconds: 300 + (index * 50)),
                        tween: Tween<double>(begin: 0, end: 1),
                        builder: (context, double value, child) {
                          return Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(0, 20 * (1 - value)),
                              child: child,
                            ),
                          );
                        },
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () async {
                              await Navigator.pushNamed(
                                context,
                                AppRoutes.gameDetail,
                                arguments: game.id,
                              );
                              // Reload games after returning from detail screen
                              if (context.mounted) {
                                context.read<GameBloc>().add(const LoadGames());
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          colorScheme.primary,
                                          colorScheme.secondary,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.golf_course_rounded,
                                      size: 28,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          app_date_utils.AppDateUtils.formatDate(game.date),
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${game.holes} holes',
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            color: colorScheme.onSurface.withOpacity(0.6),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    color: colorScheme.primary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
      floatingActionButton: BlocBuilder<GameBloc, GameState>(
        builder: (context, state) {
          // Hide FAB when there are no games (empty state has its own button)
          if (state is GamesLoaded && state.games.isEmpty) {
            return const SizedBox.shrink();
          }
          
          return FloatingActionButton.extended(
            onPressed: () async {
              await Navigator.pushNamed(context, AppRoutes.newGame);
              if (context.mounted) {
                context.read<GameBloc>().add(const LoadGames());
              }
            },
            icon: const Icon(Icons.add_rounded),
            label: const Text('New Game'),
            elevation: 4,
          );
        },
      ),
    );
  }
}
