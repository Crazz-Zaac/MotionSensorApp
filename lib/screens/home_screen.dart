import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:motion_sensor_app/screens/activities_screen.dart'; // Add this import
import 'dart:async';
import 'dart:math';

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
  
  StreamSubscription<dynamic>? _sensorSubscription;
  Timer? _recordingTimer;
  Timer? _activityTimer;
  
  bool _isRecording = false;
  String _currentActivity = 'Ready';
  int _elapsedSeconds = 0;
  int _remainingSeconds = 0;
  int _totalDuration = 0;
  
   List<Map<String, dynamic>> get _activitySequence {
    return widget.activities.map((activity) {
      return {
        'name': activity.name,
        'duration': activity.duration,
      };
    }).toList();
  }
  
  int _currentActivityIndex = 0;
  
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
  }

  @override
  void dispose() {
    _sensorSubscription?.cancel();
    _recordingTimer?.cancel();
    _activityTimer?.cancel();
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

  Future<void> _startRecording() async {
    if (_activitySequence.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No activities configured. Please add activities first.')),
      );
      return;
    }

    try {
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
          // print('Sensor stream error: $error');
        },
      );
      
      setState(() {
        _isRecording = true;
        _elapsedSeconds = 0;
        _currentActivityIndex = 0;
        _currentActivity = _activitySequence[0]['name'];
        _remainingSeconds = _totalDuration;
      });
      
      _startTimers();
      
    } catch (e) {
      // print('Error starting recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      await _sensorChannel.invokeMethod('stopSensors');
      await _serviceChannel.invokeMethod('stopService');
      
      _sensorSubscription?.cancel();
      _recordingTimer?.cancel();
      _activityTimer?.cancel();
      
      setState(() {
        _isRecording = false;
        _currentActivity = 'Ready';
        _elapsedSeconds = 0;
        _remainingSeconds = _totalDuration;
        _accelerometerData.clear();
        _gyroscopeData.clear();
      });
      
    } catch (e) {
      // print('Error stopping recording: $e');
    }
  }

  void _startTimers() {
    // Main recording timer
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedSeconds++;
        _remainingSeconds = _totalDuration - _elapsedSeconds;
      });
      
      if (_elapsedSeconds >= _totalDuration) {
        _stopRecording();
      }
    });
    
    // Activity progression timer
    _scheduleNextActivity();
  }

  void _scheduleNextActivity() {
    if (_currentActivityIndex < _activitySequence.length) {
      int activityDuration = _activitySequence[_currentActivityIndex]['duration'];
      
      _activityTimer = Timer(Duration(seconds: activityDuration), () {
        _currentActivityIndex++;
        if (_currentActivityIndex < _activitySequence.length) {
          setState(() {
            _currentActivity = _activitySequence[_currentActivityIndex]['name'];
          });
          _scheduleNextActivity();
        }
      });
    }
  }

  void _processSensorData(Map<dynamic, dynamic> data) {
    String sensorType = data['sensorType'];
    List<dynamic> values = data['values'];
    
    if (sensorType == 'accelerometer' && values.length >= 3) {
      double magnitude = sqrt(values[0] * values[0] + values[1] * values[1] + values[2] * values[2]);
      setState(() {
        _accelerometerData.add(magnitude);
        if (_accelerometerData.length > _maxDataPoints) {
          _accelerometerData.removeAt(0);
        }
      });
    } else if (sensorType == 'gyroscope' && values.length >= 3) {
      double magnitude = sqrt(values[0] * values[0] + values[1] * values[1] + values[2] * values[2]);
      setState(() {
        _gyroscopeData.add(magnitude);
        if (_gyroscopeData.length > _maxDataPoints) {
          _gyroscopeData.removeAt(0);
        }
      });
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

