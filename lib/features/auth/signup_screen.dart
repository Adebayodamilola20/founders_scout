import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../setup/screens/setup_wizard_screen.dart';
import 'widgets/auth_text_field.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _fullname = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _city = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _fullname.dispose();
    _email.dispose();
    _password.dispose();
    _city.dispose();
    super.dispose();
  }

  Future<void> _createAccount() async {
    if (_isSubmitting) {
      return;
    }
    setState(() {
      _isSubmitting = true;
    });
    try {
      // TODO: Re-enable real auth & profile creation
      // await FirebaseAuthService.instance.signUpWithEmail(
      //   email: _email.text.trim(),
      //   password: _password.text,
      //   fullName: _fullname.text.trim(),
      //   city: _city.text.trim(),
      // );
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const SetupWizardScreen(profile: null)),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message ?? error.code)),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final subtitleColor = isDark ? Colors.white54 : Colors.grey.shade500;

    return Scaffold(
      backgroundColor: isDark
          ? Theme.of(context).scaffoldBackgroundColor
          : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Text(
                'Create\naccount',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                  color: textColor,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Start finding leads today',
                style: TextStyle(
                  fontSize: 16,
                  color: subtitleColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 40),
              AuthTextField(
                label: 'Full name',
                hint: 'Your full name',
                controller: _fullname,
              ),
              AuthTextField(
                label: 'Email',
                hint: 'you@email.com',
                controller: _email,
              ),
              AuthTextField(
                label: 'Password',
                hint: 'At least 8 characters',
                isPassword: true,
                controller: _password,
              ),
              AuthTextField(
                label: 'Your city',
                hint: 'Lagos, Nigeria',
                controller: _city,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _createAccount,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark
                        ? Colors.white
                        : const Color(0xFF1A1A1A),
                    foregroundColor: isDark ? Colors.black : Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isSubmitting ? 'Creating account...' : 'Create account',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
