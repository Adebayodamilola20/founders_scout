import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'dart:async';

import '../../../app/app.dart';
import '../../setup/models/scout_setup_request.dart';
import '../models/scan_progress.dart';
import '../services/google_places_scan_service.dart';
// TODO: Re-enable scan cache
// import '../services/scan_cache_repository.dart';
import '../widgets/shimmer_text.dart';

class AnalysisScreen extends StatefulWidget {
  final ScoutSetupRequest request;

  const AnalysisScreen({
    super.key,
    required this.request,
  });

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  final GooglePlacesScanService _scanService = GooglePlacesScanService();
  // TODO: Re-enable scan cache
  // final ScanCacheRepository _cache = ScanCacheRepository.instance;
  Timer? _messageRotationTimer;
  int _activeHelperIndex = 0;

  static const List<String> _helperMessages = [
    'Please wait while Scoutify scans local businesses that match your filters.',
    'We are checking websites, reviews, and visibility signals to surface stronger lead opportunities.',
    'This usually takes a moment. Better matches now means less wasted outreach later.',
  ];

  ScanProgress _progress = const ScanProgress(
    status: 'Preparing live radar scan...',
    checkedBusinesses: 0,
  );
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startHelperMessageRotation();
    _startScan();
  }

  @override
  void dispose() {
    _messageRotationTimer?.cancel();
    super.dispose();
  }

  void _startHelperMessageRotation() {
    _messageRotationTimer?.cancel();
    _messageRotationTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _activeHelperIndex = (_activeHelperIndex + 1) % _helperMessages.length;
      });
    });
  }

  Future<void> _startScan() async {
    try {
      // TODO: Re-enable scan cache
      // final cached = await _cache.loadScan(widget.request);
      // if (cached != null && cached.leads.isNotEmpty) {
      //   if (!mounted) return;
      //   Navigator.of(context).pushReplacement(
      //     MaterialPageRoute(
      //       builder: (_) => AppShellScreen(scanResult: cached),
      //     ),
      //   );
      //   return;
      // }

      final result = await _scanService.scan(
        widget.request,
        onProgress: (progress) {
          if (!mounted) {
            return;
          }
          setState(() {
            _progress = progress;
          });
        },
      );

      if (!mounted) {
        return;
      }

      if (result.leads.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'No businesses matched your criteria in ${widget.request.location}. Try a different location, add more categories, or select different service gaps.';
        });
        return;
      }

      // TODO: Re-enable scan cache
      // _cache.saveScan(result);

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => AppShellScreen(scanResult: result),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _errorMessage = error.toString().replaceFirst('StateError: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 260,
                  width: 260,
                  child: Lottie.asset(
                    'assets/lottie/Appointment booking with smartphone.json',
                    repeat: _isLoading,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Scanning ${widget.request.location}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  child: Text(
                    _helperMessages[_activeHelperIndex],
                    key: ValueKey(_activeHelperIndex),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF686868),
                      fontSize: 14,
                      height: 1.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                ShimmerText(
                  text: _progress.status,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  duration: const Duration(milliseconds: 1800),
                  baseColor: const Color(0xFF9A9A9A),
                  highlightColor: const Color(0xFFF2F2F2),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 18),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF7A7A7A),
                      fontSize: 14,
                      height: 1.45,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isLoading = true;
                        _errorMessage = null;
                        _progress = const ScanProgress(
                          status: 'Preparing live radar scan...',
                          checkedBusinesses: 0,
                        );
                      });
                      _startScan();
                    },
                    child: const Text('Try again'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
