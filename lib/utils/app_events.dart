import 'package:flutter/foundation.dart';

class AppEvents {
  // Global notifier to trigger UI refreshes across tabs and screens
  static final ValueNotifier<int> refreshData = ValueNotifier<int>(0);

  // Global notifier to switch bottom navigation tabs
  static final ValueNotifier<int?> switchTab = ValueNotifier<int?>(null);

  static void triggerRefresh() {
    refreshData.value++;
  }

  static void goToTab(int index) {
    switchTab.value = index;
  }
}
