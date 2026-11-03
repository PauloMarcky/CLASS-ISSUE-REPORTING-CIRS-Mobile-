import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../models/issue.dart';
import '../models/issue_category.dart';
import '../models/issue_priority.dart';
import '../models/issue_status.dart';
import '../models/user_role.dart';
import '../services/api_client.dart';
import '../widgets/state_message.dart';

/// Shows every issue with its automation outcome: category, team, priority,
/// and whether the aging job escalated it.
class IssueListScreen extends StatefulWidget {
  const IssueListScreen({super.key, required this.api, required this.user});

  final ApiClient api;
  final AppUser user;

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
        title: const Text('All Issues'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            tooltip: 'Refresh',
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: _body(),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return StateMessage(
        icon: Icons.cloud_off_outlined,
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
        constraints: const BoxConstraints(maxWidth: 900),
        child: ListView.separated(
          padding: const EdgeInsets.all(24),
          itemCount: _issues.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) => _IssueCard(
            issue: _issues[i],
            api: widget.api,
            user: widget.user,
            onUpdated: _load,
          ),
        ),
      ),
    );
  }
}

class _IssueCard extends StatefulWidget {
  const _IssueCard({
    required this.issue,
    required this.api,
    required this.user,
    required this.onUpdated,
  });
  final Issue issue;
  final ApiClient api;
  final AppUser user;
  final VoidCallback onUpdated;

  @override
  State<_IssueCard> createState() => _IssueCardState();
}

class _IssueCardState extends State<_IssueCard> {
  bool _updating = false;

  List<IssueStatus> _availableStatuses() {
    final allowed = widget.issue.status.allowedNext;
    switch (widget.user.role) {
      case UserRole.coordinator:
        return allowed;
      case UserRole.facilitiesStaff:
        if (widget.issue.assignedToId != widget.user.id) return const [];
        return allowed
            .where((status) =>
                status == IssueStatus.inProgress ||
                status == IssueStatus.resolved)
            .toList();
      case UserRole.student:
      case UserRole.faculty:
        if (widget.issue.reporterId != widget.user.id) return const [];
        return allowed.where((status) => status == IssueStatus.verified).toList();
    }
  }

  Future<void> _assignFacilitator() async {
    setState(() => _updating = true);
    try {
      final facilitators = await widget.api.listFacilitators();
      if (!mounted) return;
      final selected = await showDialog<AppUser>(
        context: context,
        builder: (context) => SimpleDialog(
          title: const Text('Assign facilitator'),
          children: facilitators
              .map(
                (facilitator) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(context, facilitator),
                  child: Text(facilitator.name),
                ),
              )
              .toList(),
        ),
      );
      if (selected == null) return;
      await widget.api.updateIssue(
        issueId: widget.issue.id,
        assignedToId: selected.id,
        status: widget.issue.status == IssueStatus.categorized
            ? IssueStatus.assigned.name
            : null,
      );
      if (mounted) widget.onUpdated();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  void _showUpdateDialog() {
    final canCategorize = widget.user.role.canCategorizeAndAssign;
    final nextStatuses = _availableStatuses()
        .where((status) =>
            status != IssueStatus.assigned || widget.issue.assignedToId != null)
        .toList();
    if (nextStatuses.isEmpty && !canCategorize) return;

    showDialog(
      context: context,
      builder: (context) {
        IssueCategory? selectedCategory = widget.issue.category;
        IssueStatus? selectedStatus =
            nextStatuses.isEmpty ? null : nextStatuses.first;
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: Text(canCategorize ? 'Review issue' : 'Update Status'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current status: ${widget.issue.status.label}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                if (canCategorize) ...[
                  const SizedBox(height: 16),
                  DropdownButtonFormField<IssueCategory>(
                    initialValue: selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                    hint: const Text('Select a category'),
                    items: IssueCategory.values
                        .map(
                          (category) => DropdownMenuItem(
                            value: category,
                            child: Text(category.label),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setDialogState(() => selectedCategory = value),
                  ),
                ],
                if (nextStatuses.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  DropdownButtonFormField<IssueStatus>(
                    initialValue: selectedStatus,
                    decoration: const InputDecoration(
                      labelText: 'Next status',
                      border: OutlineInputBorder(),
                    ),
                    items: nextStatuses
                        .map(
                          (status) => DropdownMenuItem(
                            value: status,
                            child: Text(status.label),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setDialogState(() => selectedStatus = value),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: (canCategorize && selectedCategory == null) ||
                        (selectedStatus == null && nextStatuses.isNotEmpty)
                    ? null
                    : () async {
                        Navigator.pop(context);
                        setState(() => _updating = true);
                        try {
                          await widget.api.updateIssue(
                            issueId: widget.issue.id,
                            category: selectedCategory?.name,
                            status: selectedStatus?.name,
                          );
                          if (mounted) widget.onUpdated();
                        } on ApiException catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.message)),
                            );
                          }
                        } finally {
                          if (mounted) setState(() => _updating = false);
                        }
                      },
                child: const Text('Save'),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getStatusColor(IssueStatus status) {
    switch (status) {
      case IssueStatus.reported:
        return Colors.blue;
      case IssueStatus.categorized:
        return Colors.indigo;
      case IssueStatus.assigned:
        return Colors.purple;
      case IssueStatus.inProgress:
        return Colors.orange;
      case IssueStatus.resolved:
        return Colors.teal;
      case IssueStatus.verified:
        return Colors.green;
      case IssueStatus.closed:
        return Colors.grey;
    }
  }

  Color _getPriorityColor(IssuePriority priority) {
    switch (priority) {
      case IssuePriority.low:
        return Colors.blue;
      case IssuePriority.medium:
        return Colors.orange;
      case IssuePriority.high:
        return Colors.deepOrange;
      case IssuePriority.urgent:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nextStatuses = _availableStatuses();
    final statusColor = _getStatusColor(widget.issue.status);
    final priorityColor = _getPriorityColor(widget.issue.priority);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '#${widget.issue.id}',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.issue.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 16,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Reported by: ${widget.issue.reporterName ?? 'Unknown'}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              widget.issue.location,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (nextStatuses.isNotEmpty ||
                    widget.user.role.canCategorizeAndAssign)
                  IconButton(
                    icon: _updating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.edit_outlined),
                    tooltip: 'Update status',
                    onPressed: _updating ? null : _showUpdateDialog,
                  ),
                if (widget.user.role.canCategorizeAndAssign &&
                    widget.issue.status == IssueStatus.categorized &&
                    widget.issue.assignedToId == null)
                  IconButton(
                    icon: const Icon(Icons.person_add_outlined),
                    tooltip: 'Assign facilitator',
                    onPressed: _updating ? null : _assignFacilitator,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (widget.user.role.canVerifyResolution &&
                widget.issue.reporterId == widget.user.id &&
                widget.issue.status == IssueStatus.resolved)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.teal[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.teal[200]!),
                ),
                child: const Text(
                  'Action required: check the repair and verify this issue if it is fixed.',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    widget.issue.status.label,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                if (widget.issue.category != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      widget.issue.category!.label,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber[50],
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.amber[200]!),
                    ),
                    child: Text(
                      'Needs coordinator',
                      style: TextStyle(
                        color: Colors.amber[800],
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: priorityColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: priorityColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.flag, size: 12, color: priorityColor),
                      const SizedBox(width: 4),
                      Text(
                        widget.issue.priority.label,
                        style: TextStyle(
                          color: priorityColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.issue.assignedToName != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.purple[50],
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.purple[200]!),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.person,
                          size: 12,
                          color: Colors.purple[700],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.issue.assignedToName!,
                          style: TextStyle(
                            color: Colors.purple[800],
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (widget.issue.routedTeam != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.group_outlined,
                          size: 12,
                          color: Colors.blue[700],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.issue.routedTeam!,
                          style: TextStyle(
                            color: Colors.blue[800],
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (widget.issue.isEscalated)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.priority_high,
                          size: 14,
                          color: Colors.red[700],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Escalated',
                          style: TextStyle(
                            color: Colors.red[800],
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
