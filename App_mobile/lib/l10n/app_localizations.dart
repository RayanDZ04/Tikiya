import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In fr, this message translates to:
  /// **'Tikiya'**
  String get appTitle;

  /// No description provided for @langFrench.
  ///
  /// In fr, this message translates to:
  /// **'Français'**
  String get langFrench;

  /// No description provided for @langArabic.
  ///
  /// In fr, this message translates to:
  /// **'العربية'**
  String get langArabic;

  /// No description provided for @langEnglish.
  ///
  /// In fr, this message translates to:
  /// **'Anglais'**
  String get langEnglish;

  /// No description provided for @langSystem.
  ///
  /// In fr, this message translates to:
  /// **'Système'**
  String get langSystem;

  /// No description provided for @navHome.
  ///
  /// In fr, this message translates to:
  /// **'Accueil'**
  String get navHome;

  /// No description provided for @navTickets.
  ///
  /// In fr, this message translates to:
  /// **'Mes billets'**
  String get navTickets;

  /// No description provided for @navMarket.
  ///
  /// In fr, this message translates to:
  /// **'Ma billetterie'**
  String get navMarket;

  /// No description provided for @navOrga.
  ///
  /// In fr, this message translates to:
  /// **'Mes events'**
  String get navOrga;

  /// No description provided for @navProfile.
  ///
  /// In fr, this message translates to:
  /// **'Profil'**
  String get navProfile;

  /// No description provided for @navLogin.
  ///
  /// In fr, this message translates to:
  /// **'Connexion'**
  String get navLogin;

  /// No description provided for @authLogin.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get authLogin;

  /// No description provided for @authRegister.
  ///
  /// In fr, this message translates to:
  /// **'S\'inscrire'**
  String get authRegister;

  /// No description provided for @authLogout.
  ///
  /// In fr, this message translates to:
  /// **'Se déconnecter'**
  String get authLogout;

  /// No description provided for @homeTagline.
  ///
  /// In fr, this message translates to:
  /// **'Explorez, réservez et vivez les meilleurs événements'**
  String get homeTagline;

  /// No description provided for @homeSearchHint.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher un événement...'**
  String get homeSearchHint;

  /// No description provided for @homeFiltersTitle.
  ///
  /// In fr, this message translates to:
  /// **'Filtres'**
  String get homeFiltersTitle;

  /// No description provided for @homeFiltersClose.
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get homeFiltersClose;

  /// No description provided for @homeFiltersReset.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser'**
  String get homeFiltersReset;

  /// No description provided for @homeFiltersApply.
  ///
  /// In fr, this message translates to:
  /// **'Appliquer'**
  String get homeFiltersApply;

  /// No description provided for @homeNoContentYet.
  ///
  /// In fr, this message translates to:
  /// **'Aucun contenu pour le moment'**
  String get homeNoContentYet;

  /// No description provided for @filterMusic.
  ///
  /// In fr, this message translates to:
  /// **'Musique'**
  String get filterMusic;

  /// No description provided for @filterCulture.
  ///
  /// In fr, this message translates to:
  /// **'Culture'**
  String get filterCulture;

  /// No description provided for @filterEntertainment.
  ///
  /// In fr, this message translates to:
  /// **'Divertissement'**
  String get filterEntertainment;

  /// No description provided for @filterPopular.
  ///
  /// In fr, this message translates to:
  /// **'Populaire'**
  String get filterPopular;

  /// No description provided for @filterCity.
  ///
  /// In fr, this message translates to:
  /// **'Ville'**
  String get filterCity;

  /// No description provided for @filterCityHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex: Alger'**
  String get filterCityHint;

  /// No description provided for @filterDate.
  ///
  /// In fr, this message translates to:
  /// **'Date'**
  String get filterDate;

  /// No description provided for @filterDateHint.
  ///
  /// In fr, this message translates to:
  /// **'Choisir une date'**
  String get filterDateHint;

  /// No description provided for @noResults.
  ///
  /// In fr, this message translates to:
  /// **'Aucun résultat'**
  String get noResults;

  /// No description provided for @loginTitle.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get loginTitle;

  /// No description provided for @emailLabel.
  ///
  /// In fr, this message translates to:
  /// **'Adresse e-mail'**
  String get emailLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get passwordLabel;

  /// No description provided for @emailRequired.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez entrer votre e-mail'**
  String get emailRequired;

  /// No description provided for @passwordRequired.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez entrer votre mot de passe'**
  String get passwordRequired;

  /// No description provided for @loginAction.
  ///
  /// In fr, this message translates to:
  /// **'Connexion'**
  String get loginAction;

  /// No description provided for @loginProgress.
  ///
  /// In fr, this message translates to:
  /// **'Connexion...'**
  String get loginProgress;

  /// No description provided for @connected.
  ///
  /// In fr, this message translates to:
  /// **'Connecté'**
  String get connected;

  /// No description provided for @googleLogin.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter avec Google'**
  String get googleLogin;

  /// No description provided for @googleSignup.
  ///
  /// In fr, this message translates to:
  /// **'S\'inscrire avec Google'**
  String get googleSignup;

  /// No description provided for @googleFailed.
  ///
  /// In fr, this message translates to:
  /// **'Échec Google'**
  String get googleFailed;

  /// No description provided for @googleProgress.
  ///
  /// In fr, this message translates to:
  /// **'Connexion Google...'**
  String get googleProgress;

  /// No description provided for @googleUnavailableTitle.
  ///
  /// In fr, this message translates to:
  /// **'Connexion Google indisponible'**
  String get googleUnavailableTitle;

  /// No description provided for @googleUnavailableBody.
  ///
  /// In fr, this message translates to:
  /// **'Erreur 10 détectée sur l\'émulateur. Activer le mode démo pour tester l\'UI sans Google ?'**
  String get googleUnavailableBody;

  /// No description provided for @cancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get cancel;

  /// No description provided for @activate.
  ///
  /// In fr, this message translates to:
  /// **'Activer'**
  String get activate;

  /// No description provided for @demoEnabled.
  ///
  /// In fr, this message translates to:
  /// **'Mode démo activé'**
  String get demoEnabled;

  /// No description provided for @signupTitle.
  ///
  /// In fr, this message translates to:
  /// **'S\'inscrire'**
  String get signupTitle;

  /// No description provided for @firstNameLabel.
  ///
  /// In fr, this message translates to:
  /// **'Prénom'**
  String get firstNameLabel;

  /// No description provided for @lastNameLabel.
  ///
  /// In fr, this message translates to:
  /// **'Nom'**
  String get lastNameLabel;

  /// No description provided for @firstNameRequired.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez entrer votre prénom'**
  String get firstNameRequired;

  /// No description provided for @lastNameRequired.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez entrer votre nom'**
  String get lastNameRequired;

  /// No description provided for @confirmPasswordLabel.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer le mot de passe'**
  String get confirmPasswordLabel;

  /// No description provided for @confirmPasswordRequired.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez confirmer votre mot de passe'**
  String get confirmPasswordRequired;

  /// No description provided for @passwordMismatch.
  ///
  /// In fr, this message translates to:
  /// **'Les mots de passe ne correspondent pas'**
  String get passwordMismatch;

  /// No description provided for @fixFields.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez corriger les champs'**
  String get fixFields;

  /// No description provided for @signupProgress.
  ///
  /// In fr, this message translates to:
  /// **'Inscription...'**
  String get signupProgress;

  /// No description provided for @signupSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Inscrit, vous pouvez vous connecter'**
  String get signupSuccess;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
