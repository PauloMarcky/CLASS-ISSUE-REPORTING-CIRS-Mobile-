import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../models/user_role.dart';
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

  IconData _iconForRole(UserRole role) {
    switch (role) {
      case UserRole.student:
        return Icons.school_outlined;
      case UserRole.faculty:
        return Icons.person_outline;
      case UserRole.facilitiesStaff:
        return Icons.engineering_outlined;
      case UserRole.coordinator:
        return Icons.admin_panel_settings_outlined;
    }
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
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            tooltip: 'Sign out',
            onPressed: onLogout,
          ),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: ListView(
            padding: const EdgeInsets.all(32),
            children: [
              // Welcome header
              Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Icon(
                      _iconForRole(role),
                      size: 32,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back, ${user.name.split(' ').first}',
                          style: theme.textTheme.headlineMedium,
                        ),
                        Text(role.label, style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Quick actions
              Text('Quick Actions', style: theme.textTheme.titleLarge),
              const SizedBox(height: 16),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  if (role.canReportIssue)
                    _ActionButton(
                      icon: Icons.add_circle_outline,
                      label: 'Report Issue',
                      color: theme.colorScheme.primary,
                      onTap: () => _open(
                          context, ReportIssueScreen(user: user, api: api)),
                    ),
                  _ActionButton(
                    icon: Icons.list_alt_outlined,
                    label: 'View Issues',
                    color: theme.colorScheme.secondary,
                    onTap: () =>
                        _open(context, IssueListScreen(api: api, user: user)),
                  ),
                  if (role.canReviewAutomation)
                    _ActionButton(
                      icon: Icons.report_problem_outlined,
                      label: 'Automation Review',
                      color: theme.colorScheme.tertiary,
                      onTap: () => _open(
                          context, FailureQueueScreen(user: user, api: api)),
                    ),
                ],
              ),
              const SizedBox(height: 40),

              // Permissions card
              Text('Your Permissions', style: theme.textTheme.titleLarge),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      for (final ability in abilities)
                        ListTile(
                          leading: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: ability.$2
                                  ? Colors.green[50]
                                  : Colors.grey[100],
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              ability.$2 ? Icons.check : Icons.close,
                              size: 18,
                              color: ability.$2 ? Colors.green : Colors.grey,
                            ),
                          ),
                          title: Text(
                            ability.$1,
                            style: TextStyle(
                              color: ability.$2
                                  ? Colors.grey[800]
                                  : Colors.grey[500],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 180,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }
}