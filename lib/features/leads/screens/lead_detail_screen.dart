import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../auth/services/user_profile_repository.dart';
import '../models/lead_outreach_state.dart';
import '../services/outreach_tracker_service.dart';
import '../../pitch/screens/pitch_generator_screen.dart';
import '../../radar/models/scout_lead.dart';
import '../widgets/google_place_photo.dart';

class LeadDetailScreen extends StatefulWidget {
  final ScoutLead lead;

  const LeadDetailScreen({
    super.key,
    required this.lead,
  });

  @override
  State<LeadDetailScreen> createState() => _LeadDetailScreenState();
}

class _LeadDetailScreenState extends State<LeadDetailScreen> {
  int _activePhotoIndex = 0;
  late final PageController _photoPageController;

  ScoutLead get lead => widget.lead;

  @override
  void initState() {
    super.initState();
    _photoPageController = PageController();
    _photoPageController.addListener(_onPhotoPageChanged);
  }

  @override
  void dispose() {
    _photoPageController.removeListener(_onPhotoPageChanged);
    _photoPageController.dispose();
    super.dispose();
  }

  void _onPhotoPageChanged() {
    if (_photoPageController.page != null &&
        _photoPageController.page!.round() != _activePhotoIndex) {
      setState(() {
        _activePhotoIndex = _photoPageController.page!.round();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auditTiles = _buildAuditTiles();
    final scoutInsight = _buildScoutInsight();

    return ValueListenableBuilder<Map<String, LeadOutreachState>>(
      valueListenable: OutreachTrackerService.instance.states,
      builder: (context, _, __) {
        final outreachState = OutreachTrackerService.instance.stateFor(
          lead.placeId,
        );

        return Scaffold(
          backgroundColor: const Color(0xFFF8F7F3),
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: const Color(0xFFF8F7F3),
                surfaceTintColor: const Color(0xFFF8F7F3),
                pinned: true,
                leading: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.black),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                expandedHeight: 336,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (lead.photoReferences.isNotEmpty)
                        PageView.builder(
                          controller: _photoPageController,
                          itemCount: lead.photoReferences.length,
                          itemBuilder: (context, index) {
                            return _PhotoSlideshow(
                              photoReference: lead.photoReferences[index],
                            );
                          },
                        )
                      else
                        const GooglePlacePhoto(
                          photoReferences: [],
                          fit: BoxFit.cover,
                        ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.04),
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.2),
                            ],
                          ),
                        ),
                      ),
                      if (lead.photoReferences.length > 1)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 18,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(lead.photoReferences.length, (index) {
                              final isActive = index == _activePhotoIndex;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                width: isActive ? 18 : 7,
                                height: 7,
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                  color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.46),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              );
                            }),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: const Offset(0, -18),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8F7F3),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 46,
                            height: 5,
                            margin: const EdgeInsets.only(bottom: 18),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD9D7D1),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          Text(
                            lead.name,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            lead.selectedCategory,
                            style: const TextStyle(
                              color: Color(0xFF6F6F6F),
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 18),
                          _PipelineStatusCard(
                            state: outreachState,
                            onStageSelected: (stage) {
                              OutreachTrackerService.instance.setStage(
                                lead.placeId,
                                stage,
                              );
                              UserProfileRepository.instance.recordOutreach(
                                lead: lead,
                                channel: 'Pipeline',
                                stage: stage.name,
                              );
                            },
                            onReplySelected: (replied) {
                              OutreachTrackerService.instance.setReplyState(
                                lead.placeId,
                                replied,
                              );
                              UserProfileRepository.instance.recordOutreach(
                                lead: lead,
                                channel: 'Pipeline',
                                stage: replied == true ? 'replied' : 'contacted',
                                replied: replied,
                              );
                              if (replied == true) {
                                UserProfileRepository.instance.incrementStat('repliedCount');
                              }
                            },
                            onFollowUpTap: _handleFollowUp,
                          ),
                          const SizedBox(height: 22),
                          SizedBox(
                            height: 98,
                            child: Row(
                              children: auditTiles
                                  .map(
                                    (tile) => Expanded(
                                      child: Padding(
                                        padding: EdgeInsets.only(
                                          right: tile == auditTiles.last ? 0 : 10,
                                        ),
                                        child: _AuditTile(tile: tile),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                          const SizedBox(height: 18),
                          _ScoutSaysCard(message: scoutInsight),
                          const SizedBox(height: 14),
                          _LeadIntelCard(lead: lead),
                          const SizedBox(height: 22),
                          Row(
                            children: [
                              Expanded(
                                child: _PrimaryActionButton(
                                  icon: Icons.chat_bubble_outline_rounded,
                                  label: 'Connect now',
                                  onTap: _handleConnectNow,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _SecondaryActionButton(
                                  icon: Icons.schedule_send_rounded,
                                  label: 'AI pitch idea',
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => PitchGeneratorScreen(
                                          lead: lead,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Scout Actions',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _ActionCircle(
                                icon: Icons.bookmark_border_rounded,
                                label: 'Save',
                                onTap: () async {
                                  await UserProfileRepository.instance.saveLead(lead);
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Saved to shortlist.')),
                                  );
                                },
                              ),
                              _ActionCircle(
                                icon: Icons.share_outlined,
                                label: 'Share',
                                onTap: _handleShare,
                              ),
                            ],
                          ),
                          const SizedBox(height: 26),
                          const Text(
                            'Business Snapshot',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 14),
                          _DetailCard(
                            children: [
                              _DetailRow(
                                icon: Icons.info_outline_rounded,
                                title: 'About',
                                value: _buildAboutSummary(),
                              ),
                              _DetailRow(
                                icon: Icons.rate_review_outlined,
                                title: 'Reputation',
                                value: lead.ratingSnippet,
                              ),
                              _DetailRow(
                                icon: Icons.search_off_rounded,
                                title: 'Detected gaps',
                                value: lead.matchedGaps.isEmpty
                                    ? 'No clear issue'
                                    : lead.matchedGaps.join(', '),
                                isLast: true,
                              ),
                            ],
                          ),
                          const SizedBox(height: 26),
                          const Text(
                            'Explore Online',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              _LinkChip(
                                label: 'Website',
                                onTap: () => _openWebsite(),
                              ),
                              _LinkChip(
                                label: 'Google Maps',
                                onTap: () => _openSearchLink(
                                  'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent('${lead.name} ${lead.address}')}',
                                ),
                              ),
                              _LinkChip(
                                label: 'Instagram',
                                onTap: () => _openSearchLink(
                                  'https://www.google.com/search?q=${Uri.encodeComponent('${lead.name} instagram ${lead.address}')}',
                                ),
                              ),
                              _LinkChip(
                                label: 'News',
                                onTap: () => _openSearchLink(
                                  'https://www.google.com/search?q=${Uri.encodeComponent('${lead.name} news ${lead.address}')}',
                                ),
                              ),
                              _LinkChip(
                                label: 'Menu',
                                onTap: () => _openSearchLink(
                                  'https://www.google.com/search?q=${Uri.encodeComponent('${lead.name} menu ${lead.address}')}',
                                ),
                              ),
                              _LinkChip(
                                label: 'About',
                                onTap: () => _openSearchLink(
                                  'https://www.google.com/search?q=${Uri.encodeComponent('${lead.name} about ${lead.address}')}',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 26),
                          const Text(
                            'Business Details',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 14),
                          _DetailCard(
                            children: [
                              _DetailRow(
                                icon: Icons.location_on_outlined,
                                title: 'Address',
                                value: lead.address,
                              ),
                              _DetailRow(
                                icon: Icons.phone_outlined,
                                title: 'Phone',
                                value: lead.phoneNumber ?? 'Not available',
                                onCopy: lead.phoneNumber != null
                                    ? () {
                                        Clipboard.setData(ClipboardData(text: lead.phoneNumber!));
                                        if (!mounted) return;
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: const Row(
                                              children: [
                                                Icon(Icons.check_rounded, color: Colors.white, size: 18),
                                                SizedBox(width: 8),
                                                Text('Phone number copied'),
                                              ],
                                            ),
                                            duration: const Duration(seconds: 1),
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          ),
                                        );
                                      }
                                    : null,
                              ),
                              _DetailRow(
                                icon: Icons.language_rounded,
                                title: 'Website / Email',
                                value: lead.website ?? 'Not available',
                              ),
                              _DetailRow(
                                icon: Icons.verified_outlined,
                                title: 'Claim Business',
                                value: lead.businessStatus ?? 'Unknown',
                                isLast: true,
                              ),
                            ],
                          ),
                          const SizedBox(height: 26),
                          const Text(
                            'Reviews',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 14),
                          _ReviewsCard(lead: lead),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleConnectNow() async {
    final whatsappPhone = _normalizeWhatsAppNumber(lead.phoneNumber);
    final callUri = _buildPhoneCallUri(lead.phoneNumber);
    if ((whatsappPhone == null || whatsappPhone.isEmpty) && callUri == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No phone number available for this lead.')),
      );
      return;
    }

    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                const SizedBox(height: 18),
                const Text(
                  'Choose how to contact this business',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'We found a phone number for ${lead.name}. Do you want to call now or continue on WhatsApp?',
                  style: const TextStyle(
                    color: Color(0xFF676767),
                    fontSize: 15,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _SheetButton(
                        label: 'Call now',
                        isPrimary: false,
                        onTap: callUri == null
                            ? null
                            : () => Navigator.of(context).pop('call'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SheetButton(
                        label: 'WhatsApp',
                        isPrimary: true,
                        onTap: whatsappPhone == null
                            ? null
                            : () => Navigator.of(context).pop('whatsapp'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (action == null) {
      return;
    }

    if (action == 'call') {
      if (callUri != null && await canLaunchUrl(callUri)) {
        OutreachTrackerService.instance.markContacted(
          lead.placeId,
          channel: 'Phone call',
        );
        UserProfileRepository.instance.recordOutreach(
          lead: lead,
          channel: 'Phone call',
          stage: 'contacted',
        );
        UserProfileRepository.instance.incrementStat('contactedCount');
        await launchUrl(callUri, mode: LaunchMode.externalApplication);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Lead moved to Contacted.')),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open the phone app on this device.')),
        );
      }
      return;
    }

    OutreachTrackerService.instance.markContacted(
      lead.placeId,
      channel: 'WhatsApp',
    );
    UserProfileRepository.instance.recordOutreach(
      lead: lead,
      channel: 'WhatsApp',
      stage: 'contacted',
    );
    UserProfileRepository.instance.incrementStat('contactedCount');
    final opener = _buildWhatsAppOpener();
    final whatsappUri = Uri.parse(
      'https://wa.me/$whatsappPhone?text=${Uri.encodeComponent(opener)}',
    );
    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lead moved to Contacted.')),
        );
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open WhatsApp on this device.')),
      );
    }
  }

  String? _normalizeWhatsAppNumber(String? rawPhone) {
    if (rawPhone == null || rawPhone.trim().isEmpty) {
      return null;
    }

    final countryCode = _dialingCodeForCountry(lead.sourceCountry);
    var digits = rawPhone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (digits.isEmpty) {
      return null;
    }

    if (digits.startsWith('+')) {
      digits = digits.substring(1);
    }

    if (digits.startsWith('00')) {
      digits = digits.substring(2);
    }

    if (countryCode != null && digits.startsWith(countryCode)) {
      return digits;
    }

    if (digits.startsWith('0') && countryCode != null) {
      return '$countryCode${digits.substring(1)}';
    }

    if (!digits.startsWith('0') && countryCode != null) {
      final localLength = _expectedLocalNumberLength(countryCode);
      if (localLength != null && digits.length == localLength) {
        return '$countryCode$digits';
      }
    }

    return digits;
  }

  String? _dialingCodeForCountry(String country) {
    switch (country) {
      case 'Nigeria':
        return '234';
      case 'Ghana':
        return '233';
      case 'Kenya':
        return '254';
      case 'South Africa':
        return '27';
      case 'United States':
      case 'Canada':
        return '1';
      case 'United Kingdom':
        return '44';
    }
    return null;
  }

  int? _expectedLocalNumberLength(String countryCode) {
    switch (countryCode) {
      case '1':
        return 10;
      case '27':
        return 9;
      case '44':
        return 10;
      case '233':
      case '234':
      case '254':
        return 10;
    }
    return null;
  }

  Uri? _buildPhoneCallUri(String? rawPhone) {
    final normalized = _normalizeWhatsAppNumber(rawPhone);
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return Uri.parse('tel:+$normalized');
  }

  String _buildWhatsAppOpener() {
    final serviceAngle = _primaryServiceAngle();
    return 'Hi ${lead.name}, I came across your business while checking local brands in ${lead.sourceCountry}. I noticed a clear gap around $serviceAngle and I already have a simple idea that could help. Want me to send it over?';
  }

  String _buildWhatsAppFollowUp() {
    final serviceAngle = _primaryServiceAngle();
    return 'Hi ${lead.name}, just following up here. I still have a practical idea for improving your $serviceAngle and bringing in more attention locally. Happy to send it if you are open to it.';
  }

  String _primaryServiceAngle() {
    if (lead.matchedGaps.isNotEmpty) {
      return lead.matchedGaps.first.toLowerCase();
    }
    if (!lead.hasWebsite) {
      return 'website visibility';
    }
    if (lead.photoCount < 3) {
      return 'visual content';
    }
    if (!lead.hasRatings || (lead.rating ?? 0) < 4.0) {
      return 'review presence';
    }
    return 'online presence';
  }

  Future<void> _handleShare() async {
    final details = [
      lead.name,
      lead.selectedCategory,
      lead.address,
      if (lead.phoneNumber != null) 'Phone: ${lead.phoneNumber}',
      if (lead.website != null) 'Website: ${lead.website}',
    ].join('\n');
    await Share.share(details);
  }

  Future<void> _openWebsite() async {
    if (lead.website == null || lead.website!.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No website available for this business.')),
      );
      return;
    }
    await _openSearchLink(lead.website!);
  }

  Future<void> _openSearchLink(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open this link right now.')),
      );
    }
  }

  Future<void> _handleFollowUp() async {
    final phone = _normalizeWhatsAppNumber(lead.phoneNumber);
    if (phone == null || phone.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No phone number available for follow-up.')),
      );
      return;
    }

    final followUp = _buildWhatsAppFollowUp();
    final whatsappUri = Uri.parse(
      'https://wa.me/$phone?text=${Uri.encodeComponent(followUp)}',
    );
    OutreachTrackerService.instance.markContacted(
      lead.placeId,
      channel: 'WhatsApp follow-up',
    );
    UserProfileRepository.instance.recordOutreach(
      lead: lead,
      channel: 'WhatsApp follow-up',
      stage: 'contacted',
    );
    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    }
  }

  List<_AuditTileData> _buildAuditTiles() {
    final websiteTile = _AuditTileData(
      label: 'Website',
      value: lead.hasWebsite ? 'Live' : 'None',
      valueColor: lead.hasWebsite ? const Color(0xFF1DA95C) : const Color(0xFFFF5A36),
    );

    final mediaTile = _AuditTileData(
      label: 'Media',
      value: lead.hasMediaDeficit ? 'Needs work' : '${lead.photoCount} photos',
      valueColor: lead.hasMediaDeficit ? const Color(0xFFFF9800) : const Color(0xFF1DA95C),
    );

    final socialProofTile = _AuditTileData(
      label: 'Social Proof',
      value: lead.matchedGaps.contains('Social Proof Gap') ? 'Weak' : 'Healthy',
      valueColor: lead.matchedGaps.contains('Social Proof Gap')
          ? const Color(0xFFFF9800)
          : const Color(0xFF1DA95C),
    );

    return [websiteTile, mediaTile, socialProofTile];
  }

  String _buildScoutInsight() {
    final gaps = lead.matchedGaps.toList()..sort();
    final selected = lead.selectedCategory.toLowerCase();
    final reviewText = lead.userRatingsTotal == 0 ? 'no reviews' : '${lead.userRatingsTotal} reviews';

    if (gaps.length >= 2) {
      return 'Scout found multiple openings here: ${gaps.join(', ')}. This $selected has enough visible gaps for a focused outreach pitch.';
    }
    if (!lead.hasWebsite && lead.userRatingsTotal <= 5) {
      return 'High opportunity. No website + $reviewText. This $selected is barely visible online and is a strong pitch candidate.';
    }
    if (lead.hasMediaDeficit) {
      return 'Scout says the visuals are underpowered. This $selected likely needs sharper media, better content formatting, and a stronger first impression.';
    }
    if (gaps.contains('Social Proof Gap')) {
      return 'This $selected has weak social proof. The review count and rating signal a reputation gap you can directly pitch around.';
    }
    if (gaps.isNotEmpty) {
      return 'Scout found a clear service angle here: ${gaps.join(', ')}. This lead should be approached with a focused, specific offer.';
    }
    return 'Moderate opportunity. This $selected still needs a deeper digital audit before outreach.';
  }

  String _buildAboutSummary() {
    final category = lead.selectedCategory;
    final websiteState = lead.hasWebsite ? 'has a live website' : 'does not show a website';
    final reviewState = lead.hasRatings
        ? 'currently has ${lead.rating!.toStringAsFixed(1)} stars from ${lead.userRatingsTotal} reviews'
        : 'currently has no visible review history';
    return '$category in ${lead.address}. It $websiteState and $reviewState.';
  }
}

class _PhotoSlideshow extends StatelessWidget {
  final String photoReference;

  const _PhotoSlideshow({
    required this.photoReference,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 900),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      child: SizedBox.expand(
        key: ValueKey(photoReference),
        child: ClipRect(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 1.0, end: 1.08),
            duration: const Duration(milliseconds: 3800),
            curve: Curves.easeOutCubic,
            builder: (context, scale, child) {
              return Transform.scale(
                scale: scale,
                child: SizedBox.expand(child: child),
              );
            },
            child: GooglePlacePhoto(
              photoReferences: [photoReference],
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }
}

class _AuditTileData {
  final String label;
  final String value;
  final Color valueColor;

  const _AuditTileData({
    required this.label,
    required this.value,
    required this.valueColor,
  });
}

class _LinkChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _LinkChip({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFE3E1DA)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _LeadIntelCard extends StatelessWidget {
  final ScoutLead lead;

  const _LeadIntelCard({
    required this.lead,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFFEDF8EF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFB8E3C1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'LEAD INTELLIGENCE',
            style: TextStyle(
              color: Color(0xFF1E8E4A),
              fontSize: 12,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _headlineForLead(lead),
            style: const TextStyle(
              color: Colors.black,
              fontSize: 15,
              height: 1.3,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  static String _headlineForLead(ScoutLead lead) {
    if (!lead.hasWebsite && lead.userRatingsTotal <= 5) {
      return 'This business is likely losing trust online due to low visibility and weak proof. Strong outreach target.';
    }
    if (lead.matchedGaps.length >= 2) {
      return 'Multiple visible gaps make this lead warm for outreach. You have more than one clear service angle here.';
    }
    if (lead.hasMediaDeficit) {
      return 'Weak visuals are reducing first impressions. This lead likely needs content upgrades before competitors pull ahead.';
    }
    return 'There is a visible growth gap here, but this lead may need a more focused pitch angle to convert.';
  }
}

class _PipelineStatusCard extends StatelessWidget {
  final LeadOutreachState state;
  final ValueChanged<LeadPipelineStage> onStageSelected;
  final ValueChanged<bool?> onReplySelected;
  final VoidCallback onFollowUpTap;

  const _PipelineStatusCard({
    required this.state,
    required this.onStageSelected,
    required this.onReplySelected,
    required this.onFollowUpTap,
  });

  @override
  Widget build(BuildContext context) {
    final contactedAgo = _timeAgo(state.lastContactedAt);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE7E3DA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'OUTREACH PIPELINE',
            style: TextStyle(
              color: Color(0xFF808080),
              fontSize: 12,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: LeadPipelineStage.values.map((stage) {
              final isSelected = state.stage == stage;
              return GestureDetector(
                onTap: () => onStageSelected(stage),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.black : const Color(0xFFF5F5F2),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _stageLabel(stage),
                    style: TextStyle(
                      color: isSelected ? Colors.white : const Color(0xFF555555),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          if (contactedAgo != null) ...[
            const SizedBox(height: 14),
            Text(
              'You contacted this lead $contactedAgo via ${state.channel ?? 'outreach'}.',
              style: const TextStyle(
                color: Color(0xFF666666),
                fontSize: 14,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 44,
              child: Row(
                children: [
                  Expanded(
                    child: _ReplyButton(
                      label: 'Yes',
                      isSelected: state.replied == true,
                      onTap: () => onReplySelected(true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ReplyButton(
                      label: 'No',
                      isSelected: state.replied == false,
                      onTap: () => onReplySelected(false),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ReplyButton(
                      label: 'Not yet',
                      isSelected: state.replied == null,
                      onTap: () => onReplySelected(null),
                    ),
                  ),
                ],
              ),
            ),
            if (state.replied != true) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: 154,
                height: 42,
                child: ElevatedButton(
                  onPressed: onFollowUpTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Send follow-up',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  static String _stageLabel(LeadPipelineStage stage) {
    switch (stage) {
      case LeadPipelineStage.fresh:
        return 'New';
      case LeadPipelineStage.contacted:
        return 'Contacted';
      case LeadPipelineStage.replied:
        return 'Replied';
      case LeadPipelineStage.closed:
        return 'Closed';
    }
  }

  static String? _timeAgo(DateTime? dateTime) {
    if (dateTime == null) {
      return null;
    }
    final difference = DateTime.now().difference(dateTime);
    if (difference.inDays >= 1) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    }
    if (difference.inHours >= 1) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    }
    final minutes = difference.inMinutes.clamp(1, 59);
    return '$minutes min ago';
  }
}

class _ReplyButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ReplyButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : const Color(0xFFF4F4F1),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF5A5A5A),
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _AuditTile extends StatelessWidget {
  final _AuditTileData tile;

  const _AuditTile({
    required this.tile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            tile.label,
            style: const TextStyle(
              color: Color(0xFF8E8E8E),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            tile.value,
            style: TextStyle(
              color: tile.valueColor,
              fontSize: 15,
              height: 1.08,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoutSaysCard extends StatelessWidget {
  final String message;

  const _ScoutSaysCard({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3CC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFB21D), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SCOUT SAYS',
            style: TextStyle(
              color: Color(0xFFD77800),
              fontSize: 12,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(
              color: Color(0xFF4C4C4C),
              fontSize: 15,
              height: 1.28,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PrimaryActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SecondaryActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SecondaryActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE3E1DA)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.black, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCircle extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionCircle({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0x0C000000),
                  blurRadius: 12,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.black),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF6F6F6F),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetButton extends StatelessWidget {
  final String label;
  final bool isPrimary;
  final VoidCallback? onTap;

  const _SheetButton({
    required this.label,
    required this.isPrimary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: isEnabled
              ? (isPrimary ? Colors.black : const Color(0xFFF2F2EF))
              : const Color(0xFFE3E3DE),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isEnabled
                ? (isPrimary ? Colors.white : Colors.black)
                : const Color(0xFF9A9A9A),
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final List<Widget> children;

  const _DetailCard({
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final bool isLast;
  final VoidCallback? onCopy;

  const _DetailRow({
    required this.icon,
    required this.title,
    required this.value,
    this.isLast = false,
    this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, color: Colors.black, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF8C8C8C),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (onCopy != null)
            GestureDetector(
              onTap: onCopy,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.copy_all_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ReviewsCard extends StatelessWidget {
  final ScoutLead lead;

  const _ReviewsCard({required this.lead});

  @override
  Widget build(BuildContext context) {
    final rating = lead.rating;
    final total = lead.userRatingsTotal;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                rating != null ? rating.toStringAsFixed(1) : '—',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: List.generate(5, (i) {
                        final filled = rating != null && i < rating.round();
                        return Icon(
                          filled ? Icons.star_rounded : Icons.star_border_rounded,
                          color: filled ? const Color(0xFFFFB400) : const Color(0xFFD0CFC9),
                          size: 20,
                        );
                      }),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$total review${total == 1 ? '' : 's'}',
                      style: const TextStyle(
                        color: Color(0xFF8C8C8C),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (total > 0) ...[
            _RatingBar(label: '5', rating: rating!, total: total, color: const Color(0xFF34A853)),
            const SizedBox(height: 6),
            _RatingBar(label: '4', rating: rating, total: total, color: const Color(0xFF9ACD32)),
            const SizedBox(height: 6),
            _RatingBar(label: '3', rating: rating, total: total, color: const Color(0xFFFFB400)),
            const SizedBox(height: 6),
            _RatingBar(label: '2', rating: rating, total: total, color: const Color(0xFFF59E0B)),
            const SizedBox(height: 6),
            _RatingBar(label: '1', rating: rating, total: total, color: const Color(0xFFEF4444)),
            const SizedBox(height: 16),
          ],
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: () {
                _openSearchLink(
                  context,
                  'https://www.google.com/search?q=${Uri.encodeComponent('${lead.name} ${lead.address} reviews')}',
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.open_in_new_rounded, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'View all reviews on Google',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openSearchLink(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _RatingBar extends StatelessWidget {
  final String label;
  final double rating;
  final int total;
  final Color color;

  const _RatingBar({
    required this.label,
    required this.rating,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final starNum = int.parse(label);
    final proximity = (1.0 - (rating - starNum).abs() / 2.5).clamp(0.08, 1.0);
    return Row(
      children: [
        SizedBox(
          width: 14,
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF8C8C8C),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SizedBox(
                height: 8,
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFECECE8),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    SizedBox(
                      width: constraints.maxWidth * proximity,
                      child: Container(
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
