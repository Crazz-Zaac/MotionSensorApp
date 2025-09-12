// Enhanced TTS service that respects settings
import 'package:flutter_tts/flutter_tts.dart';

class TTSService {
  final FlutterTts _tts = FlutterTts();
  bool _isEnabled = true;
  double _volume = 1.0;
  double _speechRate = 0.9;

  Future<void> initialize({
    bool? enabled,
    double? volume,
    double? speechRate,
  }) async {
    _isEnabled = enabled ?? true;
    _volume = volume ?? 1.0;
    _speechRate = speechRate ?? 0.9;
    
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(_speechRate);
    await _tts.setVolume(_volume);
    await _tts.setPitch(1.0);
  }

  Future<void> updateSettings({
    bool? enabled,
    double? volume,
    double? speechRate,
  }) async {
    if (enabled != null) _isEnabled = enabled;
    if (volume != null) {
      _volume = volume;
      await _tts.setVolume(_volume);
    }
    if (speechRate != null) {
      _speechRate = speechRate;
      await _tts.setSpeechRate(_speechRate);
    }
  }

  Future<void> speak(String text) async {
    if (!_isEnabled) return;
    
    try {
      await _tts.speak(text);
    } catch (e) {
      // Handle TTS errors gracefully
      // print('TTS Error: $e');
    }
  }

  Future<void> stop() async {
    await _tts.stop();
  }

  void dispose() {
    _tts.stop();
  }
}