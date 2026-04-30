# ConfidantSanté — Guide de démarrage

## Structure du projet

```
confidantsante/
├── lib/
│   ├── main.dart                          ← Point d'entrée de l'app
│   ├── core/
│   │   ├── constants/
│   │   │   └── app_colors.dart            ← Toutes les couleurs
│   │   ├── theme/
│   │   │   └── app_theme.dart             ← Thème Material 3
│   │   ├── l10n/
│   │   │   └── app_localizations.dart     ← Textes FR / EN / SW
│   │   ├── providers/
│   │   │   ├── language_provider.dart     ← Gestion de la langue
│   │   │   └── auth_provider.dart         ← Auth PIN + biométrie
│   │   ├── database/
│   │   │   └── local_database.dart        ← SQLite offline-first
│   │   └── router/
│   │       └── app_router.dart            ← Navigation go_router
│   └── features/
│       ├── splash/                        ← Écran de démarrage
│       ├── language/                      ← Choix de langue
│       ├── onboarding/                    ← 3 slides d'intro
│       ├── auth/                          ← Login patient + soignant
│       ├── patient/
│       │   ├── dashboard/                 ← Tableau de bord patient
│       │   ├── reminders/                 ← Rappels médicaments
│       │   ├── camouflage/               ← Mode camouflage
│       │   └── profile/                  ← Profil + historique
│       └── caregiver/
│           ├── dashboard/                ← Dashboard soignant
│           └── patient_detail/           ← Dossier d'un patient
└── pubspec.yaml                          ← Dépendances
```

---

## Étapes pour démarrer dans Android Studio

### 1. Créer le projet Flutter
```
File → New → New Flutter Project
Application name : confidantsante
Organization : cd.udbl.msi
```

### 2. Remplacer les fichiers générés
Copie tous les fichiers de ce dossier dans ton projet Flutter.

### 3. Installer les dépendances
Dans le terminal Android Studio :
```bash
flutter pub get
```

### 4. Configurer Firebase
1. Va sur https://console.firebase.google.com
2. Crée un projet "ConfidantSanté"
3. Ajoute une app Android (package : cd.udbl.msi.confidantsante)
4. Télécharge google-services.json → colle dans android/app/
5. Dans le terminal :
```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

### 5. Lancer l'app
```bash
flutter run
```

---

## Dépendances clés expliquées

| Package | Rôle |
|---------|------|
| firebase_core | Connexion Firebase |
| firebase_auth | Authentification utilisateurs |
| cloud_firestore | Base de données cloud |
| sqflite | Base de données locale (offline) |
| local_auth | Empreinte digitale / Face ID |
| go_router | Navigation entre écrans |
| provider | Gestion d'état |
| flutter_local_notifications | Rappels médicaments |
| flutter_secure_storage | Stockage sécurisé PIN |

---

## Permissions à ajouter

### Android (android/app/src/main/AndroidManifest.xml)
```xml
<uses-permission android:name="android.permission.USE_BIOMETRIC"/>
<uses-permission android:name="android.permission.USE_FINGERPRINT"/>
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.VIBRATE"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```

---

## Prochains fichiers à créer (dans l'ordre)

1. `features/onboarding/onboarding_screen.dart`
2. `features/auth/role_screen.dart`
3. `features/auth/login_patient_screen.dart`
4. `features/auth/login_caregiver_screen.dart`
5. `features/patient/dashboard/patient_dashboard_screen.dart`
6. `features/patient/reminders/reminders_screen.dart`
7. `features/patient/camouflage/camouflage_screen.dart`
8. `features/patient/profile/profile_screen.dart`
9. `features/caregiver/dashboard/caregiver_dashboard_screen.dart`
10. `features/caregiver/patient_detail/patient_detail_screen.dart`
