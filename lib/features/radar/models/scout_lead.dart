import 'package:google_maps_flutter/google_maps_flutter.dart';

enum LeadRatingTier { high, medium, low }

class ScoutLead {
  final String placeId;
  final String name;
  final String address;
  final String sourceCountry;
  final LatLng position;
  final String category;
  final String selectedCategory;
  final double? rating;
  final int userRatingsTotal;
  final bool hasWebsite;
  final String? website;
  final int photoCount;
  final List<String> photoReferences;
  final String? phoneNumber;
  final String? businessStatus;
  final Set<String> matchedGaps;

  const ScoutLead({
    required this.placeId,
    required this.name,
    required this.address,
    required this.sourceCountry,
    required this.position,
    required this.category,
    required this.selectedCategory,
    required this.rating,
    required this.userRatingsTotal,
    required this.hasWebsite,
    required this.website,
    required this.photoCount,
    required this.photoReferences,
    required this.phoneNumber,
    required this.businessStatus,
    required this.matchedGaps,
  });

  bool get hasMediaDeficit => matchedGaps.contains('Media Deficit');
  bool get hasRatings => userRatingsTotal > 0 && rating != null;

  LeadRatingTier get ratingTier {
    if (matchedGaps.length >= 3) {
      return LeadRatingTier.high;
    }
    if (matchedGaps.length >= 2) {
      return LeadRatingTier.medium;
    }
    return LeadRatingTier.low;
  }

  String get ratingSnippet {
    if (!hasRatings) {
      return 'No reviews yet';
    }
    return '${rating!.toStringAsFixed(1)} stars from $userRatingsTotal reviews';
  }
}
