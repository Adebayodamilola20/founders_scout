import 'package:flutter/services.dart';

class AppConfigService {
  static const MethodChannel _channel = MethodChannel('founders_scout/config');
  static const String _mistralApiKey =
      String.fromEnvironment(
        'MISTRAL_API_KEY',
        defaultValue: '2ZdDAUw0qsB3ys84WNDtUq38YD3a3j4l',
      );
  static Future<String>? _googleMapsApiKeyFuture;

  static Future<String> getGoogleMapsApiKey() async {
    _googleMapsApiKeyFuture ??= _loadGoogleMapsApiKey();
    return _googleMapsApiKeyFuture!;
  }

  static Future<String> _loadGoogleMapsApiKey() async {
    final key = await _channel.invokeMethod<String>('getGoogleMapsApiKey');
    if (key == null || key.isEmpty) {
      throw StateError('Google Maps API key is missing.');
    }
    return key;
  }

  static String getMistralApiKey() {
    if (_mistralApiKey.isEmpty) {
      throw StateError('Mistral API key is missing.');
    }
    return _mistralApiKey;
  }
}
