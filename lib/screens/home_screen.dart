import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:motion_sensor_app/screens/activities_screen.dart';
import 'package:motion_sensor_app/services/tts_service.dart';
import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'dart:io'; // Add this import
import 'package:path_provider/path_provider.dart'; // Add this import

class HomeScreen extends StatefulWidget {
  final List<ActivityItem> activities; 
  const HomeScreen({super.key, required this.activities}); // Update constructor

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const MethodChannel _sensorChannel = MethodChannel('motion_sensor_app/sensors');
  static const MethodChannel _serviceChannel = MethodChannel('motion_sensor_app/service');
  static const EventChannel _sensorStream = EventChannel('motion_sensor_app/sensor_stream');

  final TTSService _ttsService = TTSService();
  final List<Timer> _scheduledTimers = []; // Add this to track all timers
  // int _currentActivityIndex = 0;
  Timer? _preNoticeTimer;
  
  StreamSubscription<dynamic>? _sensorSubscription;
  Timer? _recordingTimer;
  Timer? _activityTimer;
  
  bool _isRecording = false;
  String _currentActivity = 'Ready';
  int _elapsedSeconds = 0;
  int _remainingSeconds = 0;
  int _totalDuration = 0;
  int _currentActivityIndex = 0;

  File? _currentRecordingFile;
  // int _recordingStartTime = 0;
  final List<String> _csvBuffer = [];
  final int _bufferFlushSize = 100; // Flush buffer every 100 entries

  
   List<Map<String, dynamic>> get _activitySequence {
    return widget.activities.map((activity) {
      return {
        'name': activity.name,
        'duration': activity.duration,
      };
    }).toList();
  }
  
  // int _currentActivityIndex = 0;
  
  // Sensor data for live plotting
  final List<double> _accelerometerData = [];
  final List<double> _gyroscopeData = [];
  final int _maxDataPoints = 100;
  
  // Sampling rates
  final Map<String, int> _samplingRates = {
    'accelerometer': 50,
    'gyroscope': 50,
    'magnetometer': 50,
    'rotation_vector': 50,
  };

  @override
  void initState() {
    super.initState();
    _calculateTotalDuration();
    _initializeTTS();
  }

  @override
  void dispose() {
    _sensorSubscription?.cancel();
    _recordingTimer?.cancel();
    _activityTimer?.cancel();
    _preNoticeTimer?.cancel();
    
    // Cancel all scheduled timers
    for (var timer in _scheduledTimers) {
      timer.cancel();
    }
    _scheduledTimers.clear();
    
    _ttsService.dispose();
    super.dispose();
  }

  void _calculateTotalDuration() {
    if (_activitySequence.isEmpty) {
      _totalDuration = 0;
      _remainingSeconds = 0;
      return;
    }
    
    _totalDuration = _activitySequence.fold(0, (sum, activity) => sum + (activity['duration'] as int));
    _remainingSeconds = _totalDuration;
  }

  Future<void> _initializeTTS() async {
    await _ttsService.initialize(
      enabled: true,
      volume: 1.0,
      speechRate: 0.5, // Much slower default
    );
  }

  Future<void> _startRecording() async {
    if (_activitySequence.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No activities configured. Please add activities first.')),
      );
      return;
    }

    try {

      await _createRecordingFile();

      // Start sensors
      await _sensorChannel.invokeMethod('startSensors', {'samplingRates': _samplingRates});
      
      // Start foreground service
      await _serviceChannel.invokeMethod('startService');
      
      // Start listening to sensor stream
      _sensorSubscription = _sensorStream.receiveBroadcastStream().listen(
        (dynamic data) {
          _processSensorData(data);
        },
        onError: (error) {
          debugPrint('Sensor stream error: $error');
        },
      );
      
      setState(() {
        _isRecording = true;
        _elapsedSeconds = 0;
        _currentActivityIndex = 0;  
        _currentActivity = _activitySequence[0]['name'];
        _remainingSeconds = _totalDuration;
      });

      // _recordingStartTime = DateTime.now().millisecondsSinceEpoch;

      // Initial announcement
      final firstActivity = _activitySequence[0]['name'];
      final firstDuration = _activitySequence[0]['duration'];
      await _ttsService.speak('Starting recording. Begin $firstActivity for $firstDuration seconds');
      
      _startTimers();
      
    } catch (e) {
      if (!mounted) return;
      debugPrint('Error starting recording: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error starting recording: $e')),
      );
    }
  }

  Future<void> _createRecordingFile() async {
    try {
      // Get Documents directory instead of external storage
      final Directory documentsDir = await getApplicationDocumentsDirectory();
      final Directory motionSensorDir = Directory('${documentsDir.path}/Motion Sensor App/files');
      
      if (!await motionSensorDir.exists()) {
        await motionSensorDir.create(recursive: true);
      }

      // Create filename with timestamp
      final String timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final String filename = 'motion_data_$timestamp.csv';
      
      _currentRecordingFile = File('${motionSensorDir.path}/$filename');
      
      // Write CSV header
      final List<String> headers = [
        'timestamp_ms',
        'elapsed_seconds',
        'current_activity',
        'sensor_type',
        'value_x',
        'value_y', 
        'value_z',
        'magnitude'
      ];
      
      await _currentRecordingFile!.writeAsString('${headers.join(',')}\n');
      _csvBuffer.clear();
      
      debugPrint('Created recording file: ${_currentRecordingFile!.path}');
      
    } catch (e) {
      debugPrint('Error creating recording file: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {

      if (_csvBuffer.isNotEmpty) {
        await _flushCsvBuffer();
      }

      await _sensorChannel.invokeMethod('stopSensors');
      await _serviceChannel.invokeMethod('stopService');
      
      _sensorSubscription?.cancel();
      _recordingTimer?.cancel();
      _activityTimer?.cancel();
      _preNoticeTimer?.cancel();
      
      // Cancel all scheduled timers
      for (var timer in _scheduledTimers) {
        timer.cancel();
      }
      _scheduledTimers.clear();

      // Announce manual stop only if manually stopped (not at natural end)
      if (_elapsedSeconds < _totalDuration) {
        await _ttsService.speak('Recording stopped manually');
      }

      debugPrint('Recording saved to: ${_currentRecordingFile?.path}');
      
      setState(() {
        _isRecording = false;
        _currentActivity = 'Ready';
        _elapsedSeconds = 0;
        _remainingSeconds = _totalDuration;
        _accelerometerData.clear();
        _gyroscopeData.clear();
        _currentActivityIndex = 0;
      });
    
    _currentRecordingFile = null;
      
    } catch (e) {
      debugPrint('Error stopping recording: $e');
    }
  }

  void _startTimers() {
    // Clear any existing scheduled timers
    for (var timer in _scheduledTimers) {
      timer.cancel();
    }
    _scheduledTimers.clear();
    
    // Schedule all announcements upfront
    _scheduleAllAnnouncements();
    
    // Main recording timer - only for UI updates and final check
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedSeconds++;
        _remainingSeconds = _totalDuration - _elapsedSeconds;
      });
      
      if (_elapsedSeconds >= _totalDuration) {
        _stopRecording();
      }
    });
  }

  void _scheduleAllAnnouncements() {
    int accumulatedTime = 0;
    
    for (int i = 0; i < _activitySequence.length; i++) {
      final activity = _activitySequence[i];
      final int activityDuration = activity['duration'];
      // final String activityName = activity['name'];
      
      // Schedule pre-notice (at 50% of activity duration)
      if (i < _activitySequence.length - 1) { // Not the last activity
        final nextActivity = _activitySequence[i + 1]['name'];
        final int preNoticeTime = accumulatedTime + (activityDuration * 0.5).round();
        
        Timer preNoticeTimer = Timer(Duration(seconds: preNoticeTime), () {
          if (_isRecording && _currentActivityIndex == i) { // Only announce if still recording
            _ttsService.speak('Get ready to $nextActivity');
          }
        });
        _scheduledTimers.add(preNoticeTimer);
      }
      
      // Schedule activity switch (at end of current activity)
      accumulatedTime += activityDuration;
      
      if (i < _activitySequence.length - 1) {
        // Schedule activity switch announcement
        final nextActivity = _activitySequence[i + 1]['name'];
        final nextDuration = _activitySequence[i + 1]['duration'];
        Timer switchTimer = Timer(Duration(seconds: accumulatedTime), () {
          if (_isRecording) { // Only announce if still recording
            _ttsService.speak('Start $nextActivity now for $nextDuration seconds');
            
            setState(() {
              _currentActivityIndex = i + 1;
              _currentActivity = nextActivity;
            });
          }
        });
        _scheduledTimers.add(switchTimer);
      } else {
          // Schedule final announcement
          Timer endTimer = Timer(Duration(seconds: accumulatedTime), () {
          if (_isRecording) {
            _ttsService.speak('End of recording');
            // Auto-stop after a brief delay
            Timer(const Duration(seconds: 2), () {
              if (_isRecording) {
                _stopRecording();
              }
            });
          }
        });
        _scheduledTimers.add(endTimer);
      }
    }
  }
  
  void _processSensorData(Map<dynamic, dynamic> data) {
    if (!_isRecording || _currentRecordingFile == null) return;
    
    String sensorType = data['sensorType'];
    List<dynamic> values = data['values'];
    
    if (values.length >= 3) {
      final double x = values[0].toDouble();
      final double y = values[1].toDouble(); 
      final double z = values[2].toDouble();
      final double magnitude = sqrt(x * x + y * y + z * z);
      
      // Add to CSV buffer
      final int currentTimeMs = DateTime.now().millisecondsSinceEpoch;
      final List<String> row = [
        currentTimeMs.toString(),
        _elapsedSeconds.toString(),
        _currentActivity,
        sensorType,
        x.toStringAsFixed(6),
        y.toStringAsFixed(6),
        z.toStringAsFixed(6),
        magnitude.toStringAsFixed(6)
      ];
      
      _csvBuffer.add(row.join(','));
      
      // Flush buffer periodically
      if (_csvBuffer.length >= _bufferFlushSize) {
        _flushCsvBuffer();
      }
      
      // Update UI data for live plotting
      if (sensorType == 'accelerometer') {
        setState(() {
          _accelerometerData.add(magnitude);
          if (_accelerometerData.length > _maxDataPoints) {
            _accelerometerData.removeAt(0);
          }
        });
      } else if (sensorType == 'gyroscope') {
        setState(() {
          _gyroscopeData.add(magnitude);
          if (_gyroscopeData.length > _maxDataPoints) {
            _gyroscopeData.removeAt(0);
          }
        });
      }
    }
  }

  Future<void> _flushCsvBuffer() async {
    if (_csvBuffer.isEmpty || _currentRecordingFile == null) return;
    
    try {
      final String csvData = '${_csvBuffer.join('\n')}\n';
      await _currentRecordingFile!.writeAsString(csvData, mode: FileMode.append);
      _csvBuffer.clear();
    } catch (e) {
      debugPrint('Error flushing CSV buffer: $e');
    }
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Motion Sensor Recorder'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recording status card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Status: ${_isRecording ? 'Recording' : 'Ready'}',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Icon(
                          _isRecording ? Icons.fiber_manual_record : Icons.stop,
                          color: _isRecording ? Colors.red : Colors.grey,
                          size: 24,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Current Activity: $_currentActivity',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Elapsed: ${_formatTime(_elapsedSeconds)}'),
                        Text('Remaining: ${_formatTime(_remainingSeconds)}'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: _totalDuration > 0 ? _elapsedSeconds / _totalDuration : 0,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Live sensor data visualization
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Live Sensor Data',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: _isRecording
                            ? CustomPaint(
                                painter: SensorDataPainter(_accelerometerData, _gyroscopeData),
                                size: Size.infinite,
                              )
                            : const Center(
                                child: Text('Start recording to see live sensor data'),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Control buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _isRecording ? null : _startRecording,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start Recording'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isRecording ? _stopRecording : null,
                  icon: const Icon(Icons.stop),
                  label: const Text('Stop Recording'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SensorDataPainter extends CustomPainter {
  final List<double> accelerometerData;
  final List<double> gyroscopeData;

  SensorDataPainter(this.accelerometerData, this.gyroscopeData);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Draw accelerometer data in blue
    if (accelerometerData.isNotEmpty) {
      paint.color = Colors.blue;
      _drawDataLine(canvas, size, accelerometerData, paint);
    }

    // Draw gyroscope data in red
    if (gyroscopeData.isNotEmpty) {
      paint.color = Colors.red;
      _drawDataLine(canvas, size, gyroscopeData, paint, offset: size.height / 2);
    }

    // Draw labels
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    textPainter.text = const TextSpan(
      text: 'Accelerometer (Blue)',
      style: TextStyle(color: Colors.blue, fontSize: 12),
    );
    textPainter.layout();
    textPainter.paint(canvas, const Offset(10, 10));

    textPainter.text = const TextSpan(
      text: 'Gyroscope (Red)',
      style: TextStyle(color: Colors.red, fontSize: 12),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(10, size.height / 2 + 10));
  }

  void _drawDataLine(Canvas canvas, Size size, List<double> data, Paint paint, {double offset = 0}) {
    if (data.length < 2) return;

    final path = Path();
    final maxValue = data.reduce(max);
    final minValue = data.reduce(min);
    final range = maxValue - minValue;
    
    if (range == 0) return;

    final stepX = size.width / (data.length - 1);
    final chartHeight = size.height / 2 - 20;

    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final normalizedValue = (data[i] - minValue) / range;
      final y = offset + chartHeight - (normalizedValue * chartHeight);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

