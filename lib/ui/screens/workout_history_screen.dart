import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';

class WorkoutHistoryScreen extends ConsumerWidget {
  const WorkoutHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(weeklyProgressProvider);
    final primary = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('WORKOUT HISTORY', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        backgroundColor: Colors.black,
      ),
      body: progressAsync.when(
        data: (data) {
          if (data.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey[700]),
                  const SizedBox(height: 16),
                  const Text('No workout history yet.', style: TextStyle(color: Colors.grey, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('Complete a workout to see it here!', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                ],
              ),
            );
          }

          // Group by date
          final Map<String, List<Map<String, dynamic>>> grouped = {};
          for (final row in data) {
            final dateStr = row['completed_at'] as String?;
            if (dateStr == null) continue;
            final date = DateTime.parse(dateStr);
            final key = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
            grouped.putIfAbsent(key, () => []).add(row);
          }

          final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sortedKeys.length,
            itemBuilder: (context, index) {
              final dateKey = sortedKeys[index];
              final entries = grouped[dateKey]!;
              final date = DateTime.parse(dateKey);
              final isToday = DateTime.now().difference(date).inDays == 0;
              final isYesterday = DateTime.now().difference(date).inDays == 1;

              String dateLabel;
              if (isToday) {
                dateLabel = 'Today';
              } else if (isYesterday) {
                dateLabel = 'Yesterday';
              } else {
                final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
                final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                dateLabel = '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
              }

              final totalMinutes = entries.fold<int>(0, (sum, e) => sum + ((e['duration_seconds'] as num?)?.toInt() ?? 0)) ~/ 60;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          dateLabel,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isToday ? primary : Colors.white,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${entries.length} workout${entries.length != 1 ? 's' : ''} • ${totalMinutes}m',
                            style: TextStyle(color: primary, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...entries.map((entry) {
                    final dur = (entry['duration_seconds'] as num?)?.toInt() ?? 0;
                    final mins = dur ~/ 60;
                    final secs = dur % 60;
                    final timeStr = '${mins}m ${secs}s';
                    final completedAt = DateTime.parse(entry['completed_at']);
                    final timeOfDay = '${completedAt.hour.toString().padLeft(2, '0')}:${completedAt.minute.toString().padLeft(2, '0')}';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[800]!),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.check_circle, color: primary, size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Workout Completed', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                const SizedBox(height: 4),
                                Text('Duration: $timeStr', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                              ],
                            ),
                          ),
                          Text(timeOfDay, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                        ],
                      ),
                    );
                  }),
                  if (index < sortedKeys.length - 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Divider(color: Colors.grey[850]),
                    ),
                ],
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.grey))),
      ),
    );
  }
}
