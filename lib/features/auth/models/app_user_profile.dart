import 'package:cloud_firestore/cloud_firestore.dart';

import '../../setup/models/scout_setup_request.dart';

class AppUserProfile {
  final String uid;
  final String email;
  final String fullName;
  final String homeCity;
  final String selectedCountry;
  final String selectedLocation;
  final List<String> selectedCategories;
  final List<String> selectedDigitalGaps;
  final int contactedCount;
  final int repliedCount;
  final int closedCount;
  final DateTime? joinedAt;
  final DateTime? updatedAt;

  const AppUserProfile({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.homeCity,
    required this.selectedCountry,
    required this.selectedLocation,
    required this.selectedCategories,
    required this.selectedDigitalGaps,
    required this.contactedCount,
    required this.repliedCount,
    required this.closedCount,
    required this.joinedAt,
    required this.updatedAt,
  });

  factory AppUserProfile.fromFirestore(
    String uid,
    Map<String, dynamic> json,
  ) {
    final stats = (json['stats'] as Map<String, dynamic>?) ?? const {};
    return AppUserProfile(
      uid: uid,
      email: json['email'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      homeCity: json['homeCity'] as String? ?? '',
      selectedCountry: json['selectedCountry'] as String? ?? 'Nigeria',
      selectedLocation: json['selectedLocation'] as String? ?? 'Lagos Island',
      selectedCategories:
          ((json['selectedCategories'] as List<dynamic>?) ?? const [])
              .whereType<String>()
              .toList(),
      selectedDigitalGaps:
          ((json['selectedDigitalGaps'] as List<dynamic>?) ?? const [])
              .whereType<String>()
              .toList(),
      contactedCount: (stats['contactedCount'] as num?)?.toInt() ?? 0,
      repliedCount: (stats['repliedCount'] as num?)?.toInt() ?? 0,
      closedCount: (stats['closedCount'] as num?)?.toInt() ?? 0,
      joinedAt: _readDate(json['joinedAt']),
      updatedAt: _readDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'fullName': fullName,
      'homeCity': homeCity,
      'selectedCountry': selectedCountry,
      'selectedLocation': selectedLocation,
      'selectedCategories': selectedCategories,
      'selectedDigitalGaps': selectedDigitalGaps,
      'stats': {
        'contactedCount': contactedCount,
        'repliedCount': repliedCount,
        'closedCount': closedCount,
      },
      'joinedAt': joinedAt == null ? FieldValue.serverTimestamp() : Timestamp.fromDate(joinedAt!),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  AppUserProfile copyWith({
    String? email,
    String? fullName,
    String? homeCity,
    String? selectedCountry,
    String? selectedLocation,
    List<String>? selectedCategories,
    List<String>? selectedDigitalGaps,
    int? contactedCount,
    int? repliedCount,
    int? closedCount,
    DateTime? joinedAt,
    DateTime? updatedAt,
  }) {
    return AppUserProfile(
      uid: uid,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      homeCity: homeCity ?? this.homeCity,
      selectedCountry: selectedCountry ?? this.selectedCountry,
      selectedLocation: selectedLocation ?? this.selectedLocation,
      selectedCategories: selectedCategories ?? this.selectedCategories,
      selectedDigitalGaps: selectedDigitalGaps ?? this.selectedDigitalGaps,
      contactedCount: contactedCount ?? this.contactedCount,
      repliedCount: repliedCount ?? this.repliedCount,
      closedCount: closedCount ?? this.closedCount,
      joinedAt: joinedAt ?? this.joinedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get hasCompletedPreferences =>
      selectedCategories.isNotEmpty && selectedDigitalGaps.isNotEmpty && selectedLocation.trim().isNotEmpty;

  ScoutSetupRequest get setupRequest => ScoutSetupRequest(
        country: selectedCountry,
        location: selectedLocation,
        categories: selectedCategories,
        digitalGaps: selectedDigitalGaps,
      );

  static DateTime? _readDate(dynamic raw) {
    if (raw is Timestamp) {
      return raw.toDate();
    }
    return null;
  }
}
