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
      appBar: AppBar(title: const Text('Report an Issue')),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: ListView(
            padding: const EdgeInsets.all(32),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Issue Details', style: theme.textTheme.titleLarge),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _title,
                          enabled: !_loading,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Title',
                            hintText: 'Projector not working',
                            prefixIcon: Icon(Icons.title_outlined),
                          ),
                          validator: (v) => _check(v, 'Title', 5, 120),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _location,
                          enabled: !_loading,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Location',
                            hintText: 'Science Building - Room 204',
                            prefixIcon: Icon(Icons.location_on_outlined),
                          ),
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
                            hintText: 'Describe the issue in detail...',
                            alignLabelWithHint: true,
                            prefixIcon: Icon(Icons.description_outlined),
                          ),
                          validator: (v) => _check(v, 'Description', 10, 2000),
                        ),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: _loading ? null : _submit,
                          icon: _loading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.send_outlined),
                          label: Text(_loading ? 'Submitting...' : 'Submit report'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_errorMessage != null)
                Card(
                  color: theme.colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: theme.colorScheme.onErrorContainer,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _errorMessage!,
                                style: TextStyle(
                                  color: theme.colorScheme.onErrorContainer,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              for (final d in _errorDetails)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    '• $d',
                                    style: TextStyle(
                                      color: theme.colorScheme.onErrorContainer,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (_duplicate != null)
                Card(
                  color: Colors.orange[50],
                  child: ListTile(
                    leading: Icon(Icons.warning_amber_rounded, color: Colors.orange[700]),
                    title: Text(
                      'Similar issue already reported',
                      style: TextStyle(
                        color: Colors.orange[900],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      '#${_duplicate!.existingId}: ${_duplicate!.existingTitle} '
                      '(${_duplicate!.existingStatus}). No new report was created.',
                      style: TextStyle(color: Colors.orange[800]),
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
      color: Colors.green[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.green[600], size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Report #${issue.id} Received',
                    style: TextStyle(
                      color: Colors.green[900],
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    routed
                        ? 'Routed to ${issue.routedTeam} as ${issue.category!.label}, priority ${issue.priority.label}.'
                        : 'Automatic routing could not decide. A coordinator will review it.',
                    style: TextStyle(color: Colors.green[800], fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
