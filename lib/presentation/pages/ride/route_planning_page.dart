import 'package:flutter/material.dart';
import 'package:bikeapp/core/constants/app_colors.dart';
import 'package:bikeapp/presentation/widgets/map/map_widget.dart';
import 'package:bikeapp/core/services/routing_service.dart';
import 'package:bikeapp/core/services/gps_service.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';

/// Route Planning Page
/// Allows users to search for start and end points and view route on map
class RoutePlanningPage extends StatefulWidget {
  const RoutePlanningPage({super.key});

  @override
  State<RoutePlanningPage> createState() => _RoutePlanningPageState();
}

class _RoutePlanningPageState extends State<RoutePlanningPage> {
  final _startController = TextEditingController();
  final _endController = TextEditingController();
  final _routingService = RoutingService();
  final _gpsService = GpsService();
  final _mapController = MapController();

  LatLng? _startPoint;
  LatLng? _endPoint;
  List<LatLng> _routePoints = [];
  double? _routeDistance;
  int? _routeDuration;
  bool _isCalculatingRoute = false;
  List<Location> _startSuggestions = [];
  List<Location> _endSuggestions = [];
  bool _showStartSuggestions = false;
  bool _showEndSuggestions = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _startController.dispose();
    _endController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final hasPermission = await _gpsService.requestPermission();
      if (!hasPermission) return;

      final position = await _gpsService.getCurrentPosition();
      if (mounted) {
        setState(() {
          _startPoint = LatLng(position.latitude, position.longitude);
        });
        _mapController.move(_startPoint!, 13.0);
        
        // Get address for current location
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty && mounted) {
          final place = placemarks.first;
          _startController.text = '${place.street ?? ''}, ${place.locality ?? ''}';
        }
      }
    } catch (e) {
      print('Error getting current location: $e');
    }
  }

  Future<void> _searchLocation(String query, bool isStart) async {
    if (query.trim().isEmpty) {
      setState(() {
        if (isStart) {
          _startSuggestions = [];
          _showStartSuggestions = false;
        } else {
          _endSuggestions = [];
          _showEndSuggestions = false;
        }
      });
      return;
    }

    try {
      print('🔍 Searching for: $query');
      final locations = await locationFromAddress(query);
      print('✅ Found ${locations.length} locations');
      
      if (mounted) {
        setState(() {
          if (isStart) {
            _startSuggestions = locations;
            _showStartSuggestions = locations.isNotEmpty;
          } else {
            _endSuggestions = locations;
            _showEndSuggestions = locations.isNotEmpty;
          }
        });
      }
    } catch (e) {
      print('❌ Error searching location: $e');
      
      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Could not find location. Try: "Manila", "Quezon City", or tap on map'),
                ),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 3),
          ),
        );
        
        setState(() {
          if (isStart) {
            _showStartSuggestions = false;
          } else {
            _showEndSuggestions = false;
          }
        });
      }
    }
  }

  Future<void> _selectLocation(Location location, bool isStart) async {
    final latLng = LatLng(location.latitude, location.longitude);
    
    // Get readable address
    try {
      final placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );
      
      if (placemarks.isNotEmpty && mounted) {
        final place = placemarks.first;
        final address = '${place.street ?? ''}, ${place.locality ?? ''}';
        
        setState(() {
          if (isStart) {
            _startPoint = latLng;
            _startController.text = address;
            _showStartSuggestions = false;
          } else {
            _endPoint = latLng;
            _endController.text = address;
            _showEndSuggestions = false;
          }
        });

        // Calculate route if both points are set
        if (_startPoint != null && _endPoint != null) {
          await _calculateRoute();
        }

        // Move map to show the point
        _mapController.move(latLng, 14.0);
      }
    } catch (e) {
      print('Error getting placemark: $e');
    }
  }

  Future<void> _calculateRoute() async {
    if (_startPoint == null || _endPoint == null) return;

    setState(() {
      _isCalculatingRoute = true;
    });

    try {
      final route = await _routingService.getRoute(_startPoint!, _endPoint!);
      final distance = await _routingService.getRouteDistance(_startPoint!, _endPoint!);
      final duration = await _routingService.getRouteDuration(_startPoint!, _endPoint!);

      if (mounted) {
        setState(() {
          _routePoints = route;
          _routeDistance = distance;
          _routeDuration = duration;
          _isCalculatingRoute = false;
        });

        // Fit map to show entire route
        if (_routePoints.length >= 2) {
          final bounds = LatLngBounds.fromPoints(_routePoints);
          _mapController.fitCamera(CameraFit.bounds(
            bounds: bounds,
            padding: const EdgeInsets.all(50),
          ));
        }
      }
    } catch (e) {
      print('Error calculating route: $e');
      if (mounted) {
        setState(() {
          _isCalculatingRoute = false;
        });
      }
    }
  }

  void _swapLocations() {
    setState(() {
      final tempPoint = _startPoint;
      final tempText = _startController.text;
      
      _startPoint = _endPoint;
      _startController.text = _endController.text;
      
      _endPoint = tempPoint;
      _endController.text = tempText;
    });

    if (_startPoint != null && _endPoint != null) {
      _calculateRoute();
    }
  }

  void _clearRoute() {
    setState(() {
      _endPoint = null;
      _endController.clear();
      _routePoints = [];
      _routeDistance = null;
      _routeDuration = null;
      _showEndSuggestions = false;
    });
  }

  Future<void> _onMapTap(LatLng point) async {
    // If start point is not set, set it
    if (_startPoint == null) {
      setState(() {
        _startPoint = point;
      });
      
      // Get address for the point
      try {
        final placemarks = await placemarkFromCoordinates(point.latitude, point.longitude);
        if (placemarks.isNotEmpty && mounted) {
          final place = placemarks.first;
          _startController.text = '${place.street ?? place.locality ?? 'Selected location'}';
        } else {
          _startController.text = 'Lat: ${point.latitude.toStringAsFixed(4)}, Lng: ${point.longitude.toStringAsFixed(4)}';
        }
      } catch (e) {
        _startController.text = 'Lat: ${point.latitude.toStringAsFixed(4)}, Lng: ${point.longitude.toStringAsFixed(4)}';
      }
      
      _mapController.move(point, 14.0);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Start point set! Tap again for destination'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }
    } 
    // If start is set but end is not, set end point
    else if (_endPoint == null) {
      setState(() {
        _endPoint = point;
      });
      
      // Get address for the point
      try {
        final placemarks = await placemarkFromCoordinates(point.latitude, point.longitude);
        if (placemarks.isNotEmpty && mounted) {
          final place = placemarks.first;
          _endController.text = '${place.street ?? place.locality ?? 'Selected location'}';
        } else {
          _endController.text = 'Lat: ${point.latitude.toStringAsFixed(4)}, Lng: ${point.longitude.toStringAsFixed(4)}';
        }
      } catch (e) {
        _endController.text = 'Lat: ${point.latitude.toStringAsFixed(4)}, Lng: ${point.longitude.toStringAsFixed(4)}';
      }
      
      // Calculate route
      await _calculateRoute();
    }
    // Both points are set, reset and start over
    else {
      setState(() {
        _startPoint = point;
        _endPoint = null;
        _routePoints = [];
        _routeDistance = null;
        _routeDuration = null;
      });
      
      try {
        final placemarks = await placemarkFromCoordinates(point.latitude, point.longitude);
        if (placemarks.isNotEmpty && mounted) {
          final place = placemarks.first;
          _startController.text = '${place.street ?? place.locality ?? 'Selected location'}';
        } else {
          _startController.text = 'Lat: ${point.latitude.toStringAsFixed(4)}, Lng: ${point.longitude.toStringAsFixed(4)}';
        }
      } catch (e) {
        _startController.text = 'Lat: ${point.latitude.toStringAsFixed(4)}, Lng: ${point.longitude.toStringAsFixed(4)}';
      }
      
      _endController.clear();
      _mapController.move(point, 14.0);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Start point updated! Tap again for destination'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)} m';
    } else {
      return '${(meters / 1000).toStringAsFixed(2)} km';
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Plan Route',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Stack(
        children: [
          // Map
          MapWidget(
            initialCenter: _startPoint ?? const LatLng(14.5995, 120.9842),
            initialZoom: 13.0,
            mapController: _mapController,
            onTap: _onMapTap,
            markers: [
              if (_startPoint != null)
                Marker(
                  point: _startPoint!,
                  width: 40,
                  height: 40,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              if (_endPoint != null)
                Marker(
                  point: _endPoint!,
                  width: 40,
                  height: 40,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
            ],
            polylines: _routePoints.isNotEmpty
                ? [
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 4.0,
                      color: AppColors.primaryOrange,
                    ),
                  ]
                : [],
          ),

          // Search Panel
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Instructions Banner
                      if (_startPoint == null || _endPoint == null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primaryOrange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.primaryOrange.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.touch_app,
                                color: AppColors.primaryOrange,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _startPoint == null
                                      ? 'Tap on the map to set start point, or type an address'
                                      : 'Tap on the map to set destination',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                      // Start Location Search
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _startController,
                              decoration: InputDecoration(
                                hintText: 'Start location',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: AppColors.backgroundGrey,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                suffixIcon: _startController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear, size: 20),
                                        onPressed: () {
                                          _startController.clear();
                                          setState(() {
                                            _startPoint = null;
                                            _showStartSuggestions = false;
                                            _routePoints = [];
                                          });
                                        },
                                      )
                                    : IconButton(
                                        icon: const Icon(Icons.my_location, size: 20),
                                        onPressed: _getCurrentLocation,
                                      ),
                              ),
                              onChanged: (value) => _searchLocation(value, true),
                              onTap: () {
                                if (_startSuggestions.isNotEmpty) {
                                  setState(() {
                                    _showStartSuggestions = true;
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Swap Button
                      if (_startPoint != null || _endPoint != null)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 24.0),
                            child: IconButton(
                              icon: const Icon(Icons.swap_vert, color: AppColors.textSecondary),
                              onPressed: _swapLocations,
                              iconSize: 20,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ),
                        ),

                      if (_startPoint != null || _endPoint != null)
                        const SizedBox(height: 8),

                      // End Location Search
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _endController,
                              decoration: InputDecoration(
                                hintText: 'Destination',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: AppColors.backgroundGrey,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                suffixIcon: _endController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear, size: 20),
                                        onPressed: _clearRoute,
                                      )
                                    : null,
                              ),
                              onChanged: (value) => _searchLocation(value, false),
                              onTap: () {
                                if (_endSuggestions.isNotEmpty) {
                                  setState(() {
                                    _showEndSuggestions = true;
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),

                      // Route Info
                      if (_routeDistance != null && _routeDuration != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12.0),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.primaryOrange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Column(
                                  children: [
                                    const Icon(Icons.straighten, 
                                      color: AppColors.primaryOrange, size: 20),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatDistance(_routeDistance!),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const Text(
                                      'Distance',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  children: [
                                    const Icon(Icons.access_time, 
                                      color: AppColors.primaryOrange, size: 20),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatDuration(_routeDuration!),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const Text(
                                      'Duration',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Start Location Suggestions
          if (_showStartSuggestions && _startSuggestions.isNotEmpty)
            Positioned(
              top: 140,
              left: 16,
              right: 16,
              child: Container(
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _startSuggestions.length > 5 ? 5 : _startSuggestions.length,
                  itemBuilder: (context, index) {
                    final location = _startSuggestions[index];
                    return ListTile(
                      leading: const Icon(Icons.location_on, color: Colors.green),
                      title: Text('${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}'),
                      onTap: () => _selectLocation(location, true),
                    );
                  },
                ),
              ),
            ),

          // End Location Suggestions
          if (_showEndSuggestions && _endSuggestions.isNotEmpty)
            Positioned(
              top: _startPoint != null ? 230 : 140,
              left: 16,
              right: 16,
              child: Container(
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _endSuggestions.length > 5 ? 5 : _endSuggestions.length,
                  itemBuilder: (context, index) {
                    final location = _endSuggestions[index];
                    return ListTile(
                      leading: const Icon(Icons.location_on, color: Colors.red),
                      title: Text('${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}'),
                      onTap: () => _selectLocation(location, false),
                    );
                  },
                ),
              ),
            ),

          // Loading Indicator
          if (_isCalculatingRoute)
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: AppColors.primaryOrange),
                      SizedBox(width: 16),
                      Text('Calculating route...'),
                    ],
                  ),
                ),
              ),
            ),

          // Start Ride Button
          if (_routePoints.length >= 2)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Start ride with planned route
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryOrange,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Start Ride',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
