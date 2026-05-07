class AppTranslations {

  static final Map<String, Map<String, String>> _traductions = {

    // ── FRANÇAIS ────────────────────────────────────────────────
    'fr': {
      'app_nom':           'ConfidantSanté',
      'app_slogan':        'Votre santé, en toute discrétion',
      'choisir_langue':    'Choisissez votre langue',
      'continuer':         'Continuer',
      'connexion':         'Connexion Patient',
      'nouveau_compte':    'Nouveau compte',
      'se_connecter':      'Se connecter',
      'nom_complet':       'Votre nom complet',
      'numero_telephone':  'Numéro de téléphone',
      'mot_de_passe':      'Mot de passe',
      'creer_compte':      'Créer mon compte',
      'bonjour':           'Bonjour,',
      'bon_apres_midi':    'Bon après-midi,',
      'bonsoir':           'Bonsoir,',
      'observance':        'Observance du mois',
      'rappels':           'Rappels',
      'ajouter':           'Ajouter',
      'medicament':        'Médicament du jour',
      'profil':            'Mon profil',
      'discretion':        'Mode discrétion',
      'accueil':           'Accueil',
      'creer_pin':         'Créez votre PIN',
      'confirmer_pin':     'Confirmez votre PIN',
      'enregistrer':       'Enregistrer',
      'nom_medicament':    'Nom du médicament',
      'dosage':            'Dosage',
      'heure_prise':       'Heure de prise',
      'rappel_ajoute':     'Rappel ajouté avec succès',
      'prise_confirmee':   'Prise confirmée',
      'deconnecter':       'Se déconnecter',
      'annuler':           'Annuler',
      'parametres':        'Paramètres',
      'historique':        'Historique 30 jours',
      'taux_observance':   'Taux d\'observance',
      'erreur_numero':     'Veuillez entrer votre numéro',
      'erreur_mdp':        'Minimum 6 caractères',
      'erreur_login':      'Numéro ou mot de passe incorrect',
      'erreur_existe':     'Ce numéro est déjà enregistré',
    },

    // ── ENGLISH ──────────────────────────────────────────────────
    'en': {
      'app_nom':           'ConfidantHealth',
      'app_slogan':        'Your health, in complete privacy',
      'choisir_langue':    'Choose your language',
      'continuer':         'Continue',
      'connexion':         'Patient Login',
      'nouveau_compte':    'New account',
      'se_connecter':      'Sign in',
      'nom_complet':       'Your full name',
      'numero_telephone':  'Phone number',
      'mot_de_passe':      'Password',
      'creer_compte':      'Create my account',
      'bonjour':           'Good morning,',
      'bon_apres_midi':    'Good afternoon,',
      'bonsoir':           'Good evening,',
      'observance':        'Monthly adherence',
      'rappels':           'Reminders',
      'ajouter':           'Add',
      'medicament':        'Today\'s medication',
      'profil':            'My profile',
      'discretion':        'Privacy mode',
      'accueil':           'Home',
      'creer_pin':         'Create your PIN',
      'confirmer_pin':     'Confirm your PIN',
      'enregistrer':       'Save',
      'nom_medicament':    'Medication name',
      'dosage':            'Dosage',
      'heure_prise':       'Time of dose',
      'rappel_ajoute':     'Reminder added successfully',
      'prise_confirmee':   'Dose confirmed',
      'deconnecter':       'Sign out',
      'annuler':           'Cancel',
      'parametres':        'Settings',
      'historique':        '30-day history',
      'taux_observance':   'Adherence rate',
      'erreur_numero':     'Please enter your number',
      'erreur_mdp':        'Minimum 6 characters',
      'erreur_login':      'Incorrect number or password',
      'erreur_existe':     'This number is already registered',
    },

    // ── KISWAHILI ────────────────────────────────────────────────
    'sw': {
      'app_nom':           'ConfidantAfya',
      'app_slogan':        'Afya yako, kwa siri kamili',
      'choisir_langue':    'Chagua lugha yako',
      'continuer':         'Endelea',
      'connexion':         'Kuingia kwa Mgonjwa',
      'nouveau_compte':    'Akaunti mpya',
      'se_connecter':      'Ingia',
      'nom_complet':       'Jina lako kamili',
      'numero_telephone':  'Nambari ya simu',
      'mot_de_passe':      'Nenosiri',
      'creer_compte':      'Unda akaunti yangu',
      'bonjour':           'Habari za asubuhi,',
      'bon_apres_midi':    'Habari za mchana,',
      'bonsoir':           'Habari za jioni,',
      'observance':        'Uzingativu wa mwezi',
      'rappels':           'Vikumbusho',
      'ajouter':           'Ongeza',
      'medicament':        'Dawa za leo',
      'profil':            'Wasifu wangu',
      'discretion':        'Hali ya faragha',
      'accueil':           'Nyumbani',
      'creer_pin':         'Unda PIN yako',
      'confirmer_pin':     'Thibitisha PIN yako',
      'enregistrer':       'Hifadhi',
      'nom_medicament':    'Jina la dawa',
      'dosage':            'Kipimo',
      'heure_prise':       'Wakati wa kumeza',
      'rappel_ajoute':     'Kumbusho limeongezwa',
      'prise_confirmee':   'Dawa imechukuliwa',
      'deconnecter':       'Toka',
      'annuler':           'Ghairi',
      'parametres':        'Mipangilio',
      'historique':        'Historia ya siku 30',
      'taux_observance':   'Kiwango cha uzingativu',
      'erreur_numero':     'Tafadhali ingiza nambari yako',
      'erreur_mdp':        'Angalau herufi 6',
      'erreur_login':      'Nambari au nenosiri si sahihi',
      'erreur_existe':     'Nambari hii tayari imesajiliwa',
    },
  };

  // Langue actuelle
  static String _langueActuelle = 'fr';

  // Change la langue
  static void changerLangue(String code) {
    if (_traductions.containsKey(code)) {
      _langueActuelle = code;
    }
  }

  // Récupère une traduction
  static String t(String cle) {
    return _traductions[_langueActuelle]?[cle] ??
        _traductions['fr']?[cle] ??
        cle;
  }

  // Langue actuelle
  static String get langueActuelle => _langueActuelle;
}