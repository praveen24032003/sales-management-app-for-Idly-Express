import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../domain/business_types.dart';
import '../../../domain/contact_entry.dart';
import '../../workspace/application/workspace_data_controller.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({
    super.key,
    required this.workspace,
  });

  final WorkspaceDataController workspace;

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shopContacts = widget.workspace.contacts
        .where((contact) => contact.contactType == ContactType.shop)
        .toList()
      ..sort((left, right) => left.name.toLowerCase().compareTo(right.name.toLowerCase()));
    final customerContacts = widget.workspace.contacts
        .where((contact) => contact.contactType == ContactType.customer)
        .toList()
      ..sort((left, right) => left.name.toLowerCase().compareTo(right.name.toLowerCase()));

    return AnimatedBuilder(
      animation: widget.workspace,
      builder: (context, _) {
        final shopContacts = widget.workspace.contacts
            .where((contact) => contact.contactType == ContactType.shop)
            .toList()
          ..sort((left, right) => left.name.toLowerCase().compareTo(right.name.toLowerCase()));
        final customerContacts = widget.workspace.contacts
            .where((contact) => contact.contactType == ContactType.customer)
            .toList()
          ..sort((left, right) => left.name.toLowerCase().compareTo(right.name.toLowerCase()));

        return Scaffold(
          appBar: AppBar(
            title: const Text('Contacts'),
            bottom: TabBar(
              controller: _tabController,
              tabs: [
                Tab(text: 'Shops (${shopContacts.length})'),
                Tab(text: 'Customers (${customerContacts.length})'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _ContactList(
                title: 'No shop contacts yet',
                message: 'Save shop numbers here so they stay scoped to this organization.',
                contacts: shopContacts,
                onEdit: _editContact,
              ),
              _ContactList(
                title: 'No customer contacts yet',
                message: 'Save external customer numbers here for follow-up and repeat orders.',
                contacts: customerContacts,
                onEdit: _editContact,
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _addContact,
            icon: const Icon(Icons.add),
            label: const Text('Add contact'),
          ),
        );
      },
    );
  }

  Future<void> _addContact() async {
    final type = _tabController.index == 0 ? ContactType.shop : ContactType.customer;
    final result = await showModalBottomSheet<_ContactEditorResult>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _ContactEditorSheet(
        key: ValueKey('contact-editor-${type.dbValue}-new'),
        contactType: type,
      ),
    );

    if (result == null || result.contact == null) {
      return;
    }

    final created = result.contact!;

    await widget.workspace.saveContact(created);
    if (!mounted) {
      return;
    }

    if (widget.workspace.errorMessage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${created.contactType.displayName} contact saved')),
      );
    }
  }

  Future<void> _editContact(ContactEntry contact) async {
    final result = await showModalBottomSheet<_ContactEditorResult>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _ContactEditorSheet(
        key: ValueKey('contact-editor-${contact.id}'),
        existingContact: contact,
      ),
    );

    if (result == null) {
      return;
    }

    if (result.deleteRequested) {
      await _deleteContact(contact);
      return;
    }

    final updated = result.contact;
    if (updated == null) {
      return;
    }

    await widget.workspace.saveContact(updated);
    if (!mounted) {
      return;
    }

    if (widget.workspace.errorMessage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${updated.contactType.displayName} contact updated')),
      );
    }
  }

  Future<void> _deleteContact(ContactEntry contact) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete contact?'),
        content: Text('Remove ${contact.name} from this organization contact list?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete')),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    await widget.workspace.deleteContact(contact.id);
    if (!mounted) {
      return;
    }

    if (widget.workspace.errorMessage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${contact.name} removed')),
      );
    }
  }
}

class _ContactList extends StatelessWidget {
  const _ContactList({
    required this.title,
    required this.message,
    required this.contacts,
    required this.onEdit,
  });

  final String title;
  final String message;
  final List<ContactEntry> contacts;
  final Future<void> Function(ContactEntry contact) onEdit;

  @override
  Widget build(BuildContext context) {
    if (contacts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.people_outline, size: 56),
              const SizedBox(height: 16),
              Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: contacts.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final contact = contacts[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(child: Text(contact.name.isEmpty ? '?' : contact.name[0].toUpperCase())),
            title: Text(contact.name),
            subtitle: Text(contact.mobile?.isNotEmpty == true ? contact.mobile! : 'No mobile number'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: () => onEdit(contact),
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Edit contact',
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: contact.mobile?.isNotEmpty == true ? () => _call(contact.mobile!) : null,
                  icon: const Icon(Icons.call_outlined),
                  tooltip: 'Call contact',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _call(String mobile) async {
    final uri = Uri(scheme: 'tel', path: mobile);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

class _ContactEditorResult {
  const _ContactEditorResult({this.contact, this.deleteRequested = false});

  final ContactEntry? contact;
  final bool deleteRequested;
}

class _ContactEditorSheet extends StatefulWidget {
  const _ContactEditorSheet({
    super.key,
    this.contactType,
    this.existingContact,
  });

  final ContactType? contactType;
  final ContactEntry? existingContact;

  @override
  State<_ContactEditorSheet> createState() => _ContactEditorSheetState();
}

class _ContactEditorSheetState extends State<_ContactEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _mobileController;
  late ContactType _contactType;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _mobileController = TextEditingController();
    _hydrateFromContact();
  }

  @override
  void didUpdateWidget(covariant _ContactEditorSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.existingContact?.id != widget.existingContact?.id ||
        oldWidget.contactType != widget.contactType) {
      _hydrateFromContact();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  void _hydrateFromContact() {
    _contactType = widget.existingContact?.contactType ?? widget.contactType ?? ContactType.shop;
    _nameController.text = widget.existingContact?.name ?? '';
    _mobileController.text = widget.existingContact?.mobile ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.existingContact == null ? 'Add contact' : 'Edit contact',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<ContactType>(
                initialValue: _contactType,
                decoration: const InputDecoration(labelText: 'Contact type'),
                items: ContactType.values
                    .map((type) => DropdownMenuItem<ContactType>(value: type, child: Text(type.displayName)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _contactType = value);
                  }
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: _contactType == ContactType.shop ? 'Shop name' : 'Customer name'),
                validator: (value) => value == null || value.trim().isEmpty ? 'Enter a name.' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _mobileController,
                decoration: const InputDecoration(labelText: 'Mobile number'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 20),
              if (widget.existingContact != null) ...[
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pop(const _ContactEditorResult(deleteRequested: true)),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete contact'),
                ),
                const SizedBox(height: 12),
              ],
              FilledButton(
                onPressed: () {
                  if (!_formKey.currentState!.validate()) {
                    return;
                  }

                  Navigator.of(context).pop(
                    _ContactEditorResult(
                      contact: ContactEntry(
                        id: widget.existingContact?.id ?? '',
                        organizationId: widget.existingContact?.organizationId ?? '',
                        contactType: _contactType,
                        name: _nameController.text.trim(),
                        mobile: _mobileController.text.trim().isEmpty ? null : _mobileController.text.trim(),
                        createdAt: widget.existingContact?.createdAt,
                      ),
                    ),
                  );
                },
                child: Text(widget.existingContact == null ? 'Save contact' : 'Save changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}