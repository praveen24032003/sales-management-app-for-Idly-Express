import 'business_types.dart';

class ContactEntry {
  const ContactEntry({
    required this.id,
    required this.organizationId,
    required this.contactType,
    required this.name,
    this.mobile,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String organizationId;
  final ContactType contactType;
  final String name;
  final String? mobile;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ContactEntry copyWith({
    String? id,
    String? organizationId,
    ContactType? contactType,
    String? name,
    String? mobile,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ContactEntry(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      contactType: contactType ?? this.contactType,
      name: name ?? this.name,
      mobile: mobile ?? this.mobile,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory ContactEntry.fromMap(Map<String, dynamic> map) {
    return ContactEntry(
      id: map['id'] as String,
      organizationId: map['organization_id'] as String,
      contactType: ContactType.fromDatabase(map['contact_type'] as String? ?? 'customer'),
      name: map['name'] as String,
      mobile: map['mobile'] as String?,
      createdAt: map['created_at'] == null ? null : DateTime.tryParse(map['created_at'] as String),
      updatedAt: map['updated_at'] == null ? null : DateTime.tryParse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toDataMap() {
    return {
      'id': id,
      'organization_id': organizationId,
      'contact_type': contactType.dbValue,
      'name': name,
      'mobile': mobile,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toInsertMap({
    required String organizationId,
    required String userId,
  }) {
    return {
      'id': id,
      'organization_id': organizationId,
      'created_by': userId,
      'updated_by': userId,
      'contact_type': contactType.dbValue,
      'name': name,
      'mobile': mobile,
    };
  }
}