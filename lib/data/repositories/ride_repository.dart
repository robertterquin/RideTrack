import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bikeapp/data/models/ride.dart';

/// Repository for managing ride data in Firestore
class RideRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get current user ID
  String? get _currentUserId => _auth.currentUser?.uid;

  /// Save a new ride to Firestore
  /// Returns the ride ID on success
  Future<String> saveRide(Ride ride) async {
    if (_currentUserId == null) {
      throw Exception('No user is currently logged in');
    }

    try {
      print('💾 Saving ride to Firestore...');
      
      // Add ride to rides collection
      final docRef = await _firestore
          .collection('rides')
          .add(ride.toFirestore())
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Save ride timed out');
            },
          );

      print('✅ Ride saved with ID: ${docRef.id}');

      // Update user stats
      await _updateUserStats(
        userId: _currentUserId!,
        distance: ride.distance,
        duration: ride.duration,
      );

      return docRef.id;
    } catch (e) {
      print('❌ Error saving ride: $e');
      rethrow;
    }
  }

  /// Get all rides for the current user
  Future<List<Ride>> getRides({int? limit}) async {
    if (_currentUserId == null) {
      print('⚠️ No user is currently logged in');
      return [];
    }

    try {
      print('📥 Fetching rides from Firestore for user: $_currentUserId');
      
      // Fetch without ordering first (no index required)
      final snapshot = await _firestore
          .collection('rides')
          .where('userId', isEqualTo: _currentUserId)
          .get()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Fetch rides timed out');
            },
          );

      print('📊 Found ${snapshot.docs.length} total rides in Firestore');

      if (snapshot.docs.isEmpty) {
        print('⚠️ No rides found for this user');
        return [];
      }

      // Parse rides and sort in memory
      final rides = snapshot.docs.map((doc) {
        print('📄 Processing ride: ${doc.id}, data: ${doc.data()}');
        return Ride.fromFirestore(doc);
      }).toList();

      // Sort by createdAt in memory (newest first)
      rides.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Apply limit if specified
      final result = limit != null && limit < rides.length
          ? rides.sublist(0, limit)
          : rides;
      
      print('✅ Returning ${result.length} rides');
      return result;
    } catch (e, stackTrace) {
      print('❌ Error fetching rides: $e');
      print('Stack trace: $stackTrace');
      return []; // Return empty list on error
    }
  }

  /// Get recent rides (last 3)
  Future<List<Ride>> getRecentRides() async {
    return getRides(limit: 3);
  }

  /// Get a single ride by ID
  Future<Ride?> getRideById(String rideId) async {
    try {
      final doc = await _firestore
          .collection('rides')
          .doc(rideId)
          .get()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Fetch ride timed out');
            },
          );

      if (doc.exists) {
        return Ride.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('❌ Error fetching ride: $e');
      return null;
    }
  }

  /// Update ride details (name, notes, etc.)
  Future<void> updateRide(String rideId, Map<String, dynamic> updates) async {
    try {
      await _firestore
          .collection('rides')
          .doc(rideId)
          .update(updates)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Update ride timed out');
            },
          );
      
      print('✅ Ride updated successfully');
    } catch (e) {
      print('❌ Error updating ride: $e');
      rethrow;
    }
  }

  /// Delete a ride
  Future<void> deleteRide(String rideId) async {
    try {
      // First, get the ride data to decrement user stats
      final rideDoc = await _firestore
          .collection('rides')
          .doc(rideId)
          .get();
      
      if (rideDoc.exists && _currentUserId != null) {
        final ride = Ride.fromFirestore(rideDoc);
        
        // Decrement user stats before deleting
        await _decrementUserStats(
          userId: _currentUserId!,
          distance: ride.distance,
          duration: ride.duration,
        );
      }
      
      // Now delete the ride
      await _firestore
          .collection('rides')
          .doc(rideId)
          .delete()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Delete ride timed out');
            },
          );
      
      print('✅ Ride deleted successfully and stats updated');
    } catch (e) {
      print('❌ Error deleting ride: $e');
      rethrow;
    }
  }

  /// Stream of rides for real-time updates
  Stream<List<Ride>> getRidesStream() {
    if (_currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('rides')
        .where('userId', isEqualTo: _currentUserId)
        .orderBy('startTime', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => Ride.fromFirestore(doc)).toList();
        });
  }

  /// Update user statistics after saving a ride
  Future<void> _updateUserStats({
    required String userId,
    required double distance,
    required int duration,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'totalRides': FieldValue.increment(1),
        'totalDistance': FieldValue.increment(distance),
        'totalTime': FieldValue.increment(duration),
      }).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print('⚠️ Update user stats timed out');
        },
      );
      
      print('✅ User stats updated');
    } catch (e) {
      print('⚠️ Warning: Could not update user stats: $e');
      // Don't fail the ride save if stats update fails
    }
  }

  /// Decrement user statistics after deleting a ride
  Future<void> _decrementUserStats({
    required String userId,
    required double distance,
    required int duration,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'totalRides': FieldValue.increment(-1),
        'totalDistance': FieldValue.increment(-distance),
        'totalTime': FieldValue.increment(-duration),
      }).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print('⚠️ Decrement user stats timed out');
        },
      );
      
      print('✅ User stats decremented');
    } catch (e) {
      print('⚠️ Warning: Could not decrement user stats: $e');
      // Don't fail the ride deletion if stats update fails
    }
  }

  /// Get user statistics
  Future<Map<String, dynamic>?> getUserStats() async {
    if (_currentUserId == null) {
      return null;
    }

    try {
      final doc = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .get()
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              throw Exception('Fetch user stats timed out');
            },
          );

      if (doc.exists) {
        final data = doc.data()!;
        return {
          'totalRides': data['totalRides'] ?? 0,
          'totalDistance': (data['totalDistance'] ?? 0).toDouble(),
          'totalTime': data['totalTime'] ?? 0,
        };
      }
      return null;
    } catch (e) {
      print('❌ Error fetching user stats: $e');
      return null;
    }
  }
}
