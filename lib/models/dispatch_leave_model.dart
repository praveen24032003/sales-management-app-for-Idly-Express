import '../core/constants.dart';

/// Represents a leave/skip entry for a supply template on a specific date.
class DispatchLeave {
  final int? id;
  final int templateId;
  final DateTime leaveDate;
  final DeliverySlot deliverySlot;
  final DateTime createdAt;

  const DispatchLeave({
    this.id,
    required this.templateId,
    required this.leaveDate,
    required this.deliverySlot,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'template_id': templateId,
    'leave_date': leaveDate.toIso8601String().split('T').first,
    'delivery_slot': deliverySlot.index,
    'created_at': createdAt.toIso8601String(),
  };

  factory DispatchLeave.fromMap(Map<String, dynamic> map) => DispatchLeave(
    id: map['id'] as int?,
    templateId: map['template_id'] as int,
    leaveDate: DateTime.parse(map['leave_date'] as String),
    deliverySlot: DeliverySlot.values[map['delivery_slot'] as int? ?? 0],
    createdAt: DateTime.parse(map['created_at'] as String),
  );
}
