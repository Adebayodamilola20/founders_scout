import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../auth/models/app_user_profile.dart';
import '../models/lead_outreach_state.dart';
import '../services/outreach_tracker_service.dart';
import '../../radar/models/scout_lead.dart';
import '../../radar/models/scout_scan_result.dart';
import 'lead_detail_screen.dart';
import '../widgets/google_place_photo.dart';

enum _ViewMode { list, grid }

class LeadFeedScreen extends StatefulWidget {
  final ScoutScanResult? scanResult;
  final AppUserProfile? userProfile;

  const LeadFeedScreen({
    super.key,
    this.scanResult,
    this.userProfile,
  });

  @override
  State<LeadFeedScreen> createState() => _LeadFeedScreenState();
}

class _LeadFeedScreenState extends State<LeadFeedScreen> {
  static const List<ScoutLead> _fallbackLeads = [
    ScoutLead(
      placeId: 'mama-titi',
      name: 'Mama Titi',
      address: 'Lagos Island, Nigeria',
      sourceCountry: 'Nigeria',
      position: LatLng(6.4582, 3.3899),
      category: 'restaurant',
      selectedCategory: 'Restaurant',
      rating: 4.5,
      userRatingsTotal: 42,
      hasWebsite: false,
      website: null,
      photoCount: 0,
      photoReferences: [],
      phoneNumber: null,
      businessStatus: 'OPERATIONAL',
      matchedGaps: {'Media Deficit', 'Platform Missing'},
    ),
    ScoutLead(
      placeId: 'adunni-f',
      name: 'Adunni Fitness',
      address: 'Lagos Island, Nigeria',
      sourceCountry: 'Nigeria',
      position: LatLng(6.4525, 3.4018),
      category: 'gym',
      selectedCategory: 'Gym',
      rating: 4.1,
      userRatingsTotal: 16,
      hasWebsite: true,
      website: 'https://example.com',
      photoCount: 0,
      photoReferences: [],
      phoneNumber: null,
      businessStatus: 'OPERATIONAL',
      matchedGaps: {'Social Proof Gap'},
    ),
    ScoutLead(
      placeId: 'balogun-t',
      name: 'Balogun Table',
      address: 'Lagos Island, Nigeria',
      sourceCountry: 'Nigeria',
      position: LatLng(6.4487, 3.3988),
      category: 'restaurant',
      selectedCategory: 'Restaurant',
      rating: 3.4,
      userRatingsTotal: 5,
      hasWebsite: false,
      website: null,
      photoCount: 0,
      photoReferences: [],
      phoneNumber: null,
      businessStatus: 'OPERATIONAL',
      matchedGaps: {'Media Deficit', 'Social Proof Gap', 'Platform Missing'},
    ),
  ];

  static const List<String> _fallbackCategories = ['Restaurant', 'Gym'];
  String? _activeCategory;
  _ViewMode _viewMode = _ViewMode.list;

  List<ScoutLead> get _allLeads =>
      widget.scanResult?.leads.isNotEmpty == true ? widget.scanResult!.leads : _fallbackLeads;

  List<String> get _selectedCategories =>
      widget.scanResult?.selectedCategories.isNotEmpty == true
          ? widget.scanResult!.selectedCategories
          : _fallbackCategories;

  List<ScoutLead> get _visibleLeads {
    if (_activeCategory == null) {
      return _allLeads;
    }
    return _allLeads.where((lead) => lead.selectedCategory == _activeCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    final locationLabel = widget.scanResult?.request.locationLabel ??
        (widget.userProfile == null
            ? 'Lagos Island, Nigeria'
            : '${widget.userProfile!.selectedLocation}, ${widget.userProfile!.selectedCountry}');

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Lead Feed',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  PopupMenuButton<_ViewMode>(
                    icon: const Icon(Icons.view_agenda_rounded, color: Colors.black, size: 24),
                    offset: const Offset(0, 40),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    onSelected: (mode) => setState(() => _viewMode = mode),
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: _ViewMode.list,
                        child: Row(
                          children: [
                            Icon(Icons.view_list_rounded, size: 18),
                            SizedBox(width: 10),
                            Text('List'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: _ViewMode.grid,
                        child: Row(
                          children: [
                            Icon(Icons.grid_on_rounded, size: 18),
                            SizedBox(width: 10),
                            Text('Grid'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                locationLabel,
                style: const TextStyle(
                  color: Color(0xFF7C7C7C),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 46,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _FilterChip(
                      label: 'All ${_allLeads.length}',
                      isSelected: _activeCategory == null,
                      onTap: () => setState(() => _activeCategory = null),
                    ),
                    ..._selectedCategories.map((category) {
                      final count = _allLeads.where((lead) => lead.selectedCategory == category).length;
                      return Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: _FilterChip(
                          label: '$category ($count)',
                          isSelected: _activeCategory == category,
                          onTap: () => setState(() => _activeCategory = category),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: _visibleLeads.isEmpty
                    ? const Center(
                        child: Text(
                          "Couldn't find an establishment for this category in the selected area.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF7C7C7C),
                            fontSize: 15,
                            height: 1.45,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : _viewMode == _ViewMode.list
                        ? ListView.separated(
                            padding: const EdgeInsets.only(bottom: 20),
                            itemCount: _visibleLeads.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 14),
                            itemBuilder: (context, index) {
                              final lead = _visibleLeads[index];
                              return _LeadCard(
                                lead: lead,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => LeadDetailScreen(lead: lead),
                                    ),
                                  );
                                },
                              );
                            },
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.only(bottom: 20),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.78,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                            itemCount: _visibleLeads.length,
                            itemBuilder: (context, index) {
                              final lead = _visibleLeads[index];
                              return _GridLeadCard(
                                lead: lead,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => LeadDetailScreen(lead: lead),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : const Color(0xFFF3F3F0),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF5A5A5A),
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _LeadCard extends StatelessWidget {
  final ScoutLead lead;
  final VoidCallback onTap;

  const _LeadCard({
    required this.lead,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Map<String, LeadOutreachState>>(
      valueListenable: OutreachTrackerService.instance.states,
      builder: (context, _, __) {
        final state = OutreachTrackerService.instance.stateFor(lead.placeId);
        return GestureDetector(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x12000000),
                  blurRadius: 16,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                GooglePlacePhoto(
                  photoReferences: lead.photoReferences,
                  width: 114,
                  height: 114,
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(24)),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                lead.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _StageBadge(stage: state.stage),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          lead.selectedCategory,
                          style: const TextStyle(
                            color: Color(0xFF5E5E5E),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          lead.address,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF7A7A7A),
                            fontSize: 13,
                            height: 1.3,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(
                              Icons.star_rounded,
                              color: _ratingColor(lead.ratingTier),
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                lead.ratingSnippet,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF595959),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Color _ratingColor(LeadRatingTier tier) {
    switch (tier) {
      case LeadRatingTier.high:
        return const Color(0xFF1DA95C);
      case LeadRatingTier.medium:
        return const Color(0xFFE5A100);
      case LeadRatingTier.low:
        return const Color(0xFFFF5A5A);
    }
  }
}

class _StageBadge extends StatelessWidget {
  final LeadPipelineStage stage;

  const _StageBadge({
    required this.stage,
  });

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (stage) {
      LeadPipelineStage.fresh => ('New', const Color(0xFFF3F3F0), const Color(0xFF5B5B5B)),
      LeadPipelineStage.contacted => ('Contacted', const Color(0xFFE8F1FF), const Color(0xFF2667D0)),
      LeadPipelineStage.replied => ('Replied', const Color(0xFFEAF7EE), const Color(0xFF1D8C4D)),
      LeadPipelineStage.closed => ('Closed', const Color(0xFFFFF3D8), const Color(0xFFAF6A00)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _GridLeadCard extends StatelessWidget {
  final ScoutLead lead;
  final VoidCallback onTap;

  const _GridLeadCard({
    required this.lead,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Map<String, LeadOutreachState>>(
      valueListenable: OutreachTrackerService.instance.states,
      builder: (context, _, __) {
        final state = OutreachTrackerService.instance.stateFor(lead.placeId);
        return GestureDetector(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0E000000),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                  child: GooglePlacePhoto(
                    photoReferences: lead.photoReferences,
                    width: double.infinity,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                lead.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          lead.selectedCategory,
                          style: const TextStyle(
                            color: Color(0xFF5E5E5E),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.star_rounded,
                              color: _ratingColor(lead.ratingTier),
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                lead.ratingSnippet,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF595959),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        _StageBadge(stage: state.stage),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Color _ratingColor(LeadRatingTier tier) {
    switch (tier) {
      case LeadRatingTier.high:
        return const Color(0xFF1DA95C);
      case LeadRatingTier.medium:
        return const Color(0xFFE5A100);
      case LeadRatingTier.low:
        return const Color(0xFFFF5A5A);
    }
  }
}
