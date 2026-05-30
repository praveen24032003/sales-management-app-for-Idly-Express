import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:idly_express_org_sync/src/domain/business_types.dart';
import 'package:idly_express_org_sync/src/domain/contact_entry.dart';
import 'package:idly_express_org_sync/src/domain/sales_entry.dart';
import 'package:idly_express_org_sync/src/domain/supply_template.dart';
import 'package:idly_express_org_sync/src/features/balances/presentation/shop_balances_screen.dart';
import 'package:idly_express_org_sync/src/features/contacts/presentation/contacts_screen.dart';
import 'package:idly_express_org_sync/src/features/dispatch/presentation/dispatch_screen.dart';
import 'package:idly_express_org_sync/src/features/sales/presentation/sale_editor_sheet.dart';
import 'package:idly_express_org_sync/src/features/workspace/application/workspace_data_controller.dart';

void main() {
  group('sales and payments widgets', () {
    testWidgets('new sale editor uses customer defaults for external orders', (tester) async {
      final controller = _FakeWorkspaceDataController(seedSales: const []);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SaleEditorSheet(workspace: controller),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Customer details'), findsOneWidget);
      expect(_findTextFormField('Customer name'), findsOneWidget);
      expect(find.text('Will collect later'), findsOneWidget);

      final rateField = tester.widget<TextField>(_findTextFormField('Rate per unit'));
      expect(rateField.controller?.text, '5');
    });

    testWidgets('sale editor submits edited sales fields', (tester) async {
      final controller = _FakeWorkspaceDataController(
        seedSales: [
          SalesEntry(
            id: 'sale-1',
            organizationId: 'org-1',
            date: DateTime(2026, 5, 20),
            shopName: 'RK Stores',
            orderType: OrderType.externalOrder,
            deliverySlot: DeliverySlot.morning,
            deliveryTime: '07:30',
            prepLeadDays: 2,
            productType: ProductType.idly,
            saleType: SaleType.wholesale,
            ratePerUnit: 3.5,
            quantity: 100,
            costPerUnit: 2.0,
            paymentStatus: PaymentStatus.pending,
            paidAmount: 100,
            customerMobile: '9876543210',
            notes: 'old note',
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SaleEditorSheet(
              workspace: controller,
              existingSale: controller.seedSales.first,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(_findTextFormField('Amount paid'), '120');
      await tester.enterText(_findTextFormField('Notes'), 'updated note');
      await tester.ensureVisible(find.text('Update sale'));
      await tester.tap(find.text('Update sale'));
      await tester.pumpAndSettle();

      expect(controller.savedSale, isNotNull);
      expect(controller.savedSale!.id, 'sale-1');
      expect(controller.savedSale!.deliveryTime, '07:30');
      expect(controller.savedSale!.prepLeadDays, 2);
      expect(controller.savedSale!.customerMobile, '9876543210');
      expect(controller.savedSale!.paidAmount, 120);
      expect(controller.savedSale!.notes, 'updated note');
      expect(controller.savedSale!.paymentStatus, PaymentStatus.pending);
    });

    testWidgets('dispatch screen shows external orders for the selected date', (tester) async {
      final today = DateTime.now();
      final controller = _FakeWorkspaceDataController(
        seedSales: [
          SalesEntry(
            id: 'sale-1',
            organizationId: 'org-1',
            date: DateTime(today.year, today.month, today.day),
            shopName: 'Anand',
            orderType: OrderType.externalOrder,
            deliverySlot: DeliverySlot.morning,
            deliveryTime: '07:15',
            prepLeadDays: 1,
            productType: ProductType.idly,
            saleType: SaleType.retail,
            ratePerUnit: 5,
            quantity: 40,
            costPerUnit: 2.5,
            paymentStatus: PaymentStatus.pending,
            paidAmount: 0,
            customerMobile: '9876543210',
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: DispatchScreen(workspace: controller),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Anand'), findsOneWidget);
      expect(find.text('External order'), findsOneWidget);
      expect(find.textContaining('Pending'), findsOneWidget);
      expect(find.text('Morning'), findsWidgets);
      expect(find.text('Evening'), findsOneWidget);
    });

    testWidgets('dispatch screen shows planned and exact dispatched quantity for template-managed sales', (tester) async {
      final today = DateTime.now();
      final controller = _FakeWorkspaceDataController(
        seedSales: [
          SalesEntry(
            id: 'sale-1',
            organizationId: 'org-1',
            date: DateTime(today.year, today.month, today.day),
            shopName: 'RK Stores',
            orderType: OrderType.everydaySupply,
            deliverySlot: DeliverySlot.morning,
            deliveryTime: '07:00',
            prepLeadDays: 1,
            productType: ProductType.idly,
            saleType: SaleType.wholesale,
            ratePerUnit: 5,
            quantity: 12,
            costPerUnit: 3,
            paymentStatus: PaymentStatus.pending,
            paidAmount: 0,
            notes: '[dispatch:template-1|${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}|morning] Dispatched via org planner',
          ),
        ],
        seedTemplates: [
          SupplyTemplate(
            id: 'template-1',
            organizationId: 'org-1',
            shopName: 'RK Stores',
            productType: ProductType.idly,
            saleType: SaleType.wholesale,
            quantity: 40,
            ratePerUnit: 5,
            costPerUnit: 3,
            deliverySlot: DeliverySlot.morning,
            activeWeekdays: {1, 2, 3, 4, 5, 6, 7},
            morningQuantity: 40,
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: DispatchScreen(workspace: controller),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Planned 40'), findsOneWidget);
      expect(find.textContaining('Dispatched 12'), findsOneWidget);
    });

    testWidgets('dispatch screen does not show a morning-only template in the evening section', (tester) async {
      final controller = _FakeWorkspaceDataController(
        seedSales: const [],
        seedTemplates: const [
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
            eveningQuantity: 0,
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: DispatchScreen(workspace: controller),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Morning Shop'), findsOneWidget);
      expect(find.text('No Evening dispatch planned.'), findsNothing);

      await tester.drag(find.byKey(const ValueKey('dispatchSlotPager')), const Offset(-500, 0));
      await tester.pumpAndSettle();

      expect(find.text('Morning Shop'), findsNothing);
      expect(find.text('No Evening dispatch planned.'), findsOneWidget);
    });

    testWidgets('dispatch screen switches between morning and evening pages', (tester) async {
      final controller = _FakeWorkspaceDataController(
        seedSales: const [],
        seedTemplates: const [
          SupplyTemplate(
            id: 'template-morning',
            organizationId: 'org-1',
            shopName: 'Sunrise Shop',
            productType: ProductType.idly,
            saleType: SaleType.wholesale,
            quantity: 15,
            ratePerUnit: 5,
            costPerUnit: 3,
            deliverySlot: DeliverySlot.morning,
            activeWeekdays: {1, 2, 3, 4, 5, 6, 7},
            morningQuantity: 15,
          ),
          SupplyTemplate(
            id: 'template-evening',
            organizationId: 'org-1',
            shopName: 'Moonlight Shop',
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

      await tester.pumpWidget(
        MaterialApp(
          home: DispatchScreen(workspace: controller),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sunrise Shop'), findsOneWidget);
      expect(find.text('Moonlight Shop'), findsNothing);

      await tester.drag(find.byKey(const ValueKey('dispatchSlotPager')), const Offset(-500, 0));
      await tester.pumpAndSettle();

      expect(find.text('Sunrise Shop'), findsNothing);
      expect(find.text('Moonlight Shop'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('dispatchSlotMorningButton')));
      await tester.pumpAndSettle();

      expect(find.text('Sunrise Shop'), findsOneWidget);
      expect(find.text('Moonlight Shop'), findsNothing);
    });

    testWidgets('pending collections groups balances and records payment', (tester) async {
      final controller = _FakeWorkspaceDataController(
        seedSales: [
          SalesEntry(
            id: 'sale-1',
            organizationId: 'org-1',
            date: DateTime(2026, 5, 20),
            shopName: 'RK Stores',
            orderType: OrderType.externalOrder,
            deliverySlot: DeliverySlot.morning,
            prepLeadDays: 1,
            productType: ProductType.idly,
            saleType: SaleType.wholesale,
            ratePerUnit: 3.5,
            quantity: 100,
            costPerUnit: 2.0,
            paymentStatus: PaymentStatus.pending,
            paidAmount: 200,
          ),
          SalesEntry(
            id: 'sale-2',
            organizationId: 'org-1',
            date: DateTime(2026, 5, 21),
            shopName: 'RK Stores',
            orderType: OrderType.externalOrder,
            deliverySlot: DeliverySlot.evening,
            prepLeadDays: 1,
            productType: ProductType.idly,
            saleType: SaleType.wholesale,
            ratePerUnit: 4,
            quantity: 50,
            costPerUnit: 2.0,
            paymentStatus: PaymentStatus.pending,
            paidAmount: 100,
          ),
          SalesEntry(
            id: 'sale-3',
            organizationId: 'org-1',
            date: DateTime(2026, 5, 21),
            shopName: 'Metro Foods',
            orderType: OrderType.externalOrder,
            deliverySlot: DeliverySlot.morning,
            prepLeadDays: 1,
            productType: ProductType.idly,
            saleType: SaleType.wholesale,
            ratePerUnit: 3,
            quantity: 20,
            costPerUnit: 2.0,
            paymentStatus: PaymentStatus.pending,
            paidAmount: 0,
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ShopBalancesScreen(workspace: controller),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('RK Stores'), findsOneWidget);
      expect(find.textContaining('2 open entries'), findsOneWidget);
      expect(find.textContaining('2 shops still have pending collections.'), findsOneWidget);
      expect(_findTextFormField('Search shop'), findsOneWidget);
      expect(find.text('Highest due'), findsOneWidget);

      await tester.ensureVisible(find.text('Collect').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Collect').first);
      await tester.pumpAndSettle();
      await tester.enterText(_findTextFormField('Paid amount'), '50');
      await tester.tap(find.text('Save payment'));
      await tester.pumpAndSettle();

      expect(controller.lastPaymentShop, 'RK Stores');
      expect(controller.lastPaymentAmount, 50);
    });

    testWidgets('contacts screen saves a newly added contact', (tester) async {
      final controller = _FakeContactWorkspaceDataController();

      await tester.pumpWidget(
        MaterialApp(
          home: ContactsScreen(workspace: controller),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add contact'));
      await tester.pumpAndSettle();
      await tester.enterText(_findTextFormField('Shop name'), 'Fresh Shop');
      await tester.enterText(_findTextFormField('Mobile number'), '9876543210');
      await tester.tap(find.text('Save contact'));
      await tester.pumpAndSettle();

      expect(controller.savedContact, isNotNull);
      expect(controller.savedContact!.name, 'Fresh Shop');
      expect(controller.contacts.single.name, 'Fresh Shop');
    });

    testWidgets('contacts screen delete then add submits a fresh contact id', (tester) async {
      final controller = _FakeContactWorkspaceDataController(
        initialContacts: const [
          ContactEntry(
            id: 'contact-old',
            organizationId: 'org-1',
            contactType: ContactType.shop,
            name: 'Legacy Shop',
            mobile: '9000000001',
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ContactsScreen(workspace: controller),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.edit_outlined).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete contact'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(controller.deletedContactIds, ['contact-old']);
      expect(controller.contacts, isEmpty);

      await tester.tap(find.text('Add contact'));
      await tester.pumpAndSettle();
      await tester.enterText(_findTextFormField('Shop name'), 'Fresh Shop');
      await tester.enterText(_findTextFormField('Mobile number'), '9876543210');
      await tester.tap(find.text('Save contact'));
      await tester.pumpAndSettle();

      expect(controller.savedContact, isNotNull);
      expect(controller.savedContact!.id, isEmpty);
      expect(controller.contacts.single.id, 'contact-1');
      expect(controller.contacts.single.name, 'Fresh Shop');
    });
  });
}

Finder _findTextFormField(String label) {
  return find.byWidgetPredicate(
    (widget) => widget is TextField && widget.decoration?.labelText == label,
  );
}

class _FakeWorkspaceDataController extends WorkspaceDataController {
  _FakeWorkspaceDataController({required this.seedSales, this.seedTemplates = const []}) : super(skipConnectivityInit: true);

  final List<SalesEntry> seedSales;
  final List<SupplyTemplate> seedTemplates;

  SalesEntry? savedSale;
  String? lastPaymentShop;
  double? lastPaymentAmount;

  @override
  List<SalesEntry> get sales => seedSales;

  @override
  List<SupplyTemplate> get templates => seedTemplates;

  @override
  List<ContactEntry> get contacts => const [];

  @override
  bool get isLoading => false;

  @override
  SalesEntry? dispatchEntryForTemplate(SupplyTemplate template, DateTime date, DeliverySlot slot) {
    for (final sale in seedSales) {
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
    for (final template in seedTemplates) {
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
    for (final sale in seedSales) {
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
  Future<void> saveSale(SalesEntry sale) async {
    savedSale = sale;
  }

  @override
  Future<void> applyPaymentToShopPending(String shopName, double paidAmount) async {
    lastPaymentShop = shopName;
    lastPaymentAmount = paidAmount;
  }
}

class _FakeContactWorkspaceDataController extends WorkspaceDataController {
  _FakeContactWorkspaceDataController({List<ContactEntry> initialContacts = const []})
    : _contacts = List<ContactEntry>.from(initialContacts),
      super(skipConnectivityInit: true);

  final List<ContactEntry> _contacts;
  ContactEntry? savedContact;
  final List<String> deletedContactIds = [];

  @override
  List<ContactEntry> get contacts => List<ContactEntry>.unmodifiable(_contacts);

  @override
  bool get isLoading => false;

  @override
  Future<void> saveContact(ContactEntry contact) async {
    savedContact = contact;
    _contacts.add(contact.copyWith(id: contact.id.isEmpty ? 'contact-1' : contact.id));
    notifyListeners();
  }

  @override
  Future<void> deleteContact(String contactId) async {
    deletedContactIds.add(contactId);
    _contacts.removeWhere((contact) => contact.id == contactId);
    notifyListeners();
  }
}