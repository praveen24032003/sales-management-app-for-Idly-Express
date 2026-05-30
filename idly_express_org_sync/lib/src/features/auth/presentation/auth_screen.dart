import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app_shell/application/app_session_controller.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _organizationController = TextEditingController();
  bool _isSignUp = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _organizationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final session = context.read<AppSessionController>();
    if (_isSignUp) {
      await session.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        organizationName: _organizationController.text.trim(),
      );
    } else {
      await session.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = context.watch<AppSessionController>();
    final colorScheme = theme.colorScheme;
    final showVerificationState = _isSignUp && session.awaitingEmailConfirmation;
    final organizationPreview = _organizationController.text.trim().isEmpty
        ? (session.pendingOrganizationName ?? 'Your first branch workspace')
        : _organizationController.text.trim();

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFF8FCFF),
              const Color(0xFFFDFEFF),
              colorScheme.primaryContainer.withValues(alpha: 0.42),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: -50,
                right: -30,
                child: _GlowOrb(color: const Color(0xFFBEEBFA), size: 220),
              ),
              Positioned(
                top: 140,
                left: -70,
                child: _GlowOrb(color: const Color(0xFFE6F5FC), size: 200),
              ),
              Positioned(
                bottom: -80,
                right: 10,
                child: _GlowOrb(color: colorScheme.primary.withValues(alpha: 0.16), size: 250),
              ),
              Positioned(
                top: 28,
                left: 22,
                right: 22,
                child: IgnorePointer(
                  child: Text(
                    _isSignUp ? 'CREATE' : 'ACCESS',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFFE5F1F8),
                      letterSpacing: -3,
                    ),
                  ),
                ),
              ),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(22, 28, 22, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.78),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: const Color(0xFFD6EAF4)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                height: 58,
                                width: 58,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE7F7FD),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Icon(Icons.storefront_rounded, color: colorScheme.primary),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Idly Express',
                                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Clear account setup for branches, teams, and organization access.',
                                      style: theme.textTheme.bodyMedium?.copyWith(color: const Color(0xFF587282)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: const [
                            _FeatureChip(label: 'Email verification'),
                            _FeatureChip(label: 'Org auto-create'),
                            _FeatureChip(label: 'Light workspace flow'),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFF7FB),
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: _AuthModeButton(
                                            label: 'Sign in',
                                            selected: !_isSignUp,
                                            onPressed: session.isLoading
                                                ? null
                                                : () {
                                                    setState(() {
                                                      _isSignUp = false;
                                                    });
                                                  },
                                          ),
                                        ),
                                        Expanded(
                                          child: _AuthModeButton(
                                            label: 'Create account',
                                            selected: _isSignUp,
                                            onPressed: session.isLoading
                                                ? null
                                                : () {
                                                    setState(() {
                                                      _isSignUp = true;
                                                    });
                                                  },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    _isSignUp ? 'Create account and branch workspace' : 'Sign in to continue',
                                    style: theme.textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      color: const Color(0xFF20313C),
                                      height: 1,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    _isSignUp
                                        ? 'Your email gets verified first. The organization name is saved, and the app completes the workspace setup as soon as Supabase gives the session back.'
                                        : 'Use your confirmed work account to open the organization you already belong to.',
                                    style: theme.textTheme.bodyLarge?.copyWith(color: const Color(0xFF5A7382), height: 1.5),
                                  ),
                                  if (_isSignUp) ...[
                                    const SizedBox(height: 18),
                                    const Wrap(
                                      spacing: 10,
                                      runSpacing: 10,
                                      children: [
                                        _StepPill(number: '1', label: 'Create account'),
                                        _StepPill(number: '2', label: 'Verify email'),
                                        _StepPill(number: '3', label: 'Open workspace'),
                                      ],
                                    ),
                                  ],
                                  const SizedBox(height: 20),
                                  if (session.errorMessage != null)
                                    Container(
                                      margin: const EdgeInsets.only(bottom: 14),
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: colorScheme.errorContainer.withValues(alpha: 0.75),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Text(
                                        session.errorMessage!,
                                        style: TextStyle(color: colorScheme.onErrorContainer, fontWeight: FontWeight.w600),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 220),
                                    child: showVerificationState
                                        ? _VerificationStateCard(
                                            key: const ValueKey('verification-card'),
                                            email: session.pendingVerificationEmail ?? _emailController.text.trim(),
                                            organizationName: organizationPreview,
                                          )
                                        : Form(
                                            key: _formKey,
                                            child: Column(
                                              key: const ValueKey('auth-form'),
                                              crossAxisAlignment: CrossAxisAlignment.stretch,
                                              children: [
                                                if (_isSignUp) ...[
                                                  TextFormField(
                                                    key: const ValueKey('auth-organization-field'),
                                                    controller: _organizationController,
                                                    textCapitalization: TextCapitalization.words,
                                                    textInputAction: TextInputAction.next,
                                                    onChanged: (_) => setState(() {}),
                                                    decoration: const InputDecoration(
                                                      labelText: 'Organization name',
                                                      hintText: 'Idly Express - Main Branch',
                                                    ),
                                                    validator: (value) {
                                                      if (!_isSignUp) {
                                                        return null;
                                                      }
                                                      if (value == null || value.trim().isEmpty) {
                                                        return 'Enter your organization name.';
                                                      }
                                                      return null;
                                                    },
                                                  ),
                                                  const SizedBox(height: 16),
                                                ],
                                                TextFormField(
                                                  key: const ValueKey('auth-email-field'),
                                                  controller: _emailController,
                                                  keyboardType: TextInputType.emailAddress,
                                                  textInputAction: TextInputAction.next,
                                                  autofillHints: const [AutofillHints.email],
                                                  decoration: const InputDecoration(
                                                    labelText: 'Email',
                                                    hintText: 'owner@idlyexpress.com',
                                                  ),
                                                  validator: (value) {
                                                    if (value == null || value.trim().isEmpty) {
                                                      return 'Enter your email.';
                                                    }
                                                    if (!value.contains('@')) {
                                                      return 'Enter a valid email address.';
                                                    }
                                                    return null;
                                                  },
                                                ),
                                                const SizedBox(height: 16),
                                                TextFormField(
                                                  key: const ValueKey('auth-password-field'),
                                                  controller: _passwordController,
                                                  obscureText: _obscurePassword,
                                                  textInputAction: TextInputAction.done,
                                                  autofillHints: [
                                                    _isSignUp ? AutofillHints.newPassword : AutofillHints.password,
                                                  ],
                                                  onFieldSubmitted: (_) {
                                                    if (!session.isLoading) {
                                                      _submit();
                                                    }
                                                  },
                                                  decoration: InputDecoration(
                                                    labelText: 'Password',
                                                    hintText: _isSignUp ? 'Minimum 6 characters' : 'Enter your password',
                                                    suffixIcon: IconButton(
                                                      key: const ValueKey('auth-password-visibility-toggle'),
                                                      onPressed: () {
                                                        setState(() {
                                                          _obscurePassword = !_obscurePassword;
                                                        });
                                                      },
                                                      icon: Icon(
                                                        _obscurePassword
                                                            ? Icons.visibility_rounded
                                                            : Icons.visibility_off_rounded,
                                                      ),
                                                      tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                                                    ),
                                                  ),
                                                  validator: (value) {
                                                    if (value == null || value.length < 6) {
                                                      return 'Password must be at least 6 characters.';
                                                    }
                                                    return null;
                                                  },
                                                ),
                                                const SizedBox(height: 14),
                                                Text(
                                                  _isSignUp
                                                      ? 'After verification, the app returns here and completes your first organization automatically.'
                                                      : 'If your account is not verified yet, confirm the email first and then sign in.',
                                                  style: theme.textTheme.bodySmall?.copyWith(
                                                    color: const Color(0xFF6A8391),
                                                    height: 1.45,
                                                  ),
                                                ),
                                                const SizedBox(height: 20),
                                                FilledButton(
                                                  onPressed: session.isLoading ? null : _submit,
                                                  child: Text(_isSignUp ? 'Create account' : 'Sign in'),
                                                ),
                                              ],
                                            ),
                                          ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextButton(
                                    onPressed: session.isLoading
                                        ? null
                                        : () {
                                            setState(() {
                                              _isSignUp = !_isSignUp;
                                            });
                                          },
                                    child: Text(
                                      _isSignUp
                                          ? 'Already have an account? Sign in'
                                          : 'Need an account? Create one',
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(22),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: _InfoTile(
                                        title: 'Workspace preview',
                                        value: organizationPreview,
                                        caption: _isSignUp
                                            ? 'This name is saved before email verification.'
                                            : 'Use the branch workspace already linked to your account.',
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _InfoTile(
                                        title: 'Next step',
                                        value: _isSignUp ? 'Verify email' : 'Open organization',
                                        caption: _isSignUp
                                            ? 'Tap the mail link and come back here.'
                                            : 'You go straight to the organization list after sign in.',
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
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

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFD6EAF4)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _AuthModeButton extends StatelessWidget {
  const _AuthModeButton({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        backgroundColor: selected ? Colors.white : Colors.transparent,
        foregroundColor: selected ? colorScheme.primary : const Color(0xFF6A8391),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
      ),
      child: Text(label),
    );
  }
}

class _StepPill extends StatelessWidget {
  const _StepPill({required this.number, required this.label});

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

class _VerificationStateCard extends StatelessWidget {
  const _VerificationStateCard({
    super.key,
    required this.email,
    required this.organizationName,
  });

  final String email;
  final String organizationName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF3FBFE),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFCBE9F6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 46,
                width: 46,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.mark_email_read_rounded, color: Color(0xFF35A8D8)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Verification email sent',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: const Color(0xFF20313C)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: theme.textTheme.bodyMedium?.copyWith(color: const Color(0xFF5A7382), fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const _VerificationStep(
            number: '1',
            title: 'Open your inbox',
            subtitle: 'Look for the Supabase confirmation email for this account.',
          ),
          const SizedBox(height: 10),
          const _VerificationStep(
            number: '2',
            title: 'Tap the verification link',
            subtitle: 'The app is configured to return to the mobile app instead of localhost.',
          ),
          const SizedBox(height: 10),
          _VerificationStep(
            number: '3',
            title: 'Resume workspace setup',
            subtitle: 'The saved organization "$organizationName" will be created automatically once the session is ready.',
          ),
        ],
      ),
    );
  }
}

class _VerificationStep extends StatelessWidget {
  const _VerificationStep({
    required this.number,
    required this.title,
    required this.subtitle,
  });

  final String number;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 28,
          width: 28,
          decoration: BoxDecoration(
            color: const Color(0xFF35A8D8),
            borderRadius: BorderRadius.circular(999),
          ),
          alignment: Alignment.center,
          child: Text(number, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w800, color: const Color(0xFF20313C))),
              const SizedBox(height: 2),
              Text(subtitle, style: theme.textTheme.bodyMedium?.copyWith(color: const Color(0xFF5A7382), height: 1.45)),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.title,
    required this.value,
    required this.caption,
  });

  final String title;
  final String value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FCFE),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFDDECF5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.labelLarge?.copyWith(color: const Color(0xFF69808F), fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(value, style: theme.textTheme.titleMedium?.copyWith(color: const Color(0xFF20313C), fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text(caption, style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF6A8391), height: 1.45)),
        ],
      ),
    );
  }
}