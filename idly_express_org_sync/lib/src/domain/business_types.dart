enum ProductType {
  idly('idly', 'Idly'),
  sandhagai('sandhagai', 'Sandhagai'),
  idiyappam('idiyappam', 'Idiyappam');

  const ProductType(this.dbValue, this.displayName);
  final String dbValue;
  final String displayName;

  static ProductType fromDatabase(String value) {
    return ProductType.values.firstWhere(
      (item) => item.dbValue == value,
      orElse: () => ProductType.idly,
    );
  }
}

enum SaleType {
  wholesale('wholesale', 'Wholesale'),
  retail('retail', 'Retail');

  const SaleType(this.dbValue, this.displayName);
  final String dbValue;
  final String displayName;

  static SaleType fromDatabase(String value) {
    return SaleType.values.firstWhere(
      (item) => item.dbValue == value,
      orElse: () => SaleType.wholesale,
    );
  }
}

enum OrderType {
  everydaySupply('everydaySupply', 'Everyday Supply'),
  externalOrder('externalOrder', 'External Order');

  const OrderType(this.dbValue, this.displayName);
  final String dbValue;
  final String displayName;

  static OrderType fromDatabase(String value) {
    return OrderType.values.firstWhere(
      (item) => item.dbValue == value,
      orElse: () => OrderType.externalOrder,
    );
  }
}

enum DeliverySlot {
  morning('morning', 'Morning'),
  evening('evening', 'Evening');

  const DeliverySlot(this.dbValue, this.displayName);
  final String dbValue;
  final String displayName;

  static DeliverySlot fromDatabase(String value) {
    return DeliverySlot.values.firstWhere(
      (item) => item.dbValue == value,
      orElse: () => DeliverySlot.morning,
    );
  }
}

enum PaymentStatus {
  paid('paid', 'Paid'),
  pending('pending', 'Pending');

  const PaymentStatus(this.dbValue, this.displayName);
  final String dbValue;
  final String displayName;

  static PaymentStatus fromDatabase(String value) {
    return PaymentStatus.values.firstWhere(
      (item) => item.dbValue == value,
      orElse: () => PaymentStatus.paid,
    );
  }
}

enum ExpenseCategory {
  petrol('petrol', 'Petrol'),
  food('food', 'Food'),
  maintenance('maintenance', 'Maintenance'),
  other('other', 'Other');

  const ExpenseCategory(this.dbValue, this.displayName);
  final String dbValue;
  final String displayName;

  static ExpenseCategory fromDatabase(String value) {
    return ExpenseCategory.values.firstWhere(
      (item) => item.dbValue == value,
      orElse: () => ExpenseCategory.other,
    );
  }
}

enum ContactType {
  shop('shop', 'Shop'),
  customer('customer', 'Customer');

  const ContactType(this.dbValue, this.displayName);
  final String dbValue;
  final String displayName;

  static ContactType fromDatabase(String value) {
    return ContactType.values.firstWhere(
      (item) => item.dbValue == value,
      orElse: () => ContactType.customer,
    );
  }
}