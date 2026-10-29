import 'issue_category.dart';
import 'issue_priority.dart';
import 'issue_status.dart';

class Issue {
  const Issue({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.reporterId,
    required this.createdAt,
    required this.updatedAt,
    this.category,
    this.priority = IssuePriority.medium,
    this.status = IssueStatus.reported,
    this.assignedToId,
    this.isEscalated = false,
  });

  final String id;
  final String title;
  final String description;

  /// Building and room, for example "Science Building - Room 204".
  final String location;

  final String reporterId;
  final IssueCategory? category;
  final IssuePriority priority;
  final IssueStatus status;
  final String? assignedToId;
  final bool isEscalated;
  final DateTime createdAt;
  final DateTime updatedAt;

  Issue copyWith({
    String? title,
    String? description,
    String? location,
    IssueCategory? category,
    IssuePriority? priority,
    IssueStatus? status,
    String? assignedToId,
    bool? isEscalated,
    DateTime? updatedAt,
  }) =>
      Issue(
        id: id,
        title: title ?? this.title,
        description: description ?? this.description,
        location: location ?? this.location,
        reporterId: reporterId,
        category: category ?? this.category,
        priority: priority ?? this.priority,
        status: status ?? this.status,
        assignedToId: assignedToId ?? this.assignedToId,
        isEscalated: isEscalated ?? this.isEscalated,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  factory Issue.fromJson(Map<String, dynamic> json) => Issue(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        location: json['location'] as String,
        reporterId: json['reporterId'] as String,
        category: json['category'] == null
            ? null
            : IssueCategory.values.byName(json['category'] as String),
        priority: IssuePriority.values.byName(json['priority'] as String),
        status: IssueStatus.values.byName(json['status'] as String),
        assignedToId: json['assignedToId'] as String?,
        isEscalated: json['isEscalated'] as bool? ?? false,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'location': location,
        'reporterId': reporterId,
        'category': category?.name,
        'priority': priority.name,
        'status': status.name,
        'assignedToId': assignedToId,
        'isEscalated': isEscalated,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}