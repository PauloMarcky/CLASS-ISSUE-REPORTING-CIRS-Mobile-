/// The four user groups named in the project brief.
///
/// Permission helpers live here so the UI and (later) the backend
/// can share one definition of "who may do what".
enum UserRole {
  student,
  faculty,
  facilitiesStaff,
  coordinator;

  String get label => switch (this) {
        UserRole.student => 'Student',
        UserRole.faculty => 'Faculty',
        UserRole.facilitiesStaff => 'Facilities Staff',
        UserRole.coordinator => 'Coordinator',
      };

  bool get canReportIssue => this == student || this == faculty;

  bool get canCategorizeAndAssign => this == coordinator;

  bool get canUpdateProgress => this == facilitiesStaff;

  bool get canVerifyResolution =>
      this == student || this == faculty || this == coordinator;

  bool get canClose => this == coordinator;
}