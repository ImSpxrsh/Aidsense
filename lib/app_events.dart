import 'dart:async';

/// Simple app-wide event bus for one-off signals like "refresh resources".
class AppEvents {
  AppEvents._();

  static final _refreshResourcesController = StreamController<void>.broadcast();

  static Stream<void> get onRefreshResources =>
      _refreshResourcesController.stream;

  static void refreshResources() {
    try {
      _refreshResourcesController.add(null);
    } catch (_) {}
  }

  static void dispose() {
    _refreshResourcesController.close();
  }
}
