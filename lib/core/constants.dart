// Business constants for Idly Express app

// Product types
enum ProductType {
  idly,
  sandhagai,
  idiyappam;

  String get displayName {
    switch (this) {
      case ProductType.idly:
        return 'Idly';
      case ProductType.sandhagai:
        return 'Sandhagai';
      case ProductType.idiyappam:
        return 'Idiyappam';
    }
  }
}

// Sale types
enum SaleType {
  wholesale,
  retail;

  String get displayName {
    switch (this) {
      case SaleType.wholesale:
        return 'Wholesale';
      case SaleType.retail:
        return 'Retail';
    }
  }
}

// Order category to separate regular daily supply and one-off orders
enum OrderType {
  everydaySupply,
  externalOrder;

  String get displayName {
    switch (this) {
      case OrderType.everydaySupply:
        return 'Everyday Supply';
      case OrderType.externalOrder:
        return 'External Order';
    }
  }
}

// Delivery slot for production planning
enum DeliverySlot {
  morning,
  evening;

  String get displayName {
    switch (this) {
      case DeliverySlot.morning:
        return 'Morning';
      case DeliverySlot.evening:
        return 'Evening';
    }
  }
}

// Idly rate options (dropdown) - only for Idly product
const List<double> idlyRateOptions = [3.0, 3.5, 4.0, 4.5, 5.0];

// Default rates based on sale type
const double defaultWholesaleRate = 3.5;
const double defaultRetailRate = 4.0;

// Currency symbol
const String currencySymbol = '₹';

// Database constants
const String dbName = 'idly_express.db';
const String salesTable = 'sales_entries';
const String shopsTable = 'shops';
const String supplyTemplatesTable = 'supply_templates';
const String appSettingsTable = 'app_settings';
const String dispatchLeavesTable = 'dispatch_leaves';
const String settingLastTemplateGenerationDate = 'last_template_generation_date';

// Payment Status
enum PaymentStatus {
  paid,
  pending;

  String get displayName {
    switch (this) {
      case PaymentStatus.paid:
        return 'Paid';
      case PaymentStatus.pending:
        return 'Pending';
    }
  }
}
