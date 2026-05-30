import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:idly_express_org_sync/src/core/config/supabase_config.dart';
import 'package:idly_express_org_sync/src/data/local/local_workspace_store.dart';
import 'package:idly_express_org_sync/src/domain/business_types.dart';
import 'package:idly_express_org_sync/src/domain/contact_entry.dart';
import 'package:idly_express_org_sync/src/domain/dispatch_leave.dart';
import 'package:idly_express_org_sync/src/domain/expense_entry.dart';
import 'package:idly_express_org_sync/src/domain/sales_entry.dart';
import 'package:idly_express_org_sync/src/domain/supply_template.dart';
import 'package:idly_express_org_sync/src/features/app_shell/application/app_session_controller.dart';
import 'package:idly_express_org_sync/src/features/auth/data/auth_repository.dart';
import 'package:idly_express_org_sync/src/features/contacts/data/contact_repository.dart';
import 'package:idly_express_org_sync/src/features/dispatch/data/dispatch_repository.dart';
import 'package:idly_express_org_sync/src/features/expenses/data/expense_repository.dart';
import 'package:idly_express_org_sync/src/features/organization/data/organization_repository.dart';
import 'package:idly_express_org_sync/src/features/organization/domain/organization_summary.dart';
import 'package:idly_express_org_sync/src/features/sales/data/sales_repository.dart';
import 'package:idly_express_org_sync/src/features/templates/data/template_repository.dart';
import 'package:idly_express_org_sync/src/features/workspace/application/workspace_data_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SupabaseConfig.markReady();
  });

  group('AppSessionController', () {
    test('restores preferred organization on initialize', () async {
      SharedPreferences.setMockInitialValues({'active_organization_id': 'org-2'});

      final controller = AppSessionController(
        authRepository: _FakeAuthRepository(currentUserValue: _testUser()),
        organizationRepository: _FakeOrganizationRepository(
          organizations: const [
            OrganizationSummary(
              id: 'org-1',
              name: 'Alpha Foods',
              slug: 'alpha-foods',
              inviteCode: 'ALPHA123',
              role: OrganizationRole.owner,
            ),
            OrganizationSummary(
              id: 'org-2',
              name: 'Beta Stores',
              slug: 'beta-stores',
              inviteCode: 'BETA1234',
              role: OrganizationRole.manager,
            ),
          ],
        ),
      );

      await controller.initialize();

      expect(controller.activeOrganization?.id, 'org-2');
      expect(controller.organizations, hasLength(2));
    });

    test('maps invalid login credentials to user-facing auth message', () async {
      final controller = AppSessionController(
        authRepository: _FakeAuthRepository(
          signInError: AuthApiException('invalid login credentials', code: 'invalid_login_credentials'),
        ),
        organizationRepository: _FakeOrganizationRepository(),
      );

      await controller.signIn(email: 'owner@example.com', password: 'wrong-pass');

      expect(controller.errorMessage, 'Email or password is incorrect.');
      expect(controller.isLoading, isFalse);
    });

    test('maps unconfirmed email login to confirmation guidance', () async {
      final controller = AppSessionController(
        authRepository: _FakeAuthRepository(
          signInError: AuthApiException('email not confirmed', code: 'email_not_confirmed'),
        ),
        organizationRepository: _FakeOrganizationRepository(),
      );

      await controller.signIn(email: 'owner@example.com', password: 'secret123');

      expect(controller.errorMessage, 'Check your email and confirm the account before signing in.');
      expect(controller.isLoading, isFalse);
    });

    test('maps invalid signup email to user-facing auth message', () async {
      final controller = AppSessionController(
        authRepository: _FakeAuthRepository(
          signUpError: AuthApiException('invalid email address', code: 'email_address_invalid'),
        ),
        organizationRepository: _FakeOrganizationRepository(),
      );

      await controller.signUp(email: 'not-an-email', password: 'secret123');

      expect(controller.errorMessage, 'Enter a valid email address to continue.');
      expect(controller.isLoading, isFalse);
    });

    test('maps signup rate limiting to retry guidance', () async {
      final controller = AppSessionController(
        authRepository: _FakeAuthRepository(
          signUpError: AuthApiException('rate limit reached', statusCode: '429'),
        ),
        organizationRepository: _FakeOrganizationRepository(),
      );

      await controller.signUp(email: 'owner@example.com', password: 'secret123');

      expect(controller.errorMessage, 'Too many auth attempts. Wait a moment and try again.');
      expect(controller.isLoading, isFalse);
    });

    test('joinOrganization adds missing organization and selects it', () async {
      final organizationRepository = _FakeOrganizationRepository(
        organizations: const [
          OrganizationSummary(
            id: 'org-1',
            name: 'Alpha Foods',
            slug: 'alpha-foods',
            inviteCode: 'ALPHA123',
            role: OrganizationRole.owner,
          ),
        ],
        joinedOrganization: const OrganizationSummary(
          id: 'org-2',
          name: 'Beta Stores',
          slug: 'beta-stores',
          inviteCode: 'BETA1234',
          role: OrganizationRole.employee,
        ),
      );
      final controller = AppSessionController(
        authRepository: _FakeAuthRepository(currentUserValue: _testUser()),
        organizationRepository: organizationRepository,
      );

      await controller.initialize();
      await controller.joinOrganization('BETA1234');

      expect(organizationRepository.lastJoinedInviteCode, 'BETA1234');
      expect(controller.organizations.map((item) => item.id), containsAll(<String>['org-1', 'org-2']));
      expect(controller.activeOrganization?.id, 'org-2');
    });

    test('createOrganization appends owner org and selects it', () async {
      final organizationRepository = _FakeOrganizationRepository(
        organizations: const [
          OrganizationSummary(
            id: 'org-1',
            name: 'Alpha Foods',
            slug: 'alpha-foods',
            inviteCode: 'ALPHA123',
            role: OrganizationRole.owner,
          ),
        ],
        createdOrganization: const OrganizationSummary(
          id: 'org-3',
          name: 'Gamma Canteen',
          slug: 'gamma-canteen',
          inviteCode: 'GAMMA123',
          role: OrganizationRole.owner,
        ),
      );
      final controller = AppSessionController(
        authRepository: _FakeAuthRepository(currentUserValue: _testUser()),
        organizationRepository: organizationRepository,
      );

      await controller.initialize();
      await controller.createOrganization('Gamma Canteen');

      expect(organizationRepository.lastCreatedName, 'Gamma Canteen');
      expect(controller.organizations.map((item) => item.id), containsAll(<String>['org-1', 'org-3']));
      expect(controller.activeOrganization?.id, 'org-3');
    });

    test('signUp creates first organization when session is available', () async {
      final organizationRepository = _FakeOrganizationRepository(
        createdOrganization: const OrganizationSummary(
          id: 'org-5',
          name: 'Sunrise Canteen',
          slug: 'sunrise-canteen',
          inviteCode: 'SUN12345',
          role: OrganizationRole.owner,
        ),
      );
      final controller = AppSessionController(
        authRepository: _FakeAuthRepository(currentUserValue: _testUser()),
        organizationRepository: organizationRepository,
      );

      await controller.signUp(
        email: 'owner@example.com',
        password: 'secret123',
        organizationName: 'Sunrise Canteen',
      );

      expect(organizationRepository.lastCreatedName, 'Sunrise Canteen');
      expect(controller.activeOrganization?.id, 'org-5');
      expect(controller.organizations.map((item) => item.id), contains('org-5'));
    });

    test('signUp waits for email verification when confirm email is enabled', () async {
      final authRepository = _FakeAuthRepository(signUpResponse: AuthResponse(user: _testUser()));
      final controller = AppSessionController(
        authRepository: authRepository,
        organizationRepository: _FakeOrganizationRepository(),
      );

      await controller.signUp(
        email: 'owner@example.com',
        password: 'secret123',
        organizationName: 'Sunrise Canteen',
      );

      expect(authRepository.lastEmailRedirectTo, AuthRepository.mobileEmailRedirectTo);
      expect(controller.awaitingEmailConfirmation, isTrue);
      expect(controller.pendingVerificationEmail, 'owner@example.com');
      expect(controller.activeOrganization, isNull);
    });

    test('maps missing organization RPC to rollout guidance', () async {
      final controller = AppSessionController(
        authRepository: _FakeAuthRepository(currentUserValue: _testUser()),
        organizationRepository: _FakeOrganizationRepository(
          createError: const PostgrestException(
            message: 'Could not find the function public.create_organization_with_owner(org_name, org_slug, org_invite_code) in the schema cache',
          ),
        ),
      );

      await controller.initialize();
      await controller.createOrganization('Gamma Canteen');

      expect(
        controller.errorMessage,
        'Organization setup is incomplete. Apply the latest Supabase schema and try again.',
      );
    });

    test('selectOrganization switches active org and persists preference', () async {
      final controller = AppSessionController(
        authRepository: _FakeAuthRepository(currentUserValue: _testUser()),
        organizationRepository: _FakeOrganizationRepository(
          organizations: const [
            OrganizationSummary(
              id: 'org-1',
              name: 'Alpha Foods',
              slug: 'alpha-foods',
              inviteCode: 'ALPHA123',
              role: OrganizationRole.owner,
            ),
            OrganizationSummary(
              id: 'org-2',
              name: 'Beta Stores',
              slug: 'beta-stores',
              inviteCode: 'BETA1234',
              role: OrganizationRole.manager,
            ),
          ],
        ),
      );

      await controller.initialize();
      await controller.selectOrganization('org-2');

      final preferences = await SharedPreferences.getInstance();
      expect(controller.activeOrganization?.id, 'org-2');
      expect(preferences.getString('active_organization_id'), 'org-2');
    });
  });

  group('WorkspaceDataController offline queue replay', () {
    test('queues sale offline and replays it when connectivity returns', () async {
      final localStore = _FakeLocalWorkspaceStore();
      final salesRepository = _FakeSalesRepository();
      final controller = WorkspaceDataController(
        localStore: localStore,
        salesRepository: salesRepository,
        expenseRepository: _FakeExpenseRepository(),
        templateRepository: _FakeTemplateRepository(),
        dispatchRepository: _FakeDispatchRepository(),
        contactRepository: _FakeContactRepository(),
        skipConnectivityInit: true,
      );

      controller.bindSession(_BoundSession());
      await Future<void>.delayed(Duration.zero);

      await controller.saveSale(
        SalesEntry(
          id: 'sale-1',
          organizationId: 'org-1',
          date: DateTime(2026, 5, 24),
          shopName: 'RK Stores',
          orderType: OrderType.externalOrder,
          deliverySlot: DeliverySlot.morning,
          prepLeadDays: 1,
          productType: ProductType.idly,
          saleType: SaleType.wholesale,
          ratePerUnit: 4,
          quantity: 50,
          costPerUnit: 2,
          paymentStatus: PaymentStatus.pending,
          paidAmount: 0,
        ),
      );

      expect(controller.pendingQueueCount, 1);
      expect(controller.sales, hasLength(1));

      await controller.setOnlineForTest(true);

      expect(salesRepository.upsertedSales, hasLength(1));
      expect(salesRepository.upsertedSales.single.id, 'sale-1');
      expect(controller.pendingQueueCount, 0);
    });

    test('replays queued sale delete when connectivity returns', () async {
      final localStore = _FakeLocalWorkspaceStore();
      final salesRepository = _FakeSalesRepository();
      final controller = WorkspaceDataController(
        localStore: localStore,
        salesRepository: salesRepository,
        expenseRepository: _FakeExpenseRepository(),
        templateRepository: _FakeTemplateRepository(),
        dispatchRepository: _FakeDispatchRepository(),
        contactRepository: _FakeContactRepository(),
        skipConnectivityInit: true,
      );

      controller.bindSession(_BoundSession());
      await Future<void>.delayed(Duration.zero);

      await controller.deleteSale('sale-1');

      expect(controller.pendingQueueCount, 1);

      await controller.setOnlineForTest(true);

      expect(salesRepository.deletedSaleIds, ['sale-1']);
      expect(controller.pendingQueueCount, 0);
    });

    test('queues expense offline and replays it when connectivity returns', () async {
      final localStore = _FakeLocalWorkspaceStore();
      final expenseRepository = _FakeExpenseRepository();
      final controller = WorkspaceDataController(
        localStore: localStore,
        salesRepository: _FakeSalesRepository(),
        expenseRepository: expenseRepository,
        templateRepository: _FakeTemplateRepository(),
        dispatchRepository: _FakeDispatchRepository(),
        contactRepository: _FakeContactRepository(),
        skipConnectivityInit: true,
      );

      controller.bindSession(_BoundSession());
      await Future<void>.delayed(Duration.zero);

      await controller.addExpense(
        ExpenseEntry(
          id: 'expense-1',
          organizationId: 'org-1',
          date: DateTime(2026, 5, 24),
          category: ExpenseCategory.food,
          amount: 420,
          notes: 'Rice batter',
        ),
      );

      expect(controller.pendingQueueCount, 1);
      expect(controller.expenses, hasLength(1));

      await controller.setOnlineForTest(true);

      expect(expenseRepository.upsertedExpenses, hasLength(1));
      expect(expenseRepository.upsertedExpenses.single.id, 'expense-1');
      expect(controller.pendingQueueCount, 0);
    });

    test('queued contact upsert and template delete override incoming remote snapshots', () async {
      final localStore = _FakeLocalWorkspaceStore();
      final templateRepository = _StreamingTemplateRepository();
      final contactRepository = _StreamingContactRepository();
      const deletedTemplate = SupplyTemplate(
        id: 'template-1',
        organizationId: 'org-1',
        shopName: 'Alpha Stores',
        productType: ProductType.idly,
        saleType: SaleType.wholesale,
        quantity: 40,
        ratePerUnit: 4,
        costPerUnit: 2,
        deliverySlot: DeliverySlot.morning,
        activeWeekdays: {1, 2, 3, 4, 5, 6, 7},
      );
      const keptTemplate = SupplyTemplate(
        id: 'template-2',
        organizationId: 'org-1',
        shopName: 'Beta Stores',
        productType: ProductType.idiyappam,
        saleType: SaleType.retail,
        quantity: 10,
        ratePerUnit: 6,
        costPerUnit: 3,
        deliverySlot: DeliverySlot.evening,
        activeWeekdays: {1, 2, 3, 4, 5, 6, 7},
      );

      await localStore.replaceCachedRecords(
        entityType: 'supply_templates',
        organizationId: 'org-1',
        records: [deletedTemplate.toDataMap()],
      );

      final controller = WorkspaceDataController(
        localStore: localStore,
        salesRepository: _FakeSalesRepository(),
        expenseRepository: _FakeExpenseRepository(),
        templateRepository: templateRepository,
        dispatchRepository: _FakeDispatchRepository(),
        contactRepository: contactRepository,
        skipConnectivityInit: true,
      );

      controller.bindSession(_BoundSession());
      await Future<void>.delayed(Duration.zero);

      await controller.saveContact(
        ContactEntry(
          id: 'contact-1',
          organizationId: 'org-1',
          contactType: ContactType.shop,
          name: 'Queued Contact',
          mobile: '9999999999',
        ),
      );
      await controller.deleteTemplate('template-1');

      contactRepository.emit([
        ContactEntry(
          id: 'contact-1',
          organizationId: 'org-1',
          contactType: ContactType.shop,
          name: 'Remote Stale Contact',
          mobile: '1111111111',
        ),
        ContactEntry(
          id: 'contact-2',
          organizationId: 'org-1',
          contactType: ContactType.customer,
          name: 'Remote Contact',
          mobile: '2222222222',
        ),
      ]);
      templateRepository.emit([deletedTemplate, keptTemplate]);
      await Future<void>.delayed(Duration.zero);

      expect(controller.pendingQueueCount, 2);
      expect(controller.contacts, hasLength(2));
      expect(controller.contacts.firstWhere((contact) => contact.id == 'contact-1').name, 'Queued Contact');
      expect(controller.contacts.firstWhere((contact) => contact.id == 'contact-1').mobile, '9999999999');
      expect(controller.templates.map((template) => template.id), isNot(contains('template-1')));
      expect(controller.templates.map((template) => template.id), contains('template-2'));
    });

    test('queued contact delete and template upsert win over conflicting remote state', () async {
      final localStore = _FakeLocalWorkspaceStore();
      final templateRepository = _StreamingTemplateRepository();
      final contactRepository = _StreamingContactRepository();
      final existingContact = ContactEntry(
        id: 'contact-1',
        organizationId: 'org-1',
        contactType: ContactType.shop,
        name: 'Cached Contact',
        mobile: '9999999999',
      );
      const queuedTemplate = SupplyTemplate(
        id: 'template-3',
        organizationId: 'org-1',
        shopName: 'Gamma Stores',
        productType: ProductType.sandhagai,
        saleType: SaleType.wholesale,
        quantity: 25,
        ratePerUnit: 5,
        costPerUnit: 2.5,
        deliverySlot: DeliverySlot.morning,
        activeWeekdays: {1, 2, 3, 4, 5, 6, 7},
      );

      await localStore.replaceCachedRecords(
        entityType: 'contacts',
        organizationId: 'org-1',
        records: [existingContact.toDataMap()],
      );

      final controller = WorkspaceDataController(
        localStore: localStore,
        salesRepository: _FakeSalesRepository(),
        expenseRepository: _FakeExpenseRepository(),
        templateRepository: templateRepository,
        dispatchRepository: _FakeDispatchRepository(),
        contactRepository: contactRepository,
        skipConnectivityInit: true,
      );

      controller.bindSession(_BoundSession());
      await Future<void>.delayed(Duration.zero);

      await controller.deleteContact('contact-1');
      await controller.saveTemplate(queuedTemplate);

      contactRepository.emit([
        ContactEntry(
          id: 'contact-1',
          organizationId: 'org-1',
          contactType: ContactType.shop,
          name: 'Remote Contact',
          mobile: '1111111111',
        ),
        ContactEntry(
          id: 'contact-2',
          organizationId: 'org-1',
          contactType: ContactType.customer,
          name: 'Remote Survivor',
          mobile: '2222222222',
        ),
      ]);
      templateRepository.emit([
        const SupplyTemplate(
          id: 'template-3',
          organizationId: 'org-1',
          shopName: 'Remote Old Gamma',
          productType: ProductType.idly,
          saleType: SaleType.retail,
          quantity: 10,
          ratePerUnit: 3,
          costPerUnit: 1.5,
          deliverySlot: DeliverySlot.evening,
          activeWeekdays: {1, 2, 3, 4, 5, 6, 7},
        ),
      ]);
      await Future<void>.delayed(Duration.zero);

      expect(controller.pendingQueueCount, 2);
      expect(controller.contacts.map((contact) => contact.id), isNot(contains('contact-1')));
      expect(controller.contacts.map((contact) => contact.id), contains('contact-2'));
      final mergedTemplate = controller.templates.firstWhere((template) => template.id == 'template-3');
      expect(mergedTemplate.shopName, 'Gamma Stores');
      expect(mergedTemplate.productType, ProductType.sandhagai);
      expect(mergedTemplate.saleType, SaleType.wholesale);
    });
  });
}

User _testUser() {
  return User.fromJson({
    'id': 'user-1',
    'aud': 'authenticated',
    'role': 'authenticated',
    'email': 'owner@example.com',
    'app_metadata': {
      'provider': 'email',
      'providers': ['email'],
    },
    'user_metadata': <String, dynamic>{},
    'created_at': '2024-01-01T00:00:00.000Z',
    'updated_at': '2024-01-01T00:00:00.000Z',
  })!;
}

class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository({this.currentUserValue, this.signInError, this.signUpError, this.signUpResponse});

  final User? currentUserValue;
  final Object? signInError;
  final Object? signUpError;
  final AuthResponse? signUpResponse;
  String? lastEmailRedirectTo;

  @override
  Stream<AuthState> get authStateChanges => const Stream<AuthState>.empty();

  @override
  User? get currentUser => currentUserValue;

  @override
  Future<void> signIn({required String email, required String password}) async {
    if (signInError != null) {
      throw signInError!;
    }
  }

  @override
  Future<AuthResponse> signUp({required String email, required String password}) async {
    if (signUpError != null) {
      throw signUpError!;
    }
    lastEmailRedirectTo = AuthRepository.mobileEmailRedirectTo;
    return signUpResponse ?? AuthResponse(session: Session(accessToken: 'token', tokenType: 'bearer', user: currentUserValue ?? _testUser()));
  }
}

class _FakeOrganizationRepository extends OrganizationRepository {
  _FakeOrganizationRepository({
    this.organizations = const [],
    this.joinedOrganization,
    this.createdOrganization,
    this.createError,
  });

  final List<OrganizationSummary> organizations;
  final OrganizationSummary? joinedOrganization;
  final OrganizationSummary? createdOrganization;
  final Object? createError;
  String? lastJoinedInviteCode;
  String? lastCreatedName;

  @override
  Future<List<OrganizationSummary>> fetchOrganizations(String userId) async => organizations;

  @override
  Future<OrganizationSummary> createOrganization({required String userId, required String name}) async {
    lastCreatedName = name;
    if (createError != null) {
      throw createError!;
    }
    return createdOrganization ?? organizations.first;
  }

  @override
  Future<OrganizationSummary> joinOrganization({required String userId, required String inviteCode}) async {
    lastJoinedInviteCode = inviteCode;
    return joinedOrganization ?? organizations.first;
  }
}

class _BoundSession extends AppSessionController {
  _BoundSession();

  @override
  User? get currentUser => _testUser();

  @override
  OrganizationSummary? get activeOrganization => const OrganizationSummary(
        id: 'org-1',
        name: 'Alpha Foods',
        slug: 'alpha-foods',
        inviteCode: 'ALPHA123',
        role: OrganizationRole.owner,
      );
}

class _FakeLocalWorkspaceStore extends LocalWorkspaceStore {
  _FakeLocalWorkspaceStore({List<SalesEntry> cachedSales = const []}) {
    for (final sale in cachedSales) {
      _cachedRecords[_cacheKey('sales_entries', sale.id)] = {
        'entity_type': 'sales_entries',
        'record_id': sale.id,
        'organization_id': sale.organizationId,
        'payload': sale.toDataMap(),
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      };
    }
  }

  final Map<String, Map<String, dynamic>> _cachedRecords = {};
  final List<Map<String, dynamic>> _queue = [];
  int _nextQueueId = 1;

  @override
  Future<List<Map<String, dynamic>>> getCachedRecords({required String entityType, required String organizationId}) async {
    final rows = _cachedRecords.values
        .where((row) => row['entity_type'] == entityType && row['organization_id'] == organizationId)
        .toList()
      ..sort((left, right) => (right['updated_at'] as int).compareTo(left['updated_at'] as int));
    return rows.map((row) => Map<String, dynamic>.from(row['payload'] as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> replaceCachedRecords({
    required String entityType,
    required String organizationId,
    required List<Map<String, dynamic>> records,
  }) async {
    _cachedRecords.removeWhere(
      (_, row) => row['entity_type'] == entityType && row['organization_id'] == organizationId,
    );
    for (final record in records) {
      _cachedRecords[_cacheKey(entityType, record['id'] as String)] = {
        'entity_type': entityType,
        'record_id': record['id'] as String,
        'organization_id': organizationId,
        'payload': Map<String, dynamic>.from(record),
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      };
    }
  }

  @override
  Future<void> upsertCachedRecord({
    required String entityType,
    required String organizationId,
    required String recordId,
    required Map<String, dynamic> payload,
  }) async {
    _cachedRecords[_cacheKey(entityType, recordId)] = {
      'entity_type': entityType,
      'record_id': recordId,
      'organization_id': organizationId,
      'payload': Map<String, dynamic>.from(payload),
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    };
  }

  @override
  Future<void> removeCachedRecord({required String entityType, required String recordId}) async {
    _cachedRecords.remove(_cacheKey(entityType, recordId));
  }

  @override
  Future<void> enqueueOperation({
    required String entityType,
    required String recordId,
    required String organizationId,
    required String operation,
    Map<String, dynamic>? payload,
  }) async {
    _queue.removeWhere(
      (row) => row['entity_type'] == entityType && row['record_id'] == recordId && row['operation'] == operation,
    );
    _queue.add({
      'id': _nextQueueId++,
      'entity_type': entityType,
      'record_id': recordId,
      'organization_id': organizationId,
      'operation': operation,
      'payload': payload == null ? null : Map<String, dynamic>.from(payload),
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'retry_count': 0,
      'last_error': null,
    });
  }

  @override
  Future<List<Map<String, dynamic>>> getPendingQueue({String? organizationId}) async {
    final rows = _queue
        .where((row) => organizationId == null || row['organization_id'] == organizationId)
        .toList()
      ..sort((left, right) => (left['created_at'] as int).compareTo(right['created_at'] as int));
    return rows.map((row) => Map<String, dynamic>.from(row)).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getPendingQueueForEntity({
    required String entityType,
    required String organizationId,
  }) async {
    final rows = _queue
        .where((row) => row['entity_type'] == entityType && row['organization_id'] == organizationId)
        .toList()
      ..sort((left, right) => (left['created_at'] as int).compareTo(right['created_at'] as int));
    return rows.map((row) => Map<String, dynamic>.from(row)).toList();
  }

  @override
  Future<void> removeQueueItem(int id) async {
    _queue.removeWhere((row) => row['id'] == id);
  }

  @override
  Future<void> markQueueFailed(int id, Object error) async {
    final index = _queue.indexWhere((row) => row['id'] == id);
    if (index == -1) {
      return;
    }
    final row = Map<String, dynamic>.from(_queue[index]);
    row['retry_count'] = (row['retry_count'] as int) + 1;
    row['last_error'] = error.toString();
    _queue[index] = row;
  }

  String _cacheKey(String entityType, String recordId) => '$entityType::$recordId';
}

class _FakeSalesRepository extends SalesRepository {
  final List<SalesEntry> upsertedSales = [];
  final List<String> deletedSaleIds = [];

  @override
  Stream<List<SalesEntry>> watchSales(String organizationId) => Stream.value(const []);

  @override
  Future<void> upsertSale({required String organizationId, required String userId, required SalesEntry sale}) async {
    upsertedSales.add(sale);
  }

  @override
  Future<void> deleteSale(String saleId) async {
    deletedSaleIds.add(saleId);
  }
}

class _FakeExpenseRepository extends ExpenseRepository {
  final List<ExpenseEntry> upsertedExpenses = [];

  @override
  Stream<List<ExpenseEntry>> watchExpenses(String organizationId) => Stream.value(const []);

  @override
  Future<void> upsertExpense({
    required String organizationId,
    required String userId,
    required ExpenseEntry expense,
  }) async {
    upsertedExpenses.add(expense);
  }
}

class _FakeTemplateRepository extends TemplateRepository {
  @override
  Stream<List<SupplyTemplate>> watchTemplates(String organizationId) => Stream.value(const []);
}

class _FakeDispatchRepository extends DispatchRepository {
  @override
  Stream<List<DispatchLeave>> watchDispatchLeaves(String organizationId) => Stream.value(const []);
}

class _FakeContactRepository extends ContactRepository {
  @override
  Stream<List<ContactEntry>> watchContacts(String organizationId) => Stream.value(const []);
}

class _StreamingTemplateRepository extends TemplateRepository {
  final StreamController<List<SupplyTemplate>> _controller = StreamController<List<SupplyTemplate>>.broadcast();

  @override
  Stream<List<SupplyTemplate>> watchTemplates(String organizationId) => _controller.stream;

  void emit(List<SupplyTemplate> templates) {
    _controller.add(templates);
  }
}

class _StreamingContactRepository extends ContactRepository {
  final StreamController<List<ContactEntry>> _controller = StreamController<List<ContactEntry>>.broadcast();

  @override
  Stream<List<ContactEntry>> watchContacts(String organizationId) => _controller.stream;

  void emit(List<ContactEntry> contacts) {
    _controller.add(contacts);
  }
}