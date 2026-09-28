import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_state.dart';
import '../theme/app_theme.dart';
import '../services/icon_service.dart';
import '../widgets/settings_fields.dart';
import 'profiles_screen.dart';
import 'profile_edit_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _toggleTheme(BuildContext context) async {
    final state = context.read<AppState>();
    state.toggleTheme();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDark', state.isDark);
    await IconService.setIcon(isDark: state.isDark);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final t = AppTheme(state.isDark);
        final p = state.activeProfile;
        final modeLabel = state.paymentMode == PaymentMode.bank ? 'BANK' : 'UPI';

        return Scaffold(
          backgroundColor: t.bg,
          appBar: AppBar(
            backgroundColor: t.bg,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, color: t.textSub, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text('Settings', style: TextStyle(
              color: t.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(height: 0.5, color: t.border),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // ── Profiles ──────────────────────────────────────────────
              SectionLabel('Profiles', t),
              const SizedBox(height: 12),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => ChangeNotifierProvider.value(
                    value: state, child: const ProfilesScreen()))),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: t.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: t.border),
                  ),
                  child: Row(children: [
                    Container(
                      width: 42, height: 42,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: t.yellow,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(p.initial, style: TextStyle(
                        color: t.bg, fontWeight: FontWeight.bold, fontSize: 17)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${state.profileCount} saved profile${state.profileCount == 1 ? '' : 's'}',
                          style: TextStyle(color: t.textPrimary,
                            fontSize: 14, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 3),
                        Text('Active: ${p.name}  ·  $modeLabel',
                          style: TextStyle(color: t.textSub, fontSize: 12)),
                      ],
                    )),
                    Icon(Icons.chevron_right_rounded, color: t.textDim, size: 22),
                  ]),
                ),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => ChangeNotifierProvider.value(
                    value: state, child: const ProfileEditScreen()))),
                child: Container(
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: t.yellowDim,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: t.yellow.withValues(alpha: 0.4)),
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.add_rounded, color: t.yellow, size: 18),
                    const SizedBox(width: 6),
                    Text('Add profile', style: TextStyle(
                      color: t.yellow, fontWeight: FontWeight.bold, fontSize: 13)),
                  ]),
                ),
              ),
              const SizedBox(height: 28),

              // ── Appearance ────────────────────────────────────────────
              SectionLabel('Appearance', t),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: t.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: t.border),
                ),
                child: SwitchListTile(
                  value: state.isDark,
                  onChanged: (_) => _toggleTheme(context),
                  activeThumbColor: t.yellow,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  secondary: Icon(
                    state.isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                    color: t.yellow, size: 20),
                  title: Text('Dark theme', style: TextStyle(
                    color: t.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                  subtitle: Text('Also switches the launcher icon',
                    style: TextStyle(color: t.textSub, fontSize: 12)),
                ),
              ),
              const SizedBox(height: 28),

              // ── How it works ──────────────────────────────────────────
              SectionLabel('Payment modes', t),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: t.card, borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: t.border),
                ),
                child: Column(children: [
                  _InfoRow(icon: Icons.currency_rupee_rounded, color: t.yellow, t: t,
                    title: 'OTP / UPI mode',
                    desc: 'Buys UPI orders using bank OTP. Cycles through your bound banks.'),
                  const SizedBox(height: 14),
                  _InfoRow(icon: Icons.account_balance_rounded, color: t.green, t: t,
                    title: 'Bank mode',
                    desc: 'Buys bank transfer orders using direct bank transfer.'),
                  const SizedBox(height: 14),
                  _InfoRow(icon: Icons.info_outline_rounded, color: t.textSub, t: t,
                    title: 'On success',
                    desc: 'When an order is claimed, the QR payment screen appears in the WebView.'),
                ]),
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title, desc;
  final AppTheme t;

  const _InfoRow({required this.icon, required this.color,
    required this.title, required this.desc, required this.t});

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 16),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(
          color: t.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 3),
        Text(desc, style: TextStyle(color: t.textSub, fontSize: 12, height: 1.4)),
      ])),
    ]);
  }
}
