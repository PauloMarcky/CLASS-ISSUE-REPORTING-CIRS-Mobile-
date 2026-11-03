import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../models/automation_failure.dart';
import '../services/api_client.dart';
import '../widgets/state_message.dart';

/// Human work queue for automation steps that failed for good or ran out of
/// retries. Staff can mark an item handled or run the escalation job now.
class FailureQueueScreen extends StatefulWidget {
  const FailureQueueScreen({super.key, required this.user, required this.api});

  final AppUser user;
  final ApiClient api;

  @override
  State<FailureQueueScreen> createState() => _FailureQueueScreenState();
}

class _FailureQueueScreenState extends State<FailureQueueScreen> {
  bool _loading = true;
  bool _busy = false;
  String? _error;
  List<AutomationFailure> _items = const [];

  bool get _allowed => widget.user.role.canReviewAutomation;

  @override
  void initState() {
    super.initState();
    if (_allowed) {
      _load();
    } else {
      _loading = false;
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await widget.api.listFailures(actorId: widget.user.id);
      if (!mounted) return;
      setState(() => _items = items);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _resolve(AutomationFailure item) async {
    setState(() => _busy = true);
    try {
      await widget.api
          .resolveFailure(actorId: widget.user.id, failureId: item.id);
      if (!mounted) return;
      setState(() => _items = _items.where((e) => e.id != item.id).toList());
      _toast('Marked as handled.');
    } on ApiException catch (e) {
      if (mounted) _toast(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _runEscalation() async {
    setState(() => _busy = true);
    try {
      final r = await widget.api.runEscalation(actorId: widget.user.id);
      if (!mounted) return;
      _toast(r.ok
          ? 'Escalation check done: ${r.escalated} of ${r.candidates} escalated.'
          : 'The check could not finish. See the queue for details.');
      await _load();
    } on ApiException catch (e) {
      if (mounted) _toast(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Automation Review'),
      ),
      body: _body(),
    );
  }

  Widget _body() {
    if (!_allowed) {
      return const StateMessage(
        icon: Icons.lock_outline,
        message: 'Only coordinators and facilities staff can review '
            'automation failures.',
      );
    }
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return StateMessage(
        icon: Icons.cloud_off_outlined,
        message: _error!,
        actionLabel: 'Try again',
        onAction: _load,
      );
    }
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Manual Work Queue',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _runEscalation,
                  icon: _busy 
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.play_arrow_outlined, size: 18),
                  label: const Text('Run Escalation Check'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Review and resolve automation steps that failed permanently or ran out of retries.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            if (_items.isEmpty)
              const SizedBox(
                height: 240,
                child: StateMessage(
                  icon: Icons.check_circle_outline,
                  message: 'Nothing needs manual action. The system is running smoothly.',
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return _FailureCard(
                    item: item,
                    onResolve: () => _resolve(item),
                    isBusy: _busy,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _FailureCard extends StatelessWidget {
  const _FailureCard({
    required this.item,
    required this.onResolve,
    required this.isBusy,
  });

  final AutomationFailure item;
  final VoidCallback onResolve;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPermanent = item.reason == 'permanent';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isPermanent ? Colors.red[50] : Colors.orange[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPermanent ? Icons.error_outline : Icons.warning_amber_rounded,
                color: isPermanent ? Colors.red[700] : Colors.orange[700],
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.job.replaceAll('_', ' ').toUpperCase(),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isPermanent ? Colors.red[50] : Colors.orange[50],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.reasonLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isPermanent ? Colors.red[800] : Colors.orange[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (item.issueId != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Icon(Icons.link, size: 14, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text(
                            'Related to Issue #${item.issueId}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Row(
                    children: [
                      Icon(Icons.code, size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        'Error Code: ${item.errorCode}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.history, size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        'Attempts: ${item.attempts}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            FilledButton.tonal(
              onPressed: isBusy ? null : onResolve,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              child: const Text('Mark Handled'),
            ),
          ],
        ),
      ),
    );
  }
}
