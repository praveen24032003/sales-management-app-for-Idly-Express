import 'business_types.dart';

class SalesEntry {
  const SalesEntry({
    required this.id,
    required this.organizationId,
    required this.date,
    required this.shopName,
    required this.orderType,
    required this.deliverySlot,
    required this.prepLeadDays,
    required this.productType,
    required this.saleType,
    required this.ratePerUnit,
    required this.quantity,
    required this.costPerUnit,
    required this.paymentStatus,
    this.deliveryTime,
    this.paidAmount,
    this.customerMobile,
    this.notes,
  });

  final String id;
  final String organizationId;
  final DateTime date;
  final String shopName;
  final OrderType orderType;
  final DeliverySlot deliverySlot;
  final String? deliveryTime;
  final int prepLeadDays;
  final ProductType productType;
  final SaleType saleType;
  final double ratePerUnit;
  final int quantity;
  final double costPerUnit;
  final PaymentStatus paymentStatus;
  final double? paidAmount;
  final String? customerMobile;
  final String? notes;

  SalesEntry copyWith({
    String? id,
    String? organizationId,
    DateTime? date,
    String? shopName,
    OrderType? orderType,
    DeliverySlot? deliverySlot,
    String? deliveryTime,
    int? prepLeadDays,
    ProductType? productType,
    SaleType? saleType,
    double? ratePerUnit,
    int? quantity,
    double? costPerUnit,
    PaymentStatus? paymentStatus,
    double? paidAmount,
    String? customerMobile,
    String? notes,
  }) {
    return SalesEntry(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      date: date ?? this.date,
      shopName: shopName ?? this.shopName,
      orderType: orderType ?? this.orderType,
      deliverySlot: deliverySlot ?? this.deliverySlot,
      deliveryTime: deliveryTime ?? this.deliveryTime,
      prepLeadDays: prepLeadDays ?? this.prepLeadDays,
      productType: productType ?? this.productType,
      saleType: saleType ?? this.saleType,
      ratePerUnit: ratePerUnit ?? this.ratePerUnit,
      quantity: quantity ?? this.quantity,
      costPerUnit: costPerUnit ?? this.costPerUnit,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paidAmount: paidAmount ?? this.paidAmount,
      customerMobile: customerMobile ?? this.customerMobile,
      notes: notes ?? this.notes,
    );
  }

  factory SalesEntry.fromMap(Map<String, dynamic> map) {
    return SalesEntry(
      id: map['id'] as String,
      organizationId: map['organization_id'] as String,
      date: DateTime.parse(map['entry_date'] as String),
      shopName: map['shop_name'] as String,
      orderType: OrderType.fromDatabase(map['order_type'] as String? ?? 'externalOrder'),
      deliverySlot: DeliverySlot.fromDatabase(map['delivery_slot'] as String? ?? 'morning'),
      deliveryTime: map['delivery_time'] as String?,
      prepLeadDays: (map['prep_lead_days'] as num?)?.toInt() ?? 1,
      productType: ProductType.fromDatabase(map['product_type'] as String? ?? 'idly'),
      saleType: SaleType.fromDatabase(map['sale_type'] as String? ?? 'wholesale'),
      ratePerUnit: (map['rate_per_unit'] as num).toDouble(),
      quantity: (map['quantity'] as num).toInt(),
      costPerUnit: (map['cost_per_unit'] as num).toDouble(),
      paymentStatus: PaymentStatus.fromDatabase(map['payment_status'] as String? ?? 'paid'),
      paidAmount: (map['paid_amount'] as num?)?.toDouble(),
      customerMobile: map['customer_mobile'] as String?,
      notes: map['notes'] as String?,
    );
  }

  Map<String, dynamic> toDataMap() {
    return {
      'id': id,
      'organization_id': organizationId,
      'entry_date': date.toIso8601String().split('T').first,
      'shop_name': shopName,
      'order_type': orderType.dbValue,
      'delivery_slot': deliverySlot.dbValue,
      'delivery_time': deliveryTime,
      'prep_lead_days': prepLeadDays,
      'product_type': productType.dbValue,
      'sale_type': saleType.dbValue,
      'rate_per_unit': ratePerUnit,
      'quantity': quantity,
      'cost_per_unit': costPerUnit,
      'payment_status': paymentStatus.dbValue,
      'paid_amount': paidAmount,
      'customer_mobile': customerMobile,
      'notes': notes,
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

  double get totalSalesAmount => quantity * ratePerUnit;
  double get totalCost => quantity * costPerUnit;
  double get profit => totalSalesAmount - totalCost;
  double get pendingAmount => totalSalesAmount - (paidAmount ?? 0);
}