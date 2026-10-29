/// Issue categories. Routing rules (Week 13) will map each category
/// to a responsible team.
enum IssueCategory {
  electrical,
  plumbing,
  airConditioning,
  furniture,
  itEquipment,
  cleanliness,
  safety,
  other;

  String get label => switch (this) {
        IssueCategory.electrical => 'Electrical',
        IssueCategory.plumbing => 'Plumbing',
        IssueCategory.airConditioning => 'Air conditioning',
        IssueCategory.furniture => 'Furniture',
        IssueCategory.itEquipment => 'IT equipment',
        IssueCategory.cleanliness => 'Cleanliness',
        IssueCategory.safety => 'Safety',
        IssueCategory.other => 'Other',
      };
}