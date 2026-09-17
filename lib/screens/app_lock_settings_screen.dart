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
  int _autoLockTimeoutMinutes = 1;

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
    final timeout = await AppLockService.getAutoLockTimeoutMinutes();

    setState(() {
      _isLockEnabled = lockEnabled;
      _isBiometricEnabled = bioEnabled;
      _canCheckBiometrics = canBio;
      _hasSavedPin = pin != null && pin.isNotEmpty;
      _autoLockTimeoutMinutes = timeout;
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

  Future<void> _selectTimeoutDialog() async {
    final options = [
      {'label': 'Immediately (When Minimized)', 'value': 0},
      {'label': '1 Minute of inactivity', 'value': 1},
      {'label': '3 Minutes of inactivity', 'value': 3},
      {'label': '5 Minutes of inactivity', 'value': 5},
    ];

    final selected = await showDialog<int>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('Select Auto-Lock Timeout', style: TextStyle(fontWeight: FontWeight.bold)),
          children: options.map((opt) {
            final val = opt['value'] as int;
            final label = opt['label'] as String;
            final isSelected = val == _autoLockTimeoutMinutes;
            return SimpleDialogOption(
              onPressed: () => Navigator.pop(context, val),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                      color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Theme.of(context).colorScheme.primary : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );

    if (selected != null && selected != _autoLockTimeoutMinutes) {
      await AppLockService.setAutoLockTimeoutMinutes(selected);
      setState(() => _autoLockTimeoutMinutes = selected);
      if (mounted) {
        _showSnackBar(
          selected == 0
              ? 'Auto-lock set to Immediate'
              : 'Auto-lock set to $selected minute${selected > 1 ? 's' : ''}',
        );
      }
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

                // Auto-Lock Timeout Tile
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
                    onTap: _selectTimeoutDialog,
                    leading: Icon(
                      Icons.timer_outlined,
                      color: colorScheme.primary,
                    ),
                    title: const Text(
                      'Auto-Lock Timeout',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      _autoLockTimeoutMinutes == 0
                          ? 'Lock immediately when minimized'
                          : 'Lock after $_autoLockTimeoutMinutes minute${_autoLockTimeoutMinutes > 1 ? 's' : ''} of inactivity',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: Icon(
                      Icons.chevron_right,
                      color: colorScheme.outline,
                    ),
                  ),
                ),

                // Biometrics Switch Tile
                if (_canCheckBiometrics)
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
                    subtitle: Text(
                      _hasSavedPin ? 'Update 4-digit security code' : 'Create 4-digit security code',
                      style: const TextStyle(fontSize: 12),
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
