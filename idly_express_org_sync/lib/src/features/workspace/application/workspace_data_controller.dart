import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../../../core/utils/id_generator.dart';
import '../../../data/local/local_workspace_store.dart';
import '../../../domain/business_types.dart';
import '../../../domain/contact_entry.dart';
import '../../../domain/dispatch_leave.dart';
import '../../../domain/expense_entry.dart';
import '../../../domain/sales_entry.dart';
import '../../../domain/supply_template.dart';
import '../../app_shell/application/app_session_controller.dart';
import '../../contacts/data/contact_repository.dart';
import '../../dispatch/data/dispatch_repository.dart';
import '../../expenses/data/expense_repository.dart';
import '../../sales/data/sales_repository.dart';
import '../../templates/data/template_repository.dart';

class WorkspaceDataController extends ChangeNotifier {
  static const _entitySales = 'sales_entries';
  static const _entityExpenses = 'expenses';
  static const _entityTemplates = 'supply_templates';
  static const _entityLeaves = 'dispatch_leaves';
  static const _entityContacts = 'contacts';
  static const _dispatchNotePrefix = '[dispatch:';
  static const _operationUpsert = 'upsert';
  static const _operationDelete = 'delete';

  final LocalWorkspaceStore _localStore;
  final SalesRepository _salesRepository;
  final ExpenseRepository _expenseRepository;
  final TemplateRepository _templateRepository;
  final DispatchRepository _dispatchRepository;
  final ContactRepository _contactRepository;
  final Connectivity _connectivity;

  StreamSubscription<List<SalesEntry>>? _salesSubscription;
  StreamSubscription<List<ExpenseEntry>>? _expenseSubscription;
  StreamSubscription<List<SupplyTemplate>>? _templateSubscription;
  StreamSubscription<List<DispatchLeave>>? _leaveSubscription;
  StreamSubscription<List<ContactEntry>>? _contactSubscription;
  StreamSubscription<dynamic>? _connectivitySubscription;

  List<SalesEntry> _sales = const [];
  List<ExpenseEntry> _expenses = const [];
  List<SupplyTemplate> _templates = const [];
  List<DispatchLeave> _dispatchLeaves = const [];
  List<ContactEntry> _contacts = const [];
  bool _isLoading = false;
  bool _isOnline = false;
  String? _errorMessage;
  String? _organizationId;
  String? _userId;
  bool _hasInitialSales = false;
  bool _hasInitialExpenses = false;
  bool _hasInitialTemplates = false;
  bool _hasInitialLeaves = false;
  bool _hasInitialContacts = false;
  int _pendingQueueCount = 0;

  List<SalesEntry> get sales => _sales;
  List<ExpenseEntry> get expenses => _expenses;
  List<SupplyTemplate> get templates => _templates;
  List<DispatchLeave> get dispatchLeaves => _dispatchLeaves;
  List<ContactEntry> get contacts => _contacts;
  bool get isLoading => _isLoading;
  bool get isOnline => _isOnline;
  String? get errorMessage => _errorMessage;
  int get pendingQueueCount => _pendingQueueCount;

  double get todaySalesTotal {
    final today = DateTime.now();
    return _sales
        .where((sale) => _isSameDay(sale.date, today))
        .fold<double>(0, (sum, sale) => sum + sale.totalSalesAmount);
  }

  double get todayExpenseTotal {
    final today = DateTime.now();
    return _expenses
        .where((expense) => _isSameDay(expense.date, today))
        .fold<double>(0, (sum, expense) => sum + expense.amount);
  }

  double get outstandingAmount => _sales.fold<double>(0, (sum, sale) => sum + sale.pendingAmount);
  double get totalProfit => _sales.fold<double>(0, (sum, sale) => sum + sale.profit);

  WorkspaceDataController({
    LocalWorkspaceStore? localStore,
    SalesRepository? salesRepository,
    ExpenseRepository? expenseRepository,
    TemplateRepository? templateRepository,
    DispatchRepository? dispatchRepository,
    ContactRepository? contactRepository,
    Connectivity? connectivity,
    bool skipConnectivityInit = false,
  }) : _localStore = localStore ?? LocalWorkspaceStore.instance,
       _salesRepository = salesRepository ?? SalesRepository(),
       _expenseRepository = expenseRepository ?? ExpenseRepository(),
       _templateRepository = templateRepository ?? TemplateRepository(),
       _dispatchRepository = dispatchRepository ?? DispatchRepository(),
       _contactRepository = contactRepository ?? ContactRepository(),
       _connectivity = connectivity ?? Connectivity() {
    if (skipConnectivityInit) {
      return;
    }
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((result) async {
      await _updateOnlineState(result);
    });
    () async {
      await _updateOnlineState(await _connectivity.checkConnectivity());
    }();
  }

  void bindSession(AppSessionController session) {
    final nextOrganizationId = session.activeOrganization?.id;
    final nextUserId = session.currentUser?.id;

    if (_organizationId == nextOrganizationId && _userId == nextUserId) {
      return;
    }

    _organizationId = nextOrganizationId;
    _userId = nextUserId;

    if (_organizationId == null || _userId == null) {
      _salesSubscription?.cancel();
      _expenseSubscription?.cancel();
      _templateSubscription?.cancel();
      _leaveSubscription?.cancel();
      _contactSubscription?.cancel();
      _sales = const [];
      _expenses = const [];
      _templates = const [];
      _dispatchLeaves = const [];
      _contacts = const [];
      _pendingQueueCount = 0;
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
      return;
    }

    _loadCachedState();
    _subscribe();
  }

  Future<void> addSale(SalesEntry sale) async {
    await saveSale(sale);
  }

  Future<void> saveSale(SalesEntry sale) async {
    if (_organizationId == null || _userId == null) {
      _errorMessage = 'Select an organization before adding sales.';
      notifyListeners();
      return;
    }

    final draftSale = sale.copyWith(
      id: sale.id.isEmpty ? IdGenerator.uuid() : sale.id,
      organizationId: _organizationId!,
    );
    final existingSale = _findSaleById(draftSale.id);
    final dispatchTemplateId = _dispatchTemplateIdForSale(existingSale ?? draftSale);
    final newSale = dispatchTemplateId == null
        ? draftSale
        : draftSale.copyWith(
            notes: _dispatchNoteFor(
              dispatchTemplateId,
              DateTime(draftSale.date.year, draftSale.date.month, draftSale.date.day),
              draftSale.deliverySlot,
              noteText: _dispatchUserNote(draftSale.notes),
            ),
          );

    await _applyWrite(
      entityType: _entitySales,
      recordId: newSale.id,
      optimisticPayload: newSale.toDataMap(),
      remoteAction: () => _salesRepository.upsertSale(
        organizationId: _organizationId!,
        userId: _userId!,
        sale: newSale,
      ),
    );
  }

  Future<void> deleteSale(String saleId, {SalesEntry? deletedSale}) async {
    if (_organizationId == null) {
      return;
    }

    final sale = deletedSale ?? _findSaleById(saleId);
    await _createLeaveForDeletedDispatchSale(sale);

    await _applyDelete(
      entityType: _entitySales,
      recordId: saleId,
      remoteAction: () => _salesRepository.deleteSale(saleId),
    );
  }

  Future<void> applyPaymentToShopPending(String shopName, double paidAmount) async {
    if (paidAmount <= 0 || _organizationId == null || _userId == null) {
      return;
    }

    final pendingSales = _sales
        .where((sale) => sale.shopName == shopName && sale.pendingAmount > 0.1)
        .toList()
      ..sort((left, right) => left.date.compareTo(right.date));

    double remaining = paidAmount;

    for (final sale in pendingSales) {
      if (remaining <= 0.01) {
        break;
      }

      final payable = sale.pendingAmount < remaining ? sale.pendingAmount : remaining;
      final updatedPaidAmount = (sale.paidAmount ?? 0) + payable;
      final pendingAfterPayment = sale.totalSalesAmount - updatedPaidAmount;

      await saveSale(
        sale.copyWith(
          paidAmount: updatedPaidAmount,
          paymentStatus: pendingAfterPayment <= 0.1 ? PaymentStatus.paid : PaymentStatus.pending,
        ),
      );

      remaining -= payable;
    }
  }

  Future<void> addExpense(ExpenseEntry expense) async {
    if (_organizationId == null || _userId == null) {
      _errorMessage = 'Select an organization before adding expenses.';
      notifyListeners();
      return;
    }

    final newExpense = expense.copyWith(
      id: expense.id.isEmpty ? IdGenerator.uuid() : expense.id,
      organizationId: _organizationId!,
    );

    await _applyWrite(
      entityType: _entityExpenses,
      recordId: newExpense.id,
      optimisticPayload: newExpense.toDataMap(),
      remoteAction: () => _expenseRepository.upsertExpense(
        organizationId: _organizationId!,
        userId: _userId!,
        expense: newExpense,
      ),
    );
  }

  Future<void> saveExpense(ExpenseEntry expense) => addExpense(expense);

  Future<void> deleteExpense(String expenseId) async {
    if (_organizationId == null) {
      return;
    }

    await _applyDelete(
      entityType: _entityExpenses,
      recordId: expenseId,
      remoteAction: () => _expenseRepository.deleteExpense(expenseId),
    );
  }

  Future<void> saveTemplate(SupplyTemplate template) async {
    if (_organizationId == null || _userId == null) {
      _errorMessage = 'Select an organization before saving templates.';
      notifyListeners();
      return;
    }

    final nextTemplate = template.copyWith(
      id: template.id.isEmpty ? IdGenerator.uuid() : template.id,
      organizationId: _organizationId!,
    );

    await _applyWrite(
      entityType: _entityTemplates,
      recordId: nextTemplate.id,
      optimisticPayload: nextTemplate.toDataMap(),
      remoteAction: () => _templateRepository.upsertTemplate(
        organizationId: _organizationId!,
        userId: _userId!,
        template: nextTemplate,
      ),
    );
  }

  Future<void> saveContact(ContactEntry contact) async {
    if (_organizationId == null || _userId == null) {
      _errorMessage = 'Select an organization before saving contacts.';
      notifyListeners();
      return;
    }

    final nextContact = contact.copyWith(
      id: contact.id.isEmpty ? IdGenerator.uuid() : contact.id,
      organizationId: _organizationId!,
      updatedAt: DateTime.now(),
    );

    await _applyWrite(
      entityType: _entityContacts,
      recordId: nextContact.id,
      optimisticPayload: nextContact.toDataMap(),
      remoteAction: () => _contactRepository.upsertContact(
        organizationId: _organizationId!,
        userId: _userId!,
        contact: nextContact,
      ),
    );
  }

  Future<void> deleteContact(String contactId) async {
    if (_organizationId == null) {
      return;
    }

    await _applyDelete(
      entityType: _entityContacts,
      recordId: contactId,
      remoteAction: () => _contactRepository.deleteContact(contactId),
    );
  }

  Future<void> deleteTemplate(String templateId) async {
    if (_organizationId == null) return;

    await _applyDelete(
      entityType: _entityTemplates,
      recordId: templateId,
      remoteAction: () => _templateRepository.deleteTemplate(templateId),
    );
  }

  Future<void> toggleTemplateActive(SupplyTemplate template) async {
    await saveTemplate(template.copyWith(isActive: !template.isActive));
  }

  Future<void> toggleDispatchLeave({
    required SupplyTemplate template,
    required DateTime date,
    required DeliverySlot slot,
  }) async {
    final existing = findDispatchLeaveForTemplate(template, date, slot);
    if (existing != null) {
      await _applyDelete(
        entityType: _entityLeaves,
        recordId: existing.id,
        remoteAction: () => _dispatchRepository.deleteLeave(existing.id),
      );
      return;
    }

    if (_organizationId == null || _userId == null) return;

    final leave = DispatchLeave(
      id: IdGenerator.uuid(),
      organizationId: _organizationId!,
      templateId: _dispatchTemplateIdentity(template),
      leaveDate: DateTime(date.year, date.month, date.day),
      deliverySlot: slot,
      createdAt: DateTime.now(),
    );

    await _applyWrite(
      entityType: _entityLeaves,
      recordId: leave.id,
      optimisticPayload: leave.toDataMap(),
      remoteAction: () => _dispatchRepository.upsertLeave(
        organizationId: _organizationId!,
        userId: _userId!,
        leave: leave,
      ),
    );
  }

  Future<void> dispatchTemplate({
    required SupplyTemplate template,
    required DateTime date,
    required DeliverySlot slot,
    PaymentStatus paymentStatus = PaymentStatus.pending,
    double? paidAmount,
  }) async {
    if (hasDispatchEntry(template, date, slot) || findDispatchLeaveForTemplate(template, date, slot) != null) return;
    final dispatchDate = DateTime(date.year, date.month, date.day);
    final dispatchTemplateId = _dispatchTemplateIdentity(template);
    final sale = SalesEntry(
      id: IdGenerator.uuid(),
      organizationId: _organizationId ?? '',
      date: dispatchDate,
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
      notes: _dispatchNoteFor(dispatchTemplateId, dispatchDate, slot),
    );

    await addSale(sale);
  }

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

  List<DeliverySlot> templateSlots(SupplyTemplate template) {
    final slots = <DeliverySlot>[];
    if (template.morningQuantity > 0) slots.add(DeliverySlot.morning);
    if (template.eveningQuantity > 0) slots.add(DeliverySlot.evening);
    if (slots.isEmpty) slots.add(template.deliverySlot);
    return slots;
  }

  bool hasDispatchEntry(SupplyTemplate template, DateTime date, DeliverySlot slot) {
    final dispatchDate = DateTime(date.year, date.month, date.day);
    final dispatchKey = _dispatchKey(_dispatchTemplateIdentity(template), dispatchDate, slot);
    final legacyKey = _legacyDispatchKey(
      shopName: template.shopName,
      date: dispatchDate,
      slot: slot,
      productType: template.productType,
      saleType: template.saleType,
      deliveryTime: template.deliveryTime,
    );
    return _sales.any(
      (sale) {
        final saleDispatchKey = _dispatchKeyForSale(sale);
        if (saleDispatchKey == dispatchKey) {
          return true;
        }

        return _legacyDispatchKeyForSale(sale) == legacyKey;
      },
    );
  }

  SalesEntry? dispatchEntryForTemplate(SupplyTemplate template, DateTime date, DeliverySlot slot) {
    final dispatchDate = DateTime(date.year, date.month, date.day);
    final dispatchKey = _dispatchKey(_dispatchTemplateIdentity(template), dispatchDate, slot);
    final legacyKey = _legacyDispatchKey(
      shopName: template.shopName,
      date: dispatchDate,
      slot: slot,
      productType: template.productType,
      saleType: template.saleType,
      deliveryTime: template.deliveryTime,
    );

    for (final sale in _sales) {
      final saleDispatchKey = _dispatchKeyForSale(sale);
      if (saleDispatchKey == dispatchKey) {
        return sale;
      }

      if (_legacyDispatchKeyForSale(sale) == legacyKey) {
        return sale;
      }
    }

    return null;
  }

  int bookedQuantityForDate(DateTime date, {DeliverySlot? slot}) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    var total = 0;

    for (final template in _templates) {
      if (!template.isActiveOnDate(normalizedDate)) {
        continue;
      }

      final slots = slot == null ? templateSlots(template) : <DeliverySlot>[slot];
      for (final templateSlot in slots) {
        if (quantityForSlot(template, templateSlot) <= 0) {
          continue;
        }
        if (findDispatchLeaveForTemplate(template, normalizedDate, templateSlot) != null) {
          continue;
        }
        total += quantityForSlot(template, templateSlot);
      }
    }

    for (final sale in _sales) {
      if (sale.orderType != OrderType.externalOrder) {
        continue;
      }
      if (!_isSameDay(sale.date, normalizedDate)) {
        continue;
      }
      if (slot != null && sale.deliverySlot != slot) {
        continue;
      }
      total += sale.quantity;
    }

    return total;
  }

  String _dispatchNoteFor(String templateId, DateTime date, DeliverySlot slot, {String? noteText}) {
    final cleanedNote = noteText?.trim();
    final suffix = (cleanedNote == null || cleanedNote.isEmpty) ? 'Dispatched via org planner' : cleanedNote;
    return '${_dispatchKey(templateId, date, slot)}] $suffix';
  }

  String _dispatchKey(String templateId, DateTime date, DeliverySlot slot) {
    final dateKey = date.toIso8601String().split('T').first;
    return '$_dispatchNotePrefix$templateId|$dateKey|${slot.dbValue}';
  }

  String? _dispatchKeyForSale(SalesEntry sale) {
    final notes = sale.notes;
    if (notes == null || !notes.startsWith(_dispatchNotePrefix)) {
      return null;
    }

    final closingIndex = notes.indexOf(']');
    if (closingIndex == -1) {
      return null;
    }

    return notes.substring(0, closingIndex);
  }

  String? _dispatchTemplateIdForSale(SalesEntry sale) {
    final dispatchKey = _dispatchKeyForSale(sale);
    if (dispatchKey == null) {
      return null;
    }

    final templateAndRest = dispatchKey.substring(_dispatchNotePrefix.length);
    final separatorIndex = templateAndRest.indexOf('|');
    if (separatorIndex <= 0) {
      return null;
    }

    return templateAndRest.substring(0, separatorIndex);
  }

  String? _dispatchUserNote(String? notes) {
    if (notes == null) {
      return null;
    }

    final trimmed = notes.trim();
    if (!trimmed.startsWith(_dispatchNotePrefix)) {
      return trimmed.isEmpty ? null : trimmed;
    }

    final closingIndex = trimmed.indexOf(']');
    if (closingIndex == -1) {
      return null;
    }

    final suffix = trimmed.substring(closingIndex + 1).trim();
    return suffix.isEmpty ? null : suffix;
  }

  String _legacyDispatchKey({
    required String shopName,
    required DateTime date,
    required DeliverySlot slot,
    required ProductType productType,
    required SaleType saleType,
    required String? deliveryTime,
  }) {
    final dateKey = date.toIso8601String().split('T').first;
    final timeKey = deliveryTime?.trim().isNotEmpty == true ? deliveryTime!.trim() : '-';
    return 'legacy_dispatch|$shopName|$dateKey|${slot.dbValue}|${productType.dbValue}|${saleType.dbValue}|$timeKey';
  }

  String? _legacyDispatchKeyForSale(SalesEntry sale) {
    if (sale.orderType != OrderType.everydaySupply) {
      return null;
    }

    return _legacyDispatchKey(
      shopName: sale.shopName,
      date: DateTime(sale.date.year, sale.date.month, sale.date.day),
      slot: sale.deliverySlot,
      productType: sale.productType,
      saleType: sale.saleType,
      deliveryTime: sale.deliveryTime,
    );
  }

  List<Map<String, dynamic>> _deduplicateEntityRecords(String entityType, List<Map<String, dynamic>> records) {
    if (entityType != _entitySales) {
      return records;
    }

    final deduplicated = <String, Map<String, dynamic>>{};
    for (final record in records) {
      final key = _salesMergeKey(record);
      final existing = deduplicated[key];
      if (existing == null || _preferSalesRecord(candidate: record, current: existing)) {
        deduplicated[key] = record;
      }
    }
    return deduplicated.values.toList();
  }

  String _salesMergeKey(Map<String, dynamic> record) {
    final sale = SalesEntry.fromMap(record);
    final legacyKey = _legacyDispatchKeyForSale(sale);
    if (legacyKey != null) {
      return legacyKey;
    }

    final dispatchKey = _dispatchKeyForSale(sale);
    if (dispatchKey != null) {
      return dispatchKey;
    }

    return sale.id;
  }

  bool _preferSalesRecord({
    required Map<String, dynamic> candidate,
    required Map<String, dynamic> current,
  }) {
    final candidateSale = SalesEntry.fromMap(candidate);
    final currentSale = SalesEntry.fromMap(current);
    final candidateHasMarker = _dispatchKeyForSale(candidateSale) != null;
    final currentHasMarker = _dispatchKeyForSale(currentSale) != null;
    if (candidateHasMarker != currentHasMarker) {
      return candidateHasMarker;
    }

    return true;
  }

  String _dispatchTemplateIdentity(SupplyTemplate template) {
    final templateId = template.id.trim();
    if (templateId.isNotEmpty) {
      return templateId;
    }

    return _legacyTemplateIdentity(template, template.deliverySlot);
  }

  String _legacyTemplateIdentity(SupplyTemplate template, DeliverySlot slot) {
    final timeKey = template.deliveryTime?.trim().isNotEmpty == true ? template.deliveryTime!.trim() : '-';
    return [
      'legacy_template',
      _safeDispatchIdentitySegment(template.shopName),
      slot.dbValue,
      template.productType.dbValue,
      template.saleType.dbValue,
      _safeDispatchIdentitySegment(timeKey),
    ].join('~');
  }

  String _safeDispatchIdentitySegment(String value) {
    final normalized = value.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    return normalized.replaceAll(RegExp(r'^_+|_+$'), '').isEmpty ? '-' : normalized.replaceAll(RegExp(r'^_+|_+$'), '');
  }

  Set<String> _dispatchTemplateIdentityAliases(SupplyTemplate template, DeliverySlot slot) {
    final legacyIdentity = _legacyTemplateIdentity(template, slot);
    final templateId = template.id.trim();
    if (templateId.isEmpty) {
      return {legacyIdentity};
    }

    return {templateId, legacyIdentity};
  }

  DispatchLeave? findDispatchLeave(String templateId, DateTime date, DeliverySlot slot) {
    for (final leave in _dispatchLeaves) {
      if (leave.templateId == templateId && leave.deliverySlot == slot && _isSameDay(leave.leaveDate, date)) {
        return leave;
      }
    }
    return null;
  }

  DispatchLeave? findDispatchLeaveForTemplate(SupplyTemplate template, DateTime date, DeliverySlot slot) {
    final acceptedTemplateIds = _dispatchTemplateIdentityAliases(template, slot);
    for (final leave in _dispatchLeaves) {
      if (acceptedTemplateIds.contains(leave.templateId) && leave.deliverySlot == slot && _isSameDay(leave.leaveDate, date)) {
        return leave;
      }
    }
    return null;
  }

  SalesEntry? _findSaleById(String saleId) {
    for (final sale in _sales) {
      if (sale.id == saleId) {
        return sale;
      }
    }
    return null;
  }

  Future<void> _createLeaveForDeletedDispatchSale(SalesEntry? sale) async {
    if (sale == null || _organizationId == null || _userId == null) {
      return;
    }

    final templateId = _dispatchTemplateIdForSale(sale);
    if (templateId == null) {
      return;
    }

    final leaveDate = DateTime(sale.date.year, sale.date.month, sale.date.day);
    if (findDispatchLeave(templateId, leaveDate, sale.deliverySlot) != null) {
      return;
    }

    final leave = DispatchLeave(
      id: IdGenerator.uuid(),
      organizationId: _organizationId!,
      templateId: templateId,
      leaveDate: leaveDate,
      deliverySlot: sale.deliverySlot,
      createdAt: DateTime.now(),
    );

    await _applyWrite(
      entityType: _entityLeaves,
      recordId: leave.id,
      optimisticPayload: leave.toDataMap(),
      remoteAction: () => _dispatchRepository.upsertLeave(
        organizationId: _organizationId!,
        userId: _userId!,
        leave: leave,
      ),
    );
  }

  Future<void> _applyWrite({
    required String entityType,
    required String recordId,
    required Map<String, dynamic> optimisticPayload,
    required Future<void> Function() remoteAction,
  }) async {
    if (_organizationId == null) return;

    _errorMessage = null;
    await _localStore.upsertCachedRecord(
      entityType: entityType,
      organizationId: _organizationId!,
      recordId: recordId,
      payload: optimisticPayload,
    );
    await _reloadEntityFromCache(entityType);

    if (!_isOnline) {
      await _localStore.enqueueOperation(
        entityType: entityType,
        recordId: recordId,
        organizationId: _organizationId!,
        operation: _operationUpsert,
        payload: optimisticPayload,
      );
      await _refreshQueueCount();
      return;
    }

    try {
      await remoteAction();
    } catch (error, stackTrace) {
      debugPrint('WorkspaceDataController write error: $error\n$stackTrace');
      _errorMessage = error.toString();
      await _localStore.enqueueOperation(
        entityType: entityType,
        recordId: recordId,
        organizationId: _organizationId!,
        operation: _operationUpsert,
        payload: optimisticPayload,
      );
      await _refreshQueueCount();
      notifyListeners();
    }
  }

  Future<void> _applyDelete({
    required String entityType,
    required String recordId,
    required Future<void> Function() remoteAction,
  }) async {
    if (_organizationId == null) return;

    _errorMessage = null;
    await _localStore.removeCachedRecord(entityType: entityType, recordId: recordId);
    await _reloadEntityFromCache(entityType);

    if (!_isOnline) {
      await _localStore.enqueueOperation(
        entityType: entityType,
        recordId: recordId,
        organizationId: _organizationId!,
        operation: _operationDelete,
      );
      await _refreshQueueCount();
      return;
    }

    try {
      await remoteAction();
    } catch (error, stackTrace) {
      debugPrint('WorkspaceDataController delete error: $error\n$stackTrace');
      _errorMessage = error.toString();
      await _localStore.enqueueOperation(
        entityType: entityType,
        recordId: recordId,
        organizationId: _organizationId!,
        operation: _operationDelete,
      );
      await _refreshQueueCount();
      notifyListeners();
    }
  }

  Future<void> _loadCachedState() async {
    if (_organizationId == null) return;

    _sales = (await _localStore.getCachedRecords(entityType: _entitySales, organizationId: _organizationId!))
        .map(SalesEntry.fromMap)
        .toList();
    _expenses = (await _localStore.getCachedRecords(entityType: _entityExpenses, organizationId: _organizationId!))
        .map(ExpenseEntry.fromMap)
        .toList();
    _templates = (await _localStore.getCachedRecords(entityType: _entityTemplates, organizationId: _organizationId!))
        .map(SupplyTemplate.fromMap)
        .toList();
    _dispatchLeaves = (await _localStore.getCachedRecords(entityType: _entityLeaves, organizationId: _organizationId!))
        .map(DispatchLeave.fromMap)
        .toList();
    _contacts = (await _localStore.getCachedRecords(entityType: _entityContacts, organizationId: _organizationId!))
      .map(ContactEntry.fromMap)
      .toList();
    await _refreshQueueCount();
    notifyListeners();
  }

  void _subscribe() {
    _salesSubscription?.cancel();
    _expenseSubscription?.cancel();
    _templateSubscription?.cancel();
    _leaveSubscription?.cancel();
    _contactSubscription?.cancel();
    _hasInitialSales = false;
    _hasInitialExpenses = false;
    _hasInitialTemplates = false;
    _hasInitialLeaves = false;
    _hasInitialContacts = false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _salesSubscription = _salesRepository.watchSales(_organizationId!).listen(
      (sales) async {
        final merged = await _mergeRemoteWithQueued(
          entityType: _entitySales,
          remoteRecords: sales.map((sale) => sale.toDataMap()).toList(),
        );
        _sales = merged.map(SalesEntry.fromMap).toList();
        _hasInitialSales = true;
        _completeInitialLoadIfReady();
      },
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('Sales stream error: $error\n$stackTrace');
        _errorMessage = error.toString();
        _isLoading = false;
        notifyListeners();
      },
    );

    _expenseSubscription = _expenseRepository.watchExpenses(_organizationId!).listen(
      (expenses) async {
        final merged = await _mergeRemoteWithQueued(
          entityType: _entityExpenses,
          remoteRecords: expenses.map((expense) => expense.toDataMap()).toList(),
        );
        _expenses = merged.map(ExpenseEntry.fromMap).toList();
        _hasInitialExpenses = true;
        _completeInitialLoadIfReady();
      },
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('Expense stream error: $error\n$stackTrace');
        _errorMessage = error.toString();
        _isLoading = false;
        notifyListeners();
      },
    );

    _templateSubscription = _templateRepository.watchTemplates(_organizationId!).listen(
      (templates) async {
        final merged = await _mergeRemoteWithQueued(
          entityType: _entityTemplates,
          remoteRecords: templates.map((template) => template.toDataMap()).toList(),
        );
        _templates = merged.map(SupplyTemplate.fromMap).toList();
        _hasInitialTemplates = true;
        _completeInitialLoadIfReady();
      },
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('Template stream error: $error\n$stackTrace');
        _errorMessage = error.toString();
        _isLoading = false;
        notifyListeners();
      },
    );

    _leaveSubscription = _dispatchRepository.watchDispatchLeaves(_organizationId!).listen(
      (leaves) async {
        final merged = await _mergeRemoteWithQueued(
          entityType: _entityLeaves,
          remoteRecords: leaves.map((leave) => leave.toDataMap()).toList(),
        );
        _dispatchLeaves = merged.map(DispatchLeave.fromMap).toList();
        _hasInitialLeaves = true;
        _completeInitialLoadIfReady();
      },
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('Dispatch leaves stream error: $error\n$stackTrace');
        _errorMessage = error.toString();
        _isLoading = false;
        notifyListeners();
      },
    );

    _contactSubscription = _contactRepository.watchContacts(_organizationId!).listen(
      (contacts) async {
        final merged = await _mergeRemoteWithQueued(
          entityType: _entityContacts,
          remoteRecords: contacts.map((contact) => contact.toDataMap()).toList(),
        );
        _contacts = merged.map(ContactEntry.fromMap).toList();
        _hasInitialContacts = true;
        _completeInitialLoadIfReady();
      },
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('Contacts stream error: $error\n$stackTrace');
        _errorMessage = error.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  void _completeInitialLoadIfReady() {
    if (!_hasInitialSales || !_hasInitialExpenses || !_hasInitialTemplates || !_hasInitialLeaves || !_hasInitialContacts) {
      return;
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _updateOnlineState(dynamic result) async {
    _isOnline = _hasNetworkConnection(result);
    notifyListeners();
    if (_isOnline) {
      await _processPendingQueue();
    }
  }

  bool _hasNetworkConnection(dynamic result) {
    if (result is List<ConnectivityResult>) {
      return result.any(_isConnectedResult);
    }
    if (result is ConnectivityResult) {
      return _isConnectedResult(result);
    }
    return false;
  }

  bool _isConnectedResult(ConnectivityResult result) {
    return result == ConnectivityResult.mobile ||
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.ethernet;
  }

  @visibleForTesting
  Future<void> setOnlineForTest(bool isOnline) async {
    _isOnline = isOnline;
    notifyListeners();
    if (_isOnline) {
      await _processPendingQueue();
    }
  }

  Future<List<Map<String, dynamic>>> _mergeRemoteWithQueued({
    required String entityType,
    required List<Map<String, dynamic>> remoteRecords,
  }) async {
    if (_organizationId == null) {
      return remoteRecords;
    }

    final merged = <String, Map<String, dynamic>>{
      for (final record in remoteRecords) record['id'] as String: record,
    };

    final queueItems = await _localStore.getPendingQueueForEntity(
      entityType: entityType,
      organizationId: _organizationId!,
    );

    for (final item in queueItems) {
      final operation = item['operation'] as String;
      final recordId = item['record_id'] as String;
      final payload = item['payload'] as Map<String, dynamic>?;
      if (operation == _operationUpsert && payload != null) {
        merged[recordId] = payload;
      } else if (operation == _operationDelete) {
        merged.remove(recordId);
      }
    }

    final records = _deduplicateEntityRecords(entityType, merged.values.toList());
    await _localStore.replaceCachedRecords(
      entityType: entityType,
      organizationId: _organizationId!,
      records: records,
    );
    await _refreshQueueCount();
    return records;
  }

  Future<void> _reloadEntityFromCache(String entityType) async {
    if (_organizationId == null) return;

    final records = await _localStore.getCachedRecords(entityType: entityType, organizationId: _organizationId!);
    switch (entityType) {
      case _entitySales:
        _sales = records.map(SalesEntry.fromMap).toList();
      case _entityExpenses:
        _expenses = records.map(ExpenseEntry.fromMap).toList();
      case _entityTemplates:
        _templates = records.map(SupplyTemplate.fromMap).toList();
      case _entityLeaves:
        _dispatchLeaves = records.map(DispatchLeave.fromMap).toList();
      case _entityContacts:
        _contacts = records.map(ContactEntry.fromMap).toList();
    }
    notifyListeners();
  }

  Future<void> _processPendingQueue() async {
    if (!_isOnline || _organizationId == null || _userId == null) {
      return;
    }

    final queueItems = await _localStore.getPendingQueue(organizationId: _organizationId);
    for (final item in queueItems) {
      final queueId = item['id'] as int;
      final entityType = item['entity_type'] as String;
      final operation = item['operation'] as String;
      final recordId = item['record_id'] as String;
      final payload = item['payload'] as Map<String, dynamic>?;

      try {
        if (entityType == _entitySales && operation == _operationUpsert && payload != null) {
          await _salesRepository.upsertSale(
            organizationId: _organizationId!,
            userId: _userId!,
            sale: SalesEntry.fromMap(payload),
          );
        }
        if (entityType == _entitySales && operation == _operationDelete) {
          await _salesRepository.deleteSale(recordId);
        }
        if (entityType == _entityExpenses && operation == _operationUpsert && payload != null) {
          await _expenseRepository.upsertExpense(
            organizationId: _organizationId!,
            userId: _userId!,
            expense: ExpenseEntry.fromMap(payload),
          );
        }
        if (entityType == _entityExpenses && operation == _operationDelete) {
          await _expenseRepository.deleteExpense(recordId);
        }
        if (entityType == _entityTemplates && operation == _operationUpsert && payload != null) {
          await _templateRepository.upsertTemplate(
            organizationId: _organizationId!,
            userId: _userId!,
            template: SupplyTemplate.fromMap(payload),
          );
        }
        if (entityType == _entityTemplates && operation == _operationDelete) {
          await _templateRepository.deleteTemplate(recordId);
        }
        if (entityType == _entityLeaves && operation == _operationUpsert && payload != null) {
          await _dispatchRepository.upsertLeave(
            organizationId: _organizationId!,
            userId: _userId!,
            leave: DispatchLeave.fromMap(payload),
          );
        }
        if (entityType == _entityLeaves && operation == _operationDelete) {
          await _dispatchRepository.deleteLeave(recordId);
        }
        if (entityType == _entityContacts && operation == _operationUpsert && payload != null) {
          await _contactRepository.upsertContact(
            organizationId: _organizationId!,
            userId: _userId!,
            contact: ContactEntry.fromMap(payload),
          );
        }
        if (entityType == _entityContacts && operation == _operationDelete) {
          await _contactRepository.deleteContact(recordId);
        }
        await _localStore.removeQueueItem(queueId);
      } catch (error, stackTrace) {
        debugPrint('Queue replay error: $error\n$stackTrace');
        await _localStore.markQueueFailed(queueId, error);
        _errorMessage = error.toString();
      }
    }

    await _refreshQueueCount();
    notifyListeners();
  }

  Future<void> _refreshQueueCount() async {
    if (_organizationId == null) {
      _pendingQueueCount = 0;
      return;
    }

    _pendingQueueCount = (await _localStore.getPendingQueue(organizationId: _organizationId)).length;
  }

  bool _isSameDay(DateTime left, DateTime right) {
    return left.year == right.year && left.month == right.month && left.day == right.day;
  }

  @override
  void dispose() {
    _salesSubscription?.cancel();
    _expenseSubscription?.cancel();
    _templateSubscription?.cancel();
    _leaveSubscription?.cancel();
    _contactSubscription?.cancel();
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}