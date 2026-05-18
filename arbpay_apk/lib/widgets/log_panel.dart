import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';

const _yellow   = Color(0xFFFFCC00);
const _bg       = Color(0xFF0A0A0F);
const _card     = Color(0xFF1C1C26);
const _border   = Color(0xFF2A2A38);
const _grey     = Color(0xFF8888A0);
const _greyDim  = Color(0xFF3A3A50);

class LogPanel extends StatelessWidget {
  const LogPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final logs = state.logs;
        return Container(
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _border),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    const Icon(Icons.terminal, color: _yellow, size: 14),
                    const SizedBox(width: 8),
                    const Text('LIVE LOG', style: TextStyle(
                      color: _yellow, fontSize: 11,
                      fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        if (logs.isEmpty) return;
                        final text = logs.reversed
                            .map((e) => '[${e.time}] ${e.message}')
                            .join('\n');
                        Clipboard.setData(ClipboardData(text: text));
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('${logs.length} lines copied',
                            style: const TextStyle(color: Color(0xFF0A0A0F))),
                          backgroundColor: _yellow,
                          duration: const Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        ));
                      },
                      child: const Text('COPY', style: TextStyle(
                        color: _grey, fontSize: 10, letterSpacing: 1)),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => state.clearLogs(),
                      child: const Text('CLEAR', style: TextStyle(
                        color: _grey, fontSize: 10, letterSpacing: 1)),
                    ),
                  ],
                ),
              ),
              Divider(color: _border, height: 1),
              Expanded(
                child: logs.isEmpty
                    ? Center(child: Text('No logs yet',
                        style: TextStyle(color: _greyDim, fontSize: 13)))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        itemCount: logs.length,
                        itemBuilder: (_, i) => _LogRow(entry: logs[i]),
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
      case LogLevel.success: return const Color(0xFF00E676);
      case LogLevel.warning: return const Color(0xFFFFA726);
      case LogLevel.error:   return const Color(0xFFFF4444);
      case LogLevel.info:    return const Color(0xFF8888A0);
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
          Text(entry.time, style: const TextStyle(
            color: _greyDim, fontSize: 10, fontFamily: 'monospace')),
          const SizedBox(width: 8),
          Icon(_icon, size: 11, color: _color),
          const SizedBox(width: 6),
          Expanded(child: Text(entry.message, style: TextStyle(
            color: _color, fontSize: 12,
            fontFamily: 'monospace', height: 1.4))),
        ],
      ),
    );
  }
}
