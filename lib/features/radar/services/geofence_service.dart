import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/services/notification_service.dart';
import '../models/scout_lead.dart';

class GeofenceService {
  GeofenceService._();

  static final GeofenceService instance = GeofenceService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUid => _auth.currentUser?.uid;

  static const double defaultRadiusMeters = 5000;

  double calculateDistance(LatLng point1, LatLng point2) {
    const earthRadius = 6371000;
    final lat1 = _degreesToRadians(point1.latitude);
    final lat2 = _degreesToRadians(point2.latitude);
    final deltaLat = _degreesToRadians(point2.latitude - point1.latitude);
    final deltaLon = _degreesToRadians(point2.longitude - point1.longitude);

    final a = sin(deltaLat / 2) * sin(deltaLat / 2) +
        cos(lat1) * cos(lat2) * sin(deltaLon / 2) * sin(deltaLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  List<ScoutLead> findLeadsWithinRadius({
    required List<ScoutLead> allLeads,
    required LatLng userLocation,
    double radiusMeters = defaultRadiusMeters,
  }) {
    return allLeads.where((lead) {
      final distance = calculateDistance(userLocation, lead.position);
      return distance <= radiusMeters;
    }).toList();
  }

  List<ScoutLead> findHighValueLeadsNearby({
    required List<ScoutLead> allLeads,
    required LatLng userLocation,
    double radiusMeters = defaultRadiusMeters,
  }) {
    final nearby = findLeadsWithinRadius(
      allLeads: allLeads,
      userLocation: userLocation,
      radiusMeters: radiusMeters,
    );

    return nearby.where((lead) {
      final score = _leadOpportunityScore(lead);
      return score >= 6;
    }).toList();
  }

  int _leadOpportunityScore(ScoutLead lead) {
    var score = 0;
    if (!lead.hasWebsite) score += 4;
    score += lead.matchedGaps.length * 3;
    if (lead.photoCount < 3) score += 2;
    if (!lead.hasRatings) score += 2;
    if (lead.phoneNumber != null && lead.phoneNumber!.trim().isNotEmpty) score += 1;
    return score;
  }

  Future<void> checkAndNotifyNearbyLeads({
    required List<ScoutLead> allLeads,
    required LatLng userLocation,
    double radiusMeters = defaultRadiusMeters,
  }) async {
    final uid = currentUid;
    if (uid == null) return;

    final nearbyHighValue = findHighValueLeadsNearby(
      allLeads: allLeads,
      userLocation: userLocation,
      radiusMeters: radiusMeters,
    );

    if (nearbyHighValue.isEmpty) return;

    final now = DateTime.now();
    final todayKey = '${now.year}-${now.month}-${now.day}';

    final lastNotifiedDoc = await _firestore
        .collection('users')
        .doc(uid)
        .collection('geofenceLog')
        .doc(todayKey)
        .get();

    if (lastNotifiedDoc.exists) {
      final data = lastNotifiedDoc.data();
      final lastNotified = (data?['leadIds'] as List<dynamic>? ?? [])
          .whereType<String>()
          .toSet();

      final newLeads = nearbyHighValue
          .where((lead) => !lastNotified.contains(lead.placeId))
          .toList();

      if (newLeads.isEmpty) return;

      await _notifyLeads(newLeads, userLocation);

      await _firestore
          .collection('users')
          .doc(uid)
          .collection('geofenceLog')
          .doc(todayKey)
          .set({
        'leadIds': [...lastNotified, ...newLeads.map((l) => l.placeId)],
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } else {
      await _notifyLeads(nearbyHighValue, userLocation);

      await _firestore
          .collection('users')
          .doc(uid)
          .collection('geofenceLog')
          .doc(todayKey)
          .set({
        'leadIds': nearbyHighValue.map((l) => l.placeId).toList(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> _notifyLeads(List<ScoutLead> leads, LatLng userLocation) async {
    if (leads.isEmpty) return;

    final topLead = leads.first;
    final distance = calculateDistance(userLocation, topLead.position);
    final distanceText = distance < 1000
        ? '${(distance / 1000).toStringAsFixed(1)}km'
        : '${distance.round()}m';

    final title = leads.length == 1
        ? 'High-value lead nearby!'
        : '${leads.length} high-value leads nearby!';

    await NotificationService.instance.showScanAlert(
      location: topLead.address,
      leadCount: leads.length,
    );
  }

  Future<void> saveGeofenceRadius(double radiusMeters) async {
    final uid = currentUid;
    if (uid == null) return;

    await _firestore
        .collection('users')
        .doc(uid)
        .set({
      'geofenceRadius': radiusMeters,
    }, SetOptions(merge: true));
  }

  Future<double> loadGeofenceRadius() async {
    final uid = currentUid;
    if (uid == null) return defaultRadiusMeters;

    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      final data = doc.data();
      return (data?['geofenceRadius'] as num?)?.toDouble() ?? defaultRadiusMeters;
    } catch (_) {
      return defaultRadiusMeters;
    }
  }
}
