import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/services/app_config_service.dart';

class LocationSuggestionsService {
  LocationSuggestionsService({
    http.Client? client,
  }) : _client = client ?? http.Client();

  final http.Client _client;

  static const Map<String, String> _countryCodes = {
    'Nigeria': 'ng',
    'Ghana': 'gh',
    'Kenya': 'ke',
    'South Africa': 'za',
    'United States': 'us',
    'United Kingdom': 'gb',
  };

  Future<List<String>> searchLocations({
    required String query,
    required String country,
  }) async {
    if (query.trim().isEmpty) {
      return const [];
    }

    final apiKey = await AppConfigService.getGoogleMapsApiKey();
    final countryCode = _countryCodes[country] ?? '';
    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/place/autocomplete/json',
      {
        'input': query,
        'types': '(regions)',
        'components': 'country:$countryCode',
        'language': 'en',
        'key': apiKey,
      },
    );

    final response = await _client.get(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'Location lookup failed with status ${response.statusCode}.',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final status = json['status'] as String?;
    if (status != null && status != 'OK' && status != 'ZERO_RESULTS') {
      throw StateError('Location lookup failed with status $status.');
    }

    final predictions = json['predictions'] as List<dynamic>? ?? const [];
    return predictions
        .map((prediction) => prediction as Map<String, dynamic>)
        .map((prediction) => prediction['description'] as String?)
        .whereType<String>()
        .toList();
  }
}
