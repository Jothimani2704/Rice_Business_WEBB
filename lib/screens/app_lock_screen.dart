import 'package:flutter/material.dart';
import '../services/app_lock_service.dart';

class AppLockScreen extends StatefulWidget {
  final VoidCallback onUnlocked;
  final bool isSettingUpPin;
  final Function(String pin)? onPinCreated;

  const AppLockScreen({
    super.key,
    required this.onUnlocked,
    this.isSettingUpPin = false,
    this.onPinCreated,
  });

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  String _enteredPin = '';
  String? _savedPin;
  String _errorMessage = '';
  bool _canUseBiometrics = false;
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    _initLockState();
  }

  Future<void> _initLockState() async {
    if (widget.isSettingUpPin) {
      return;
    }

    final pin = await AppLockService.getPin();
    final canBio = await AppLockService.canCheckBiometrics();
    final isBioEnabled = await AppLockService.isBiometricEnabled();

    setState(() {
      _savedPin = pin;
      _canUseBiometrics = canBio && isBioEnabled;
    });

    if (_canUseBiometrics) {
      _triggerBiometricAuth();
    }
  }

  Future<void> _triggerBiometricAuth() async {
    if (_isAuthenticating) return;
    setState(() {
      _isAuthenticating = true;
      _errorMessage = '';
    });

    final success = await AppLockService.authenticateWithBiometrics();
    if (!mounted) return;

    setState(() => _isAuthenticating = false);

    if (success) {
      widget.onUnlocked();
    } else {
      setState(() {
        _errorMessage = 'Biometric unlock failed. Please use PIN.';
      });
    }
  }

  void _onKeyPress(String val) {
    if (_enteredPin.length < 4) {
      setState(() {
        _enteredPin += val;
        _errorMessage = '';
      });

      if (_enteredPin.length == 4) {
        _verifyPin();
      }
    }
  }

  void _onDelete() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        _errorMessage = '';
      });
    }
  }

  void _verifyPin() {
    if (widget.isSettingUpPin) {
      if (widget.onPinCreated != null) {
        widget.onPinCreated!(_enteredPin);
      }
      return;
    }

    if (_savedPin == null || _savedPin == _enteredPin) {
      widget.onUnlocked();
    } else {
      setState(() {
        _errorMessage = 'Incorrect PIN. Try again.';
        _enteredPin = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: const Color(0xFF121915),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),

            // App Icon / Logo
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: primaryColor.withValues(alpha: 0.4),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.lock_rounded,
                color: primaryColor,
                size: 40,
              ),
            ),
            const SizedBox(height: 24),

            // Header Text
            Text(
              widget.isSettingUpPin ? 'Set Security PIN' : 'Rice Business App',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.isSettingUpPin
                  ? 'Enter a 4-digit PIN for app lock'
                  : 'Enter PIN or use Fingerprint to unlock',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 32),

            // 4 Dots PIN Indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                final isFilled = index < _enteredPin.length;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isFilled ? primaryColor : Colors.transparent,
                    border: Border.all(
                      color: isFilled ? primaryColor : Colors.white38,
                      width: 2,
                    ),
                  ),
                );
              }),
            ),

            // Error Message Text
            SizedBox(
              height: 40,
              child: Center(
                child: _errorMessage.isNotEmpty
                    ? Text(
                        _errorMessage,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    : null,
              ),
            ),

            const Spacer(),

            // Custom Keypad
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [
                  _buildKeypadRow(['1', '2', '3']),
                  const SizedBox(height: 16),
                  _buildKeypadRow(['4', '5', '6']),
                  const SizedBox(height: 16),
                  _buildKeypadRow(['7', '8', '9']),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Left Button: Biometrics or Empty
                      _canUseBiometrics && !widget.isSettingUpPin
                          ? _buildIconButton(
                              icon: Icons.fingerprint_rounded,
                              onPressed: _triggerBiometricAuth,
                              color: primaryColor,
                            )
                          : const SizedBox(width: 70, height: 70),

                      // Zero Button
                      _buildKeyButton('0'),

                      // Delete Button
                      _buildIconButton(
                        icon: Icons.backspace_outlined,
                        onPressed: _onDelete,
                        color: Colors.white70,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypadRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: keys.map((key) => _buildKeyButton(key)).toList(),
    );
  }

  Widget _buildKeyButton(String val) {
    return InkWell(
      onTap: () => _onKeyPress(val),
      borderRadius: BorderRadius.circular(35),
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.08),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.12),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          val,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(35),
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.05),
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          color: color,
          size: 28,
        ),
      ),
    );
  }
}
