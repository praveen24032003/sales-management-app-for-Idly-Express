import 'dart:math';
import '../core/constants.dart';
import '../models/sales_entry_model.dart';
import 'database_service.dart';

class MockDataService {
  final _random = Random();
  final DatabaseService _db = DatabaseService.instance;

  final List<String> _shopNames = [
    'Annapoorna Hotel',
    'Saravana Bhavan',
    'Krishna Sweets',
    'Murugan Idly',
    'Sangeetha Veg',
    'Adyar Ananda Bhavan',
    'Hot Chips',
    'Aryas',
    'Vasantha Bhavan',
    'Geetha Cafe',
    'Sri Balaji Bhavan',
    'Hotel Tamilnadu',
    'Amma Canteen',
    'Salem RR Biryani', // Just for variety
    'Madurai Idly Shop',
    'Coimbatore Mess'
  ];

  Future<int> generateMockData() async {
    // Clear existing data first? No, let's append.
    // Actually, user might want to clear. ideally, maybe we should clear. 
    // Let's assume user wants to populate a fresh DB or just add to it.
    // For safety, let's just add.
    
    final List<SalesEntry> entries = [];
    final now = DateTime.now();

    // Generate for last 90 days
    for (int i = 0; i < 90; i++) {
      final date = now.subtract(Duration(days: i));
      
      // Random number of entries per day (3 to 10)
      final dailyEntriesCount = 3 + _random.nextInt(8); 

      for (int j = 0; j < dailyEntriesCount; j++) {
        final productType = ProductType.values[_random.nextInt(ProductType.values.length)];
        final saleType = SaleType.values[_random.nextInt(SaleType.values.length)];
        final shopName = _shopNames[_random.nextInt(_shopNames.length)];
        
        double rate;
        double cost;
        int quantity = 20 + _random.nextInt(200); // 20 to 220 items

        if (productType == ProductType.idly) {
           rate = idlyRateOptions[_random.nextInt(idlyRateOptions.length)];
           cost = 1.5 + _random.nextDouble(); // Cost between 1.5 and 2.5
        } else {
           // Other items
           rate = 5.0 + _random.nextInt(10); // 5 to 15
           cost = 3.0 + _random.nextInt(4);  // 3 to 7
        }

        // Adjust for wholesale
        if (saleType == SaleType.wholesale) {
          quantity *= 2; // Wholesale usually more quantity
          rate *= 0.8; // Lower rate
        }

        entries.add(SalesEntry(
          date: date, // Keep time as is for sorting
          shopName: shopName,
          productType: productType,
          saleType: saleType,
          ratePerUnit: double.parse(rate.toStringAsFixed(1)),
          quantity: quantity,
          costPerUnit: double.parse(cost.toStringAsFixed(1)),
          notes: _random.nextBool() ? 'Regular customer' : null,
        ));
      }
    }

    return await _db.batchInsert(entries);
  }
}
