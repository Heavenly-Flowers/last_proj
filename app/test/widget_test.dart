import 'package:app/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});

    await Supabase.initialize(
      url: 'https://zdodrwqygpqwmvdwgrit.supabase.co',
      anonKey: 'sb_publishable_Xw2mfttSFjkmgZWK8mT2sQ_644P36pX',
    );
  });

  testWidgets('Shows auth screen for signed out user', (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Вход'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Пароль'), findsOneWidget);
  });
}
