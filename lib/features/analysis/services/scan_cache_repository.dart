import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../radar/models/scout_lead.dart';
import '../../radar/models/scout_scan_result.dart';
import '../../setup/models/scout_setup_request.dart';

class ScanCacheRepository {
  ScanCacheRepository._();

  static final ScanCacheRepository instance = ScanCacheRepository._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUid => _auth.currentUser?.uid;

  String _cacheDocId(ScoutSetupRequest request) {
    final keyParts = [
      request.country,
      request.locationLabel,
      ...request.categories,
      ...request.digitalGaps,
    ];
    return keyParts.join('|').toLowerCase();
  }

  Future<void> saveScan(ScoutScanResult result) async {
    final uid = currentUid;
    if (uid == null) return;

    final cacheId = _cacheDocId(result.request);

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('scanCache')
        .doc(cacheId)
        .set({
      'cacheKey': cacheId,
      'country': result.request.country,
      'location': result.request.location,
      'categories': result.request.categories,
      'digitalGaps': result.request.digitalGaps,
      'centerLat': result.center.latitude,
      'centerLng': result.center.longitude,
      'checkedBusinesses': result.checkedBusinesses,
      'leads': result.leads.map(_encodeLead).toList(),
      'cachedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<ScoutScanResult?> loadScan(ScoutSetupRequest request) async {
    final uid = currentUid;
    if (uid == null) return null;

    final cacheId = _cacheDocId(request);

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('scanCache')
          .doc(cacheId)
          .get();

      final data = snapshot.data();
      if (data == null) return null;

      final cachedAt = data['cachedAt'];
      if (cachedAt is Timestamp) {
        final age = DateTime.now().difference(cachedAt.toDate());
        if (age.inHours > 24) {
          await _firestore
              .collection('users')
              .doc(uid)
              .collection('scanCache')
              .doc(cacheId)
              .delete();
          return null;
        }
      }

      final leads = (data['leads'] as List<dynamic>?) ?? const [];
      return ScoutScanResult(
        request: ScoutSetupRequest(
          country: data['country'] as String? ?? 'Nigeria',
          location: data['location'] as String? ?? '',
          categories: ((data['categories'] as List<dynamic>?) ?? const [])
              .whereType<String>()
              .toList(),
          digitalGaps: ((data['digitalGaps'] as List<dynamic>?) ?? const [])
              .whereType<String>()
              .toList(),
        ),
        center: LatLng(
          (data['centerLat'] as num?)?.toDouble() ?? 0,
          (data['centerLng'] as num?)?.toDouble() ?? 0,
        ),
        leads: (leads as List<Map<String, dynamic>>)
            .map(_decodeLead)
            .toList(),
        checkedBusinesses: (data['checkedBusinesses'] as num?)?.toInt() ?? 0,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> clearScanCache(ScoutSetupRequest request) async {
    final uid = currentUid;
    if (uid == null) return;

    final cacheId = _cacheDocId(request);

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('scanCache')
        .doc(cacheId)
        .delete();
  }

  Map<String, dynamic> _encodeLead(ScoutLead lead) {
    return {
      'placeId': lead.placeId,
      'name': lead.name,
      'address': lead.address,
      'sourceCountry': lead.sourceCountry,
      'lat': lead.position.latitude,
      'lng': lead.position.longitude,
      'category': lead.category,
      'selectedCategory': lead.selectedCategory,
      'rating': lead.rating,
      'userRatingsTotal': lead.userRatingsTotal,
      'hasWebsite': lead.hasWebsite,
      'website': lead.website,
      'photoCount': lead.photoCount,
      'photoReferences': lead.photoReferences,
      'phoneNumber': lead.phoneNumber,
      'businessStatus': lead.businessStatus,
      'matchedGaps': lead.matchedGaps.toList(),
    };
  }

  ScoutLead _decodeLead(Map<String, dynamic> data) {
    return ScoutLead(
      placeId: data['placeId'] as String,
      name: data['name'] as String,
      address: data['address'] as String,
      sourceCountry: data['sourceCountry'] as String,
      position: LatLng(
        (data['lat'] as num?)?.toDouble() ?? 0,
        (data['lng'] as num?)?.toDouble() ?? 0,
      ),
      category: data['category'] as String,
      selectedCategory: data['selectedCategory'] as String,
      rating: (data['rating'] as num?)?.toDouble(),
      userRatingsTotal: (data['userRatingsTotal'] as num?)?.toInt() ?? 0,
      hasWebsite: data['hasWebsite'] as bool? ?? false,
      website: data['website'] as String?,
      photoCount: (data['photoCount'] as num?)?.toInt() ?? 0,
      photoReferences: ((data['photoReferences'] as List<dynamic>?) ?? const [])
          .whereType<String>()
          .toList(),
      phoneNumber: data['phoneNumber'] as String?,
      businessStatus: data['businessStatus'] as String?,
      matchedGaps: ((data['matchedGaps'] as List<dynamic>?) ?? const [])
          .whereType<String>()
          .toSet(),
    );
  }
}
