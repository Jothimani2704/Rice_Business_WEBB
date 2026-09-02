import 'package:flutter/foundation.dart';

class AppEvents {
  // Global notifier to trigger UI refreshes across tabs and screens
  static final ValueNotifier<int> refreshData = ValueNotifier<int>(0);

  static void triggerRefresh() {
    refreshData.value++;
  }
}
