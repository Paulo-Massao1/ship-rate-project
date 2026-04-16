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
  String get alreadyHaveAccount => 'Already have an account? Sign in';

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

  @override
  String get latestDepths => 'Latest Depths';

  @override
  String get locations => 'Locations';

  @override
  String get newRecord => 'New Record';

  @override
  String get latestDepthsRegistered => 'Latest registered depths';

  @override
  String get noRecords => 'No records';

  @override
  String get lastDepth => 'LAST DEPTH';

  @override
  String get history => 'History';

  @override
  String get back => 'Back';

  @override
  String get totalDepth => 'TOTAL DEPTH';

  @override
  String get maxDraft => 'MAX DRAFT';

  @override
  String get ukc => 'UKC';

  @override
  String get direction => 'DIRECTION';

  @override
  String get passageData => 'Passage Data';

  @override
  String get selectLocation => 'Select location';

  @override
  String get addNewLocation => 'Add new location';

  @override
  String get newLocationName => 'New location name';

  @override
  String get anchoragePt => 'Point (1-15)';

  @override
  String get shipNameOptional => 'Ship name (optional)';

  @override
  String get passageDate => 'Passage date';

  @override
  String get goingUp => 'Going up';

  @override
  String get goingDown => 'Going down';

  @override
  String get totalDepthLabel => 'TOTAL DEPTH';

  @override
  String get complementaryData => 'Complementary Data';

  @override
  String get maxDraftInput => 'Max Draft (m)';

  @override
  String get ukcInput => 'UKC (m)';

  @override
  String get speedOptional => 'Speed (knots)';

  @override
  String get optional => 'optional';

  @override
  String get squatConsidered => 'Squat considered?';

  @override
  String get sonarPosition => 'Sonar Position';

  @override
  String get bow => 'Bow';

  @override
  String get stern => 'Stern';

  @override
  String get positionLatLong => 'Position (LAT/LONG)';

  @override
  String get observations => 'Observations / References';

  @override
  String get additionalInfo => 'Additional information...';

  @override
  String get registerPassage => 'Register Passage';

  @override
  String get recordSavedSuccess => 'Record saved successfully!';

  @override
  String get locationRequired => 'Select a location';

  @override
  String get depthRequired => 'Enter total depth';

  @override
  String get draftRequired => 'Enter max draft';

  @override
  String get ukcRequired => 'Enter UKC';

  @override
  String get directionRequired => 'Select direction';

  @override
  String get sonarRequired => 'Select sonar position';

  @override
  String get myRecords => 'My Records';

  @override
  String get drawerMyRecords => 'My Records';

  @override
  String get yourRecords => 'Your Records';

  @override
  String get recordsLabel => 'records';

  @override
  String get locationsLabel => 'locations';

  @override
  String get contributionLabel => 'contribution';

  @override
  String get editRecord => 'Edit';

  @override
  String get deleteRecord => 'Delete';

  @override
  String get deleteRecordTitle => 'Delete Record';

  @override
  String get deleteRecordConfirm => 'Are you sure you want to delete this record? This action cannot be undone.';

  @override
  String get recordDeletedSuccess => 'Record deleted successfully!';

  @override
  String get recordUpdatedSuccess => 'Record updated successfully!';

  @override
  String get updatePassage => 'Update Passage';

  @override
  String get noRecordsYet => 'No records yet';

  @override
  String get noRecordsSubtitle => 'You haven\'t registered any passages yet.\nStart recording your next passage!';

  @override
  String get recordDetails => 'Record Details';

  @override
  String get passageInfo => 'Passage Information';

  @override
  String get by => 'By';

  @override
  String get technicalData => 'Technical Data';

  @override
  String get position => 'Position';

  @override
  String get anchoragePoint => 'Anchorage Point';

  @override
  String get totalDepthShort => 'Total Depth';

  @override
  String get modules => 'Modules';

  @override
  String lastRecordBy(String name) {
    return 'Last record by: $name';
  }

  @override
  String navShipLabel(String name) {
    return 'Ship: $name';
  }

  @override
  String get enterEmail => 'Enter your email';

  @override
  String get sendCode => 'Send code';

  @override
  String get emailNotAuthorized => 'Email not authorized. Contact ZP01.';

  @override
  String codeSentTo(String email) {
    return 'Code sent to $email';
  }

  @override
  String get enterCode => 'Enter the 6-digit code';

  @override
  String get verify => 'Verify';

  @override
  String get resendCode => 'Resend code';

  @override
  String get invalidCode => 'Invalid code';

  @override
  String get expiredCode => 'Code expired. Request a new one.';

  @override
  String get rateLimited => 'Too many attempts. Wait 15 minutes.';

  @override
  String get tooManyAttempts => 'Too many incorrect attempts. Wait 15 minutes.';

  @override
  String resendIn(String seconds) {
    return 'Resend in ${seconds}s';
  }

  @override
  String get noAccount => 'Don\'t have an account? Register';

  @override
  String get register => 'Register';

  @override
  String get createPassword => 'Create password';

  @override
  String get passwordHint => 'Minimum 6 characters';

  @override
  String get accountCreated => 'Account created successfully!';

  @override
  String get invalidCredentials => 'Invalid email or password';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get passwordTooShort => 'Password must be at least 6 characters';

  @override
  String get emailAlreadyRegistered => 'This email already has an account. Use the login screen.';

  @override
  String get settings => 'Settings';

  @override
  String get pushNotifications => 'Push notifications';

  @override
  String get emailNotifications => 'Email notifications';

  @override
  String get notificationPermissionDenied => 'Notification permission denied';

  @override
  String get invalidEmail => 'Invalid email';

  @override
  String get navSafetyBlocked => 'To access the navigation safety area, register again in the app using your Unipilot email.';
}
