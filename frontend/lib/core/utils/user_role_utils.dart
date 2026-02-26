/// Helper for checking user permissions based on roles.
class UserRoleUtils {
  UserRoleUtils._();

  /// Returns true if the role has management permissions (Manager, Dept Head, HR, Admin).
  static bool isManagerLike(String? role) {
    if (role == null) return false;
    final r = role.toUpperCase();
    return r == 'MANAGER' ||
        r == 'DEPT_HEAD' ||
        r == 'HR' ||
        r == 'ADMIN';
  }

  /// Returns true if the role has HR or Admin permissions (HR, Admin).
  static bool isHR(String? role) {
    if (role == null) return false;
    final r = role.toUpperCase();
    return r == 'HR' || r == 'ADMIN';
  }

  /// Returns true if the role is purely a manager.
  static bool isManager(String? role) {
    if (role == null) return false;
    return role.toUpperCase() == 'MANAGER';
  }

  /// Returns true if the role is a department head.
  static bool isDepartmentHead(String? role) {
    if (role == null) return false;
    return role.toUpperCase() == 'DEPT_HEAD';
  }

  /// Returns true if the role is purely an employee.
  static bool isEmployee(String? role) {
    if (role == null) return false;
    return role.toUpperCase() == 'EMPLOYEE';
  }
}
