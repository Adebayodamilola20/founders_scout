import 'dart:convert';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import '../../../core/services/app_config_service.dart';
import '../../radar/models/scout_lead.dart';
import '../../radar/models/scout_scan_result.dart';
import '../../setup/models/scout_setup_request.dart';
import '../models/scan_progress.dart';

class GooglePlacesScanService {
  GooglePlacesScanService({
    http.Client? client,
  }) : _client = client ?? http.Client();

  final http.Client _client;

  Future<ScoutScanResult> scan(
    ScoutSetupRequest request, {
    required void Function(ScanProgress progress) onProgress,
  }) async {
    onProgress(
      const ScanProgress(
        status: 'Resolving target location...',
        checkedBusinesses: 0,
      ),
    );

    final apiKey = await AppConfigService.getGoogleMapsApiKey();
    final center = await _resolveLocation(request.locationLabel, apiKey);

    final placeSummaries = <Map<String, dynamic>>[];
    for (final category in request.categories) {
      onProgress(
        ScanProgress(
          status: 'Searching $category around ${request.location}...',
          checkedBusinesses: placeSummaries.length,
        ),
      );
      final results = await _searchPlaces(
        query: '$category in ${request.locationLabel}',
        apiKey: apiKey,
      );
      placeSummaries.addAll(
        results.map((result) => {
          ...result,
          '_selected_category': category,
        }),
      );
    }

    final uniqueSummaries = <String, Map<String, dynamic>>{};
    for (final summary in placeSummaries) {
      final placeId = summary['place_id'] as String?;
      if (placeId != null && placeId.isNotEmpty) {
        uniqueSummaries[placeId] = summary;
      }
    }

    final leads = <ScoutLead>[];
    var checkedBusinesses = 0;

    for (final entry in uniqueSummaries.entries) {
      checkedBusinesses += 1;
      onProgress(
        ScanProgress(
          status: 'Checking $checkedBusinesses businesses nearby',
          checkedBusinesses: checkedBusinesses,
        ),
      );

      final details = await _fetchPlaceDetails(entry.key, apiKey);
      final lead = _buildLead(
        request: request,
        summary: entry.value,
        details: details,
      );
      if (lead != null) {
        leads.add(lead);
      }
    }

    leads.sort((a, b) {
      final websitePriority = (a.hasWebsite ? 1 : 0).compareTo(b.hasWebsite ? 1 : 0);
      if (websitePriority != 0) {
        return websitePriority;
      }
      return a.name.compareTo(b.name);
    });

    return ScoutScanResult(
      request: request,
      center: center,
      leads: leads,
      checkedBusinesses: checkedBusinesses,
    );
  }

  Future<LatLng> _resolveLocation(String address, String apiKey) async {
    final uri = Uri.https('maps.googleapis.com', '/maps/api/geocode/json', {
      'address': address,
      'key': apiKey,
    });
    final response = await _client.get(uri);
    final json = _decodeJson(response);
    final results = json['results'] as List<dynamic>? ?? const [];
    if (results.isEmpty) {
      throw StateError('No location match found for $address.');
    }
    final geometry = results.first['geometry'] as Map<String, dynamic>;
    final location = geometry['location'] as Map<String, dynamic>;
    return LatLng(
      (location['lat'] as num).toDouble(),
      (location['lng'] as num).toDouble(),
    );
  }

  Future<List<Map<String, dynamic>>> _searchPlaces({
    required String query,
    required String apiKey,
  }) async {
    final uri = Uri.https('maps.googleapis.com', '/maps/api/place/textsearch/json', {
      'query': query,
      'key': apiKey,
    });
    final response = await _client.get(uri);
    final json = _decodeJson(response);
    final results = json['results'] as List<dynamic>? ?? const [];
    return results.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> _fetchPlaceDetails(String placeId, String apiKey) async {
    final uri = Uri.https('maps.googleapis.com', '/maps/api/place/details/json', {
      'place_id': placeId,
      'fields':
          'place_id,name,formatted_address,geometry,website,formatted_phone_number,rating,user_ratings_total,photos,types,business_status',
      'key': apiKey,
    });
    final response = await _client.get(uri);
    final json = _decodeJson(response);
    return (json['result'] as Map<String, dynamic>?) ?? const {};
  }

  ScoutLead? _buildLead({
    required ScoutSetupRequest request,
    required Map<String, dynamic> summary,
    required Map<String, dynamic> details,
  }) {
    final geometry = (details['geometry'] ?? summary['geometry']) as Map<String, dynamic>?;
    final location = geometry?['location'] as Map<String, dynamic>?;
    if (location == null) {
      return null;
    }

    final website = details['website'] as String?;
    final hasWebsite = website != null && website.isNotEmpty;
    final phoneNumber = details['formatted_phone_number'] as String?;
    final businessStatus = details['business_status'] as String?;
    final detailPhotos = details['photos'];
    final summaryPhotos = summary['photos'];
    final photos = detailPhotos is List
        ? detailPhotos
        : summaryPhotos is List
            ? summaryPhotos
            : const <dynamic>[];
    final rating = (details['rating'] ?? summary['rating']) as num?;
    final userRatingsTotal = (details['user_ratings_total'] ?? summary['user_ratings_total'] ?? 0) as num;

    final matchedGaps = _matchGaps(
      selectedGaps: request.digitalGaps,
      hasWebsite: hasWebsite,
      photoCount: photos.length,
      rating: rating?.toDouble(),
      userRatingsTotal: userRatingsTotal.toInt(),
    );

    if (matchedGaps.isEmpty) {
      return null;
    }

    final types = (details['types'] as List<dynamic>? ?? summary['types'] as List<dynamic>? ?? const [])
        .cast<String>();

    return ScoutLead(
      placeId: (details['place_id'] ?? summary['place_id']) as String,
      name: (details['name'] ?? summary['name'] ?? 'Unknown business') as String,
      address:
          (details['formatted_address'] ?? summary['formatted_address'] ?? request.locationLabel) as String,
      sourceCountry: request.country,
      position: LatLng(
        (location['lat'] as num).toDouble(),
        (location['lng'] as num).toDouble(),
      ),
      category: _humanizeCategory(types, request.categories),
      selectedCategory: (summary['_selected_category'] as String?) ?? request.categories.first,
      rating: rating?.toDouble(),
      userRatingsTotal: userRatingsTotal.toInt(),
      hasWebsite: hasWebsite,
      website: website,
      photoCount: photos.length,
      photoReferences: photos
          .map((photo) => (photo as Map<String, dynamic>)['photo_reference'] as String?)
          .whereType<String>()
          .toList(),
      phoneNumber: phoneNumber,
      businessStatus: businessStatus,
      matchedGaps: matchedGaps,
    );
  }

  Set<String> _matchGaps({
    required List<String> selectedGaps,
    required bool hasWebsite,
    required int photoCount,
    required double? rating,
    required int userRatingsTotal,
  }) {
    final matches = <String>{};
    for (final gap in selectedGaps) {
      switch (gap) {
        case 'Website Design':
          if (!hasWebsite) {
            matches.add(gap);
          }
          break;
        case 'Review Management':
          if (userRatingsTotal == 0 || (rating ?? 0) < 3.8) {
            matches.add(gap);
          }
          break;
        case 'Photography / Video':
          if (photoCount < 3) {
            matches.add(gap);
          }
          break;
        case 'Social Media Mgmt':
          if (photoCount < 4 || userRatingsTotal < 5) {
            matches.add(gap);
          }
          break;
        case 'Logo / Branding':
          if (!hasWebsite || photoCount < 2) {
            matches.add(gap);
          }
          break;
        case 'Lead Capture':
          if (hasWebsite == false || userRatingsTotal == 0) {
            matches.add(gap);
          }
          break;
      }
    }
    return matches;
  }

  String _humanizeCategory(List<String> types, List<String> fallbackCategories) {
    if (types.isNotEmpty) {
      return types.first.replaceAll('_', ' ');
    }
    return fallbackCategories.first;
  }

  Map<String, dynamic> _decodeJson(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('Google API request failed with status ${response.statusCode}.');
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final status = json['status'] as String?;
    if (status != null && status != 'OK' && status != 'ZERO_RESULTS') {
      final errorMessage = json['error_message'] as String?;
      throw StateError(errorMessage ?? 'Google API request failed with status $status.');
    }
    return json;
  }
}
