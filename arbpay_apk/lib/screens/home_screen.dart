import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../models/app_state.dart';
import '../models/profile.dart';
import '../services/arbpay_service.dart';
import '../services/icon_service.dart';
import '../widgets/log_panel.dart';
import '../theme/app_theme.dart';
import 'settings_screen.dart';
import 'profiles_screen.dart';
import 'profile_edit_screen.dart';

Future<void> _clearWebViewSession() async {
  try { await CookieManager.instance().deleteAllCookies(); } catch (_) {}
  try { await WebStorageManager.instance().deleteAllData(); } catch (_) {}
}

const kBuildVersion = 'v1.2.1';

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
  bool _pageLoading = false;
  String _loadError = '';
  int  _entryIndex  = 0;

  // Entry domains. arbpay.me is flaky (and the site itself lists *.top/.vip/.ai
  // as its official domains), so we let the user fall back to another one.
  static const List<String> _entryUrls = [
    'https://arbpay.me',
    'https://arbpay.top',
    'https://arbpay.vip',
    'https://arbpay.ai',
  ];

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
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
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ── Flow ───────────────────────────────────────────────────────────────────
  Future<void> _captureToken() async {
    final state = context.read<AppState>();
    if (!state.activeProfile.isConfigured) {
      await _editProfile(state.activeProfile);
      if (!mounted) return;
      if (!context.read<AppState>().activeProfile.isConfigured) return;
    }
    await _clearWebViewSession();
    setState(() {
      _webViewKey++;
      _webController = null;
      _showWebView = true;
      _loginReady = false;
      _loadError = '';
      _pageLoading = true;
    });
  }

  void _retryPage() {
    setState(() {
      _loadError = '';
      _pageLoading = true;
      _webViewKey++;
      _webController = null;
    });
  }

  void _nextDomain() {
    setState(() {
      _entryIndex = (_entryIndex + 1) % _entryUrls.length;
      _loadError = '';
      _pageLoading = true;
      _webViewKey++;
      _webController = null;
    });
  }

  Future<void> _editProfile(Profile profile) async {
    final state = context.read<AppState>();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: state,
          child: ProfileEditScreen(existing: profile),
        ),
      ),
    );
  }

  Future<void> _completeCaptureAndRun() async {
    final state = context.read<AppState>();
    setState(() => _isRunning = true);
    state.setStatus(BotStatus.capturing);
    state.addLog('Capturing token from session...', level: LogLevel.info);
    if (_webController != null) _service.init(_webController!, state);
    await _service.captureTokenAndRun(
        state.phone, state.password, state.amountMin, state.amountMax);
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
      _isRunning = false;
      _showWebView = false;
      _loginReady = false;
      _webViewKey++;
      _webController = null;
    });
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final t = AppTheme(state.isDark);
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: t.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
          child: Scaffold(
            backgroundColor: t.bg,
            body: SafeArea(
              child: _showWebView ? _buildWebView(state, t) : _buildMain(state, t),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMain(AppState state, AppTheme t) {
    return Column(
      children: [
        _buildHeader(state, t),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                _buildProfileCard(state, t),
                const SizedBox(height: 14),
                _buildStatusBanner(state, t),
                const SizedBox(height: 14),
                _buildStatsRow(state, t),
                const SizedBox(height: 18),
                _buildActions(state, t),
                const SizedBox(height: 20),
                _sectionLabel('LIVE LOG', t),
                const SizedBox(height: 10),
                SizedBox(height: 280, child: LogPanel(t: t)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader(AppState state, AppTheme t) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: t.bg,
        border: Border(bottom: BorderSide(color: t.border, width: 0.5)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              state.isDark
                  ? 'assets/images/app_icon_dark.png'
                  : 'assets/images/app_icon_light.png',
              width: 36, height: 36, fit: BoxFit.cover),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ARBPay Bot', style: TextStyle(
                color: t.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
              Row(children: [
                Text('Auto Buy Engine',
                  style: TextStyle(color: t.textSub, fontSize: 10, letterSpacing: 0.5)),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: t.isDark ? const Color(0x33FFCC00) : const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(kBuildVersion, style: TextStyle(
                    color: t.isDark ? t.yellow : const Color(0xFFFFCC00),
                    fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                ),
              ]),
            ],
          ),
          const Spacer(),
          _headerBtn(
            icon: state.isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            color: t.yellow, t: t,
            onTap: () async {
              state.toggleTheme();
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('isDark', state.isDark);
              await IconService.setIcon(isDark: state.isDark);
            },
          ),
          const SizedBox(width: 8),
          _headerBtn(
            icon: Icons.tune_rounded, color: t.textSub, t: t,
            onTap: _isRunning
                ? null
                : () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => ChangeNotifierProvider.value(
                      value: state, child: const SettingsScreen()))),
          ),
        ],
      ),
    );
  }

  Widget _headerBtn({required IconData icon, required Color color,
      required AppTheme t, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
          color: t.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: t.border),
        ),
        child: Icon(icon, color: onTap == null ? t.textDim : color, size: 18),
      ),
    );
  }

  // ── Active profile card ─────────────────────────────────────────────────────
  Widget _buildProfileCard(AppState state, AppTheme t) {
    final p = state.activeProfile;
    final configured = p.isConfigured;
    final modeLabel = state.paymentMode == PaymentMode.bank ? 'BANK' : 'UPI';

    return Container(
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: configured ? t.yellow.withValues(alpha: 0.35) : t.border,
        ),
      ),
      child: Column(children: [
        // Tappable body → profile picker
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _isRunning ? null : () => showProfilePicker(context),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Container(
                width: 46, height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: t.yellow,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Text(p.initial, style: TextStyle(
                  color: t.bg, fontWeight: FontWeight.bold, fontSize: 19)),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Flexible(child: Text(p.name,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: t.textPrimary,
                        fontSize: 16, fontWeight: FontWeight.bold))),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: t.bg,
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: t.border),
                      ),
                      child: Text(modeLabel, style: TextStyle(
                        color: t.yellow, fontSize: 9,
                        fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                    ),
                  ]),
                  const SizedBox(height: 4),
                  Text(
                    configured
                        ? '${p.maskedPhone}  ·  ₹${p.amountMin}–${p.amountMax}'
                        : 'No login saved — tap to set up',
                    style: TextStyle(
                      color: configured ? t.textSub : t.red,
                      fontSize: 12),
                  ),
                ],
              )),
              const SizedBox(width: 6),
              Column(children: [
                Icon(Icons.unfold_more_rounded, color: t.yellow, size: 20),
                const SizedBox(height: 2),
                Text('SWITCH', style: TextStyle(
                  color: t.textSub, fontSize: 8, letterSpacing: 0.8)),
              ]),
            ]),
          ),
        ),
        Container(height: 0.5, color: t.border),
        // Footer actions
        Row(children: [
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _isRunning ? null : () => _editProfile(p),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.edit_outlined,
                    color: _isRunning ? t.textDim : t.textSub, size: 14),
                  const SizedBox(width: 6),
                  Text('Edit', style: TextStyle(
                    color: _isRunning ? t.textDim : t.textSub,
                    fontSize: 12, fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
          ),
          Container(width: 0.5, height: 24, color: t.border),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _isRunning
                  ? null
                  : () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => ChangeNotifierProvider.value(
                        value: state, child: const ProfilesScreen()))),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.switch_account_rounded,
                    color: _isRunning ? t.textDim : t.textSub, size: 14),
                  const SizedBox(width: 6),
                  Text('All profiles (${state.profileCount})', style: TextStyle(
                    color: _isRunning ? t.textDim : t.textSub,
                    fontSize: 12, fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
          ),
        ]),
      ]),
    );
  }

  // ── Status banner ──────────────────────────────────────────────────────────
  Widget _buildStatusBanner(AppState state, AppTheme t) {
    final info = _statusInfo(state.status, t);
    final isActive = [BotStatus.running, BotStatus.capturing,
      BotStatus.connecting, BotStatus.loggingIn].contains(state.status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: info.color.withValues(alpha: 0.25)),
        boxShadow: [BoxShadow(color: info.color.withValues(alpha: 0.06), blurRadius: 20)],
      ),
      child: Row(children: [
        AnimatedBuilder(
          animation: _pulseAnim,
          builder: (_, __) => Container(
            width: 10, height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: info.color.withValues(alpha: isActive ? _pulseAnim.value : 0.8),
              boxShadow: isActive ? [BoxShadow(
                color: info.color.withValues(alpha: 0.4 * _pulseAnim.value),
                blurRadius: 10, spreadRadius: 2)] : null,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(info.label, style: TextStyle(
              color: info.color, fontWeight: FontWeight.bold,
              fontSize: 14, letterSpacing: 0.8)),
            if (state.currentOrder.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text('Order: ${state.currentOrder}',
                style: TextStyle(color: t.textSub, fontSize: 11, fontFamily: 'monospace')),
            ],
          ],
        )),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: t.bg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: t.border),
          ),
          child: Column(children: [
            Text('₹${state.amountMin}–₹${state.amountMax}',
              style: TextStyle(color: t.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
            Text('RANGE', style: TextStyle(color: t.textSub, fontSize: 8, letterSpacing: 0.8)),
          ]),
        ),
      ]),
    );
  }

  // ── Stats row ──────────────────────────────────────────────────────────────
  Widget _buildStatsRow(AppState state, AppTheme t) {
    return Row(children: [
      _StatCard(label: 'ATTEMPTS', value: '${state.attempts}',
        icon: Icons.refresh_rounded, color: t.textSub, t: t),
      const SizedBox(width: 10),
      _StatCard(label: 'ROUNDS', value: '${state.rounds}',
        icon: Icons.loop_rounded, color: t.yellow, t: t),
      const SizedBox(width: 10),
      _StatCard(label: 'WINS', value: '${state.successCount}',
        icon: Icons.emoji_events_rounded, color: t.green, t: t),
    ]);
  }

  // ── Actions ────────────────────────────────────────────────────────────────
  Widget _buildActions(AppState state, AppTheme t) {
    return Column(children: [
      if (!_isRunning && state.status != BotStatus.qrReady)
        _PrimaryBtn(label: 'CAPTURE TOKEN', icon: Icons.fingerprint_rounded,
          t: t, onTap: _captureToken),
      if (_isRunning)
        _OutlineBtn(label: 'STOP BOT', icon: Icons.stop_circle_outlined,
          color: t.red, t: t, onTap: _stopBot),
      if (!_isRunning && state.status == BotStatus.qrReady) ...[
        _PrimaryBtn(label: 'CAPTURE TOKEN', icon: Icons.fingerprint_rounded,
          t: t, onTap: _captureToken),
        const SizedBox(height: 10),
        _OutlineBtn(label: 'RESTART FLOW', icon: Icons.replay_rounded,
          color: t.yellow, t: t, onTap: _restartFlow),
      ],
    ]);
  }

  Widget _sectionLabel(String label, AppTheme t) {
    return Text(label, style: TextStyle(
      color: t.textSub, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5));
  }

  // ── WebView ────────────────────────────────────────────────────────────────
  Widget _buildWebView(AppState state, AppTheme t) {
    final p = state.activeProfile;
    final domain = _entryUrls[_entryIndex];
    return Column(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: t.bg,
        child: Row(children: [
          _headerBtn(icon: Icons.arrow_back_ios_new_rounded, color: t.textSub, t: t,
            onTap: () => setState(() { _showWebView = false; _loginReady = false; })),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Login to ARBPay',
                style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
              Text('Signing in as ${p.name}',
                style: TextStyle(color: t.textSub, fontSize: 11)),
            ],
          )),
          GestureDetector(
            onTap: () => _showLogsSheet(state, t),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: t.yellowDim, borderRadius: BorderRadius.circular(8),
                border: Border.all(color: t.yellow.withValues(alpha: 0.3)),
              ),
              child: Row(children: [
                Icon(Icons.terminal, color: t.yellow, size: 13),
                const SizedBox(width: 5),
                Text('LOGS', style: TextStyle(color: t.yellow, fontSize: 11,
                  fontWeight: FontWeight.bold, letterSpacing: 0.8)),
              ]),
            ),
          ),
        ]),
      ),
      Container(height: 0.5, color: t.border),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: t.surface,
        child: Row(children: [
          Icon(_loadError.isEmpty ? Icons.info_outline_rounded : Icons.wifi_off_rounded,
            color: _loadError.isEmpty ? t.yellow : t.red, size: 15),
          const SizedBox(width: 8),
          Expanded(child: Text(
            _loadError.isEmpty
                ? 'Log in below, then tap "Run Bot" once you are on the home page.'
                : 'Could not reach $domain. Try again or pick another domain below.',
            style: TextStyle(
              color: _loadError.isEmpty ? t.textSub : t.red, fontSize: 12))),
        ]),
      ),
      Expanded(child: Stack(children: [
        InAppWebView(
          key: ValueKey(_webViewKey),
          initialUrlRequest: URLRequest(url: WebUri(domain)),
          initialSettings: InAppWebViewSettings(
            javaScriptEnabled: true, domStorageEnabled: true, databaseEnabled: true,
            userAgent: 'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 '
                '(KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
          ),
          onWebViewCreated: (c) { _webController = c; _service.init(c, state); },
          onLoadStart: (c, url) {
            if (mounted) setState(() => _pageLoading = true);
          },
          onLoadStop: (c, url) async {
            _webController = c;
            if (mounted) {
              setState(() { _pageLoading = false; _loadError = ''; });
            }
            await _handleUrlChange(c, url?.toString() ?? '');
          },
          onReceivedError: (c, request, error) {
            if (!mounted) return;
            if (request.isForMainFrame != true) return;
            setState(() { _pageLoading = false; _loadError = error.description; });
            state.addLog('Page load failed: ${error.description} (${error.type})',
                level: LogLevel.error);
          },
          onUpdateVisitedHistory: (c, url, _) async =>
              _handleUrlChange(c, url?.toString() ?? ''),
        ),
        // Loading overlay — replaces the blank/black WebView while it connects.
        if (_pageLoading && _loadError.isEmpty)
          Positioned.fill(child: Container(
            color: t.bg.withValues(alpha: 0.9),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              SizedBox(width: 30, height: 30,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: t.yellow)),
              const SizedBox(height: 16),
              Text('Connecting to ARBPay',
                style: TextStyle(color: t.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(domain, style: TextStyle(color: t.textSub, fontSize: 11)),
            ]),
          )),
        // Error state — explicit recovery instead of a silent black screen.
        if (_loadError.isNotEmpty)
          Positioned.fill(child: Container(
            color: t.bg,
            padding: const EdgeInsets.all(28),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.wifi_off_rounded, color: t.red, size: 46),
              const SizedBox(height: 16),
              Text("Couldn't reach ARBPay",
                style: TextStyle(color: t.textPrimary, fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(_loadError, textAlign: TextAlign.center,
                style: TextStyle(color: t.textSub, fontSize: 12.5, height: 1.4)),
              const SizedBox(height: 6),
              Text(domain, style: TextStyle(
                color: t.textDim, fontSize: 11, fontFamily: 'monospace')),
              const SizedBox(height: 22),
              _PrimaryBtn(label: 'TRY AGAIN', icon: Icons.refresh_rounded,
                t: t, onTap: _retryPage),
              const SizedBox(height: 10),
              _OutlineBtn(label: 'TRY ANOTHER DOMAIN', icon: Icons.swap_horiz_rounded,
                color: t.yellow, t: t, onTap: _nextDomain),
            ]),
          )),
      ])),
      Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        decoration: BoxDecoration(
          color: t.bg,
          border: Border(top: BorderSide(color: t.border, width: 0.5)),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _loginReady && !_isRunning
              ? _PrimaryBtn(key: const ValueKey('run'), label: 'RUN BOT',
                  icon: Icons.bolt_rounded, t: t, onTap: _completeCaptureAndRun)
              : Container(
                  key: const ValueKey('wait'),
                  height: 56,
                  decoration: BoxDecoration(
                    color: t.card, borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: t.border),
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    SizedBox(width: 14, height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: t.textSub)),
                    const SizedBox(width: 10),
                    Text(_isRunning ? 'Running...' : 'Waiting for login...',
                      style: TextStyle(color: t.textSub, fontSize: 14)),
                  ]),
                ),
        ),
      ),
    ]);
  }

  void _showLogsSheet(AppState state, AppTheme t) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(value: state, child: _LogsSheet(t: t)),
    );
  }

  /// Login detection: the site redirects to a rotating domain, so the URL is
  /// no longer a reliable signal. Read the auth token straight from
  /// localStorage instead, and autofill the login form when it is shown.
  Future<void> _handleUrlChange(InAppWebViewController c, String url) async {
    _webController = c;
    if (await _hasToken(c)) {
      if (mounted && !_loginReady) setState(() => _loginReady = true);
      return;
    }
    if (url.contains('login')) {
      await _autoFill(c);
      if (mounted && _loginReady) setState(() => _loginReady = false);
    }
  }

  Future<bool> _hasToken(InAppWebViewController c) async {
    try {
      final r = await c.evaluateJavascript(
          source: "try{return localStorage.getItem('token')||''}catch(e){return ''}");
      final s = r?.toString() ?? '';
      return s.length > 20 && s != 'null';
    } catch (_) {
      return false;
    }
  }

  Future<void> _autoFill(InAppWebViewController c) async {
    final state = context.read<AppState>();
    final phone = state.phone.trim();
    final pass = state.password;
    if (phone.isEmpty || pass.isEmpty) return;
    for (int i = 0; i < 12; i++) {
      await Future.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      final sp = phone.replaceAll('"', r'\"');
      final sw = pass.replaceAll('"', r'\"');
      final r = await c.evaluateJavascript(source: '''
        (function(){
          function set(el,v){var p=Object.getPrototypeOf(el),d=Object.getOwnPropertyDescriptor(p,'value');
            if(d&&d.set)d.set.call(el,v);else el.value=v;
            ['input','change','blur'].forEach(function(e){el.dispatchEvent(new Event(e,{bubbles:true}));});}
          var ins=Array.from(document.querySelectorAll('input'));
          var ph=ins.find(function(i){var h=((i.placeholder||'')+(i.name||'')+(i.id||'')).toLowerCase();
            return h.match(/phone|mobile|user|account|login|tel/)&&i.type!=='password';});
          if(!ph)ph=ins.find(function(i){return i.type!=='password'&&i.type!=='hidden'&&i.type!=='submit';});
          var pw=ins.find(function(i){return i.type==='password';});
          if(!ph||!pw)return 'FAIL';
          set(ph,"$sp");set(pw,"$sw");return 'FILLED';
        })();
      ''');
      if ((r?.toString() ?? '').contains('FILLED')) {
        state.addLog('Autofill success', level: LogLevel.success);
        break;
      }
      if (i == 11) state.addLog('Autofill failed', level: LogLevel.warning);
    }
  }

  _StatusInfo _statusInfo(BotStatus s, AppTheme t) {
    switch (s) {
      case BotStatus.idle:       return _StatusInfo('IDLE', t.textDim);
      case BotStatus.connecting: return _StatusInfo('CONNECTING', const Color(0xFF42A5F5));
      case BotStatus.cloudflare: return _StatusInfo('CF CHALLENGE', const Color(0xFFFFA726));
      case BotStatus.loggingIn:  return _StatusInfo('LOGGING IN', const Color(0xFF42A5F5));
      case BotStatus.capturing:  return _StatusInfo('CAPTURING TOKEN', t.yellow);
      case BotStatus.running:    return _StatusInfo('RUNNING', t.yellow);
      case BotStatus.qrReady:    return _StatusInfo('QR READY — PAY NOW', t.green);
      case BotStatus.success:    return _StatusInfo('SUCCESS', t.green);
      case BotStatus.error:      return _StatusInfo('ERROR', t.red);
    }
  }
}

// ── Stat card ──────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  final AppTheme t;
  const _StatCard({required this.label, required this.value,
    required this.icon, required this.color, required this.t});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: t.card, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: t.border),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: t.textSub, fontSize: 9, letterSpacing: 1.2)),
        ]),
      ),
    );
  }
}

// ── Primary button ─────────────────────────────────────────────────────────────
class _PrimaryBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final AppTheme t;
  final VoidCallback onTap;
  const _PrimaryBtn({super.key, required this.label, required this.icon,
    required this.t, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity, height: 56,
        decoration: BoxDecoration(
          color: t.yellow, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: t.yellow.withValues(alpha: 0.25),
            blurRadius: 20, offset: const Offset(0, 6))],
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: t.bg, size: 22),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(color: t.bg, fontWeight: FontWeight.bold,
            fontSize: 15, letterSpacing: 1.2)),
        ]),
      ),
    );
  }
}

// ── Outline button ─────────────────────────────────────────────────────────────
class _OutlineBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final AppTheme t;
  final VoidCallback onTap;
  const _OutlineBtn({required this.label, required this.icon,
    required this.color, required this.t, required this.onTap});

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
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold,
            fontSize: 15, letterSpacing: 1.2)),
        ]),
      ),
    );
  }
}

class _StatusInfo { final String label; final Color color; _StatusInfo(this.label, this.color); }

// ── Logs sheet ─────────────────────────────────────────────────────────────────
class _LogsSheet extends StatelessWidget {
  final AppTheme t;
  const _LogsSheet({required this.t});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(builder: (context, state, _) {
      final logs = state.logs;
      return Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(children: [
          Container(margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 36, height: 4,
            decoration: BoxDecoration(color: t.textDim, borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            child: Row(children: [
              Icon(Icons.terminal, color: t.yellow, size: 16),
              const SizedBox(width: 8),
              Text('Live Log', style: TextStyle(color: t.yellow, fontSize: 15,
                fontWeight: FontWeight.bold, letterSpacing: 1.0)),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  if (logs.isEmpty) return;
                  Clipboard.setData(ClipboardData(
                    text: logs.reversed.map((e) => '[${e.time}] ${e.message}').join('\n')));
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('${logs.length} lines copied')));
                },
                child: Text('COPY', style: TextStyle(color: t.textSub, fontSize: 11, letterSpacing: 1)),
              ),
              const SizedBox(width: 14),
              GestureDetector(onTap: () => state.clearLogs(),
                child: Text('CLEAR', style: TextStyle(color: t.textSub, fontSize: 11, letterSpacing: 1))),
              const SizedBox(width: 14),
              GestureDetector(onTap: () => Navigator.pop(context),
                child: Icon(Icons.close_rounded, color: t.textSub, size: 20)),
            ]),
          ),
          Divider(color: t.border, height: 1),
          Expanded(
            child: logs.isEmpty
                ? Center(child: Text('No logs yet', style: TextStyle(color: t.textDim, fontSize: 13)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: logs.length,
                    itemBuilder: (_, i) {
                      final e = logs[i];
                      final color = _logColor(e.level);
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(e.time, style: TextStyle(color: t.textDim, fontSize: 10, fontFamily: 'monospace')),
                          const SizedBox(width: 8),
                          Icon(_logIcon(e.level), size: 11, color: color),
                          const SizedBox(width: 6),
                          Expanded(child: Text(e.message, style: TextStyle(
                            color: color, fontSize: 12, fontFamily: 'monospace', height: 1.4))),
                        ]),
                      );
                    }),
          ),
        ]),
      );
    });
  }

  Color _logColor(LogLevel l) {
    switch (l) {
      case LogLevel.success: return t.logSuccess;
      case LogLevel.warning: return t.logWarning;
      case LogLevel.error:   return t.logError;
      case LogLevel.info:    return t.logInfo;
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
