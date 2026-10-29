enum IssuePriority {
  low,
  medium,
  high,
  urgent;

  String get label => switch (this) {
        IssuePriority.low => 'Low',
        IssuePriority.medium => 'Medium',
        IssuePriority.high => 'High',
        IssuePriority.urgent => 'Urgent',
      };
}