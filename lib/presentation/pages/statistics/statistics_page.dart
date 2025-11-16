import 'package:flutter/material.dart';
import 'package:bikeapp/core/constants/app_colors.dart';
import 'package:bikeapp/data/models/ride.dart';
import 'package:bikeapp/data/repositories/ride_repository.dart';
import 'package:intl/intl.dart';

/// Statistics Page
/// Shows detailed analytics and charts for ride performance
class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  final RideRepository _rideRepository = RideRepository();
  List<Ride> _allRides = [];
  bool _isLoading = true;
  String _selectedPeriod = 'all'; // 'week', 'month', 'year', 'all'

  @override
  void initState() {
    super.initState();
    _loadRides();
  }

  Future<void> _loadRides() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final rides = await _rideRepository.getRides();
      if (mounted) {
        setState(() {
          _allRides = rides;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading rides: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<Ride> get _filteredRides {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'week':
        final weekAgo = now.subtract(const Duration(days: 7));
        return _allRides.where((r) => r.startTime.isAfter(weekAgo)).toList();
      case 'month':
        final monthAgo = DateTime(now.year, now.month - 1, now.day);
        return _allRides.where((r) => r.startTime.isAfter(monthAgo)).toList();
      case 'year':
        final yearAgo = DateTime(now.year - 1, now.month, now.day);
        return _allRides.where((r) => r.startTime.isAfter(yearAgo)).toList();
      default:
        return _allRides;
    }
  }

  double get _totalDistance => _filteredRides.fold(0.0, (sum, ride) => sum + (ride.distance / 1000));
  int get _totalRides => _filteredRides.length;
  int get _totalDuration => _filteredRides.fold(0, (sum, ride) => sum + ride.duration);
  double get _averageSpeed => _filteredRides.isEmpty ? 0.0 : _filteredRides.fold(0.0, (sum, ride) => sum + ride.averageSpeed) / _filteredRides.length;
  double get _averageDistance => _totalRides == 0 ? 0.0 : _totalDistance / _totalRides;
  int get _averageDuration => _totalRides == 0 ? 0 : _totalDuration ~/ _totalRides;
  double get _longestRide => _filteredRides.isEmpty ? 0.0 : _filteredRides.map((r) => r.distance / 1000).reduce((a, b) => a > b ? a : b);
  double get _totalCalories {
    // Sum actual calories from rides that have the data
    final ridesWithCalories = _filteredRides.where((r) => r.calories != null);
    if (ridesWithCalories.isEmpty) {
      // Fallback to estimation if no rides have calorie data
      return _totalDistance * 50; // ~50 kcal per km estimate
    }
    return ridesWithCalories.fold(0.0, (sum, ride) => sum + ride.calories!);
  }
  double get _averageCalories => _totalRides == 0 ? 0.0 : _totalCalories / _totalRides;

  Map<String, int> get _ridesByType {
    final map = <String, int>{};
    for (var ride in _filteredRides) {
      map[ride.type] = (map[ride.type] ?? 0) + 1;
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGrey,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primaryOrange))
            : RefreshIndicator(
              onRefresh: _loadRides,
              color: AppColors.primaryOrange,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Period selector
                    _buildPeriodSelector(),
                    
                    const SizedBox(height: 20),

                    // Key metrics cards
                    Row(
                      children: [
                        Expanded(child: _buildMetricCard('Total Distance', '${_totalDistance.toStringAsFixed(1)} km', Icons.straighten, AppColors.primaryOrange)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildMetricCard('Total Rides', '$_totalRides', Icons.directions_bike, AppColors.primaryPurple)),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(child: _buildMetricCard('Total Time', _formatDuration(_totalDuration), Icons.access_time, AppColors.success)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildMetricCard('Calories', '${_totalCalories.toStringAsFixed(0)} kcal', Icons.local_fire_department, Colors.deepOrange)),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Averages section
                    _buildSectionTitle('Averages'),
                    const SizedBox(height: 12),
                    _buildStatsCard([
                      _buildStatRow('Average Distance', '${_averageDistance.toStringAsFixed(1)} km'),
                      const Divider(height: 24),
                      _buildStatRow('Average Duration', _formatDuration(_averageDuration)),
                      const Divider(height: 24),
                      _buildStatRow('Average Speed', '${_averageSpeed.toStringAsFixed(1)} km/h'),
                      const Divider(height: 24),
                      _buildStatRow('Average Calories', '${_averageCalories.toStringAsFixed(0)} kcal'),
                    ]),

                    const SizedBox(height: 24),

                    // Records section
                    _buildSectionTitle('Records'),
                    const SizedBox(height: 12),
                    _buildStatsCard([
                      _buildStatRow('Longest Ride', '${_longestRide.toStringAsFixed(1)} km'),
                      const Divider(height: 24),
                      _buildStatRow('Total Calories', '${_totalCalories.toStringAsFixed(0)} kcal'),
                      const Divider(height: 24),
                      _buildStatRow('Total Activities', '$_totalRides rides'),
                    ]),

                    const SizedBox(height: 24),

                    // Ride types breakdown
                    if (_ridesByType.isNotEmpty) ...[
                      _buildSectionTitle('Ride Types'),
                      const SizedBox(height: 12),
                      _buildRideTypesCard(),
                      const SizedBox(height: 24),
                    ],

                    // Recent activity
                    if (_filteredRides.isNotEmpty) ...[
                      _buildSectionTitle('Recent Activity'),
                      const SizedBox(height: 12),
                      _buildRecentActivityCard(),
                    ],

                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(child: _buildPeriodButton('Week', 'week')),
          Expanded(child: _buildPeriodButton('Month', 'month')),
          Expanded(child: _buildPeriodButton('Year', 'year')),
          Expanded(child: _buildPeriodButton('All Time', 'all')),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String label, String value) {
    final isSelected = _selectedPeriod == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPeriod = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryOrange : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildStatsCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildRideTypesCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: _ridesByType.entries.map((entry) {
          final percentage = (_totalRides > 0 ? (entry.value / _totalRides * 100) : 0).toStringAsFixed(0);
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          entry.key == 'Commute' ? Icons.work : Icons.directions_bike,
                          size: 20,
                          color: entry.key == 'Commute' ? AppColors.primaryPurple : AppColors.primaryOrange,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          entry.key,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${entry.value} rides ($percentage%)',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: entry.value / _totalRides,
                    backgroundColor: AppColors.backgroundGrey,
                    valueColor: AlwaysStoppedAnimation(
                      entry.key == 'Commute' ? AppColors.primaryPurple : AppColors.primaryOrange,
                    ),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRecentActivityCard() {
    final recentRides = _filteredRides.take(5).toList();
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: recentRides.asMap().entries.map((entry) {
          final ride = entry.value;
          final isLast = entry.key == recentRides.length - 1;
          
          return Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryOrange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.directions_bike, color: AppColors.primaryOrange, size: 24),
                ),
                title: Text(
                  ride.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                subtitle: Text(
                  DateFormat('MMM d, yyyy • h:mm a').format(ride.startTime),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${(ride.distance / 1000).toStringAsFixed(1)} km',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      _formatDuration(ride.duration),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast) const Divider(height: 1, indent: 76),
            ],
          );
        }).toList(),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
}
