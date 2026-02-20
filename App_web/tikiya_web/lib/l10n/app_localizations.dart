import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static const supportedLocales = [
    Locale('fr'),
    Locale('en'),
    Locale('ar'),
  ];

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const Map<String, Map<String, String>> _localizedValues = {
    'fr': {
      'app_title': 'Tikiya',
      'nav_discover': 'Découvrir',
      'nav_events': 'Événements',
      'nav_participants': 'Participants',
      'cta_login': 'Se connecter',
      'cta_register': "S'inscrire",
      'cta_im_participant': 'Je suis participant',
      'cta_im_organizer': 'Je suis organisateur',
      'cta_back': 'Retour',
      'auth_login_title': 'Connexion',
      'auth_register_title': 'Inscription',
      'auth_email': 'Email',
      'auth_password': 'Mot de passe',
      'auth_email_required': 'Email requis',
      'auth_password_required': 'Mot de passe requis',
      'auth_no_account': "Pas de compte ? S'inscrire",
      'auth_have_account': 'Déjà un compte ? Se connecter',
      'auth_organizer_account': 'Compte organisateur',
      'landing_tagline': 'Billets, événements, contrôle — tout en un.',
      'landing_note':
          "Avant connexion, l'espace est identique. Après, on te redirige selon ton rôle.",
      'home_title_compact': 'Le moyen le plus simple\nd’entrer aux meilleurs\névénements',
      'home_title_full': 'Le moyen le plus simple\nd’entrer aux meilleurs événements',
      'home_subtitle': 'Billets sécurisés, QR code et accès rapide.',
      'home_google_play': 'Télécharger sur Google Play',
      'home_app_store': "Télécharger sur l’App Store",
      'home_view_events': 'Voir tous les événements',
      'home_phone_semantics': 'Aperçu de l’application mobile',
      'events_title': 'À ne pas manquer en Algérie',
      'events_subtitle':
          'Découvrez et réservez vos prochains événements: concerts,\nsoirées, spectacles et plus encore.',
      'events_search_hint': 'Rechercher un événement...',
      'events_filter_city': 'Alger',
      'events_filter_weekend': 'Ce week-end',
      'events_filter_filters': 'Filtres',
      'events_empty_title': 'Aucun événement pour le moment',
      'events_empty_body':
          'Les événements à venir seront bientôt disponibles.\nRevenez plus tard pour découvrir nos prochains événements !',
      'participant_title': 'Simplifiez vos sorties\navec Tikiya',
      'participant_subtitle':
          'Accédez bientôt à vos billets, QR code et événements en un seul endroit.',
      'participant_feature1_title': 'Billet QR code\nsécurisé',
      'participant_feature1_sub': 'Votre billet généré\ninstantanément.',
      'participant_feature2_title': 'Billets\nMarketplace',
      'participant_feature2_sub': 'Revendez vos billets\nfacilement.',
      'participant_feature3_title': 'Paiement flexible',
      'participant_feature3_sub': 'Carte bancaire ou en\nespèces au bureau de tabac.',
      'orga_logout': 'Se déconnecter',
      'orga_welcome': 'Bienvenue ! (organisateur)',
      'orga_needs_title': 'Présentez-nous votre activité',
      'orga_needs_subtitle': 'Vous serez recontacté par notre équipe',
      'orga_needs_note': 'Ce formulaire est réservé aux organisateurs & agences',
      'field_first_name': 'Prénom*',
      'field_last_name': 'Nom*',
      'field_email': 'E-mail*',
      'field_phone': 'Téléphone*',
      'field_website': 'Site web*',
      'hint_first_name': 'Ryad',
      'hint_last_name': 'Mahrez',
      'hint_email': 'votre@email-pro.dz',
      'hint_phone': '+213 # ## ## ## ##',
      'hint_website': 'Liens de votre site',
      'orga_needs_submit': 'Soumettre mes informations',
      'orga_public_title': 'Boostez la vente de vos billets,\nsuivez vos événements\nen temps réel',
      'orga_public_subtitle':
          'Proposez vos événements, boostez vos ventes et\naccédez aux meilleures statistiques avec\nun panel organisateur intuitif.',
      'orga_feature1_title': 'Tableau de bord complet',
      'orga_feature1_sub': 'Suivez tous vos événements en\nun coup d\'œil',
      'orga_feature2_title': 'Statistiques en temps réel',
      'orga_feature2_sub': 'Consultez vos ventes, billets vendus,\net tendances en direct',
      'orga_feature3_title': 'Création d\'événements facile',
      'orga_feature3_sub': 'Postez vos événements\nen quelques clics',
      'orga_feature4_title': 'Gestion en live',
      'orga_feature4_sub': 'Modifiez la capacité, ouvrez les ventes,\nsuivez les entrées',
      'orga_cta_primary': 'Commencer maintenant',
      'orga_cta_secondary': 'Échanger sur vos besoins',
    },
    'en': {
      'app_title': 'Tikiya',
      'nav_discover': 'Discover',
      'nav_events': 'Events',
      'nav_participants': 'Participants',
      'cta_login': 'Sign in',
      'cta_register': 'Sign up',
      'cta_im_participant': "I'm a participant",
      'cta_im_organizer': "I'm an organizer",
      'cta_back': 'Back',
      'auth_login_title': 'Sign in',
      'auth_register_title': 'Sign up',
      'auth_email': 'Email',
      'auth_password': 'Password',
      'auth_email_required': 'Email required',
      'auth_password_required': 'Password required',
      'auth_no_account': 'No account? Sign up',
      'auth_have_account': 'Already have an account? Sign in',
      'auth_organizer_account': 'Organizer account',
      'landing_tagline': 'Tickets, events, control — all in one.',
      'landing_note':
          "Before signing in, the space is the same. After, you’re redirected based on your role.",
      'home_title_compact': 'The easiest way\nto access the best\nevents',
      'home_title_full': 'The easiest way\nto access the best events',
      'home_subtitle': 'Secure tickets, QR code and fast entry.',
      'home_google_play': 'Get it on Google Play',
      'home_app_store': 'Download on the App Store',
      'home_view_events': 'See all events',
      'home_phone_semantics': 'Mobile app preview',
      'events_title': 'Must-see in Algeria',
      'events_subtitle':
          'Discover and book your next events: concerts,\nparties, shows and more.',
      'events_search_hint': 'Search an event...',
      'events_filter_city': 'Algiers',
      'events_filter_weekend': 'This weekend',
      'events_filter_filters': 'Filters',
      'events_empty_title': 'No events for now',
      'events_empty_body':
          'Upcoming events will be available soon.\nCome back later to discover our next events!',
      'participant_title': 'Simplify your outings\nwith Tikiya',
      'participant_subtitle': 'Access your tickets, QR code and events in one place.',
      'participant_feature1_title': 'Secure QR code\nticket',
      'participant_feature1_sub': 'Your ticket generated\ninstantly.',
      'participant_feature2_title': 'Tickets\nMarketplace',
      'participant_feature2_sub': 'Resell your tickets\neasily.',
      'participant_feature3_title': 'Flexible payment',
      'participant_feature3_sub': 'Card or cash\nat the tobacco shop.',
      'orga_logout': 'Sign out',
      'orga_welcome': 'Welcome! (organizer)',
      'orga_needs_title': 'Tell us about your activity',
      'orga_needs_subtitle': 'Our team will contact you',
      'orga_needs_note': 'This form is reserved for organizers & agencies',
      'field_first_name': 'First name*',
      'field_last_name': 'Last name*',
      'field_email': 'Email*',
      'field_phone': 'Phone*',
      'field_website': 'Website*',
      'hint_first_name': 'Ryad',
      'hint_last_name': 'Mahrez',
      'hint_email': 'your@pro-email.dz',
      'hint_phone': '+213 # ## ## ## ##',
      'hint_website': 'Your website link',
      'orga_needs_submit': 'Submit my information',
      'orga_public_title': 'Boost ticket sales,\ntrack your events\nin real time',
      'orga_public_subtitle':
          'List your events, boost sales and\naccess the best stats with\nan intuitive organizer dashboard.',
      'orga_feature1_title': 'Complete dashboard',
      'orga_feature1_sub': 'Track all your events at\na glance',
      'orga_feature2_title': 'Real-time analytics',
      'orga_feature2_sub': 'View your sales, tickets sold,\nand live trends',
      'orga_feature3_title': 'Easy event creation',
      'orga_feature3_sub': 'Post your events\nin a few clicks',
      'orga_feature4_title': 'Live management',
      'orga_feature4_sub': 'Adjust capacity, open sales,\ntrack entries',
      'orga_cta_primary': 'Get started',
      'orga_cta_secondary': 'Discuss your needs',
    },
    'ar': {
      'app_title': 'تيكيا',
      'nav_discover': 'اكتشف',
      'nav_events': 'الفعاليات',
      'nav_participants': 'المشاركون',
      'cta_login': 'تسجيل الدخول',
      'cta_register': 'إنشاء حساب',
      'cta_im_participant': 'أنا مشارك',
      'cta_im_organizer': 'أنا منظّم',
      'cta_back': 'رجوع',
      'auth_login_title': 'تسجيل الدخول',
      'auth_register_title': 'إنشاء حساب',
      'auth_email': 'البريد الإلكتروني',
      'auth_password': 'كلمة المرور',
      'auth_email_required': 'البريد الإلكتروني مطلوب',
      'auth_password_required': 'كلمة المرور مطلوبة',
      'auth_no_account': 'لا تملك حسابًا؟ أنشئ حسابًا',
      'auth_have_account': 'لديك حساب؟ سجّل الدخول',
      'auth_organizer_account': 'حساب منظّم',
      'landing_tagline': 'تذاكر، فعاليات، تحكّم — الكل في واحد.',
      'landing_note': 'قبل تسجيل الدخول، المساحة واحدة. بعد ذلك نوجّهك حسب دورك.',
      'home_title_compact': 'أسهل طريقة\nللوصول إلى أفضل\nالفعاليات',
      'home_title_full': 'أسهل طريقة\nللوصول إلى أفضل الفعاليات',
      'home_subtitle': 'تذاكر آمنة، رمز QR ودخول سريع.',
      'home_google_play': 'احصل عليه من Google Play',
      'home_app_store': 'حمّل من App Store',
      'home_view_events': 'عرض كل الفعاليات',
      'home_phone_semantics': 'معاينة تطبيق الهاتف',
      'events_title': 'لا تفوّت في الجزائر',
      'events_subtitle':
          'اكتشف واحجز فعالياتك القادمة: حفلات موسيقية،\nسهرات، عروض وأكثر.',
      'events_search_hint': 'ابحث عن فعالية...',
      'events_filter_city': 'الجزائر',
      'events_filter_weekend': 'نهاية هذا الأسبوع',
      'events_filter_filters': 'فلاتر',
      'events_empty_title': 'لا توجد فعاليات حاليًا',
      'events_empty_body': 'ستكون الفعاليات القادمة متاحة قريبًا.\nعُد لاحقًا لاكتشاف فعالياتنا القادمة!',
      'participant_title': 'بسّط خرجاتك\nمع تيكيا',
      'participant_subtitle': 'احصل على تذاكرك ورمز QR والفعاليات في مكان واحد.',
      'participant_feature1_title': 'تذكرة QR\nمؤمّنة',
      'participant_feature1_sub': 'تذكرتك تُنشأ\nفورًا.',
      'participant_feature2_title': 'سوق\nالتذاكر',
      'participant_feature2_sub': 'أعِد بيع تذاكرك\nبسهولة.',
      'participant_feature3_title': 'دفع مرن',
      'participant_feature3_sub': 'بطاقة مصرفية أو نقدًا\nفي محل التبغ.',
      'orga_logout': 'تسجيل الخروج',
      'orga_welcome': 'مرحبًا! (منظّم)',
      'orga_needs_title': 'عرّفنا على نشاطك',
      'orga_needs_subtitle': 'سيتواصل معك فريقنا',
      'orga_needs_note': 'هذا النموذج مخصص للمنظمين والوكالات',
      'field_first_name': 'الاسم الأول*',
      'field_last_name': 'اسم العائلة*',
      'field_email': 'البريد الإلكتروني*',
      'field_phone': 'الهاتف*',
      'field_website': 'الموقع الإلكتروني*',
      'hint_first_name': 'Ryad',
      'hint_last_name': 'Mahrez',
      'hint_email': 'your@pro-email.dz',
      'hint_phone': '+213 # ## ## ## ##',
      'hint_website': 'رابط موقعك',
      'orga_needs_submit': 'إرسال معلوماتي',
      'orga_public_title': 'عزّز مبيعات التذاكر،\nوتابع فعالياتك\nفي الوقت الحقيقي',
      'orga_public_subtitle':
          'اعرض فعالياتك، عزّز مبيعاتك\nواطّلع على أفضل الإحصاءات عبر\nلوحة منظّم سهلة الاستخدام.',
      'orga_feature1_title': 'لوحة تحكم كاملة',
      'orga_feature1_sub': 'تابع جميع فعالياتك\nبنظرة واحدة',
      'orga_feature2_title': 'إحصاءات فورية',
      'orga_feature2_sub': 'اطّلع على المبيعات والتذاكر المباعة\nوالاتجاهات مباشرة',
      'orga_feature3_title': 'إنشاء فعاليات بسهولة',
      'orga_feature3_sub': 'انشر فعالياتك\nببضع نقرات',
      'orga_feature4_title': 'إدارة مباشرة',
      'orga_feature4_sub': 'عدّل السعة، افتح المبيعات،\nوتابع الدخول',
      'orga_cta_primary': 'ابدأ الآن',
      'orga_cta_secondary': 'ناقش احتياجاتك',
    },
  };

  String t(String key) {
    final lang = locale.languageCode;
    return _localizedValues[lang]?[key] ?? _localizedValues['fr']?[key] ?? key;
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['fr', 'en', 'ar'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async => AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
