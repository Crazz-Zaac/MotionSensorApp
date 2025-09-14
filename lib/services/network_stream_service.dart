import 'dart:io';
import 'dart:convert';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:network_info_plus/network_info_plus.dart';

class NetworkStreamService {
  static const String _defaultHost = '127.0.0.1';
  static const int _defaultPort = 8080;
  
  io.Socket? _socket;
  String _host = _defaultHost;
  int _port = _defaultPort;
  bool _isStreaming = false;
  NetworkProtocol _protocol = NetworkProtocol.tcp;
  
  final NetworkInfo _networkInfo = NetworkInfo();
  
  Future<void> initialize({String? host, int? port, NetworkProtocol? protocol}) async {
    _host = host ?? _defaultHost;
    _port = port ?? _defaultPort;
    _protocol = protocol ?? NetworkProtocol.tcp;
    
    if (_protocol == NetworkProtocol.tcp) {
      _initializeTcpSocket();
    }
    // UDP would require different implementation
  }
  
  void _initializeTcpSocket() {
    try {
      _socket = io.io('http://$_host:$_port', <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
      });
      
      _socket!.on('connect', (_) {
        debugPrint('Connected to $_host:$_port');
      });
      
      _socket!.on('disconnect', (_) {
        debugPrint('Disconnected from $_host:$_port');
      });
      
      _socket!.on('error', (error) {
        debugdebugPrint('Socket error: $error');
      });
      
      _socket!.connect();
    } catch (e) {
      debugPrint('Error initializing socket: $e');
    }
  }
  
  Future<void> startStreaming() async {
    if (_socket != null && !_socket!.connected) {
      _socket!.connect();
    }
    _isStreaming = true;
  }
  
  Future<void> stopStreaming() async {
    _isStreaming = false;
    if (_socket != null && _socket!.connected) {
      _socket!.disconnect();
    }
  }
  
  Future<void> sendSensorData(Map<String, dynamic> sensorData) async {
    if (!_isStreaming || _socket == null || !_socket!.connected) {
      return;
    }
    
    try {
      final jsonData = jsonEncode({
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'data': sensorData,
        'device_info': await _getDeviceInfo(),
      });
      
      _socket!.emit('sensor_data', jsonData);
    } catch (e) {
      debugPrint('Error sending sensor data: $e');
    }
  }
  
  Future<Map<String, dynamic>> _getDeviceInfo() async {
    final wifiIP = await _networkInfo.getWifiIP();
    return {
      'ip_address': wifiIP,
      'platform': Platform.operatingSystem,
      'platform_version': Platform.operatingSystemVersion,
    };
  }
  
  Future<void> updateSettings({String? host, int? port, NetworkProtocol? protocol}) async {
    await stopStreaming();
    await initialize(host: host, port: port, protocol: protocol);
  }
  
  bool get isStreaming => _isStreaming;
  bool get isConnected => _socket?.connected ?? false;
  String get connectionStatus => isConnected ? 'Connected to $_host:$_port' : 'Disconnected';
  
  void dispose() {
    stopStreaming();
    _socket?.disconnect();
    _socket?.destroy();
    _socket = null;
  }
}

enum NetworkProtocol {
  tcp,
  udp,
  // Add other protocols if needed
}