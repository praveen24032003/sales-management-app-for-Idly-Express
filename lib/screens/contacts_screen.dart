import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../providers/sales_provider.dart';
import '../services/database_service.dart';

/// Contact directory: Shops tab + External Customers tab.
/// Shops are stored with their mobile numbers.
/// External customers are derived from sales_entries (external orders).
class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  int _reloadKey = 0;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _addContact(String contactType) async {
    final isShop = contactType == contactTypeShop;
    final nameController = TextEditingController();
    final mobileController = TextEditingController();

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isShop ? 'Add shop contact' : 'Add customer contact',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: isShop ? 'Shop name' : 'Customer name'),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: mobileController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Mobile number'),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    final success = await context.read<SalesProvider>().addManualContact(
                          contactType: contactType,
                          name: nameController.text.trim(),
                          mobile: mobileController.text.trim(),
                        );
                    if (!context.mounted) return;
                    Navigator.pop(context, success);
                  },
                  child: const Text('Save contact'),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (saved == true && mounted) {
      setState(() => _reloadKey++);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isShop ? 'Shop contact added' : 'Customer contact added'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.bgDark : AppColors.bgLight;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        title: const Text('Contacts'),
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: const [
            Tab(text: 'Shops'),
            Tab(text: 'Customers'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _ShopsTab(key: ValueKey('shops_$_reloadKey')),
          _CustomersTab(key: ValueKey('customers_$_reloadKey')),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addContact(_tabCtrl.index == 0 ? contactTypeShop : contactTypeCustomer),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _ShopsTab extends StatefulWidget {
  const _ShopsTab({super.key});

  @override
  State<_ShopsTab> createState() => _ShopsTabState();
}

class _ShopsTabState extends State<_ShopsTab> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = DatabaseService.instance.getAllShopsWithMobile();
  }

  Future<void> _call(String mobile) async {
    final uri = Uri(scheme: 'tel', path: mobile);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  void _refresh() {
    setState(() {
      _future = DatabaseService.instance.getAllShopsWithMobile();
    });
  }

  Future<void> _editShopContact(String currentName, String? currentMobile) async {
    final nameController = TextEditingController(text: currentName);
    final mobileController = TextEditingController(text: currentMobile ?? '');

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Edit shop contact', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Shop name'),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: mobileController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Mobile number'),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    final success = await context.read<SalesProvider>().updateShopContact(
                          oldName: currentName,
                          newName: nameController.text.trim(),
                          mobile: mobileController.text.trim(),
                        );
                    if (!context.mounted) return;
                    Navigator.pop(context, success);
                  },
                  child: const Text('Save changes'),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (saved == true && mounted) {
      _refresh();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Shop contact updated'), behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final surface = isDark ? AppColors.cardDark : AppColors.cardLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final shops = snap.data!;
        if (shops.isEmpty) {
          return Center(child: Text('No shops yet', style: TextStyle(color: textSecondary)));
        }
        return RefreshIndicator(
          onRefresh: () async => _refresh(),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: shops.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final shop = shops[i];
              final name = shop['name'] as String? ?? '';
              final mobile = shop['mobile'] as String?;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: border),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: TextStyle(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                          if (mobile != null && mobile.isNotEmpty)
                            Text(mobile, style: TextStyle(color: textSecondary, fontSize: 12))
                          else
                            Text('No number', style: TextStyle(color: textSecondary.withValues(alpha: 0.5), fontSize: 12, fontStyle: FontStyle.italic)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.edit_outlined, color: Theme.of(context).colorScheme.primary, size: 20),
                      onPressed: () => _editShopContact(name, mobile),
                    ),
                    if (mobile != null && mobile.isNotEmpty)
                      IconButton(
                        icon: Icon(Icons.phone, color: Theme.of(context).colorScheme.primary, size: 20),
                        onPressed: () => _call(mobile),
                      ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _CustomersTab extends StatefulWidget {
  const _CustomersTab({super.key});

  @override
  State<_CustomersTab> createState() => _CustomersTabState();
}

class _CustomersTabState extends State<_CustomersTab> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = DatabaseService.instance.getRecentExternalCustomers();
  }

  Future<void> _call(String mobile) async {
    final uri = Uri(scheme: 'tel', path: mobile);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  void _refresh() {
    setState(() {
      _future = DatabaseService.instance.getRecentExternalCustomers();
    });
  }

  Future<void> _editCustomerContact(String currentName, String currentMobile) async {
    final nameController = TextEditingController(text: currentName);
    final mobileController = TextEditingController(text: currentMobile);

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Edit customer contact', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Customer name'),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: mobileController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Mobile number'),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    final success = await context.read<SalesProvider>().updateExternalCustomerContact(
                          oldName: currentName,
                          newName: nameController.text.trim(),
                          mobile: mobileController.text.trim(),
                        );
                    if (!context.mounted) return;
                    Navigator.pop(context, success);
                  },
                  child: const Text('Save changes'),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (saved == true && mounted) {
      _refresh();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Customer contact updated'), behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final surface = isDark ? AppColors.cardDark : AppColors.cardLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final customers = snap.data!;
        if (customers.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.people_outline, size: 48, color: textSecondary.withValues(alpha: 0.4)),
                const SizedBox(height: 12),
                Text('No external customer contacts yet', style: TextStyle(color: textSecondary, fontSize: 14)),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async => _refresh(),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: customers.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final c = customers[i];
              final name = c['name']?.toString() ?? '';
              final mobile = c['mobile']?.toString() ?? '';
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: border),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: const TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: TextStyle(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                          Text(mobile.isEmpty ? 'No number' : mobile, style: TextStyle(color: textSecondary, fontSize: 12)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: Color(0xFFF59E0B), size: 20),
                      onPressed: () => _editCustomerContact(name, mobile),
                    ),
                    if (mobile.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.phone, color: Color(0xFFF59E0B), size: 20),
                        onPressed: () => _call(mobile),
                      ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
