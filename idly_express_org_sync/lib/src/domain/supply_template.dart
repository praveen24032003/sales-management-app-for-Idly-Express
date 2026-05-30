import 'business_types.dart';

class SupplyTemplate {
  const SupplyTemplate({
    required this.id,
    required this.organizationId,
    required this.shopName,
    required this.productType,
    required this.saleType,
    required this.quantity,
    required this.ratePerUnit,
    required this.costPerUnit,
    required this.deliverySlot,
    required this.activeWeekdays,
    this.deliveryTime,
    this.prepLeadDays = 1,
    this.startDate,
    this.endDate,
    this.isActive = true,
    this.morningQuantity = 0,
    this.eveningQuantity = 0,
    this.shopMobile,
  });

  final String id;
  final String organizationId;
  final String shopName;
  final ProductType productType;
  final SaleType saleType;
  final int quantity;
  final double ratePerUnit;
  final double costPerUnit;
  final DeliverySlot deliverySlot;
  final String? deliveryTime;
  final int prepLeadDays;
  final Set<int> activeWeekdays;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isActive;
  final int morningQuantity;
  final int eveningQuantity;
  final String? shopMobile;

  String get activeWeekdaysCsv {
    final sorted = activeWeekdays.toList()..sort();
    return sorted.join(',');
  }

  bool isActiveOnDate(DateTime date) {
    if (!isActive) return false;
    if (!activeWeekdays.contains(date.weekday)) return false;

    final day = DateTime(date.year, date.month, date.day);
    if (startDate != null) {
      final start = DateTime(startDate!.year, startDate!.month, startDate!.day);
      if (day.isBefore(start)) return false;
    }
    if (endDate != null) {
      final end = DateTime(endDate!.year, endDate!.month, endDate!.day);
      if (day.isAfter(end)) return false;
    }

    return true;
  }

  SupplyTemplate copyWith({
    String? id,
    String? organizationId,
    String? shopName,
    ProductType? productType,
    SaleType? saleType,
    int? quantity,
    double? ratePerUnit,
    double? costPerUnit,
    DeliverySlot? deliverySlot,
    String? deliveryTime,
    int? prepLeadDays,
    Set<int>? activeWeekdays,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    int? morningQuantity,
    int? eveningQuantity,
    String? shopMobile,
  }) {
    return SupplyTemplate(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      shopName: shopName ?? this.shopName,
      productType: productType ?? this.productType,
      saleType: saleType ?? this.saleType,
      quantity: quantity ?? this.quantity,
      ratePerUnit: ratePerUnit ?? this.ratePerUnit,
      costPerUnit: costPerUnit ?? this.costPerUnit,
      deliverySlot: deliverySlot ?? this.deliverySlot,
      deliveryTime: deliveryTime ?? this.deliveryTime,
      prepLeadDays: prepLeadDays ?? this.prepLeadDays,
      activeWeekdays: activeWeekdays ?? this.activeWeekdays,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      morningQuantity: morningQuantity ?? this.morningQuantity,
      eveningQuantity: eveningQuantity ?? this.eveningQuantity,
      shopMobile: shopMobile ?? this.shopMobile,
    );
  }

  factory SupplyTemplate.fromMap(Map<String, dynamic> map) {
    final rawWeekdays = map['active_weekdays'];
    final weekdays = switch (rawWeekdays) {
      List<dynamic> list => list.map((item) => (item as num).toInt()).toSet(),
      String text => text
          .split(',')
          .map((entry) => int.tryParse(entry.trim()))
          .whereType<int>()
          .toSet(),
      _ => <int>{1, 2, 3, 4, 5, 6, 7},
    };

    return SupplyTemplate(
      id: map['id'] as String,
      organizationId: map['organization_id'] as String,
      shopName: map['shop_name'] as String,
      productType: ProductType.fromDatabase(map['product_type'] as String? ?? 'idly'),
      saleType: SaleType.fromDatabase(map['sale_type'] as String? ?? 'wholesale'),
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      ratePerUnit: (map['rate_per_unit'] as num).toDouble(),
      costPerUnit: (map['cost_per_unit'] as num).toDouble(),
      deliverySlot: DeliverySlot.fromDatabase(map['delivery_slot'] as String? ?? 'morning'),
      deliveryTime: map['delivery_time'] as String?,
      prepLeadDays: (map['prep_lead_days'] as num?)?.toInt() ?? 1,
      activeWeekdays: weekdays.isEmpty ? {1, 2, 3, 4, 5, 6, 7} : weekdays,
      startDate: map['start_date'] == null ? null : DateTime.tryParse(map['start_date'] as String),
      endDate: map['end_date'] == null ? null : DateTime.tryParse(map['end_date'] as String),
      isActive: map['is_active'] as bool? ?? true,
      morningQuantity: (map['morning_quantity'] as num?)?.toInt() ?? 0,
      eveningQuantity: (map['evening_quantity'] as num?)?.toInt() ?? 0,
      shopMobile: map['shop_mobile'] as String?,
    );
  }

  Map<String, dynamic> toDataMap() {
    return {
      'id': id,
      'organization_id': organizationId,
      'shop_name': shopName,
      'product_type': productType.dbValue,
      'sale_type': saleType.dbValue,
      'quantity': quantity,
      'rate_per_unit': ratePerUnit,
      'cost_per_unit': costPerUnit,
      'delivery_slot': deliverySlot.dbValue,
      'delivery_time': deliveryTime,
      'prep_lead_days': prepLeadDays,
      'active_weekdays': activeWeekdays.toList()..sort(),
      'start_date': startDate?.toIso8601String().split('T').first,
      'end_date': endDate?.toIso8601String().split('T').first,
      'is_active': isActive,
      'morning_quantity': morningQuantity,
      'evening_quantity': eveningQuantity,
      'shop_mobile': shopMobile,
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
      ...toDataMap()..remove('id')..remove('organization_id'),
    };
  }
}