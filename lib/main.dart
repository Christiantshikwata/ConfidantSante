import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_colors.dart';
import 'core/services/database_service.dart';
import 'core/services/session_service.dart';
import 'core/providers/patient_provider.dart';
import 'features/splash/splash_screen.dart';
import 'features/auth/role_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise SQLite
  await DatabaseService().database;

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(
    // Provider rend les données accessibles partout dans l'app
    ChangeNotifierProvider(
      create: (_) => PatientProvider(),
      child: const ConfidantSanteApp(),
    ),
  );
}

class ConfidantSanteApp extends StatelessWidget {
  const ConfidantSanteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ConfidantSanté',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
        ),
        useMaterial3: true,
      ),
      routes: {
        '/': (context) => const SplashScreen(),
        '/role': (context) => const RoleScreen(),
      },
      initialRoute: '/',
    );
  }
}