import 'package:flutter/material.dart';
import '../services/app_lock_service.dart';
import '../utils/app_toast.dart';
import 'app_lock_screen.dart';

class AppLockSettingsScreen extends StatefulWidget {
  const AppLockSettingsScreen({super.key});

  @override
  State<AppLockSettingsScreen> createState() => _AppLockSettingsScreenState();
}

class _AppLockSettingsScreenState extends State<AppLockSettingsScreen> {
  bool _isLockEnabled = false;
  bool _isBiometricEnabled = false;
  bool _canCheckBiometrics = false;
  bool _hasSavedPin = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    final lockEnabled = await AppLockService.isLockEnabled();
    final bioEnabled = await AppLockService.isBiometricEnabled();
    final canBio = await AppLockService.canCheckBiometrics();
    final pin = await AppLockService.getPin();

    setState(() {
      _isLockEnabled = lockEnabled;
      _isBiometricEnabled = bioEnabled;
      _canCheckBiometrics = canBio;
      _hasSavedPin = pin != null && pin.isNotEmpty;
      _isLoading = false;
    });
  }

  Future<void> _onToggleLock(bool value) async {
    if (value) {
      // If enabling lock and no PIN set yet, prompt to set PIN
      if (!_hasSavedPin) {
        await _promptCreatePin();
        final pin = await AppLockService.getPin();
        if (pin == null || pin.isEmpty) {
          return; // User cancelled or didn't complete PIN
        }
      }
      await AppLockService.setLockEnabled(true);
      setState(() => _isLockEnabled = true);
      _showSnackBar('App Lock enabled successfully');
    } else {
      await AppLockService.setLockEnabled(false);
      setState(() => _isLockEnabled = false);
      _showSnackBar('App Lock disabled');
    }
  }

  Future<void> _onToggleBiometric(bool value) async {
    await AppLockService.setBiometricEnabled(value);
    setState(() => _isBiometricEnabled = value);
    _showSnackBar(value ? 'Biometrics enabled' : 'Biometrics disabled');
  }

  Future<void> _promptCreatePin() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AppLockScreen(
          isSettingUpPin: true,
          onUnlocked: () {},
          onPinCreated: (newPin) async {
            await AppLockService.setPin(newPin);
            setState(() => _hasSavedPin = true);
            if (mounted) {
              Navigator.pop(context);
              _showSnackBar('PIN created successfully');
            }
          },
        ),
      ),
    );
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    if (isError) {
      AppToast.showError(context, msg);
    } else {
      AppToast.showSuccess(context, msg);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'App Security & Lock',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Header Banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.security_rounded,
                        color: colorScheme.primary,
                        size: 32,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Security & Biometrics',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Protect your rice business data with Fingerprint or 4-digit PIN lock.',
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Enable App Lock Switch Tile
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? theme.primaryColor.withValues(alpha: 0.5)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.05),
                    ),
                  ),
                  child: SwitchListTile(
                    value: _isLockEnabled,
                    onChanged: _onToggleLock,
                    activeColor: colorScheme.primary,
                    title: const Text(
                      'Enable App Lock',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text(
                      'Require PIN or Fingerprint when opening app',
                      style: TextStyle(fontSize: 12),
                    ),
                    secondary: Icon(
                      Icons.lock_outline_rounded,
                      color: colorScheme.primary,
                    ),
                  ),
                ),

                // Biometrics Switch Tile
                if (_isLockEnabled && _canCheckBiometrics)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? theme.primaryColor.withValues(alpha: 0.5)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.black.withValues(alpha: 0.05),
                      ),
                    ),
                    child: SwitchListTile(
                      value: _isBiometricEnabled,
                      onChanged: _onToggleBiometric,
                      activeColor: colorScheme.primary,
                      title: const Text(
                        'Fingerprint / Biometric Unlock',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: const Text(
                        'Unlock app using your device biometric scanner',
                        style: TextStyle(fontSize: 12),
                      ),
                      secondary: Icon(
                        Icons.fingerprint_rounded,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),

                // Change PIN Button
                if (_isLockEnabled)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? theme.primaryColor.withValues(alpha: 0.5)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.black.withValues(alpha: 0.05),
                      ),
                    ),
                    child: ListTile(
                      onTap: _promptCreatePin,
                      leading: Icon(
                        Icons.pin_rounded,
                        color: colorScheme.primary,
                      ),
                      title: Text(
                        _hasSavedPin ? 'Change Security PIN' : 'Set Security PIN',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: const Text(
                        'Update 4-digit security code',
                        style: TextStyle(fontSize: 12),
                      ),
                      trailing: Icon(
                        Icons.chevron_right,
                        color: colorScheme.outline,
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
