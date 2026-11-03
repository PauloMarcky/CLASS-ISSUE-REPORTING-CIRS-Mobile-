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
    this.reporterName,
    required this.createdAt,
    required this.updatedAt,
    this.category,
    this.priority = IssuePriority.medium,
    this.status = IssueStatus.reported,
    this.assignedToId,
    this.assignedToName,
    this.isEscalated = false,
    this.routedTeam,
  });

  final String id;
  final String title;
  final String description;

  /// Building and room, for example "Science Building - Room 204".
  final String location;

  final String reporterId;
  final String? reporterName;
  final IssueCategory? category;
  final IssuePriority priority;
  final IssueStatus status;
  final String? assignedToId;
  final String? assignedToName;
  final bool isEscalated;

  /// Team chosen by the automatic routing rules (set by the server).
  final String? routedTeam;
  final DateTime createdAt;
  final DateTime updatedAt;

  Issue copyWith({
    String? id,
    String? title,
    String? description,
    String? location,
    String? reporterId,
    String? reporterName,
    IssueCategory? category,
    IssuePriority? priority,
    IssueStatus? status,
    String? assignedToId,
    String? assignedToName,
    bool? isEscalated,
    String? routedTeam,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      Issue(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description ?? this.description,
        location: location ?? this.location,
        reporterId: reporterId ?? this.reporterId,
        reporterName: reporterName ?? this.reporterName,
        category: category ?? this.category,
        priority: priority ?? this.priority,
        status: status ?? this.status,
        assignedToId: assignedToId ?? this.assignedToId,
        assignedToName: assignedToName ?? this.assignedToName,
        isEscalated: isEscalated ?? this.isEscalated,
        routedTeam: routedTeam ?? this.routedTeam,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  factory Issue.fromJson(Map<String, dynamic> json) => Issue(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        location: json['location'] as String,
        reporterId: json['reporterId'] as String,
        reporterName: json['reporterName'] as String?,
        category: json['category'] == null
            ? null
            : IssueCategory.values.byName(json['category'] as String),
        priority: IssuePriority.values.byName(json['priority'] as String),
        status: IssueStatus.values.byName(json['status'] as String),
        assignedToId: json['assignedToId'] as String?,
        assignedToName: json['assignedToName'] as String?,
        isEscalated: json['isEscalated'] as bool? ?? false,
        routedTeam: json['routedTeam'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'location': location,
        'reporterId': reporterId,
        'reporterName': reporterName,
        'category': category?.name,
        'priority': priority.name,
        'status': status.name,
        'assignedToId': assignedToId,
        'assignedToName': assignedToName,
        'isEscalated': isEscalated,
        'routedTeam': routedTeam,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}