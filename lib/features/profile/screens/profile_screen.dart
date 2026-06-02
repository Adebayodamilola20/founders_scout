import 'package:flutter/material.dart';

import '../../auth/models/app_user_profile.dart';
import '../../auth/services/firebase_auth_service.dart';
import '../../auth/services/user_profile_repository.dart';
import '../../radar/models/scout_scan_result.dart';
import '../../setup/models/setup_options.dart';

class ProfileScreen extends StatefulWidget {
  final ScoutScanResult? scanResult;
  final AppUserProfile? currentProfile;

  const ProfileScreen({
    super.key,
    this.scanResult,
    this.currentProfile,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late String _homeCity;

  late String _selectedCountry;
  late String _selectedLocation;
  late Set<String> _selectedCategories;
  late Set<String> _selectedGaps;

  bool _scanCompleteNotifications = true;
  bool _followUpReminders = true;
  bool _morningReminders = true;
  bool _streakAlerts = true;
  bool _scanAlerts = true;
  bool _weeklyDigest = false;
  bool _soundAlerts = true;
  bool _openLeadsTabAfterScan = false;
  String _planName = 'Pro Plan';

  @override
  void initState() {
    super.initState();
    final profile = widget.currentProfile;
    final request = widget.scanResult?.request;
    _nameController = TextEditingController(text: profile?.fullName ?? 'Chioma Okonkwo');
    _emailController = TextEditingController(text: profile?.email ?? 'chioma@founders.ng');
    _phoneController = TextEditingController(text: '+234 801 234 5678');
    _homeCity = profile?.homeCity.isNotEmpty == true
        ? profile!.homeCity
        : (request?.location ?? 'Lagos Island');
    _selectedCountry = profile?.selectedCountry ?? request?.country ?? 'Nigeria';
    _selectedLocation = profile?.selectedLocation ?? request?.location ?? 'Lagos Island';
    _selectedCategories = {
      ...?profile?.selectedCategories,
      if ((profile?.selectedCategories ?? const []).isEmpty) ...?request?.categories,
      if ((profile?.selectedCategories ?? const []).isEmpty && request == null) 'Restaurant',
      if ((profile?.selectedCategories ?? const []).isEmpty && request == null) 'Nightclubs & Bars',
    };
    _selectedGaps = {
      ...?profile?.selectedDigitalGaps,
      if ((profile?.selectedDigitalGaps ?? const []).isEmpty) ...?request?.digitalGaps,
      if ((profile?.selectedDigitalGaps ?? const []).isEmpty && request == null) 'Website Design',
      if ((profile?.selectedDigitalGaps ?? const []).isEmpty && request == null) 'Review Management',
    };
    if (profile == null) {
      _hydrateFromFirestore();
    }
  }

  Future<void> _hydrateFromFirestore() async {
    final profile = await UserProfileRepository.instance.fetchCurrentUserProfile();
    if (!mounted || profile == null) {
      return;
    }
    setState(() {
      _nameController.text = profile.fullName;
      _emailController.text = profile.email;
      _homeCity = profile.homeCity;
      _selectedCountry = profile.selectedCountry;
      _selectedLocation = profile.selectedLocation;
      _selectedCategories = {...profile.selectedCategories};
      _selectedGaps = {...profile.selectedDigitalGaps};
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  String get _profileInitial {
    final trimmed = _nameController.text.trim();
    return trimmed.isEmpty ? 'S' : trimmed.substring(0, 1).toUpperCase();
  }

  Future<void> _openSettingsPage({
    required String title,
    required Widget child,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _SettingsScaffold(
          title: title,
          child: child,
        ),
      ),
    );
  }

  Future<void> _persistProfile() {
    return UserProfileRepository.instance.updateProfileFields(
      fullName: _nameController.text.trim(),
      email: _emailController.text.trim(),
      homeCity: _homeCity,
      selectedCountry: _selectedCountry,
      selectedLocation: _selectedLocation,
      selectedCategories: _selectedCategories.toList(),
      selectedDigitalGaps: _selectedGaps.toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scanResult = widget.scanResult;
    final matchesLabel = scanResult == null
        ? 'No active scan yet'
        : '${scanResult.totalLeads} matches in ${scanResult.request.location}';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
          children: [
            const Text(
              'Profile',
              style: TextStyle(
                color: Color(0xFF1F1F1F),
                fontSize: 32,
                height: 1,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 22),
            _ProfileHero(
              initial: _profileInitial,
              name: _nameController.text,
              contactLine: '${_emailController.text}  •  ${_phoneController.text}',
              planName: _planName,
              metaLine: matchesLabel,
            ),
            const SizedBox(height: 28),
            _ProfileSection(
              title: 'Account',
              items: [
                _ProfileItemData(
                  label: 'Edit Profile',
                  subtitle: 'Name, email, phone, and identity',
                  onTap: () => _openSettingsPage(
                    title: 'Edit Profile',
                    child: _ProfileFormPage(
                      nameController: _nameController,
                      emailController: _emailController,
                      phoneController: _phoneController,
                      onSaved: () async {
                        await _persistProfile();
                        if (mounted) {
                          setState(() {});
                        }
                      },
                    ),
                  ),
                ),
                _ProfileItemData(
                  label: 'Notifications',
                  subtitle: 'Scan alerts, reminders, and digest',
                  trailingText: _scanCompleteNotifications ? 'On' : 'Off',
                  trailingColor: _scanCompleteNotifications
                      ? const Color(0xFF22C55E)
                      : const Color(0xFF8A8A8A),
                  onTap: () => _openSettingsPage(
                    title: 'Notifications',
                    child: StatefulBuilder(
                      builder: (context, setLocalState) {
                        void sync(VoidCallback change) {
                          setState(change);
                          setLocalState(() {});
                        }

                        return _ToggleListPage(
                          items: [
                            _ToggleItem(
                              label: 'Scan complete notifications',
                              subtitle: 'Show a mobile notification when a scan finishes.',
                              value: _scanCompleteNotifications,
                              onChanged: (value) => sync(() {
                                _scanCompleteNotifications = value;
                              }),
                            ),
                            _ToggleItem(
                              label: 'Morning reminders',
                              subtitle: 'Daily reminder at 8 AM to check your leads.',
                              value: _morningReminders,
                              onChanged: (value) => sync(() {
                                _morningReminders = value;
                              }),
                            ),
                            _ToggleItem(
                              label: 'Follow-up reminders',
                              subtitle: 'Remind me to follow up with contacted leads.',
                              value: _followUpReminders,
                              onChanged: (value) => sync(() {
                                _followUpReminders = value;
                              }),
                            ),
                            _ToggleItem(
                              label: 'Streak alerts',
                              subtitle: 'Notify me when my scout streak increases.',
                              value: _streakAlerts,
                              onChanged: (value) => sync(() {
                                _streakAlerts = value;
                              }),
                            ),
                            _ToggleItem(
                              label: 'Scan alerts',
                              subtitle: 'Alert when new leads are found in my area.',
                              value: _scanAlerts,
                              onChanged: (value) => sync(() {
                                _scanAlerts = value;
                              }),
                            ),
                            _ToggleItem(
                              label: 'Weekly scout digest',
                              subtitle: 'Get a weekly summary of activity and pipeline.',
                              value: _weeklyDigest,
                              onChanged: (value) => sync(() {
                                _weeklyDigest = value;
                              }),
                            ),
                            _ToggleItem(
                              label: 'Sound alerts',
                              subtitle: 'Play sound for important notifications.',
                              value: _soundAlerts,
                              onChanged: (value) => sync(() {
                                _soundAlerts = value;
                              }),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                _ProfileItemData(
                  label: 'Subscription & Billing',
                  subtitle: 'Plan details, upgrade path, and renewal',
                  trailingText: 'Active',
                  trailingColor: const Color(0xFF22C55E),
                  onTap: () => _openSettingsPage(
                    title: 'Subscription',
                    child: StatefulBuilder(
                      builder: (context, setLocalState) {
                        return _SubscriptionPage(
                          planName: _planName,
                          onPlanSelected: (value) {
                            setState(() {
                              _planName = value;
                            });
                            setLocalState(() {});
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _ProfileSection(
              title: 'Scout Setup',
              items: [
                _ProfileItemData(
                  label: 'Scout Area',
                  subtitle: '$_selectedLocation, $_selectedCountry',
                  onTap: () => _openSettingsPage(
                    title: 'Scout Area',
                    child: StatefulBuilder(
                      builder: (context, setLocalState) {
                        final currentLocations =
                            scoutQuickLocationOptionsByCountry[_selectedCountry] ?? const [];
                        return _ScoutAreaPage(
                          selectedCountry: _selectedCountry,
                          selectedLocation: _selectedLocation,
                          locations: currentLocations,
                          onCountryChanged: (value) {
                            setState(() {
                              _selectedCountry = value;
                              _selectedLocation =
                                  (scoutQuickLocationOptionsByCountry[value] ?? const [''])[0];
                            });
                            _persistProfile();
                            setLocalState(() {});
                          },
                          onLocationChanged: (value) {
                            setState(() {
                              _selectedLocation = value;
                            });
                            _persistProfile();
                            setLocalState(() {});
                          },
                        );
                      },
                    ),
                  ),
                ),
                _ProfileItemData(
                  label: 'Scout Focus',
                  subtitle: '${_selectedCategories.length} categories • ${_selectedGaps.length} services',
                  onTap: () => _openSettingsPage(
                    title: 'Scout Focus',
                    child: StatefulBuilder(
                      builder: (context, setLocalState) {
                        return _ScoutFocusPage(
                          selectedCategories: _selectedCategories,
                          selectedGaps: _selectedGaps,
                          onToggleCategory: (value) {
                            setState(() {
                              if (_selectedCategories.contains(value)) {
                                _selectedCategories.remove(value);
                              } else {
                                _selectedCategories.add(value);
                              }
                            });
                            _persistProfile();
                            setLocalState(() {});
                          },
                          onToggleGap: (value) {
                            setState(() {
                              if (_selectedGaps.contains(value)) {
                                _selectedGaps.remove(value);
                              } else {
                                _selectedGaps.add(value);
                              }
                            });
                            _persistProfile();
                            setLocalState(() {});
                          },
                        );
                      },
                    ),
                  ),
                ),
                _ProfileItemData(
                  label: 'Scout Workflow',
                  subtitle: _openLeadsTabAfterScan ? 'Open leads after scan' : 'Open radar after scan',
                  onTap: () => _openSettingsPage(
                    title: 'Scout Workflow',
                    child: StatefulBuilder(
                      builder: (context, setLocalState) {
                        return _ToggleListPage(
                          items: [
                            _ToggleItem(
                              label: 'Open Leads tab after scan',
                              subtitle: 'Jump to the leads list instead of staying on Radar.',
                              value: _openLeadsTabAfterScan,
                              onChanged: (value) {
                                setState(() {
                                  _openLeadsTabAfterScan = value;
                                });
                                setLocalState(() {});
                              },
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _ProfileSection(
              title: 'Workspace',
              items: [
                _ProfileItemData(
                  label: 'Outreach Defaults',
                  subtitle: 'WhatsApp first • short pitch tone',
                  onTap: () => _openSettingsPage(
                    title: 'Outreach Defaults',
                    child: const _InfoPage(
                      sections: [
                        _InfoSection(
                          title: 'Current default channel',
                          body: 'WhatsApp is the primary outreach action right now.',
                        ),
                        _InfoSection(
                          title: 'Recommended next upgrade',
                          body: 'Add saved tone presets like Direct, Warm, and Premium so pitch generation matches the freelancer style.',
                        ),
                      ],
                    ),
                  ),
                ),
                _ProfileItemData(
                  label: 'Pipeline & CRM',
                  subtitle: 'Track contacted, replied, and closed leads',
                  onTap: () => _openSettingsPage(
                    title: 'Pipeline & CRM',
                    child: const _InfoPage(
                      sections: [
                        _InfoSection(
                          title: 'What is live now',
                          body: 'Your lead workflow supports New, Contacted, Replied, and Closed stages.',
                        ),
                        _InfoSection(
                          title: 'Next useful addition',
                          body: 'A small dashboard with contacted count, reply rate, and close count will make retention stronger.',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _ProfileSection(
              title: 'API & Support',
              items: [
                const _ProfileItemData(
                  label: 'Google Places API Key',
                  subtitle: 'Used for location scans and lead details',
                  trailingText: 'Connected',
                  trailingColor: Color(0xFF22C55E),
                ),
                const _ProfileItemData(
                  label: 'WhatsApp Integration',
                  subtitle: 'Prefilled message handoff',
                  trailingText: 'Active',
                  trailingColor: Color(0xFF22C55E),
                ),
                _ProfileItemData(
                  label: 'Help & Feedback',
                  subtitle: 'Report issues or suggest features',
                  onTap: () => _openSettingsPage(
                    title: 'Help & Feedback',
                    child: const _InfoPage(
                      sections: [
                        _InfoSection(
                          title: 'Fastest feedback path',
                          body: 'Collect bug reports with device type, scan area, and a screenshot of the issue.',
                        ),
                        _InfoSection(
                          title: 'What users care about most',
                          body: 'Lead quality, phone formatting, pitch relevance, and follow-up reminders.',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _ProfileSection(
              title: 'Session',
              items: [
                _ProfileItemData(
                  label: 'Sign Out',
                  subtitle: 'End current session',
                  trailingText: '',
                  trailingColor: Color(0xFFFF4D38),
                  isDestructive: true,
                  onTap: () => FirebaseAuthService.instance.signOut(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  final String initial;
  final String name;
  final String contactLine;
  final String planName;
  final String metaLine;

  const _ProfileHero({
    required this.initial,
    required this.name,
    required this.contactLine,
    required this.planName,
    required this.metaLine,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 116,
          height: 116,
          decoration: const BoxDecoration(
            color: Color(0xFF22C55E),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            initial,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 46,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          name,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          contactLine,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF8A8A8A),
            fontSize: 15,
            height: 1.35,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          metaLine,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF5F5F5F),
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFE5F7EC),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            planName,
            style: const TextStyle(
              color: Color(0xFF1A8A44),
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileSection extends StatelessWidget {
  final String title;
  final List<_ProfileItemData> items;

  const _ProfileSection({
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: Color(0xFF8A8A8A),
            fontSize: 13,
            letterSpacing: 1.8,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return Padding(
              padding: EdgeInsets.only(bottom: index == items.length - 1 ? 0 : 12),
              child: _ProfileActionCard(item: item),
            );
          },
        ),
      ],
    );
  }
}

class _ProfileActionCard extends StatelessWidget {
  final _ProfileItemData item;

  const _ProfileActionCard({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = item.isDestructive
        ? const Color(0xFFFFD7D1)
        : const Color(0xFFEDE8DE);
    final labelColor = item.isDestructive ? const Color(0xFFFF4D38) : Colors.black;

    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: item.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.label,
                    style: TextStyle(
                      color: labelColor,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (item.subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.subtitle,
                      style: const TextStyle(
                        color: Color(0xFF7E7E7E),
                        fontSize: 13,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (item.trailingText.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Text(
                  '${item.trailingText} ✓',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: item.trailingColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            Icon(
              Icons.chevron_right_rounded,
              color: item.isDestructive ? const Color(0xFFFF4D38) : const Color(0xFFC2C2C2),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileItemData {
  final String label;
  final String subtitle;
  final String trailingText;
  final Color trailingColor;
  final bool isDestructive;
  final VoidCallback? onTap;

  const _ProfileItemData({
    required this.label,
    this.subtitle = '',
    this.trailingText = '',
    this.trailingColor = Colors.transparent,
    this.isDestructive = false,
    this.onTap,
  });
}

class _SettingsScaffold extends StatelessWidget {
  final String title;
  final Widget child;

  const _SettingsScaffold({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: child,
      ),
    );
  }
}

class _ProfileFormPage extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final VoidCallback onSaved;

  const _ProfileFormPage({
    required this.nameController,
    required this.emailController,
    required this.phoneController,
    required this.onSaved,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      children: [
        _FieldCard(
          label: 'Full name',
          child: TextField(controller: nameController),
        ),
        const SizedBox(height: 14),
        _FieldCard(
          label: 'Email',
          child: TextField(controller: emailController),
        ),
        const SizedBox(height: 14),
        _FieldCard(
          label: 'Phone',
          child: TextField(controller: phoneController),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () {
            onSaved();
            Navigator.of(context).pop();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child: const Text(
            'Save profile',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

class _ToggleListPage extends StatelessWidget {
  final List<_ToggleItem> items;

  const _ToggleListPage({
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: const Color(0xFFF7F6F2),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.label,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.subtitle,
                      style: const TextStyle(
                        color: Color(0xFF737373),
                        fontSize: 13,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Switch(
                value: item.value,
                onChanged: item.onChanged,
              ),
            ],
          ),
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemCount: items.length,
    );
  }
}

class _ToggleItem {
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleItem({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });
}

class _SubscriptionPage extends StatelessWidget {
  final String planName;
  final ValueChanged<String> onPlanSelected;

  const _SubscriptionPage({
    required this.planName,
    required this.onPlanSelected,
  });

  @override
  Widget build(BuildContext context) {
    const plans = ['Starter', 'Pro Plan', 'Agency'];
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      children: [
        const _InfoSectionCard(
          title: 'Current billing status',
          body: 'Your workspace is active. Use plan controls here to test upgrade and downgrade flows.',
        ),
        const SizedBox(height: 14),
        ...plans.map((plan) {
          final isActive = plan == planName;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () => onPlanSelected(plan),
              borderRadius: BorderRadius.circular(22),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  color: isActive ? const Color(0xFF111111) : const Color(0xFFF7F6F2),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        plan,
                        style: TextStyle(
                          color: isActive ? Colors.white : Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Text(
                      isActive ? 'Selected' : 'Choose',
                      style: TextStyle(
                        color: isActive ? Colors.white70 : const Color(0xFF666666),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _ScoutAreaPage extends StatelessWidget {
  final String selectedCountry;
  final String selectedLocation;
  final List<String> locations;
  final ValueChanged<String> onCountryChanged;
  final ValueChanged<String> onLocationChanged;

  const _ScoutAreaPage({
    required this.selectedCountry,
    required this.selectedLocation,
    required this.locations,
    required this.onCountryChanged,
    required this.onLocationChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selectedDropdownLocation = locations.isEmpty
        ? null
        : (locations.contains(selectedLocation) ? selectedLocation : locations.first);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      children: [
        _FieldCard(
          label: 'Country',
          child: DropdownButtonFormField<String>(
            value: selectedCountry,
            items: scoutCountryOptions
                .map((country) => DropdownMenuItem(value: country, child: Text(country)))
                .toList(),
            onChanged: (value) {
              if (value != null) {
                onCountryChanged(value);
              }
            },
          ),
        ),
        const SizedBox(height: 14),
        _FieldCard(
          label: 'Quick location',
          child: DropdownButtonFormField<String>(
            value: selectedDropdownLocation,
            items: locations
                .map((location) => DropdownMenuItem(value: location, child: Text(location)))
                .toList(),
            onChanged: (value) {
              if (value != null) {
                onLocationChanged(value);
              }
            },
          ),
        ),
      ],
    );
  }
}

class _ScoutFocusPage extends StatelessWidget {
  final Set<String> selectedCategories;
  final Set<String> selectedGaps;
  final ValueChanged<String> onToggleCategory;
  final ValueChanged<String> onToggleGap;

  const _ScoutFocusPage({
    required this.selectedCategories,
    required this.selectedGaps,
    required this.onToggleCategory,
    required this.onToggleGap,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      children: [
        const Text(
          'Categories',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: scoutCategoryOptions.take(14).map((category) {
            final isSelected = selectedCategories.contains(category);
            return _SelectableChip(
              label: category,
              isSelected: isSelected,
              onTap: () => onToggleCategory(category),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        const Text(
          'Service focus',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: digitalGapOptions.map((gap) {
            final title = gap['title']!;
            final isSelected = selectedGaps.contains(title);
            return _SelectableChip(
              label: title,
              isSelected: isSelected,
              onTap: () => onToggleGap(title),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _SelectableChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SelectableChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : const Color(0xFFF2F1EC),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _InfoPage extends StatelessWidget {
  final List<_InfoSection> sections;

  const _InfoPage({
    required this.sections,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      itemCount: sections.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final section = sections[index];
        return _InfoSectionCard(
          title: section.title,
          body: section.body,
        );
      },
    );
  }
}

class _InfoSection {
  final String title;
  final String body;

  const _InfoSection({
    required this.title,
    required this.body,
  });
}

class _InfoSectionCard extends StatelessWidget {
  final String title;
  final String body;

  const _InfoSectionCard({
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F6F2),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              color: Color(0xFF696969),
              fontSize: 14,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldCard extends StatelessWidget {
  final String label;
  final Widget child;

  const _FieldCard({
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F6F2),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF6F6F6F),
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
