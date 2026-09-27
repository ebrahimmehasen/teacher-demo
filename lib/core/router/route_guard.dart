import '../../data/models/models.dart';
import '../../services/session_service.dart';
import 'role_destinations.dart';

const loginPath = '/login';

/// Returns where to send the user, or null to allow [path].
/// [staff] is null while an assistant's permissions are still loading.
String? resolveRedirect({
  required Session? session,
  required StaffMember? staff,
  required String path,
}) {
  if (session == null) return path == loginPath ? null : loginPath;

  final role = session.role;
  final home = RoleDestinations.homeOf(role);
  if (path == loginPath || path == '/') return home;

  final destination = RoleDestinations.match(role, path);
  if (destination == null) return home;

  final permission = destination.permission;
  if (permission != null && staff != null && !staff.can(permission)) return home;
  return null;
}
