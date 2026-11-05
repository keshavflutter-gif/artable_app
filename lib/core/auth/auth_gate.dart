import 'package:flutter/foundation.dart';

/// Lightweight auth flag for [GoRouter] redirects (avoids Cubit/context cycles).
class AuthGate extends ChangeNotifier {
  AuthGate._();
  static final AuthGate instance = AuthGate._();

  bool _initialized = false;
  bool _isLoggedIn = false;

  bool get initialized => _initialized;
  bool get isLoggedIn => _isLoggedIn;

  void markInitialized({required bool isLoggedIn}) {
    _initialized = true;
    if (_isLoggedIn != isLoggedIn) {
      _isLoggedIn = isLoggedIn;
    }
    notifyListeners();
  }

  void setLoggedIn(bool value) {
    if (_isLoggedIn == value && _initialized) return;
    _initialized = true;
    _isLoggedIn = value;
    notifyListeners();
  }
}
