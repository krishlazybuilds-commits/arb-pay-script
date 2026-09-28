import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:arbpay_bot/models/app_state.dart';
import 'package:arbpay_bot/models/profile.dart';
import 'package:arbpay_bot/services/profile_store.dart';
import 'package:arbpay_bot/screens/profiles_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('profiles persist and the active profile backs the settings', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = ProfileStore(prefs);

    final state = AppState();
    final a = Profile(
        id: 'a', name: 'Account A', phone: '111122223333', password: 'pw-a');
    final b = Profile(
        id: 'b', name: 'Account B', phone: '999988887777', password: 'pw-b');
    state.setProfiles([a, b], 'a');

    expect(state.profileCount, 2);
    expect(state.phone, '111122223333');

    state.selectProfile('b');
    expect(state.phone, '999988887777');
    expect(state.password, 'pw-b');

    // Editing settings mutates the active profile.
    state.phone = '900000000001';
    await ProfileStore.persist(state);

    final reloaded = store.loadProfiles();
    expect(reloaded.length, 2);
    expect(reloaded.firstWhere((p) => p.id == 'b').phone, '900000000001');
    expect(store.loadActiveId(reloaded), 'b');
  });

  test('deleting the active profile falls back to another one', () {
    final state = AppState();
    state.setProfiles([
      Profile(id: 'a', name: 'A'),
      Profile(id: 'b', name: 'B'),
    ], 'a');

    state.deleteProfile('a');
    expect(state.profileCount, 1);
    expect(state.activeProfileId, 'b');

    // Never leaves zero profiles behind.
    state.deleteProfile('b');
    expect(state.profileCount, 1);
  });

  test('legacy single account migrates into the first profile', () async {
    SharedPreferences.setMockInitialValues({
      'phone': '9724839891',
      'password': 'legacy-pw',
      'amtMin': 500,
      'amtMax': 1000,
      'paymentMode': 'bank',
    });
    final prefs = await SharedPreferences.getInstance();
    final profiles = ProfileStore(prefs).loadProfiles();

    expect(profiles.length, 1);
    expect(profiles.first.phone, '9724839891');
    expect(profiles.first.amountMin, 500);
    expect(profiles.first.amountMax, 1000);
    expect(profiles.first.paymentMode, PaymentMode.bank);
    expect(profiles.first.name, 'Account 9891');
  });

  testWidgets('profiles screen lists accounts and switches the active one',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final state = AppState();
    state.setProfiles([
      Profile(id: 'a', name: 'Alpha', phone: '111122223333', password: 'x'),
      Profile(id: 'b', name: 'Bravo', phone: '999988887777', password: 'y'),
    ], 'a');

    await tester.pumpWidget(ChangeNotifierProvider<AppState>.value(
      value: state,
      child: const MaterialApp(home: ProfilesScreen()),
    ));

    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('Bravo'), findsOneWidget);
    expect(state.activeProfileId, 'a');

    await tester.tap(find.text('Bravo'));
    await tester.pumpAndSettle();

    expect(state.activeProfileId, 'b');
    expect(state.phone, '999988887777');
  });
}
