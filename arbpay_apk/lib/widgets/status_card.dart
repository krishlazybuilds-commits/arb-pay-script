import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';

const _green   = Color(0xFFFFD600);
const _surface = Color(0xFFF5F5F5);
const _border  = Color(0xFFE0E0E0);
const _textMain= Color(0xFF212121);
const _textSub = Color(0xFF757575);

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
    return Consumer<AppState>(
      builder: (context, state, _) {
        final info = _statusInfo(state.status);
        final isActive = state.status == BotStatus.running ||
            state.status == BotStatus.connecting ||
            state.status == BotStatus.loggingIn ||
            state.status == BotStatus.capturing ||
            state.status == BotStatus.cloudflare;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: info.color.withValues(alpha: 0.4)),
            boxShadow: [
              BoxShadow(
                color: info.color.withValues(alpha: 0.06),
                blurRadius: 16, spreadRadius: 2,
              )
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
                      boxShadow: isActive ? [
                        BoxShadow(
                          color: info.color.withValues(alpha: 0.35),
                          blurRadius: 8 * _pulseAnim.value,
                          spreadRadius: 2,
                        )
                      ] : null,
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
                          style: const TextStyle(color: _textSub, fontSize: 11)),
                  ],
                ),
              ),
              _StatChip(label: 'Rounds', value: '${state.rounds}'),
              const SizedBox(width: 8),
              _StatChip(label: 'Wins', value: '${state.successCount}',
                  color: _green),
            ],
          ),
        );
      },
    );
  }

  _StatusInfo _statusInfo(BotStatus status) {
    switch (status) {
      case BotStatus.idle:
        return _StatusInfo('IDLE', const Color(0xFFBDBDBD));
      case BotStatus.connecting:
        return _StatusInfo('CONNECTING', const Color(0xFF1E88E5));
      case BotStatus.cloudflare:
        return _StatusInfo('CF CHALLENGE', const Color(0xFFF9A825));
      case BotStatus.loggingIn:
        return _StatusInfo('LOGGING IN', const Color(0xFF1E88E5));
      case BotStatus.capturing:
        return _StatusInfo('CAPTURING TOKEN', const Color(0xFFFB8C00));
      case BotStatus.running:
        return _StatusInfo('RUNNING', const Color(0xFFFFD600));
      case BotStatus.qrReady:
        return _StatusInfo('QR READY — PAY NOW!', const Color(0xFFFFD600));
      case BotStatus.success:
        return _StatusInfo('SUCCESS', const Color(0xFFFFD600));
      case BotStatus.error:
        return _StatusInfo('ERROR', const Color(0xFFE53935));
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
  const _StatChip({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  color: color ?? _textMain,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
          Text(label,
              style: const TextStyle(color: _textSub, fontSize: 9)),
        ],
      ),
    );
  }
}
