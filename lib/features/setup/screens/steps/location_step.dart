import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/setup_options.dart';
import '../../services/location_suggestions_service.dart';

class LocationStep extends StatefulWidget {
  final TextEditingController locationController;
  final String selectedCountry;
  final String? selectedQuickLocation;
  final ValueChanged<String> onCountryChanged;
  final ValueChanged<String> onQuickLocationSelected;

  const LocationStep({
    super.key,
    required this.locationController,
    required this.selectedCountry,
    required this.selectedQuickLocation,
    required this.onCountryChanged,
    required this.onQuickLocationSelected,
  });

  @override
  State<LocationStep> createState() => _LocationStepState();
}

class _LocationStepState extends State<LocationStep> {
  final LocationSuggestionsService _suggestionsService =
      LocationSuggestionsService();
  Timer? _debounce;
  List<String> _quickPicks = const [];
  List<String> _searchSuggestions = const [];
  bool _isRefreshingQuickPicks = false;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    widget.locationController.addListener(_handleSearchChanged);
    _loadQuickPicks(initial: true);
  }

  @override
  void didUpdateWidget(covariant LocationStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedCountry != widget.selectedCountry) {
      _loadQuickPicks();
      _searchSuggestions = const [];
      widget.locationController.clear();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    widget.locationController.removeListener(_handleSearchChanged);
    super.dispose();
  }

  Future<void> _loadQuickPicks({bool initial = false}) async {
    if (!initial) {
      setState(() {
        _isRefreshingQuickPicks = true;
      });
      await Future<void>.delayed(const Duration(milliseconds: 750));
    }

    final nextPicks =
        scoutQuickLocationOptionsByCountry[widget.selectedCountry] ?? const [];

    if (!mounted) {
      return;
    }

    setState(() {
      _quickPicks = nextPicks;
      _isRefreshingQuickPicks = false;
    });
  }

  void _handleSearchChanged() {
    _debounce?.cancel();
    final query = widget.locationController.text.trim();

    if (query.isEmpty) {
      if (mounted) {
        setState(() {
          _searchSuggestions = const [];
          _isSearching = false;
        });
      }
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 320), () async {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSearching = true;
      });

      try {
        final results = await _suggestionsService.searchLocations(
          query: query,
          country: widget.selectedCountry,
        );
        if (!mounted) {
          return;
        }
        setState(() {
          _searchSuggestions = results;
          _isSearching = false;
        });
      } catch (_) {
        if (!mounted) {
          return;
        }
        setState(() {
          _searchSuggestions = const [];
          _isSearching = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          const Text(
            'Tell us where you want to search.',
            style: TextStyle(
              color: Colors.black,
              fontSize: 30,
              fontWeight: FontWeight.w900,
              height: 1.08,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Select the country first, then type a city, area, or tap one of the quick locations below.',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 15,
              height: 1.55,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 28),
          const _LocationSectionLabel(title: 'COUNTRY'),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: widget.selectedCountry,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.black),
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
                items: scoutCountryOptions.map((country) {
                  return DropdownMenuItem(
                    value: country,
                    child: Text(country),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    widget.onCountryChanged(value);
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 28),
          const _LocationSectionLabel(title: 'LOCATION'),
          const SizedBox(height: 14),
          TextField(
            controller: widget.locationController,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
            decoration: InputDecoration(
              hintText: 'Type a city, district, or neighborhood',
              hintStyle: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              prefixIcon: const Icon(Icons.search_rounded, color: Colors.black),
              filled: true,
              fillColor: const Color(0xFFF5F5F3),
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(color: Colors.black, width: 1.4),
              ),
            ),
          ),
          if (_isSearching)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: LinearProgressIndicator(
                minHeight: 2.4,
                color: Colors.black,
                backgroundColor: Color(0xFFEAEAE7),
              ),
            ),
          if (_searchSuggestions.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE6E4DE)),
              ),
              child: Column(
                children: _searchSuggestions.take(6).map((location) {
                  return ListTile(
                    dense: true,
                    leading: const Icon(
                      Icons.location_on_outlined,
                      color: Colors.black,
                    ),
                    title: Text(
                      location,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    onTap: () {
                      widget.locationController.text = location;
                      setState(() {
                        _searchSuggestions = const [];
                      });
                    },
                  );
                }).toList(),
              ),
            ),
          ],
          const SizedBox(height: 24),
          const _LocationSectionLabel(title: 'QUICK PICKS'),
          const SizedBox(height: 14),
          if (_isRefreshingQuickPicks)
            Wrap(
              spacing: 12,
              runSpacing: 14,
              children: List.generate(
                8,
                (_) => const _QuickLocationShimmer(),
              ),
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 14,
              children: _quickPicks.map((location) {
                return _QuickLocationChip(
                  label: location,
                  isSelected: widget.selectedQuickLocation == location,
                  onTap: () => widget.onQuickLocationSelected(location),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

class _QuickLocationShimmer extends StatefulWidget {
  const _QuickLocationShimmer();

  @override
  State<_QuickLocationShimmer> createState() => _QuickLocationShimmerState();
}

class _QuickLocationShimmerState extends State<_QuickLocationShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
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
      builder: (context, _) {
        final start = -1.1 + (_controller.value * 2.2);
        return Container(
          width: 120,
          height: 46,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: LinearGradient(
              begin: Alignment(start, 0),
              end: Alignment(start + 1.2, 0),
              colors: const [
                Color(0xFFEDEDE8),
                Color(0xFFF8F8F4),
                Color(0xFFE8E8E2),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LocationSectionLabel extends StatelessWidget {
  final String title;

  const _LocationSectionLabel({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFF8B8B8B),
        fontSize: 13,
        fontWeight: FontWeight.w900,
        letterSpacing: 1,
      ),
    );
  }
}

class _QuickLocationChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _QuickLocationChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : const Color(0xFFF5F5F3),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF5E5E5E),
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
