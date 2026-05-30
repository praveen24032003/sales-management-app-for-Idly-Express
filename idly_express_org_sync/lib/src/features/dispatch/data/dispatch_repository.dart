import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_config.dart';
import '../../../domain/dispatch_leave.dart';

class DispatchRepository {
  SupabaseClient get _client => SupabaseConfig.client;

  Stream<List<DispatchLeave>> watchDispatchLeaves(String organizationId) {
    return _client
        .from('dispatch_leaves')
        .stream(primaryKey: ['id'])
        .eq('organization_id', organizationId)
        .order('leave_date')
        .map((rows) => rows.map((row) => DispatchLeave.fromMap(row)).toList());
  }

  Future<void> upsertLeave({
    required String organizationId,
    required String userId,
    required DispatchLeave leave,
  }) async {
    await _client.from('dispatch_leaves').upsert(leave.toInsertMap(
          organizationId: organizationId,
          userId: userId,
        ));
  }

  Future<void> deleteLeave(String leaveId) async {
    await _client.from('dispatch_leaves').delete().eq('id', leaveId);
  }
}