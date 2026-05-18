import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_state.dart';

const _green    = Color(0xFFFFD600);
const _bg       = Colors.white;
const _surface  = Color(0xFFF5F5F5);
const _border   = Color(0xFFE0E0E0);
const _textMain = Color(0xFF212121);
const _textSub  = Color(0xFF757575);
const _textHint = Color(0xFFBDBDBD);

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Settings saved',
              style: TextStyle(color: Color(0xFF1A1A1A))),
          backgroundColor: _green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        title: const Text('Settings',
            style: TextStyle(color: _textMain, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: _textMain, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('SAVE',
                style: TextStyle(
                    color: _green,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2)),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: _border),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _SectionHeader('Account'),
          const SizedBox(height: 12),
          _SettingField(
            label: 'Phone Number',
            controller: _phoneCtrl,
            icon: Icons.phone_android,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 12),
          _SettingField(
            label: 'Password',
            controller: _passwordCtrl,
            icon: Icons.lock_outline,
            obscureText: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: _textHint, size: 20,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          const SizedBox(height: 28),
          _SectionHeader('Amount Range (₹)'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SettingField(
                  label: 'Minimum',
                  controller: _amtMinCtrl,
                  icon: Icons.arrow_downward,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SettingField(
                  label: 'Maximum',
                  controller: _amtMaxCtrl,
                  icon: Icons.arrow_upward,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          _SectionHeader('Payment Mode'),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _paymentMode = PaymentMode.upi),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: _paymentMode == PaymentMode.upi ? _green : Colors.transparent,
                        borderRadius: const BorderRadius.horizontal(left: Radius.circular(11)),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.phone_android,
                            color: _paymentMode == PaymentMode.upi
                                ? const Color(0xFF1A1A1A) : _textSub,
                            size: 20),
                          const SizedBox(height: 4),
                          Text('OTP / UPI',
                            style: TextStyle(
                              color: _paymentMode == PaymentMode.upi
                                  ? const Color(0xFF1A1A1A) : _textSub,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            )),
                          const SizedBox(height: 2),
                          Text('payType: 3 · orderType: 1',
                            style: TextStyle(
                              color: _paymentMode == PaymentMode.upi
                                  ? const Color(0xFF1A1A1A).withValues(alpha: 0.6) : _textHint,
                              fontSize: 9,
                            )),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(width: 1, height: 60, color: _border),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _paymentMode = PaymentMode.bank),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: _paymentMode == PaymentMode.bank ? _green : Colors.transparent,
                        borderRadius: const BorderRadius.horizontal(right: Radius.circular(11)),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.account_balance,
                            color: _paymentMode == PaymentMode.bank
                                ? const Color(0xFF1A1A1A) : _textSub,
                            size: 20),
                          const SizedBox(height: 4),
                          Text('Bank',
                            style: TextStyle(
                              color: _paymentMode == PaymentMode.bank
                                  ? const Color(0xFF1A1A1A) : _textSub,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            )),
                          const SizedBox(height: 2),
                          Text('payType: 1 · orderType: 2',
                            style: TextStyle(
                              color: _paymentMode == PaymentMode.bank
                                  ? const Color(0xFF1A1A1A).withValues(alpha: 0.6) : _textHint,
                              fontSize: 9,
                            )),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          _SectionHeader('Info'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _border),
            ),
            child: const Text(
              'OTP/UPI mode: cycles through UPI banks (payType 3, orderType 1).\n'
              'Bank mode: uses bank transfer orders (payType 1, orderType 2).\n'
              'When an order is claimed, the QR payment screen will appear.',
              style: TextStyle(color: _textSub, fontSize: 12, height: 1.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
          color: _green,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5),
    );
  }
}

class _SettingField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final TextInputType keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;

  const _SettingField({
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
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        style: const TextStyle(color: _textMain, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: _textSub, fontSize: 12),
          prefixIcon: Icon(icon, color: _textHint, size: 18),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}
