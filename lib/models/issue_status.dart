/// Lifecycle of an issue: report -> categorize -> assign -> update ->
/// verify -> close.
enum IssueStatus {
  reported,
  categorized,
  assigned,
  inProgress,
  resolved,
  verified,
  closed;

  String get label => switch (this) {
        IssueStatus.reported => 'Reported',
        IssueStatus.categorized => 'Categorized',
        IssueStatus.assigned => 'Assigned',
        IssueStatus.inProgress => 'In progress',
        IssueStatus.resolved => 'Resolved (awaiting verification)',
        IssueStatus.verified => 'Verified',
        IssueStatus.closed => 'Closed',
      };

  /// The only moves allowed from this status.
  /// `resolved -> inProgress` is the recovery path when a fix fails
  /// verification.
  List<IssueStatus> get allowedNext => switch (this) {
        IssueStatus.reported => const [IssueStatus.categorized],
        IssueStatus.categorized => const [IssueStatus.assigned],
        IssueStatus.assigned => const [IssueStatus.inProgress],
        IssueStatus.inProgress => const [IssueStatus.resolved],
        IssueStatus.resolved => const [
            IssueStatus.verified,
            IssueStatus.inProgress,
          ],
        IssueStatus.verified => const [IssueStatus.closed],
        IssueStatus.closed => const <IssueStatus>[],
      };

  bool canMoveTo(IssueStatus next) => allowedNext.contains(next);

  bool get isOpen => this != IssueStatus.closed;
}