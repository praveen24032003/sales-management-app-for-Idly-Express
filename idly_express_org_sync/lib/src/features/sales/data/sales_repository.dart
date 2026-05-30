import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_config.dart';
import '../../../domain/sales_entry.dart';

class SalesRepository {
  SupabaseClient get _client => SupabaseConfig.client;

  Stream<List<SalesEntry>> watchSales(String organizationId) {
    return _client
        .from('sales_entries')
        .stream(primaryKey: ['id'])
        .eq('organization_id', organizationId)
        .order('entry_date')
        .map((rows) => rows.map((row) => SalesEntry.fromMap(row)).toList().reversed.toList());
  }

  Future<void> upsertSale({
    required String organizationId,
    required String userId,
    required SalesEntry sale,
  }) async {
    await _client.from('sales_entries').upsert(sale.toInsertMap(
          organizationId: organizationId,
          userId: userId,
        ));
  }

  Future<void> deleteSale(String saleId) async {
    await _client.from('sales_entries').delete().eq('id', saleId);
  }
}