import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/language_provider.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'screens/app_lock_screen.dart';
import 'services/app_lock_service.dart';
import 'services/offline_sync_service.dart';
import 'widgets/skeleton_loader.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ],
      child: const RiceBusinessApp(),
    ),
  );
}

class RiceBusinessApp extends StatelessWidget {
  const RiceBusinessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          title: 'Rice Business App',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          builder: (context, child) {
            return ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
              child: child!,
            );
          },
          home: Consumer<AuthProvider>(
            builder: (context, auth, _) {
              if (auth.isLoading) {
                return const DashboardSkeleton();
              }
              if (!auth.isAuthenticated) {
                return const LoginScreen();
              }
              return const AppLockWrapper(child: MainScreen());
            },
          ),
        );
      },
    );
  }
}

class AppLockWrapper extends StatefulWidget {
  final Widget child;
  const AppLockWrapper({super.key, required this.child});

  static void lock(BuildContext context) {
    context.findAncestorStateOfType<_AppLockWrapperState>()?._lockApp();
  }

  static void resetTimer(BuildContext context) {
    context.findAncestorStateOfType<_AppLockWrapperState>()?._resetInactivityTimer();
  }

  @override
  State<AppLockWrapper> createState() => _AppLockWrapperState();
}

class _AppLockWrapperState extends State<AppLockWrapper> with WidgetsBindingObserver {
  bool _isUnlocked = false;
  bool _isCheckingLock = true;
  DateTime? _pausedTimestamp;
  Timer? _inactivityTimer;
  Timer? _autoSyncTimer;

  void _lockApp() {
    _inactivityTimer?.cancel();
    setState(() {
      _isUnlocked = false;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialLockCheck();
    _startAutoSyncWorker();
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    _autoSyncTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _startAutoSyncWorker() {
    _autoSyncTimer?.cancel();
    // Run initial sync after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        OfflineSyncService.syncPendingSales(context: context);
      }
    });

    // Periodically sync every 30 seconds
    _autoSyncTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        OfflineSyncService.syncPendingSales(context: context);
      }
    });
  }

  Future<void> _initialLockCheck() async {
    try {
      final lockEnabled = await AppLockService.isLockEnabled();
      if (mounted) {
        setState(() {
          _isUnlocked = !lockEnabled;
          _isCheckingLock = false;
        });
        if (_isUnlocked) {
          _resetInactivityTimer();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUnlocked = true;
          _isCheckingLock = false;
        });
      }
    }
  }

  Future<void> _resetInactivityTimer() async {
    _inactivityTimer?.cancel();
    if (!_isUnlocked) return;

    try {
      final lockEnabled = await AppLockService.isLockEnabled();
      if (!lockEnabled) return;

      final timeoutMinutes = await AppLockService.getAutoLockTimeoutMinutes();
      if (timeoutMinutes <= 0) return;

      _inactivityTimer = Timer(Duration(minutes: timeoutMinutes), () {
        if (mounted && _isUnlocked) {
          _lockApp();
        }
      });
    } catch (e) {
      // Ignore timer errors
    }
  }

  void _onUserInteraction() {
    if (_isUnlocked) {
      _resetInactivityTimer();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pausedTimestamp = DateTime.now();
      _inactivityTimer?.cancel();
    } else if (state == AppLifecycleState.resumed) {
      _handleResumed();
    }
  }

  Future<void> _handleResumed() async {
    final lockEnabled = await AppLockService.isLockEnabled();
    if (!lockEnabled) {
      if (!_isUnlocked) {
        setState(() => _isUnlocked = true);
      }
      return;
    }

    if (_pausedTimestamp != null) {
      final elapsedSeconds = DateTime.now().difference(_pausedTimestamp!).inSeconds;
      _pausedTimestamp = null;
      if (elapsedSeconds >= 2) {
        setState(() {
          _isUnlocked = false;
        });
        return;
      }
    }

    if (_isUnlocked) {
      _resetInactivityTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingLock) {
      return const DashboardSkeleton();
    }

    if (!_isUnlocked) {
      return AppLockScreen(
        onUnlocked: () {
          setState(() {
            _isUnlocked = true;
          });
          _resetInactivityTimer();
        },
      );
    }

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _onUserInteraction(),
      onPointerMove: (_) => _onUserInteraction(),
      child: widget.child,
    );
  }
}
