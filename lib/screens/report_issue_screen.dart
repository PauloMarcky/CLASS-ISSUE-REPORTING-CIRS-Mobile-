import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../models/issue.dart';
import '../services/api_client.dart';

/// Report a new issue. The server routes it automatically and may report
/// that a similar issue already exists.
class ReportIssueScreen extends StatefulWidget {
  const ReportIssueScreen({super.key, required this.user, required this.api});

  final AppUser user;
  final ApiClient api;

  @override
  State<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _location = TextEditingController();
  final _description = TextEditingController();

  bool _loading = false;
  String? _errorMessage;
  List<String> _errorDetails = const [];
  Issue? _created;
  DuplicateInfo? _duplicate;

  @override
  void dispose() {
    _title.dispose();
    _location.dispose();
    _description.dispose();
    super.dispose();
  }

  // Same limits as the server, so most mistakes are caught before sending.
  String? _check(String? value, String label, int min, int max) {
    final text = value?.trim() ?? '';
    if (text.length < min) return '$label needs at least $min characters.';
    if (text.length > max) return '$label must be at most $max characters.';
    return null;
  }

  Future<void> _submit() async {
    if (_loading || !_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
      _errorDetails = const [];
      _created = null;
      _duplicate = null;
    });
    try {
      final result = await widget.api.createIssue(
        reporterId: widget.user.id,
        title: _title.text,
        location: _location.text,
        description: _description.text,
      );
      if (!mounted) return;
      setState(() {
        _created = result.issue;
        _duplicate = result.duplicate;
      });
      if (result.issue != null) {
        _title.clear();
        _location.clear();
        _description.clear();
      }
    } on ValidationException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _errorDetails = e.details;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Report an issue')),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _title,
                      enabled: !_loading,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                          labelText: 'Title', hintText: 'Projector not working'),
                      validator: (v) => _check(v, 'Title', 5, 120),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _location,
                      enabled: !_loading,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                          labelText: 'Location',
                          hintText: 'Science Building - Room 204'),
                      validator: (v) => _check(v, 'Location', 3, 120),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _description,
                      enabled: !_loading,
                      minLines: 4,
                      maxLines: 6,
                      decoration: const InputDecoration(
                          labelText: 'What is wrong?',
                          alignLabelWithHint: true),
                      validator: (v) => _check(v, 'Description', 10, 2000),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Submit report'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (_errorMessage != null)
                Card(
                  color: theme.colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_errorMessage!,
                            style: TextStyle(
                                color: theme.colorScheme.onErrorContainer)),
                        for (final d in _errorDetails)
                          Text('- $d',
                              style: TextStyle(
                                  color: theme.colorScheme.onErrorContainer)),
                      ],
                    ),
                  ),
                ),
              if (_duplicate != null)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.content_copy),
                    title: const Text('Similar issue already reported'),
                    subtitle: Text(
                      '#${_duplicate!.existingId}: ${_duplicate!.existingTitle} '
                      '(${_duplicate!.existingStatus}). No new report was created.',
                    ),
                  ),
                ),
              if (_created != null) _SuccessCard(issue: _created!),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuccessCard extends StatelessWidget {
  const _SuccessCard({required this.issue});
  final Issue issue;

  @override
  Widget build(BuildContext context) {
    final routed = issue.category != null;
    return Card(
      child: ListTile(
        leading: const Icon(Icons.check_circle, color: Colors.green),
        title: Text('Report #${issue.id} received'),
        subtitle: Text(
          routed
              ? 'Routed to ${issue.routedTeam} as ${issue.category!.label}, '
                  'priority ${issue.priority.label}.'
              : 'Automatic routing could not decide. A coordinator will '
                  'review it.',
        ),
      ),
    );
  }
}
