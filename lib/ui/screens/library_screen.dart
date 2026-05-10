import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';
import 'exercise_detail_screen.dart';

const _muscleGroups = [
  {'key': 'all', 'label': 'All', 'icon': Icons.grid_view},
  {'key': 'chest', 'label': 'Chest', 'icon': Icons.fitness_center},
  {'key': 'back', 'label': 'Back', 'icon': Icons.accessibility_new},
  {'key': 'shoulders', 'label': 'Shoulders', 'icon': Icons.sports_gymnastics},
  {'key': 'arms', 'label': 'Arms', 'icon': Icons.front_hand},
  {'key': 'legs', 'label': 'Legs', 'icon': Icons.directions_walk},
  {'key': 'core', 'label': 'Core', 'icon': Icons.self_improvement},
  {'key': 'full_body', 'label': 'Full Body', 'icon': Icons.person},
  {'key': 'cardio', 'label': 'Cardio', 'icon': Icons.monitor_heart},
];

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  String _searchQuery = '';
  String _selectedGroup = 'all';

  @override
  Widget build(BuildContext context) {
    final exercisesAsync = ref.watch(exercisesProvider);
    final primary = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
        color: primary,
        onRefresh: () async => ref.invalidate(exercisesProvider),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 120.0,
              floating: false,
              pinned: true,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  'LIBRARY',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                    color: primary,
                  ),
                ),
                titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
              ),
            ),

            // Search bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Search exercises...',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    prefixIcon: Icon(Icons.search, color: primary),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () => setState(() => _searchQuery = ''),
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.grey[900],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
              ),
            ),

            // Category filter chips
            SliverToBoxAdapter(
              child: SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: _muscleGroups.length,
                  separatorBuilder: (_, index) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final group = _muscleGroups[index];
                    final isSelected = _selectedGroup == group['key'];
                    return GestureDetector(
                      onTap: () => setState(() => _selectedGroup = group['key'] as String),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: isSelected ? primary : Colors.grey[900],
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? primary : Colors.grey[800]!,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              group['icon'] as IconData,
                              size: 16,
                              color: isSelected ? Colors.black : Colors.grey,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              group['label'] as String,
                              style: TextStyle(
                                color: isSelected ? Colors.black : Colors.grey,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            const SliverPadding(padding: EdgeInsets.only(top: 16)),

            exercisesAsync.when(
              data: (exercises) {
                var filtered = exercises;

                // Apply muscle group filter
                if (_selectedGroup != 'all') {
                  filtered = filtered.where((e) => (e.muscleGroup ?? 'full_body') == _selectedGroup).toList();
                }

                // Apply search filter
                if (_searchQuery.isNotEmpty) {
                  filtered = filtered.where((e) =>
                      e.title.toLowerCase().contains(_searchQuery) ||
                      (e.description?.toLowerCase().contains(_searchQuery) ?? false)).toList();
                }

                if (filtered.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 48, color: Colors.grey[700]),
                          const SizedBox(height: 12),
                          Text(
                            _searchQuery.isEmpty ? 'No exercises in this category.' : 'No results for "$_searchQuery"',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final exercise = filtered[index];
                        final groupLabel = _muscleGroups.firstWhere(
                          (g) => g['key'] == (exercise.muscleGroup ?? 'full_body'),
                          orElse: () => {'label': 'Other'},
                        )['label'] as String;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey[900],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey[800]!),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(12),
                            leading: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.fitness_center, color: primary),
                            ),
                            title: Text(
                              exercise.title.toUpperCase(),
                              style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      groupLabel,
                                      style: TextStyle(color: primary, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      exercise.description ?? '',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => ExerciseDetailScreen(exercise: exercise)));
                            },
                          ),
                        );
                      },
                      childCount: filtered.length,
                    ),
                  ),
                );
              },
              loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
              error: (err, stack) => SliverFillRemaining(child: Center(child: Text('Error: $err'))),
            ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
          ],
        ),
      ),
    );
  }
}
