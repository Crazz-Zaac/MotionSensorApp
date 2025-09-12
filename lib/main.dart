import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/activities_screen.dart';
import 'screens/export_screen.dart';
import 'screens/settings_screen.dart';

void main() {
  runApp(const MotionSensorApp());
}

class MotionSensorApp extends StatelessWidget {
  const MotionSensorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Motion Sensor Recorder',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  // Centralized activities list that we can pass to HomeScreen.
  // Use the concrete type your HomeScreen expects (ActivityItem).
  // Note: activities can be loaded from disk or a DB in initState if needed.
  List<ActivityItem> _activities = <ActivityItem>[];

  // Builds the currently selected screen, passing activities to HomeScreen.
  Widget _currentScreen() {
    switch (_selectedIndex) {
      case 0:
        // pass activities here — HomeScreen expects this required parameter
        return HomeScreen(activities: _activities);
      case 1:
        return ActivitiesScreen(initialActivities: _activities);
      case 2:
        return const ExportScreen();
      case 3:
      default:
        return const SettingsScreen();
    }
  }

  void _onItemTapped(int index) {
    // If navigating to ActivitiesScreen, wait for result
    if (index == 1) {
      _navigateToActivitiesScreen();
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  Future<void> _navigateToActivitiesScreen() async {
    // Navigate to ActivitiesScreen and wait for result
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActivitiesScreen(initialActivities: _activities),
      ),
    );

    // Update activities if we got a result
    if (result != null && result is List<ActivityItem>) {
      setState(() {
        _activities = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _currentScreen(),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Activities',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.folder),
            label: 'Export',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        onTap: _onItemTapped,
      ),
    );
  }
}
