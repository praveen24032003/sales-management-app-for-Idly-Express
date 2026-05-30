import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_config.dart';
import '../../../domain/expense_entry.dart';

class ExpenseRepository {
  SupabaseClient get _client => SupabaseConfig.client;

  Stream<List<ExpenseEntry>> watchExpenses(String organizationId) {
    return _client
        .from('expenses')
        .stream(primaryKey: ['id'])
        .eq('organization_id', organizationId)
        .order('expense_date')
        .map((rows) => rows.map((row) => ExpenseEntry.fromMap(row)).toList().reversed.toList());
  }

  Future<void> upsertExpense({
    required String organizationId,
    required String userId,
    required ExpenseEntry expense,
  }) async {
    await _client.from('expenses').upsert(expense.toInsertMap(
          organizationId: organizationId,
          userId: userId,
        ));
  }

  Future<void> deleteExpense(String expenseId) async {
    await _client.from('expenses').delete().eq('id', expenseId);
  }
}