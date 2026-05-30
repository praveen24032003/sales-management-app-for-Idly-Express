import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_config.dart';
import '../../../domain/contact_entry.dart';

class ContactRepository {
  SupabaseClient get _client => SupabaseConfig.client;

  Stream<List<ContactEntry>> watchContacts(String organizationId) {
    return _client
        .from('contacts')
        .stream(primaryKey: ['id'])
        .eq('organization_id', organizationId)
        .order('name')
        .map((rows) => rows.map((row) => ContactEntry.fromMap(row)).toList());
  }

  Future<void> upsertContact({
    required String organizationId,
    required String userId,
    required ContactEntry contact,
  }) async {
    await _client.from('contacts').upsert(contact.toInsertMap(
          organizationId: organizationId,
          userId: userId,
        ));
  }

  Future<void> deleteContact(String contactId) async {
    await _client.from('contacts').delete().eq('id', contactId);
  }
}