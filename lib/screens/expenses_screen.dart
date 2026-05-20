import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/constants.dart';
import '../models/expense_model.dart';
import '../providers/expense_provider.dart';
import '../widgets/custom_dropdown.dart';
import '../widgets/custom_textfield.dart';
import '../core/theme.dart';
import '../widgets/soft_card.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExpenseProvider>().loadExpenses();
    });
  }

  void _showAddExpenseDialog() {
    showDialog(
      context: context,
      builder: (context) => const AddExpenseDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'en_IN',
      symbol: currencySymbol,
      decimalDigits: 2,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
      ),
      body: Consumer<ExpenseProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.monthExpenses.isEmpty) {
             return Center(
               child: Column(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                   const Icon(Icons.money_off, size: 64, color: Colors.grey),
                   const SizedBox(height: 16),
                   const Text('No expenses this month'),
                    const SizedBox(height: 16),
                   ElevatedButton.icon(
                     onPressed: _showAddExpenseDialog,
                     icon: const Icon(Icons.add),
                     label: const Text('Add Expense'),
                   ),
                 ],
               ),
             );
          }

          return Column(
            children: [
               // Month Summary
              Container(
                padding: const EdgeInsets.all(16),
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('This Month Total', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      currencyFormat.format(provider.monthTotal),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // List
              Expanded(
                child: ListView.separated(
                  itemCount: provider.monthExpenses.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final expense = provider.monthExpenses[index];
                        return SoftCard(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: context.lossColor.withValues(alpha: 0.1),
                              child: Icon(_getCategoryIcon(expense.category), color: context.lossColor),
                            ),
                            title: Text(expense.category.displayName),
                            subtitle: Text(
                              '${DateFormat('dd MMM').format(expense.date)} • ${expense.notes ?? ''}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                 Text(
                                  currencyFormat.format(expense.amount),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.grey, size: 20),
                                  onPressed: () => _confirmDelete(context, expense.id!),
                                ),
                              ],
                            ),
                          ),
                        );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddExpenseDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  IconData _getCategoryIcon(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.petrol: return Icons.local_gas_station;
      case ExpenseCategory.food: return Icons.restaurant;
      case ExpenseCategory.maintenance: return Icons.build;
      case ExpenseCategory.other: return Icons.receipt;
    }
  }

  void _confirmDelete(BuildContext context, int id) {
     showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Expense'),
        content: const Text('Are you sure?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              context.read<ExpenseProvider>().deleteExpense(id);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class AddExpenseDialog extends StatefulWidget {
  const AddExpenseDialog({super.key});

  @override
  State<AddExpenseDialog> createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends State<AddExpenseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  ExpenseCategory _category = ExpenseCategory.petrol;
  DateTime _date = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Expense'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Date
              InkWell(
                onTap: () async {
                   final picked = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setState(() => _date = picked);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    border: OutlineInputBorder(),
                  ),
                  child: Text(DateFormat('dd/MM/yyyy').format(_date)),
                ),
              ),
              const SizedBox(height: 16),

              // Category
              CustomDropdown<ExpenseCategory>(
                label: 'Category',
                value: _category,
                items: ExpenseCategory.values,
                itemLabel: (c) => c.displayName,
                onChanged: (val) => setState(() => _category = val!),
              ),
              const SizedBox(height: 16),

              // Amount
              NumericTextField(
                label: 'Amount',
                controller: _amountController,
                allowDecimal: true,
                validator: (val) => (val == null || val.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // Notes
              CustomTextField(
                label: 'Notes',
                controller: _notesController,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    
    final expense = Expense(
      date: _date,
      category: _category,
      amount: double.parse(_amountController.text),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text,
    );

    context.read<ExpenseProvider>().addExpense(expense);
    Navigator.pop(context);
  }
}
