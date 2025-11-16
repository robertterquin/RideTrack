import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

/// Ride Model
/// Represents a single bike ride with GPS tracking data
class Ride {
  final String id;
  final String userId;
  final String name;
  final String type; // 'Commute' or 'Recreation'
  final double distance; // in meters
  final int duration; // in seconds
  final double averageSpeed; // in km/h
  final DateTime startTime;
  final DateTime endTime;
  final List<LatLng> actualRoute; // GPS path taken
  final List<LatLng>? plannedRoute; // Optional planned route
  final LatLng? startLocation;
  final LatLng? endLocation;
  final String? notes;
  final double? calories; // Calories burned during the ride (kcal)
  final DateTime createdAt;

  Ride({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.distance,
    required this.duration,
    required this.averageSpeed,
    required this.startTime,
    required this.endTime,
    required this.actualRoute,
    this.plannedRoute,
    this.startLocation,
    this.endLocation,
    this.notes,
    this.calories,
    required this.createdAt,
  });

  /// Create Ride from Firestore document
  factory Ride.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return Ride(
      id: doc.id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? 'Untitled Ride',
      type: data['type'] ?? 'Recreation',
      distance: (data['distance'] ?? 0).toDouble(),
      duration: data['duration'] ?? 0,
      averageSpeed: (data['averageSpeed'] ?? 0).toDouble(),
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      actualRoute: _parseRoute(data['actualRoute']),
      plannedRoute: data['plannedRoute'] != null ? _parseRoute(data['plannedRoute']) : null,
      startLocation: data['startLocation'] != null
          ? LatLng(
              data['startLocation']['latitude'],
              data['startLocation']['longitude'],
            )
          : null,
      endLocation: data['endLocation'] != null
          ? LatLng(
              data['endLocation']['latitude'],
              data['endLocation']['longitude'],
            )
          : null,
      notes: data['notes'],
      calories: data['calories'] != null ? (data['calories'] as num).toDouble() : null,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  /// Convert Ride to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'name': name,
      'type': type,
      'distance': distance,
      'duration': duration,
      'averageSpeed': averageSpeed,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'actualRoute': _routeToList(actualRoute),
      'plannedRoute': plannedRoute != null ? _routeToList(plannedRoute!) : null,
      'startLocation': startLocation != null
          ? {
              'latitude': startLocation!.latitude,
              'longitude': startLocation!.longitude,
            }
          : null,
      'endLocation': endLocation != null
          ? {
              'latitude': endLocation!.latitude,
              'longitude': endLocation!.longitude,
            }
          : null,
      'notes': notes,
      'calories': calories,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Parse route from Firestore list
  static List<LatLng> _parseRoute(dynamic routeData) {
    if (routeData == null) return [];
    
    final List<dynamic> routeList = routeData as List<dynamic>;
    return routeList.map((point) {
      return LatLng(
        point['latitude'] as double,
        point['longitude'] as double,
      );
    }).toList();
  }

  /// Convert route to Firestore list
  static List<Map<String, double>> _routeToList(List<LatLng> route) {
    return route.map((point) {
      return {
        'latitude': point.latitude,
        'longitude': point.longitude,
      };
    }).toList();
  }

  /// Copy with method for creating modified copies
  Ride copyWith({
    String? id,
    String? userId,
    String? name,
    String? type,
    double? distance,
    int? duration,
    double? averageSpeed,
    DateTime? startTime,
    DateTime? endTime,
    List<LatLng>? actualRoute,
    List<LatLng>? plannedRoute,
    LatLng? startLocation,
    LatLng? endLocation,
    String? notes,
    double? calories,
    DateTime? createdAt,
  }) {
    return Ride(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      type: type ?? this.type,
      distance: distance ?? this.distance,
      duration: duration ?? this.duration,
      averageSpeed: averageSpeed ?? this.averageSpeed,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      actualRoute: actualRoute ?? this.actualRoute,
      plannedRoute: plannedRoute ?? this.plannedRoute,
      startLocation: startLocation ?? this.startLocation,
      endLocation: endLocation ?? this.endLocation,
      notes: notes ?? this.notes,
      calories: calories ?? this.calories,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
