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
  state.phone     = prefs.getString('phone')    ?? '';
  state.password  = prefs.getString('password') ?? '';
  state.amountMin = prefs.getInt('amtMin')      ?? 1700;
  state.amountMax = prefs.getInt('amtMax')      ?? 2000;

  runApp(
    ChangeNotifierProvider.value(
      value: state,
      child: const ArbPayApp(),
    ),
  );
}

class ArbPayApp extends StatelessWidget {
  const ArbPayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ARBPay Bot',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.light(
          primary: const Color(0xFFFFD600),
          secondary: const Color(0xFFFFEA00),
          surface: const Color(0xFFF5F5F5),
          onPrimary: const Color(0xFF1A1A1A),
          onSurface: const Color(0xFF212121),
        ),
        fontFamily: 'sans-serif',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: Color(0xFF212121)),
          titleTextStyle: TextStyle(
            color: Color(0xFF212121), fontWeight: FontWeight.bold, fontSize: 18),
          systemOverlayStyle: SystemUiOverlayStyle.dark,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: const Color(0xFFFFD600),
          contentTextStyle: const TextStyle(color: Color(0xFF1A1A1A)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          behavior: SnackBarBehavior.floating,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
