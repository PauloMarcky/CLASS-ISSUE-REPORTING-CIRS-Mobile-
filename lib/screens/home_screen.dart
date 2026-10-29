import 'package:flutter/material.dart';

import '../models/app_user.dart';

/// Placeholder home. Real role-specific screens replace this in later steps.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.user, required this.onLogout});

  final AppUser user;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final role = user.role;

    final abilities = <(String, bool)>[
      ('Report an issue', role.canReportIssue),
      ('Categorize and assign issues', role.canCategorizeAndAssign),
      ('Update repair progress', role.canUpdateProgress),
      ('Verify a resolution', role.canVerifyResolution),
      ('Close an issue', role.canClose),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Classroom Issue Reporting'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: onLogout,
          ),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Welcome, ${user.name}',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              Text(role.label, style: theme.textTheme.titleMedium),
              const SizedBox(height: 24),
              Text('What you can do', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    for (final ability in abilities)
                      ListTile(
                        leading: Icon(
                          ability.$2 ? Icons.check_circle : Icons.block,
                          color: ability.$2 ? Colors.green : Colors.grey,
                        ),
                        title: Text(ability.$1),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Issue screens arrive in the next steps.',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}