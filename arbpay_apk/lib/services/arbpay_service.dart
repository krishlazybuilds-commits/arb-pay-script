import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../models/app_state.dart';

class ArbPayService {
  static const String _apiUrl = 'https://apiweb.arbpay.me';
  static const List<String> _bankCodes = [
    'mobikwik', 'paytm', 'phonepe', 'gpay', 'amazonpay', 'freecharge', 'airtel'
  ];

  InAppWebViewController? _webView;
  AppState? _state;
  bool _running = false;
  String _token = '';
  String _deviceCode = '';
  int _bankIndex = 0;
  final Set<String> _skippedOrders = {};
  final Set<String> _seenBuyCodes = {};   // mirrors Python _seen_codes

  void init(InAppWebViewController controller, AppState state) {
    _webView = controller;
    _state = state;
  }

  void dispose() {
    stop();
    _webView = null;
    _state = null;
  }

  bool get isRunning => _running;

  Future<void> captureTokenAndRun(String phone, String password, int amtMin, int amtMax) async {
    if (_running) return;
    _running = true;
    _state?.setStatus(BotStatus.capturing);
    _log('Capturing token from active session...', level: LogLevel.info);

    try {
      await _buildApiSession();
      if (_token.isEmpty) {
        _log('Token not found — make sure you are logged in', level: LogLevel.error);
        _state?.setStatus(BotStatus.error);
        _running = false;
        return;
      }
      _log('Token captured! Starting buy loop...', level: LogLevel.success);
      _state?.setStatus(BotStatus.running);
      _seenBuyCodes.clear();
      await _runBuyLoop(amtMin, amtMax);
    } catch (e) {
      _log('Fatal error: $e', level: LogLevel.error);
      _state?.setStatus(BotStatus.error);
      _running = false;
    }
  }

  void stop() {
    _running = false;
    _state?.setStatus(BotStatus.idle);
    _log('Bot stopped by user', level: LogLevel.warning);
  }

  // ── Extract token from WebView localStorage ───────────────────────────────
  // Mirrors Python build_api_session exactly:
  //   token       = json.loads(ls.get("token",      "{}")).get("value", "")
  //   device_code = json.loads(ls.get("deviceCode", "{}")).get("value", "")
  Future<void> _buildApiSession() async {
    if (_webView == null) return;

    final result = await _webView!.callAsyncJavaScript(functionBody: '''
      var ls = {};
      for (var i = 0; i < localStorage.length; i++) {
        var k = localStorage.key(i);
        ls[k] = localStorage.getItem(k);
      }
      return ls;
    ''');

    if (result == null || result.value == null) {
      _log('localStorage empty — cannot read session', level: LogLevel.warning);
      return;
    }

    final lsMap = Map<String, dynamic>.from(result.value as Map);
    _log('LS keys: ${lsMap.keys.toList()}', level: LogLevel.info);

    // Primary path: exact Python approach
    try {
      final tokenRaw = lsMap['token']?.toString() ?? '{}';
      final tokenParsed = jsonDecode(tokenRaw) as Map;
      final t = tokenParsed['value']?.toString() ?? '';
      if (t.length > 20) {
        _token = t;
        _log('Token found at key "token"', level: LogLevel.success);
      }
    } catch (_) {}

    try {
      final dcRaw = lsMap['deviceCode']?.toString() ?? '{}';
      final dcParsed = jsonDecode(dcRaw) as Map;
      _deviceCode = dcParsed['value']?.toString() ?? '';
    } catch (_) {}

    // Fallback: scan all keys for token/auth/jwt patterns
    if (_token.isEmpty) {
      for (final entry in lsMap.entries) {
        final key = entry.key.toLowerCase();
        final val = entry.value?.toString() ?? '';
        if (key.contains('token') || key.contains('auth') || key.contains('jwt')) {
          if (val.length > 20 && !val.startsWith('{')) {
            _token = val;
            _log('Token found at key "${entry.key}"', level: LogLevel.success);
            break;
          }
          try {
            final parsed = jsonDecode(val) as Map;
            final t = (parsed['value'] ?? parsed['token'] ??
                parsed['accessToken'] ?? parsed['access_token'] ?? '').toString();
            if (t.length > 20) {
              _token = t;
              _log('Token found nested at key "${entry.key}"', level: LogLevel.success);
              break;
            }
          } catch (_) {}
        }
        if (_deviceCode.isEmpty && (key.contains('device') || key.contains('code'))) {
          if (val.length > 5 && !val.startsWith('{')) {
            _deviceCode = val;
          } else {
            try {
              final parsed = jsonDecode(val) as Map;
              _deviceCode = (parsed['value'] ?? parsed['deviceCode'] ?? '').toString();
            } catch (_) {}
          }
        }
      }
    }

    // Last resort: any JWT-like long string with dots
    if (_token.isEmpty) {
      for (final entry in lsMap.entries) {
        final val = entry.value?.toString() ?? '';
        if (val.contains('.') && val.length > 50 && !val.startsWith('{')) {
          _token = val;
          _log('Token guessed from key "${entry.key}"', level: LogLevel.warning);
          break;
        }
        try {
          final parsed = jsonDecode(val);
          if (parsed is Map) {
            for (final v in parsed.values) {
              final s = v?.toString() ?? '';
              if (s.length > 50 && s.contains('.')) {
                _token = s;
                _log('Token guessed nested from key "${entry.key}"', level: LogLevel.warning);
                break;
              }
            }
          }
        } catch (_) {}
        if (_token.isNotEmpty) break;
      }
    }

    if (_token.isNotEmpty) {
      _log(
        'API session ready — token ...${_token.length > 12 ? _token.substring(_token.length - 12) : _token}',
        level: LogLevel.success,
      );
    } else {
      _log('Token not found — make sure you are logged in', level: LogLevel.error);
    }
  }

  // ── Buy loop ───────────────────────────────────────────────────────────────
  Future<void> _runBuyLoop(int amtMin, int amtMax) async {
    _log('Buy loop started (₹$amtMin - ₹$amtMax)', level: LogLevel.success);
    _log('Token last 12: ...${_token.length > 12 ? _token.substring(_token.length - 12) : _token}',
        level: LogLevel.info);
    _log('deviceCode: ${_deviceCode.isEmpty ? "(empty)" : _deviceCode}',
        level: LogLevel.info);
    _skippedOrders.clear();
    _bankIndex = 0;
    int emptyStreak   = 0;
    int fetchFailStreak = 0;
    int buyListCallCount = 0;
    // Log every buy response for first 10 attempts, then every unique code
    int verboseBuyCount = 0;

    while (_running) {
      _state?.incrementAttempts();
      final attempts = _state?.attempts ?? 0;

      if (_token.isEmpty) {
        _log('No token — waiting 3s', level: LogLevel.warning);
        await Future.delayed(const Duration(seconds: 3));
        continue;
      }

      // ── buyList — verbose on first call and every 10 attempts ─────────────
      buyListCallCount++;
      final isVerbose = buyListCallCount <= 3 || buyListCallCount % 10 == 0;
      final orders = await _getOrderList(amtMin, amtMax, verbose: isVerbose);

      if (orders.isEmpty) {
        emptyStreak++;
        if (emptyStreak % 10 == 0) {
          _log('No orders in ₹$amtMin-₹$amtMax after $emptyStreak empty calls (attempt $attempts)',
              level: LogLevel.warning);
        }
        if (emptyStreak >= 100) {
          _log('[WARN] 100 empty buyLists — rebuilding session', level: LogLevel.warning);
          await _buildApiSession();
          emptyStreak = 0;
        }
        await Future.delayed(const Duration(milliseconds: 50));
        continue;
      }
      emptyStreak = 0;
      fetchFailStreak = 0;

      // Pick first order not in skip list
      Map<String, dynamic>? order;
      for (final o in orders) {
        final oid = (o['platformOrder'] ?? o['orderNo'] ?? o['mOrderNo'] ?? '').toString();
        if (oid.isNotEmpty && !_skippedOrders.contains(oid)) {
          order = o;
          break;
        }
      }
      if (order == null) {
        _skippedOrders.clear();
        await Future.delayed(const Duration(milliseconds: 100));
        continue;
      }

      final platformOrder = (order['platformOrder'] ?? order['orderNo'] ?? order['mOrderNo'] ?? '').toString();
      final amount = (double.tryParse(order['amount']?.toString() ?? '0') ?? 0).toInt();
      if (platformOrder.isEmpty) {
        await Future.delayed(const Duration(milliseconds: 50));
        continue;
      }

      _log('Attempt #$attempts → order=$platformOrder ₹$amount bank=${_bankCodes[_bankIndex % _bankCodes.length]}',
          level: LogLevel.info);

      // ── buy ───────────────────────────────────────────────────────────────
      final currentBank = _bankCodes[_bankIndex % _bankCodes.length];
      verboseBuyCount++;
      final buyResp = await _apiBuy(platformOrder, amount, currentBank,
          verbose: verboseBuyCount <= 5);

      // Always log the full raw buy response for the first 5, then every unique code
      final rawPreview = jsonEncode(buyResp);
      if (verboseBuyCount <= 5) {
        _log('buy[$verboseBuyCount] raw: ${rawPreview.length > 400 ? rawPreview.substring(0, 400) : rawPreview}',
            level: LogLevel.info);
      }

      if (buyResp.isEmpty) {
        fetchFailStreak++;
        _log('buy empty resp #$fetchFailStreak', level: LogLevel.warning);
        if (fetchFailStreak >= 5) {
          _log('[WARN] $fetchFailStreak consecutive empty — rebuilding session',
              level: LogLevel.warning);
          await _buildApiSession();
          fetchFailStreak = 0;
        }
        await Future.delayed(const Duration(milliseconds: 100));
        continue;
      }
      fetchFailStreak = 0;

      final code = buyResp['code']?.toString() ?? '';
      final msg  = buyResp['msg']?.toString() ?? buyResp['message']?.toString() ?? '';

      // Log every unique code with its message
      if (!_seenBuyCodes.contains(code)) {
        _seenBuyCodes.add(code);
        _log('NEW buy code=$code msg="$msg" | ${rawPreview.length > 250 ? rawPreview.substring(0, 250) : rawPreview}',
            level: LogLevel.warning);
      }

      if (['200', '0', '1', '00', 'success', 'SUCCESS'].contains(code)) {
        final mrOrder = _extractMrOrder(buyResp);
        if (mrOrder.isNotEmpty) {
          _log('BUY SUCCESS after $attempts attempts — Order: $mrOrder ₹$amount',
              level: LogLevel.success);
          _state?.incrementSuccess();
          _state?.setCurrentOrder(mrOrder);
          _state?.incrementRounds();
          _state?.setStatus(BotStatus.qrReady);
          await _reloadWebView();
          return;
        } else {
          _log('code=$code but MR order missing! Full: $rawPreview', level: LogLevel.error);
        }
      } else if (code == '2005') {
        _log('Bank "$currentBank" rejected (2005) for $platformOrder — next bank');
        _bankIndex++;
        if (_bankIndex % _bankCodes.length == 0) {
          _log('All banks rejected for $platformOrder — skipping', level: LogLevel.warning);
          _skippedOrders.add(platformOrder);
          _bankIndex = 0;
        }
        await Future.delayed(const Duration(milliseconds: 50));
        continue;
      } else if (code == '1027') {
        final data = buyResp['data'];
        final existingOrder = (data is Map ? (data['platformOrder'] ?? '') : '').toString();
        if (existingOrder.isNotEmpty) {
          _log('Unfinished order: $existingOrder — proceeding', level: LogLevel.warning);
          _state?.setCurrentOrder(existingOrder);
          _state?.setStatus(BotStatus.qrReady);
          await _reloadWebView();
          return;
        }
      } else if (code == '1191') {
        _log('Rate limited (1191) "$msg" — waiting 5s', level: LogLevel.warning);
        await Future.delayed(const Duration(seconds: 5));
        continue;
      } else if (code == '1194') {
        // Snatched by someone else — just loop silently
      } else {
        _log('Unknown code=$code msg="$msg"', level: LogLevel.warning);
      }

      await Future.delayed(const Duration(milliseconds: 20));
    }
  }

  Future<void> _reloadWebView() async {
    try {
      await _webView?.reload();
    } catch (_) {}
    _log('QR payment screen ready!', level: LogLevel.success);
  }

  // ── WebView fetch() — full verbose logging ───────────────────────────────
  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body,
      {String page = 'Arb', bool verbose = false}) async {
    if (_webView == null) {
      _log('POST $path — WebView is null!', level: LogLevel.error);
      return {};
    }
    if (_token.isEmpty) {
      _log('POST $path — token is empty!', level: LogLevel.error);
      return {};
    }

    try {
      final result = await _webView!.callAsyncJavaScript(
        functionBody: '''
          try {
            var resp = await fetch(apiUrl, {
              method: 'POST',
              headers: {
                'Accept': 'application/json, text/plain, */*',
                'Content-Type': 'application/json',
                'authorization': 'Bearer ' + token,
                'deviceCode': deviceCode || '',
                'deviceId': '',
                'deviceType': '3',
                'language': '1',
                'page': page
              },
              body: bodyStr
            });
            var text = await resp.text();
            return { ok: resp.ok, status: resp.status, text: text };
          } catch(e) {
            return { ok: false, status: 0, text: String(e) };
          }
        ''',
        arguments: {
          'apiUrl':     '$_apiUrl$path',
          'token':      _token,
          'deviceCode': _deviceCode,
          'page':       page,
          'bodyStr':    jsonEncode(body),
        },
      );

      // ── callAsyncJavaScript-level failure ──────────────────────────────
      if (result == null) {
        _log('POST $path → callAsyncJS returned null', level: LogLevel.error);
        return {};
      }
      if (result.error != null && (result.error?.isNotEmpty ?? false)) {
        _log('POST $path → JS exception: ${result.error}', level: LogLevel.error);
        return {};
      }
      if (result.value == null) {
        _log('POST $path → JS returned null value', level: LogLevel.error);
        return {};
      }

      final res = Map<String, dynamic>.from(result.value as Map);
      final status = (res['status'] as num?)?.toInt() ?? 0;
      final text   = res['text']?.toString() ?? '';
      final ok     = res['ok'] == true;

      // ── Always log non-200 HTTP responses ────────────────────────────────
      if (!ok || (status != 200 && status != 201)) {
        final preview = text.length > 300 ? text.substring(0, 300) : text;
        _log('POST $path → HTTP $status (ok=$ok) body: $preview',
            level: LogLevel.error);
        return {};
      }

      if (text.isEmpty) {
        _log('POST $path → HTTP $status but empty body', level: LogLevel.warning);
        return {};
      }

      // ── Verbose: log raw success response ─────────────────────────────
      if (verbose) {
        final preview = text.length > 400 ? text.substring(0, 400) : text;
        _log('POST $path → $status: $preview', level: LogLevel.info);
      }

      try {
        return Map<String, dynamic>.from(jsonDecode(text));
      } catch (e) {
        _log('POST $path → JSON parse error: $e | body: ${text.substring(0, text.length.clamp(0, 200))}',
            level: LogLevel.error);
        return {};
      }
    } catch (e) {
      _log('POST $path → Dart exception: $e', level: LogLevel.error);
      return {};
    }
  }

  // ── Order list ─────────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> _getOrderList(int amtMin, int amtMax,
      {bool verbose = false}) async {
    final data = await _post(
      '/ar-wallet/buyCenter/buyList',
      {'orderType': 1, 'pageNo': 1},
      verbose: verbose,
    );

    if (data.isEmpty) return [];

    // Log full raw top-level keys every verbose call
    if (verbose) {
      _log('buyList keys: ${data.keys.toList()} | code=${data['code']}',
          level: LogLevel.info);
    }

    List<dynamic> records = [];
    for (final topKey in ['data', 'result', 'body', 'response']) {
      final inner = data[topKey];
      if (inner == null) continue;
      if (inner is List) { records = inner; break; }
      if (inner is Map) {
        for (final subKey in ['records', 'list', 'rows', 'data', 'items', 'content']) {
          final val = inner[subKey];
          if (val is List && val.isNotEmpty) { records = val; break; }
        }
        if (records.isNotEmpty) break;
      }
    }

    if (verbose) {
      if (records.isEmpty) {
        _log('buyList: 0 raw records. Full resp: ${jsonEncode(data).substring(0, jsonEncode(data).length.clamp(0, 500))}',
            level: LogLevel.warning);
      } else {
        final amounts = records
            .whereType<Map>()
            .map((o) => o['amount']?.toString() ?? '?')
            .take(5)
            .join(', ');
        _log('buyList: ${records.length} records, amounts=[$amounts...]',
            level: LogLevel.info);
      }
    }

    final filtered = records
        .whereType<Map<String, dynamic>>()
        .where((o) {
          final amt = double.tryParse(o['amount']?.toString() ?? '0') ?? 0;
          return amt >= amtMin && amt <= amtMax;
        })
        .toList();

    if (verbose && records.isNotEmpty) {
      _log('buyList: ${filtered.length} orders in ₹$amtMin-₹$amtMax range',
          level: filtered.isEmpty ? LogLevel.warning : LogLevel.success);
    }

    return filtered;
  }

  Future<Map<String, dynamic>> _apiBuy(
      String platformOrder, int amount, String bankCode,
      {bool verbose = false}) async {
    final resp = await _post(
      '/ar-wallet/buyCenter/buy',
      {
        'amount': amount,
        'platformOrder': platformOrder,
        'payType': '3',
        'orderType': 1,
        'buyBankCode': bankCode,
        'buyerKycId': 0,
      },
      verbose: verbose,
    );
    return resp;
  }

  String _extractMrOrder(Map<String, dynamic> resp) {
    final data = resp['data'] ?? resp['result'];
    if (data is String && data.startsWith('MR')) return data;
    if (data is Map) {
      return (data['buyOrderNo'] ?? data['platformOrder'] ??
          data['orderNo'] ?? data['mOrderNo'] ?? '').toString();
    }
    return '';
  }

  void _log(String msg, {LogLevel level = LogLevel.info}) {
    _state?.addLog(msg, level: level);
    debugPrint('[ARBPay] $msg');
  }
}

const String siteUrl = 'https://arbpay.me';
