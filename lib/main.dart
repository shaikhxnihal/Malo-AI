import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:malo/services/monetization_service.dart';
import 'package:malo/utils/app_theme.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ✅ Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
  ));

  // ✅ Lock orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

   await dotenv.load(fileName: ".env");

  // ✅ Initialize Monetization (includes RevenueCat)
  // await MonetizationService.instance.initialize();

  runApp(const MaloApp());
}

class MaloApp extends StatelessWidget {
  const MaloApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Malo',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: AppColors.accent,
        scaffoldBackgroundColor: AppColors.bg,
        colorScheme: ColorScheme.dark(
          primary: AppColors.accent,
          secondary: AppColors.blue,
          surface: AppColors.surface,
          error: AppColors.danger,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
