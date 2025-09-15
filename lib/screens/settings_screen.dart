import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:motion_sensor_app/services/network_stream_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Sampling rate settings
  double _accelerometerRate = 50.0;
  double _gyroscopeRate = 50.0;
  double _magnetometerRate = 50.0;
  double _rotationVectorRate = 50.0;

  // Pre-notice settings
  bool _usePercentageMode = true;
  double _preNoticePercentage = 50.0;
  int _preNoticeSeconds = 5;

  // File format settings
  bool _useCSVFormat = true;
  bool _useForegroundService = true;

  // TTS settings
  bool _enableTTS = true;
  double _ttsVolume = 1.0;
  double _ttsSpeed = 0.5;

  // Network settings
  NetworkProtocol _selectedProtocol = NetworkProtocol.tcp;
  String _streamHost = '127.0.0.1';
  int _streamPort = 8080;
  bool _enableStreaming = false;

  // Controllers for text fields
  final TextEditingController _hostController = TextEditingController();
  final TextEditingController _portController = TextEditingController();

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      setState(() {
        // Sampling rates
        _accelerometerRate = prefs.getDouble('accelerometer_rate') ?? 50.0;
        _gyroscopeRate = prefs.getDouble('gyroscope_rate') ?? 50.0;
        _magnetometerRate = prefs.getDouble('magnetometer_rate') ?? 50.0;
        _rotationVectorRate = prefs.getDouble('rotation_vector_rate') ?? 50.0;

        // Pre-notice settings
        _usePercentageMode = prefs.getBool('use_percentage_mode') ?? true;
        _preNoticePercentage = prefs.getDouble('pre_notice_percentage') ?? 50.0;
        _preNoticeSeconds = prefs.getInt('pre_notice_seconds') ?? 5;

        // File format settings
        _useCSVFormat = prefs.getBool('use_csv_format') ?? true;
        _useForegroundService = prefs.getBool('use_foreground_service') ?? true;

        // TTS settings
        _enableTTS = prefs.getBool('enable_tts') ?? true;
        _ttsVolume = prefs.getDouble('tts_volume') ?? 1.0;
        _ttsSpeed = prefs.getDouble('tts_speed') ?? 0.5;

        // Network settings
        _enableStreaming = prefs.getBool('enable_streaming') ?? false;
        _streamHost = prefs.getString('stream_host') ?? '127.0.0.1';
        _streamPort = prefs.getInt('stream_port') ?? 8080;
        
        String protocolString = prefs.getString('stream_protocol') ?? 'tcp';
        _selectedProtocol = protocolString == 'udp' ? NetworkProtocol.udp : NetworkProtocol.tcp;

        // Initialize text controllers
        _hostController.text = _streamHost;
        _portController.text = _streamPort.toString();
        
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading settings: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

   Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Sampling rates
      await prefs.setDouble('accelerometer_rate', _accelerometerRate);
      await prefs.setDouble('gyroscope_rate', _gyroscopeRate);
      await prefs.setDouble('magnetometer_rate', _magnetometerRate);
      await prefs.setDouble('rotation_vector_rate', _rotationVectorRate);

      // Pre-notice settings
      await prefs.setBool('use_percentage_mode', _usePercentageMode);
      await prefs.setDouble('pre_notice_percentage', _preNoticePercentage);
      await prefs.setInt('pre_notice_seconds', _preNoticeSeconds);

      // File format settings
      await prefs.setBool('use_csv_format', _useCSVFormat);
      await prefs.setBool('use_foreground_service', _useForegroundService);

      // TTS settings
      await prefs.setBool('enable_tts', _enableTTS);
      await prefs.setDouble('tts_volume', _ttsVolume);
      await prefs.setDouble('tts_speed', _ttsSpeed);

      // Network settings
      await prefs.setBool('enable_streaming', _enableStreaming);
      await prefs.setString('stream_host', _streamHost);
      await prefs.setInt('stream_port', _streamPort);
      await prefs.setString('stream_protocol', _selectedProtocol.toString().split('.').last);
      
    } catch (e) {
      debugPrint('Error saving settings: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () async {
              await _saveSettings();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings saved')),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Sensor Sampling Rates Section
          _buildSectionCard(
            'Sensor Sampling Rates',
            [
              _buildSliderSetting(
                'Accelerometer',
                _accelerometerRate,
                1.0,
                200.0,
                'Hz',
                (value) => setState(() => _accelerometerRate = value),
              ),
              _buildSliderSetting(
                'Gyroscope',
                _gyroscopeRate,
                1.0,
                200.0,
                'Hz',
                (value) => setState(() => _gyroscopeRate = value),
              ),
              _buildSliderSetting(
                'Magnetometer',
                _magnetometerRate,
                1.0,
                200.0,
                'Hz',
                (value) => setState(() => _magnetometerRate = value),
              ),
              _buildSliderSetting(
                'Rotation Vector',
                _rotationVectorRate,
                1.0,
                200.0,
                'Hz',
                (value) => setState(() => _rotationVectorRate = value),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Pre-notice Settings Section
          _buildSectionCard(
            'Pre-notice Settings',
            [
              SwitchListTile(
                title: const Text('Use Percentage Mode'),
                subtitle: Text(_usePercentageMode 
                    ? 'Pre-notice at percentage of activity duration'
                    : 'Pre-notice at fixed seconds before switch'),
                value: _usePercentageMode,
                onChanged: (value) => setState(() => _usePercentageMode = value),
              ),
              if (_usePercentageMode)
                _buildSliderSetting(
                  'Pre-notice Percentage',
                  _preNoticePercentage,
                  10.0,
                  90.0,
                  '%',
                  (value) => setState(() => _preNoticePercentage = value),
                )
              else
                _buildSliderSetting(
                  'Pre-notice Time',
                  _preNoticeSeconds.toDouble(),
                  1.0,
                  30.0,
                  's',
                  (value) => setState(() => _preNoticeSeconds = value.round()),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // File Format Settings Section
          _buildSectionCard(
            'File Format & Service',
            [
              SwitchListTile(
                title: const Text('CSV Format'),
                subtitle: Text(_useCSVFormat ? 'Export as CSV files' : 'Export as JSON files'),
                value: _useCSVFormat,
                onChanged: (value) => setState(() => _useCSVFormat = value),
              ),
              SwitchListTile(
                title: const Text('Foreground Service'),
                subtitle: const Text('Keep recording in background'),
                value: _useForegroundService,
                onChanged: (value) => setState(() => _useForegroundService = value),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // TTS Settings Section
          _buildSectionCard(
            'Text-to-Speech Settings',
            [
              SwitchListTile(
                title: const Text('Enable TTS'),
                subtitle: const Text('Voice announcements for activities'),
                value: _enableTTS,
                onChanged: (value) => setState(() => _enableTTS = value),
              ),
              if (_enableTTS) ...[
                _buildSliderSetting(
                  'TTS Volume',
                  _ttsVolume,
                  0.1,
                  1.0,
                  '',
                  (value) => setState(() => _ttsVolume = value),
                ),
                // Updated TTS Speed with better range
                _buildSliderSetting(
                  'TTS Speed',
                  _ttsSpeed,
                  0.3,  // Much slower minimum
                  1.5,  // Reasonable maximum
                  'x',
                  (value) => setState(() => _ttsSpeed = value),
                ),
                // Show current speed value
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'Current speed: ${_ttsSpeed.toStringAsFixed(1)}x',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 16),

          // Network Streaming Section
          _buildSectionCard(
            'Network Streaming',
            [
              SwitchListTile(
                title: const Text('Enable Live Streaming'),
                subtitle: const Text('Stream sensor data over network'),
                value: _enableStreaming,
                 onChanged: (value) async {
                  setState(() => _enableStreaming = value);
                  await _saveSettings(); // Auto-save streaming toggle
                }, // Auto-save streaming toggle
              ),
              if (_enableStreaming) ...[
                DropdownButtonFormField<NetworkProtocol>(
                  initialValue: _selectedProtocol,
                  items: NetworkProtocol.values.map((protocol) {
                    return DropdownMenuItem(
                      value: protocol,
                      child: Text(protocol.toString().split('.').last.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedProtocol = value!),
                  decoration: const InputDecoration(labelText: 'Protocol', border: OutlineInputBorder(),),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: _streamHost,
                    decoration: const InputDecoration(labelText: 'Host IP', 
                    hintText: '127.0.0.1 or 192.168.1.100',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => setState(() => _streamHost = value),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _portController,
                  decoration: const InputDecoration(
                    labelText: 'Port Number',
                    hintText: '8080',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(5),
                  ],
                  onChanged: (value){
                    final port = int.tryParse(value);
                    if (port != null && port >= 1024 && port <= 65535) {
                      _streamPort = port;
                    }
                  },
                ),

                const SizedBox(height: 8,),
                Text(
                  'Port range: 1024 - 65535',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16,),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Stream Endpoint: ',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4,),
                      SelectableText(
                        '${_selectedProtocol.toString().split('.').last.toUpperCase()}://$_streamHost:$_streamPort',
                        style: const TextStyle(fontFamily: 'monospace'),
                      )
                    ],
                  ),
                )
              ],
            ],
          ),

          const SizedBox(height: 16),

          // Action Buttons Section
          _buildSectionCard(
            'Actions',
            [
              ListTile(
                leading: const Icon(Icons.restore),
                title: const Text('Reset to Defaults'),
                subtitle: const Text('Restore all settings to default values'),
                onTap: _resetToDefaults,
              ),
              ListTile(
                leading: const Icon(Icons.info),
                title: const Text('About'),
                subtitle: const Text('App version and information'),
                onTap: _showAboutDialog,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildSliderSetting(
    String label,
    double value,
    double min,
    double max,
    String unit,
    ValueChanged<double> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text('${value.round()}$unit'),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: (max - min).round(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  void _resetToDefaults() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reset Settings'),
          content: const Text('Are you sure you want to reset all settings to their default values?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                setState(() {
                  _accelerometerRate = 50.0;
                  _gyroscopeRate = 50.0;
                  _magnetometerRate = 50.0;
                  _rotationVectorRate = 50.0;
                  _usePercentageMode = true;
                  _preNoticePercentage = 50.0;
                  _preNoticeSeconds = 5;
                  _useCSVFormat = true;
                  _useForegroundService = true;
                  _enableTTS = true;
                  _ttsVolume = 1.0;
                  _ttsSpeed = 0.5;
                  _enableStreaming = false;
                  _streamHost = '127.0.0.1';
                  _streamPort = 8080;
                  _selectedProtocol = NetworkProtocol.tcp;
                  
                  _hostController.text = _streamHost;
                  _portController.text = _streamPort.toString();
                });
                await _saveSettings();
                if (!context.mounted) return;
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Settings reset to defaults')),
                );
              },
              child: const Text('Reset'),
            ),
          ],
        );
      },
    );
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'Motion Sensor Recorder',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.sensors, size: 48),
      children: [
        const Text('A Flutter app for recording motion sensor data with activity tagging.'),
        const SizedBox(height: 16),
        const Text('Features:'),
        const Text('• Record accelerometer, gyroscope, magnetometer, and rotation vector data'),
        const Text('• Tag data with user-defined activity sequences'),
        const Text('• TTS announcements for activity transitions'),
        const Text('• Export data as CSV or JSON files'),
        const Text('• Background recording with foreground service'),
        const Text('• Live streaming of sensor data over network'),
      ],
    );
  }

  Map<String, dynamic> getSettings() {
    return {
      'samplingRates': {
        'accelerometer': _accelerometerRate.round(),
        'gyroscope': _gyroscopeRate.round(),
        'magnetometer': _magnetometerRate.round(),
        'rotation_vector': _rotationVectorRate.round(),
      },
      'preNotice': {
        'usePercentageMode': _usePercentageMode,
        'percentage': _preNoticePercentage,
        'seconds': _preNoticeSeconds,
      },
      'fileFormat': {
        'useCSV': _useCSVFormat,
        'useForegroundService': _useForegroundService,
      },
      'tts': {
        'enabled': _enableTTS,
        'volume': _ttsVolume,
        'speed': _ttsSpeed,
      },
      'streaming': {
        'enabled': _enableStreaming,
        'protocol': _selectedProtocol.toString(),
        'host': _streamHost,
        'port': _streamPort,
      },
    };
  }
}

