import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../features/setup/models/scout_setup_request.dart';
import 'scout_lead.dart';

class ScoutScanResult {
  final ScoutSetupRequest request;
  final LatLng center;
  final List<ScoutLead> leads;
  final int checkedBusinesses;

  const ScoutScanResult({
    required this.request,
    required this.center,
    required this.leads,
    required this.checkedBusinesses,
  });

  int get totalLeads => leads.length;

  List<String> get selectedCategories => request.categories;

  int countForTier(LeadRatingTier tier) {
    return leads.where((lead) => lead.ratingTier == tier).length;
  }

  int countForCategory(String category) {
    return leads.where((lead) => lead.selectedCategory == category).length;
  }

  List<ScoutLead> leadsForCategory(String? category) {
    if (category == null) {
      return leads;
    }
    return leads.where((lead) => lead.selectedCategory == category).toList();
  }
}
