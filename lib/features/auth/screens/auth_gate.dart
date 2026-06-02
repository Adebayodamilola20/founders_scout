import 'package:flutter/material.dart';

import '../../onboarding/screens/onboarding_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: Re-enable Firebase auth when ready
    // return StreamBuilder<User?>(
    //   stream: FirebaseAuthService.instance.authStateChanges(),
    //   builder: (context, authSnapshot) {
    //     if (authSnapshot.connectionState == ConnectionState.waiting) {
    //       return const Scaffold(
    //         body: Center(child: CircularProgressIndicator()),
    //       );
    //     }
    //
    //     final user = authSnapshot.data;
    //     if (user == null) {
    //       return const OnboardingScreen();
    //     }
    //
    //     return StreamBuilder<AppUserProfile?>(
    //       stream: UserProfileRepository.instance.watchCurrentUserProfile(),
    //       builder: (context, profileSnapshot) {
    //         if (profileSnapshot.connectionState == ConnectionState.waiting) {
    //           return const Scaffold(
    //             body: Center(child: CircularProgressIndicator()),
    //           );
    //         }
    //
    //         final profile = profileSnapshot.data;
    //         if (profile == null || !profile.hasCompletedPreferences) {
    //           return SetupWizardScreen(profile: profile);
    //         }
    //
    //         return AppShellScreen(userProfile: profile);
    //       },
    //     );
    //   },
    // );
    return const OnboardingScreen();
  }
}
