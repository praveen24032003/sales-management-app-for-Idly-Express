import '../core/constants.dart';

/// Recurring daily supply template for automatic order generation.
class SupplyTemplate {
  final int? id;
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

  const SupplyTemplate({
    this.id,
    required this.shopName,
    required this.productType,
    required this.saleType,
    required this.quantity,
    required this.ratePerUnit,
    required this.costPerUnit,
    required this.deliverySlot,
    this.deliveryTime,
    this.prepLeadDays = 1,
    this.activeWeekdays = const {1, 2, 3, 4, 5, 6, 7},
    this.startDate,
    this.endDate,
    this.isActive = true,
    this.morningQuantity = 0,
    this.eveningQuantity = 0,
    this.shopMobile,
  });

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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'shop_name': shopName,
      'product_type': productType.index,
      'sale_type': saleType.index,
      'quantity': quantity,
      'rate_per_unit': ratePerUnit,
      'cost_per_unit': costPerUnit,
      'delivery_slot': deliverySlot.index,
      'delivery_time': deliveryTime,
      'prep_lead_days': prepLeadDays,
      'active_weekdays': activeWeekdaysCsv,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'is_active': isActive ? 1 : 0,
      'morning_quantity': morningQuantity,
      'evening_quantity': eveningQuantity,
      'shop_mobile': shopMobile,
    };
  }

  factory SupplyTemplate.fromMap(Map<String, dynamic> map) {
    final weekdaysRaw = map['active_weekdays'] as String?;
    final weekdays = (weekdaysRaw == null || weekdaysRaw.trim().isEmpty)
        ? <int>{1, 2, 3, 4, 5, 6, 7}
        : weekdaysRaw
            .split(',')
            .map((e) => int.tryParse(e.trim()))
            .whereType<int>()
            .where((d) => d >= 1 && d <= 7)
            .toSet();

    return SupplyTemplate(
      id: map['id'] as int?,
      shopName: map['shop_name'] as String,
      productType: ProductType.values[map['product_type'] as int],
      saleType: SaleType.values[map['sale_type'] as int],
      quantity: map['quantity'] as int,
      ratePerUnit: (map['rate_per_unit'] as num).toDouble(),
      costPerUnit: (map['cost_per_unit'] as num).toDouble(),
      deliverySlot: DeliverySlot.values[map['delivery_slot'] as int],
      deliveryTime: map['delivery_time'] as String?,
      prepLeadDays: map['prep_lead_days'] as int? ?? 1,
      activeWeekdays: weekdays.isEmpty ? {1, 2, 3, 4, 5, 6, 7} : weekdays,
      startDate: map['start_date'] != null ? DateTime.tryParse(map['start_date'] as String) : null,
      endDate: map['end_date'] != null ? DateTime.tryParse(map['end_date'] as String) : null,
      isActive: (map['is_active'] as int? ?? 1) == 1,
      morningQuantity: map['morning_quantity'] as int? ?? 0,
      eveningQuantity: map['evening_quantity'] as int? ?? 0,
      shopMobile: map['shop_mobile'] as String?,
    );
  }

  SupplyTemplate copyWith({
    int? id,
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
}
