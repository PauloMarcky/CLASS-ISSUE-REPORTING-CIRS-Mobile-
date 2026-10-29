import 'package:flutter/foundation.dart';

import '../data/mock_users.dart';
import '../models/app_user.dart';

/// Holds the signed-in user for the whole app.
class SessionController extends ChangeNotifier {
  AppUser? _user;

  AppUser? get user => _user;

  bool get isLoggedIn => _user != null;

  /// Returns null on success, otherwise an error message for the UI.
  String? login(String email, String password) {
    final match = MockUsers.authenticate(email, password);
    if (match == null) return 'Invalid email or password.';
    _user = match;
    notifyListeners();
    return null;
  }

  void logout() {
    _user = null;
    notifyListeners();
  }
}