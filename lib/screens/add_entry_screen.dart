import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../models/sales_entry_model.dart';
import '../providers/sales_provider.dart';
import '../widgets/custom_dropdown.dart';
import '../widgets/custom_textfield.dart';

/// Add/Edit Sales Entry Screen
class AddEntryScreen extends StatefulWidget {
  final SalesEntry? editEntry;

  const AddEntryScreen({super.key, this.editEntry});

  @override
  State<AddEntryScreen> createState() => _AddEntryScreenState();
}

class _AddEntryScreenState extends State<AddEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Form controllers
  late DateTime _selectedDate;
  late TextEditingController _shopNameController;
  late ProductType _selectedProduct;
  late SaleType _selectedSaleType;
  late double _selectedRate;
  late TextEditingController _rateController;
  late TextEditingController _quantityController;
  late TextEditingController _costController;
  late TextEditingController _notesController;
  
  // Payment
  late PaymentStatus _paymentStatus;
  late TextEditingController _paidAmountController;

  // Shop suggestions
  List<String> _shopSuggestions = [];
  bool _showSuggestions = false;

  // Computed values
  double _totalSalesAmount = 0;
  double _totalCost = 0;
  double _profit = 0;

  bool get isEditing => widget.editEntry != null;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    final entry = widget.editEntry;
    
    _selectedDate = entry?.date ?? DateTime.now();
    _shopNameController = TextEditingController(text: entry?.shopName ?? '');
    _selectedProduct = entry?.productType ?? ProductType.idly;
    _selectedSaleType = entry?.saleType ?? SaleType.wholesale;
    
    // Set rate based on sale type for new entries
    if (entry != null) {
      _selectedRate = entry.ratePerUnit;
    } else {
      _selectedRate = _selectedSaleType == SaleType.wholesale
          ? defaultWholesaleRate
          : defaultRetailRate;
    }
    
    _rateController = TextEditingController(
      text: entry != null ? entry.ratePerUnit.toString() : '',
    );
    _quantityController = TextEditingController(
      text: entry != null ? entry.quantity.toString() : '',
    );
    _costController = TextEditingController(
      text: entry != null ? entry.costPerUnit.toString() : '',
    );
    _notesController = TextEditingController(text: entry?.notes ?? '');
    
    _paymentStatus = entry?.paymentStatus ?? PaymentStatus.paid;
    _paidAmountController = TextEditingController(
      text: entry != null 
          ? entry.paidAmount.toString() 
          : '', // Initialized to empty, will be auto-filled logic
    );

    // Calculate initial values if editing
    if (entry != null) {
      _calculateTotals();
    }
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _rateController.dispose();
    _quantityController.dispose();
    _costController.dispose();
    _notesController.dispose();
    _paidAmountController.dispose();
    super.dispose();
  }

  /// Calculate totals based on current inputs
  void _calculateTotals() {
    final quantity = int.tryParse(_quantityController.text) ?? 0;
    final costPerUnit = double.tryParse(_costController.text) ?? 0;
    
    double rate;
    if (_selectedProduct == ProductType.idly) {
      rate = _selectedRate;
    } else {
      rate = double.tryParse(_rateController.text) ?? 0;
    }

    setState(() {
      _totalSalesAmount = quantity * rate;
      _totalCost = quantity * costPerUnit;
      _profit = _totalSalesAmount - _totalCost;
    });
  }

  /// Fetch shop suggestions
  Future<void> _fetchShopSuggestions(String query) async {
    final suggestions = await context.read<SalesProvider>().getShopSuggestions(query);
    setState(() {
      _shopSuggestions = suggestions;
      _showSuggestions = suggestions.isNotEmpty && query.isNotEmpty;
    });
  }

  /// Handle sale type change - update default rate for Idly
  void _onSaleTypeChanged(SaleType? type) {
    if (type == null) return;
    setState(() {
      _selectedSaleType = type;
      // Update default rate for Idly product
      if (_selectedProduct == ProductType.idly) {
        _selectedRate = type == SaleType.wholesale
            ? defaultWholesaleRate
            : defaultRetailRate;
      }
    });
    _calculateTotals();
  }

  /// Handle product type change
  void _onProductChanged(ProductType? product) {
    if (product == null) return;
    setState(() {
      _selectedProduct = product;
      // Reset rate to default when switching to Idly
      if (product == ProductType.idly) {
        _selectedRate = _selectedSaleType == SaleType.wholesale
            ? defaultWholesaleRate
            : defaultRetailRate;
        _rateController.clear();
      }
    });
    _calculateTotals();
  }

  /// Save entry
  Future<void> _saveEntry() async {
    if (!_formKey.currentState!.validate()) return;

    final quantity = int.parse(_quantityController.text);
    final costPerUnit = double.parse(_costController.text);
    
    double rate;
    if (_selectedProduct == ProductType.idly) {
      rate = _selectedRate;
    } else {
      rate = double.parse(_rateController.text);
    }

    final entry = SalesEntry(
      id: widget.editEntry?.id,
      date: _selectedDate,
      shopName: _shopNameController.text.trim(),
      productType: _selectedProduct,
      saleType: _selectedSaleType,
      ratePerUnit: rate,
      quantity: quantity,
      costPerUnit: costPerUnit,
      paymentStatus: _paymentStatus,
      paidAmount: _paymentStatus == PaymentStatus.paid 
          ? rate * quantity // Fully paid
          : double.tryParse(_paidAmountController.text) ?? 0.0,
      notes: _notesController.text.trim().isEmpty 
          ? null 
          : _notesController.text.trim(),
    );

    final provider = context.read<SalesProvider>();
    bool success;
    
    if (isEditing) {
      success = await provider.updateEntry(entry);
    } else {
      success = await provider.addEntry(entry);
    }

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing ? 'Entry updated!' : 'Entry saved!'),
          backgroundColor: context.profitColor,
        ),
      );
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Failed to save'),
          backgroundColor: context.lossColor,
        ),
      );
    }
  }

  /// Reset form
  void _resetForm() {
    _formKey.currentState?.reset();
    setState(() {
      _selectedDate = DateTime.now();
      _shopNameController.clear();
      _selectedProduct = ProductType.idly;
      _selectedSaleType = SaleType.wholesale;
      _selectedRate = defaultWholesaleRate;
      _rateController.clear();
      _quantityController.clear();
      _costController.clear();
      _notesController.clear();
      _paymentStatus = PaymentStatus.paid;
      _paidAmountController.clear();
      _totalSalesAmount = 0;
      _totalCost = 0;
      _profit = 0;
    });
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
        title: Text(isEditing ? 'Edit Entry' : 'Add Sale Entry'),
        actions: [
          if (!isEditing)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _resetForm,
              tooltip: 'Reset',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Date Picker
              _buildDatePicker(),
              const SizedBox(height: 16),

              // Shop Name with Autocomplete
              _buildShopNameField(),
              const SizedBox(height: 16),

              // Product Type Dropdown
              CustomDropdown<ProductType>(
                label: 'Product',
                value: _selectedProduct,
                items: ProductType.values,
                itemLabel: (p) => p.displayName,
                onChanged: _onProductChanged,
              ),
              const SizedBox(height: 16),

              // Sale Type Dropdown
              CustomDropdown<SaleType>(
                label: 'Sale Type',
                value: _selectedSaleType,
                items: SaleType.values,
                itemLabel: (s) => s.displayName,
                onChanged: _onSaleTypeChanged,
              ),
              const SizedBox(height: 16),

              // Rate Input - Dropdown for Idly, Text for others
              if (_selectedProduct == ProductType.idly)
                RateDropdown(
                  value: _selectedRate,
                  options: idlyRateOptions,
                  onChanged: (rate) {
                    if (rate != null) {
                      setState(() => _selectedRate = rate);
                      _calculateTotals();
                    }
                  },
                )
              else
                NumericTextField(
                  label: 'Rate per Unit ($currencySymbol)',
                  controller: _rateController,
                  allowDecimal: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Rate is required';
                    }
                    final rate = double.tryParse(value);
                    if (rate == null || rate <= 0) {
                      return 'Enter a valid rate > 0';
                    }
                    return null;
                  },
                  onChanged: (_) => _calculateTotals(),
                ),
              const SizedBox(height: 16),

              // Quantity
              NumericTextField(
                label: 'Quantity',
                controller: _quantityController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Quantity is required';
                  }
                  final qty = int.tryParse(value);
                  if (qty == null || qty <= 0) {
                    return 'Enter a valid quantity > 0';
                  }
                  return null;
                },
                onChanged: (_) => _calculateTotals(),
              ),
              const SizedBox(height: 16),

              // Cost per Unit
              NumericTextField(
                label: 'Cost per Unit ($currencySymbol)',
                controller: _costController,
                allowDecimal: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Cost is required';
                  }
                  final cost = double.tryParse(value);
                  if (cost == null || cost <= 0) {
                    return 'Enter a valid cost > 0';
                  }
                  return null;
                },
                onChanged: (_) => _calculateTotals(),
              ),
              const SizedBox(height: 24),
              
              // Payment Status
              Text(
                'Payment Status',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<PaymentStatus>(
                      title: const Text('Paid'),
                      value: PaymentStatus.paid,
                      groupValue: _paymentStatus,
                      onChanged: (value) {
                         setState(() {
                           _paymentStatus = value!;
                           // If switching to paid, auto-fill full amount logically in save, 
                           // but clear controller to avoid confusion or set to total
                           _paidAmountController.clear(); 
                         });
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<PaymentStatus>(
                      title: const Text('Pending'),
                      value: PaymentStatus.pending,
                      groupValue: _paymentStatus,
                      onChanged: (value) {
                         setState(() => _paymentStatus = value!);
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
              
              // Paid Amount Input (only if Pending)
              if (_paymentStatus == PaymentStatus.pending)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: NumericTextField(
                    label: 'Amount Paid (Partial)',
                    controller: _paidAmountController,
                    allowDecimal: true,
                    hint: 'Enter 0 logic for credit',
                  ),
                ),

              const SizedBox(height: 24),

              // Calculated Fields
              Card(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildCalculatedRow(
                        'Total Sales Amount',
                        currencyFormat.format(_totalSalesAmount),
                      ),
                      const Divider(),
                      _buildCalculatedRow(
                        'Total Cost',
                        currencyFormat.format(_totalCost),
                      ),
                      const Divider(),
                      _buildCalculatedRow(
                        'Profit',
                        currencyFormat.format(_profit),
                        valueColor: _profit >= 0
                            ? context.profitColor
                            : context.lossColor,
                        isBold: true,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Notes
              CustomTextField(
                label: 'Notes (Optional)',
                controller: _notesController,
                maxLines: 2,
                hint: 'Any additional notes...',
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _resetForm,
                      child: const Text('Reset'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _saveEntry,
                      child: Text(isEditing ? 'Update Entry' : 'Save Entry'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
            );
            if (picked != null) {
              setState(() => _selectedDate = picked);
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Theme.of(context).inputDecorationTheme.fillColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, size: 20),
                const SizedBox(width: 12),
                Text(
                  DateFormat('dd/MM/yyyy').format(_selectedDate),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShopNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Shop Name',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        Autocomplete<String>(
          initialValue: TextEditingValue(text: _shopNameController.text),
          optionsBuilder: (textEditingValue) async {
            if (textEditingValue.text.isEmpty) {
              // Show recent shops
              return await context.read<SalesProvider>().getShopSuggestions('');
            }
            return await context
                .read<SalesProvider>()
                .getShopSuggestions(textEditingValue.text);
          },
          onSelected: (selection) {
            _shopNameController.text = selection;
          },
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            // Sync with our controller
            controller.text = _shopNameController.text;
            controller.addListener(() {
              _shopNameController.text = controller.text;
            });
            
            return TextFormField(
              controller: controller,
              focusNode: focusNode,
              decoration: const InputDecoration(
                hintText: 'Enter shop name',
                prefixIcon: Icon(Icons.store),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Shop name is required';
                }
                return null;
              },
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(8),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final option = options.elementAt(index);
                      return ListTile(
                        leading: const Icon(Icons.history),
                        title: Text(option),
                        onTap: () => onSelected(option),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCalculatedRow(String label, String value,
      {Color? valueColor, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isBold ? 18 : 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
