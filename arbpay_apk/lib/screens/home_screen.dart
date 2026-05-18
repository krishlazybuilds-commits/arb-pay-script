import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../models/app_state.dart';
import '../services/arbpay_service.dart';
import '../widgets/log_panel.dart';
import '../widgets/status_card.dart';
import 'settings_screen.dart';

// Clears all WebView cookies + web storage so every capture starts fresh
Future<void> _clearWebViewSession() async {
  try {
    await CookieManager.instance().deleteAllCookies();
  } catch (_) {}
  try {
    await WebStorageManager.instance().deleteAllData();
  } catch (_) {}
}

// ── Build version (bump every time a new APK is built) ─────────────────────────
const kBuildVersion = 'v1.0.7';

// ── Palette ────────────────────────────────────────────────────────────────────
const _green     = Color(0xFFFFD600);
const _greenLight= Color(0xFFFFEA00);
const _bg        = Colors.white;
const _surface   = Color(0xFFF5F5F5);
const _border    = Color(0xFFE0E0E0);
const _textMain  = Color(0xFF212121);
const _textSub   = Color(0xFF757575);
const _textHint  = Color(0xFFBDBDBD);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final ArbPayService _service = ArbPayService();
  InAppWebViewController? _webController;

  bool _showWebView = false;
  bool _loginReady  = false;
  bool _isRunning   = false;
  int  _webViewKey  = 0;   // incremented each capture → forces a brand-new WebView

  final _phoneCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _obscurePass = true;

  @override
  void initState() {
    super.initState();
    final state = context.read<AppState>();
    _phoneCtrl.text = state.phone;
    _passCtrl.text  = state.password;
  }

  @override
  void dispose() {
    _service.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _captureToken() async {
    final state = context.read<AppState>();
    state.phone    = _phoneCtrl.text.trim();
    state.password = _passCtrl.text;
    await _clearWebViewSession();          // wipe cookies + storage
    setState(() {
      _webViewKey++;                       // forces a completely new WebView
      _webController = null;
      _showWebView   = true;
      _loginReady    = false;
    });
  }

  Future<void> _completeCaptureAndRun() async {
    final state = context.read<AppState>();
    setState(() => _isRunning = true);
    state.setStatus(BotStatus.capturing);
    state.addLog('Capturing token from session...', level: LogLevel.info);

    if (_webController != null) _service.init(_webController!, state);

    await _service.captureTokenAndRun(
      state.phone, state.password, state.amountMin, state.amountMax,
    );

    setState(() { _isRunning = false; _showWebView = false; _loginReady = false; });
  }

  void _stopBot() {
    _service.stop();
    setState(() { _isRunning = false; _showWebView = false; _loginReady = false; });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: Consumer<AppState>(
            builder: (context, state, _) => Column(
              children: [
                _buildTopBar(state),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _showWebView
                        ? _buildWebViewStep(state)
                        : _buildCredentialsStep(state),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Top Bar ────────────────────────────────────────────────────────────────
  Widget _buildTopBar(AppState state) {
    return Container(
      decoration: const BoxDecoration(
        color: _bg,
        border: Border(bottom: BorderSide(color: _border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: _green,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Text('A', style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('ARBPay Bot', style: TextStyle(
                color: _textMain, fontWeight: FontWeight.bold, fontSize: 16)),
              Row(
                children: [
                  const Text('Auto Buy Engine', style: TextStyle(
                    color: _textSub, fontSize: 10, letterSpacing: 0.5)),
                  const SizedBox(width: 6),
                  const _BuildBadge(),
                ],
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            onPressed: _isRunning ? null : () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChangeNotifierProvider.value(
                  value: state,
                  child: const SettingsScreen(),
                ),
              ),
            ),
            icon: Icon(Icons.settings_outlined,
              color: _isRunning ? _textHint : _textSub, size: 22),
          ),
        ],
      ),
    );
  }

  // ── Credentials Step ──────────────────────────────────────────────────────
  Widget _buildCredentialsStep(AppState state) {
    return Column(
      children: [
        const SizedBox(height: 16),
        const StatusCard(),
        const SizedBox(height: 16),

        Row(
          children: [
            _InfoChip(icon: Icons.currency_rupee, label: 'Range',
              value: '₹${state.amountMin} - ₹${state.amountMax}'),
            const SizedBox(width: 8),
            _InfoChip(icon: Icons.refresh, label: 'Attempts',
              value: '${state.attempts}'),
          ],
        ),
        const SizedBox(height: 20),

        _buildInputField(
          controller: _phoneCtrl,
          label: 'Phone / Username',
          icon: Icons.phone_android_rounded,
          keyboardType: TextInputType.phone,
          enabled: !_isRunning,
        ),
        const SizedBox(height: 12),

        _buildInputField(
          controller: _passCtrl,
          label: 'Password',
          icon: Icons.lock_outline_rounded,
          obscure: _obscurePass,
          enabled: !_isRunning,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: _textHint, size: 20),
            onPressed: () => setState(() => _obscurePass = !_obscurePass),
          ),
        ),
        const SizedBox(height: 20),

        if (!_isRunning)
          _ActionButton(
            label: 'CAPTURE TOKEN',
            icon: Icons.open_in_browser_rounded,
            color: _green,
            textColor: const Color(0xFF1A1A1A),
            onTap: () => _captureToken(),
          ),

        if (_isRunning)
          _ActionButton(
            label: 'STOP BOT',
            icon: Icons.stop_rounded,
            color: Colors.white,
            textColor: Colors.red,
            borderColor: Colors.red.withValues(alpha: 0.4),
            onTap: _stopBot,
          ),

        const SizedBox(height: 14),
        Expanded(child: const LogPanel()),
        const SizedBox(height: 16),
      ],
    );
  }

  // ── Logs popup ────────────────────────────────────────────────────────────
  void _showLogsPopup(AppState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: state,
        child: const _LogsBottomSheet(),
      ),
    );
  }

  // ── WebView Step ──────────────────────────────────────────────────────────
  Widget _buildWebViewStep(AppState state) {
    return Column(
      children: [
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _green.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _green.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: _green, size: 18),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Login below. Once on the home page, press "Complete Capture & Run Script".',
                  style: TextStyle(color: _textSub, fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _showLogsPopup(state),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _green.withValues(alpha: 0.4)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.terminal, color: _green, size: 13),
                      SizedBox(width: 4),
                      Text('LOGS',
                          style: TextStyle(
                            color: _green,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          )),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _border),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: InAppWebView(
                key: ValueKey(_webViewKey),
                initialUrlRequest: URLRequest(url: WebUri('https://arbpay.me')),
                initialSettings: InAppWebViewSettings(
                  javaScriptEnabled: true,
                  domStorageEnabled: true,
                  databaseEnabled: true,
                  userAgent: 'Mozilla/5.0 (Linux; Android 13; Pixel 7) '
                      'AppleWebKit/537.36 (KHTML, like Gecko) '
                      'Chrome/120.0.0.0 Mobile Safari/537.36',
                ),
                onWebViewCreated: (controller) {
                  _webController = controller;
                  _service.init(controller, state);
                },
                onLoadStop: (controller, url) async {
                  _webController = controller;
                  await _handleUrlChange(controller, url?.toString() ?? '');
                },
                onUpdateVisitedHistory: (controller, url, androidIsReload) async {
                  await _handleUrlChange(controller, url?.toString() ?? '');
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              flex: 1,
              child: GestureDetector(
                onTap: () => setState(() { _showWebView = false; _loginReady = false; }),
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _border),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.close_rounded, color: _textSub, size: 20),
                      SizedBox(width: 6),
                      Text('Cancel', style: TextStyle(color: _textSub, fontSize: 14)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: GestureDetector(
                onTap: _loginReady && !_isRunning ? _completeCaptureAndRun : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 52,
                  decoration: BoxDecoration(
                    color: _loginReady && !_isRunning ? _green : _surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _loginReady && !_isRunning ? Colors.transparent : _border),
                    boxShadow: _loginReady && !_isRunning ? [
                      BoxShadow(
                        color: _green.withValues(alpha: 0.3),
                        blurRadius: 16, spreadRadius: 1, offset: const Offset(0, 4),
                      ),
                    ] : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isRunning ? Icons.hourglass_top_rounded : Icons.bolt_rounded,
                        color: _loginReady && !_isRunning ? const Color(0xFF1A1A1A) : _textHint,
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isRunning ? 'Running...' : 'Complete Capture & Run',
                        style: TextStyle(
                          color: _loginReady && !_isRunning ? const Color(0xFF1A1A1A) : _textHint,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Future<void> _handleUrlChange(InAppWebViewController controller, String urlStr) async {
    _webController = controller;
    final isLoginPage = urlStr.contains('login') ||
        urlStr == 'https://arbpay.me/' ||
        urlStr == 'https://arbpay.me/#/' ||
        urlStr.endsWith('arbpay.me');
    if (isLoginPage) {
      await _autoFillLogin(controller);
      if (mounted) setState(() => _loginReady = false);
    } else if (urlStr.contains('arbpay.me') && urlStr.isNotEmpty) {
      if (mounted) setState(() => _loginReady = true);
    }
  }

  Future<void> _autoFillLogin(InAppWebViewController controller) async {
    final phone = _phoneCtrl.text.trim();
    final pass  = _passCtrl.text;
    if (phone.isEmpty || pass.isEmpty) return;

    final appState = context.read<AppState>();

    for (int attempt = 0; attempt < 15; attempt++) {
      await Future.delayed(const Duration(milliseconds: 800));

      final safePhone = phone.replaceAll('"', r'\"');
      final safePass  = pass.replaceAll('"', r'\"');

      final result = await controller.evaluateJavascript(source: '''
        (function() {
          function nativeSet(el, val) {
            var proto = Object.getPrototypeOf(el);
            var desc = Object.getOwnPropertyDescriptor(proto, 'value');
            if (desc && desc.set) { desc.set.call(el, val); } else { el.value = val; }
            el.dispatchEvent(new Event('input',  {bubbles:true}));
            el.dispatchEvent(new Event('change', {bubbles:true}));
            el.dispatchEvent(new Event('blur',   {bubbles:true}));
          }
          var inputs = Array.from(document.querySelectorAll('input'));
          var phoneEl = inputs.find(function(i){
            var hint = ((i.placeholder||'')+(i.name||'')+(i.id||'')).toLowerCase();
            return hint.match(/phone|mobile|user|account|login|tel/) && i.type !== 'password';
          });
          if (!phoneEl) {
            phoneEl = inputs.find(function(i){
              return i.type !== 'password' && i.type !== 'hidden' &&
                     i.type !== 'submit'   && i.type !== 'checkbox' && i.type !== 'radio';
            });
          }
          var passEl = inputs.find(function(i){ return i.type === 'password'; });
          if (!phoneEl && !passEl) return 'NO_INPUTS_AT_ALL';
          if (!phoneEl) return 'NO_PHONE_INPUT';
          if (!passEl)  return 'NO_PASS_INPUT';
          nativeSet(phoneEl, "$safePhone");
          nativeSet(passEl,  "$safePass");
          return 'FILLED:phone_id=' + (phoneEl.id||phoneEl.name||phoneEl.className||'?') +
                 ',pass_id=' + (passEl.id||passEl.name||passEl.className||'?');
        })();
      ''');

      final res = result?.toString().replaceAll('"', '') ?? '';
      debugPrint('[ARBPay] Autofill[$attempt]: $res');
      if (res.startsWith('FILLED')) {
        appState.addLog('Autofill success', level: LogLevel.success);
        break;
      }
      if (attempt == 14) appState.addLog('Autofill failed: $res', level: LogLevel.warning);
    }
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
    bool enabled = true,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        enabled: enabled,
        style: const TextStyle(color: _textMain, fontSize: 15),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: _textHint, size: 20),
          suffixIcon: suffixIcon,
          labelText: label,
          labelStyle: const TextStyle(color: _textSub, fontSize: 13),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        ),
      ),
    );
  }
}

// ── Shared Widgets ───��─────────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoChip({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            Icon(icon, color: _green, size: 14),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(
                  color: _textSub, fontSize: 9, letterSpacing: 0.8)),
                Text(value, style: const TextStyle(
                  color: _textMain, fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Build version badge ────────────────────────────────────────────────────────
class _BuildBadge extends StatelessWidget {
  const _BuildBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: _green,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        kBuildVersion,
        style: TextStyle(
          color: Color(0xFF1A1A1A),
          fontSize: 9,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ── Logs bottom-sheet popup ───────────────────────────────────────────────────
class _LogsBottomSheet extends StatelessWidget {
  const _LogsBottomSheet();

  Color _levelColor(LogLevel level) {
    switch (level) {
      case LogLevel.success: return const Color(0xFF00A844);
      case LogLevel.warning: return const Color(0xFFF57F17);
      case LogLevel.error:   return const Color(0xFFD32F2F);
      case LogLevel.info:    return const Color(0xFF616161);
    }
  }

  IconData _levelIcon(LogLevel level) {
    switch (level) {
      case LogLevel.success: return Icons.check_circle_outline;
      case LogLevel.warning: return Icons.warning_amber_outlined;
      case LogLevel.error:   return Icons.error_outline;
      case LogLevel.info:    return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final logs = state.logs;
        return Container(
          height: MediaQuery.of(context).size.height * 0.72,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                child: Row(
                  children: [
                    const Icon(Icons.terminal, color: _green, size: 18),
                    const SizedBox(width: 8),
                    const Text('Live Log',
                        style: TextStyle(
                            color: _green,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0)),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        final logs = state.logs;
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
                    const SizedBox(width: 14),
                    GestureDetector(
                      onTap: () => state.clearLogs(),
                      child: const Text('CLEAR',
                          style: TextStyle(
                              color: _textSub, fontSize: 11, letterSpacing: 1)),
                    ),
                    const SizedBox(width: 14),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.close_rounded,
                          color: _textSub, size: 20),
                    ),
                  ],
                ),
              ),
              const Divider(color: _border, height: 1),
              // Log list
              Expanded(
                child: logs.isEmpty
                    ? const Center(
                        child: Text('No logs yet',
                            style: TextStyle(color: _textHint, fontSize: 13)),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: logs.length,
                        itemBuilder: (context, index) {
                          final entry = logs[index];
                          final color = _levelColor(entry.level);
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 3),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(entry.time,
                                    style: const TextStyle(
                                        color: _textHint,
                                        fontSize: 10,
                                        fontFamily: 'monospace')),
                                const SizedBox(width: 7),
                                Icon(_levelIcon(entry.level),
                                    size: 12, color: color),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(entry.message,
                                      style: TextStyle(
                                          color: color,
                                          fontSize: 12,
                                          fontFamily: 'monospace',
                                          height: 1.4)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color textColor;
  final Color? borderColor;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.textColor,
    required this.onTap,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          border: borderColor != null ? Border.all(color: borderColor!) : null,
          boxShadow: [
            BoxShadow(
              color: color == Colors.white
                  ? Colors.black.withValues(alpha: 0.05)
                  : color.withValues(alpha: 0.3),
              blurRadius: 20, spreadRadius: 2, offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor, size: 24),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(
              color: textColor, fontWeight: FontWeight.bold,
              fontSize: 15, letterSpacing: 1.2,
            )),
          ],
        ),
      ),
    );
  }
}
