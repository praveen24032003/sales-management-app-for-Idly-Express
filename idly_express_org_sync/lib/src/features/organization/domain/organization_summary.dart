enum OrganizationRole {
  owner('Owner'),
  manager('Manager'),
  employee('Employee');

  const OrganizationRole(this.label);
  final String label;

  static OrganizationRole fromDatabase(String value) {
    return switch (value) {
      'owner' => OrganizationRole.owner,
      'manager' => OrganizationRole.manager,
      _ => OrganizationRole.employee,
    };
  }
}

class OrganizationSummary {
  const OrganizationSummary({
    required this.id,
    required this.name,
    required this.slug,
    required this.inviteCode,
    required this.role,
  });

  final String id;
  final String name;
  final String slug;
  final String inviteCode;
  final OrganizationRole role;

  factory OrganizationSummary.fromMembershipMap(Map<String, dynamic> map) {
    final organization = Map<String, dynamic>.from(map['organization'] as Map);

    return OrganizationSummary(
      id: organization['id'] as String,
      name: organization['name'] as String,
      slug: organization['slug'] as String? ?? '',
      inviteCode: organization['invite_code'] as String? ?? '',
      role: OrganizationRole.fromDatabase(map['role'] as String? ?? 'employee'),
    );
  }

  factory OrganizationSummary.fromOrganizationMap(Map<String, dynamic> map, OrganizationRole role) {
    return OrganizationSummary(
      id: map['id'] as String,
      name: map['name'] as String,
      slug: map['slug'] as String? ?? '',
      inviteCode: map['invite_code'] as String? ?? '',
      role: role,
    );
  }
}