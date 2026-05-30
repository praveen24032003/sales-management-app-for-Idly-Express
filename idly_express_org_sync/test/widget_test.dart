import 'package:flutter_test/flutter_test.dart';
import 'package:idly_express_org_sync/src/app.dart';

void main() {
  testWidgets('renders setup gate when Supabase is not configured', (WidgetTester tester) async {
    await tester.pumpWidget(const IdlyExpressOrgApp());
    await tester.pumpAndSettle();

    expect(find.text('Supabase is not configured yet'), findsOneWidget);
  });
}
