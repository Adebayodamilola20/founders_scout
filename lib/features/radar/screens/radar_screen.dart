import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:founders_scout/features/leads/screens/lead_feed_screen.dart';
import 'package:founders_scout/features/leads/screens/lead_detail_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../auth/models/app_user_profile.dart';
import '../models/scout_lead.dart';
import '../models/scout_scan_result.dart';
import '../services/geofence_service.dart';

class RadarScreen extends StatefulWidget {
  final ScoutScanResult? scanResult;
  final AppUserProfile? userProfile;
  final VoidCallback? onOpenLeads;

  const RadarScreen({super.key, this.scanResult, this.userProfile, this.onOpenLeads});

  @override
  State<RadarScreen> createState() => _RadarScreenState();
}

class _RadarScreenState extends State<RadarScreen>
    with SingleTickerProviderStateMixin {
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

  static const LatLng _fallbackCenter = LatLng(6.4541, 3.3947);

  late final AnimationController _controller;
  GoogleMapController? _mapController;
  Map<String, BitmapDescriptor> _markerIcons = const {};
  Map<String, BitmapDescriptor> _focusedMarkerIcons = const {};
  Set<Marker> _markers = const {};
  String? _focusedLeadId;
  bool _showSummaryMetrics = false;
  Timer? _summaryRevealTimer;

  List<ScoutLead> get _activeLeads =>
      widget.scanResult?.leads.isNotEmpty == true
      ? widget.scanResult!.leads
      : _fallbackLeads;

  LatLng get _mapCenter => widget.scanResult?.center ?? _fallbackCenter;
  String get _locationLabel =>
      widget.scanResult?.request.locationLabel ??
      (widget.userProfile == null
          ? 'Lagos Island, Nigeria'
          : '${widget.userProfile!.selectedLocation}, ${widget.userProfile!.selectedCountry}');

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 1800),
          )..repeat();
    _primeMarkerIcons();
    _scheduleSummaryReveal();
    _checkNearbyLeads();
  }

  Future<void> _checkNearbyLeads() async {
    if (widget.scanResult == null) return;
    await GeofenceService.instance.checkAndNotifyNearbyLeads(
      allLeads: _activeLeads,
      userLocation: _mapCenter,
    );
  }

  @override
  void didUpdateWidget(covariant RadarScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scanResult != widget.scanResult) {
      _focusedLeadId = null;
      _primeMarkerIcons();
      _scheduleSummaryReveal();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _summaryRevealTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  void _scheduleSummaryReveal() {
    _summaryRevealTimer?.cancel();

    if (_showSummaryMetrics && mounted) {
      setState(() {
        _showSummaryMetrics = false;
      });
    } else {
      _showSummaryMetrics = false;
    }

    _summaryRevealTimer = Timer(const Duration(seconds: 6), () {
      if (!mounted) {
        return;
      }
      setState(() {
        _showSummaryMetrics = true;
      });
    });
  }

  Future<void> _primeMarkerIcons() async {
    final categoryKeys = _activeLeads
        .map(_markerKeyForLead)
        .toSet()
        .toList(growable: false);

    final regularEntries = await Future.wait(
      categoryKeys.map((key) async {
        return MapEntry(
          key,
          await _createMarkerIcon(
            icon: _iconForCategoryKey(key),
            accentColor: _markerColorForCategoryKey(key),
            isFocused: false,
          ),
        );
      }),
    );
    final focusedEntries = await Future.wait(
      categoryKeys.map((key) async {
        return MapEntry(
          key,
          await _createMarkerIcon(
            icon: _iconForCategoryKey(key),
            accentColor: _markerColorForCategoryKey(key),
            isFocused: true,
          ),
        );
      }),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _markerIcons = Map<String, BitmapDescriptor>.fromEntries(regularEntries);
      _focusedMarkerIcons = Map<String, BitmapDescriptor>.fromEntries(focusedEntries);
    });
    _rebuildMarkers();
  }

  Future<BitmapDescriptor> _createMarkerIcon({
    required IconData icon,
    required Color accentColor,
    required bool isFocused,
  }) async {
    final canvasSize = isFocused ? 170.0 : 150.0;
    final badgeSize = isFocused ? 68.0 : 56.0;
    final iconSize = isFocused ? 34.0 : 28.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final center = Offset(canvasSize / 2, isFocused ? 58 : 52);

    final shadowPaint = Paint()
      ..color = accentColor.withValues(alpha: isFocused ? 0.22 : 0.14)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, isFocused ? 36 : 28, shadowPaint);

    final badgeRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: badgeSize, height: badgeSize),
      Radius.circular(isFocused ? 23 : 20),
    );

    canvas.drawRRect(badgeRect, Paint()..color = accentColor);
    canvas.drawRRect(
      badgeRect,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isFocused ? 3 : 2.4,
    );

    final tailPath = Path()
      ..moveTo(center.dx - 12, center.dy + (badgeSize / 2) - 2)
      ..lineTo(center.dx + 12, center.dy + (badgeSize / 2) - 2)
      ..lineTo(center.dx, center.dy + (badgeSize / 2) + 24)
      ..close();
    canvas.drawPath(tailPath, Paint()..color = accentColor);

    final textPainter = TextPainter(textDirection: TextDirection.ltr)
      ..text = TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: iconSize,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: Colors.white,
        ),
      )
      ..layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - (textPainter.width / 2),
        center.dy - (textPainter.height / 2),
      ),
    );

    final image = await recorder.endRecording().toImage(
      canvasSize.toInt(),
      canvasSize.toInt(),
    );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
  }

  void _rebuildMarkers() {
    if (_markerIcons.isEmpty) {
      return;
    }

    final nextMarkers = _activeLeads.map((lead) {
      final markerKey = _markerKeyForLead(lead);
      final isFocused = _focusedLeadId == lead.placeId;
      final regularIcon = _markerIcons[markerKey];
      final focusedIcon = _focusedMarkerIcons[markerKey] ?? regularIcon;

      return Marker(
        markerId: MarkerId(lead.placeId),
        position: lead.position,
        anchor: const Offset(0.5, 0.88),
        zIndexInt: isFocused ? 3 : (lead.hasMediaDeficit ? 2 : 1),
        icon: isFocused ? focusedIcon! : regularIcon!,
        infoWindow: InfoWindow(
          title: lead.name,
          snippet: lead.selectedCategory,
        ),
        onTap: () {
          _focusLead(lead);
        },
      );
    }).toSet();

    if (!mounted) {
      return;
    }

    setState(() {
      _markers = nextMarkers;
    });
  }

  String _markerKeyForLead(ScoutLead lead) {
    return '${lead.selectedCategory}|${lead.category}'.toLowerCase();
  }

  IconData _iconForCategoryKey(String key) {
    if (key.contains('restaurant') ||
        key.contains('food') ||
        key.contains('dining') ||
        key.contains('bar') ||
        key.contains('nightclub')) {
      return Icons.restaurant_rounded;
    }
    if (key.contains('gym') ||
        key.contains('fitness') ||
        key.contains('yoga') ||
        key.contains('pilates') ||
        key.contains('trainer') ||
        key.contains('mma') ||
        key.contains('boxing')) {
      return Icons.fitness_center_rounded;
    }
    if (key.contains('fashion') || key.contains('retail')) {
      return Icons.shopping_bag_rounded;
    }
    if (key.contains('health')) {
      return Icons.local_hospital_rounded;
    }
    if (key.contains('tech')) {
      return Icons.memory_rounded;
    }
    if (key.contains('wedding') || key.contains('venue')) {
      return Icons.celebration_rounded;
    }
    if (key.contains('real estate')) {
      return Icons.apartment_rounded;
    }
    if (key.contains('car')) {
      return Icons.directions_car_filled_rounded;
    }
    return Icons.storefront_rounded;
  }

  Color _markerColorForCategoryKey(String key) {
    if (key.contains('restaurant') ||
        key.contains('food') ||
        key.contains('dining') ||
        key.contains('bar') ||
        key.contains('nightclub')) {
      return const Color(0xFFF5533D);
    }
    if (key.contains('gym') ||
        key.contains('fitness') ||
        key.contains('yoga') ||
        key.contains('pilates') ||
        key.contains('trainer') ||
        key.contains('mma') ||
        key.contains('boxing')) {
      return const Color(0xFF0D8CF1);
    }
    if (key.contains('fashion') || key.contains('retail')) {
      return const Color(0xFF8B5CF6);
    }
    if (key.contains('health')) {
      return const Color(0xFF22C55E);
    }
    if (key.contains('tech')) {
      return const Color(0xFF111827);
    }
    if (key.contains('wedding') || key.contains('venue')) {
      return const Color(0xFFE879F9);
    }
    if (key.contains('real estate')) {
      return const Color(0xFFF59E0B);
    }
    if (key.contains('car')) {
      return const Color(0xFF334155);
    }
    return const Color(0xFF1F2937);
  }

  Future<void> _focusLead(ScoutLead lead) async {
    if (_focusedLeadId != lead.placeId) {
      _focusedLeadId = lead.placeId;
      _rebuildMarkers();
    }

    final controller = _mapController;
    if (controller == null) {
      return;
    }

    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: lead.position, zoom: 12.4),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 260));
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: lead.position, zoom: 16.6),
      ),
    );
  }

  Future<void> _onMapCreated(GoogleMapController controller) async {
    _mapController = controller;
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: _mapCenter, zoom: 13.8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pulse =
        0.88 + (0.12 * math.sin(_controller.value * math.pi * 2).abs());
    final totalLeads = _activeLeads.length;
    final highLeads = _activeLeads
        .where((lead) => lead.ratingTier == LeadRatingTier.high)
        .toList();
    final mediumLeads = _activeLeads
        .where((lead) => lead.ratingTier == LeadRatingTier.medium)
        .toList();
    final lowLeads = _activeLeads
        .where((lead) => lead.ratingTier == LeadRatingTier.low)
        .toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _mapCenter,
                zoom: 13.8,
              ),
              onMapCreated: _onMapCreated,
              markers: _markers,
              mapType: MapType.normal,
              zoomControlsEnabled: false,
              myLocationButtonEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: false,
              tiltGesturesEnabled: false,
              indoorViewEnabled: false,
              buildingsEnabled: true,
              trafficEnabled: false,
            ),
          ),
          SafeArea(
            child: Stack(
              children: [
                Positioned(
                  top: 12,
                  left: 14,
                  right: 14,
                  child: _LocationHeaderCard(
                    pulse: pulse,
                    locationLabel: _locationLabel,
                  ),
                ),
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 18,
                  child: _LeadSummaryCard(
                    pulse: pulse,
                    isLoading: !_showSummaryMetrics,
                    totalLeads: totalLeads,
                    highLeads: highLeads,
                    mediumLeads: mediumLeads,
                    lowLeads: lowLeads,
                    onLeadSelected: _focusLead,
                    onCheckoutLead: (lead) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => LeadDetailScreen(lead: lead),
                        ),
                      );
                    },
                    onSeeAll: () {
                      if (widget.onOpenLeads != null) {
                        widget.onOpenLeads!();
                        return;
                      }
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => LeadFeedScreen(scanResult: widget.scanResult),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationHeaderCard extends StatelessWidget {
  final double pulse;
  final String locationLabel;

  const _LocationHeaderCard({required this.pulse, required this.locationLabel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              locationLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 21,
                height: 1,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFF4F3F7),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Center(
              child: Opacity(
                opacity: pulse,
                child: const Icon(
                  Icons.near_me_rounded,
                  color: Color(0xFFD1CFD5),
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LeadSummaryCard extends StatelessWidget {
  final double pulse;
  final bool isLoading;
  final int totalLeads;
  final List<ScoutLead> highLeads;
  final List<ScoutLead> mediumLeads;
  final List<ScoutLead> lowLeads;
  final ValueChanged<ScoutLead> onLeadSelected;
  final ValueChanged<ScoutLead> onCheckoutLead;
  final VoidCallback onSeeAll;

  const _LeadSummaryCard({
    required this.pulse,
    required this.isLoading,
    required this.totalLeads,
    required this.highLeads,
    required this.mediumLeads,
    required this.lowLeads,
    required this.onLeadSelected,
    required this.onCheckoutLead,
    required this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: Color(0x16000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: isLoading
                    ? const _ShimmerBlock(
                        height: 24,
                        width: 190,
                        radius: 12,
                      )
                    : Text(
                        '$totalLeads leads found',
                        style: const TextStyle(
                          color: Color(0xFF1F1F1F),
                          fontSize: 24,
                          height: 1,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
              ),
              Opacity(
                opacity: isLoading ? 0.5 : pulse,
                child: TextButton(
                  onPressed: onSeeAll,
                  child: const Text(
                    'See all →',
                    style: TextStyle(
                      color: Color(0xFF6571FF),
                      fontSize: 16,
                      height: 1,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: isLoading
                    ? const _MetricStatSkeleton()
                    : _MetricStatButton(
                        count: '${highLeads.length}',
                        subtitle: 'High value',
                        textColor: const Color(0xFFFF5555),
                        onTap: () => _showTierSheet(
                          context,
                          title: 'High value places',
                          leads: highLeads,
                          accent: const Color(0xFFFF5555),
                          onLeadSelected: onLeadSelected,
                          onCheckoutLead: onCheckoutLead,
                        ),
                      ),
              ),
              const _MetricDivider(),
              Expanded(
                child: isLoading
                    ? const _MetricStatSkeleton()
                    : _MetricStatButton(
                        count: '${mediumLeads.length}',
                        subtitle: 'Medium',
                        textColor: const Color(0xFFE18D00),
                        onTap: () => _showTierSheet(
                          context,
                          title: 'Medium places',
                          leads: mediumLeads,
                          accent: const Color(0xFFE18D00),
                          onLeadSelected: onLeadSelected,
                          onCheckoutLead: onCheckoutLead,
                        ),
                      ),
              ),
              const _MetricDivider(),
              Expanded(
                child: isLoading
                    ? const _MetricStatSkeleton()
                    : _MetricStatButton(
                        count: '${lowLeads.length}',
                        subtitle: 'Low gap',
                        textColor: const Color(0xFF20A255),
                        onTap: () => _showTierSheet(
                          context,
                          title: 'Low gap places',
                          leads: lowLeads,
                          accent: const Color(0xFF20A255),
                          onLeadSelected: onLeadSelected,
                          onCheckoutLead: onCheckoutLead,
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showTierSheet(
    BuildContext context, {
    required String title,
    required List<ScoutLead> leads,
    required Color accent,
    required ValueChanged<ScoutLead> onLeadSelected,
    required ValueChanged<ScoutLead> onCheckoutLead,
  }) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.52,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5E5E2),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Text(
                        '${leads.length}',
                        style: TextStyle(
                          color: accent,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: leads.isEmpty
                        ? const Center(
                            child: Text(
                              'No leads in this bucket yet.',
                              style: TextStyle(
                                color: Color(0xFF7A7A7A),
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          )
                        : ListView.separated(
                            itemCount: leads.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final lead = leads[index];
                              final problems = lead.matchedGaps.join(', ');
                              return GestureDetector(
                                onTap: () {
                                  Navigator.of(context).pop();
                                  onLeadSelected(lead);
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF7F7F4),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  lead.name,
                                                  style: const TextStyle(
                                                    color: Colors.black,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w900,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  lead.selectedCategory,
                                                  style: TextStyle(
                                                    color: accent,
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  problems.isEmpty
                                                      ? 'No clear issue'
                                                      : problems,
                                                  textAlign: TextAlign.right,
                                                  style: const TextStyle(
                                                    color: Color(0xFF666666),
                                                    fontSize: 13,
                                                    height: 1.35,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                                const SizedBox(height: 12),
                                                ElevatedButton(
                                                  onPressed: () {
                                                    Navigator.of(context)
                                                        .pop();
                                                    onCheckoutLead(lead);
                                                  },
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        Colors.black,
                                                    foregroundColor:
                                                        Colors.white,
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                        14,
                                                      ),
                                                    ),
                                                    elevation: 0,
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 20,
                                                      vertical: 10,
                                                    ),
                                                  ),
                                                  child: const Text(
                                                    'Check out',
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w900,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MetricStatSkeleton extends StatelessWidget {
  const _MetricStatSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ShimmerBlock(height: 28, width: 34, radius: 10),
        SizedBox(height: 8),
        _ShimmerBlock(height: 12, width: 66, radius: 8),
      ],
    );
  }
}

class _ShimmerBlock extends StatefulWidget {
  final double height;
  final double width;
  final double radius;

  const _ShimmerBlock({
    required this.height,
    required this.width,
    required this.radius,
  });

  @override
  State<_ShimmerBlock> createState() => _ShimmerBlockState();
}

class _ShimmerBlockState extends State<_ShimmerBlock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final start = -1.2 + (_controller.value * 2.4);
        return Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(start, 0),
              end: Alignment(start + 1.2, 0),
              colors: const [
                Color(0xFFECECE8),
                Color(0xFFF7F7F4),
                Color(0xFFE7E7E2),
              ],
              stops: const [0, 0.5, 1],
            ),
          ),
        );
      },
    );
  }
}

class _MetricStatButton extends StatelessWidget {
  final String count;
  final String subtitle;
  final Color textColor;
  final VoidCallback onTap;

  const _MetricStatButton({
    required this.count,
    required this.subtitle,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          decoration: BoxDecoration(
            color: textColor.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                count,
                style: TextStyle(
                  color: textColor,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF6D6D6D),
                  fontSize: 14,
                  height: 1.1,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricDivider extends StatelessWidget {
  const _MetricDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 42,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: const Color(0x16000000),
    );
  }
}
