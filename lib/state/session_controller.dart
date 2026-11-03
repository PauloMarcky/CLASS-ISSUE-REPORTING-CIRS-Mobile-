import 'package:flutter/foundation.dart';

import '../services/api_client.dart';
import '../models/app_user.dart';

/// Holds the signed-in user for the whole app.
class SessionController extends ChangeNotifier {
  AppUser? _user;

  AppUser? get user => _user;

  bool get isLoggedIn => _user != null;

  /// Returns null on success, otherwise an error message for the UI.
  Future<String?> login(String email, String password) async {
    AppUser? match;
    try {
      match = await ApiClient().login(email: email, password: password);
    } on ApiException catch (e) {
      return e.message;
    }
    // match is set only when the server accepted the sign-in.
    _user = match;
    notifyListeners();
    return null;
  }

  void logout() {
    ApiClient.authToken = null;
    _user = null;
    notifyListeners();
  }
}