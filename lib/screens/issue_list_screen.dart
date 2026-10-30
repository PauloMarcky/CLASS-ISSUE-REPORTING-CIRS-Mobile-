import 'package:flutter/material.dart';

import '../models/issue.dart';
import '../services/api_client.dart';
import '../widgets/state_message.dart';

/// Shows every issue with its automation outcome: category, team, priority,
/// and whether the aging job escalated it.
class IssueListScreen extends StatefulWidget {
  const IssueListScreen({super.key, required this.api});

  final ApiClient api;

  @override
  State<IssueListScreen> createState() => _IssueListScreenState();
}

class _IssueListScreenState extends State<IssueListScreen> {
  bool _loading = true;
  String? _error;
  List<Issue> _issues = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final issues = await widget.api.listIssues();
      if (!mounted) return;
      setState(() => _issues = issues);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Issues'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: _body(),
    );
  }

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return StateMessage(
        icon: Icons.cloud_off,
        message: _error!,
        actionLabel: 'Try again',
        onAction: _load,
      );
    }
    if (_issues.isEmpty) {
      return const StateMessage(
        icon: Icons.inbox_outlined,
        message: 'No issues have been reported yet.',
      );
    }
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _issues.length,
          itemBuilder: (context, i) => _IssueCard(issue: _issues[i]),
        ),
      ),
    );
  }
}

class _IssueCard extends StatelessWidget {
  const _IssueCard({required this.issue});
  final Issue issue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('#${issue.id}  ${issue.title}',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(issue.location, style: theme.textTheme.bodySmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                Chip(label: Text(issue.status.label)),
                Chip(label: Text(issue.category?.label ?? 'Needs coordinator')),
                Chip(label: Text('Priority: ${issue.priority.label}')),
                if (issue.category != null && issue.routedTeam != null)
                  Chip(label: Text(issue.routedTeam!)),
                if (issue.isEscalated)
                  Chip(
                    avatar: const Icon(Icons.priority_high, size: 16),
                    label: const Text('Escalated'),
                    backgroundColor: theme.colorScheme.errorContainer,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
