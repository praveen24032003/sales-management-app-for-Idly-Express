/// Expense categories
enum ExpenseCategory {
  petrol,
  food,
  maintenance,
  other;

  String get displayName {
    switch (this) {
      case ExpenseCategory.petrol:
        return 'Petrol';
      case ExpenseCategory.food:
        return 'Food';
      case ExpenseCategory.maintenance:
        return 'Maintenance';
      case ExpenseCategory.other:
        return 'Other';
    }
  }
}

/// Expense Model
class Expense {
  final int? id;
  final DateTime date;
  final ExpenseCategory category;
  final double amount;
  final String? notes;
  final String? firestoreId;
  final int lastModified;
  final bool isSynced;

  Expense({
    this.id,
    required this.date,
    required this.category,
    required this.amount,
    this.notes,
    this.firestoreId,
    this.lastModified = 0,
    this.isSynced = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'category': category.index,
      'amount': amount,
      'notes': notes,
      'firestore_id': firestoreId,
      'last_modified': lastModified,
      'is_synced': isSynced ? 1 : 0,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as int?,
      date: DateTime.parse(map['date'] as String),
      category: ExpenseCategory.values[map['category'] as int],
      amount: (map['amount'] as num).toDouble(),
      notes: map['notes'] as String?,
      firestoreId: map['firestore_id'] as String?,
      lastModified: map['last_modified'] as int? ?? 0,
      isSynced: (map['is_synced'] as int? ?? 0) == 1,
    );
  }
}
