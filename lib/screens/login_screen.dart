import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'dart:async';
import 'dart:ui';

import 'package:shared_preferences/shared_preferences.dart';

import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import '../utils/app_toast.dart';
import '../widgets/language_toggle_button.dart';
import '../widgets/password_strength_meter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _rememberMe = false;

  int _lockoutSecondsRemaining = 0;
  Timer? _lockoutTimer;
  String? _loginErrorMessage;

  // Premium Color Palette
  final Color _accentGold = const Color(0xFFE5C07B);

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUsername = prefs.getString('saved_username');
    final savedPassword = prefs.getString('saved_password');
    final rememberMe = prefs.getBool('remember_me') ?? false;

    if (rememberMe && savedUsername != null && savedPassword != null) {
      setState(() {
        _usernameController.text = savedUsername;
        _passwordController.text = savedPassword;
        _rememberMe = true;
      });
    }
  }

  @override
  void dispose() {
    _lockoutTimer?.cancel();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _startLockoutTimer(int seconds) {
    _lockoutTimer?.cancel();
    setState(() {
      _lockoutSecondsRemaining = seconds;
    });
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_lockoutSecondsRemaining > 1) {
        if (mounted) {
          setState(() {
            _lockoutSecondsRemaining--;
          });
        }
      } else {
        timer.cancel();
        if (mounted) {
          setState(() {
            _lockoutSecondsRemaining = 0;
          });
        }
      }
    });
  }

  Future<void> _login() async {
    if (_lockoutSecondsRemaining > 0) return;
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final success = await authProvider.login(
      _usernameController.text.trim(),
      _passwordController.text,
    );

    if (success) {
      _lockoutTimer?.cancel();
      if (mounted) {
        setState(() {
          _lockoutSecondsRemaining = 0;
          _loginErrorMessage = null;
        });
      }
      final prefs = await SharedPreferences.getInstance();
      if (_rememberMe) {
        await prefs.setString('saved_username', _usernameController.text.trim());
        await prefs.setString('saved_password', _passwordController.text);
        await prefs.setBool('remember_me', true);
      } else {
        await prefs.remove('saved_username');
        await prefs.remove('saved_password');
        await prefs.setBool('remember_me', false);
      }
    } else {
      if (!mounted) return;
      final errorMsg = authProvider.errorMessage;

      if (errorMsg.contains('60 seconds') || errorMsg.contains('locked') || errorMsg.contains('try again in')) {
        int secs = 60;
        final match = RegExp(r'(\d+)\s*second').firstMatch(errorMsg);
        if (match != null) {
          secs = int.tryParse(match.group(1)!) ?? 60;
        }
        _startLockoutTimer(secs);
      }

      String displayMsg = errorMsg;
      if (languageProvider.isTamil) {
        if (errorMsg.contains('Invalid username or password') || errorMsg.contains('Invalid credentials')) {
          displayMsg = errorMsg
              .replaceAll('Invalid credentials', 'தவறான பயனர் பெயர் அல்லது கடவுச்சொல்')
              .replaceAll('Invalid username or password', 'தவறான பயனர் பெயர் அல்லது கடவுச்சொல்!')
              .replaceAll('attempt(s) remaining before lockout', 'முயற்சிகள் மட்டுமே மீதமுள்ளன!');
        } else if (errorMsg.contains('locked') || errorMsg.contains('Too many failed')) {
          displayMsg = 'தொடர்ச்சியாக 5 முறை தவறான கடவுச்சொல்! கணக்கு 60 வினாடிகளுக்கு பூட்டப்பட்டுள்ளது.';
        }
      }

      // Show Top Toast Notification
      AppToast.showError(context, displayMsg);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;
    final languageProvider = context.watch<LanguageProvider>();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
  color: Theme.of(context).brightness == Brightness.dark
      ? null
      : Theme.of(context).scaffoldBackgroundColor,
  gradient: Theme.of(context).brightness == Brightness.dark
      ? RadialGradient(
            center: const Alignment(0, -0.6),
            radius: 1.2,
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).primaryColor,
              Colors.black,
            ],
            stops: const [0.0, 0.6, 1.0],
          )
      : null,
),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Language Switcher Toggle
                  const Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 16.0),
                      child: LanguageToggleButton(),
                    ),
                  ),

                  // Logo Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor
                              .withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _accentGold.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _accentGold.withValues(alpha: 0.1),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.grass,
                          size: 36,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            languageProvider.tr('appName'),
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                              letterSpacing: 1.2,
                              shadows: [
                                Shadow(
                                  color: _accentGold.withValues(alpha: 0.5),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                          ),
                          Text(
                            languageProvider.tr('appSubtitle'),
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.outline,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),

                  // Glassmorphism Login Card
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.all(28.0),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface
                              .withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                            width: 1.5,
                          ),
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Theme.of(context)
                                        .primaryColor
                                        .withValues(alpha: 0.5),
                                    radius: 24,
                                    child: Icon(
                                      Icons.person,
                                      color: _accentGold,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        languageProvider.tr('welcomeBack'),
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).colorScheme.onSurface,
                                        ),
                                      ),
                                      Text(
                                        languageProvider.tr('signInToContinue'),
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .outline,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                               const SizedBox(height: 32),

                               // Username Field
                              Text(
                                languageProvider.tr('username'),
                                style: TextStyle(
                                  color: _accentGold,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildTextField(
                                controller: _usernameController,
                                hintText: languageProvider.tr('username'),
                                icon: Icons.person,
                                validator: (value) =>
                                    value == null || value.isEmpty
                                    ? 'Required'
                                    : null,
                              ),
                              const SizedBox(height: 24),

                              // Password Field
                              Text(
                                languageProvider.tr('currentPassword'),
                                style: TextStyle(
                                  color: _accentGold,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildTextField(
                                controller: _passwordController,
                                hintText: languageProvider.tr('currentPassword'),
                                icon: Icons.lock,
                                isPassword: true,
                                validator: (value) =>
                                    value == null || value.isEmpty
                                    ? 'Required'
                                    : null,
                              ),

                              const SizedBox(height: 12),
                              Wrap(
                                alignment: WrapAlignment.spaceBetween,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 12,
                                runSpacing: 8,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: Checkbox(
                                          value: _rememberMe,
                                          activeColor: _accentGold,
                                          checkColor: Colors.black,
                                          side: BorderSide(color: _accentGold),
                                          onChanged: (value) {
                                            setState(() {
                                              _rememberMe = value ?? false;
                                            });
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        languageProvider.tr('rememberMe'),
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.outline,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                  TextButton(
                                    onPressed: _showForgotPasswordDialog,
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: Text(
                                      languageProvider.tr('forgotPassword'),
                                      style: TextStyle(
                                        color: _accentGold,
                                        fontSize: 13,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                               if (_lockoutSecondsRemaining > 0) ...[
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.red.shade400, width: 1.5),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.shield_outlined, color: Colors.redAccent, size: 28),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              languageProvider.isTamil
                                                  ? 'பாதுகாப்பு பூட்டு (Brute-Force Attack Prevention)'
                                                  : 'Security Lockout (Brute-Force Prevention)',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.redAccent,
                                                fontSize: 13,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              languageProvider.isTamil
                                                  ? '5 முறை தவறான கடவுச்சொல். ${_lockoutSecondsRemaining} வினாடிகளில் மீண்டும் முயற்சிக்கவும்.'
                                                  : '5 consecutive failed attempts. Try again in ${_lockoutSecondsRemaining}s.',
                                              style: TextStyle(
                                                color: Theme.of(context).colorScheme.onSurface,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ] else
                                const SizedBox(height: 24),

                              // Login Button
                              Container(
                                width: double.infinity,
                                height: 56,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  gradient: _lockoutSecondsRemaining > 0
                                      ? LinearGradient(
                                          colors: [
                                            Colors.grey.shade700,
                                            Colors.grey.shade800,
                                          ],
                                        )
                                      : LinearGradient(
                                          colors: [
                                            Theme.of(context).colorScheme.primary,
                                            Theme.of(context).colorScheme.secondary,
                                          ],
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                        ),
                                  border: Border.all(
                                    color: _lockoutSecondsRemaining > 0
                                        ? Colors.grey.shade600
                                        : _accentGold.withValues(alpha: 0.5),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _lockoutSecondsRemaining > 0
                                          ? Colors.transparent
                                          : _accentGold.withValues(alpha: 0.2),
                                      blurRadius: 15,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: (isLoading || _lockoutSecondsRemaining > 0) ? null : _login,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: isLoading
                                      ? SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: CircularProgressIndicator(
                                            color: _accentGold,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : _lockoutSecondsRemaining > 0
                                          ? Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                const Icon(Icons.timer_outlined, color: Colors.white70, size: 20),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'LOCKED (${_lockoutSecondsRemaining}s)',
                                                  style: const TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white70,
                                                    letterSpacing: 1.2,
                                                  ),
                                                ),
                                              ],
                                            )
                                          : Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  languageProvider.tr('login'),
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Theme.of(context).colorScheme.onPrimary,
                                                    letterSpacing: 1.5,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Icon(
                                                  Icons.arrow_forward,
                                                  color: Theme.of(context).colorScheme.onPrimary,
                                                  size: 20,
                                                ),
                                              ],
                                            ),
                                ),
                              ),
                              const SizedBox(height: 32),

                              // Secure Access Divider
                              Row(
                                children: [
                                  Expanded(
                                    child: Divider(
                                      color: Theme.of(context).primaryColor,
                                      thickness: 1,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12.0,
                                    ),
                                    child: Icon(
                                      Icons.security,
                                      color: _accentGold,
                                      size: 20,
                                    ),
                                  ),
                                  Expanded(
                                    child: Divider(
                                      color: Theme.of(context).primaryColor,
                                      thickness: 1,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Center(
                                child: Text(
                                  'Secure access',
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .outline,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'v1.0.0',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.outline
                          .withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showForgotPasswordDialog() async {
    final resetUsernameController = TextEditingController(text: _usernameController.text);
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final dialogFormKey = GlobalKey<FormState>();

    bool obscureNewPassword = true;
    bool obscureConfirmPassword = true;
    bool isResetting = false;
    String? dialogError;

    await showDialog(
      context: context,
      barrierDismissible: !isResetting,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF1E2638)
                  : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: _accentGold.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              title: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: _accentGold.withValues(alpha: 0.2),
                    radius: 20,
                    child: Icon(Icons.lock_reset, color: _accentGold, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Reset Password',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 380,
                  child: Form(
                    key: dialogFormKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Enter your username and new password to reset account access.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Username or Email',
                          style: TextStyle(
                            color: _accentGold,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: resetUsernameController,
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                          decoration: InputDecoration(
                            hintText: 'Username',
                            prefixIcon: Icon(Icons.person, color: _accentGold, size: 20),
                            filled: true,
                            fillColor: Theme.of(context).brightness == Brightness.dark
                                ? Colors.black.withValues(alpha: 0.3)
                                : Colors.grey.shade100,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Enter username' : null,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'New Password',
                          style: TextStyle(
                            color: _accentGold,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: newPasswordController,
                          obscureText: obscureNewPassword,
                          onChanged: (val) => setDialogState(() {}),
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                          decoration: InputDecoration(
                            hintText: 'New Password',
                            prefixIcon: Icon(Icons.lock_outline, color: _accentGold, size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(
                                obscureNewPassword ? Icons.visibility_off : Icons.visibility,
                                color: _accentGold.withValues(alpha: 0.7),
                                size: 20,
                              ),
                              onPressed: () {
                                setDialogState(() {
                                  obscureNewPassword = !obscureNewPassword;
                                });
                              },
                            ),
                            filled: true,
                            fillColor: Theme.of(context).brightness == Brightness.dark
                                ? Colors.black.withValues(alpha: 0.3)
                                : Colors.grey.shade100,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Enter new password';
                            if (v.length < 4) return 'Min 4 characters';
                            return null;
                          },
                        ),
                        PasswordStrengthMeter(password: newPasswordController.text),
                        const SizedBox(height: 16),
                        Text(
                          'Confirm New Password',
                          style: TextStyle(
                            color: _accentGold,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: confirmPasswordController,
                          obscureText: obscureConfirmPassword,
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                          decoration: InputDecoration(
                            hintText: 'Confirm New Password',
                            prefixIcon: Icon(Icons.lock, color: _accentGold, size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(
                                obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                                color: _accentGold.withValues(alpha: 0.7),
                                size: 20,
                              ),
                              onPressed: () {
                                setDialogState(() {
                                  obscureConfirmPassword = !obscureConfirmPassword;
                                });
                              },
                            ),
                            filled: true,
                            fillColor: Theme.of(context).brightness == Brightness.dark
                                ? Colors.black.withValues(alpha: 0.3)
                                : Colors.grey.shade100,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          validator: (v) {
                            if (v != newPasswordController.text) return 'Passwords do not match';
                            return null;
                          },
                        ),
                        if (dialogError != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            dialogError!,
                            style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isResetting ? null : () => Navigator.pop(dialogContext),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: Theme.of(context).colorScheme.outline),
                  ),
                ),
                ElevatedButton(
                  onPressed: isResetting
                      ? null
                      : () async {
                          if (!dialogFormKey.currentState!.validate()) return;
                          setDialogState(() {
                            isResetting = true;
                            dialogError = null;
                          });

                          try {
                            final success = await AuthService.resetPassword(
                              resetUsernameController.text.trim(),
                              newPasswordController.text,
                            );

                            if (success && mounted) {
                              Navigator.pop(dialogContext);
                              setState(() {
                                _usernameController.text = resetUsernameController.text.trim();
                                _passwordController.text = newPasswordController.text;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Password reset successfully! You can now log in.'),
                                  backgroundColor: Colors.green,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          } catch (e) {
                            setDialogState(() {
                              isResetting = false;
                              dialogError = e.toString().replaceAll('Exception: ', '');
                            });
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accentGold,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: isResetting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                        )
                      : const Text(
                          'RESET PASSWORD',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool isPassword = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword ? _obscurePassword : false,
      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
        ),
        prefixIcon: Icon(icon, color: _accentGold),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: _accentGold.withValues(alpha: 0.7),
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              )
            : null,
        filled: true,
        fillColor: Theme.of(context).brightness == Brightness.dark 
            ? Theme.of(context).primaryColor.withValues(alpha: 0.6)
            : Theme.of(context).colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _accentGold.withValues(alpha: 0.5)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade400),
        ),
      ),
      validator: validator,
    );
  }
}
