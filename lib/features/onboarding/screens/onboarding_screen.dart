import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/login_screen.dart';
import '../../auth/signup_screen.dart';
import '../widgets/radar_animation.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final PageController _pageController;
  int _currentPage = 0;

  static const _slides = [
    _SlideData(
      title: 'Scan your city\nfor hidden clients',
      description:
          'Explore live business pockets, spot missing digital presence, and uncover local leads that need your service.',
      chips: ['Nearby leads', 'Weak presence', 'Fast discovery'],
    ),
    _SlideData(
      title: 'We score every\ndigital gap',
      description:
          'Each business gets a Scout Score so your team can quickly focus on the leads with the biggest upside.',
      chips: ['Scout Score', 'Priority first', 'Zero guesswork'],
    ),
    _SlideData(
      title: 'Filter the leads\nworth chasing',
      description:
          'Sort by city, niche, and weakness so you spend time where the conversion potential is highest.',
      chips: ['By city', 'By niche', 'By opportunity'],
    ),
    _SlideData(
      title: 'Build a clean\noutreach pipeline',
      description:
          'Save, qualify, and move prospects through a workflow your team can actually use every day.',
      chips: ['Saved leads', 'Team workflow', 'Contact ready'],
    ),
    _SlideData(
      title: 'AI writes your\npitch in seconds',
      description:
          'Generate a clean email, WhatsApp opener, or LinkedIn message for each lead without starting from scratch.',
      chips: ['Email', 'WhatsApp', 'LinkedIn'],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool get _isAuthPage => _currentPage == _slides.length;

  void _nextPage() {
    if (_currentPage >= _slides.length) {
      return;
    }

    _pageController.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  void _skipToAuth() {
    _pageController.animateToPage(
      _slides.length,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final slide = _isAuthPage ? null : _slides[_currentPage];

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            children: [
              _TopBar(currentPage: _currentPage, totalPages: _slides.length),
              const SizedBox(height: 16),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemCount: _slides.length + 1,
                  itemBuilder: (context, index) {
                    if (index == _slides.length) {
                      return _StaggerItem(
                        visible: index == _currentPage,
                        delay: Duration.zero,
                        child: _AuthPage(
                          onLogin: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const LoginScreen()),
                            );
                          },
                          onSignup: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const SignupScreen()),
                            );
                          },
                        ),
                      );
                    }

                    return _StaggerItem(
                      visible: index == _currentPage,
                      delay: Duration.zero,
                      child: _OnboardingCard(
                        pageIndex: index,
                        isActive: index == _currentPage,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 320),
                switchInCurve: Curves.easeOutCubic,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.04),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: !_isAuthPage
                    ? Column(
                        key: ValueKey(_currentPage),
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              slide!.title,
                              style: theme.textTheme.displayMedium?.copyWith(
                                fontSize: 34,
                                fontWeight: FontWeight.w900,
                                height: 1.05,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            slide.description,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: AppTheme.textSecondary,
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: slide.chips.map((chip) => _Chip(label: chip)).toList(),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 56,
                                  child: OutlinedButton(
                                    onPressed: _skipToAuth,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppTheme.textPrimary,
                                      side: const BorderSide(color: Color(0x14000000)),
                                      backgroundColor: const Color(0xFFF6F6F4),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                    ),
                                    child: const Text('Skip'),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: SizedBox(
                                  height: 56,
                                  child: ElevatedButton(
                                    onPressed: _nextPage,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.black,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                    ),
                                    child: const Text('Next'),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                    : const SizedBox(key: ValueKey('auth_bottom_hidden')),
              ),
              const SizedBox(height: 14),
              Text(
                'By continuing, you agree to our Terms and Privacy Policy.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
              ),
          ],
        ),
      ),
    ),
    );
  }
}

class _SlideData {
  final String title;
  final String description;
  final List<String> chips;

  const _SlideData({
    required this.title,
    required this.description,
    required this.chips,
  });
}

class _TopBar extends StatelessWidget {
  final int currentPage;
  final int totalPages;

  const _TopBar({
    required this.currentPage,
    required this.totalPages,
  });

  @override
  Widget build(BuildContext context) {
    final activePage = currentPage >= totalPages ? totalPages - 1 : currentPage;

    return Row(
      children: [
        Text(
          'Scoutify',
          style: GoogleFonts.spaceGrotesk(
            color: Colors.black,
            fontSize: 34,
            fontWeight: FontWeight.w900,
          ),
        ),
        const Spacer(),
        Row(
          children: List.generate(
            totalPages,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: EdgeInsets.only(left: index == 0 ? 0 : 8),
              width: activePage == index ? 30 : 16,
              height: 6,
              decoration: BoxDecoration(
                color: activePage == index ? Colors.black : const Color(0xFFD8D8D3),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StaggerItem extends StatefulWidget {
  final bool visible;
  final Duration delay;
  final Widget child;

  const _StaggerItem({
    required this.visible,
    required this.delay,
    required this.child,
  });

  @override
  State<_StaggerItem> createState() => _StaggerItemState();
}

class _StaggerItemState extends State<_StaggerItem> {
  bool _shown = false;
  int _runId = 0;

  @override
  void initState() {
    super.initState();
    _schedule();
  }

  @override
  void didUpdateWidget(covariant _StaggerItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.visible != widget.visible) {
      _schedule();
    }
  }

  void _schedule() {
    _runId++;
    final currentRun = _runId;

    if (!widget.visible) {
      setState(() {
        _shown = false;
      });
      return;
    }

    setState(() {
      _shown = false;
    });

    Future.delayed(widget.delay, () {
      if (!mounted || currentRun != _runId || !widget.visible) {
        return;
      }
      setState(() {
        _shown = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      duration: const Duration(milliseconds: 340),
      curve: Curves.easeOutCubic,
      offset: _shown ? Offset.zero : const Offset(0, 0.06),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        opacity: _shown ? 1 : 0,
        child: widget.child,
      ),
    );
  }
}

class _OnboardingCard extends StatelessWidget {
  final int pageIndex;
  final bool isActive;

  const _OnboardingCard({
    required this.pageIndex,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(36),
        border: Border.all(color: const Color(0x11000000)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 32,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: switch (pageIndex) {
          0 => _DiscoveryPreview(isActive: isActive),
          1 => _ScorePreview(isActive: isActive),
          2 => _FiltersPreview(isActive: isActive),
          3 => _PipelinePreview(isActive: isActive),
          _ => _PitchPreview(isActive: isActive),
        },
      ),
    );
  }
}

class _DiscoveryPreview extends StatelessWidget {
  final bool isActive;

  const _DiscoveryPreview({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFF3E8),
            Color(0xFFEFF7FF),
            Color(0xFFF8F6FF),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: _StaggerItem(
              visible: isActive,
              delay: const Duration(milliseconds: 40),
              child: const Padding(
                padding: EdgeInsets.all(14),
                child: RadarAnimation(),
              ),
            ),
          ),
          Positioned(
            top: 16,
            left: 16,
            child: _StaggerItem(
              visible: isActive,
              delay: const Duration(milliseconds: 180),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x11000000),
                      blurRadius: 20,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_on_rounded, color: Color(0xFFFF6B57), size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Lagos Island, 5km scan',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: 16,
            top: 16,
            child: _StaggerItem(
              visible: isActive,
              delay: const Duration(milliseconds: 300),
              child: const _StatCard(),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 16,
            child: _StaggerItem(
              visible: isActive,
              delay: const Duration(milliseconds: 420),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '+18',
                      style: TextStyle(
                        color: Color(0xFF21A366),
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'new weak-presence\nleads nearby',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '324',
            style: TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'projects found',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 10),
          Row(
            children: [
              _MiniDot(color: Color(0xFFFF6B57)),
              SizedBox(width: 6),
              _MiniDot(color: Color(0xFF4C8DFF)),
              SizedBox(width: 6),
              _MiniDot(color: Color(0xFFFFB547)),
              SizedBox(width: 10),
              Text(
                'Updated live',
                style: TextStyle(
                  color: Color(0xB3FFFFFF),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniDot extends StatelessWidget {
  final Color color;

  const _MiniDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _ScorePreview extends StatelessWidget {
  final bool isActive;

  const _ScorePreview({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: _StaggerItem(
            visible: isActive,
            delay: const Duration(milliseconds: 120),
            child: const _LeadCard(
              name: 'Mama Titi Kitchen',
              subtitle: 'Lagos Island • Restaurant',
              score: '94',
              scoreColor: Color(0xFFFF5A5F),
              tags: ['No website', '0 reviews', 'No IG'],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: _StaggerItem(
            visible: isActive,
            delay: const Duration(milliseconds: 280),
            child: const _LeadCard(
              name: 'Balogun Tailors',
              subtitle: 'Balogun Street • Fashion',
              score: '82',
              scoreColor: Color(0xFFFFB547),
              tags: ['No website', 'No socials'],
            ),
          ),
        ),
      ],
    );
  }
}

class _FiltersPreview extends StatelessWidget {
  final bool isActive;

  const _FiltersPreview({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StaggerItem(
          visible: isActive,
          delay: const Duration(milliseconds: 100),
          child: const Text(
            'Search filters',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 16),
        _StaggerItem(
          visible: isActive,
          delay: const Duration(milliseconds: 220),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: const [
              _FilterPill(label: 'Restaurants', color: Color(0xFFFFE7D6)),
              _FilterPill(label: 'Lagos Island', color: Color(0xFFE3F0FF)),
              _FilterPill(label: 'No website', color: Color(0xFFFFE3E3)),
              _FilterPill(label: '0-10 reviews', color: Color(0xFFEDF7E8)),
              _FilterPill(label: 'High score', color: Color(0xFFF3ECFF)),
              _FilterPill(label: 'This week', color: Color(0xFFF2F2F2)),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: _StaggerItem(
            visible: isActive,
            delay: const Duration(milliseconds: 360),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F7F5),
                borderRadius: BorderRadius.circular(26),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Matched lead pocket',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      '18 local businesses match your filters',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 26,
                        height: 1.12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Most are listed on Maps but still missing a website or any visible social proof.',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const _SimpleMetric(label: 'Restaurants', value: '11'),
                    const SizedBox(height: 10),
                    const _SimpleMetric(label: 'No website', value: '15'),
                    const SizedBox(height: 10),
                    const _SimpleMetric(label: 'Weak reviews', value: '9'),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PipelinePreview extends StatelessWidget {
  final bool isActive;

  const _PipelinePreview({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: _StaggerItem(
            visible: isActive,
            delay: const Duration(milliseconds: 120),
            child: const _StageTile(
              title: 'Discovered',
              subtitle: '42 fresh businesses found this week',
              value: '42',
              accent: Color(0xFFEAF2FF),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _StaggerItem(
            visible: isActive,
            delay: const Duration(milliseconds: 260),
            child: const _StageTile(
              title: 'Qualified',
              subtitle: '18 strong-fit businesses worth contact',
              value: '18',
              accent: Color(0xFFFFF1DB),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _StaggerItem(
            visible: isActive,
            delay: const Duration(milliseconds: 400),
            child: const _StageTile(
              title: 'Ready to contact',
              subtitle: '9 leads with messaging prepared',
              value: '9',
              accent: Color(0xFFE9F7EA),
            ),
          ),
        ),
      ],
    );
  }
}

class _PitchPreview extends StatelessWidget {
  final bool isActive;

  const _PitchPreview({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F5),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StaggerItem(
              visible: isActive,
              delay: const Duration(milliseconds: 120),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Image.asset('assets/branding/scoutify_logo_ui.png'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Scoutify AI',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Generating a personalised pitch...',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: _StaggerItem(
                visible: isActive,
                delay: const Duration(milliseconds: 280),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SUBJECT LINE',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Quick idea for Mama Titi Kitchen',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 24,
                          height: 1.15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Hi, I found your restaurant on Google Maps and noticed there is a clear opportunity to improve your online visibility and attract more local customers.',
                        style: TextStyle(
                          color: Color(0xFF42464D),
                          fontSize: 15,
                          height: 1.55,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthPage extends StatelessWidget {
  final VoidCallback onLogin;
  final VoidCallback onSignup;

  const _AuthPage({
    required this.onLogin,
    required this.onSignup,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(36),
        border: Border.all(color: const Color(0x11000000)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 32,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F7F5),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Text(
                  'Get started',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Create your account and start scouting better leads.',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 32,
                  height: 1.08,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Sign up, log in, or continue with your preferred provider to begin using Founder Scout.',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 15,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: onSignup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: const Text('Sign Up'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: OutlinedButton(
                        onPressed: onLogin,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.black,
                          side: const BorderSide(color: Color(0x14000000)),
                          backgroundColor: const Color(0xFFF6F6F4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: const Text('Log In'),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const _SocialButton(
                label: 'Continue with Google',
                icon: Icons.circle,
                darkStyle: false,
                isGoogle: true,
              ),
              const SizedBox(height: 12),
              const _SocialButton(
                label: 'Continue with Apple',
                icon: Icons.apple_rounded,
                darkStyle: true,
                isGoogle: false,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LeadCard extends StatelessWidget {
  final String name;
  final String subtitle;
  final String score;
  final Color scoreColor;
  final List<String> tags;

  const _LeadCard({
    required this.name,
    required this.subtitle,
    required this.score,
    required this.scoreColor,
    required this.tags,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F5),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: scoreColor, width: 4),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    score,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Text(
                    'SCR',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: tags
                      .map((tag) => _TagPill(label: tag, color: scoreColor))
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final Color color;

  const _FilterPill({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SimpleMetric extends StatelessWidget {
  final String label;
  final String value;

  const _SimpleMetric({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _StageTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String value;
  final Color accent;

  const _StageTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: accent,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Center(
              child: Text(
                value,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                    height: 1.4,
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

class _Chip extends StatelessWidget {
  final String label;

  const _Chip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _TagPill extends StatelessWidget {
  final String label;
  final Color color;

  const _TagPill({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool darkStyle;
  final bool isGoogle;

  const _SocialButton({
    required this.label,
    required this.icon,
    required this.darkStyle,
    required this.isGoogle,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = darkStyle ? Colors.black : const Color(0xFFF6F6F4);
    final foregroundColor = darkStyle ? Colors.white : Colors.black;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton.icon(
        onPressed: () {},
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          side: BorderSide(
            color: darkStyle ? Colors.black : const Color(0x14000000),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        icon: isGoogle ? const _GoogleMark() : Icon(icon, size: 20),
        label: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: foregroundColor,
          ),
        ),
      ),
    );
  }
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      child: const Text(
        'G',
        style: TextStyle(
          color: Color(0xFF4285F4),
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
