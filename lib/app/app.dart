import 'package:flutter/material.dart';

import '../core/services/notification_service.dart';
import '../features/auth/models/app_user_profile.dart';
import '../features/auth/services/user_profile_repository.dart';
import '../features/leads/screens/lead_feed_screen.dart';
import '../features/pitch/screens/pitch_generator_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/radar/models/scout_scan_result.dart';
import '../features/radar/screens/radar_screen.dart';
import '../features/stats/screens/stats_screen.dart';

class AppShellScreen extends StatefulWidget {
  final ScoutScanResult? scanResult;
  final AppUserProfile? userProfile;
  final int initialIndex;

  const AppShellScreen({
    super.key,
    this.scanResult,
    this.userProfile,
    this.initialIndex = 0,
  });

  @override
  State<AppShellScreen> createState() => _AppShellScreenState();
}

class _AppShellScreenState extends State<AppShellScreen> {
  late int _currentIndex;
  bool _sentScanCompleteNotification = false;

  static const _items = [
    _NavItem(icon: Icons.radar_rounded, label: 'Radar'),
    _NavItem(icon: Icons.people_alt_rounded, label: 'Leads'),
    _NavItem(icon: Icons.auto_awesome_rounded, label: 'Pitch'),
    _NavItem(icon: Icons.bar_chart_rounded, label: 'Stats'),
    _NavItem(icon: Icons.person_rounded, label: 'Profile'),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, _items.length - 1);
    _maybeShowScanCompleteNotification();
  }

  void _maybeShowScanCompleteNotification() {
    if (_sentScanCompleteNotification || widget.scanResult == null) {
      return;
    }

    _sentScanCompleteNotification = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(const Duration(seconds: 2), () {
        NotificationService.instance.showScanCompleteNotification(widget.scanResult!);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppUserProfile?>(
      stream: UserProfileRepository.instance.watchCurrentUserProfile(),
      builder: (context, snapshot) {
        final currentProfile = snapshot.data ?? widget.userProfile;

        return Scaffold(
          backgroundColor: Colors.white,
          body: IndexedStack(
            index: _currentIndex,
            children: [
              RadarScreen(
                scanResult: widget.scanResult,
                userProfile: currentProfile,
                onOpenLeads: () {
                  setState(() {
                    _currentIndex = 1;
                  });
                },
              ),
              LeadFeedScreen(
                scanResult: widget.scanResult,
                userProfile: currentProfile,
              ),
              PitchGeneratorScreen(scanResult: widget.scanResult),
              const StatsScreen(),
              ProfileScreen(
                scanResult: widget.scanResult,
                currentProfile: currentProfile,
              ),
            ],
          ),
          bottomNavigationBar: SafeArea(
            minimum: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x12000000),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: List.generate(_items.length, (index) {
                  final item = _items[index];
                  final isSelected = _currentIndex == index;

                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _currentIndex = index;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFF5F5F3) : Colors.transparent,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              item.icon,
                              size: isSelected ? 25 : 22,
                              color: isSelected ? Colors.black : const Color(0xFFB7B7B7),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.label,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: isSelected ? Colors.black : const Color(0xFFB7B7B7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;

  const _NavItem({
    required this.icon,
    required this.label,
  });
}
