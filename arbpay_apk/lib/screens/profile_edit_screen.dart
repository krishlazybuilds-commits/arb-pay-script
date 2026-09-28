import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import '../models/profile.dart';
import '../services/profile_store.dart';
import '../theme/app_theme.dart';
import '../widgets/settings_fields.dart';

/// Create or edit a single saved account profile.
class ProfileEditScreen extends StatefulWidget {
  final Profile? existing;
  const ProfileEditScreen({super.key, this.existing});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _passCtrl;
  late final TextEditingController _minCtrl;
  late final TextEditingController _maxCtrl;
  late PaymentMode _mode;
  bool _obscure = true;

  bool get _isNew => widget.existing == null;
  bool get _canDelete =>
      !_isNew && context.read<AppState>().profileCount > 1;

  @override
  void initState() {
    super.initState();
    final p = widget.existing;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _phoneCtrl = TextEditingController(text: p?.phone ?? '');
    _passCtrl = TextEditingController(text: p?.password ?? '');
    _minCtrl = TextEditingController(text: '${p?.amountMin ?? 1700}');
    _maxCtrl = TextEditingController(text: '${p?.amountMax ?? 2000}');
    _mode = p?.paymentMode ?? PaymentMode.upi;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    _minCtrl.dispose();
    _maxCtrl.dispose();
    super.dispose();
  }

  String _fallbackName() {
    final n = _nameCtrl.text.trim();
    if (n.isNotEmpty) return n;
    final p = _phoneCtrl.text.trim();
    if (p.length >= 4) return 'Account ${p.substring(p.length - 4)}';
    return 'Account ${context.read<AppState>().profileCount + 1}';
  }

  Future<void> _save() async {
    final state = context.read<AppState>();
    var min = int.tryParse(_minCtrl.text.trim()) ?? 1700;
    var max = int.tryParse(_maxCtrl.text.trim()) ?? 2000;
    if (max < min) max = min;

    final profile = Profile(
      id: widget.existing?.id ?? AppState.newProfileId(),
      name: _fallbackName(),
      phone: _phoneCtrl.text.trim(),
      password: _passCtrl.text,
      amountMin: min,
      amountMax: max,
      paymentMode: _mode,
    );

    state.upsertProfile(profile);
    await ProfileStore.persist(state);
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('${profile.name} saved',
          style: TextStyle(color: AppTheme(state.isDark).bg)),
    ));
  }

  Future<void> _delete() async {
    final state = context.read<AppState>();
    final t = AppTheme(state.isDark);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: t.surface,
        title: Text('Delete profile?',
            style: TextStyle(color: t.textPrimary, fontSize: 17)),
        content: Text(
          '${widget.existing?.name ?? 'This profile'} will be removed from this device.',
          style: TextStyle(color: t.textSub, fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: t.textSub)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete', style: TextStyle(color: t.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    state.deleteProfile(widget.existing!.id);
    await ProfileStore.persist(state);
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final t = AppTheme(state.isDark);
        return Scaffold(
          backgroundColor: t.bg,
          appBar: AppBar(
            backgroundColor: t.bg,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded,
                  color: t.textSub, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(_isNew ? 'New profile' : 'Edit profile',
                style: TextStyle(
                    color: t.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
            actions: [
              GestureDetector(
                onTap: _save,
                child: Container(
                  margin: const EdgeInsets.only(right: 16),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                  decoration: BoxDecoration(
                    color: t.yellow,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('SAVE',
                      style: TextStyle(
                          color: t.bg,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          letterSpacing: 1.0)),
                ),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(height: 0.5, color: t.border),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              SectionLabel('Profile name', t),
              const SizedBox(height: 10),
              DarkField(
                label: 'Name',
                controller: _nameCtrl,
                icon: Icons.badge_outlined,
                t: t,
              ),
              const SizedBox(height: 8),
              Text('Used only on this device, to tell your accounts apart.',
                  style: TextStyle(color: t.textDim, fontSize: 11)),
              const SizedBox(height: 26),
              SectionLabel('Login', t),
              const SizedBox(height: 10),
              DarkField(
                label: 'Phone Number',
                controller: _phoneCtrl,
                icon: Icons.phone_android_rounded,
                keyboardType: TextInputType.phone,
                t: t,
              ),
              const SizedBox(height: 10),
              DarkField(
                label: 'Password',
                controller: _passCtrl,
                icon: Icons.lock_outline_rounded,
                obscureText: _obscure,
                t: t,
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!_obscure)
                      IconButton(
                        icon: Icon(Icons.copy_rounded,
                            color: t.textDim, size: 16),
                        tooltip: 'Copy password',
                        onPressed: () {
                          Clipboard.setData(
                              ClipboardData(text: _passCtrl.text));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Password copied')),
                          );
                        },
                      ),
                    IconButton(
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: t.textDim,
                        size: 18,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 26),
              SectionLabel('Amount range (₹)', t),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: DarkField(
                    label: 'Minimum',
                    controller: _minCtrl,
                    icon: Icons.arrow_downward_rounded,
                    keyboardType: TextInputType.number,
                    t: t,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DarkField(
                    label: 'Maximum',
                    controller: _maxCtrl,
                    icon: Icons.arrow_upward_rounded,
                    keyboardType: TextInputType.number,
                    t: t,
                  ),
                ),
              ]),
              const SizedBox(height: 26),
              SectionLabel('Payment mode', t),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: t.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: t.border),
                ),
                child: Row(children: [
                  ModeTab(
                    label: 'OTP / UPI',
                    subLabel: 'Cycles through UPI banks',
                    icon: Icons.currency_rupee_rounded,
                    selected: _mode == PaymentMode.upi,
                    isLeft: true,
                    t: t,
                    onTap: () => setState(() => _mode = PaymentMode.upi),
                  ),
                  Container(width: 0.5, height: 72, color: t.border),
                  ModeTab(
                    label: 'Bank',
                    subLabel: 'Direct bank transfer',
                    icon: Icons.account_balance_rounded,
                    selected: _mode == PaymentMode.bank,
                    isLeft: false,
                    t: t,
                    onTap: () => setState(() => _mode = PaymentMode.bank),
                  ),
                ]),
              ),
              const SizedBox(height: 32),
              if (_canDelete)
                GestureDetector(
                  onTap: _delete,
                  child: Container(
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: t.red.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border:
                          Border.all(color: t.red.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.delete_outline_rounded,
                            color: t.red, size: 18),
                        const SizedBox(width: 8),
                        Text('DELETE PROFILE',
                            style: TextStyle(
                                color: t.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                letterSpacing: 1.0)),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}
