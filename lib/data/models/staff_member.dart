import 'package:flutter/foundation.dart';

import 'enums.dart';

class StaffMember {
  const StaffMember({
    required this.id,
    required this.tenantId,
    required this.userId,
    required this.type,
    required this.permissions,
  });

  factory StaffMember.fromJson(Map<String, dynamic> json) => StaffMember(
    id: json['id'] as String,
    tenantId: json['tenantId'] as String,
    userId: json['userId'] as String,
    type: StaffType.values.byName(json['type'] as String),
    permissions: {
      for (final p in json['permissions'] as List) Permission.values.byName(p as String),
    },
  );

  final String id;
  final String tenantId;
  final String userId;
  final StaffType type;
  final Set<Permission> permissions;

  bool can(Permission permission) => permissions.contains(permission);

  StaffMember copyWith({StaffType? type, Set<Permission>? permissions}) => StaffMember(
    id: id,
    tenantId: tenantId,
    userId: userId,
    type: type ?? this.type,
    permissions: permissions ?? this.permissions,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'tenantId': tenantId,
    'userId': userId,
    'type': type.name,
    'permissions': [for (final p in permissions) p.name],
  };

  @override
  bool operator ==(Object other) =>
      other is StaffMember &&
      other.id == id &&
      other.tenantId == tenantId &&
      other.userId == userId &&
      other.type == type &&
      setEquals(other.permissions, permissions);

  @override
  int get hashCode => Object.hash(id, tenantId, userId, type, Object.hashAllUnordered(permissions));
}
