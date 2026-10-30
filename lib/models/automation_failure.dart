/// One row of the human work queue: an automation step that failed for good
/// or ran out of retries. Only an error CODE is shown, never raw details.
class AutomationFailure {
  const AutomationFailure({
    required this.id,
    required this.job,
    required this.issueId,
    required this.errorCode,
    required this.reason,
    required this.attempts,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String job;
  final String? issueId;
  final String errorCode;
  final String reason;
  final int attempts;
  final String status;
  final DateTime createdAt;

  String get reasonLabel => switch (reason) {
        'permanent' => 'Permanent error (not retried)',
        'retries_exhausted' => 'Retries used up',
        _ => reason,
      };

  factory AutomationFailure.fromJson(Map<String, dynamic> json) =>
      AutomationFailure(
        id: json['id'] as String,
        job: json['job'] as String,
        issueId: json['issueId'] as String?,
        errorCode: json['errorCode'] as String,
        reason: json['reason'] as String,
        attempts: json['attempts'] as int,
        status: json['status'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
