import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ActivitiesScreen extends StatefulWidget {
  const ActivitiesScreen({super.key});

  @override
  State<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen> {
  List<ActivityItem> _activities = [
    ActivityItem(name: 'Walk', duration: 10),
    ActivityItem(name: 'Sit', duration: 10),
    ActivityItem(name: 'Jump', duration: 10),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity Sequence'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addActivity,
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary card
          Card(
            margin: const EdgeInsets.all(16.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sequence Summary',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text('Total Activities: ${_activities.length}'),
                  Text('Total Duration: ${_getTotalDuration()} seconds'),
                  Text('Estimated Time: ${_formatDuration(_getTotalDuration())}'),
                ],
              ),
            ),
          ),
          
          // Activities list
          Expanded(
            child: _activities.isEmpty
                ? const Center(
                    child: Text('No activities added. Tap + to add an activity.'),
                  )
                : ReorderableListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: _activities.length,
                    onReorder: _reorderActivities,
                    itemBuilder: (context, index) {
                      final activity = _activities[index];
                      return Card(
                        key: ValueKey(activity.id),
                        margin: const EdgeInsets.only(bottom: 8.0),
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text('${index + 1}'),
                          ),
                          title: Text(activity.name),
                          subtitle: Text('${activity.duration} seconds'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _editActivity(index),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => _deleteActivity(index),
                              ),
                              const Icon(Icons.drag_handle),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addActivity,
        child: const Icon(Icons.add),
      ),
    );
  }

  int _getTotalDuration() {
    return _activities.fold(0, (sum, activity) => sum + activity.duration);
  }

  String _formatDuration(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes}m ${remainingSeconds}s';
  }

  void _reorderActivities(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final ActivityItem item = _activities.removeAt(oldIndex);
      _activities.insert(newIndex, item);
    });
  }

  void _addActivity() {
    _showActivityDialog();
  }

  void _editActivity(int index) {
    _showActivityDialog(activity: _activities[index], index: index);
  }

  void _deleteActivity(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Activity'),
          content: Text('Are you sure you want to delete "${_activities[index].name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _activities.removeAt(index);
                });
                Navigator.of(context).pop();
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _showActivityDialog({ActivityItem? activity, int? index}) {
    final nameController = TextEditingController(text: activity?.name ?? '');
    final durationController = TextEditingController(
      text: activity?.duration.toString() ?? '10',
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(activity == null ? 'Add Activity' : 'Edit Activity'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Activity Name',
                  hintText: 'e.g., Walk, Run, Sit',
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: durationController,
                decoration: const InputDecoration(
                  labelText: 'Duration (seconds)',
                  hintText: '10',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final name = nameController.text.trim();
                final duration = int.tryParse(durationController.text) ?? 10;

                if (name.isNotEmpty && duration > 0) {
                  setState(() {
                    if (activity == null) {
                      // Add new activity
                      _activities.add(ActivityItem(name: name, duration: duration));
                    } else {
                      // Edit existing activity
                      _activities[index!] = ActivityItem(
                        id: activity.id,
                        name: name,
                        duration: duration,
                      );
                    }
                  });
                  Navigator.of(context).pop();
                } else {
                  // Show error
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid name and duration'),
                    ),
                  );
                }
              },
              child: Text(activity == null ? 'Add' : 'Save'),
            ),
          ],
        );
      },
    );
  }
}

class ActivityItem {
  final String id;
  final String name;
  final int duration;

  ActivityItem({
    String? id,
    required this.name,
    required this.duration,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  @override
  String toString() {
    return 'ActivityItem(id: $id, name: $name, duration: $duration)';
  }
}

