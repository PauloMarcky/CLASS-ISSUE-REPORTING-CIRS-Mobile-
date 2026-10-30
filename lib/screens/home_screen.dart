import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../services/api_client.dart';
import 'failure_queue_screen.dart';
import 'issue_list_screen.dart';
import 'report_issue_screen.dart';

/// Role-aware home: shows what the user may do and links to the screens.
class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.user,
    required this.api,
    required this.onLogout,
  });

  final AppUser user;
  final ApiClient api;
  final VoidCallback onLogout;

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

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
      ('Review automation failures', role.canReviewAutomation),
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
              Text('Welcome, ${user.name}',
                  style: theme.textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(role.label, style: theme.textTheme.titleMedium),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  if (role.canReportIssue)
                    FilledButton.icon(
                      onPressed: () => _open(
                          context, ReportIssueScreen(user: user, api: api)),
                      icon: const Icon(Icons.add),
                      label: const Text('Report an issue'),
                    ),
                  FilledButton.tonalIcon(
                    onPressed: () =>
                        _open(context, IssueListScreen(api: api)),
                    icon: const Icon(Icons.list),
                    label: const Text('View issues'),
                  ),
                  if (role.canReviewAutomation)
                    FilledButton.tonalIcon(
                      onPressed: () => _open(
                          context, FailureQueueScreen(user: user, api: api)),
                      icon: const Icon(Icons.report_problem_outlined),
                      label: const Text('Automation review'),
                    ),
                ],
              ),
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
            ],
          ),
        ),
      ),
    );
  }
}
