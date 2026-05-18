import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_state.dart';

// ── Design tokens (matching home screen) ──────────────────────────────────────
const _bg      = Color(0xFF0A0A0F);
const _surface = Color(0xFF13131A);
const _card    = Color(0xFF1C1C26);
const _border  = Color(0xFF2A2A38);
const _yellow  = Color(0xFFFFCC00);
const _yellowDim = Color(0x33FFCC00);
const _white   = Color(0xFFFFFFFF);
const _grey    = Color(0xFF8888A0);
const _greyDim = Color(0xFF3A3A50);
const _red     = Color(0xFFFF4444);
const _green   = Color(0xFF00E676);

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _phoneCtrl;
  late TextEditingController _passwordCtrl;
  late TextEditingController _amtMinCtrl;
  late TextEditingController _amtMaxCtrl;
  bool _obscurePassword = true;
  late PaymentMode _paymentMode;

  @override
  void initState() {
    super.initState();
    final state = context.read<AppState>();
    _phoneCtrl    = TextEditingController(text: state.phone);
    _passwordCtrl = TextEditingController(text: state.password);
    _amtMinCtrl   = TextEditingController(text: state.amountMin.toString());
    _amtMaxCtrl   = TextEditingController(text: state.amountMax.toString());
    _paymentMode  = state.paymentMode;
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _amtMinCtrl.dispose();
    _amtMaxCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final state = context.read<AppState>();
    state.phone        = _phoneCtrl.text.trim();
    state.password     = _passwordCtrl.text;
    state.amountMin    = int.tryParse(_amtMinCtrl.text) ?? 1700;
    state.amountMax    = int.tryParse(_amtMaxCtrl.text) ?? 2000;
    state.setPaymentMode(_paymentMode);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('phone',       state.phone);
    await prefs.setString('password',    state.password);
    await prefs.setInt('amtMin',         state.amountMin);
    await prefs.setInt('amtMax',         state.amountMax);
    await prefs.setString('paymentMode', _paymentMode == PaymentMode.bank ? 'bank' : 'upi');

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Settings saved',
          style: TextStyle(color: Color(0xFF0A0A0F), fontWeight: FontWeight.bold)),
        backgroundColor: _yellow,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _grey, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Settings',
          style: TextStyle(color: _white, fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          // Theme toggle
          GestureDetector(
            onTap: () async {
              final state = context.read<AppState>();
              state.toggleTheme();
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('isDark', state.isDark);
            },
            child: Consumer<AppState>(
              builder: (_, state, __) => Container(
                margin: const EdgeInsets.only(right: 8),
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _border),
                ),
                child: Icon(
                  state.isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  color: _yellow, size: 18),
              ),
            ),
          ),
          GestureDetector(
            onTap: _save,
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _yellow,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('SAVE',
                style: TextStyle(
                  color: _bg, fontWeight: FontWeight.bold,
                  fontSize: 13, letterSpacing: 1.0)),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 0.5, color: _border),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Account ──────────────────────────────────────────────────────
          _SectionLabel('ACCOUNT'),
          const SizedBox(height: 12),
          _DarkField(
            label: 'Phone Number',
            controller: _phoneCtrl,
            icon: Icons.phone_android_rounded,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 10),
          _DarkField(
            label: 'Password',
            controller: _passwordCtrl,
            icon: Icons.lock_outline_rounded,
            obscureText: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: _greyDim, size: 18),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),

          const SizedBox(height: 28),

          // ── Amount range ──────────────────────────────────────────────────
          _SectionLabel('AMOUNT RANGE (₹)'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _DarkField(
                  label: 'Minimum',
                  controller: _amtMinCtrl,
                  icon: Icons.arrow_downward_rounded,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DarkField(
                  label: 'Maximum',
                  controller: _amtMaxCtrl,
                  icon: Icons.arrow_upward_rounded,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // ── Payment mode ──────────────────────────────────────────────────
          _SectionLabel('PAYMENT MODE'),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _border),
            ),
            child: Row(
              children: [
                _ModeTab(
                  label: 'OTP / UPI',
                  subLabel: 'payType: 3 · orderType: 1',
                  icon: Icons.currency_rupee_rounded,
                  selected: _paymentMode == PaymentMode.upi,
                  isLeft: true,
                  onTap: () => setState(() => _paymentMode = PaymentMode.upi),
                ),
                Container(width: 0.5, height: 72, color: _border),
                _ModeTab(
                  label: 'Bank',
                  subLabel: 'payType: 1 · orderType: 2',
                  icon: Icons.account_balance_rounded,
                  selected: _paymentMode == PaymentMode.bank,
                  isLeft: false,
                  onTap: () => setState(() => _paymentMode = PaymentMode.bank),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // ── Info ──────────────────────────────────────────────────────────
          _SectionLabel('INFO'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _border),
            ),
            child: Column(
              children: [
                _InfoRow(
                  icon: Icons.currency_rupee_rounded,
                  color: _yellow,
                  title: 'OTP / UPI mode',
                  desc: 'Buys UPI orders using bank OTP. Cycles through PhonePe, GPay, Paytm etc.',
                ),
                const SizedBox(height: 14),
                _InfoRow(
                  icon: Icons.account_balance_rounded,
                  color: _green,
                  title: 'Bank mode',
                  desc: 'Buys bank transfer orders. Uses payType=1 and orderType=2.',
                ),
                const SizedBox(height: 14),
                _InfoRow(
                  icon: Icons.info_outline_rounded,
                  color: _grey,
                  title: 'On success',
                  desc: 'When an order is claimed, the QR payment screen appears in the WebView.',
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Section label ──────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(text,
      style: const TextStyle(
        color: _grey, fontSize: 10,
        fontWeight: FontWeight.bold, letterSpacing: 1.5));
  }
}

// ── Dark input field ───────────────────────────────────────────────────────────
class _DarkField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final TextInputType keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;

  const _DarkField({
    required this.label,
    required this.controller,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        style: const TextStyle(color: _white, fontSize: 15),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: _grey, fontSize: 13),
          prefixIcon: Icon(icon, color: _greyDim, size: 18),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}

// ── Mode tab ───────────────────────────────────────────────────────────────────
class _ModeTab extends StatelessWidget {
  final String label;
  final String subLabel;
  final IconData icon;
  final bool selected;
  final bool isLeft;
  final VoidCallback onTap;

  const _ModeTab({
    required this.label, required this.subLabel, required this.icon,
    required this.selected, required this.isLeft, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: selected ? _yellowDim : Colors.transparent,
            borderRadius: BorderRadius.horizontal(
              left: isLeft ? const Radius.circular(13) : Radius.zero,
              right: isLeft ? Radius.zero : const Radius.circular(13),
            ),
            border: selected
                ? Border.all(color: _yellow.withValues(alpha: 0.4))
                : Border.all(color: Colors.transparent),
          ),
          child: Column(
            children: [
              Icon(icon, color: selected ? _yellow : _greyDim, size: 20),
              const SizedBox(height: 6),
              Text(label,
                style: TextStyle(
                  color: selected ? _yellow : _grey,
                  fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 3),
              Text(subLabel,
                style: TextStyle(
                  color: selected ? _yellow.withValues(alpha: 0.5) : _greyDim,
                  fontSize: 9)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Info row ───────────────────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String desc;

  const _InfoRow({required this.icon, required this.color,
    required this.title, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                style: const TextStyle(
                  color: _white, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 3),
              Text(desc,
                style: const TextStyle(color: _grey, fontSize: 12, height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }
}
