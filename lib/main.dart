import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_colors.dart';
import 'core/services/database_service.dart';
import 'core/services/notification_service.dart';
import 'core/providers/patient_provider.dart';
import 'core/providers/langue_provider.dart';
import 'features/splash/splash_screen.dart';
import 'features/auth/role_screen.dart';
import 'core/services/sync_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise les données de locale pour le formatage des dates (fr_FR, etc.).
  // Sans ça, DateFormat('…','fr_FR') plante (écran rouge sur les rendez-vous).
  await initializeDateFormatting('fr_FR', null);

  // Initialise Firebase. Si l'init échoue, l'app continue en mode 100% local.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('[main] Firebase non initialisé, mode local : $e');
  }

  await DatabaseService().database;
  await NotificationService().initialiser();
  // Démarre l'écoute de connectivité pour sync automatique (si Firebase dispo)
  SyncService().ecouterConnectivite();
  // Charge la langue avant de lancer l'app
  final langueProvider = LangueProvider();
  await langueProvider.charger();

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
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: langueProvider),
        ChangeNotifierProvider(create: (_) => PatientProvider()),
      ],
      child: const ConfidantSanteApp(),
    ),
  );
}

class ConfidantSanteApp extends StatelessWidget {
  const ConfidantSanteApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Écoute la langue : tout changement reconstruit l'app.
    context.watch<LangueProvider>();
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