// lib/data/services/milestone_service.dart

import 'package:shared_preferences/shared_preferences.dart';

/// Service that decides which community milestone celebration to show.
///
/// Each milestone is shown once per device: after the user dismisses it,
/// the id is persisted in [SharedPreferences] and never shown again.
class MilestoneService {
  /// Triggered when the community reaches 500 ship ratings.
  static const String milestone500Ratings = 'milestone_500_ratings';

  /// Triggered when the community reaches 100 registered users.
  static const String milestone100Users = 'milestone_100_users';

  static const String _prefsKeyPrefix = 'milestone_seen_';

  /// Returns the first unseen milestone that qualifies for the given stats,
  /// or `null` when there is nothing to celebrate.
  ///
  /// Only one milestone is returned at a time; 500 ratings has priority.
  Future<String?> checkMilestones(int totalRatings, int totalUsers) async {
    if (totalRatings >= 500 && !await hasSeen(milestone500Ratings)) {
      return milestone500Ratings;
    }
    if (totalUsers >= 100 && !await hasSeen(milestone100Users)) {
      return milestone100Users;
    }
    return null;
  }

  /// Marks the milestone as seen so it never shows again on this device.
  Future<void> dismissMilestone(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_prefsKeyPrefix$id', true);
  }

  /// Whether the milestone was already shown and dismissed.
  Future<bool> hasSeen(String id) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_prefsKeyPrefix$id') ?? false;
  }
}
