/// Business constants for Idly Express app

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
