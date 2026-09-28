import 'app_state.dart';

/// A saved account profile. Each profile owns its own credentials, payment
/// mode and amount range so switching between accounts is one tap.
class Profile {
  String id;
  String name;
  String phone;
  String password;
  int amountMin;
  int amountMax;
  PaymentMode paymentMode;

  Profile({
    required this.id,
    required this.name,
    this.phone = '',
    this.password = '',
    this.amountMin = 1700,
    this.amountMax = 2000,
    this.paymentMode = PaymentMode.upi,
  });

  Profile copyWith({
    String? name,
    String? phone,
    String? password,
    int? amountMin,
    int? amountMax,
    PaymentMode? paymentMode,
  }) {
    return Profile(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      password: password ?? this.password,
      amountMin: amountMin ?? this.amountMin,
      amountMax: amountMax ?? this.amountMax,
      paymentMode: paymentMode ?? this.paymentMode,
    );
  }

  bool get isConfigured => phone.isNotEmpty && password.isNotEmpty;

  /// First character of the display name, for the avatar chip.
  String get initial {
    final n = name.trim();
    if (n.isEmpty) return '?';
    return n.substring(0, 1).toUpperCase();
  }

  /// Phone shown masked: keeps the last 4 digits only.
  String get maskedPhone {
    final p = phone.trim();
    if (p.isEmpty) return 'No number';
    if (p.length <= 4) return p;
    return '•••• ${p.substring(p.length - 4)}';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'password': password,
        'amountMin': amountMin,
        'amountMax': amountMax,
        'paymentMode': paymentMode == PaymentMode.bank ? 'bank' : 'upi',
      };

  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
        id: j['id']?.toString() ?? '',
        name: j['name']?.toString() ?? 'Account',
        phone: j['phone']?.toString() ?? '',
        password: j['password']?.toString() ?? '',
        amountMin: (j['amountMin'] as num?)?.toInt() ?? 1700,
        amountMax: (j['amountMax'] as num?)?.toInt() ?? 2000,
        paymentMode:
            j['paymentMode'] == 'bank' ? PaymentMode.bank : PaymentMode.upi,
      );
}
