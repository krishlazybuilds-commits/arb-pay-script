import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/app_state.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  final prefs = await SharedPreferences.getInstance();
  final state = AppState();
  state.phone        = prefs.getString('phone')    ?? '';
  state.password     = prefs.getString('password') ?? '';
  state.amountMin    = prefs.getInt('amtMin')      ?? 1700;
  state.amountMax    = prefs.getInt('amtMax')      ?? 2000;
  state.paymentMode  = (prefs.getString('paymentMode') == 'bank')
      ? PaymentMode.bank : PaymentMode.upi;
  state.isDark       = prefs.getBool('isDark') ?? true;

  runApp(ChangeNotifierProvider.value(value: state, child: const ArbPayApp()));
}

class ArbPayApp extends StatelessWidget {
  const ArbPayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        return MaterialApp(
          title: 'ARBPay Bot',
          debugShowCheckedModeBanner: false,
          themeMode: state.isDark ? ThemeMode.dark : ThemeMode.light,
          darkTheme: _darkTheme,
          theme: _lightTheme,
          home: const HomeScreen(),
        );
      },
    );
  }
}

// ── Dark theme ─────────────────────────────────────────────────────────────────
final _darkTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: const Color(0xFF0A0A0F),
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFFFFCC00),
    secondary: Color(0xFFFFCC00),
    surface: Color(0xFF13131A),
    onPrimary: Color(0xFF0A0A0F),
    onSurface: Color(0xFFFFFFFF),
  ),
  fontFamily: 'sans-serif',
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF0A0A0F),
    elevation: 0,
    iconTheme: IconThemeData(color: Color(0xFFFFFFFF)),
    titleTextStyle: TextStyle(
      color: Color(0xFFFFFFFF), fontWeight: FontWeight.bold, fontSize: 18),
    systemOverlayStyle: SystemUiOverlayStyle.light,
  ),
  snackBarTheme: SnackBarThemeData(
    backgroundColor: const Color(0xFFFFCC00),
    contentTextStyle: const TextStyle(color: Color(0xFF0A0A0F)),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    behavior: SnackBarBehavior.floating,
  ),
);

// ── Light theme ────────────────────────────────────────────────────────────────
final _lightTheme = ThemeData(
  brightness: Brightness.light,
  scaffoldBackgroundColor: const Color(0xFFF5F5F7),
  colorScheme: const ColorScheme.light(
    primary: Color(0xFFFFCC00),
    secondary: Color(0xFFFFCC00),
    surface: Color(0xFFFFFFFF),
    onPrimary: Color(0xFF0A0A0F),
    onSurface: Color(0xFF1A1A1A),
  ),
  fontFamily: 'sans-serif',
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFFF5F5F7),
    elevation: 0,
    iconTheme: IconThemeData(color: Color(0xFF1A1A1A)),
    titleTextStyle: TextStyle(
      color: Color(0xFF1A1A1A), fontWeight: FontWeight.bold, fontSize: 18),
    systemOverlayStyle: SystemUiOverlayStyle.dark,
  ),
  snackBarTheme: SnackBarThemeData(
    backgroundColor: const Color(0xFFFFCC00),
    contentTextStyle: const TextStyle(color: Color(0xFF0A0A0F)),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    behavior: SnackBarBehavior.floating,
  ),
);
