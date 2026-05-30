import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_config.dart';
import '../../auth/data/auth_repository.dart';
import '../../organization/data/organization_repository.dart';
import '../../organization/domain/organization_summary.dart';

class AppSessionController extends ChangeNotifier {
  static const _activeOrgPreferenceKey = 'active_organization_id';
  static const _pendingOrgNamePreferenceKey = 'pending_signup_organization_name';

  AppSessionController({
    AuthRepository? authRepository,
    OrganizationRepository? organizationRepository,
  }) : _authRepository = authRepository ?? AuthRepository(),
       _organizationRepository = organizationRepository ?? OrganizationRepository();

  final AuthRepository _authRepository;
  final OrganizationRepository _organizationRepository;

  StreamSubscription<AuthState>? _authSubscription;

  bool _isLoading = true;
  String? _errorMessage;
  User? _currentUser;
  List<OrganizationSummary> _organizations = const [];
  OrganizationSummary? _activeOrganization;
  String? _pendingOrganizationName;
  bool _awaitingEmailConfirmation = false;
  String? _pendingVerificationEmail;

  bool get isLoading => _isLoading;
  bool get needsSupabaseSetup => !SupabaseConfig.isReady;
  String? get errorMessage => _errorMessage;
  User? get currentUser => _currentUser;
  List<OrganizationSummary> get organizations => _organizations;
  OrganizationSummary? get activeOrganization => _activeOrganization;
  bool get awaitingEmailConfirmation => _awaitingEmailConfirmation;
  String? get pendingVerificationEmail => _pendingVerificationEmail;
  String? get pendingOrganizationName => _pendingOrganizationName;

  Future<void> initialize() async {
    if (!SupabaseConfig.isReady) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    _authSubscription ??= _authRepository.authStateChanges.listen((event) {
      _handleAuthChange(event.session?.user);
    });

    await _handleAuthChange(_authRepository.currentUser);
  }

  Future<void> signIn({required String email, required String password}) async {
    await _runBusy(() async {
      _awaitingEmailConfirmation = false;
      _pendingVerificationEmail = null;
      await _authRepository.signIn(email: email, password: password);
    });
  }

  Future<void> signUp({
    required String email,
    required String password,
    String? organizationName,
  }) async {
    await _runBusy(() async {
      final trimmedOrganizationName = organizationName?.trim();
      _pendingOrganizationName = trimmedOrganizationName == null || trimmedOrganizationName.isEmpty
          ? null
          : trimmedOrganizationName;
      await _persistPendingOrganizationName();

      final response = await _authRepository.signUp(email: email, password: password);

      if (_pendingOrganizationName == null) {
        _awaitingEmailConfirmation = response.session == null;
        _pendingVerificationEmail = response.session == null ? email.trim() : null;
        return;
      }

      final signedInUser = response.session?.user ?? _authRepository.currentUser;
      if (signedInUser == null) {
        _awaitingEmailConfirmation = true;
        _pendingVerificationEmail = email.trim();
        return;
      }

      _currentUser = signedInUser;
      _awaitingEmailConfirmation = false;
      _pendingVerificationEmail = null;
      await _createPendingOrganizationIfNeeded();
    });
  }

  Future<void> signOut() async {
    await _runBusy(() async {
      await _authRepository.signOut();
      _currentUser = null;
      _organizations = const [];
      _activeOrganization = null;
      _awaitingEmailConfirmation = false;
      _pendingVerificationEmail = null;
    });
  }

  Future<void> createOrganization(String name) async {
    final userId = _currentUser?.id;
    if (userId == null) {
      _errorMessage = 'Sign in before creating an organization.';
      notifyListeners();
      return;
    }

    await _runBusy(() async {
      final organization = await _organizationRepository.createOrganization(
        userId: userId,
        name: name,
      );
      _organizations = [..._organizations, organization];
      await _setActiveOrganizationById(organization.id);
    });
  }

  Future<void> joinOrganization(String inviteCode) async {
    final userId = _currentUser?.id;
    if (userId == null) {
      _errorMessage = 'Sign in before joining an organization.';
      notifyListeners();
      return;
    }

    await _runBusy(() async {
      final organization = await _organizationRepository.joinOrganization(
        userId: userId,
        inviteCode: inviteCode,
      );

      final exists = _organizations.any((item) => item.id == organization.id);
      _organizations = exists
          ? _organizations.map((item) => item.id == organization.id ? organization : item).toList()
          : [..._organizations, organization];
      await _setActiveOrganizationById(organization.id);
    });
  }

  Future<void> refreshOrganizations() async {
    final userId = _currentUser?.id;
    if (userId == null) {
      _errorMessage = 'Sign in before refreshing organizations.';
      notifyListeners();
      return;
    }

    await _runBusy(() async {
      _organizations = await _organizationRepository.fetchOrganizations(userId);
      await _restoreActiveOrganization();
    });
  }

  Future<void> selectOrganization(String organizationId) async {
    await _setActiveOrganizationById(organizationId);
    notifyListeners();
  }

  Future<void> clearActiveOrganization() async {
    _activeOrganization = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_activeOrgPreferenceKey);
    notifyListeners();
  }

  Future<void> clearError() async {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> _handleAuthChange(User? user) async {
    _currentUser = user;
    _errorMessage = null;

    if (user == null) {
      _organizations = const [];
      _activeOrganization = null;
      _awaitingEmailConfirmation = false;
      _isLoading = false;
      notifyListeners();
      return;
    }

    await _runBusy(() async {
      _awaitingEmailConfirmation = false;
      _pendingVerificationEmail = null;
      await _loadPendingOrganizationName();
      _organizations = await _organizationRepository.fetchOrganizations(user.id);
      await _createPendingOrganizationIfNeeded();
      await _restoreActiveOrganization();
    });
  }

  Future<void> _createPendingOrganizationIfNeeded() async {
    final userId = _currentUser?.id;
    final pendingName = _pendingOrganizationName?.trim();

    if (userId == null || pendingName == null || pendingName.isEmpty) {
      return;
    }

    final existingMatch = _organizations.where((item) => item.name.trim().toLowerCase() == pendingName.toLowerCase());
    if (existingMatch.isNotEmpty) {
      _pendingOrganizationName = null;
      await _persistPendingOrganizationName();
      await _setActiveOrganizationById(existingMatch.first.id);
      return;
    }

    final organization = await _organizationRepository.createOrganization(
      userId: userId,
      name: pendingName,
    );
    final existingIds = _organizations.map((item) => item.id).toSet();
    _organizations = existingIds.contains(organization.id) ? _organizations : [..._organizations, organization];
    _pendingOrganizationName = null;
    await _persistPendingOrganizationName();
    await _setActiveOrganizationById(organization.id);
  }

  Future<void> _loadPendingOrganizationName() async {
    final prefs = await SharedPreferences.getInstance();
    _pendingOrganizationName = prefs.getString(_pendingOrgNamePreferenceKey);
  }

  Future<void> _persistPendingOrganizationName() async {
    final prefs = await SharedPreferences.getInstance();
    final pendingName = _pendingOrganizationName?.trim();
    if (pendingName == null || pendingName.isEmpty) {
      await prefs.remove(_pendingOrgNamePreferenceKey);
      return;
    }
    await prefs.setString(_pendingOrgNamePreferenceKey, pendingName);
  }

  Future<void> _restoreActiveOrganization() async {
    if (_organizations.isEmpty) {
      _activeOrganization = null;
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final preferredId = prefs.getString(_activeOrgPreferenceKey);

    _activeOrganization = _organizations.firstWhere(
      (item) => item.id == preferredId,
      orElse: () => _organizations.first,
    );

    await prefs.setString(_activeOrgPreferenceKey, _activeOrganization!.id);
  }

  Future<void> _setActiveOrganizationById(String organizationId) async {
    _activeOrganization = _organizations.firstWhere(
      (item) => item.id == organizationId,
      orElse: () => _activeOrganization ?? _organizations.first,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeOrgPreferenceKey, _activeOrganization!.id);
  }

  Future<void> _runBusy(Future<void> Function() action) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await action();
    } catch (error, stackTrace) {
      debugPrint('AppSessionController error: $error\n$stackTrace');
      _errorMessage = _formatError(error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _formatError(Object error) {
    if (error is AuthException) {
      final code = error.statusCode;
      final authCode = error is AuthApiException ? error.code : null;

      if (authCode == 'email_not_confirmed') {
        return 'Check your email and confirm the account before signing in.';
      }

      if (authCode == 'email_address_invalid') {
        return 'Enter a valid email address to continue.';
      }

      if (authCode == 'invalid_login_credentials') {
        return 'Email or password is incorrect.';
      }

      if (code == '429') {
        return 'Too many auth attempts. Wait a moment and try again.';
      }

      if (error.message.toLowerCase().contains('redirect') && error.message.toLowerCase().contains('allow')) {
        return 'Supabase redirect setup is incomplete. Add com.idlyexpress.salesmanager://login-callback/ to Auth URL Configuration and try again.';
      }

      if (error.message.isNotEmpty) {
        return error.message;
      }
    }

    if (error is PostgrestException) {
      final message = error.message.toLowerCase();

      if (error.code == '23505' || message.contains('duplicate key')) {
        if (message.contains('invite_code')) {
          return 'That invite code is already in use. Try again.';
        }
        if (message.contains('slug')) {
          return 'That organization name is already in use. Try a different name.';
        }
      }

      if (message.contains('authentication required')) {
        return 'Sign in again, then create the organization.';
      }

      if (message.contains('organization name is required')) {
        return 'Enter an organization name to continue.';
      }

      if (message.contains('invite code not found')) {
        return 'No organization matches that invite code. Double-check it with the owner.';
      }

      // Only flag the schema as missing when Postgres actually reports the
      // function does not exist (PostgREST code PGRST202 / SQLSTATE 42883).
      final indicatesMissingFunction = error.code == 'PGRST202' ||
          error.code == '42883' ||
          message.contains('does not exist') ||
          message.contains('schema cache');
      if (indicatesMissingFunction &&
          (message.contains('create_organization_with_owner') ||
              message.contains('join_organization_with_invite'))) {
        return 'Organization setup is incomplete. Apply the latest Supabase schema and try again.';
      }

      if (message.isNotEmpty) {
        return error.message;
      }
    }

    return 'Something went wrong. Please try again.';
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}