// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'ShipRate';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get cancel => 'Cancel';

  @override
  String get ratings => 'Ratings';

  @override
  String get cabin => 'Cabin';

  @override
  String get bridge => 'Bridge';

  @override
  String get pilot => 'Pilot';

  @override
  String get loginSubtitle => 'Enter your email and password to continue';

  @override
  String get loginButton => 'Log in';

  @override
  String get loginSuccess => 'Login successful';

  @override
  String get forgotPassword => 'Forgot my password';

  @override
  String get createAccount => 'Create new account';

  @override
  String get createAccountTitle => 'Create account';

  @override
  String get registerSubtitle => 'Fill in the details to continue';

  @override
  String get callSign => 'Call sign';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get registerButton => 'Register';

  @override
  String get registerSuccess => 'Registration successful';

  @override
  String get alreadyHaveAccount => 'I already have an account';

  @override
  String get recoverPassword => 'Recover password';

  @override
  String get recoverPasswordSubtitle => 'Enter your email to receive the reset link';

  @override
  String get sendLink => 'Send link';

  @override
  String get resetEmailSent => 'We sent a recovery link to your email.';

  @override
  String get spamNotice => 'If you can\'t find the email, also check your SPAM or Junk folder.';

  @override
  String get backToLogin => 'Back to login';

  @override
  String get appSubtitle => 'Professional ship evaluation';

  @override
  String get drawerSearchRate => 'Search / Rate Ships';

  @override
  String get drawerMyRatings => 'My Ratings';

  @override
  String get drawerSendSuggestion => 'Send Suggestion';

  @override
  String get drawerShareApp => 'Share App';

  @override
  String get drawerLogout => 'Log out';

  @override
  String get linkCopied => 'Link copied to clipboard!';

  @override
  String get updateAvailable => 'Update Available';

  @override
  String get shareShipRate => 'Share ShipRate';

  @override
  String get copyLink => 'Copy Link';

  @override
  String get shareText => 'Check out ShipRate! The professional ship evaluation app for pilots. Visit: https://shiprate-daf18.web.app/';

  @override
  String get shipRatingTitle => 'Ship Rating';

  @override
  String get searchSubtitle => 'Search ratings or register your experience';

  @override
  String get searchTab => 'Search';

  @override
  String get rateTab => 'Rate';

  @override
  String get searchHint => 'Search by ship name or IMO';

  @override
  String get newShipRating => 'New Ship Rating';

  @override
  String get rateSubtitle => 'Register your technical evaluation quickly and safely';

  @override
  String get startRating => 'Start rating';

  @override
  String get generalInfo => 'General Information';

  @override
  String get ratingAverages => 'Rating Averages';

  @override
  String get viewOnMarineTraffic => 'View Details on MarineTraffic';

  @override
  String get marineTrafficError => 'Could not open MarineTraffic';

  @override
  String get crew => 'Crew';

  @override
  String get cabins => 'Cabins';

  @override
  String get minibar => 'Minibar';

  @override
  String get sink => 'Sink';

  @override
  String get microwave => 'Microwave';

  @override
  String get avgCabinTemp => 'Cabin Temp.';

  @override
  String get avgCabinCleanliness => 'Cabin Cleanliness';

  @override
  String get avgBridgeEquipment => 'Bridge Equip.';

  @override
  String get avgBridgeTemp => 'Bridge Temp.';

  @override
  String get avgFood => 'Food';

  @override
  String get avgRelationship => 'Relationship';

  @override
  String get avgDevice => 'Device';

  @override
  String pilotCallSign(String callSign) {
    return 'Pilot: $callSign';
  }

  @override
  String get viewRating => 'View rating';

  @override
  String get rateShipTitle => 'Rate Ship';

  @override
  String get saveRating => 'Save Rating';

  @override
  String get shipData => 'Ship Data';

  @override
  String get shipName => 'Ship name';

  @override
  String get enterShipName => 'Enter the ship name';

  @override
  String get imoOptional => 'IMO (optional)';

  @override
  String get disembarkationDate => 'Disembarkation date';

  @override
  String get tapToSelect => 'Tap to select';

  @override
  String get crewNationality => 'Crew nationality';

  @override
  String get nationalityFilipino => 'Filipino';

  @override
  String get nationalityRussian => 'Russian';

  @override
  String get nationalityUkrainian => 'Ukrainian';

  @override
  String get nationalityIndian => 'Indian';

  @override
  String get nationalityChinese => 'Chinese';

  @override
  String get nationalityBrazilian => 'Brazilian';

  @override
  String get nationalityOther => 'Other';

  @override
  String get specifyNationality => 'Specify nationality';

  @override
  String get cabinCount => 'Number of cabins';

  @override
  String get cabinCountOne => 'One';

  @override
  String get cabinCountTwo => 'Two';

  @override
  String get cabinCountMoreThanTwo => 'More than two';

  @override
  String get cabinType => 'Cabin type';

  @override
  String get cabinDeck => 'Cabin deck';

  @override
  String get deckBridge => 'Bridge deck';

  @override
  String get deck1Below => '1 deck below bridge';

  @override
  String get deck2Below => '2 decks below bridge';

  @override
  String get deck3Below => '3 decks below bridge';

  @override
  String get deck4PlusBelow => '4+ decks below bridge';

  @override
  String deckLabel(String deck) {
    return 'Deck $deck';
  }

  @override
  String get hasMinibar => 'Has minibar';

  @override
  String get hasSink => 'Has sink';

  @override
  String get hasMicrowave => 'Has microwave';

  @override
  String get otherRatings => 'Other Ratings';

  @override
  String get generalObservation => 'General Observation';

  @override
  String get generalObservationHint => 'Additional comments about the overall experience on the ship...';

  @override
  String get observationsOptional => 'Observations (optional)';

  @override
  String get shipFoundTapToRate => 'Ship found — tap to select from the list';

  @override
  String get shipExistsSelectFromList => 'This ship already exists. Please select it from the dropdown list.';

  @override
  String get fillRequiredFields => 'Fill in all required fields';

  @override
  String get editRatingTitle => 'Edit Rating';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get editWarningBanner => 'Edit only typos. For ship changes, create a new rating.';

  @override
  String get ratingUpdatedSuccess => 'Rating updated successfully!';

  @override
  String errorLoadingData(String error) {
    return 'Error loading data: $error';
  }

  @override
  String errorSaving(String error) {
    return 'Error saving: $error';
  }

  @override
  String get shipNameRequired => 'Ship name *';

  @override
  String get disembarkationDateRequired => 'Disembarkation date *';

  @override
  String get cabinTypeRequired => 'Cabin type *';

  @override
  String get myRatingsTitle => 'My Ratings';

  @override
  String get loadingRatings => 'Loading your ratings...';

  @override
  String get tryAgain => 'Try Again';

  @override
  String get noRatingsYet => 'No ratings yet';

  @override
  String get noRatingsSubtitle => 'You haven\'t rated any ships yet.\nStart rating your next voyage!';

  @override
  String totalRatings(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Total: $count ratings',
      one: 'Total: 1 rating',
    );
    return '$_temp0';
  }

  @override
  String get newestFirst => 'Newest first';

  @override
  String get averageScore => 'Average Score';

  @override
  String get ratingDate => 'Rating Date';

  @override
  String get deleteLabel => 'Delete';

  @override
  String get editLabel => 'Edit';

  @override
  String get ratingDeletedSuccess => 'Rating deleted successfully!';

  @override
  String errorDeleting(String error) {
    return 'Error deleting: $error';
  }

  @override
  String get pdfGeneratedSuccess => 'PDF generated successfully!';

  @override
  String errorGeneratingPdf(String error) {
    return 'Error generating PDF: $error';
  }

  @override
  String get editWarningTitle => 'Warning';

  @override
  String get editWarningCorrectionsOnly => 'Edit only to correct errors';

  @override
  String get editWarningDescription => 'This feature is for correcting typos or incorrect information.';

  @override
  String get editWarningImportant => 'Important: Use only for corrections, not to update ship changes over time.';

  @override
  String get editWarningNewRating => 'If the ship\'s condition has changed since your last rating, create a NEW rating instead of editing this one.';

  @override
  String get editWarningHistory => 'Keeping history helps other pilots!';

  @override
  String get editWarningConfirm => 'I understand, I want to edit';

  @override
  String get deleteRatingTitle => 'Delete Rating';

  @override
  String deleteRatingConfirm(String shipName) {
    return 'Are you sure you want to delete the rating for ship \"$shipName\"?';
  }

  @override
  String get deleteWarning => 'This action cannot be undone!';

  @override
  String get deleteButton => 'Delete';

  @override
  String get ratingDetailTitle => 'Rating Details';

  @override
  String get exportPdf => 'Export PDF';

  @override
  String get errorLoadingShipData => 'Error loading ship data';

  @override
  String get defaultShipName => 'Ship';

  @override
  String ratedOn(String date) {
    return 'Rated on: $date';
  }

  @override
  String disembarkationDateValue(String date) {
    return 'Disembarkation date: $date';
  }

  @override
  String cabinTypeValue(String type) {
    return 'Cabin type: $type';
  }

  @override
  String cabinDeckValue(String deck) {
    return 'Cabin deck: $deck';
  }

  @override
  String imoValue(String imo) {
    return 'IMO: $imo';
  }

  @override
  String get shipInfo => 'Ship Information';

  @override
  String get generalObservations => 'General Observations';

  @override
  String get cabinSection => 'Cabin';

  @override
  String get bridgeSection => 'Bridge';

  @override
  String get otherSection => 'Other';

  @override
  String scoreLabel(String score) {
    return 'Score: $score';
  }

  @override
  String get anonymous => 'Anonymous';

  @override
  String get notAvailable => 'N/A';

  @override
  String get criteriaCabinTemp => 'Cabin Temperature';

  @override
  String get criteriaCabinCleanliness => 'Cabin Cleanliness';

  @override
  String get criteriaBridgeEquipment => 'Bridge - Equipment';

  @override
  String get criteriaBridgeTemp => 'Bridge - Temperature';

  @override
  String get criteriaDevice => 'Boarding/Disembarking Device';

  @override
  String get criteriaFood => 'Food';

  @override
  String get criteriaRelationship => 'Relationship with captain/crew';

  @override
  String get sendSuggestionTitle => 'Send Suggestion';

  @override
  String get yourOpinionMatters => 'Your opinion matters';

  @override
  String get helpImproveApp => 'Help improve ShipRate with suggestions and ideas.';

  @override
  String get suggestionType => 'Suggestion';

  @override
  String get complaintType => 'Complaint';

  @override
  String get complimentType => 'Compliment';

  @override
  String get messageLabel => 'Message';

  @override
  String get sendButton => 'Send';

  @override
  String get messageSentSuccess => 'Message sent successfully!';

  @override
  String get errorSendingMessage => 'Error sending message.';

  @override
  String get dashboardAppStats => 'ShipRate in numbers';

  @override
  String get dashboardYourActivity => 'Your Activity';

  @override
  String get totalShipsLabel => 'Ships';

  @override
  String get totalRatingsLabel => 'Ratings';

  @override
  String get yourRatingsLabel => 'Your Ratings';

  @override
  String get yourContribution => 'Your Contribution';

  @override
  String contributionProgress(String percent) {
    return '$percent% of ratings';
  }

  @override
  String contributionSummary(String userCount, String totalCount) {
    return 'You rated $userCount of $totalCount';
  }

  @override
  String get recentActivity => 'Recent Activity';

  @override
  String get noRecentActivity => 'No recent activity';

  @override
  String get pdfReportTitle => 'Ship Rating Report';

  @override
  String get pdfEvaluationInfo => 'Evaluation Information';

  @override
  String get pdfEvaluator => 'Evaluator Pilot';

  @override
  String get pdfEvaluationDate => 'Evaluation Date';

  @override
  String get pdfCabinType => 'Cabin Type';

  @override
  String get pdfDisembarkationDate => 'Disembarkation Date';

  @override
  String get pdfOverallAverage => 'Overall Average Score';

  @override
  String get pdfCrewNationality => 'Crew Nationality';

  @override
  String get pdfCabinCount => 'Number of Cabins';

  @override
  String get pdfRatingsByCriteria => 'Ratings by Criteria';

  @override
  String get pdfGeneralObservation => 'General Observation';

  @override
  String get pdfGeneratedBy => 'Generated by ShipRate';

  @override
  String get pdfDateLabel => 'Date';

  @override
  String get ratingSavedSuccess => 'Rating saved successfully!';

  @override
  String get rateThisShip => 'Rate This Ship';

  @override
  String welcomePilot(String name) {
    return 'Welcome, $name';
  }

  @override
  String get selectModule => 'Select module';

  @override
  String get shipRatingModule => 'Ship Rating';

  @override
  String get shipRatingDesc => 'Rate ships and share experiences';

  @override
  String get navSafetyModule => 'Navigation Safety';

  @override
  String get navSafetyDesc => 'Depths, draft and section conditions';
}
