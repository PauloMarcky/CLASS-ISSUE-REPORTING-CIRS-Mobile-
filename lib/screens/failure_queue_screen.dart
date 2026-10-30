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
      appBar: AppBar(title: const Text('Automation review')),
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
        icon: Icons.cloud_off,
        message: _error!,
        actionLabel: 'Try again',
        onAction: _load,
      );
    }
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: _busy ? null : _runEscalation,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Run escalation check now'),
              ),
            ),
            const SizedBox(height: 16),
            if (_items.isEmpty)
              const SizedBox(
                height: 240,
                child: StateMessage(
                  icon: Icons.done_all,
                  message: 'Nothing needs manual action.',
                ),
              )
            else
              for (final item in _items)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.report_problem_outlined),
                    title: Text('${item.job}'
                        '${item.issueId != null ? '  (issue #${item.issueId})' : ''}'),
                    subtitle: Text('${item.reasonLabel}. Code: ${item.errorCode}. '
                        'Attempts: ${item.attempts}.'),
                    trailing: TextButton(
                      onPressed: _busy ? null : () => _resolve(item),
                      child: const Text('Mark handled'),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
