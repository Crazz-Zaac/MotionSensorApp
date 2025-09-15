import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:motion_sensor_app/services/activities_persistence_service.dart';

class ActivitiesScreen extends StatefulWidget {
  final List<ActivityItem> initialActivities; 

  const ActivitiesScreen({super.key, required this.initialActivities});

  @override
  State<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen> {
  List<ActivityItem> _activities = [];
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    _activities = List.from(widget.initialActivities);
  }

  Future<void> _saveActivities() async {
    try {
      await ActivitiesPersistenceService.saveActivities(_activities);
      setState(() {
        _hasUnsavedChanges = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Activities saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving activities: $e')),
        );
      }
    }
  }

  void _markAsChanged() {
    if (!_hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = true;
      });
    }
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
      _markAsChanged();
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
                  _markAsChanged();
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
                      // Edit existing activity using copyWith
                      _activities[index!] = activity.copyWith(
                        name: name,
                        duration: duration,
                      );
                    }
                    _markAsChanged();
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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
       onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return;
        
        if (_hasUnsavedChanges) {
          await _saveActivities();
        }
        if (!context.mounted) return;
        Navigator.pop(context, _activities);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Activity Sequence'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          actions: [
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: () async {
                await _saveActivities();
                if (!context.mounted) return;
                Navigator.pop(context, _activities);
              },
            ),
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
      ),
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

  // Add copyWith method for easy updates
  ActivityItem copyWith({
    String? name,
    int? duration,
  }) {
    return ActivityItem(
      id: id, // Keep the same ID
      name: name ?? this.name,
      duration: duration ?? this.duration,
    );
  }

  // Override equality operators
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ActivityItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ActivityItem(id: $id, name: $name, duration: $duration)';
  }
}