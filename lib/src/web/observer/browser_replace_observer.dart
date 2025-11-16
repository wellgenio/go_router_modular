import 'package:flutter/widgets.dart';
import 'web_channel_stub.dart' if (dart.library.html) 'web_channel.dart';

/// Observer that synchronizes browser URL with navigation changes
/// using `replaceState` instead of `pushState` to avoid cluttering browser history.
///
/// This observer is designed for web applications where you want to keep the
/// browser URL in sync with the Flutter navigation state, but without creating
/// multiple history entries for each navigation action. This is particularly
/// useful for single-page applications (SPAs) where you want a clean history
/// stack.
///
/// ## How it works
///
/// The observer listens to navigation events and updates the browser URL using
/// `history.replaceState()` instead of `history.pushState()`. This means:
///
/// - The URL bar reflects the current route
/// - No new history entries are created on navigation
/// - The browser back button behavior is preserved naturally
///
/// ## Platform Support
///
/// This observer uses conditional imports:
/// - On web platforms (`dart.library.html`): Uses the actual browser API
/// - On non-web platforms: Uses a stub implementation (no-op)
///
/// ## Usage
///
/// Add this observer to your `GoRouter` configuration:
///
/// ```dart
/// final router = GoRouter(
///   routes: [...],
///   observers: [
///     BrowserReplaceObserver(),
///   ],
/// );
/// ```
///
/// ## Navigation Behavior
///
/// - **Push operations** (`didPush`): URL is replaced to match the new route
/// - **Replace operations** (`didReplace`): URL is replaced to match the new route
/// - **Pop operations** (`didPop`): No action taken - browser handles back navigation naturally
///
/// ## URL Resolution Strategy
///
/// The observer determines the URL to use in the following priority order:
///
/// 1. If `route.settings.arguments` is a `String`, use it as the URL
/// 2. Otherwise, use `Uri.base.path` (current browser path)
///
/// The URL is normalized to always start with `/`.
class BrowserReplaceObserver extends NavigatorObserver {
  /// Called when a new route has been pushed onto the navigator.
  ///
  /// This method is triggered when a new route is added to the navigation stack
  /// (e.g., using `Navigator.push()` or `GoRouter.push()`).
  ///
  /// The browser URL is immediately updated to reflect the new route using
  /// `history.replaceState()`, which updates the URL without creating a new
  /// history entry.
  ///
  /// - [route]: The route that was pushed onto the navigator
  /// - [previousRoute]: The route that was previously on top of the navigator,
  ///   or `null` if this is the first route
  @override
  void didPush(Route route, Route? previousRoute) {
    _replaceBrowserUrl(route);
  }

  /// Called when a route has been replaced in the navigator.
  ///
  /// This method is triggered when a route is replaced with another route
  /// (e.g., using `Navigator.pushReplacement()` or `GoRouter.pushReplacement()`).
  ///
  /// The browser URL is updated to reflect the new route, replacing the current
  /// history entry rather than creating a new one.
  ///
  /// - [newRoute]: The route that replaced the old route, or `null` if no route
  ///   was provided
  /// - [oldRoute]: The route that was replaced, or `null` if no route was provided
  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    if (newRoute != null) {
      _replaceBrowserUrl(newRoute);
    }
  }

  /// Called when a route has been popped from the navigator.
  ///
  /// This method is intentionally left empty because:
  ///
  /// - When the user presses the browser back button, the browser automatically
  ///   handles the URL change and history navigation
  /// - When Flutter pops a route programmatically, the browser's history stack
  ///   should remain unchanged to maintain consistency
  ///
  /// By not replacing the URL on pop, we allow the browser's natural back/forward
  /// navigation to work correctly.
  ///
  /// - [route]: The route that was popped from the navigator
  /// - [previousRoute]: The route that is now on top of the navigator after
  ///   the pop operation, or `null` if the navigator is now empty
  @override
  void didPop(Route route, Route? previousRoute) {
    // Don't replace URL on pop - browser back button handles this naturally
  }

  /// Replaces the browser URL to match the current route.
  ///
  /// This private method extracts the URL from the route settings and updates
  /// the browser's address bar using `history.replaceState()`. The URL is
  /// normalized to ensure it always starts with `/`.
  ///
  /// ## URL Resolution Priority
  ///
  /// 1. **Route arguments as String**: If `route.settings.arguments` is a `String`,
  ///    it's used directly as the URL. This allows explicit URL specification.
  ///
  /// 2. **Current browser path**: Otherwise, `Uri.base.path` is used. This relies
  ///    on GoRouter having already updated the URL, and we're just ensuring the
  ///    history entry is replaced rather than pushed.
  ///
  /// ## URL Normalization
  ///
  /// The URL is normalized to ensure it starts with `/`. If the URL doesn't
  /// start with `/`, a leading slash is prepended.
  ///
  /// ## Platform Behavior
  ///
  /// - **Web platforms**: Calls `replaceBrowserUrl()` which uses `html.window.history.replaceState()`
  /// - **Non-web platforms**: Calls `replaceBrowserUrl()` which is a no-op stub
  ///
  /// - [route]: The route from which to extract the URL information
  void _replaceBrowserUrl(Route route) {
    final settings = route.settings;
    String url = '/';

    // Priority 1: Use route arguments if it's a String (explicit URL)
    if (settings.arguments is String) {
      url = settings.arguments as String;
    } else if (settings.name != null) {
      // Priority 2: If we have a route name, use current path as fallback
      // GoRouter should already have updated the URL
      url = Uri.base.path;
    } else {
      // Priority 3: Default to current browser path
      url = Uri.base.path;
    }

    // Normalize URL - ensure it starts with /
    if (!url.startsWith('/')) {
      url = '/$url';
    }

    // Use history.replaceState to update URL without adding to history
    replaceBrowserUrl(url);
  }
}
