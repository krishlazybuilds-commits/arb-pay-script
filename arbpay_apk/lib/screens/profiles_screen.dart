import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import '../models/profile.dart';
import '../services/profile_store.dart';
import '../theme/app_theme.dart';
import 'profile_edit_screen.dart';

/// Full-screen list of saved profiles: select, edit, add, delete.
class ProfilesScreen extends StatelessWidget {
  const ProfilesScreen({super.key});

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
            title: Text('Profiles',
                style: TextStyle(
                    color: t.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
            actions: [
              IconButton(
                tooltip: 'Add profile',
                icon: Icon(Icons.add_rounded, color: t.yellow, size: 24),
                onPressed: () => _openEditor(context),
              ),
              const SizedBox(width: 8),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(height: 0.5, color: t.border),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
            children: [
              Text(
                'Switch between your saved accounts without retyping anything. '
                'Each profile keeps its own password, amount range and payment mode.',
                style: TextStyle(color: t.textSub, fontSize: 12.5, height: 1.5),
              ),
              const SizedBox(height: 18),
              for (final p in state.profiles) ...[
                _ProfileTile(
                  profile: p,
                  active: p.id == state.activeProfileId,
                  canDelete: state.profileCount > 1,
                  onSelect: () async {
                    state.selectProfile(p.id);
                    await ProfileStore.persist(state);
                  },
                  onEdit: () =>
                      _openEditor(context, existing: p),
                  onDelete: () async {
                    state.deleteProfile(p.id);
                    await ProfileStore.persist(state);
                  },
                ),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 8),
              _AddButton(t: t, onTap: () => _openEditor(context)),
            ],
          ),
        );
      },
    );
  }

  static Future<void> _openEditor(BuildContext context, {Profile? existing}) {
    final state = context.read<AppState>();
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: state,
          child: ProfileEditScreen(existing: existing),
        ),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final Profile profile;
  final bool active;
  final bool canDelete;
  final VoidCallback onSelect;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProfileTile({
    required this.profile,
    required this.active,
    required this.canDelete,
    required this.onSelect,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final t = AppTheme(state.isDark);
    final subtitle = profile.phone.isEmpty
        ? 'Not set up yet'
        : '${profile.maskedPhone}  ·  ₹${profile.amountMin}–${profile.amountMax}';
    final modeLabel =
        profile.paymentMode == PaymentMode.bank ? 'BANK' : 'UPI';

    return GestureDetector(
      onTap: onSelect,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: t.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: active ? t.yellow.withValues(alpha: 0.6) : t.border,
            width: active ? 1.5 : 1,
          ),
        ),
        child: Row(children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active ? t.yellow : t.yellowDim,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(profile.initial,
                style: TextStyle(
                    color: active ? t.bg : t.yellow,
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Flexible(
                    child: Text(profile.name,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: t.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: t.bg,
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: t.border),
                    ),
                    child: Text(modeLabel,
                        style: TextStyle(
                            color: t.yellow,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8)),
                  ),
                ]),
                const SizedBox(height: 4),
                Text(subtitle,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: t.textSub, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (active)
            Icon(Icons.check_circle_rounded, color: t.yellow, size: 22)
          else
            Icon(Icons.chevron_right_rounded, color: t.textDim, size: 22),
          const SizedBox(width: 4),
          _IconAction(
            icon: Icons.edit_outlined,
            color: t.textSub,
            tooltip: 'Edit ${profile.name}',
            onTap: onEdit,
          ),
          if (canDelete)
            _IconAction(
              icon: Icons.delete_outline_rounded,
              color: t.textDim,
              tooltip: 'Delete ${profile.name}',
              onTap: onDelete,
            ),
        ]),
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;
  const _IconAction({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkResponse(
        onTap: onTap,
        radius: 22,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: color, size: 18),
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final AppTheme t;
  final VoidCallback onTap;
  const _AddButton({required this.t, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: t.yellowDim,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: t.yellow.withValues(alpha: 0.4)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.add_rounded, color: t.yellow, size: 20),
          const SizedBox(width: 8),
          Text('ADD PROFILE',
              style: TextStyle(
                  color: t.yellow,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: 1.0)),
        ]),
      ),
    );
  }
}

/// Quick profile switcher shown from the home screen header.
Future<void> showProfilePicker(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) {
      final state = context.read<AppState>();
      return ChangeNotifierProvider.value(
        value: state,
        child: Consumer<AppState>(
          builder: (context, s, _) {
            final t = AppTheme(s.isDark);
            return Container(
              decoration: BoxDecoration(
                color: t.surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              child: SafeArea(
                top: false,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                        color: t.textDim,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                  Row(children: [
                    Icon(Icons.switch_account_rounded,
                        color: t.yellow, size: 16),
                    const SizedBox(width: 8),
                    Text('Switch account',
                        style: TextStyle(
                            color: t.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 15)),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChangeNotifierProvider.value(
                              value: s,
                              child: const ProfilesScreen(),
                            ),
                          ),
                        );
                      },
                      child: Text('MANAGE',
                          style: TextStyle(
                              color: t.textSub,
                              fontSize: 11,
                              letterSpacing: 1)),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  for (final p in s.profiles)
                    _PickerRow(
                      profile: p,
                      active: p.id == s.activeProfileId,
                      t: t,
                      onTap: () async {
                        s.selectProfile(p.id);
                        await ProfileStore.persist(s);
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                    ),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChangeNotifierProvider.value(
                            value: s,
                            child: const ProfileEditScreen(),
                          ),
                        ),
                      );
                    },
                    child: Container(
                      height: 50,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: t.yellowDim,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: t.yellow.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_rounded,
                                color: t.yellow, size: 18),
                            const SizedBox(width: 6),
                            Text('New profile',
                                style: TextStyle(
                                    color: t.yellow,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13)),
                          ]),
                    ),
                  ),
                ]),
              ),
            );
          },
        ),
      );
    },
  );
}

class _PickerRow extends StatelessWidget {
  final Profile profile;
  final bool active;
  final AppTheme t;
  final VoidCallback onTap;
  const _PickerRow({
    required this.profile,
    required this.active,
    required this.t,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: active ? t.yellowDim : t.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: active ? t.yellow.withValues(alpha: 0.5) : t.border),
        ),
        child: Row(children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active ? t.yellow : t.bg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(profile.initial,
                style: TextStyle(
                    color: active ? t.bg : t.yellow,
                    fontWeight: FontWeight.bold,
                    fontSize: 15)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(profile.name,
                    style: TextStyle(
                        color: t.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  profile.phone.isEmpty
                      ? 'Not set up yet'
                      : profile.maskedPhone,
                  style: TextStyle(color: t.textSub, fontSize: 11.5),
                ),
              ],
            ),
          ),
          if (active)
            Icon(Icons.check_circle_rounded, color: t.yellow, size: 20),
        ]),
      ),
    );
  }
}
