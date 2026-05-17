import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';

const _green    = Color(0xFFFFD600);
const _surface  = Color(0xFFF5F5F5);
const _border   = Color(0xFFE0E0E0);
const _textSub  = Color(0xFF757575);
const _textHint = Color(0xFFBDBDBD);

class LogPanel extends StatelessWidget {
  const LogPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final logs = state.logs;
        return Container(
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _border),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    const Icon(Icons.terminal, color: _green, size: 16),
                    const SizedBox(width: 8),
                    const Text('Live Log',
                        style: TextStyle(
                            color: _green,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2)),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        if (logs.isEmpty) return;
                        final text = logs.reversed
                            .map((e) => '[${e.time}] ${e.message}')
                            .join('\n');
                        Clipboard.setData(ClipboardData(text: text));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${logs.length} log lines copied',
                                style: const TextStyle(color: Color(0xFF1A1A1A))),
                            backgroundColor: _green,
                            duration: const Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                        );
                      },
                      child: const Text('COPY',
                          style: TextStyle(
                              color: _textSub, fontSize: 11, letterSpacing: 1)),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => state.clearLogs(),
                      child: const Text('CLEAR',
                          style: TextStyle(
                              color: _textSub, fontSize: 11, letterSpacing: 1)),
                    ),
                  ],
                ),
              ),
              const Divider(color: _border, height: 1),
              Expanded(
                child: logs.isEmpty
                    ? const Center(
                        child: Text('No logs yet',
                            style: TextStyle(color: _textHint, fontSize: 13)),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        itemCount: logs.length,
                        itemBuilder: (context, index) => _LogRow(entry: logs[index]),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LogRow extends StatelessWidget {
  final LogEntry entry;
  const _LogRow({required this.entry});

  Color get _color {
    switch (entry.level) {
      case LogLevel.success: return const Color(0xFFF9A825);
      case LogLevel.warning: return const Color(0xFFF57F17);
      case LogLevel.error:   return const Color(0xFFD32F2F);
      case LogLevel.info:    return const Color(0xFF616161);
    }
  }

  IconData get _icon {
    switch (entry.level) {
      case LogLevel.success: return Icons.check_circle_outline;
      case LogLevel.warning: return Icons.warning_amber_outlined;
      case LogLevel.error:   return Icons.error_outline;
      case LogLevel.info:    return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(entry.time,
              style: const TextStyle(
                  color: _textHint, fontSize: 10, fontFamily: 'monospace')),
          const SizedBox(width: 8),
          Icon(_icon, size: 12, color: _color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(entry.message,
                style: TextStyle(
                    color: _color, fontSize: 12,
                    fontFamily: 'monospace', height: 1.4)),
          ),
        ],
      ),
    );
  }
}
