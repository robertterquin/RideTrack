/// Calorie Calculator Utility
/// Calculates calories burned during cycling based on MET (Metabolic Equivalent of Task) formula
/// 
/// Formula: Calories = MET × 3.5 × weight(kg) × duration(min) / 200
/// 
/// MET values based on average cycling speed:
/// - < 13 km/h: Leisure cycling (MET = 4.0)
/// - 13-16 km/h: Light cycling (MET = 6.0)
/// - 16-20 km/h: Moderate cycling (MET = 8.0)
/// - 20-22 km/h: Vigorous cycling (MET = 10.0)
/// - 22-25 km/h: Fast cycling (MET = 12.0)
/// - 25+ km/h: Racing cycling (MET = 16.0)

class CalorieCalculator {
  /// Calculate calories burned during a cycling session
  /// 
  /// [weightKg] - User's weight in kilograms
  /// [avgSpeedKmh] - Average speed during the ride in km/h
  /// [durationMinutes] - Duration of the ride in minutes
  /// 
  /// Returns: Calories burned (kcal)
  static double calculateCalories({
    required double weightKg,
    required double avgSpeedKmh,
    required double durationMinutes,
  }) {
    final met = _getMET(avgSpeedKmh);
    return (met * 3.5 * weightKg * durationMinutes) / 200;
  }

  /// Calculate calories from duration in seconds
  static double calculateCaloriesFromSeconds({
    required double weightKg,
    required double avgSpeedKmh,
    required int durationSeconds,
  }) {
    final durationMinutes = durationSeconds / 60.0;
    return calculateCalories(
      weightKg: weightKg,
      avgSpeedKmh: avgSpeedKmh,
      durationMinutes: durationMinutes,
    );
  }

  /// Get MET value based on average speed
  static double _getMET(double avgSpeedKmh) {
    if (avgSpeedKmh < 13) {
      return 4.0; // Leisure
    } else if (avgSpeedKmh < 16) {
      return 6.0; // Light
    } else if (avgSpeedKmh < 20) {
      return 8.0; // Moderate
    } else if (avgSpeedKmh < 22) {
      return 10.0; // Vigorous
    } else if (avgSpeedKmh < 25) {
      return 12.0; // Fast
    } else {
      return 16.0; // Racing
    }
  }

  /// Get cycling intensity description based on speed
  static String getIntensity(double avgSpeedKmh) {
    if (avgSpeedKmh < 13) {
      return 'Leisure';
    } else if (avgSpeedKmh < 16) {
      return 'Light';
    } else if (avgSpeedKmh < 20) {
      return 'Moderate';
    } else if (avgSpeedKmh < 22) {
      return 'Vigorous';
    } else if (avgSpeedKmh < 25) {
      return 'Fast';
    } else {
      return 'Racing';
    }
  }

  /// Estimate calories for a distance if no weight is available (rough estimate)
  /// Uses average weight of 70kg and moderate intensity
  static double estimateCaloriesFromDistance(double distanceKm) {
    // Rough estimate: ~50 kcal per km at moderate intensity
    return distanceKm * 50;
  }
}
