import '../core/constants.dart';

/// Sales Entry Model - stores all data for a single sale
class SalesEntry {
  final int? id;
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
  final String? firestoreId;
  final int lastModified;
  final bool isSynced;

  SalesEntry({
    this.id,
    required this.date,
    required this.shopName,
    this.orderType = OrderType.externalOrder,
    this.deliverySlot = DeliverySlot.morning,
    this.deliveryTime,
    this.prepLeadDays = 1,
    required this.productType,
    required this.saleType,
    required this.ratePerUnit,
    required this.quantity,
    required this.costPerUnit,
    this.paymentStatus = PaymentStatus.paid,
    double? paidAmount,
    this.customerMobile,
    this.notes,
    this.firestoreId,
    this.lastModified = 0,
    this.isSynced = false,
  }) : paidAmount = paidAmount ?? (quantity * ratePerUnit);

  // Calculated fields
  double get totalSalesAmount => quantity * ratePerUnit;
  double get totalCost => quantity * costPerUnit;
  double get profit => totalSalesAmount - totalCost;
  bool get isProfitable => profit >= 0;
  double get pendingAmount => totalSalesAmount - (paidAmount ?? 0);
  bool get isFullyPaid => pendingAmount <= 0.1; // Tolerance for float math

  // Convert to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'shopName': shopName,
      'order_type': orderType.index,
      'delivery_slot': deliverySlot.index,
      'delivery_time': deliveryTime,
      'prep_lead_days': prepLeadDays,
      'productType': productType.index,
      'saleType': saleType.index,
      'ratePerUnit': ratePerUnit,
      'quantity': quantity,
      'costPerUnit': costPerUnit,
      'totalSalesAmount': totalSalesAmount,
      'totalCost': totalCost,
      'profit': profit,
      'paymentStatus': paymentStatus.index,
      'paidAmount': paidAmount,
      'customer_mobile': customerMobile,
      'notes': notes,
      'firestore_id': firestoreId,
      'last_modified': lastModified,
      'is_synced': isSynced ? 1 : 0,
    };
  }

  // Create from Map
  factory SalesEntry.fromMap(Map<String, dynamic> map) {
    return SalesEntry(
      id: map['id'] as int?,
      date: DateTime.parse(map['date'] as String),
      shopName: map['shopName'] as String,
      orderType: OrderType.values[map['order_type'] as int? ?? 1],
      deliverySlot: DeliverySlot.values[map['delivery_slot'] as int? ?? 0],
      deliveryTime: map['delivery_time'] as String?,
      prepLeadDays: map['prep_lead_days'] as int? ?? 1,
      productType: ProductType.values[map['productType'] as int],
      saleType: SaleType.values[map['saleType'] as int],
      ratePerUnit: (map['ratePerUnit'] as num).toDouble(),
      quantity: map['quantity'] as int,
      costPerUnit: (map['costPerUnit'] as num).toDouble(),
      paymentStatus: PaymentStatus.values[map['paymentStatus'] as int? ?? 0],
      paidAmount: map['paidAmount'] != null 
          ? (map['paidAmount'] as num).toDouble() 
          : (map['quantity'] as int) * (map['ratePerUnit'] as num).toDouble(),
      customerMobile: map['customer_mobile'] as String?,
      notes: map['notes'] as String?,
      firestoreId: map['firestore_id'] as String?,
      lastModified: map['last_modified'] as int? ?? 0,
      isSynced: (map['is_synced'] as int? ?? 0) == 1,
    );
  }

  // Copy with modifications
  SalesEntry copyWith({
    int? id,
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
    String? firestoreId,
    int? lastModified,
    bool? isSynced,
  }) {
    return SalesEntry(
      id: id ?? this.id,
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
      firestoreId: firestoreId ?? this.firestoreId,
      lastModified: lastModified ?? this.lastModified,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  // For CSV export
  static String get csvHeader =>
      'Date,Shop Name,Order Type,Delivery Slot,Delivery Time,Prep Lead Days,Product,Sale Type,Rate,Quantity,Cost/Unit,Total Sales,Total Cost,Profit,Payment Status,Paid Amount,Pending Amount,Notes';

  String toCsvRow() {
    return '${date.toIso8601String().split('T')[0]},$shopName,${orderType.displayName},${deliverySlot.displayName},${deliveryTime ?? ''},$prepLeadDays,${productType.displayName},${saleType.displayName},$ratePerUnit,$quantity,$costPerUnit,$totalSalesAmount,$totalCost,$profit,${paymentStatus.displayName},$paidAmount,$pendingAmount,${notes ?? ''}';
  }
}
