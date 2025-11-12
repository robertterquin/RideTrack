import 'package:flutter/material.dart';
import 'package:bikeapp/core/constants/app_colors.dart';
// StartRidePage intentionally not imported here; start is available from Dashboard

/// Rides Page
/// Shows ride history, filters, and allows starting new rides
class RidesPage extends StatefulWidget {
  const RidesPage({super.key});

  @override
  State<RidesPage> createState() => _RidesPageState();
}

class _RidesPageState extends State<RidesPage> {
  String _selectedFilter = 'All';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGrey,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            floating: true,
            pinned: true,
            automaticallyImplyLeading: false,
            toolbarHeight: 72,
            flexibleSpace: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.backgroundGrey,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value.toLowerCase();
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Search rides...',
                            hintStyle: TextStyle(
                              color: AppColors.textSecondary.withOpacity(0.6),
                              fontSize: 14,
                            ),
                            prefixIcon: const Icon(
                              Icons.search,
                              color: AppColors.textSecondary,
                              size: 20,
                            ),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.clear,
                                      color: AppColors.textSecondary,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _searchController.clear();
                                        _searchQuery = '';
                                      });
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    PopupMenuButton<String>(
                      icon: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundGrey,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.filter_list,
                          color: AppColors.textPrimary,
                          size: 20,
                        ),
                      ),
                      onSelected: (value) {
                        setState(() {
                          _selectedFilter = value;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.filter_list, color: Colors.white),
                                const SizedBox(width: 12),
                                Text('Filtering by: $value'),
                              ],
                            ),
                            backgroundColor: AppColors.primaryPurple,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            margin: const EdgeInsets.all(16),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'All', child: Text('All Rides')),
                        const PopupMenuItem(value: 'This Week', child: Text('This Week')),
                        const PopupMenuItem(value: 'This Month', child: Text('This Month')),
                        const PopupMenuItem(value: 'This Year', child: Text('This Year')),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 80),
            sliver: _buildRidesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRidesList() {
    final allRides = _getMockRides();
    
    // Filter rides based on search query
    final filteredRides = allRides.where((ride) {
      if (_searchQuery.isEmpty) return true;
      return ride['title']!.toLowerCase().contains(_searchQuery) ||
             ride['distance']!.toLowerCase().contains(_searchQuery) ||
             ride['type']!.toLowerCase().contains(_searchQuery);
    }).toList();

    if (filteredRides.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.directions_bike_outlined,
                size: 80,
                color: AppColors.textSecondary.withOpacity(0.3),
              ),
              const SizedBox(height: 16),
              Text(
                _searchQuery.isNotEmpty ? 'No rides found' : 'No rides yet',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _searchQuery.isNotEmpty
                    ? 'Try a different search term'
                    : _selectedFilter == 'All'
                        ? 'Tap "Start New Ride" from Dashboard to begin'
                        : 'No rides in $_selectedFilter',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary.withOpacity(0.5),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final ride = filteredRides[index];
          return _buildRideCard(
            title: ride['title']!,
            distance: ride['distance']!,
            duration: ride['duration']!,
            date: ride['date']!,
            type: ride['type']!,
            icon: ride['icon'] as IconData,
          );
        },
        childCount: filteredRides.length,
      ),
    );
  }

  List<Map<String, dynamic>> _getMockRides() {
    return [
      {
        'title': 'Morning Commute',
        'distance': '12.5 km',
        'duration': '35 min',
        'date': 'Today, 8:30 AM',
        'type': 'Commute',
        'icon': Icons.wb_sunny_outlined,
      },
      {
        'title': 'Evening Ride',
        'distance': '18.2 km',
        'duration': '52 min',
        'date': 'Yesterday, 6:15 PM',
        'type': 'Recreation',
        'icon': Icons.nightlight_outlined,
      },
      {
        'title': 'Weekend Trail',
        'distance': '32.8 km',
        'duration': '1h 45m',
        'date': 'Nov 7, 10:00 AM',
        'type': 'Recreation',
        'icon': Icons.terrain,
      },
      {
        'title': 'Office Commute',
        'distance': '11.3 km',
        'duration': '32 min',
        'date': 'Nov 6, 8:45 AM',
        'type': 'Commute',
        'icon': Icons.business,
      },
      {
        'title': 'Lunch Break Ride',
        'distance': '8.5 km',
        'duration': '25 min',
        'date': 'Nov 6, 12:30 PM',
        'type': 'Recreation',
        'icon': Icons.restaurant,
      },
      {
        'title': 'City Tour',
        'distance': '25.4 km',
        'duration': '1h 18m',
        'date': 'Nov 5, 3:00 PM',
        'type': 'Recreation',
        'icon': Icons.location_city,
      },
    ];
  }

  Widget _buildRideCard({
    required String title,
    required String distance,
    required String duration,
    required String date,
    required String type,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // TODO: Navigate to ride details
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(child: Text('Ride details for "$title" coming soon!')),
                  ],
                ),
                backgroundColor: AppColors.primaryPurple,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                margin: const EdgeInsets.all(16),
                duration: const Duration(seconds: 2),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppColors.primaryOrange, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: type == 'Commute'
                                  ? AppColors.primaryPurple.withOpacity(0.1)
                                  : AppColors.primaryOrange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              type,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: type == 'Commute' ? AppColors.primaryPurple : AppColors.primaryOrange,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.straighten, size: 14, color: AppColors.textSecondary.withOpacity(0.7)),
                          const SizedBox(width: 4),
                          Text(
                            distance,
                            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          ),
                          const SizedBox(width: 12),
                          Icon(Icons.access_time, size: 14, color: AppColors.textSecondary.withOpacity(0.7)),
                          const SizedBox(width: 4),
                          Text(
                            duration,
                            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        date,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.lightGrey),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
