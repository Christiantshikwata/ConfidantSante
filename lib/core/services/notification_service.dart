import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {

  static final NotificationService _instance =
  NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();

  bool _initialise = false;

  Future<void> initialiser() async {
    if (_initialise) return;

    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Africa/Lubumbashi'));

    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings =
    InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint('Notification : ${details.payload}');
      },
    );

    // Permission Android 13+ — sur une seule ligne
    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        _plugin.resolvePlatformSpecificImplementation
    AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();

    _initialise = true;
  }

  AndroidNotificationDetails get _androidDetails =>
      const AndroidNotificationDetails(
        'confidantsante_rappels',
        'Rappels médicaments',
        channelDescription: 'Rappels de prise ARV',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        color: Color(0xFF1565C0),
        enableVibration: true,
        playSound: true,
      );

  // Notification immédiate
  Future<void> afficherNotification({
    required int id,
    required String titre,
    required String corps,
  }) async {
    await initialiser();
    await _plugin.show(
      id,
      titre,
      corps,
      NotificationDetails(android: _androidDetails),
    );
  }

  // Rappel quotidien programmé
  Future<void> programmerRappelQuotidien({
    required int id,
    required String nomMedicament,
    required String dosage,
    required int heure,
    required int minute,
  }) async {
    await initialiser();

    final maintenant = tz.TZDateTime.now(tz.local);
    var prochain = tz.TZDateTime(
      tz.local,
      maintenant.year,
      maintenant.month,
      maintenant.day,
      heure,
      minute,
    );

    if (prochain.isBefore(maintenant)) {
      prochain = prochain.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id,
      'Rappel médicament',
      'Prenez votre $nomMedicament — $dosage',
      prochain,
      NotificationDetails(android: _androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: nomMedicament,
    );

    debugPrint('Rappel programmé : $nomMedicament à ${heure}h$minute');
  }

  // Programme depuis texte "08h30"
  Future<void> programmerDepuisTexte({
    required int id,
    required String nomMedicament,
    required String dosage,
    required String heureTexte,
  }) async {
    try {
      final parties = heureTexte.replaceAll('h', ':').split(':');
      final h = int.parse(parties[0]);
      final m = int.parse(parties[1]);
      await programmerRappelQuotidien(
        id: id,
        nomMedicament: nomMedicament,
        dosage: dosage,
        heure: h,
        minute: m,
      );
    } catch (e) {
      debugPrint('Erreur parsing heure : $e');
    }
  }

  Future<void> annulerRappel(int id) async {
    await _plugin.cancel(id);
  }

  Future<void> annulerTous() async {
    await _plugin.cancelAll();
  }
}