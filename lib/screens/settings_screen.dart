import 'package:flutter/material.dart';

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
  double _ttsSpeed = 1.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
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
                _buildSliderSetting(
                  'TTS Speed',
                  _ttsSpeed,
                  0.5,
                  2.0,
                  'x',
                  (value) => setState(() => _ttsSpeed = value),
                ),
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
              onPressed: () {
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
                  _ttsSpeed = 1.0;
                });
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
    };
  }
}

