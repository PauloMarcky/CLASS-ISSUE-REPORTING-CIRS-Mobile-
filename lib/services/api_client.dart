import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/automation_failure.dart';
import '../models/issue.dart';

/// Base type for every error the UI has to handle.
/// Messages are already safe to show to a user.
class ApiException implements Exception {
  const ApiException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// The server could not be reached (offline, wrong address, timeout).
class NetworkException extends ApiException {
  const NetworkException()
      : super('Cannot reach the server. Check your connection and try again.');
}

/// The server answered with an error (5xx).
class ServerException extends ApiException {
  const ServerException()
      : super('The server had a problem. Please try again in a moment.');
}

/// The caller may not do this (401 or 403).
class ForbiddenException extends ApiException {
  const ForbiddenException()
      : super('You are not allowed to do this.');
}

/// The input was rejected (400). [details] lists what to fix.
class ValidationException extends ApiException {
  const ValidationException(super.message, this.details);
  final List<String> details;
}

/// A similar open issue already exists, so nothing new was created.
class DuplicateInfo {
  const DuplicateInfo({
    required this.existingId,
    required this.existingTitle,
    required this.existingStatus,
    required this.message,
  });
  final String existingId;
  final String existingTitle;
  final String existingStatus;
  final String message;
}

/// Result of reporting an issue: exactly one of the two is set.
class SubmitResult {
  const SubmitResult.created(Issue this.issue) : duplicate = null;
  const SubmitResult.duplicate(DuplicateInfo this.duplicate) : issue = null;
  final Issue? issue;
  final DuplicateInfo? duplicate;
}

class EscalationRunResult {
  const EscalationRunResult({
    required this.ok,
    required this.candidates,
    required this.escalated,
    required this.needsHuman,
  });
  final bool ok;
  final int candidates;
  final int escalated;
  final bool needsHuman;
}

class ApiClient {
  ApiClient({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? ApiConfig.baseUrl;

  final http.Client _client;
  final String _baseUrl;

  Future<SubmitResult> createIssue({
    required String reporterId,
    required String title,
    required String location,
    required String description,
  }) async {
    final res = await _request('POST', '/api/issues', body: {
      'title': title.trim(),
      'location': location.trim(),
      'description': description.trim(),
      'reporterId': reporterId,
    });
    final json = res.json as Map<String, dynamic>;
    if (json['duplicate'] == true) {
      final existing = json['existingIssue'] as Map<String, dynamic>;
      return SubmitResult.duplicate(DuplicateInfo(
        existingId: existing['id'] as String,
        existingTitle: existing['title'] as String,
        existingStatus: existing['status'] as String,
        message: json['message'] as String? ??
            'A similar open issue already exists.',
      ));
    }
    return SubmitResult.created(Issue.fromJson(json));
  }

  Future<List<Issue>> listIssues() async {
    final res = await _request('GET', '/api/issues');
    return (res.json as List)
        .map((e) => Issue.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<AutomationFailure>> listFailures({required String actorId}) async {
    final res = await _request('GET', '/api/automation/failures',
        actorId: actorId);
    return (res.json as List)
        .map((e) => AutomationFailure.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> resolveFailure(
      {required String actorId, required String failureId}) async {
    await _request('POST', '/api/automation/failures/$failureId/resolve',
        actorId: actorId);
  }

  Future<EscalationRunResult> runEscalation({required String actorId}) async {
    final res = await _request('POST', '/api/automation/escalation/run',
        actorId: actorId);
    final json = res.json as Map<String, dynamic>;
    return EscalationRunResult(
      ok: json['ok'] as bool? ?? false,
      candidates: json['candidates'] as int? ?? 0,
      escalated: json['escalated'] as int? ?? 0,
      needsHuman: json['needsHuman'] as bool? ?? false,
    );
  }

  Future<({int status, dynamic json})> _request(
    String method,
    String path, {
    String? actorId,
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('$_baseUrl$path');
    final headers = {
      'Content-Type': 'application/json',
      // Prototype identity header. Week 14 replaces it with a signed token.
      if (actorId != null) 'x-user-id': actorId,
    };

    http.Response response;
    try {
      final call = method == 'POST'
          ? _client.post(uri, headers: headers, body: jsonEncode(body ?? {}))
          : _client.get(uri, headers: headers);
      response = await call.timeout(ApiConfig.timeout);
    } on TimeoutException {
      throw const NetworkException();
    } on http.ClientException {
      throw const NetworkException();
    }

    dynamic json;
    if (response.body.isNotEmpty) {
      try {
        json = jsonDecode(response.body);
      } on FormatException {
        if (response.statusCode < 400) throw const ServerException();
      }
    }

    final code = response.statusCode;
    if (code >= 200 && code < 300) return (status: code, json: json);
    if (code == 400) {
      final map = json is Map<String, dynamic> ? json : <String, dynamic>{};
      throw ValidationException(
        map['error'] as String? ?? 'Please check your input.',
        ((map['details'] as List?) ?? const []).map((e) => '$e').toList(),
      );
    }
    if (code == 401 || code == 403) throw const ForbiddenException();
    if (code == 404) throw const ApiException('That item was not found.');
    throw const ServerException();
  }
}
