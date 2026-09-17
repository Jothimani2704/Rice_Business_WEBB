import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'screens/app_lock_screen.dart';
import 'services/app_lock_service.dart';
import 'widgets/skeleton_loader.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
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

  @override
  State<AppLockWrapper> createState() => _AppLockWrapperState();
}

class _AppLockWrapperState extends State<AppLockWrapper> with WidgetsBindingObserver {
  bool _isUnlocked = false;
  bool _isCheckingLock = true;
  DateTime? _pausedTimestamp;

  void _lockApp() {
    setState(() {
      _isUnlocked = false;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialLockCheck();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _initialLockCheck() async {
    final lockEnabled = await AppLockService.isLockEnabled();
    if (mounted) {
      setState(() {
        _isUnlocked = !lockEnabled;
        _isCheckingLock = false;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pausedTimestamp = DateTime.now();
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

    // Only re-lock if the app was actually in background (paused) for more than 2 seconds.
    // Short pauses (like OS system dialogs / fingerprint overlay popping up) will NOT re-lock!
    if (_pausedTimestamp != null) {
      final elapsedSeconds = DateTime.now().difference(_pausedTimestamp!).inSeconds;
      _pausedTimestamp = null;
      if (elapsedSeconds >= 2) {
        setState(() {
          _isUnlocked = false;
        });
      }
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
        },
      );
    }

    return widget.child;
  }
}
