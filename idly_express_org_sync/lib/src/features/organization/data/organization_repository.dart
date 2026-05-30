import 'dart:math';

import '../../../core/config/supabase_config.dart';
import '../domain/organization_summary.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OrganizationRepository {
  Future<List<OrganizationSummary>> fetchOrganizations(String userId) async {
    final rows = await SupabaseConfig.client
        .from('organization_members')
        .select('role, organization:organizations(id, name, slug, invite_code)')
        .eq('user_id', userId);

    return (rows as List<dynamic>)
        .map((row) => OrganizationSummary.fromMembershipMap(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  Future<OrganizationSummary> createOrganization({
    required String userId,
    required String name,
  }) async {
    for (var attempt = 0; attempt < 3; attempt++) {
      final inviteCode = _buildInviteCode();
      final slug = _buildUniqueSlug(name);

      try {
        final organizationRow = await SupabaseConfig.client.rpc('create_organization_with_owner', params: {
          'org_name': name,
          'org_slug': slug,
          'org_invite_code': inviteCode,
        });

        return OrganizationSummary.fromOrganizationMap(
          _extractSingleRow(organizationRow),
          OrganizationRole.owner,
        );
      } on PostgrestException catch (error) {
        if (_isUniqueConstraintError(error) && attempt < 2) {
          continue;
        }
        rethrow;
      }
    }

    throw StateError('Unable to create organization after multiple retries.');
  }

  Future<OrganizationSummary> joinOrganization({
    required String userId,
    required String inviteCode,
  }) async {
    final organizationRow = await SupabaseConfig.client.rpc('join_organization_with_invite', params: {
      'org_invite_code': inviteCode,
    });

    final organization = _extractSingleRow(organizationRow);
    final role = OrganizationRole.values.firstWhere(
      (item) => item.name == organization['role'],
      orElse: () => OrganizationRole.employee,
    );

    return OrganizationSummary.fromOrganizationMap(
      organization,
      role,
    );
  }

  String _slugify(String name) {
    final base = name
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return base.isEmpty ? 'org-${DateTime.now().millisecondsSinceEpoch}' : base;
  }

  String _buildUniqueSlug(String name) {
    final base = _slugify(name);
    final suffix = _buildToken(length: 4, alphabet: 'abcdefghjkmnpqrstuvwxyz23456789').toLowerCase();
    return '$base-$suffix';
  }

  String _buildInviteCode() {
    return _buildToken(length: 8, alphabet: 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789');
  }

  String _buildToken({required int length, required String alphabet}) {
    final random = Random.secure();
    return List.generate(length, (_) => alphabet[random.nextInt(alphabet.length)]).join();
  }

  bool _isUniqueConstraintError(PostgrestException error) {
    return error.code == '23505' || error.message.toLowerCase().contains('duplicate key');
  }

  Map<String, dynamic> _extractSingleRow(dynamic response) {
    if (response is List && response.isNotEmpty) {
      return Map<String, dynamic>.from(response.first as Map);
    }
    if (response is Map) {
      return Map<String, dynamic>.from(response);
    }
    throw StateError('Unexpected organization response: ${response.runtimeType}');
  }
}