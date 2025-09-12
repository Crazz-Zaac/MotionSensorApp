# Motion Sensor Recorder

A comprehensive Android Flutter application for recording motion sensor data with activity tagging, TTS alerts, and data export functionality. This app combines Flutter's cross-platform UI capabilities with native Kotlin sensor handling for precise, high-frequency data collection.

## Features

### Core Functionality
- **Multi-sensor Recording**: Simultaneous recording from accelerometer, gyroscope, magnetometer, and rotation vector sensors
- **Activity Sequence Management**: Create, edit, and reorder custom activity sequences with user-defined durations
- **Real-time Data Visualization**: Live plotting of sensor data during recording sessions
- **TTS Announcements**: Voice guidance for activity transitions with configurable pre-notice timing
- **Background Recording**: Foreground service ensures continuous recording even when app is backgrounded
- **Data Export**: Save recordings as CSV files with timestamp and activity tagging

### User Interface
- **Activities Screen**: Intuitive interface for creating and managing activity sequences
- **Home Screen**: Main recording interface with live sensor visualization and recording controls
- **Export Screen**: File management for viewing, sharing, and deleting recordings
- **Settings Screen**: Comprehensive configuration for sampling rates, TTS preferences, and app behavior

### Technical Features
- **Native Sensor Integration**: Kotlin-based sensor handling with precise sampling rate control
- **Chunked Data Writing**: Efficient CSV writing with buffered I/O to prevent memory issues
- **Foreground Service**: Android foreground service for stable background operation
- **MethodChannel/EventChannel**: Seamless Flutter-Kotlin communication for sensor control and data streaming

## Architecture

### Flutter Layer
The Flutter application provides the user interface and coordinates the overall app flow:

- **Main App**: Navigation between screens using bottom navigation bar
- **Screen Components**: Modular screen implementations for different app functions
- **Platform Channels**: Communication bridge to native Android functionality

### Kotlin Native Layer
Native Android components handle sensor operations and system-level functionality:

- **SensorManager**: Core sensor handling with configurable sampling rates
- **DataRecorder**: CSV file writing with chunked buffering and activity tagging
- **SensorRecordingService**: Foreground service for background recording with TTS integration
- **Platform Channels**: MethodChannel and EventChannel handlers for Flutter communication

## Installation

### Prerequisites
- Flutter SDK 3.16.0 or later
- Android SDK with API level 21 (Android 5.0) or higher
- Java JDK 17
- Android Studio or VS Code with Flutter extensions

### Setup Instructions

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd motion_sensor_app
   ```

2. **Install Flutter dependencies**:
   ```bash
   flutter pub get
   ```

3. **Configure Android SDK**:
   - Ensure Android SDK is properly installed
   - Set `ANDROID_HOME` environment variable
   - Install required SDK platforms and build tools

4. **Build the application**:
   ```bash
   # Debug build
   flutter build apk --debug
   
   # Release build
   flutter build apk --release
   ```

5. **Install on device**:
   ```bash
   flutter install
   ```

## Usage

### Creating Activity Sequences

1. Navigate to the **Activities** tab
2. Tap the **+** button to add a new activity
3. Enter activity name and duration in seconds
4. Use drag handles to reorder activities
5. Edit or delete activities using the action buttons

### Recording Sensor Data

1. Go to the **Home** tab
2. Ensure your activity sequence is configured
3. Tap **Start Recording** to begin
4. Follow TTS announcements for activity transitions
5. Monitor live sensor data visualization
6. Tap **Stop Recording** to end manually, or let it complete automatically

### Managing Recordings

1. Visit the **Export** tab to view all recordings
2. Tap on a recording to preview its contents
3. Use the menu button for additional actions:
   - **Preview**: View recording metadata and sample data
   - **Share**: Share the CSV file with other apps
   - **Export**: Copy to external storage
   - **Delete**: Remove the recording permanently

### Configuring Settings

1. Access the **Settings** tab for app configuration
2. Adjust sensor sampling rates using sliders (1-200 Hz)
3. Configure pre-notice timing:
   - **Percentage Mode**: Pre-notice at percentage of activity duration
   - **Fixed Mode**: Pre-notice at fixed seconds before transition
4. Toggle file format between CSV and JSON
5. Enable/disable foreground service and TTS announcements

## Data Format

### CSV Structure
Recordings are saved as CSV files with the following structure:

```csv
timestamp,accelerometer_x,accelerometer_y,accelerometer_z,gyroscope_x,gyroscope_y,gyroscope_z,magnetometer_x,magnetometer_y,magnetometer_z,rotation_vector_x,rotation_vector_y,rotation_vector_z,rotation_vector_w,activity
2024-01-15T10:30:00.123Z,0.123,-9.456,0.789,0.012,-0.034,0.056,45.2,-12.8,23.1,0.707,0.0,0.0,0.707,Walk
```

### Data Fields
- **timestamp**: ISO8601 formatted timestamp with millisecond precision
- **accelerometer_x/y/z**: Acceleration values in m/s²
- **gyroscope_x/y/z**: Angular velocity in rad/s
- **magnetometer_x/y/z**: Magnetic field strength in μT
- **rotation_vector_x/y/z/w**: Rotation quaternion components
- **activity**: Current activity label from the sequence

## Development

### Project Structure
```
motion_sensor_app/
├── android/
│   └── app/src/main/kotlin/com/example/motion_sensor_app/
│       ├── MainActivity.kt              # Main activity with platform channels
│       ├── SensorManager.kt             # Core sensor handling
│       ├── DataRecorder.kt              # CSV writing and file management
│       ├── SensorRecordingService.kt    # Foreground service with TTS
│       └── SensorStreamHandler.kt       # EventChannel stream handler
├── lib/
│   ├── main.dart                        # App entry point and navigation
│   └── screens/
│       ├── home_screen.dart             # Recording interface
│       ├── activities_screen.dart       # Activity sequence management
│       ├── export_screen.dart           # File management
│       └── settings_screen.dart         # App configuration
├── .github/workflows/
│   └── android-build.yml               # CI/CD workflow
└── README.md                            # This documentation
```

### Building and Testing

#### Local Development
```bash
# Run in debug mode
flutter run

# Analyze code quality
flutter analyze

# Run unit tests
flutter test

# Build release APK
flutter build apk --release
```

#### Continuous Integration
The project includes a GitHub Actions workflow that automatically:
- Builds the app on every push and pull request
- Runs code analysis and tests
- Generates release APK and App Bundle artifacts
- Uploads build artifacts for download

### Platform Channels

#### Sensor Control (MethodChannel)
```dart
static const MethodChannel _sensorChannel = MethodChannel('motion_sensor_app/sensors');

// Start sensors with sampling rates
await _sensorChannel.invokeMethod('startSensors', {'samplingRates': rates});

// Stop all sensors
await _sensorChannel.invokeMethod('stopSensors');
```

#### Sensor Data Stream (EventChannel)
```dart
static const EventChannel _sensorStream = EventChannel('motion_sensor_app/sensor_stream');

// Listen to sensor data
_sensorStream.receiveBroadcastStream().listen((data) {
  // Process sensor data
});
```

#### Data Recording (MethodChannel)
```dart
static const MethodChannel _dataChannel = MethodChannel('motion_sensor_app/data');

// Start recording with activity sequence
await _dataChannel.invokeMethod('startRecording', {'activitySequence': sequence});

// Stop recording and get file path
String filePath = await _dataChannel.invokeMethod('stopRecording');
```

## Permissions

The app requires the following Android permissions:

- `BODY_SENSORS`: Access to motion sensors
- `WRITE_EXTERNAL_STORAGE`: Save recording files
- `READ_EXTERNAL_STORAGE`: Read recording files
- `FOREGROUND_SERVICE`: Background recording capability
- `WAKE_LOCK`: Prevent device sleep during recording

## Acceptance Testing

### Test Scenario: 30-Second Recording Sequence

To verify the app meets the specified requirements, perform this acceptance test:

1. **Setup**: Create a sequence with three activities:
   - Walk: 10 seconds
   - Sit: 10 seconds  
   - Jump: 10 seconds

2. **Expected TTS Announcements**:
   - 0s: "Get ready to Walk for 10 seconds"
   - 5s: "Get ready to Sit" (50% pre-notice)
   - 10s: "Start Sit now"
   - 15s: "Get ready to Jump" (50% pre-notice)
   - 20s: "Start Jump now"
   - 25s: "Get ready to [next]" (if applicable)
   - 30s: "End of recording"

3. **Verification**:
   - CSV file is created with correct headers
   - All sensor data includes proper timestamps
   - Activity labels match the sequence timing
   - File size is reasonable for 30 seconds of multi-sensor data

## Troubleshooting

### Common Issues

#### Sensors Not Working
- Verify device has required sensors using device specifications
- Check that sensor permissions are granted
- Ensure sampling rates are within device capabilities

#### Recording Files Not Saved
- Confirm storage permissions are granted
- Check available storage space
- Verify external storage is accessible

#### TTS Not Working
- Check device TTS settings and language support
- Verify audio output is not muted
- Ensure TTS is enabled in app settings

#### Background Recording Stops
- Enable foreground service in settings
- Check battery optimization settings for the app
- Verify the app has permission to run in background

### Performance Optimization

#### High-Frequency Recording
- Use lower sampling rates if device performance is poor
- Enable foreground service for stable background operation
- Monitor battery usage during extended recordings

#### Large File Sizes
- Adjust sampling rates based on analysis requirements
- Use chunked writing to manage memory usage
- Regularly export and delete old recordings

## Contributing

### Development Guidelines
1. Follow Flutter and Kotlin coding standards
2. Add unit tests for new functionality
3. Update documentation for API changes
4. Test on multiple Android versions and devices

### Pull Request Process
1. Fork the repository
2. Create a feature branch
3. Implement changes with tests
4. Update documentation
5. Submit pull request with detailed description

## License

This project is licensed under the MIT License. See the LICENSE file for details.

## Support

For issues, questions, or contributions:
- Create an issue on the GitHub repository
- Follow the contributing guidelines
- Provide detailed information about your environment and the issue

## Acknowledgments

- Flutter team for the excellent cross-platform framework
- Android team for comprehensive sensor APIs
- Contributors and testers who helped improve the application
