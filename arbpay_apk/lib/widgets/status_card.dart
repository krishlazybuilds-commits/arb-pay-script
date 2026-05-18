import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import '../theme/app_theme.dart';

class StatusCard extends StatefulWidget {
  const StatusCard({super.key});

  @override
  State<StatusCard> createState() => _StatusCardState();
}

class _StatusCardState extends State<StatusCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    return Consumer<AppState>(
      builder: (context, state, _) {
        final info = _statusInfo(state.status, t);
        final isActive = state.status == BotStatus.running ||
            state.status == BotStatus.connecting ||
            state.status == BotStatus.loggingIn ||
            state.status == BotStatus.capturing ||
            state.status == BotStatus.cloudflare;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: t.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: info.color.withValues(alpha: 0.4)),
            boxShadow: [
              BoxShadow(
                color: info.color.withValues(alpha: 0.06),
                blurRadius: 16, spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            children: [
              AnimatedBuilder(
                animation: _pulseAnim,
                builder: (context, child) {
                  return Container(
                    width: 12, height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: info.color.withValues(
                          alpha: isActive ? _pulseAnim.value : 0.7),
                      boxShadow: isActive
                          ? [BoxShadow(
                              color: info.color.withValues(alpha: 0.35),
                              blurRadius: 8 * _pulseAnim.value,
                              spreadRadius: 2,
                            )]
                          : null,
                    ),
                  );
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(info.label,
                        style: TextStyle(
                          color: info.color,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          letterSpacing: 0.5,
                        )),
                    if (state.currentOrder.isNotEmpty)
                      Text('Order: ${state.currentOrder}',
                          style: TextStyle(color: t.textSub, fontSize: 11)),
                  ],
                ),
              ),
              _StatChip(label: 'Rounds', value: '${state.rounds}', t: t),
              const SizedBox(width: 8),
              _StatChip(label: 'Wins', value: '${state.successCount}',
                  color: t.green, t: t),
            ],
          ),
        );
      },
    );
  }

  _StatusInfo _statusInfo(BotStatus status, AppTheme t) {
    switch (status) {
      case BotStatus.idle:       return _StatusInfo('IDLE', t.textDim);
      case BotStatus.connecting: return _StatusInfo('CONNECTING', const Color(0xFF42A5F5));
      case BotStatus.cloudflare: return _StatusInfo('CF CHALLENGE', const Color(0xFFFFA726));
      case BotStatus.loggingIn:  return _StatusInfo('LOGGING IN', const Color(0xFF42A5F5));
      case BotStatus.capturing:  return _StatusInfo('CAPTURING TOKEN', t.yellow);
      case BotStatus.running:    return _StatusInfo('RUNNING', t.yellow);
      case BotStatus.qrReady:    return _StatusInfo('QR READY — PAY NOW!', t.green);
      case BotStatus.success:    return _StatusInfo('SUCCESS', t.green);
      case BotStatus.error:      return _StatusInfo('ERROR', t.red);
    }
  }
}

class _StatusInfo {
  final String label;
  final Color color;
  _StatusInfo(this.label, this.color);
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  final AppTheme t;
  const _StatChip({required this.label, required this.value,
    required this.t, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: t.bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: t.border),
      ),
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  color: color ?? t.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
          Text(label,
              style: TextStyle(color: t.textSub, fontSize: 9)),
        ],
      ),
    );
  }
}
