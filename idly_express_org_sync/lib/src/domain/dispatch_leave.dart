import 'business_types.dart';

class DispatchLeave {
  const DispatchLeave({
    required this.id,
    required this.organizationId,
    required this.templateId,
    required this.leaveDate,
    required this.deliverySlot,
    required this.createdAt,
  });

  final String id;
  final String organizationId;
  final String templateId;
  final DateTime leaveDate;
  final DeliverySlot deliverySlot;
  final DateTime createdAt;

  DispatchLeave copyWith({
    String? id,
    String? organizationId,
    String? templateId,
    DateTime? leaveDate,
    DeliverySlot? deliverySlot,
    DateTime? createdAt,
  }) {
    return DispatchLeave(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      templateId: templateId ?? this.templateId,
      leaveDate: leaveDate ?? this.leaveDate,
      deliverySlot: deliverySlot ?? this.deliverySlot,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory DispatchLeave.fromMap(Map<String, dynamic> map) {
    return DispatchLeave(
      id: map['id'] as String,
      organizationId: map['organization_id'] as String,
      templateId: map['template_id'] as String,
      leaveDate: DateTime.parse(map['leave_date'] as String),
      deliverySlot: DeliverySlot.fromDatabase(map['delivery_slot'] as String? ?? 'morning'),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toDataMap() {
    return {
      'id': id,
      'organization_id': organizationId,
      'template_id': templateId,
      'leave_date': leaveDate.toIso8601String().split('T').first,
      'delivery_slot': deliverySlot.dbValue,
      'created_at': createdAt.toIso8601String(),
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
      ...toDataMap()..remove('id')..remove('organization_id'),
    };
  }
}