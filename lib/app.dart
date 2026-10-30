import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'services/api_client.dart';
import 'screens/login_screen.dart';
import 'state/session_controller.dart';
import 'theme/app_theme.dart';

class SrmsApp extends StatefulWidget {
  const SrmsApp({super.key});

  @override
  State<SrmsApp> createState() => _SrmsAppState();
}

class _SrmsAppState extends State<SrmsApp> {
  final _session = SessionController();
  final _api = ApiClient();

  @override
  void dispose() {
    _session.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Classroom Issue Reporting',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: ListenableBuilder(
        listenable: _session,
        builder: (context, _) {
          final user = _session.user;
          if (user == null) {
            return LoginScreen(session: _session);
          }
          return HomeScreen(user: user, api: _api, onLogout: _session.logout);
        },
      ),
    );
  }
}