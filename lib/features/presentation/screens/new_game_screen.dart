import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/player_avatar.dart';
import '../bloc/game/game_bloc.dart';
import '../bloc/game/game_event.dart';
import '../bloc/player/player_bloc.dart';
import '../bloc/player/player_state.dart';
import '../../domain/game.dart';
import '../../domain/player.dart';

class NewGameScreen extends StatefulWidget {
  const NewGameScreen({super.key});

  @override
  State<NewGameScreen> createState() => _NewGameScreenState();
}

class _NewGameScreenState extends State<NewGameScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  int _selectedHoles = AppConstants.defaultHoles;
  final Map<int, bool> _selectedPlayers = {};
  final Map<int, Map<int, int>> _scores = {}; // playerId -> holeNumber -> score

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _togglePlayer(int playerId) {
    setState(() {
      if (_selectedPlayers[playerId] == true) {
        _selectedPlayers[playerId] = false;
        _scores.remove(playerId);
      } else {
        _selectedPlayers[playerId] = true;
        _scores[playerId] = {};
        for (int i = 1; i <= _selectedHoles; i++) {
          _scores[playerId]![i] = 0;
        }
      }
    });
  }

  void _updateScore(int playerId, int holeNumber, int score) {
    setState(() {
      _scores[playerId]![holeNumber] = score;
    });
  }

  MapEntry<Player, int>? _getCurrentWinner(List<Player> players) {
    final totals = <int, int>{};
    
    for (final player in players) {
      if (player.id != null && _selectedPlayers[player.id] == true) {
        final playerScores = _scores[player.id] ?? {};
        final total = playerScores.values.fold<int>(0, (sum, score) => sum + score);
        if (total > 0) { // Only include players with at least one score
          totals[player.id!] = total;
        }
      }
    }
    
    if (totals.isEmpty) return null;
    
    final sortedEntries = totals.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value)); // Lower is better in golf
    
    final winnerEntry = sortedEntries.first;
    final winner = players.firstWhere((p) => p.id != null && p.id == winnerEntry.key);
    return MapEntry(winner, winnerEntry.value);
  }

  void _saveGame() {
    if (_selectedPlayers.values.every((selected) => !selected)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one player')),
      );
      return;
    }

    final game = Game(
      date: _selectedDate,
      holes: _selectedHoles,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
      createdAt: DateTime.now(),
    );

    context.read<GameBloc>().add(CreateGame(game, _scores));
    Navigator.pop(context);
  }

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
            expandedHeight: 140,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: colorScheme.background,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'New Game',
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
          ),

          // Content
          SliverToBoxAdapter(
            child: BlocBuilder<PlayerBloc, PlayerState>(
              builder: (context, playerState) {
                if (playerState is PlayerLoading) {
                  return Container(
                    height: MediaQuery.of(context).size.height * 0.7,
                    alignment: Alignment.center,
                    child: CircularProgressIndicator(
                      color: colorScheme.primary,
                    ),
                  );
                }

                if (playerState is PlayerError) {
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
                          'Error: ${playerState.message}',
                          style: theme.textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  );
                }

                if (playerState is PlayerLoaded) {
                  if (playerState.players.isEmpty) {
                    return Container(
                      height: MediaQuery.of(context).size.height * 0.7,
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline_rounded,
                            size: 64,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No players yet. Add players first!',
                            style: theme.textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pushNamed(context, '/players');
                            },
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Add Players'),
                          ),
                        ],
                      ),
                    );
                  }

                  return Form(
                    key: _formKey,
                    child: ListView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Date picker
                        Card(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => _selectDate(context),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: colorScheme.primaryContainer,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Icons.calendar_today_rounded,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Date',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: colorScheme.onSurface.withOpacity(0.6),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
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
                        const SizedBox(height: 16),

                        // Holes selector
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.golf_course_rounded,
                                      color: colorScheme.primary,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Number of Holes',
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                SegmentedButton<int>(
                                  segments: const [
                                    ButtonSegment(value: 9, label: Text('9')),
                                    ButtonSegment(value: 18, label: Text('18')),
                                    ButtonSegment(value: 27, label: Text('27')),
                                    ButtonSegment(value: 36, label: Text('36')),
                                  ],
                                  selected: {_selectedHoles},
                                  onSelectionChanged: (Set<int> newSelection) {
                                    setState(() {
                                      _selectedHoles = newSelection.first;
                                      // Reset scores for new hole count
                                      _scores.forEach((playerId, scores) {
                                        scores.clear();
                                        for (int i = 1; i <= _selectedHoles; i++) {
                                          scores[i] = 0;
                                        }
                                      });
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Players selection
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.people_rounded,
                                          color: colorScheme.primary,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          'Select Players',
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    TextButton.icon(
                                      onPressed: () {
                                        Navigator.pushNamed(context, '/players');
                                      },
                                      icon: const Icon(Icons.add_rounded),
                                      label: const Text('Add'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: playerState.players.map((player) {
                                    final isSelected = _selectedPlayers[player.id] == true;
                                    return FilterChip(
                                      avatar: PlayerAvatar(
                                        photoPath: player.photoPath,
                                        name: player.name,
                                        radius: 16,
                                      ),
                                      label: Text(player.name),
                                      selected: isSelected,
                                      onSelected: (_) {
                                        if (player.id != null) {
                                          _togglePlayer(player.id!);
                                        }
                                      },
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Winner display
                        if (_selectedPlayers.values.any((selected) => selected))
                          Builder(
                            builder: (context) {
                              final winner = _getCurrentWinner(playerState.players);
                              if (winner != null) {
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: isDark
                                            ? [
                                                colorScheme.primary.withOpacity(0.2),
                                                colorScheme.secondary.withOpacity(0.15),
                                              ]
                                            : [
                                                colorScheme.primary.withOpacity(0.1),
                                                colorScheme.secondary.withOpacity(0.05),
                                              ],
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    padding: const EdgeInsets.all(20),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: colorScheme.primaryContainer,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.emoji_events_rounded,
                                            color: colorScheme.onPrimaryContainer,
                                            size: 32,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Current Leader',
                                                style: theme.textTheme.bodySmall?.copyWith(
                                                  color: colorScheme.onSurface.withOpacity(0.7),
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  PlayerAvatar(
                                                    photoPath: winner.key.photoPath,
                                                    name: winner.key.name,
                                                    radius: 20,
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Text(
                                                      winner.key.name,
                                                      style: theme.textTheme.titleLarge?.copyWith(
                                                        fontWeight: FontWeight.bold,
                                                        color: colorScheme.primary,
                                                      ),
                                                    ),
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 6,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: colorScheme.primaryContainer,
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: Text(
                                                      '${winner.value}',
                                                      style: theme.textTheme.titleMedium?.copyWith(
                                                        fontWeight: FontWeight.bold,
                                                        color: colorScheme.onPrimaryContainer,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),

                        // Score input
                        if (_selectedPlayers.values.any((selected) => selected))
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.scoreboard_rounded,
                                        color: colorScheme.primary,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Scores',
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  ...playerState.players.where((player) {
                                    return player.id != null && _selectedPlayers[player.id] == true;
                                  }).map((player) {
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 20),
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: colorScheme.surfaceVariant.withOpacity(0.3),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: colorScheme.outline.withOpacity(0.2),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              PlayerAvatar(
                                                photoPath: player.photoPath,
                                                name: player.name,
                                                radius: 20,
                                              ),
                                              const SizedBox(width: 12),
                                              Text(
                                                player.name,
                                                style: theme.textTheme.titleSmall?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 8,
                                            children: List.generate(_selectedHoles, (index) {
                                              final holeNumber = index + 1;
                                              final score = _scores[player.id]?[holeNumber] ?? 0;
                                              return SizedBox(
                                                width: 60,
                                                child: TextFormField(
                                                  initialValue: score == 0 ? '' : score.toString(),
                                                  keyboardType: TextInputType.number,
                                                  decoration: InputDecoration(
                                                    labelText: 'H$holeNumber',
                                                    border: const OutlineInputBorder(),
                                                    contentPadding: const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 8,
                                                    ),
                                                  ),
                                                  onChanged: (value) {
                                                    final scoreValue = int.tryParse(value) ?? 0;
                                                    if (player.id != null) {
                                                      _updateScore(player.id!, holeNumber, scoreValue);
                                                    }
                                                  },
                                                ),
                                              );
                                            }),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),

                        // Notes
                        TextFormField(
                          controller: _notesController,
                          decoration: InputDecoration(
                            labelText: 'Notes (optional)',
                            hintText: 'Add any notes about this game...',
                            border: const OutlineInputBorder(),
                            prefixIcon: Icon(
                              Icons.note_rounded,
                              color: colorScheme.primary,
                            ),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 24),

                        // Save button
                        ElevatedButton.icon(
                          onPressed: _saveGame,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          icon: const Icon(Icons.save_rounded),
                          label: const Text('Save Game'),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}

