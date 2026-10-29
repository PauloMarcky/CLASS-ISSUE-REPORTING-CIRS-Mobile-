import '../models/app_user.dart';
import '../models/user_role.dart';

/// Prototype-only accounts. Replaced by real authentication in Week 14.
class MockUsers {
  MockUsers._();

  static const String demoPassword = 'Passw0rd!';

  static const List<AppUser> all = [
    AppUser(
      id: 'u1',
      name: 'Sam Student',
      email: 'student@srms.test',
      role: UserRole.student,
    ),
    AppUser(
      id: 'u2',
      name: 'Fiona Faculty',
      email: 'faculty@srms.test',
      role: UserRole.faculty,
    ),
    AppUser(
      id: 'u3',
      name: 'Felix Facilities',
      email: 'facilities@srms.test',
      role: UserRole.facilitiesStaff,
    ),
    AppUser(
      id: 'u4',
      name: 'Cora Coordinator',
      email: 'coordinator@srms.test',
      role: UserRole.coordinator,
    ),
  ];

  /// Returns the matching user, or null when the credentials are wrong.
  static AppUser? authenticate(String email, String password) {
    if (password != demoPassword) return null;
    final wanted = email.trim().toLowerCase();
    for (final user in all) {
      if (user.email.toLowerCase() == wanted) return user;
    }
    return null;
  }
}