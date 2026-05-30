import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app_shell/application/app_session_controller.dart';

class OrganizationGateScreen extends StatefulWidget {
  const OrganizationGateScreen({super.key});

  @override
  State<OrganizationGateScreen> createState() => _OrganizationGateScreenState();
}

class _OrganizationGateScreenState extends State<OrganizationGateScreen> {
  final _createController = TextEditingController();
  final _inviteController = TextEditingController();
  String? _createFieldError;
  String? _inviteFieldError;

  @override
  void dispose() {
    _createController.dispose();
    _inviteController.dispose();
    super.dispose();
  }

  void _attemptCreate(AppSessionController session) {
    final name = _createController.text.trim();
    if (name.isEmpty) {
      setState(() => _createFieldError = 'Enter your organization name.');
      return;
    }
    setState(() => _createFieldError = null);
    session.createOrganization(name);
  }

  void _attemptJoin(AppSessionController session) {
    final code = _inviteController.text.trim();
    if (code.isEmpty) {
      setState(() => _inviteFieldError = 'Enter the invite code from your owner.');
      return;
    }
    if (code.length < 6) {
      setState(() => _inviteFieldError = 'Invite codes are at least 6 characters.');
      return;
    }
    setState(() => _inviteFieldError = null);
    session.joinOrganization(code);
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AppSessionController>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasSetupError = (session.errorMessage ?? '').toLowerCase().contains('organization setup is incomplete');

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFF8FCFF),
              const Color(0xFFFDFEFF),
              colorScheme.primaryContainer.withValues(alpha: 0.38),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: -40,
                left: -50,
                child: _GlowOrb(color: const Color(0xFFE4F5FC), size: 200),
              ),
              Positioned(
                bottom: -60,
                right: -10,
                child: _GlowOrb(color: colorScheme.primary.withValues(alpha: 0.14), size: 230),
              ),
              Positioned(
                top: 20,
                left: 22,
                right: 22,
                child: IgnorePointer(
                  child: Text(
                    'WORKSPACE',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFFE4F1F8),
                      letterSpacing: -3,
                    ),
                  ),
                ),
              ),
              CustomScrollView(
                slivers: [
                  SliverAppBar(
                    pinned: true,
                    backgroundColor: const Color(0xFFFDFEFF),
                    foregroundColor: const Color(0xFF20313C),
                    surfaceTintColor: Colors.transparent,
                    elevation: 0,
                    scrolledUnderElevation: 0,
                    shadowColor: Colors.transparent,
                    bottom: PreferredSize(
                      preferredSize: const Size.fromHeight(1),
                      child: Container(
                        height: 1,
                        color: const Color(0xFFD8E9F4),
                      ),
                    ),
                    title: const Text('Choose organization'),
                    actions: [
                      IconButton(
                        onPressed: session.isLoading ? null : session.refreshOrganizations,
                        icon: const Icon(Icons.refresh),
                        tooltip: 'Refresh organizations',
                      ),
                      IconButton(
                        onPressed: session.isLoading ? null : session.signOut,
                        icon: const Icon(Icons.logout),
                        tooltip: 'Sign out',
                      ),
                    ],
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: const Color(0xFFD6EAF4)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 60,
                                width: 60,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE9F8FD),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Icon(Icons.apartment_rounded, color: colorScheme.primary),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Set up or choose your workspace',
                                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Pick one clear action: create your own organization, join with an invite code, or reopen an existing branch you already belong to.',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: const Color(0xFF5A7382),
                                        height: 1.45,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _StepBadge(number: '1', label: 'Review memberships'),
                            _StepBadge(number: '2', label: 'Create or join'),
                            _StepBadge(number: '3', label: 'Continue working'),
                          ],
                        ),
                        const SizedBox(height: 20),
                        if (session.organizations.isNotEmpty) ...[
                          Text('Your organizations', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                          const SizedBox(height: 12),
                          ...session.organizations.map(
                            (organization) => Card(
                              child: InkWell(
                                borderRadius: BorderRadius.circular(30),
                                onTap: session.isLoading ? null : () => session.selectOrganization(organization.id),
                                child: Padding(
                                  padding: const EdgeInsets.all(18),
                                  child: Row(
                                    children: [
                                      Container(
                                        height: 50,
                                        width: 50,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE9F8FD),
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Icon(Icons.storefront_rounded, color: colorScheme.primary),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(organization.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                                            const SizedBox(height: 6),
                                            Wrap(
                                              spacing: 8,
                                              runSpacing: 8,
                                              children: [
                                                _MetaChip(label: organization.role.label),
                                                _MetaChip(label: 'Invite ${organization.inviteCode}'),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(Icons.chevron_right),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ] else ...[
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(26),
                              border: Border.all(color: const Color(0xFFD8E9F4)),
                            ),
                            child: Text(
                              'No organizations are linked yet. Create your first workspace below, or refresh if another device already added this account to a team.',
                              style: theme.textTheme.bodyMedium?.copyWith(color: const Color(0xFF5A7382), height: 1.45),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const _CardHeader(number: '1', title: 'Create organization'),
                                const SizedBox(height: 8),
                                Text(
                                  'Start a fresh branch workspace for your team. After creation, the app selects it and continues directly into the main workspace.',
                                  style: theme.textTheme.bodyMedium?.copyWith(color: const Color(0xFF5A7382), height: 1.45),
                                ),
                                const SizedBox(height: 14),
                                TextField(
                                  controller: _createController,
                                  textCapitalization: TextCapitalization.words,
                                  textInputAction: TextInputAction.done,
                                  onChanged: (_) {
                                    if (_createFieldError != null) {
                                      setState(() => _createFieldError = null);
                                    }
                                  },
                                  onSubmitted: (_) {
                                    if (!session.isLoading) {
                                      _attemptCreate(session);
                                    }
                                  },
                                  decoration: InputDecoration(
                                    labelText: 'Organization name',
                                    hintText: 'Idly Express - Main Branch',
                                    errorText: _createFieldError,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                FilledButton(
                                  onPressed: session.isLoading ? null : () => _attemptCreate(session),
                                  child: const Text('Create and continue'),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const _CardHeader(number: '2', title: 'Join with invite code'),
                                const SizedBox(height: 8),
                                Text(
                                  'Already have a workspace? Use the invite code from the organization owner.',
                                  style: theme.textTheme.bodyMedium?.copyWith(color: const Color(0xFF5A7382), height: 1.45),
                                ),
                                const SizedBox(height: 14),
                                TextField(
                                  controller: _inviteController,
                                  textCapitalization: TextCapitalization.characters,
                                  textInputAction: TextInputAction.done,
                                  onChanged: (_) {
                                    if (_inviteFieldError != null) {
                                      setState(() => _inviteFieldError = null);
                                    }
                                  },
                                  onSubmitted: (_) {
                                    if (!session.isLoading) {
                                      _attemptJoin(session);
                                    }
                                  },
                                  decoration: InputDecoration(
                                    labelText: 'Invite code',
                                    hintText: 'ABCD1234',
                                    errorText: _inviteFieldError,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                FilledButton.tonal(
                                  onPressed: session.isLoading ? null : () => _attemptJoin(session),
                                  child: const Text('Join organization'),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (session.errorMessage != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: hasSetupError
                                  ? const Color(0xFFFFF6E6)
                                  : colorScheme.errorContainer.withValues(alpha: 0.78),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: hasSetupError ? const Color(0xFFF0D6A7) : colorScheme.error.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  hasSetupError ? 'Backend setup still needs one step' : 'Organization action failed',
                                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  session.errorMessage!,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: hasSetupError ? const Color(0xFF7B4D18) : colorScheme.onErrorContainer,
                                    height: 1.45,
                                  ),
                                ),
                                if (hasSetupError) ...[
                                  const SizedBox(height: 10),
                                  Text(
                                    'Apply `supabase/schema.sql` in the hosted Supabase SQL Editor, then reopen the app and try again.',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: const Color(0xFF7B4D18),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ]),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        height: size,
        width: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0.04)],
          ),
        ),
      ),
    );
  }
}

class _StepBadge extends StatelessWidget {
  const _StepBadge({required this.number, required this.label});

  final String number;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F9FD),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFD6EAF4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 24,
            width: 24,
            decoration: BoxDecoration(
              color: const Color(0xFF35A8D8),
              borderRadius: BorderRadius.circular(999),
            ),
            alignment: Alignment.center,
            child: Text(number, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF365060))),
        ],
      ),
    );
  }
}

class _CardHeader extends StatelessWidget {
  const _CardHeader({required this.number, required this.title});

  final String number;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 30,
          width: 30,
          decoration: BoxDecoration(
            color: const Color(0xFF35A8D8),
            borderRadius: BorderRadius.circular(999),
          ),
          alignment: Alignment.center,
          child: Text(number, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F9FD),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: const Color(0xFF4C6B7A),
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}