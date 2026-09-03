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

  /// No description provided for @roleSelectionTitle.
  ///
  /// In fr, this message translates to:
  /// **'Qui êtes-vous ?'**
  String get roleSelectionTitle;

  /// No description provided for @roleSelectionSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez votre profil pour créer votre compte'**
  String get roleSelectionSubtitle;

  /// No description provided for @roleParticipant.
  ///
  /// In fr, this message translates to:
  /// **'Participant'**
  String get roleParticipant;

  /// No description provided for @roleParticipantDesc.
  ///
  /// In fr, this message translates to:
  /// **'Je veux découvrir et réserver des événements'**
  String get roleParticipantDesc;

  /// No description provided for @roleOrganisateur.
  ///
  /// In fr, this message translates to:
  /// **'Organisateur'**
  String get roleOrganisateur;

  /// No description provided for @roleOrganisateurDesc.
  ///
  /// In fr, this message translates to:
  /// **'Je veux créer et gérer des événements'**
  String get roleOrganisateurDesc;

  /// No description provided for @orgaSignupTitle.
  ///
  /// In fr, this message translates to:
  /// **'Inscription organisateur'**
  String get orgaSignupTitle;

  /// No description provided for @orgaCompanyLabel.
  ///
  /// In fr, this message translates to:
  /// **'Nom de l\'entreprise'**
  String get orgaCompanyLabel;

  /// No description provided for @orgaCompanyRequired.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez entrer le nom de votre entreprise'**
  String get orgaCompanyRequired;

  /// No description provided for @orgaPhoneLabel.
  ///
  /// In fr, this message translates to:
  /// **'Numéro de téléphone'**
  String get orgaPhoneLabel;

  /// No description provided for @orgaPhoneRequired.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez entrer votre numéro de téléphone'**
  String get orgaPhoneRequired;

  /// No description provided for @orgaWebsiteLabel.
  ///
  /// In fr, this message translates to:
  /// **'Site web (optionnel)'**
  String get orgaWebsiteLabel;

  /// No description provided for @orgaProEmailLabel.
  ///
  /// In fr, this message translates to:
  /// **'Email professionnel'**
  String get orgaProEmailLabel;

  /// No description provided for @orgaHomeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mes événements'**
  String get orgaHomeTitle;

  /// No description provided for @orgaEventsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Créer un événement'**
  String get orgaEventsTitle;

  /// No description provided for @orgaEventsEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun événement créé'**
  String get orgaEventsEmpty;

  /// No description provided for @orgaCreateEvent.
  ///
  /// In fr, this message translates to:
  /// **'Créer un événement'**
  String get orgaCreateEvent;

  /// No description provided for @orgaAccountTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mon compte'**
  String get orgaAccountTitle;

  /// No description provided for @eventTitleLabel.
  ///
  /// In fr, this message translates to:
  /// **'Titre de l\'événement'**
  String get eventTitleLabel;

  /// No description provided for @eventTitleRequired.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez entrer un titre'**
  String get eventTitleRequired;

  /// No description provided for @eventDateLabel.
  ///
  /// In fr, this message translates to:
  /// **'Date et heure'**
  String get eventDateLabel;

  /// No description provided for @eventDateRequired.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez entrer une date'**
  String get eventDateRequired;

  /// No description provided for @eventLocationLabel.
  ///
  /// In fr, this message translates to:
  /// **'Lieu'**
  String get eventLocationLabel;

  /// No description provided for @eventDescriptionLabel.
  ///
  /// In fr, this message translates to:
  /// **'Description'**
  String get eventDescriptionLabel;

  /// No description provided for @eventPriceLabel.
  ///
  /// In fr, this message translates to:
  /// **'Prix (DZD)'**
  String get eventPriceLabel;

  /// No description provided for @eventCapacityLabel.
  ///
  /// In fr, this message translates to:
  /// **'Capacité'**
  String get eventCapacityLabel;

  /// No description provided for @eventCreateSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Événement créé !'**
  String get eventCreateSuccess;

  /// No description provided for @eventDeleteConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer cet événement ?'**
  String get eventDeleteConfirm;

  /// No description provided for @eventDeleteSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Événement supprimé'**
  String get eventDeleteSuccess;

  /// No description provided for @delete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get delete;

  /// No description provided for @confirm.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer'**
  String get confirm;

  /// No description provided for @navDashboard.
  ///
  /// In fr, this message translates to:
  /// **'Tableau de bord'**
  String get navDashboard;

  /// No description provided for @dashboardWelcome.
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue,'**
  String get dashboardWelcome;

  /// No description provided for @dashboardTotalEvents.
  ///
  /// In fr, this message translates to:
  /// **'Événements'**
  String get dashboardTotalEvents;

  /// No description provided for @dashboardUpcoming.
  ///
  /// In fr, this message translates to:
  /// **'À venir'**
  String get dashboardUpcoming;

  /// No description provided for @dashboardTotalCapacity.
  ///
  /// In fr, this message translates to:
  /// **'Places totales'**
  String get dashboardTotalCapacity;

  /// No description provided for @dashboardPast.
  ///
  /// In fr, this message translates to:
  /// **'Passé'**
  String get dashboardPast;

  /// No description provided for @dashboardRevenue.
  ///
  /// In fr, this message translates to:
  /// **'Revenu réel'**
  String get dashboardRevenue;

  /// No description provided for @dashboardEstimatedRevenue.
  ///
  /// In fr, this message translates to:
  /// **'Estimation (places)'**
  String get dashboardEstimatedRevenue;

  /// No description provided for @dashboardQuickActions.
  ///
  /// In fr, this message translates to:
  /// **'Actions rapides'**
  String get dashboardQuickActions;

  /// No description provided for @dashboardMyEvents.
  ///
  /// In fr, this message translates to:
  /// **'Mes événements'**
  String get dashboardMyEvents;

  /// No description provided for @dashboardRecent.
  ///
  /// In fr, this message translates to:
  /// **'Événements récents'**
  String get dashboardRecent;

  /// No description provided for @profilePseudo.
  ///
  /// In fr, this message translates to:
  /// **'Pseudo'**
  String get profilePseudo;

  /// No description provided for @profileSettings.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres'**
  String get profileSettings;

  /// No description provided for @settingsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres du compte'**
  String get settingsTitle;

  /// No description provided for @settingsChangeEmail.
  ///
  /// In fr, this message translates to:
  /// **'Modifier l\'adresse email'**
  String get settingsChangeEmail;

  /// No description provided for @settingsChangeEmailSub.
  ///
  /// In fr, this message translates to:
  /// **'Changer l\'email de connexion'**
  String get settingsChangeEmailSub;

  /// No description provided for @settingsChangePassword.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le mot de passe'**
  String get settingsChangePassword;

  /// No description provided for @settingsChangePasswordSub.
  ///
  /// In fr, this message translates to:
  /// **'Changer le mot de passe actuel'**
  String get settingsChangePasswordSub;

  /// No description provided for @settingsEmailSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Adresse email modifiée avec succès !'**
  String get settingsEmailSuccess;

  /// No description provided for @settingsPasswordSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe modifié avec succès !'**
  String get settingsPasswordSuccess;

  /// No description provided for @settingsNewEmail.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle adresse email'**
  String get settingsNewEmail;

  /// No description provided for @settingsCurrentPassword.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe actuel'**
  String get settingsCurrentPassword;

  /// No description provided for @settingsNewPassword.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau mot de passe'**
  String get settingsNewPassword;

  /// No description provided for @settingsPasswordConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer le nouveau mot de passe'**
  String get settingsPasswordConfirm;

  /// No description provided for @settingsChangeUsername.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le pseudo'**
  String get settingsChangeUsername;

  /// No description provided for @settingsChangeUsernameSub.
  ///
  /// In fr, this message translates to:
  /// **'Changer votre nom affiché'**
  String get settingsChangeUsernameSub;

  /// No description provided for @settingsNewUsername.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau pseudo'**
  String get settingsNewUsername;

  /// No description provided for @settingsUsernameHint.
  ///
  /// In fr, this message translates to:
  /// **'ex : Goten42'**
  String get settingsUsernameHint;

  /// No description provided for @settingsUsernameSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Pseudo modifié avec succès !'**
  String get settingsUsernameSuccess;

  /// No description provided for @settingsSaving.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrement...'**
  String get settingsSaving;

  /// No description provided for @fieldRequired.
  ///
  /// In fr, this message translates to:
  /// **'Champ requis'**
  String get fieldRequired;

  /// No description provided for @fieldEmailInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Email invalide'**
  String get fieldEmailInvalid;

  /// No description provided for @fieldMin2Chars.
  ///
  /// In fr, this message translates to:
  /// **'Au moins 2 caractères'**
  String get fieldMin2Chars;

  /// No description provided for @fieldMin8Chars.
  ///
  /// In fr, this message translates to:
  /// **'Au moins 8 caractères'**
  String get fieldMin8Chars;

  /// No description provided for @editEventTitle.
  ///
  /// In fr, this message translates to:
  /// **'Modifier l\'événement'**
  String get editEventTitle;

  /// No description provided for @editEventSave.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer les modifications'**
  String get editEventSave;

  /// No description provided for @editEventSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Événement modifié !'**
  String get editEventSuccess;

  /// No description provided for @editEventSaving.
  ///
  /// In fr, this message translates to:
  /// **'Modification...'**
  String get editEventSaving;

  /// No description provided for @eventImageAdd.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une image'**
  String get eventImageAdd;

  /// No description provided for @eventImageChange.
  ///
  /// In fr, this message translates to:
  /// **'Changer l\'image'**
  String get eventImageChange;

  /// No description provided for @eventImageDelete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer l\'image'**
  String get eventImageDelete;

  /// No description provided for @eventUploading.
  ///
  /// In fr, this message translates to:
  /// **'Envoi image...'**
  String get eventUploading;

  /// No description provided for @eventCreating.
  ///
  /// In fr, this message translates to:
  /// **'Création...'**
  String get eventCreating;

  /// No description provided for @paymentSecured.
  ///
  /// In fr, this message translates to:
  /// **'Paiement sécurisé via Chargily Pay'**
  String get paymentSecured;

  /// No description provided for @paymentTickets.
  ///
  /// In fr, this message translates to:
  /// **'Nombre de billets'**
  String get paymentTickets;

  /// No description provided for @paymentRemaining.
  ///
  /// In fr, this message translates to:
  /// **'billet(s) restant(s)'**
  String get paymentRemaining;

  /// No description provided for @paymentTotal.
  ///
  /// In fr, this message translates to:
  /// **'Total'**
  String get paymentTotal;

  /// No description provided for @paymentBuyTicket.
  ///
  /// In fr, this message translates to:
  /// **'Acheter un billet'**
  String get paymentBuyTicket;

  /// No description provided for @paymentBuyTickets.
  ///
  /// In fr, this message translates to:
  /// **'Acheter {n} billets'**
  String paymentBuyTickets(int n);

  /// No description provided for @paymentRedirecting.
  ///
  /// In fr, this message translates to:
  /// **'Redirection...'**
  String get paymentRedirecting;

  /// No description provided for @paymentError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors du paiement.'**
  String get paymentError;

  /// No description provided for @paymentBrowserError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'ouvrir le navigateur.'**
  String get paymentBrowserError;

  /// No description provided for @ticketsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mes Billets'**
  String get ticketsTitle;

  /// No description provided for @ticketsEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun billet pour le moment'**
  String get ticketsEmpty;

  /// No description provided for @ticketsDownloadQr.
  ///
  /// In fr, this message translates to:
  /// **'Télécharger QR'**
  String get ticketsDownloadQr;

  /// No description provided for @ticketsQrDownloaded.
  ///
  /// In fr, this message translates to:
  /// **'QR téléchargé !'**
  String get ticketsQrDownloaded;

  /// No description provided for @filterAll.
  ///
  /// In fr, this message translates to:
  /// **'Tous'**
  String get filterAll;

  /// No description provided for @freeEntry.
  ///
  /// In fr, this message translates to:
  /// **'Entrée gratuite'**
  String get freeEntry;

  /// No description provided for @paymentMethodLabel.
  ///
  /// In fr, this message translates to:
  /// **'Moyen de paiement'**
  String get paymentMethodLabel;

  /// No description provided for @fieldPasswordSameAsCurrent.
  ///
  /// In fr, this message translates to:
  /// **'Doit être différent du mot de passe actuel'**
  String get fieldPasswordSameAsCurrent;

  /// No description provided for @loginRequired.
  ///
  /// In fr, this message translates to:
  /// **'Connectez-vous pour acheter un billet.'**
  String get loginRequired;

  /// No description provided for @pricePerTicketLabel.
  ///
  /// In fr, this message translates to:
  /// **'{price} DZD / billet'**
  String pricePerTicketLabel(String price);

  /// No description provided for @freeEntryReserveBtn.
  ///
  /// In fr, this message translates to:
  /// **'Entrée gratuite — Réserver'**
  String get freeEntryReserveBtn;

  /// No description provided for @paymentSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Paiement réussi !'**
  String get paymentSuccess;

  /// No description provided for @paymentFailed.
  ///
  /// In fr, this message translates to:
  /// **'Paiement échoué'**
  String get paymentFailed;

  /// No description provided for @paymentSuccessMsg.
  ///
  /// In fr, this message translates to:
  /// **'Votre billet a été confirmé.\nRetrouvez-le dans \"Mes Billets\".'**
  String get paymentSuccessMsg;

  /// No description provided for @paymentFailedMsg.
  ///
  /// In fr, this message translates to:
  /// **'Le paiement n\'a pas pu être traité.\nVeuillez réessayer.'**
  String get paymentFailedMsg;

  /// No description provided for @viewMyTickets.
  ///
  /// In fr, this message translates to:
  /// **'Voir mes billets'**
  String get viewMyTickets;

  /// No description provided for @backToHome.
  ///
  /// In fr, this message translates to:
  /// **'Retour à l\'accueil'**
  String get backToHome;

  /// No description provided for @ticketsLoginRequired.
  ///
  /// In fr, this message translates to:
  /// **'Connectez-vous pour voir vos billets.'**
  String get ticketsLoginRequired;

  /// No description provided for @ticketsLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger vos billets.'**
  String get ticketsLoadError;

  /// No description provided for @ticketStatusConfirmed.
  ///
  /// In fr, this message translates to:
  /// **'Confirmé'**
  String get ticketStatusConfirmed;

  /// No description provided for @ticketStatusPending.
  ///
  /// In fr, this message translates to:
  /// **'En attente'**
  String get ticketStatusPending;

  /// No description provided for @ticketStatusFailed.
  ///
  /// In fr, this message translates to:
  /// **'Échoué'**
  String get ticketStatusFailed;

  /// No description provided for @ticketStatusCanceled.
  ///
  /// In fr, this message translates to:
  /// **'Annulé'**
  String get ticketStatusCanceled;

  /// No description provided for @ticketSwipeQr.
  ///
  /// In fr, this message translates to:
  /// **'Glisser les QR'**
  String get ticketSwipeQr;

  /// No description provided for @ticketTapZoom.
  ///
  /// In fr, this message translates to:
  /// **'Appuyer pour agrandir'**
  String get ticketTapZoom;

  /// No description provided for @ticketsViewEvents.
  ///
  /// In fr, this message translates to:
  /// **'Voir les événements'**
  String get ticketsViewEvents;

  /// No description provided for @retry.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get retry;

  /// No description provided for @free.
  ///
  /// In fr, this message translates to:
  /// **'Gratuit'**
  String get free;

  /// No description provided for @eventLabel.
  ///
  /// In fr, this message translates to:
  /// **'ÉVÉNEMENT'**
  String get eventLabel;

  /// No description provided for @dashboardTicketsSold.
  ///
  /// In fr, this message translates to:
  /// **'Billets vendus'**
  String get dashboardTicketsSold;

  /// No description provided for @dashboardTicketsRemaining.
  ///
  /// In fr, this message translates to:
  /// **'Billets restants'**
  String get dashboardTicketsRemaining;

  /// No description provided for @dashboardPricePerTicket.
  ///
  /// In fr, this message translates to:
  /// **'Prix / billet'**
  String get dashboardPricePerTicket;

  /// No description provided for @dashboardFillRate.
  ///
  /// In fr, this message translates to:
  /// **'Taux de remplissage'**
  String get dashboardFillRate;

  /// No description provided for @dashboardRevenueGenerated.
  ///
  /// In fr, this message translates to:
  /// **'Revenus générés'**
  String get dashboardRevenueGenerated;

  /// No description provided for @dashboardDetail.
  ///
  /// In fr, this message translates to:
  /// **'Détail'**
  String get dashboardDetail;

  /// No description provided for @alreadyAccount.
  ///
  /// In fr, this message translates to:
  /// **'Déjà un compte ?'**
  String get alreadyAccount;

  /// No description provided for @noAccount.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore de compte ?'**
  String get noAccount;

  /// No description provided for @signupLink.
  ///
  /// In fr, this message translates to:
  /// **'S\'inscrire'**
  String get signupLink;

  /// No description provided for @role.
  ///
  /// In fr, this message translates to:
  /// **'Rôle'**
  String get role;

  /// No description provided for @organisateur.
  ///
  /// In fr, this message translates to:
  /// **'Organisateur'**
  String get organisateur;

  /// No description provided for @otpTitle.
  ///
  /// In fr, this message translates to:
  /// **'Vérification de l\'email'**
  String get otpTitle;

  /// No description provided for @otpSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Un code à 6 chiffres a été envoyé à {email}'**
  String otpSubtitle(String email);

  /// No description provided for @otpCodeHint.
  ///
  /// In fr, this message translates to:
  /// **'Entrez le code'**
  String get otpCodeHint;

  /// No description provided for @otpVerify.
  ///
  /// In fr, this message translates to:
  /// **'Vérifier'**
  String get otpVerify;

  /// No description provided for @otpResend.
  ///
  /// In fr, this message translates to:
  /// **'Renvoyer le code'**
  String get otpResend;

  /// No description provided for @otpSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Email vérifié avec succès !'**
  String get otpSuccess;

  /// No description provided for @otpInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Code invalide ou expiré.'**
  String get otpInvalid;

  /// No description provided for @otpTooManyAttempts.
  ///
  /// In fr, this message translates to:
  /// **'Trop de tentatives. Demandez un nouveau code.'**
  String get otpTooManyAttempts;

  /// No description provided for @otpResendSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau code envoyé.'**
  String get otpResendSuccess;

  /// No description provided for @shopTitle.
  ///
  /// In fr, this message translates to:
  /// **'Tikiya Shop'**
  String get shopTitle;

  /// No description provided for @shopSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Vendez ou achetez des billets aux enchères'**
  String get shopSubtitle;

  /// No description provided for @shopTabShop.
  ///
  /// In fr, this message translates to:
  /// **'Shop'**
  String get shopTabShop;

  /// No description provided for @shopTabActive.
  ///
  /// In fr, this message translates to:
  /// **'Enchères actives'**
  String get shopTabActive;

  /// No description provided for @shopTabMine.
  ///
  /// In fr, this message translates to:
  /// **'Mes ventes'**
  String get shopTabMine;

  /// No description provided for @shopSellFab.
  ///
  /// In fr, this message translates to:
  /// **'Vendre un billet'**
  String get shopSellFab;

  /// No description provided for @shopStartingPrice.
  ///
  /// In fr, this message translates to:
  /// **'Prix de départ (DZD)'**
  String get shopStartingPrice;

  /// No description provided for @shopDurationLabel.
  ///
  /// In fr, this message translates to:
  /// **'Durée'**
  String get shopDurationLabel;

  /// No description provided for @shopDuration24h.
  ///
  /// In fr, this message translates to:
  /// **'24 heures'**
  String get shopDuration24h;

  /// No description provided for @shopDuration48h.
  ///
  /// In fr, this message translates to:
  /// **'48 heures'**
  String get shopDuration48h;

  /// No description provided for @shopDuration72h.
  ///
  /// In fr, this message translates to:
  /// **'72 heures'**
  String get shopDuration72h;

  /// No description provided for @shopCurrentBid.
  ///
  /// In fr, this message translates to:
  /// **'Enchère actuelle'**
  String get shopCurrentBid;

  /// No description provided for @shopNoBids.
  ///
  /// In fr, this message translates to:
  /// **'Aucune offre pour l\'instant'**
  String get shopNoBids;

  /// No description provided for @shopPlaceBid.
  ///
  /// In fr, this message translates to:
  /// **'Enchérir'**
  String get shopPlaceBid;

  /// No description provided for @shopBidAmount.
  ///
  /// In fr, this message translates to:
  /// **'Montant de l\'offre (DZD)'**
  String get shopBidAmount;

  /// No description provided for @shopBidPlaced.
  ///
  /// In fr, this message translates to:
  /// **'Offre envoyée !'**
  String get shopBidPlaced;

  /// No description provided for @shopTicketListed.
  ///
  /// In fr, this message translates to:
  /// **'Billet mis aux enchères !'**
  String get shopTicketListed;

  /// No description provided for @shopNoAuctions.
  ///
  /// In fr, this message translates to:
  /// **'Aucune enchère en cours'**
  String get shopNoAuctions;

  /// No description provided for @shopNoListings.
  ///
  /// In fr, this message translates to:
  /// **'Aucun billet en vente'**
  String get shopNoListings;

  /// No description provided for @shopEndsIn.
  ///
  /// In fr, this message translates to:
  /// **'Se termine dans'**
  String get shopEndsIn;

  /// No description provided for @shopChooseTicket.
  ///
  /// In fr, this message translates to:
  /// **'Choisir un billet à vendre'**
  String get shopChooseTicket;

  /// No description provided for @shopListTicket.
  ///
  /// In fr, this message translates to:
  /// **'Mettre en vente'**
  String get shopListTicket;

  /// No description provided for @shopBannerTitle.
  ///
  /// In fr, this message translates to:
  /// **'Tikiya Shop'**
  String get shopBannerTitle;

  /// No description provided for @shopBannerSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Revendez vos billets aux enchères'**
  String get shopBannerSubtitle;

  /// No description provided for @shopBannerBtn.
  ///
  /// In fr, this message translates to:
  /// **'Accéder au Shop'**
  String get shopBannerBtn;

  /// No description provided for @shopSellAction.
  ///
  /// In fr, this message translates to:
  /// **'Vendre'**
  String get shopSellAction;

  /// No description provided for @shopMinBidError.
  ///
  /// In fr, this message translates to:
  /// **'L\'offre doit dépasser l\'enchère actuelle'**
  String get shopMinBidError;

  /// No description provided for @shopMinPriceError.
  ///
  /// In fr, this message translates to:
  /// **'Prix minimum : 1 DZD'**
  String get shopMinPriceError;

  /// No description provided for @shopYourBid.
  ///
  /// In fr, this message translates to:
  /// **'Votre offre'**
  String get shopYourBid;
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
