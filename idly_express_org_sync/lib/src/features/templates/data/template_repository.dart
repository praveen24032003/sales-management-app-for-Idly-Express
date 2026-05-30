import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_config.dart';
import '../../../domain/supply_template.dart';

class TemplateRepository {
  SupabaseClient get _client => SupabaseConfig.client;

  Stream<List<SupplyTemplate>> watchTemplates(String organizationId) {
    return _client
        .from('supply_templates')
        .stream(primaryKey: ['id'])
        .eq('organization_id', organizationId)
        .order('shop_name')
        .map((rows) => rows.map((row) => SupplyTemplate.fromMap(row)).toList());
  }

  Future<void> upsertTemplate({
    required String organizationId,
    required String userId,
    required SupplyTemplate template,
  }) async {
    await _client.from('supply_templates').upsert(template.toInsertMap(
          organizationId: organizationId,
          userId: userId,
        ));
  }

  Future<void> deleteTemplate(String templateId) async {
    await _client.from('supply_templates').delete().eq('id', templateId);
  }
}