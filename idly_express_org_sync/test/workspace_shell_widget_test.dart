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
import 'package:idly_express_org_sync/src/features/settings/theme_controller.dart';
import 'package:idly_express_org_sync/src/features/workspace/application/workspace_data_controller.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  testWidgets('shared add button stays visible and stays centered by section', (tester) async {
    final session = _ShellSession();
    final workspace = _ShellWorkspaceController();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AppSessionController>.value(value: session),
          ChangeNotifierProvider<WorkspaceDataController>.value(value: workspace),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const WorkspaceShellScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final screenWidth = tester.getSize(find.byType(Scaffold).first).width;

    expect(find.byIcon(Icons.add_rounded), findsOneWidget);
    expect(_fabCenter(tester).dx, closeTo(screenWidth / 2, 36));

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.text('Add sale entry'), findsOneWidget);
    await tester.tapAt(const Offset(12, 12));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Dispatch'));
    await tester.pumpAndSettle();
    expect(_fabCenter(tester).dx, closeTo(screenWidth / 2, 36));

    await tester.tap(find.text('Sales'));
    await tester.pumpAndSettle();
    expect(_fabCenter(tester).dx, closeTo(screenWidth / 2, 36));
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.text('Add sale entry'), findsOneWidget);
    await tester.tapAt(const Offset(12, 12));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Expenses'));
    await tester.pumpAndSettle();
    expect(_fabCenter(tester).dx, closeTo(screenWidth / 2, 36));
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.text('Expense date'), findsOneWidget);
  });

  testWidgets('expenses delete then add submits a fresh expense id', (tester) async {
    final session = _ShellSession();
    final workspace = _MutableExpenseShellWorkspaceController(
      initialExpenses: [
        ExpenseEntry(
          id: 'expense-old',
          organizationId: 'org-1',
          date: DateTime(2026, 5, 20),
          category: ExpenseCategory.petrol,
          amount: 250,
          notes: 'old expense',
        ),
      ],
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AppSessionController>.value(value: session),
          ChangeNotifierProvider<WorkspaceDataController>.value(value: workspace),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const WorkspaceShellScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Expenses'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert_rounded).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete expense'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(workspace.deletedExpenseIds, ['expense-old']);
    expect(workspace.expenses, isEmpty);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    final editableFields = find.byType(EditableText);
    await tester.enterText(editableFields.at(0), '120');
    await tester.enterText(editableFields.at(1), 'new expense');
    await tester.tap(find.text('Save expense'));
    await tester.pumpAndSettle();

    expect(workspace.savedExpense, isNotNull);
    expect(workspace.savedExpense!.id, isEmpty);
    expect(workspace.expenses.single.id, 'expense-1');
    expect(workspace.expenses.single.amount, 120);
  });

  testWidgets('sales delete then dispatch does not recreate deleted dispatch sale in section flow', (tester) async {
    final today = DateTime.now();
    final dispatchDate = DateTime(today.year, today.month, today.day);
    final initialSale = SalesEntry(
      id: 'sale-1',
      organizationId: 'org-1',
      date: dispatchDate,
      shopName: 'RK Stores',
      orderType: OrderType.everydaySupply,
      deliverySlot: DeliverySlot.morning,
      deliveryTime: '07:00',
      prepLeadDays: 1,
      productType: ProductType.idly,
      saleType: SaleType.wholesale,
      ratePerUnit: 5,
      quantity: 40,
      costPerUnit: 3,
      paymentStatus: PaymentStatus.pending,
      paidAmount: 0,
      customerMobile: '9999999999',
      notes: '[dispatch:template-1|${dispatchDate.year.toString().padLeft(4, '0')}-${dispatchDate.month.toString().padLeft(2, '0')}-${dispatchDate.day.toString().padLeft(2, '0')}|morning] Dispatched via org planner',
    );
    final template = SupplyTemplate(
      id: 'template-1',
      organizationId: 'org-1',
      shopName: 'RK Stores',
      shopMobile: '9999999999',
      productType: ProductType.idly,
      saleType: SaleType.wholesale,
      quantity: 40,
      ratePerUnit: 5,
      costPerUnit: 3,
      deliverySlot: DeliverySlot.morning,
      deliveryTime: '07:00',
      activeWeekdays: {1, 2, 3, 4, 5, 6, 7},
    );
    final session = _ShellSession();
    final workspace = _MutableShellWorkspaceController(
      initialSales: [initialSale],
      initialTemplates: [template],
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AppSessionController>.value(value: session),
          ChangeNotifierProvider<WorkspaceDataController>.value(value: workspace),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const WorkspaceShellScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sales'));
    await tester.pumpAndSettle();

    expect(find.text('RK Stores'), findsWidgets);
    await tester.tap(find.byIcon(Icons.more_vert_rounded).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete sale'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(workspace.sales, isEmpty);
    expect(find.text('No sales yet'), findsOneWidget);

    await tester.tap(find.text('Dispatch'));
    await tester.pumpAndSettle();

    expect(find.text('RK Stores'), findsWidgets);
    expect(find.text('Skip today'), findsWidgets);
    expect(find.text('Payment for RK Stores'), findsNothing);
    expect(workspace.sales, isEmpty);

    await tester.tap(find.text('Sales'));
    await tester.pumpAndSettle();
    expect(workspace.sales, isEmpty);
    expect(find.text('No sales yet'), findsOneWidget);
  });

  testWidgets('dispatch shows not dispatched shops before dispatched shops', (tester) async {
    final today = DateTime.now();
    final dispatchDate = DateTime(today.year, today.month, today.day);
    final session = _ShellSession();
    final workspace = _MutableShellWorkspaceController(
      initialTemplates: [
        SupplyTemplate(
          id: 'template-dispatched',
          organizationId: 'org-1',
          shopName: 'Alpha Stores',
          shopMobile: '9999999991',
          productType: ProductType.idly,
          saleType: SaleType.wholesale,
          quantity: 20,
          ratePerUnit: 5,
          costPerUnit: 3,
          deliverySlot: DeliverySlot.morning,
          deliveryTime: '07:00',
          activeWeekdays: {1, 2, 3, 4, 5, 6, 7},
        ),
        SupplyTemplate(
          id: 'template-pending',
          organizationId: 'org-1',
          shopName: 'Zulu Stores',
          shopMobile: '9999999992',
          productType: ProductType.idly,
          saleType: SaleType.wholesale,
          quantity: 20,
          ratePerUnit: 5,
          costPerUnit: 3,
          deliverySlot: DeliverySlot.morning,
          deliveryTime: '07:00',
          activeWeekdays: {1, 2, 3, 4, 5, 6, 7},
        ),
      ],
      initialSales: [
        SalesEntry(
          id: 'sale-dispatched',
          organizationId: 'org-1',
          date: dispatchDate,
          shopName: 'Alpha Stores',
          orderType: OrderType.everydaySupply,
          deliverySlot: DeliverySlot.morning,
          deliveryTime: '07:00',
          prepLeadDays: 1,
          productType: ProductType.idly,
          saleType: SaleType.wholesale,
          ratePerUnit: 5,
          quantity: 20,
          costPerUnit: 3,
          paymentStatus: PaymentStatus.pending,
          paidAmount: 0,
          customerMobile: '9999999991',
          notes: '[dispatch:template-dispatched|${dispatchDate.year.toString().padLeft(4, '0')}-${dispatchDate.month.toString().padLeft(2, '0')}-${dispatchDate.day.toString().padLeft(2, '0')}|morning] Dispatched via org planner',
        ),
      ],
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AppSessionController>.value(value: session),
          ChangeNotifierProvider<WorkspaceDataController>.value(value: workspace),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const WorkspaceShellScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Dispatch'));
    await tester.pumpAndSettle();

    final pendingY = tester.getTopLeft(find.text('Zulu Stores')).dy;
    final dispatchedY = tester.getTopLeft(find.text('Alpha Stores')).dy;

    expect(pendingY, lessThan(dispatchedY));
  });

  testWidgets('editing a dispatched sale via sales UI keeps dispatch protection and locks identity fields', (tester) async {
    final today = DateTime.now();
    final dispatchDate = DateTime(today.year, today.month, today.day);
    final initialSale = SalesEntry(
      id: 'sale-edit-1',
      organizationId: 'org-1',
      date: dispatchDate,
      shopName: 'RK Stores',
      orderType: OrderType.everydaySupply,
      deliverySlot: DeliverySlot.morning,
      deliveryTime: '07:00',
      prepLeadDays: 1,
      productType: ProductType.idly,
      saleType: SaleType.wholesale,
      ratePerUnit: 5,
      quantity: 40,
      costPerUnit: 3,
      paymentStatus: PaymentStatus.pending,
      paidAmount: 0,
      customerMobile: '9999999999',
      notes: '[dispatch:template-1|${dispatchDate.year.toString().padLeft(4, '0')}-${dispatchDate.month.toString().padLeft(2, '0')}-${dispatchDate.day.toString().padLeft(2, '0')}|morning] Dispatched via org planner',
    );
    final template = SupplyTemplate(
      id: 'template-1',
      organizationId: 'org-1',
      shopName: 'RK Stores',
      shopMobile: '9999999999',
      productType: ProductType.idly,
      saleType: SaleType.wholesale,
      quantity: 40,
      ratePerUnit: 5,
      costPerUnit: 3,
      deliverySlot: DeliverySlot.morning,
      deliveryTime: '07:00',
      activeWeekdays: {1, 2, 3, 4, 5, 6, 7},
    );
    final session = _ShellSession();
    final workspace = _MutableShellWorkspaceController(
      initialSales: [initialSale],
      initialTemplates: [template],
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AppSessionController>.value(value: session),
          ChangeNotifierProvider<WorkspaceDataController>.value(value: workspace),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const WorkspaceShellScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sales'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert_rounded).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit sale'));
    await tester.pumpAndSettle();

    expect(find.text('Edit sale entry'), findsOneWidget);
    expect(find.textContaining('This sale came from a dispatch template.'), findsOneWidget);
    expect(find.text('Edit template instead'), findsOneWidget);
    expect(find.text('Template-managed details'), findsOneWidget);
    expect(find.text('Template product'), findsOneWidget);
    expect(find.text('Quantity and pricing'), findsOneWidget);

    final shopTextField = tester.widget<TextField>(
      find.descendant(
        of: find.byKey(const ValueKey('saleEditorShopNameField')),
        matching: find.byType(TextField),
      ),
    );
    expect(shopTextField.readOnly, isTrue);

    final quantityField = find.byKey(const ValueKey('saleEditorQuantityField'));
    await tester.enterText(quantityField, '42');
    final updateButton = find.widgetWithText(FilledButton, 'Update sale');
    await tester.ensureVisible(updateButton);
    await tester.tap(updateButton);
    await tester.pumpAndSettle();

    expect(workspace.sales.single.quantity, 42);
    expect(workspace.sales.single.notes, startsWith('[dispatch:template-1|'));
    expect(find.text('[dispatch:'), findsNothing);

    await tester.tap(find.byIcon(Icons.more_vert_rounded).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete sale'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(workspace.sales, isEmpty);
    await tester.tap(find.text('Dispatch'));
    await tester.pumpAndSettle();

    expect(find.text('Skip today'), findsWidgets);
    expect(workspace.sales, isEmpty);
  });

  testWidgets('dispatch-managed sale can jump to matching template editor', (tester) async {
    final today = DateTime.now();
    final dispatchDate = DateTime(today.year, today.month, today.day);
    final initialSale = SalesEntry(
      id: 'sale-template-jump',
      organizationId: 'org-1',
      date: dispatchDate,
      shopName: 'RK Stores',
      orderType: OrderType.everydaySupply,
      deliverySlot: DeliverySlot.morning,
      deliveryTime: '07:00',
      prepLeadDays: 1,
      productType: ProductType.idly,
      saleType: SaleType.wholesale,
      ratePerUnit: 5,
      quantity: 40,
      costPerUnit: 3,
      paymentStatus: PaymentStatus.pending,
      paidAmount: 0,
      customerMobile: '9999999999',
      notes: '[dispatch:template-1|${dispatchDate.year.toString().padLeft(4, '0')}-${dispatchDate.month.toString().padLeft(2, '0')}-${dispatchDate.day.toString().padLeft(2, '0')}|morning] Dispatched via org planner',
    );
    final template = SupplyTemplate(
      id: 'template-1',
      organizationId: 'org-1',
      shopName: 'RK Stores',
      shopMobile: '9999999999',
      productType: ProductType.idly,
      saleType: SaleType.wholesale,
      quantity: 40,
      ratePerUnit: 5,
      costPerUnit: 3,
      deliverySlot: DeliverySlot.morning,
      deliveryTime: '07:00',
      activeWeekdays: {1, 2, 3, 4, 5, 6, 7},
    );
    final session = _ShellSession();
    final workspace = _MutableShellWorkspaceController(
      initialSales: [initialSale],
      initialTemplates: [template],
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AppSessionController>.value(value: session),
          ChangeNotifierProvider<WorkspaceDataController>.value(value: workspace),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const WorkspaceShellScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sales'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.more_vert_rounded).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit sale'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, 'Edit template instead'));
    await tester.pumpAndSettle();

    expect(find.text('Supply templates'), findsOneWidget);
    expect(find.text('Edit template'), findsOneWidget);
    expect(find.text('Shop name'), findsOneWidget);
  });

  testWidgets('overview hides invite code, reveals profit on tap, and settings contains invite and sync details', (tester) async {
    final today = DateTime.now();
    final session = _ShellSession();
    final themeController = ThemeController();
    final workspace = _MutableShellWorkspaceController(
      initialSales: [
        SalesEntry(
          id: 'sale-1',
          organizationId: 'org-1',
          date: DateTime(today.year, today.month, today.day),
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
      ],
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AppSessionController>.value(value: session),
          ChangeNotifierProvider<WorkspaceDataController>.value(value: workspace),
          ChangeNotifierProvider<ThemeController>.value(value: themeController),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const WorkspaceShellScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Invite ALPHA123'), findsNothing);
    expect(find.text('Booked morning'), findsOneWidget);
    expect(find.text('Tap to reveal'), findsOneWidget);

    await tester.ensureVisible(find.text('Profit'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profit'));
    await tester.pumpAndSettle();

    expect(find.text('Tap to reveal'), findsNothing);
    expect(find.textContaining('₹'), findsWidgets);

    await tester.ensureVisible(find.text('Booked morning'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Booked morning'));
    await tester.pumpAndSettle();

    expect(find.text('Dispatch'), findsWidgets);
    expect(find.text('Morning Shop'), findsOneWidget);

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();

    expect(find.text('Workspace sync'), findsOneWidget);
    expect(find.text('ALPHA123'), findsOneWidget);
  });

  testWidgets('overview metric cards keep consistent spacing in light and dark themes', (tester) async {
    final today = DateTime.now();

    Future<Map<String, dynamic>> pumpForTheme(ThemeData theme) async {
      final session = _ShellSession();
      final workspace = _MutableShellWorkspaceController(
        initialSales: [
          SalesEntry(
            id: 'sale-1',
            organizationId: 'org-1',
            date: DateTime(today.year, today.month, today.day),
            shopName: 'RK Stores',
            orderType: OrderType.externalOrder,
            deliverySlot: DeliverySlot.morning,
            prepLeadDays: 1,
            productType: ProductType.idly,
            saleType: SaleType.wholesale,
            ratePerUnit: 5,
            quantity: 10,
            costPerUnit: 3,
            paymentStatus: PaymentStatus.pending,
            paidAmount: 20,
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
        ],
      );

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

      final salesCardFinder = find.byKey(const ValueKey('metricCard_today_sales'));
      final expensesCardFinder = find.byKey(const ValueKey('metricCard_today_expenses'));
      final bookedMorningFinder = find.byKey(const ValueKey('metricCard_booked_morning'));
      final bookedEveningFinder = find.byKey(const ValueKey('metricCard_booked_evening'));
      final profitFinder = find.byKey(const ValueKey('metricCard_profit'));
      expect(salesCardFinder, findsOneWidget);
      expect(expensesCardFinder, findsOneWidget);
      expect(bookedMorningFinder, findsOneWidget);
      expect(bookedEveningFinder, findsOneWidget);
      expect(profitFinder, findsOneWidget);

      final salesRect = tester.getRect(salesCardFinder);
      final expensesRect = tester.getRect(expensesCardFinder);
      final bookedMorningRect = tester.getRect(bookedMorningFinder);
      final bookedEveningRect = tester.getRect(bookedEveningFinder);
      final profitRect = tester.getRect(profitFinder);
      final salesInk = tester.widget<Ink>(salesCardFinder);
      final decoration = salesInk.decoration! as BoxDecoration;
      final gradient = decoration.gradient! as LinearGradient;

      expect(tester.takeException(), isNull);
      return {
        'salesRect': salesRect,
        'expensesRect': expensesRect,
        'bookedMorningRect': bookedMorningRect,
        'bookedEveningRect': bookedEveningRect,
        'profitRect': profitRect,
        'gradientSecondColor': gradient.colors.last,
      };
    }

    final lightResult = await pumpForTheme(AppTheme.light);
    final darkResult = await pumpForTheme(AppTheme.dark);

    final lightSalesRect = lightResult['salesRect'] as Rect;
    final lightExpensesRect = lightResult['expensesRect'] as Rect;
    final lightBookedMorningRect = lightResult['bookedMorningRect'] as Rect;
    final lightBookedEveningRect = lightResult['bookedEveningRect'] as Rect;
    final lightProfitRect = lightResult['profitRect'] as Rect;
    final darkSalesRect = darkResult['salesRect'] as Rect;
    final darkExpensesRect = darkResult['expensesRect'] as Rect;
    final darkBookedMorningRect = darkResult['bookedMorningRect'] as Rect;
    final darkBookedEveningRect = darkResult['bookedEveningRect'] as Rect;
    final darkProfitRect = darkResult['profitRect'] as Rect;

    expect(lightSalesRect.size, equals(lightExpensesRect.size));
    expect(darkSalesRect.size, equals(darkExpensesRect.size));
    expect(lightExpensesRect.left - lightSalesRect.right, closeTo(14, 0.1));
    expect(darkExpensesRect.left - darkSalesRect.right, closeTo(14, 0.1));
    expect(lightBookedMorningRect.top, closeTo(lightBookedEveningRect.top, 0.1));
    expect(darkBookedMorningRect.top, closeTo(darkBookedEveningRect.top, 0.1));
    expect(lightProfitRect.top, greaterThan(lightBookedMorningRect.top));
    expect(darkProfitRect.top, greaterThan(darkBookedMorningRect.top));
    expect(lightResult['gradientSecondColor'], isNot(equals(darkResult['gradientSecondColor'])));
  });
}

Offset _fabCenter(WidgetTester tester) {
  final iconFinder = find.descendant(
    of: find.byType(FloatingActionButton),
    matching: find.byIcon(Icons.add_rounded),
  );
  return tester.getCenter(iconFinder);
}

class _ShellSession extends AppSessionController {
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

class _ShellWorkspaceController extends WorkspaceDataController {
  _ShellWorkspaceController() : super(skipConnectivityInit: true);

  @override
  List<SalesEntry> get sales => const [];

  @override
  List<ExpenseEntry> get expenses => const [];

  @override
  List<SupplyTemplate> get templates => const [];

  @override
  List<ContactEntry> get contacts => const [];

  @override
  bool get isLoading => false;

  @override
  bool get isOnline => true;

  @override
  int get pendingQueueCount => 0;

  @override
  Future<void> saveSale(SalesEntry sale) async {}

  @override
  Future<void> saveExpense(ExpenseEntry expense) async {}
}

class _MutableExpenseShellWorkspaceController extends WorkspaceDataController {
  _MutableExpenseShellWorkspaceController({required List<ExpenseEntry> initialExpenses})
    : _expenses = List<ExpenseEntry>.from(initialExpenses),
      super(skipConnectivityInit: true);

  final List<ExpenseEntry> _expenses;
  ExpenseEntry? savedExpense;
  final List<String> deletedExpenseIds = [];

  @override
  List<SalesEntry> get sales => const [];

  @override
  List<ExpenseEntry> get expenses => List<ExpenseEntry>.unmodifiable(_expenses);

  @override
  List<SupplyTemplate> get templates => const [];

  @override
  List<ContactEntry> get contacts => const [];

  @override
  bool get isLoading => false;

  @override
  bool get isOnline => true;

  @override
  int get pendingQueueCount => 0;

  @override
  Future<void> saveSale(SalesEntry sale) async {}

  @override
  Future<void> saveExpense(ExpenseEntry expense) async {
    savedExpense = expense;
    final normalized = expense.copyWith(id: expense.id.isEmpty ? 'expense-1' : expense.id);
    final index = _expenses.indexWhere((item) => item.id == normalized.id);
    if (index == -1) {
      _expenses.add(normalized);
    } else {
      _expenses[index] = normalized;
    }
    notifyListeners();
  }

  @override
  Future<void> deleteExpense(String expenseId) async {
    deletedExpenseIds.add(expenseId);
    _expenses.removeWhere((expense) => expense.id == expenseId);
    notifyListeners();
  }
}

class _MutableShellWorkspaceController extends WorkspaceDataController {
  _MutableShellWorkspaceController({
    required List<SalesEntry> initialSales,
    required List<SupplyTemplate> initialTemplates,
  })  : _sales = List<SalesEntry>.from(initialSales),
        _dispatchLeaves = <DispatchLeave>[],
        _templates = List<SupplyTemplate>.from(initialTemplates),
        super(skipConnectivityInit: true);

  final List<SalesEntry> _sales;
  final List<DispatchLeave> _dispatchLeaves;
  final List<SupplyTemplate> _templates;

  @override
  List<SalesEntry> get sales => List<SalesEntry>.unmodifiable(_sales);

  @override
  List<ExpenseEntry> get expenses => const [];

  @override
  List<SupplyTemplate> get templates => List<SupplyTemplate>.unmodifiable(_templates);

  @override
  List<DispatchLeave> get dispatchLeaves => List<DispatchLeave>.unmodifiable(_dispatchLeaves);

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
  double get todaySalesTotal {
    final now = DateTime.now();
    return _sales
        .where((sale) => sale.date.year == now.year && sale.date.month == now.month && sale.date.day == now.day)
        .fold<double>(0, (sum, sale) => sum + sale.totalSalesAmount);
  }

  @override
  double get todayExpenseTotal => 0;

  @override
  double get outstandingAmount => _sales.fold<double>(0, (sum, sale) => sum + sale.pendingAmount);

  @override
  double get totalProfit => _sales.fold<double>(0, (sum, sale) => sum + sale.profit);

  @override
  Future<void> saveSale(SalesEntry sale) async {
    final index = _sales.indexWhere((item) => item.id == sale.id);
    final existing = index == -1 ? null : _sales[index];
    final normalizedSale = _preserveDispatchNote(existing, sale);
    if (index == -1) {
      _sales.add(normalizedSale);
    } else {
      _sales[index] = normalizedSale;
    }
    notifyListeners();
  }

  @override
  Future<void> deleteSale(String saleId, {SalesEntry? deletedSale}) async {
    final sale = deletedSale ?? _sales.cast<SalesEntry?>().firstWhere((item) => item?.id == saleId, orElse: () => null);
    final templateId = _dispatchTemplateIdForSale(sale);
    if (sale != null && templateId != null) {
      final leaveDate = DateTime(sale.date.year, sale.date.month, sale.date.day);
      final exists = _dispatchLeaves.any(
        (leave) => leave.templateId == templateId &&
            leave.deliverySlot == sale.deliverySlot &&
            leave.leaveDate.year == leaveDate.year &&
            leave.leaveDate.month == leaveDate.month &&
            leave.leaveDate.day == leaveDate.day,
      );
      if (!exists) {
        _dispatchLeaves.add(
          DispatchLeave(
            id: 'leave-${_dispatchLeaves.length + 1}',
            organizationId: 'org-1',
            templateId: templateId,
            leaveDate: leaveDate,
            deliverySlot: sale.deliverySlot,
            createdAt: DateTime.now(),
          ),
        );
      }
    }

    _sales.removeWhere((sale) => sale.id == saleId);
    notifyListeners();
  }

  @override
  Future<void> dispatchTemplate({
    required SupplyTemplate template,
    required DateTime date,
    required DeliverySlot slot,
    PaymentStatus paymentStatus = PaymentStatus.pending,
    double? paidAmount,
  }) async {
    if (hasDispatchEntry(template, date, slot) || findDispatchLeave(template.id, date, slot) != null) {
      return;
    }

    _sales.add(
      SalesEntry(
        id: 'redispatched-${_sales.length + 1}',
        organizationId: 'org-1',
        date: DateTime(date.year, date.month, date.day),
        shopName: template.shopName,
        orderType: OrderType.everydaySupply,
        deliverySlot: slot,
        deliveryTime: template.deliveryTime,
        prepLeadDays: template.prepLeadDays,
        productType: template.productType,
        saleType: template.saleType,
        ratePerUnit: template.ratePerUnit,
        quantity: quantityForSlot(template, slot),
        costPerUnit: template.costPerUnit,
        paymentStatus: paymentStatus,
        paidAmount: paidAmount,
        customerMobile: template.shopMobile,
        notes: '[dispatch:${template.id}|${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}|${slot.dbValue}] Dispatched via org planner',
      ),
    );
    notifyListeners();
  }

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
  bool hasDispatchEntry(SupplyTemplate template, DateTime date, DeliverySlot slot) {
    return _sales.any(
      (sale) => sale.orderType == OrderType.everydaySupply &&
          sale.shopName == template.shopName &&
          sale.deliverySlot == slot &&
          sale.productType == template.productType &&
          sale.saleType == template.saleType &&
          sale.date.year == date.year &&
          sale.date.month == date.month &&
          sale.date.day == date.day,
    );
  }

  @override
  SalesEntry? dispatchEntryForTemplate(SupplyTemplate template, DateTime date, DeliverySlot slot) {
    for (final sale in _sales) {
      if (sale.orderType != OrderType.everydaySupply) {
        continue;
      }
      if (sale.shopName != template.shopName || sale.deliverySlot != slot) {
        continue;
      }
      if (sale.productType != template.productType || sale.saleType != template.saleType) {
        continue;
      }
      if (sale.date.year != date.year || sale.date.month != date.month || sale.date.day != date.day) {
        continue;
      }
      return sale;
    }
    return null;
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
      if (sale.date.year != date.year || sale.date.month != date.month || sale.date.day != date.day) {
        continue;
      }
      if (slot != null && sale.deliverySlot != slot) {
        continue;
      }
      total += sale.quantity;
    }
    return total;
  }

  @override
  DispatchLeave? findDispatchLeave(String templateId, DateTime date, DeliverySlot slot) {
    for (final leave in _dispatchLeaves) {
      if (leave.templateId == templateId &&
          leave.deliverySlot == slot &&
          leave.leaveDate.year == date.year &&
          leave.leaveDate.month == date.month &&
          leave.leaveDate.day == date.day) {
        return leave;
      }
    }
    return null;
  }

  @override
  Future<void> toggleDispatchLeave({
    required SupplyTemplate template,
    required DateTime date,
    required DeliverySlot slot,
  }) async {}

  @override
  Future<void> saveExpense(ExpenseEntry expense) async {}

  String? _dispatchTemplateIdForSale(SalesEntry? sale) {
    final notes = sale?.notes;
    if (notes == null || !notes.startsWith('[dispatch:')) {
      return null;
    }

    final closingIndex = notes.indexOf(']');
    if (closingIndex == -1) {
      return null;
    }

    final payload = notes.substring('[dispatch:'.length, closingIndex);
    final separatorIndex = payload.indexOf('|');
    if (separatorIndex <= 0) {
      return null;
    }

    return payload.substring(0, separatorIndex);
  }

  SalesEntry _preserveDispatchNote(SalesEntry? existing, SalesEntry next) {
    final existingTemplateId = _dispatchTemplateIdForSale(existing);
    if (existingTemplateId == null) {
      return next;
    }

    final visibleNote = _visibleDispatchNote(next.notes);
    final date = DateTime(next.date.year, next.date.month, next.date.day);
    final suffix = (visibleNote == null || visibleNote.isEmpty) ? 'Dispatched via org planner' : visibleNote;
    return next.copyWith(
      notes: '[dispatch:$existingTemplateId|${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}|${next.deliverySlot.dbValue}] $suffix',
    );
  }

  String? _visibleDispatchNote(String? notes) {
    if (notes == null) {
      return null;
    }

    final trimmed = notes.trim();
    if (!trimmed.startsWith('[dispatch:')) {
      return trimmed.isEmpty ? null : trimmed;
    }

    final closingIndex = trimmed.indexOf(']');
    if (closingIndex == -1) {
      return null;
    }

    final suffix = trimmed.substring(closingIndex + 1).trim();
    return suffix.isEmpty ? null : suffix;
  }
}