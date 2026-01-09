import '../core/constants.dart';

/// Sales Entry Model - stores all data for a single sale
class SalesEntry {
  final int? id;
  final DateTime date;
  final String shopName;
  final ProductType productType;
  final SaleType saleType;
  final double ratePerUnit;
  final int quantity;
  final double costPerUnit;
  final String? notes;

  SalesEntry({
    this.id,
    required this.date,
    required this.shopName,
    required this.productType,
    required this.saleType,
    required this.ratePerUnit,
    required this.quantity,
    required this.costPerUnit,
    this.notes,
  });

  // Calculated fields
  double get totalSalesAmount => quantity * ratePerUnit;
  double get totalCost => quantity * costPerUnit;
  double get profit => totalSalesAmount - totalCost;
  bool get isProfitable => profit >= 0;

  // Convert to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'shopName': shopName,
      'productType': productType.index,
      'saleType': saleType.index,
      'ratePerUnit': ratePerUnit,
      'quantity': quantity,
      'costPerUnit': costPerUnit,
      'totalSalesAmount': totalSalesAmount,
      'totalCost': totalCost,
      'profit': profit,
      'notes': notes,
    };
  }

  // Create from database Map
  factory SalesEntry.fromMap(Map<String, dynamic> map) {
    return SalesEntry(
      id: map['id'] as int?,
      date: DateTime.parse(map['date'] as String),
      shopName: map['shopName'] as String,
      productType: ProductType.values[map['productType'] as int],
      saleType: SaleType.values[map['saleType'] as int],
      ratePerUnit: (map['ratePerUnit'] as num).toDouble(),
      quantity: map['quantity'] as int,
      costPerUnit: (map['costPerUnit'] as num).toDouble(),
      notes: map['notes'] as String?,
    );
  }

  // Copy with modifications
  SalesEntry copyWith({
    int? id,
    DateTime? date,
    String? shopName,
    ProductType? productType,
    SaleType? saleType,
    double? ratePerUnit,
    int? quantity,
    double? costPerUnit,
    String? notes,
  }) {
    return SalesEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      shopName: shopName ?? this.shopName,
      productType: productType ?? this.productType,
      saleType: saleType ?? this.saleType,
      ratePerUnit: ratePerUnit ?? this.ratePerUnit,
      quantity: quantity ?? this.quantity,
      costPerUnit: costPerUnit ?? this.costPerUnit,
      notes: notes ?? this.notes,
    );
  }

  // For CSV export
  static String get csvHeader =>
      'Date,Shop Name,Product,Sale Type,Rate,Quantity,Cost/Unit,Total Sales,Total Cost,Profit,Notes';

  String toCsvRow() {
    return '${date.toIso8601String().split('T')[0]},$shopName,${productType.displayName},${saleType.displayName},$ratePerUnit,$quantity,$costPerUnit,$totalSalesAmount,$totalCost,$profit,${notes ?? ''}';
  }
}
