import 'package:flutter/foundation.dart';
import 'profile.dart';

enum BotStatus { idle, connecting, cloudflare, loggingIn, capturing, running, qrReady, success, error }

enum PaymentMode { upi, bank }

class LogEntry {
  final String time;
  final String message;
  final LogLevel level;

  LogEntry({required this.time, required this.message, required this.level});
}

enum LogLevel { info, success, warning, error }

class AppState extends ChangeNotifier {
  BotStatus _status = BotStatus.idle;
  final List<LogEntry> _logs = [];
  int _rounds = 0;
  int _attempts = 0;
  int _successCount = 0;
  String _currentOrder = '';

  // Profiles — each account is a saved Profile. The active one backs the
  // phone/password/amount/paymentMode accessors below, so callers keep working.
  List<Profile> _profiles = [];
  String _activeProfileId = '';
  bool isDark = true;

  List<Profile> get profiles => List.unmodifiable(_profiles);
  String get activeProfileId => _activeProfileId;
  bool get hasProfiles => _profiles.isNotEmpty;
  int get profileCount => _profiles.length;

  static String newProfileId() =>
      DateTime.now().microsecondsSinceEpoch.toString();

  Profile get activeProfile {
    if (_profiles.isEmpty) {
      _profiles.add(Profile(id: newProfileId(), name: 'Account 1'));
    }
    return _profiles.firstWhere(
      (p) => p.id == _activeProfileId,
      orElse: () => _profiles.first,
    );
  }

  // Settings — delegated to the active profile.
  String get phone => activeProfile.phone;
  set phone(String v) {
    activeProfile.phone = v;
    notifyListeners();
  }

  String get password => activeProfile.password;
  set password(String v) {
    activeProfile.password = v;
    notifyListeners();
  }

  int get amountMin => activeProfile.amountMin;
  set amountMin(int v) {
    activeProfile.amountMin = v;
    notifyListeners();
  }

  int get amountMax => activeProfile.amountMax;
  set amountMax(int v) {
    activeProfile.amountMax = v;
    notifyListeners();
  }

  PaymentMode get paymentMode => activeProfile.paymentMode;
  set paymentMode(PaymentMode m) {
    activeProfile.paymentMode = m;
    notifyListeners();
  }

  // ── Profile management ────────────────────────────────────────────────────
  void setProfiles(List<Profile> profiles, String activeId) {
    _profiles = List.of(profiles);
    if (_profiles.isEmpty) {
      _profiles.add(Profile(id: newProfileId(), name: 'Account 1'));
    }
    _activeProfileId = _profiles.any((p) => p.id == activeId)
        ? activeId
        : _profiles.first.id;
    notifyListeners();
  }

  void selectProfile(String id) {
    if (_profiles.any((p) => p.id == id)) {
      _activeProfileId = id;
      notifyListeners();
    }
  }

  void upsertProfile(Profile p) {
    final i = _profiles.indexWhere((x) => x.id == p.id);
    if (i >= 0) {
      _profiles[i] = p;
    } else {
      _profiles.add(p);
      _activeProfileId = p.id;
    }
    notifyListeners();
  }

  void deleteProfile(String id) {
    _profiles.removeWhere((p) => p.id == id);
    if (_profiles.isEmpty) {
      _profiles.add(Profile(id: newProfileId(), name: 'Account 1'));
    }
    if (_activeProfileId == id) {
      _activeProfileId = _profiles.first.id;
    }
    notifyListeners();
  }

  BotStatus get status => _status;
  List<LogEntry> get logs => List.unmodifiable(_logs);
  int get rounds => _rounds;
  int get attempts => _attempts;
  int get successCount => _successCount;
  String get currentOrder => _currentOrder;

  // Derived API values based on payment mode
  int get orderType => paymentMode == PaymentMode.upi ? 1 : 2;
  String get payType => paymentMode == PaymentMode.upi ? '3' : '1';

  void setPaymentMode(PaymentMode mode) {
    paymentMode = mode;
    notifyListeners();
  }

  void toggleTheme() {
    isDark = !isDark;
    notifyListeners();
  }

  void setStatus(BotStatus s) {
    _status = s;
    notifyListeners();
  }

  void addLog(String message, {LogLevel level = LogLevel.info}) {
    final now = DateTime.now();
    final time =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    _logs.insert(0, LogEntry(time: time, message: message, level: level));
    if (_logs.length > 200) _logs.removeLast();
    notifyListeners();
  }

  void incrementAttempts() {
    _attempts++;
    notifyListeners();
  }

  void incrementRounds() {
    _rounds++;
    notifyListeners();
  }

  void incrementSuccess() {
    _successCount++;
    notifyListeners();
  }

  void setCurrentOrder(String order) {
    _currentOrder = order;
    notifyListeners();
  }

  void reset() {
    _status = BotStatus.idle;
    _attempts = 0;
    _currentOrder = '';
    notifyListeners();
  }

  void clearLogs() {
    _logs.clear();
    notifyListeners();
  }
}
