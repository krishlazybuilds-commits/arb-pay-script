import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import '../theme/app_theme.dart';

class LogPanel extends StatelessWidget {
  final AppTheme t;
  const LogPanel({super.key, required this.t});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final logs = state.logs;
        return Container(
          decoration: BoxDecoration(
            color: t.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: t.border),
          ),
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(children: [
                Icon(Icons.terminal, color: t.yellow, size: 14),
                const SizedBox(width: 8),
                Text('LIVE LOG', style: TextStyle(color: t.yellow, fontSize: 11,
                  fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    if (logs.isEmpty) return;
                    Clipboard.setData(ClipboardData(
                      text: logs.reversed.map((e) => '[${e.time}] ${e.message}').join('\n')));
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('${logs.length} lines copied',
                        style: TextStyle(color: t.bg)),
                      backgroundColor: t.yellow,
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ));
                  },
                  child: Text('COPY', style: TextStyle(color: t.textSub, fontSize: 10, letterSpacing: 1)),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => state.clearLogs(),
                  child: Text('CLEAR', style: TextStyle(color: t.textSub, fontSize: 10, letterSpacing: 1)),
                ),
              ]),
            ),
            Divider(color: t.border, height: 1),
            Expanded(
              child: logs.isEmpty
                  ? Center(child: Text('No logs yet',
                      style: TextStyle(color: t.textDim, fontSize: 13)))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      itemCount: logs.length,
                      itemBuilder: (_, i) => _LogRow(entry: logs[i], t: t),
                    ),
            ),
          ]),
        );
      },
    );
  }
}

class _LogRow extends StatelessWidget {
  final LogEntry entry;
  final AppTheme t;
  const _LogRow({required this.entry, required this.t});

  Color get _color {
    switch (entry.level) {
      case LogLevel.success: return t.logSuccess;
      case LogLevel.warning: return t.logWarning;
      case LogLevel.error:   return t.logError;
      case LogLevel.info:    return t.logInfo;
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
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(entry.time, style: TextStyle(color: t.textDim, fontSize: 10, fontFamily: 'monospace')),
        const SizedBox(width: 8),
        Icon(_icon, size: 11, color: _color),
        const SizedBox(width: 6),
        Expanded(child: Text(entry.message, style: TextStyle(
          color: _color, fontSize: 12, fontFamily: 'monospace', height: 1.4))),
      ]),
    );
  }
}
