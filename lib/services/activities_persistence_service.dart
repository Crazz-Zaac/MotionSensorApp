import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:motion_sensor_app/screens/activities_screen.dart';

class ActivitiesPersistenceService {
  static const String _activitiesKey = 'saved_activities';
  
  /// Save activities to persistent storage
  static Future<void> saveActivities(List<ActivityItem> activities) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final activitiesJson = activities.map((activity) => {
        'id': activity.id,
        'name': activity.name,
        'duration': activity.duration,
      }).toList();
      
      final jsonString = jsonEncode(activitiesJson);
      await prefs.setString(_activitiesKey, jsonString);
      
      // print('Saved ${activities.length} activities to persistent storage');
    } catch (e) {
      // print('Error saving activities: $e');
      rethrow;
    }
  }
  
  /// Load activities from persistent storage
  static Future<List<ActivityItem>> loadActivities() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_activitiesKey);
      
      if (jsonString == null || jsonString.isEmpty) {
        // print('No saved activities found');
        return [];
      }
      
      final activitiesJson = jsonDecode(jsonString) as List<dynamic>;
      final activities = activitiesJson.map((json) => ActivityItem(
        id: json['id'] as String,
        name: json['name'] as String,
        duration: json['duration'] as int,
      )).toList();
      
      // print('Loaded ${activities.length} activities from persistent storage');
      return activities;
    } catch (e) {
      // print('Error loading activities: $e');
      return [];
    }
  }
  
  /// Clear all saved activities
  static Future<void> clearActivities() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_activitiesKey);
      // print('Cleared all saved activities');
    } catch (e) {
      // print('Error clearing activities: $e');
      rethrow;
    }
  }
  
  /// Check if activities are saved
  static Future<bool> hasActivities() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_activitiesKey);
      return jsonString != null && jsonString.isNotEmpty;
    } catch (e) {
      // print('Error checking for activities: $e');
      return false;
    }
  }
}