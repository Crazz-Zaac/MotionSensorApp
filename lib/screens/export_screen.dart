import 'package:flutter/material.dart';
// Remove unused import: import 'dart:io';

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  final List<RecordingItem> _recordings = [ // Added 'final' here
    RecordingItem(
      name: 'Recording_2024_01_15_10_30',
      size: '2.5 MB',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      filePath: '/storage/emulated/0/MotionSensor/Recording_2024_01_15_10_30.csv',
    ),
    RecordingItem(
      name: 'Recording_2024_01_15_09_15',
      size: '1.8 MB',
      timestamp: DateTime.now().subtract(const Duration(hours: 5)),
      filePath: '/storage/emulated/0/MotionSensor/Recording_2024_01_15_09_15.csv',
    ),
    RecordingItem(
      name: 'Recording_2024_01_14_16_45',
      size: '3.2 MB',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      filePath: '/storage/emulated/0/MotionSensor/Recording_2024_01_14_16_45.csv',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recordings'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshRecordings,
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
                    'Storage Summary',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text('Total Recordings: ${_recordings.length}'),
                  Text('Total Size: ${_getTotalSize()}'),
                  const Text('Storage Path: /storage/emulated/0/MotionSensor/'),
                ],
              ),
            ),
          ),
          
          // Recordings list
          Expanded(
            child: _recordings.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.folder_open, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No recordings found'),
                        Text('Start recording to create files'),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: _recordings.length,
                    itemBuilder: (context, index) {
                      final recording = _recordings[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8.0),
                        child: ListTile(
                          leading: const Icon(Icons.insert_chart, size: 40),
                          title: Text(recording.name),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Size: ${recording.size}'),
                              Text('Date: ${_formatDateTime(recording.timestamp)}'),
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) => _handleMenuAction(value, recording, index),
                            itemBuilder: (BuildContext context) => [
                              const PopupMenuItem(
                                value: 'preview',
                                child: ListTile(
                                  leading: Icon(Icons.visibility),
                                  title: Text('Preview'),
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'share',
                                child: ListTile(
                                  leading: Icon(Icons.share),
                                  title: Text('Share'),
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'export',
                                child: ListTile(
                                  leading: Icon(Icons.file_download),
                                  title: Text('Export'),
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: ListTile(
                                  leading: Icon(Icons.delete, color: Colors.red),
                                  title: Text('Delete', style: TextStyle(color: Colors.red)),
                                ),
                              ),
                            ],
                          ),
                          onTap: () => _previewRecording(recording),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _getTotalSize() {
    // Calculate total size from all recordings
    double totalMB = 0;
    for (var recording in _recordings) {
      String sizeStr = recording.size.replaceAll(' MB', '');
      totalMB += double.tryParse(sizeStr) ?? 0;
    }
    return '${totalMB.toStringAsFixed(1)} MB';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _refreshRecordings() {
    // TODO: Implement actual file system scanning
    setState(() {
      // Simulate refresh
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Recordings refreshed')),
    );
  }

  void _handleMenuAction(String action, RecordingItem recording, int index) {
    switch (action) {
      case 'preview':
        _previewRecording(recording);
        break;
      case 'share':
        _shareRecording(recording);
        break;
      case 'export':
        _exportRecording(recording);
        break;
      case 'delete':
        _deleteRecording(recording, index);
        break;
    }
  }

  void _previewRecording(RecordingItem recording) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Preview: ${recording.name}'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('File: ${recording.name}.csv'),
                Text('Size: ${recording.size}'),
                Text('Created: ${_formatDateTime(recording.timestamp)}'),
                Text('Path: ${recording.filePath}'),
                const SizedBox(height: 16),
                const Text('Sample Data:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const SingleChildScrollView(
                      child: Text(
                        'timestamp,accelerometer_x,accelerometer_y,accelerometer_z,gyroscope_x,gyroscope_y,gyroscope_z,activity\n'
                        '2024-01-15T10:30:00.123Z,0.123,-9.456,0.789,0.012,-0.034,0.056,Walk\n'
                        '2024-01-15T10:30:00.143Z,0.145,-9.423,0.812,0.015,-0.031,0.052,Walk\n'
                        '2024-01-15T10:30:00.163Z,0.167,-9.389,0.834,0.018,-0.028,0.048,Walk\n'
                        '...',
                        style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _shareRecording(RecordingItem recording) {
    // TODO: Implement actual sharing functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Sharing ${recording.name}...')),
    );
  }

  void _exportRecording(RecordingItem recording) {
    // TODO: Implement actual export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Exporting ${recording.name}...')),
    );
  }

  void _deleteRecording(RecordingItem recording, int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Recording'),
          content: Text('Are you sure you want to delete "${recording.name}"?\n\nThis action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _recordings.removeAt(index);
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${recording.name} deleted')),
                );
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}

class RecordingItem {
  final String name;
  final String size;
  final DateTime timestamp;
  final String filePath;

  const RecordingItem({ // Added 'const' constructor
    required this.name,
    required this.size,
    required this.timestamp,
    required this.filePath,
  });
}