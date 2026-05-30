import 'business_types.dart';

class ExpenseEntry {
  const ExpenseEntry({
    required this.id,
    required this.organizationId,
    required this.date,
    required this.category,
    required this.amount,
    this.notes,
  });

  final String id;
  final String organizationId;
  final DateTime date;
  final ExpenseCategory category;
  final double amount;
  final String? notes;

  ExpenseEntry copyWith({
    String? id,
    String? organizationId,
    DateTime? date,
    ExpenseCategory? category,
    double? amount,
    String? notes,
  }) {
    return ExpenseEntry(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      date: date ?? this.date,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      notes: notes ?? this.notes,
    );
  }

  factory ExpenseEntry.fromMap(Map<String, dynamic> map) {
    return ExpenseEntry(
      id: map['id'] as String,
      organizationId: map['organization_id'] as String,
      date: DateTime.parse(map['expense_date'] as String),
      category: ExpenseCategory.fromDatabase(map['category'] as String? ?? 'other'),
      amount: (map['amount'] as num).toDouble(),
      notes: map['notes'] as String?,
    );
  }

  Map<String, dynamic> toDataMap() {
    return {
      'id': id,
      'organization_id': organizationId,
      'expense_date': date.toIso8601String().split('T').first,
      'category': category.dbValue,
      'amount': amount,
      'notes': notes,
    };
  }

  Map<String, dynamic> toInsertMap({
    required String organizationId,
    required String userId,
  }) {
    return {
      'id': id,
      'organization_id': organizationId,
      'created_by': userId,
      'updated_by': userId,
      ...toDataMap()..remove('id')..remove('organization_id'),
    };
  }
}