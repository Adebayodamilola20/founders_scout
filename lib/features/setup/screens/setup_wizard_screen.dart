import 'package:flutter/material.dart';

import '../../analysis/screens/analysis_screen.dart';
import '../../auth/models/app_user_profile.dart';
import '../models/scout_setup_request.dart';
import '../screens/steps/category_step.dart';
import '../screens/steps/location_step.dart';

class SetupWizardScreen extends StatefulWidget {
  final AppUserProfile? profile;

  const SetupWizardScreen({
    super.key,
    this.profile,
  });

  @override
  State<SetupWizardScreen> createState() => _SetupWizardScreenState();
}

class _SetupWizardScreenState extends State<SetupWizardScreen> {
  final PageController _pageController = PageController();
  late final TextEditingController _locationController;

  int _currentPage = 0;
  final int _totalPages = 2;
  final Set<String> _selectedGaps = {
    'Photography / Video',
    'Review Management',
    'Website Design',
  };
  final Set<String> _selectedCategories = {
    'Restaurant',
    'Nightclubs & Bars',
  };
  late String _activeGapTitle;
  late String _selectedCountry;
  String? _selectedQuickLocation;
  String? _rejectedCategory;

  static const int _maxCategories = 6;

  @override
  void initState() {
    super.initState();
    final profile = widget.profile;
    _locationController = TextEditingController(
      text: profile?.selectedLocation.isNotEmpty == true
          ? profile!.selectedLocation
          : 'Lagos Island',
    );
    if (profile != null) {
      _selectedGaps
        ..clear()
        ..addAll(profile.selectedDigitalGaps.isEmpty
            ? {'Photography / Video', 'Review Management', 'Website Design'}
            : profile.selectedDigitalGaps);
      _selectedCategories
        ..clear()
        ..addAll(profile.selectedCategories.isEmpty
            ? {'Restaurant', 'Nightclubs & Bars'}
            : profile.selectedCategories);
    }
    _activeGapTitle = _selectedGaps.first;
    _selectedCountry = profile?.selectedCountry ?? 'Nigeria';
    _selectedQuickLocation = profile?.selectedLocation ?? 'Lagos Island';
  }

  @override
  void dispose() {
    _pageController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _nextPage() async {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      return;
    }

    final request = ScoutSetupRequest(
      country: _selectedCountry,
      location: _locationController.text.trim(),
      categories: _selectedCategories.toList(),
      digitalGaps: _selectedGaps.toList(),
    );

    // TODO: Re-enable DB write
    // await UserProfileRepository.instance.updatePreferences(request);

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => AnalysisScreen(request: request),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            if (_currentPage > 0) {
              _pageController.previousPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: List.generate(_totalPages, (index) {
                  return Expanded(
                    child: Container(
                      margin: EdgeInsets.only(right: index == _totalPages - 1 ? 0 : 8),
                      height: 4,
                      decoration: BoxDecoration(
                        color: index <= _currentPage ? Colors.black : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),
              Text(
                _currentPage == 0 ? 'Step 1 of 2' : 'Step 2 of 2',
                style: const TextStyle(
                  color: Color(0xFF8B8B8B),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  children: [
                    CategoryStep(
                      selectedGaps: _selectedGaps,
                      selectedCategories: _selectedCategories,
                      activeGapTitle: _activeGapTitle,
                      rejectedCategory: _rejectedCategory,
                      onGapTapped: (gap) {
                        setState(() {
                          if (_selectedGaps.contains(gap)) {
                            _selectedGaps.remove(gap);
                          } else {
                            _selectedGaps.add(gap);
                          }
                          _activeGapTitle = gap;
                        });
                      },
                      onCategoryTapped: (category) {
                        setState(() {
                          if (_selectedCategories.contains(category)) {
                            _selectedCategories.remove(category);
                            _rejectedCategory = null;
                          } else if (_selectedCategories.length < _maxCategories) {
                            _selectedCategories.add(category);
                            _rejectedCategory = null;
                          } else {
                            _rejectedCategory = category;
                            Future.delayed(const Duration(milliseconds: 600), () {
                              if (mounted) {
                                setState(() {
                                  _rejectedCategory = null;
                                });
                              }
                            });
                          }
                        });
                      },
                      onRejectedCategoryCleared: () {
                        if (mounted) {
                          setState(() {
                            _rejectedCategory = null;
                          });
                        }
                      },
                    ),
                    LocationStep(
                      locationController: _locationController,
                      selectedCountry: _selectedCountry,
                      selectedQuickLocation: _selectedQuickLocation,
                      onCountryChanged: (value) {
                        setState(() {
                          _selectedCountry = value;
                          _selectedQuickLocation = null;
                          _locationController.clear();
                        });
                      },
                      onQuickLocationSelected: (value) {
                        setState(() {
                          _selectedQuickLocation = value;
                          _locationController.text = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.only(top: 16, bottom: 8),
                color: Colors.white,
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: (_selectedCategories.isEmpty || _selectedGaps.isEmpty || _locationController.text.trim().isEmpty)
                        ? null
                        : _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      _currentPage == _totalPages - 1 ? 'Find Leads' : 'Continue',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
