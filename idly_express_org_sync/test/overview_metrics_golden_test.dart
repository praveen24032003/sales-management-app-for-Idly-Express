import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:idly_express_org_sync/src/core/theme/app_theme.dart';
import 'package:idly_express_org_sync/src/domain/business_types.dart';
import 'package:idly_express_org_sync/src/domain/contact_entry.dart';
import 'package:idly_express_org_sync/src/domain/dispatch_leave.dart';
import 'package:idly_express_org_sync/src/domain/expense_entry.dart';
import 'package:idly_express_org_sync/src/domain/sales_entry.dart';
import 'package:idly_express_org_sync/src/domain/supply_template.dart';
import 'package:idly_express_org_sync/src/features/app_shell/application/app_session_controller.dart';
import 'package:idly_express_org_sync/src/features/dashboard/presentation/workspace_shell_screen.dart';
import 'package:idly_express_org_sync/src/features/organization/domain/organization_summary.dart';
import 'package:idly_express_org_sync/src/features/workspace/application/workspace_data_controller.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpOverviewMetrics(
    WidgetTester tester, {
    required ThemeData theme,
  }) async {
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    final today = DateTime(2026, 5, 30);
    final session = _GoldenShellSession();
    final workspace = _GoldenWorkspaceController(
      initialSales: [
        SalesEntry(
          id: 'sale-1',
          organizationId: 'org-1',
          date: today,
          shopName: 'RK Stores',
          orderType: OrderType.externalOrder,
          deliverySlot: DeliverySlot.morning,
          deliveryTime: '07:00',
          prepLeadDays: 1,
          productType: ProductType.idly,
          saleType: SaleType.wholesale,
          ratePerUnit: 5,
          quantity: 10,
          costPerUnit: 3,
          paymentStatus: PaymentStatus.pending,
          paidAmount: 20,
        ),
        SalesEntry(
          id: 'sale-2',
          organizationId: 'org-1',
          date: today,
          shopName: 'Metro Foods',
          orderType: OrderType.externalOrder,
          deliverySlot: DeliverySlot.evening,
          deliveryTime: '18:30',
          prepLeadDays: 1,
          productType: ProductType.idly,
          saleType: SaleType.retail,
          ratePerUnit: 6,
          quantity: 8,
          costPerUnit: 3.2,
          paymentStatus: PaymentStatus.paid,
          paidAmount: 48,
        ),
      ],
      initialTemplates: [
        SupplyTemplate(
          id: 'template-1',
          organizationId: 'org-1',
          shopName: 'Morning Shop',
          productType: ProductType.idly,
          saleType: SaleType.wholesale,
          quantity: 25,
          ratePerUnit: 5,
          costPerUnit: 3,
          deliverySlot: DeliverySlot.morning,
          activeWeekdays: {1, 2, 3, 4, 5, 6, 7},
          morningQuantity: 25,
        ),
        SupplyTemplate(
          id: 'template-2',
          organizationId: 'org-1',
          shopName: 'Evening Shop',
          productType: ProductType.idly,
          saleType: SaleType.wholesale,
          quantity: 18,
          ratePerUnit: 5,
          costPerUnit: 3,
          deliverySlot: DeliverySlot.evening,
          activeWeekdays: {1, 2, 3, 4, 5, 6, 7},
          eveningQuantity: 18,
        ),
      ],
    );

    await tester.binding.setSurfaceSize(const Size(430, 960));
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AppSessionController>.value(value: session),
          ChangeNotifierProvider<WorkspaceDataController>.value(value: workspace),
        ],
        child: MaterialApp(
          theme: theme,
          home: const WorkspaceShellScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('overviewMetricsGrid')), findsOneWidget);
  }

  testWidgets('overview metric grid matches light golden', (tester) async {
    await pumpOverviewMetrics(tester, theme: AppTheme.light);
    await expectLater(
      find.byKey(const ValueKey('overviewMetricsGrid')),
      matchesGoldenFile('goldens/overview_metrics_light.png'),
    );
  });

  testWidgets('overview metric grid matches dark golden', (tester) async {
    await pumpOverviewMetrics(tester, theme: AppTheme.dark);
    await expectLater(
      find.byKey(const ValueKey('overviewMetricsGrid')),
      matchesGoldenFile('goldens/overview_metrics_dark.png'),
    );
  });
}

class _GoldenShellSession extends AppSessionController {
  @override
  User? get currentUser => User.fromJson({
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
      });

  @override
  OrganizationSummary? get activeOrganization => const OrganizationSummary(
        id: 'org-1',
        name: 'Alpha Foods',
        slug: 'alpha-foods',
        inviteCode: 'ALPHA123',
        role: OrganizationRole.owner,
      );
}

class _GoldenWorkspaceController extends WorkspaceDataController {
  _GoldenWorkspaceController({
    required List<SalesEntry> initialSales,
    required List<SupplyTemplate> initialTemplates,
  })  : _sales = List<SalesEntry>.from(initialSales),
        _templates = List<SupplyTemplate>.from(initialTemplates),
        super(skipConnectivityInit: true);

  final List<SalesEntry> _sales;
  final List<SupplyTemplate> _templates;

  @override
  List<SalesEntry> get sales => List<SalesEntry>.unmodifiable(_sales);

  @override
  List<ExpenseEntry> get expenses => const [];

  @override
  List<SupplyTemplate> get templates => List<SupplyTemplate>.unmodifiable(_templates);

  @override
  List<DispatchLeave> get dispatchLeaves => const [];

  @override
  List<ContactEntry> get contacts => const [];

  @override
  bool get isLoading => false;

  @override
  bool get isOnline => true;

  @override
  int get pendingQueueCount => 0;

  @override
  String? get errorMessage => null;

  @override
  double get todaySalesTotal => _sales.fold<double>(0, (sum, sale) => sum + sale.totalSalesAmount);

  @override
  double get todayExpenseTotal => 0;

  @override
  double get outstandingAmount => _sales.fold<double>(0, (sum, sale) => sum + sale.pendingAmount);

  @override
  double get totalProfit => _sales.fold<double>(0, (sum, sale) => sum + sale.profit);

  @override
  int quantityForSlot(SupplyTemplate template, DeliverySlot slot) {
    final hasSplitQuantities = template.morningQuantity > 0 || template.eveningQuantity > 0;
    if (hasSplitQuantities) {
      if (slot == DeliverySlot.morning) {
        return template.morningQuantity;
      }
      if (slot == DeliverySlot.evening) {
        return template.eveningQuantity;
      }
    }
    if (slot == DeliverySlot.morning && template.morningQuantity > 0) {
      return template.morningQuantity;
    }
    if (slot == DeliverySlot.evening && template.eveningQuantity > 0) {
      return template.eveningQuantity;
    }
    return template.quantity;
  }

  @override
  int bookedQuantityForDate(DateTime date, {DeliverySlot? slot}) {
    var total = 0;
    for (final template in _templates) {
      if (!template.isActiveOnDate(date)) {
        continue;
      }
      if (slot == null || slot == DeliverySlot.morning) {
        total += quantityForSlot(template, DeliverySlot.morning);
      }
      if (slot == null || slot == DeliverySlot.evening) {
        total += quantityForSlot(template, DeliverySlot.evening);
      }
    }
    for (final sale in _sales) {
      if (sale.orderType != OrderType.externalOrder) {
        continue;
      }
      if (slot != null && sale.deliverySlot != slot) {
        continue;
      }
      total += sale.quantity;
    }
    return total;
  }
}