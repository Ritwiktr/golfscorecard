import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/widgets/player_avatar.dart';
import '../../../core/widgets/empty_state.dart';
import '../bloc/player/player_bloc.dart';
import '../bloc/player/player_state.dart';
import '../bloc/game/game_bloc.dart';
import '../bloc/game/game_state.dart';
import '../../application/services/statistics_service.dart';
import '../../domain/player_statistics.dart';
import '../../domain/player.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final StatisticsService _statisticsService = StatisticsService();
  PlayerStatistics? _selectedPlayerStats;
  bool _isLoadingStats = false;
  Map<int, PlayerStatistics> _allPlayerStats = {};
  bool _isLoadingAllStats = false;
  bool _hasInitialized = false;

  Future<void> _loadAllPlayerStats(List<Player> players, {bool forceRefresh = false}) async {
    if (forceRefresh) {
      setState(() {
        _allPlayerStats = {};
        _selectedPlayerStats = null;
      });
      // Invalidate cache when forcing refresh
      await _statisticsService.invalidateCache();
    }

    setState(() {
      _isLoadingAllStats = true;
    });

    final Map<int, PlayerStatistics> statsMap = {};
    
    for (final player in players) {
      if (player.id != null) {
        try {
          // Use cache unless forcing refresh
          final stats = await _statisticsService.getPlayerStatistics(
            player.id!,
            useCache: !forceRefresh,
          );
          statsMap[player.id!] = stats;
        } catch (e) {
          // Skip players with errors, they'll show empty stats
        }
      }
    }

    if (!mounted) return;
    setState(() {
      _allPlayerStats = statsMap;
      _isLoadingAllStats = false;
      
      // Refresh selected player stats if one is selected
      if (_selectedPlayerStats != null && _selectedPlayerStats!.player.id != null) {
        final updatedStats = statsMap[_selectedPlayerStats!.player.id];
        if (updatedStats != null) {
          _selectedPlayerStats = updatedStats;
        }
      }
    });
  }

  Future<void> _loadPlayerDetails(int playerId) async {
    setState(() {
      _isLoadingStats = true;
    });

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      final stats = await _statisticsService.getPlayerStatistics(playerId);
      if (!mounted) return;
      setState(() {
        _selectedPlayerStats = stats;
        _isLoadingStats = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingStats = false;
      });
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Error loading statistics: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      colorScheme.primary.withOpacity(0.1),
                      colorScheme.secondary.withOpacity(0.05),
                    ]
                  : [
                      colorScheme.primary.withOpacity(0.05),
                      colorScheme.secondary.withOpacity(0.02),
                    ],
            ),
          ),
        ),
      ),
      body: MultiBlocListener(
        listeners: [
          // Listen to PlayerBloc changes (when players are added/updated/deleted)
          BlocListener<PlayerBloc, PlayerState>(
            listener: (context, state) {
              if (state is PlayerLoaded) {
                // Refresh stats when players change
                if (_hasInitialized) {
                  _loadAllPlayerStats(state.players, forceRefresh: true);
                }
              }
            },
          ),
          // Listen to GameBloc changes (when games are added/deleted)
          BlocListener<GameBloc, GameState>(
            listener: (context, state) {
              if (state is GamesLoaded) {
                // Refresh stats when games change
                if (_hasInitialized) {
                  final playerState = context.read<PlayerBloc>().state;
                  if (playerState is PlayerLoaded) {
                    _loadAllPlayerStats(playerState.players, forceRefresh: true);
                  }
                }
              }
            },
          ),
        ],
        child: BlocBuilder<PlayerBloc, PlayerState>(
          builder: (context, state) {
            if (state is PlayerLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is PlayerError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: colorScheme.error),
                    const SizedBox(height: 16),
                    Text('Error: ${state.message}'),
                  ],
                ),
              );
            }

            if (state is PlayerLoaded) {
              if (state.players.isEmpty) {
                return EmptyState(
                  icon: Icons.bar_chart,
                  title: 'No Statistics Available',
                  message: 'Play some games to see statistics!',
                );
              }

              // Load all stats when players are loaded (initial load)
              if (!_hasInitialized && _allPlayerStats.isEmpty && !_isLoadingAllStats) {
                _hasInitialized = true;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _loadAllPlayerStats(state.players);
                });
              }

              return Column(
                children: [
                  // Dropdown selector
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceVariant.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.outline.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.person_rounded,
                            color: colorScheme.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int?>(
                              value: _selectedPlayerStats?.player.id,
                              hint: Text(
                                'Select a player for detailed view',
                                style: TextStyle(
                                  color: colorScheme.onSurface.withOpacity(0.6),
                                  fontSize: 14,
                                ),
                              ),
                              isExpanded: true,
                              borderRadius: BorderRadius.circular(12),
                              items: [
                                DropdownMenuItem<int?>(
                                  value: null,
                                  child: Text(
                                    'All Players',
                                    style: TextStyle(
                                      color: colorScheme.onSurface.withOpacity(0.6),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                ...state.players.map((player) {
                                  return DropdownMenuItem<int?>(
                                    value: player.id,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        PlayerAvatar(
                                          photoPath: player.photoPath,
                                          name: player.name,
                                          radius: 14,
                                        ),
                                        const SizedBox(width: 12),
                                        Flexible(
                                          child: Text(
                                            player.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                              onChanged: (playerId) {
                                if (playerId != null) {
                                  _loadPlayerDetails(playerId);
                                } else {
                                  setState(() {
                                    _selectedPlayerStats = null;
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Content area
                  Expanded(
                    child: _isLoadingStats
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(color: colorScheme.primary),
                                const SizedBox(height: 16),
                                Text(
                                  'Loading statistics...',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: colorScheme.onSurface.withOpacity(0.6),
                                      ),
                                ),
                              ],
                            ),
                          )
                        : _selectedPlayerStats == null
                            ? _buildPlayersGrid(context, state.players)
                        : _buildStatisticsContent(context, _selectedPlayerStats!),
                  ),
                ],
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildPlayersGrid(BuildContext context, List<Player> players) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoadingAllStats) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: colorScheme.primary),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Loading player statistics...',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }

    // Responsive grid columns based on screen width
    final screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = 4;
    if (screenWidth < 600) {
      crossAxisCount = 2;
    } else if (screenWidth < 900) {
      crossAxisCount = 3;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
      children: [
          Text(
            'All Players',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.85,
            ),
            itemCount: players.length,
            itemBuilder: (context, index) {
              final player = players[index];
              final stats = player.id != null ? _allPlayerStats[player.id] : null;
              return _buildPlayerCard(context, player, stats);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerCard(BuildContext context, Player player, PlayerStatistics? stats) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = _selectedPlayerStats?.player.id == player.id;
    final screenWidth = MediaQuery.of(context).size.width;
    final avatarRadius = screenWidth < 600 ? 28.0 : 36.0;

    return GestureDetector(
      onTap: () {
        if (player.id != null) {
          _loadPlayerDetails(player.id!);
        }
      },
      child: Card(
        elevation: isSelected ? 4 : 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: isSelected
              ? BorderSide(color: colorScheme.primary, width: 2)
              : BorderSide.none,
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: isSelected
                ? LinearGradient(
                    colors: [
                      colorScheme.primaryContainer.withOpacity(0.4),
                      colorScheme.primaryContainer.withOpacity(0.2),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: isSelected ? [
                      BoxShadow(
                        color: colorScheme.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ] : null,
                  ),
                  child: PlayerAvatar(
                    photoPath: player.photoPath,
                    name: player.name,
                    radius: avatarRadius,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  player.name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: screenWidth < 600 ? 13 : null,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                if (stats != null && stats.totalGames > 0) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${stats.totalGames} games',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: screenWidth < 600 ? 10 : 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Avg: ${stats.averageScore.toStringAsFixed(1)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.7),
                      fontSize: screenWidth < 600 ? 10 : 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'No games',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.5),
                        fontSize: screenWidth < 600 ? 10 : 11,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildStatisticsContent(BuildContext context, PlayerStatistics stats) {
    final theme = Theme.of(context);
    final scoreRange = stats.worstScore - stats.bestScore;
    final consistency = scoreRange > 0 ? (1 - (scoreRange / stats.worstScore)).clamp(0.0, 1.0) : 1.0;

    return SingleChildScrollView(
      padding: EdgeInsets.all(MediaQuery.of(context).size.width < 600 ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Enhanced Player header with gradient
          _buildPlayerHeader(context, stats),
          SizedBox(height: MediaQuery.of(context).size.width < 600 ? 16 : 24),

          // Key Performance Metrics
          Text(
            'Performance Overview',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildPerformanceGrid(context, stats, consistency),
          SizedBox(height: MediaQuery.of(context).size.width < 600 ? 24 : 32),

          // Score Distribution
          if (stats.scoresByHole.isNotEmpty) ...[
            Text(
              'Average Scores by Hole',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildHoleScoresChart(context, stats),
            SizedBox(height: MediaQuery.of(context).size.width < 600 ? 24 : 32),
          ],

          // Additional Insights
          Text(
            'Additional Insights',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildInsightsSection(context, stats, scoreRange, consistency),
        ],
      ),
    );
  }

  Widget _buildPlayerHeader(BuildContext context, PlayerStatistics stats) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary,
            colorScheme.primaryContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
        child: isSmallScreen
            ? Column(
                children: [
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: PlayerAvatar(
                  photoPath: stats.player.photoPath,
                  name: stats.player.name,
                  radius: 40,
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stats.player.name,
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 16,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: [
                      _buildHeaderStat(
                        context,
                        Icons.golf_course,
                        '${stats.totalGames}',
                        'Games',
                        Colors.white,
                      ),
                      _buildHeaderStat(
                        context,
                        Icons.flag,
                        '${stats.totalHoles}',
                        'Holes',
                        Colors.white,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Avg Score',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                            const SizedBox(height: 2),
                      Text(
                              stats.averageScore.toStringAsFixed(1),
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              )
            : Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: PlayerAvatar(
                      photoPath: stats.player.photoPath,
                      name: stats.player.name,
                      radius: 50,
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stats.player.name,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 24,
                          runSpacing: 8,
                          children: [
                            _buildHeaderStat(
                              context,
                              Icons.golf_course,
                              '${stats.totalGames}',
                              'Games',
                              Colors.white,
                            ),
                            _buildHeaderStat(
                              context,
                              Icons.flag,
                              '${stats.totalHoles}',
                              'Holes',
                              Colors.white,
                            ),
                          ],
                ),
              ],
            ),
          ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
          children: [
                        Text(
                          'Avg Score',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          stats.averageScore.toStringAsFixed(1),
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildHeaderStat(
    BuildContext context,
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: color.withOpacity(0.9),
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceGrid(
    BuildContext context,
    PlayerStatistics stats,
    double consistency,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Responsive grid configuration
    // Lower aspect ratio = taller cards (more height)
    int crossAxisCount;
    double childAspectRatio;
    double spacing;
    
    if (screenWidth < 400) {
      // Very small phones - need taller cards
      crossAxisCount = 1;
      childAspectRatio = 2.2;
      spacing = 12;
    } else if (screenWidth < 600) {
      // Small phones - need taller cards
      crossAxisCount = 1;
      childAspectRatio = 2.0;
      spacing = 14;
    } else if (screenWidth < 900) {
      // Tablets
      crossAxisCount = 2;
      childAspectRatio = 1.3;
      spacing = 16;
    } else {
      // Large screens
      crossAxisCount = 2;
      childAspectRatio = 1.2;
      spacing = 16;
    }

    return GridView.count(
      crossAxisCount: crossAxisCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: spacing,
      mainAxisSpacing: spacing,
      childAspectRatio: childAspectRatio,
          children: [
        _buildEnhancedStatCard(
          context,
          'Best Score',
          stats.bestScore.toString(),
          Icons.emoji_events,
          Colors.amber,
          subtitle: 'Personal best',
        ),
        _buildEnhancedStatCard(
                context,
                'Average Score',
                stats.averageScore.toStringAsFixed(1),
                Icons.trending_up,
          Colors.green,
          subtitle: 'Overall average',
        ),
        _buildEnhancedStatCard(
          context,
          'Worst Score',
          stats.worstScore.toString(),
          Icons.trending_down,
          Colors.red,
          subtitle: 'Highest score',
        ),
        _buildEnhancedStatCard(
          context,
          'Consistency',
          '${(consistency * 100).toStringAsFixed(0)}%',
          Icons.analytics,
          Colors.blue,
          subtitle: 'Score stability',
        ),
      ],
    );
  }

  Widget _buildEnhancedStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color, {
    String? subtitle,
  }) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Responsive sizing based on screen dimensions
    final isSmallScreen = screenWidth < 600;
    final isVerySmallScreen = screenWidth < 400;
    
    final padding = isVerySmallScreen 
        ? 12.0 
        : isSmallScreen 
            ? 16.0 
            : 20.0;
    
    final iconSize = isVerySmallScreen 
        ? 20.0 
        : isSmallScreen 
            ? 22.0 
            : 24.0;
    
    final iconPadding = isVerySmallScreen 
        ? 8.0 
        : isSmallScreen 
            ? 9.0 
            : 10.0;
    
    final borderRadius = isSmallScreen ? 12.0 : 16.0;
    final iconBorderRadius = isSmallScreen ? 10.0 : 12.0;
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // Icon at top
            Container(
              padding: EdgeInsets.all(iconPadding),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(iconBorderRadius),
              ),
              child: Icon(icon, color: color, size: iconSize),
            ),
            // Spacer to push content down
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (subtitle != null) ...[
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                        fontSize: isVerySmallScreen ? 10 : isSmallScreen ? 11 : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: isVerySmallScreen ? 4 : 6),
                  ],
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: isVerySmallScreen 
                            ? 22 
                            : isSmallScreen 
                                ? 26 
                                : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(height: isVerySmallScreen ? 4 : 6),
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      fontSize: isVerySmallScreen ? 11 : isSmallScreen ? 12 : null,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHoleScoresChart(BuildContext context, PlayerStatistics stats) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Calculate average scores per hole
    final holeAverages = stats.scoresByHole.map(
      (hole, totalScore) => MapEntry(hole, totalScore / stats.totalGames),
    );
    
    // Sort by hole number
    final sortedHoles = holeAverages.keys.toList()..sort();
    final maxScore = holeAverages.values.isEmpty 
        ? 1.0 
        : holeAverages.values.reduce((a, b) => a > b ? a : b);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsets.all(MediaQuery.of(context).size.width < 600 ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bar_chart, color: colorScheme.primary),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Performance by Hole',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: sortedHoles.map((hole) {
                  final avgScore = holeAverages[hole]!;
                  final height = maxScore > 0 ? (avgScore / maxScore) * 150 : 0.0;
                  
                  return Container(
                    width: 50,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          height: height.clamp(20.0, 150.0),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                colorScheme.primary,
                                colorScheme.primaryContainer,
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(8),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              avgScore.toStringAsFixed(1),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            'H$hole',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightsSection(
    BuildContext context,
    PlayerStatistics stats,
    int scoreRange,
    double consistency,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    
    return isSmallScreen
        ? Column(
                children: [
              _buildInsightCard(
                context,
                'Score Range',
                '${stats.bestScore} - ${stats.worstScore}',
                Icons.swap_vert,
                colorScheme.secondary,
                '${scoreRange} stroke difference',
                  ),
                  const SizedBox(height: 16),
              _buildInsightCard(
                context,
                'Total Holes',
                '${stats.totalHoles}',
                Icons.flag,
                colorScheme.tertiary,
                'Across ${stats.totalGames} games',
              ),
            ],
          )
        : Row(
            children: [
              Expanded(
                child: _buildInsightCard(
                  context,
                  'Score Range',
                  '${stats.bestScore} - ${stats.worstScore}',
                  Icons.swap_vert,
                  colorScheme.secondary,
                  '${scoreRange} stroke difference',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInsightCard(
                  context,
                  'Total Holes',
                  '${stats.totalHoles}',
                  Icons.flag,
                  colorScheme.tertiary,
                  'Across ${stats.totalGames} games',
                ),
              ),
      ],
    );
  }

  Widget _buildInsightCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
              title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

