import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_state.dart';
import '../models/profile.dart';

/// Persists the list of saved profiles and which one is active.
///
/// Older builds stored a single account under the flat keys
/// (phone, password, amtMin, amtMax, paymentMode). On first run those are
/// migrated into the first profile so nobody loses their saved login.
class ProfileStore {
  static const _kProfiles = 'profiles';
  static const _kActive = 'activeProfileId';

  final SharedPreferences prefs;
  ProfileStore(this.prefs);

  static String newId() => DateTime.now().microsecondsSinceEpoch.toString();

  /// Writes the current in-memory profiles + active id back to disk.
  static Future<void> persist(AppState state) async {
    final prefs = await SharedPreferences.getInstance();
    await ProfileStore(prefs).save(state.profiles, state.activeProfileId);
  }

  List<Profile> loadProfiles() {
    final raw = prefs.getString(_kProfiles);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          final list = decoded
              .whereType<Map>()
              .map((e) => Profile.fromJson(Map<String, dynamic>.from(e)))
              .where((p) => p.id.isNotEmpty)
              .toList();
          if (list.isNotEmpty) return list;
        }
      } catch (_) {
        // Corrupt payload — fall through to migration.
      }
    }
    return [_migrateLegacy()];
  }

  String loadActiveId(List<Profile> profiles) {
    final id = prefs.getString(_kActive) ?? '';
    if (profiles.any((p) => p.id == id)) return id;
    return profiles.isEmpty ? '' : profiles.first.id;
  }

  Future<void> save(List<Profile> profiles, String activeId) async {
    await prefs.setString(
      _kProfiles,
      jsonEncode(profiles.map((p) => p.toJson()).toList()),
    );
    await prefs.setString(_kActive, activeId);
  }

  Profile _migrateLegacy() {
    final phone = prefs.getString('phone') ?? '';
    final pass = prefs.getString('password') ?? '';
    final tail = phone.length >= 4 ? phone.substring(phone.length - 4) : phone;
    return Profile(
      id: newId(),
      name: phone.isEmpty ? 'Account 1' : 'Account $tail',
      phone: phone,
      password: pass,
      amountMin: prefs.getInt('amtMin') ?? 1700,
      amountMax: prefs.getInt('amtMax') ?? 2000,
      paymentMode: prefs.getString('paymentMode') == 'bank'
          ? PaymentMode.bank
          : PaymentMode.upi,
    );
  }
}
