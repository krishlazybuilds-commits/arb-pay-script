import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../models/app_state.dart';
import '../services/arbpay_service.dart';
import '../widgets/log_panel.dart';
import 'settings_screen.dart';

Future<void> _clearWebViewSession() async {
  try { await CookieManager.instance().deleteAllCookies(); } catch (_) {}
  try { await WebStorageManager.instance().deleteAllData(); } catch (_) {}
}

const kBuildVersion = 'v1.0.7';

// ── Design tokens ──────────────────────────────────────────────────────────────
const _bg       = Color(0xFF0A0A0F);
const _surface  = Color(0xFF13131A);
const _card     = Color(0xFF1C1C26);
const _border   = Color(0xFF2A2A38);
const _yellow   = Color(0xFFFFCC00);
const _yellowDim= Color(0x33FFCC00);
const _white    = Color(0xFFFFFFFF);
const _grey     = Color(0xFF8888A0);
const _greyDim  = Color(0xFF3A3A50);
const _red      = Color(0xFFFF4444);
const _green    = Color(0xFF00E676);

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
  int  _webViewKey  = 0;

  final _phoneCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _obscurePass = true;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    final state = context.read<AppState>();
    _phoneCtrl.text = state.phone;
    _passCtrl.text  = state.password;

    _pulseCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _service.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _captureToken() async {
    final state = context.read<AppState>();
    state.phone    = _phoneCtrl.text.trim();
    state.password = _passCtrl.text;
    await _clearWebViewSession();
    setState(() {
      _webViewKey++;
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

  void _restartFlow() {
    final state = context.read<AppState>();
    state.reset();
    state.clearLogs();
    _service.stop();
    setState(() {
      _isRunning   = false;
      _showWebView = false;
      _loginReady  = false;
      _webViewKey++;
      _webController = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: Consumer<AppState>(
            builder: (context, state, _) => _showWebView
                ? _buildWebViewStep(state)
                : _buildMainStep(state),
          ),
        ),
      ),
    );
  }

  // ── Main screen ────────────────────────────────────────────────────────────
  Widget _buildMainStep(AppState state) {
    return Column(
      children: [
        _buildHeader(state),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                _buildStatusBanner(state),
                const SizedBox(height: 16),
                _buildStatsRow(state),
                const SizedBox(height: 20),
                _buildSectionLabel('CREDENTIALS'),
                const SizedBox(height: 10),
                _buildInputField(
                  controller: _phoneCtrl,
                  label: 'Phone / Username',
                  icon: Icons.phone_android_rounded,
                  keyboardType: TextInputType.phone,
                  enabled: !_isRunning,
                ),
                const SizedBox(height: 10),
                _buildInputField(
                  controller: _passCtrl,
                  label: 'Password',
                  icon: Icons.lock_outline_rounded,
                  obscure: _obscurePass,
                  enabled: !_isRunning,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: _greyDim, size: 18),
                    onPressed: () => setState(() => _obscurePass = !_obscurePass),
                  ),
                ),
                const SizedBox(height: 20),
                _buildActionButtons(state),
                const SizedBox(height: 20),
                _buildSectionLabel('LIVE LOG'),
                const SizedBox(height: 10),
                SizedBox(height: 280, child: const LogPanel()),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader(AppState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: _bg,
        border: Border(bottom: BorderSide(color: _border, width: 0.5)),
      ),
      child: Row(
        children: [
          // Logo mark
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assets/images/app_icon.png',
                width: 38, height: 38, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('ARBPay Bot',
                style: TextStyle(color: _white, fontWeight: FontWeight.bold, fontSize: 16)),
              Row(
                children: [
                  Text('Auto Buy Engine',
                    style: TextStyle(color: _grey, fontSize: 10, letterSpacing: 0.5)),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _yellowDim,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: _yellow.withValues(alpha: 0.4)),
                    ),
                    child: Text(kBuildVersion,
                      style: const TextStyle(
                        color: _yellow, fontSize: 9,
                        fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          // Theme toggle
          GestureDetector(
            onTap: () async {
              state.toggleTheme();
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('isDark', state.isDark);
            },
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _border),
              ),
              child: Icon(
                state.isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                color: _yellow, size: 18),
            ),
          ),
          const SizedBox(width: 8),
          // Mode badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _border),
            ),
            child: Row(
              children: [
                Icon(
                  state.paymentMode == PaymentMode.bank
                      ? Icons.account_balance : Icons.currency_rupee,
                  color: _yellow, size: 12),
                const SizedBox(width: 5),
                Text(
                  state.paymentMode == PaymentMode.bank ? 'BANK' : 'UPI',
                  style: const TextStyle(
                    color: _yellow, fontSize: 10,
                    fontWeight: FontWeight.bold, letterSpacing: 0.8)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _isRunning ? null : () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChangeNotifierProvider.value(
                  value: state, child: const SettingsScreen()),
              ),
            ).then((_) {
              if (mounted) {
                final s = context.read<AppState>();
                _phoneCtrl.text = s.phone;
                _passCtrl.text  = s.password;
              }
            }),
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _border),
              ),
              child: Icon(Icons.tune_rounded,
                color: _isRunning ? _greyDim : _grey, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  // ── Status banner ──────────────────────────────────────────────────────────
  Widget _buildStatusBanner(AppState state) {
    final info = _statusInfo(state.status);
    final isActive = [
      BotStatus.running, BotStatus.capturing,
      BotStatus.connecting, BotStatus.loggingIn,
    ].contains(state.status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: info.color.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: info.color.withValues(alpha: 0.06),
            blurRadius: 20, spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          // Pulse dot
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, __) => Container(
              width: 10, height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: info.color.withValues(alpha: isActive ? _pulseAnim.value : 0.8),
                boxShadow: isActive ? [
                  BoxShadow(
                    color: info.color.withValues(alpha: 0.4 * _pulseAnim.value),
                    blurRadius: 10, spreadRadius: 2,
                  ),
                ] : null,
              ),
            ),
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
                    fontSize: 14, letterSpacing: 0.8)),
                if (state.currentOrder.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text('Order: ${state.currentOrder}',
                    style: TextStyle(color: _grey, fontSize: 11,
                      fontFamily: 'monospace')),
                ],
              ],
            ),
          ),
          // Range chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _bg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _border),
            ),
            child: Column(
              children: [
                Text('₹${state.amountMin}–₹${state.amountMax}',
                  style: const TextStyle(
                    color: _white, fontSize: 11, fontWeight: FontWeight.w600)),
                Text('RANGE', style: TextStyle(color: _grey, fontSize: 8,
                  letterSpacing: 0.8)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Stats row ──────────────────────────────────────────────────────────────
  Widget _buildStatsRow(AppState state) {
    return Row(
      children: [
        _StatCard(label: 'ATTEMPTS', value: '${state.attempts}',
          icon: Icons.refresh_rounded, color: _grey),
        const SizedBox(width: 10),
        _StatCard(label: 'ROUNDS', value: '${state.rounds}',
          icon: Icons.loop_rounded, color: _yellow),
        const SizedBox(width: 10),
        _StatCard(label: 'WINS', value: '${state.successCount}',
          icon: Icons.emoji_events_rounded, color: _green),
      ],
    );
  }

  // ── Action buttons ─────────────────────────────────────────────────────────
  Widget _buildActionButtons(AppState state) {
    return Column(
      children: [
        if (!_isRunning && state.status != BotStatus.qrReady)
          _PrimaryButton(
            label: 'CAPTURE TOKEN',
            icon: Icons.fingerprint_rounded,
            onTap: _captureToken,
          ),

        if (_isRunning)
          _OutlineButton(
            label: 'STOP BOT',
            icon: Icons.stop_circle_outlined,
            color: _red,
            onTap: _stopBot,
          ),

        if (!_isRunning && state.status == BotStatus.qrReady) ...[
          _PrimaryButton(
            label: 'CAPTURE TOKEN',
            icon: Icons.fingerprint_rounded,
            onTap: _captureToken,
          ),
          const SizedBox(height: 10),
          _OutlineButton(
            label: 'RESTART FLOW',
            icon: Icons.replay_rounded,
            color: _yellow,
            onTap: _restartFlow,
          ),
        ],
      ],
    );
  }

  // ── Section label ──────────────────────────────────────────────────────────
  Widget _buildSectionLabel(String label) {
    return Text(label,
      style: TextStyle(
        color: _grey, fontSize: 10,
        fontWeight: FontWeight.bold, letterSpacing: 1.5));
  }

  // ── Input field ────────────────────────────────────────────────────────────
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
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        enabled: enabled,
        style: const TextStyle(color: _white, fontSize: 15),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: _greyDim, size: 20),
          suffixIcon: suffixIcon,
          labelText: label,
          labelStyle: TextStyle(color: _grey, fontSize: 13),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        ),
      ),
    );
  }

  // ── WebView step ───────────────────────────────────────────────────────────
  Widget _buildWebViewStep(AppState state) {
    return Column(
      children: [
        // WebView header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: _bg,
          child: Row(
            children: [
              GestureDetector(
                onTap: () => setState(() { _showWebView = false; _loginReady = false; }),
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: _card, borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _border),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: _grey, size: 16),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Login to ARBPay',
                  style: TextStyle(color: _white, fontWeight: FontWeight.bold,
                    fontSize: 16)),
              ),
              GestureDetector(
                onTap: () => _showLogsSheet(state),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _yellowDim,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _yellow.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.terminal, color: _yellow, size: 13),
                      SizedBox(width: 5),
                      Text('LOGS', style: TextStyle(
                        color: _yellow, fontSize: 11,
                        fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(height: 0.5, color: _border),
        // Hint bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: _surface,
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: _yellow, size: 15),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Log in below, then tap "Run Bot" once you reach the home page.',
                  style: TextStyle(color: _grey, fontSize: 12)),
              ),
            ],
          ),
        ),
        // WebView
        Expanded(
          child: ClipRRect(
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
              onWebViewCreated: (c) { _webController = c; _service.init(c, state); },
              onLoadStop: (c, url) async {
                _webController = c;
                await _handleUrlChange(c, url?.toString() ?? '');
              },
              onUpdateVisitedHistory: (c, url, _) async {
                await _handleUrlChange(c, url?.toString() ?? '');
              },
            ),
          ),
        ),
        // Bottom action bar
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          decoration: BoxDecoration(
            color: _bg,
            border: const Border(top: BorderSide(color: _border, width: 0.5)),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _loginReady && !_isRunning
                ? _PrimaryButton(
                    key: const ValueKey('run'),
                    label: 'RUN BOT',
                    icon: Icons.bolt_rounded,
                    onTap: _completeCaptureAndRun,
                  )
                : Container(
                    key: const ValueKey('wait'),
                    height: 56,
                    decoration: BoxDecoration(
                      color: _card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 14, height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: _grey,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(_isRunning ? 'Running...' : 'Waiting for login...',
                          style: TextStyle(color: _grey, fontSize: 14)),
                      ],
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  void _showLogsSheet(AppState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: state,
        child: _LogsSheet(),
      ),
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
          if (!phoneEl) phoneEl = inputs.find(function(i){
            return i.type !== 'password' && i.type !== 'hidden' &&
                   i.type !== 'submit' && i.type !== 'checkbox' && i.type !== 'radio';
          });
          var passEl = inputs.find(function(i){ return i.type === 'password'; });
          if (!phoneEl && !passEl) return 'NO_INPUTS_AT_ALL';
          if (!phoneEl) return 'NO_PHONE_INPUT';
          if (!passEl)  return 'NO_PASS_INPUT';
          nativeSet(phoneEl, "$safePhone");
          nativeSet(passEl,  "$safePass");
          return 'FILLED';
        })();
      ''');
      final res = result?.toString().replaceAll('"', '') ?? '';
      if (res.startsWith('FILLED')) {
        appState.addLog('Autofill success', level: LogLevel.success);
        break;
      }
      if (attempt == 14) appState.addLog('Autofill failed: $res', level: LogLevel.warning);
    }
  }

  _StatusInfo _statusInfo(BotStatus status) {
    switch (status) {
      case BotStatus.idle:       return _StatusInfo('IDLE', _greyDim);
      case BotStatus.connecting: return _StatusInfo('CONNECTING', const Color(0xFF42A5F5));
      case BotStatus.cloudflare: return _StatusInfo('CF CHALLENGE', const Color(0xFFFFA726));
      case BotStatus.loggingIn:  return _StatusInfo('LOGGING IN', const Color(0xFF42A5F5));
      case BotStatus.capturing:  return _StatusInfo('CAPTURING TOKEN', _yellow);
      case BotStatus.running:    return _StatusInfo('RUNNING', _yellow);
      case BotStatus.qrReady:    return _StatusInfo('QR READY — PAY NOW', _green);
      case BotStatus.success:    return _StatusInfo('SUCCESS', _green);
      case BotStatus.error:      return _StatusInfo('ERROR', _red);
    }
  }
}

// ── Stat card ──────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.label, required this.value,
    required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(height: 8),
            Text(value,
              style: TextStyle(
                color: color, fontSize: 22,
                fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(label,
              style: const TextStyle(
                color: _grey, fontSize: 9, letterSpacing: 1.2)),
          ],
        ),
      ),
    );
  }
}

// ── Primary button ─────────────────────────────────────────────────────────────
class _PrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _PrimaryButton({super.key, required this.label,
    required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity, height: 56,
        decoration: BoxDecoration(
          color: _yellow,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _yellow.withValues(alpha: 0.25),
              blurRadius: 20, spreadRadius: 0, offset: const Offset(0, 6)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: _bg, size: 22),
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(
              color: _bg, fontWeight: FontWeight.bold,
              fontSize: 15, letterSpacing: 1.2)),
          ],
        ),
      ),
    );
  }
}

// ── Outline button ─────────────────────────────────────────────────────────────
class _OutlineButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _OutlineButton({required this.label, required this.icon,
    required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity, height: 56,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 10),
            Text(label, style: TextStyle(
              color: color, fontWeight: FontWeight.bold,
              fontSize: 15, letterSpacing: 1.2)),
          ],
        ),
      ),
    );
  }
}

// ── Status info ────────────────────────────────────────────────────────────────
class _StatusInfo {
  final String label;
  final Color color;
  _StatusInfo(this.label, this.color);
}

// ── Logs bottom sheet ──────────────────────────────────────────────────────────
class _LogsSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final logs = state.logs;
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: _greyDim, borderRadius: BorderRadius.circular(2)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                child: Row(
                  children: [
                    const Icon(Icons.terminal, color: _yellow, size: 16),
                    const SizedBox(width: 8),
                    const Text('Live Log', style: TextStyle(
                      color: _yellow, fontSize: 15,
                      fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        if (logs.isEmpty) return;
                        Clipboard.setData(ClipboardData(
                          text: logs.reversed.map((e) => '[${e.time}] ${e.message}').join('\n')));
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('${logs.length} lines copied',
                            style: const TextStyle(color: _bg)),
                          backgroundColor: _yellow,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ));
                      },
                      child: const Text('COPY', style: TextStyle(
                        color: _grey, fontSize: 11, letterSpacing: 1)),
                    ),
                    const SizedBox(width: 14),
                    GestureDetector(
                      onTap: () => state.clearLogs(),
                      child: const Text('CLEAR', style: TextStyle(
                        color: _grey, fontSize: 11, letterSpacing: 1)),
                    ),
                    const SizedBox(width: 14),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.close_rounded, color: _grey, size: 20),
                    ),
                  ],
                ),
              ),
              const Divider(color: _border, height: 1),
              Expanded(
                child: logs.isEmpty
                    ? Center(child: Text('No logs yet',
                        style: TextStyle(color: _greyDim, fontSize: 13)))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: logs.length,
                        itemBuilder: (_, i) {
                          final e = logs[i];
                          final color = _logColor(e.level);
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(e.time, style: const TextStyle(
                                  color: _greyDim, fontSize: 10, fontFamily: 'monospace')),
                                const SizedBox(width: 8),
                                Icon(_logIcon(e.level), size: 11, color: color),
                                const SizedBox(width: 6),
                                Expanded(child: Text(e.message, style: TextStyle(
                                  color: color, fontSize: 12,
                                  fontFamily: 'monospace', height: 1.4))),
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

  Color _logColor(LogLevel l) {
    switch (l) {
      case LogLevel.success: return const Color(0xFF00E676);
      case LogLevel.warning: return const Color(0xFFFFA726);
      case LogLevel.error:   return const Color(0xFFFF4444);
      case LogLevel.info:    return const Color(0xFF8888A0);
    }
  }

  IconData _logIcon(LogLevel l) {
    switch (l) {
      case LogLevel.success: return Icons.check_circle_outline;
      case LogLevel.warning: return Icons.warning_amber_outlined;
      case LogLevel.error:   return Icons.error_outline;
      case LogLevel.info:    return Icons.info_outline;
    }
  }
}
