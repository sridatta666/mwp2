import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/providers.dart';
import 'admin_dashboard_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authService = ref.watch(authServiceProvider);
    final user = authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.signOut();
            },
            tooltip: 'Log Out',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Avatar
            CircleAvatar(
              radius: 60,
              backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
              child: Icon(
                Icons.person,
                size: 60,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              user?.email ?? 'Unknown User',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Member since 2026',
              style: TextStyle(color: Colors.grey[400]),
            ),
            const SizedBox(height: 32),
            
            // Stats Grid
            ref.watch(userStatsProvider).when(
              data: (stats) {
                int hours = stats.totalDurationSeconds ~/ 3600;
                int minutes = (stats.totalDurationSeconds % 3600) ~/ 60;
                String timeStr = hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';
                
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _buildStatCard(context, 'Workouts', '${stats.totalWorkouts}')),
                        const SizedBox(width: 16),
                        Expanded(child: _buildStatCard(context, 'Active Days', '${stats.activeDays}')),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildStatCard(context, 'Total Time', timeStr)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildStatCard(context, 'Current Streak', '${stats.currentStreak} 🔥')),
                      ],
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => const Center(child: Text('Could not load stats')),
            ),
            
            const SizedBox(height: 32),

            // Weekly Activity Chart
            _buildWeeklyChart(context, ref),

            const SizedBox(height: 32),
            // Settings List
            _buildSettingsTile(context, Icons.notifications_outlined, 'Notifications', onTap: () {}),
            _buildSettingsTile(context, Icons.dark_mode_outlined, 'Appearance', onTap: () {}),
            _buildSettingsTile(context, Icons.lock_outline, 'Privacy & Security', onTap: () {}),
            _buildSettingsTile(context, Icons.help_outline, 'Help & Support', onTap: () {}),
            
            const SizedBox(height: 24),
            const Divider(color: Colors.grey),
            const SizedBox(height: 16),
            
            // Admin Access
            _buildSettingsTile(
              context, 
              Icons.admin_panel_settings, 
              'Admin Dashboard', 
              color: Theme.of(context).primaryColor,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDashboardScreen()));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyChart(BuildContext context, WidgetRef ref) {
    final primary = Theme.of(context).primaryColor;
    
    return ref.watch(weeklyProgressProvider).when(
      data: (rawData) {
        // Build daily aggregation for the last 7 days
        final now = DateTime.now();
        final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        
        // Initialize last 7 days
        final List<_DayData> days = List.generate(7, (i) {
          final date = now.subtract(Duration(days: 6 - i));
          return _DayData(
            dayLabel: dayNames[date.weekday - 1],
            workoutCount: 0,
            totalMinutes: 0,
          );
        });

        // Aggregate raw data into days
        for (final row in rawData) {
          final dateStr = row['completed_at'] as String?;
          final durationSec = (row['duration_seconds'] as num?)?.toInt() ?? 0;
          if (dateStr != null) {
            final date = DateTime.parse(dateStr);
            final dayDiff = now.difference(date).inDays;
            if (dayDiff >= 0 && dayDiff < 7) {
              final idx = 6 - dayDiff;
              days[idx].workoutCount++;
              days[idx].totalMinutes += durationSec ~/ 60;
            }
          }
        }

        final maxMinutes = days.fold<int>(0, (max, d) => d.totalMinutes > max ? d.totalMinutes : max);
        final maxY = maxMinutes > 0 ? (maxMinutes + 10).toDouble() : 30.0;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[800]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'WEEKLY ACTIVITY',
                    style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    '${rawData.length} workouts',
                    style: TextStyle(color: primary, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 180,
                child: BarChart(
                  BarChartData(
                    maxY: maxY,
                    minY: 0,
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (_) => Colors.grey[800]!,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final day = days[group.x];
                          return BarTooltipItem(
                            '${day.totalMinutes} min\n${day.workoutCount} workout${day.workoutCount != 1 ? 's' : ''}',
                            TextStyle(color: primary, fontWeight: FontWeight.bold, fontSize: 12),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          getTitlesWidget: (value, meta) {
                            if (value == 0) return const SizedBox.shrink();
                            return Text(
                              '${value.toInt()}m',
                              style: TextStyle(color: Colors.grey[600], fontSize: 10),
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final idx = value.toInt();
                            if (idx < 0 || idx >= days.length) return const SizedBox.shrink();
                            final isToday = idx == 6;
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                isToday ? 'Today' : days[idx].dayLabel,
                                style: TextStyle(
                                  color: isToday ? primary : Colors.grey[500],
                                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                                  fontSize: 11,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: maxY / 3,
                      getDrawingHorizontalLine: (_) => FlLine(color: Colors.grey[800]!, strokeWidth: 0.5),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: List.generate(days.length, (i) {
                      final hasData = days[i].totalMinutes > 0;
                      return BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: hasData ? days[i].totalMinutes.toDouble() : 0,
                            width: 22,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                            gradient: hasData
                                ? LinearGradient(
                                    colors: [primary.withValues(alpha: 0.6), primary],
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                  )
                                : null,
                            color: hasData ? null : Colors.grey[800],
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => Container(
        height: 220,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Container(
        height: 220,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(child: Text('Could not load chart: $err', style: const TextStyle(color: Colors.grey))),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(BuildContext context, IconData icon, String title, {required VoidCallback onTap, Color? color}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color ?? Colors.white),
      ),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
}

class _DayData {
  final String dayLabel;
  int workoutCount;
  int totalMinutes;

  _DayData({required this.dayLabel, required this.workoutCount, required this.totalMinutes});
}
