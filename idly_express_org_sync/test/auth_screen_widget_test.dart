import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:idly_express_org_sync/src/features/app_shell/application/app_session_controller.dart';
import 'package:idly_express_org_sync/src/features/auth/data/auth_repository.dart';
import 'package:idly_express_org_sync/src/features/auth/presentation/auth_screen.dart';
import 'package:idly_express_org_sync/src/features/organization/data/organization_repository.dart';
import 'package:idly_express_org_sync/src/features/organization/domain/organization_summary.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('password field can be revealed from the auth screen', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final controller = AppSessionController(
      authRepository: _FakeAuthRepository(currentUserValue: _testUser()),
      organizationRepository: _FakeOrganizationRepository(),
    );

    await tester.pumpWidget(_buildTestApp(controller));
    await tester.pumpAndSettle();

    final passwordEditableFinder = find.descendant(
      of: find.byKey(const ValueKey('auth-password-field')),
      matching: find.byType(EditableText),
    );
    expect(
      tester.widget<EditableText>(passwordEditableFinder).obscureText,
      isTrue,
    );

    await tester.tap(find.byKey(const ValueKey('auth-password-visibility-toggle')));
    await tester.pumpAndSettle();

    expect(
      tester.widget<EditableText>(passwordEditableFinder).obscureText,
      isFalse,
    );
  });

}

Widget _buildTestApp(AppSessionController controller) {
  return ChangeNotifierProvider.value(
    value: controller,
    child: MaterialApp(
      home: const AuthScreen(),
    ),
  );
}

User _testUser() {
  return User.fromJson({
    'id': 'user-1',
    'aud': 'authenticated',
    'role': 'authenticated',
    'email': 'owner@example.com',
    'app_metadata': {
      'provider': 'email',
      'providers': ['email'],
    },
    'user_metadata': <String, dynamic>{},
    'created_at': '2024-01-01T00:00:00.000Z',
    'updated_at': '2024-01-01T00:00:00.000Z',
  })!;
}

class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository({this.currentUserValue});

  final User? currentUserValue;
  String? lastSignUpEmail;

  @override
  Stream<AuthState> get authStateChanges => const Stream<AuthState>.empty();

  @override
  User? get currentUser => currentUserValue;

  @override
  Future<AuthResponse> signUp({required String email, required String password}) async {
    lastSignUpEmail = email;
    return AuthResponse();
  }
}

class _FakeOrganizationRepository extends OrganizationRepository {
  @override
  Future<List<OrganizationSummary>> fetchOrganizations(String userId) async => const [];
}

