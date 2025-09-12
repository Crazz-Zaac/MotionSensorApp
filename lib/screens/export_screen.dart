import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  List<RecordingItem> _recordings = [];
  String _storagePath = '';

  @override
  void initState() {
    super.initState();
    _initializeStorage();
  }

  Future<void> _initializeStorage() async {
    try {
      // Use Documents directory consistently with recording
      final Directory? documentsDir = await getExternalStorageDirectory();
      
      if (documentsDir == null) {
        setState(() {
          _storagePath = 'Error: Cannot access external storage';
        });
        return;
      }

      final motionSensorDir = Directory('${documentsDir.path}/Motion Sensor App/files');
      
      if (!await motionSensorDir.exists()) {
        await motionSensorDir.create(recursive: true);
      }
      
      setState(() {
        _storagePath = motionSensorDir.path;
      });
      
      // Debug: Print the actual path
      debugPrint('Export screen storage path: $_storagePath');
      
      _refreshRecordings();
    } catch (e) {
      debugPrint('Error initializing storage: $e');
      setState(() {
        _storagePath = 'Error: $e';
      });
    }
  }

  String get _displayPath {
    if (_storagePath.isEmpty) return 'Loading...';
    
    // Show user-friendly path
    if (_storagePath.contains('/Motion Sensor App/files')) {
      return 'Documents/Motion Sensor App/files/';
    }
    
    return _storagePath;
  }


  Future<void> _refreshRecordings() async {
  if (_storagePath.isEmpty) return;

  try {
    final dir = Directory(_storagePath);
    if (!await dir.exists()) {
      debugPrint('Directory does not exist: $_storagePath');
      setState(() {
        _recordings = [];
      });
      return;
    }

    final files = await dir.list().toList();
    final csvFiles = files.where((entity) => 
      entity is File && entity.path.toLowerCase().endsWith('.csv')
    ).cast<File>().toList();
    
    debugPrint('Found ${csvFiles.length} CSV files in $_storagePath');
    
    final List<RecordingItem> recordings = [];
    
    for (var file in csvFiles) {
      try {
        final stat = await file.stat();
        final fileName = file.uri.pathSegments.last.replaceAll('.csv', '');
        
        recordings.add(RecordingItem(
          name: fileName,
          size: '${(stat.size / (1024 * 1024)).toStringAsFixed(1)} MB',
          timestamp: stat.modified,
          filePath: file.path,
        ));
        
        debugPrint('Added recording: $fileName (${stat.size} bytes)');
      } catch (e) {
        debugPrint('Error processing file ${file.path}: $e');
      }
    }
    
    // Sort by timestamp (newest first)
    recordings.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    setState(() {
      _recordings = recordings;
    });
    
    debugPrint('Loaded ${recordings.length} recordings');
  } catch (e) {
    debugPrint('Error refreshing recordings: $e');
    setState(() {
      _recordings = [];
    });
  }
}

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
          IconButton(
            icon: const Icon(Icons.info),
            onPressed: _showPathInfo,
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
                  Text('Storage Path: $_storagePath'),
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

  void _showPathInfo() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Storage Information'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Full Path:', style: TextStyle(fontWeight: FontWeight.bold)),
              SelectableText(_storagePath),
              const SizedBox(height: 16),
              const Text('Display Path:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(_displayPath),
              const SizedBox(height: 16),
              Text('Directory exists: ${_storagePath.isNotEmpty ? Directory(_storagePath).existsSync() : false}'),
              Text('Platform: ${Platform.operatingSystem}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  String _getTotalSize() {
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

  Future<void> _previewRecording(RecordingItem recording) async {
    try {
      final file = File(recording.filePath);
      final content = await file.readAsString();

      if (!mounted) return;
      
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
                      child: SingleChildScrollView(
                        child: Text(
                          content.length > 500 ? '${content.substring(0, 500)}...' : content,
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
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
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error reading file: $e')),
      );
    }
  }

  Future<void> _shareRecording(RecordingItem recording) async {
    try {
      final file = File(recording.filePath);
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Motion sensor recording - ${recording.name}',
        subject: 'Motion Sensor Data',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sharing file: $e')),
      );
    }
  }

  Future<void> _exportRecording(RecordingItem recording) async {
    try {
      final sourceFile = File(recording.filePath);
      
      // Get Downloads directory for easy access
      final Directory? downloadsDir = await getDownloadsDirectory();
      if (downloadsDir == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot access downloads directory')),
        );
        return;
      }
      
      final destinationFile = File('${downloadsDir.path}/${recording.name}.csv');
      await sourceFile.copy(destinationFile.path);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exported to Downloads/${recording.name}.csv')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error exporting file: $e')),
      );
    }
  }

  Future<void> _deleteRecording(RecordingItem recording, int index) async {
    try {
      final file = File(recording.filePath);
      if (await file.exists()) {
        await file.delete();

        if (!mounted) return; // <- Guard here

        setState(() {
          _recordings.removeAt(index);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${recording.name} deleted')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting file: $e')),
      );
    }
  }
}

class RecordingItem {
  final String name;
  final String size;
  final DateTime timestamp;
  final String filePath;

  const RecordingItem({
    required this.name,
    required this.size,
    required this.timestamp,
    required this.filePath,
  });
}