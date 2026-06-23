import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pt.dart';

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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('pt')
  ];

  /// Title text for app.
  ///
  /// In pt, this message translates to:
  /// **'ShipRate'**
  String get appTitle;

  /// Localized text for email.
  ///
  /// In pt, this message translates to:
  /// **'E-mail'**
  String get email;

  /// Localized text for password.
  ///
  /// In pt, this message translates to:
  /// **'Senha'**
  String get password;

  /// Localized text for the affirmative response option.
  ///
  /// In pt, this message translates to:
  /// **'Sim'**
  String get yes;

  /// Localized text for the negative response option.
  ///
  /// In pt, this message translates to:
  /// **'Não'**
  String get no;

  /// Button label used to cancel an action.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar'**
  String get cancel;

  /// Localized text for ratings.
  ///
  /// In pt, this message translates to:
  /// **'Avaliações'**
  String get ratings;

  /// Localized text for cabin.
  ///
  /// In pt, this message translates to:
  /// **'Cabine'**
  String get cabin;

  /// Localized text for bridge.
  ///
  /// In pt, this message translates to:
  /// **'Passadiço'**
  String get bridge;

  /// Localized text for pilot.
  ///
  /// In pt, this message translates to:
  /// **'Prático'**
  String get pilot;

  /// Subtitle text for login.
  ///
  /// In pt, this message translates to:
  /// **'Entre com seu e-mail e senha para continuar'**
  String get loginSubtitle;

  /// Button label for login.
  ///
  /// In pt, this message translates to:
  /// **'Entrar'**
  String get loginButton;

  /// Localized text for login success.
  ///
  /// In pt, this message translates to:
  /// **'Login realizado com sucesso'**
  String get loginSuccess;

  /// Localized text for forgot password.
  ///
  /// In pt, this message translates to:
  /// **'Esqueci minha senha'**
  String get forgotPassword;

  /// Localized text for create account.
  ///
  /// In pt, this message translates to:
  /// **'Criar nova conta'**
  String get createAccount;

  /// Title text for create account.
  ///
  /// In pt, this message translates to:
  /// **'Criar conta'**
  String get createAccountTitle;

  /// Subtitle text for register.
  ///
  /// In pt, this message translates to:
  /// **'Preencha os dados para continuar'**
  String get registerSubtitle;

  /// Localized text for call sign.
  ///
  /// In pt, this message translates to:
  /// **'Nome de guerra'**
  String get callSign;

  /// Localized text for confirm password.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar senha'**
  String get confirmPassword;

  /// Button label for register.
  ///
  /// In pt, this message translates to:
  /// **'Cadastrar'**
  String get registerButton;

  /// Localized text for register success.
  ///
  /// In pt, this message translates to:
  /// **'Cadastro realizado com sucesso'**
  String get registerSuccess;

  /// Localized text for already have account.
  ///
  /// In pt, this message translates to:
  /// **'Já tem conta? Entrar'**
  String get alreadyHaveAccount;

  /// Localized text for recover password.
  ///
  /// In pt, this message translates to:
  /// **'Recuperar senha'**
  String get recoverPassword;

  /// Subtitle text for recover password.
  ///
  /// In pt, this message translates to:
  /// **'Informe seu e-mail para receber o link de redefinição'**
  String get recoverPasswordSubtitle;

  /// Localized text for send link.
  ///
  /// In pt, this message translates to:
  /// **'Enviar link'**
  String get sendLink;

  /// Localized text for reset email sent.
  ///
  /// In pt, this message translates to:
  /// **'Enviamos um link de recuperação para o seu e-mail.'**
  String get resetEmailSent;

  /// Localized text for spam notice.
  ///
  /// In pt, this message translates to:
  /// **'Caso não encontre o e-mail, verifique também sua caixa de SPAM ou Lixo Eletrônico.'**
  String get spamNotice;

  /// Localized text for back to login.
  ///
  /// In pt, this message translates to:
  /// **'Voltar para o login'**
  String get backToLogin;

  /// Subtitle text for app.
  ///
  /// In pt, this message translates to:
  /// **'Avaliação profissional de navios'**
  String get appSubtitle;

  /// Localized text for drawer search rate.
  ///
  /// In pt, this message translates to:
  /// **'Buscar / Avaliar Navios'**
  String get drawerSearchRate;

  /// Localized text for drawer my ratings.
  ///
  /// In pt, this message translates to:
  /// **'Minhas Avaliações'**
  String get drawerMyRatings;

  /// Localized text for drawer send suggestion.
  ///
  /// In pt, this message translates to:
  /// **'Enviar Sugestão'**
  String get drawerSendSuggestion;

  /// Localized text for drawer share app.
  ///
  /// In pt, this message translates to:
  /// **'Compartilhar App'**
  String get drawerShareApp;

  /// Localized text for drawer logout.
  ///
  /// In pt, this message translates to:
  /// **'Sair'**
  String get drawerLogout;

  /// Localized text for link copied.
  ///
  /// In pt, this message translates to:
  /// **'Link copiado para a área de transferência!'**
  String get linkCopied;

  /// Localized text for update available.
  ///
  /// In pt, this message translates to:
  /// **'Atualização Disponível'**
  String get updateAvailable;

  /// Localized text for share ship rate.
  ///
  /// In pt, this message translates to:
  /// **'Compartilhar ShipRate'**
  String get shareShipRate;

  /// Localized text for copy link.
  ///
  /// In pt, this message translates to:
  /// **'Copiar Link'**
  String get copyLink;

  /// Localized text for share text.
  ///
  /// In pt, this message translates to:
  /// **'Conheça o ShipRate, o app dos práticos para avaliar navios e reportar profundidades dos trechos navegados. Baixe aqui: https://shiprate-daf18.web.app'**
  String get shareText;

  /// Texto curto exibido antes do link do app nas mensagens de compartilhamento.
  ///
  /// In pt, this message translates to:
  /// **'Para informar seu cruzamento, acesse:'**
  String get shareMoreInfo;

  /// Title text for ship rating.
  ///
  /// In pt, this message translates to:
  /// **'Avaliação de Navios'**
  String get shipRatingTitle;

  /// Subtitle text for search.
  ///
  /// In pt, this message translates to:
  /// **'Pesquise avaliações ou registre sua experiência'**
  String get searchSubtitle;

  /// Localized text for search tab.
  ///
  /// In pt, this message translates to:
  /// **'Buscar'**
  String get searchTab;

  /// Localized text for rate tab.
  ///
  /// In pt, this message translates to:
  /// **'Avaliar'**
  String get rateTab;

  /// Hint text for search.
  ///
  /// In pt, this message translates to:
  /// **'Buscar por nome do navio ou IMO'**
  String get searchHint;

  /// Localized text for new ship rating.
  ///
  /// In pt, this message translates to:
  /// **'Nova Avaliação de Navio'**
  String get newShipRating;

  /// Subtitle text for rate.
  ///
  /// In pt, this message translates to:
  /// **'Registre sua avaliação técnica de forma rápida e segura'**
  String get rateSubtitle;

  /// Localized text for start rating.
  ///
  /// In pt, this message translates to:
  /// **'Iniciar avaliação'**
  String get startRating;

  /// Localized text for general info.
  ///
  /// In pt, this message translates to:
  /// **'Informações Gerais'**
  String get generalInfo;

  /// Localized text for rating averages.
  ///
  /// In pt, this message translates to:
  /// **'Médias das Avaliações'**
  String get ratingAverages;

  /// Localized text for view on marine traffic.
  ///
  /// In pt, this message translates to:
  /// **'Ver Detalhes no MarineTraffic'**
  String get viewOnMarineTraffic;

  /// Localized text for marine traffic error.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível abrir MarineTraffic'**
  String get marineTrafficError;

  /// Localized text for crew.
  ///
  /// In pt, this message translates to:
  /// **'Tripulação'**
  String get crew;

  /// Localized text for cabins.
  ///
  /// In pt, this message translates to:
  /// **'Cabines'**
  String get cabins;

  /// Localized text for minibar.
  ///
  /// In pt, this message translates to:
  /// **'Frigobar'**
  String get minibar;

  /// Localized text for sink.
  ///
  /// In pt, this message translates to:
  /// **'Pia'**
  String get sink;

  /// Localized text for microwave.
  ///
  /// In pt, this message translates to:
  /// **'Micro-ondas'**
  String get microwave;

  /// Localized text for avg cabin temp.
  ///
  /// In pt, this message translates to:
  /// **'Temp. Cabine'**
  String get avgCabinTemp;

  /// Localized text for avg cabin cleanliness.
  ///
  /// In pt, this message translates to:
  /// **'Limpeza Cabine'**
  String get avgCabinCleanliness;

  /// Localized text for avg bridge equipment.
  ///
  /// In pt, this message translates to:
  /// **'Equip. Passadiço'**
  String get avgBridgeEquipment;

  /// Localized text for avg bridge temp.
  ///
  /// In pt, this message translates to:
  /// **'Temp. Passadiço'**
  String get avgBridgeTemp;

  /// Localized text for avg food.
  ///
  /// In pt, this message translates to:
  /// **'Alimentação'**
  String get avgFood;

  /// Localized text for avg relationship.
  ///
  /// In pt, this message translates to:
  /// **'Relacionamento'**
  String get avgRelationship;

  /// Localized text for avg device.
  ///
  /// In pt, this message translates to:
  /// **'Dispositivo'**
  String get avgDevice;

  /// Localized text for pilot call sign.
  ///
  /// In pt, this message translates to:
  /// **'Prático: {callSign}'**
  String pilotCallSign(String callSign);

  /// Localized text for view rating.
  ///
  /// In pt, this message translates to:
  /// **'Visualizar avaliação'**
  String get viewRating;

  /// Title text for rate ship.
  ///
  /// In pt, this message translates to:
  /// **'Avaliar Navio'**
  String get rateShipTitle;

  /// Localized text for save rating.
  ///
  /// In pt, this message translates to:
  /// **'Salvar Avaliação'**
  String get saveRating;

  /// Localized text for ship data.
  ///
  /// In pt, this message translates to:
  /// **'Dados do Navio'**
  String get shipData;

  /// Localized text for ship name.
  ///
  /// In pt, this message translates to:
  /// **'Nome do navio'**
  String get shipName;

  /// Localized text for enter ship name.
  ///
  /// In pt, this message translates to:
  /// **'Informe o nome do navio'**
  String get enterShipName;

  /// Localized text for imo optional.
  ///
  /// In pt, this message translates to:
  /// **'IMO (opcional)'**
  String get imoOptional;

  /// Localized text for disembarkation date.
  ///
  /// In pt, this message translates to:
  /// **'Data de desembarque'**
  String get disembarkationDate;

  /// Localized text for tap to select.
  ///
  /// In pt, this message translates to:
  /// **'Toque para selecionar'**
  String get tapToSelect;

  /// Localized text for crew nationality.
  ///
  /// In pt, this message translates to:
  /// **'Nacionalidade da tripulação'**
  String get crewNationality;

  /// Localized text for nationality filipino.
  ///
  /// In pt, this message translates to:
  /// **'Filipina'**
  String get nationalityFilipino;

  /// Localized text for nationality russian.
  ///
  /// In pt, this message translates to:
  /// **'Russa'**
  String get nationalityRussian;

  /// Localized text for nationality ukrainian.
  ///
  /// In pt, this message translates to:
  /// **'Ucraniana'**
  String get nationalityUkrainian;

  /// Localized text for nationality indian.
  ///
  /// In pt, this message translates to:
  /// **'Indiana'**
  String get nationalityIndian;

  /// Localized text for nationality chinese.
  ///
  /// In pt, this message translates to:
  /// **'Chinesa'**
  String get nationalityChinese;

  /// Localized text for nationality brazilian.
  ///
  /// In pt, this message translates to:
  /// **'Brasileira'**
  String get nationalityBrazilian;

  /// Localized text for nationality other.
  ///
  /// In pt, this message translates to:
  /// **'Outro'**
  String get nationalityOther;

  /// Localized text for specify nationality.
  ///
  /// In pt, this message translates to:
  /// **'Especifique a nacionalidade'**
  String get specifyNationality;

  /// Localized text for cabin count.
  ///
  /// In pt, this message translates to:
  /// **'Quantidade de cabines'**
  String get cabinCount;

  /// Localized text for cabin count one.
  ///
  /// In pt, this message translates to:
  /// **'Uma'**
  String get cabinCountOne;

  /// Localized text for cabin count two.
  ///
  /// In pt, this message translates to:
  /// **'Duas'**
  String get cabinCountTwo;

  /// Localized text for cabin count more than two.
  ///
  /// In pt, this message translates to:
  /// **'Mais de duas'**
  String get cabinCountMoreThanTwo;

  /// Localized text for cabin type.
  ///
  /// In pt, this message translates to:
  /// **'Tipo da cabine'**
  String get cabinType;

  /// Localized text for cabin deck.
  ///
  /// In pt, this message translates to:
  /// **'Deck da cabine'**
  String get cabinDeck;

  /// Localized text for deck bridge.
  ///
  /// In pt, this message translates to:
  /// **'Deck do passadiço'**
  String get deckBridge;

  /// Localized text for deck1 below.
  ///
  /// In pt, this message translates to:
  /// **'1 deck abaixo do passadiço'**
  String get deck1Below;

  /// Localized text for deck2 below.
  ///
  /// In pt, this message translates to:
  /// **'2 decks abaixo do passadiço'**
  String get deck2Below;

  /// Localized text for deck3 below.
  ///
  /// In pt, this message translates to:
  /// **'3 decks abaixo do passadiço'**
  String get deck3Below;

  /// Localized text for deck4 plus below.
  ///
  /// In pt, this message translates to:
  /// **'4+ decks abaixo do passadiço'**
  String get deck4PlusBelow;

  /// Label text for deck.
  ///
  /// In pt, this message translates to:
  /// **'Deck {deck}'**
  String deckLabel(String deck);

  /// Localized text for has minibar.
  ///
  /// In pt, this message translates to:
  /// **'Possui frigobar'**
  String get hasMinibar;

  /// Localized text for has sink.
  ///
  /// In pt, this message translates to:
  /// **'Possui pia'**
  String get hasSink;

  /// Localized text for has microwave.
  ///
  /// In pt, this message translates to:
  /// **'Possui micro-ondas'**
  String get hasMicrowave;

  /// Localized text for other ratings.
  ///
  /// In pt, this message translates to:
  /// **'Outras Avaliações'**
  String get otherRatings;

  /// Localized text for general observation.
  ///
  /// In pt, this message translates to:
  /// **'Observação Geral'**
  String get generalObservation;

  /// Hint text for general observation.
  ///
  /// In pt, this message translates to:
  /// **'Comentários adicionais sobre a experiência geral no navio...'**
  String get generalObservationHint;

  /// Localized text for observations optional.
  ///
  /// In pt, this message translates to:
  /// **'Observações (opcional)'**
  String get observationsOptional;

  /// Localized text for ship found tap to rate.
  ///
  /// In pt, this message translates to:
  /// **'Navio encontrado — toque para selecionar da lista'**
  String get shipFoundTapToRate;

  /// Localized text for ship exists select from list.
  ///
  /// In pt, this message translates to:
  /// **'Este navio já existe. Selecione-o na lista suspensa.'**
  String get shipExistsSelectFromList;

  /// Localized text for fill required fields.
  ///
  /// In pt, this message translates to:
  /// **'Preencha todos os campos obrigatórios'**
  String get fillRequiredFields;

  /// Title text for edit rating.
  ///
  /// In pt, this message translates to:
  /// **'Editar Avaliação'**
  String get editRatingTitle;

  /// Localized text for save changes.
  ///
  /// In pt, this message translates to:
  /// **'Salvar Alterações'**
  String get saveChanges;

  /// Banner text shown at the top of the edit rating page.
  ///
  /// In pt, this message translates to:
  /// **'Edite apenas para corrigir erros ou inserir informações de sua viagem. Se o navio mudou de condição, crie uma nova avaliação.'**
  String get editRatingBanner;

  /// Localized text for rating updated success.
  ///
  /// In pt, this message translates to:
  /// **'Avaliação atualizada com sucesso!'**
  String get ratingUpdatedSuccess;

  /// Error message for loading data.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao carregar dados: {error}'**
  String errorLoadingData(String error);

  /// Error message for saving.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao salvar: {error}'**
  String errorSaving(String error);

  /// Localized text for ship name required.
  ///
  /// In pt, this message translates to:
  /// **'Nome do navio *'**
  String get shipNameRequired;

  /// Localized text for disembarkation date required.
  ///
  /// In pt, this message translates to:
  /// **'Data de desembarque *'**
  String get disembarkationDateRequired;

  /// Localized text for cabin type required.
  ///
  /// In pt, this message translates to:
  /// **'Tipo da cabine *'**
  String get cabinTypeRequired;

  /// Title text for my ratings.
  ///
  /// In pt, this message translates to:
  /// **'Minhas Avaliações'**
  String get myRatingsTitle;

  /// Localized text for loading ratings.
  ///
  /// In pt, this message translates to:
  /// **'Carregando suas avaliações...'**
  String get loadingRatings;

  /// Localized text for try again.
  ///
  /// In pt, this message translates to:
  /// **'Tentar Novamente'**
  String get tryAgain;

  /// Empty-state or negative message for ratings yet.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma avaliação ainda'**
  String get noRatingsYet;

  /// Subtitle text for no ratings.
  ///
  /// In pt, this message translates to:
  /// **'Você ainda não avaliou nenhum navio.\nComece avaliando sua próxima viagem!'**
  String get noRatingsSubtitle;

  /// Localized text for total ratings.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{Total: 1 avaliação} other{Total: {count} avaliações}}'**
  String totalRatings(int count);

  /// Localized text for newest first.
  ///
  /// In pt, this message translates to:
  /// **'Mais recentes primeiro'**
  String get newestFirst;

  /// Localized text for average score.
  ///
  /// In pt, this message translates to:
  /// **'Nota Média'**
  String get averageScore;

  /// Localized text for rating date.
  ///
  /// In pt, this message translates to:
  /// **'Data de Avaliação'**
  String get ratingDate;

  /// Label text for delete.
  ///
  /// In pt, this message translates to:
  /// **'Excluir'**
  String get deleteLabel;

  /// Label text for edit.
  ///
  /// In pt, this message translates to:
  /// **'Editar'**
  String get editLabel;

  /// Localized text for rating deleted success.
  ///
  /// In pt, this message translates to:
  /// **'Avaliação excluída com sucesso!'**
  String get ratingDeletedSuccess;

  /// Error message for deleting.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao excluir: {error}'**
  String errorDeleting(String error);

  /// Localized text for pdf generated success.
  ///
  /// In pt, this message translates to:
  /// **'PDF gerado com sucesso!'**
  String get pdfGeneratedSuccess;

  /// Error message for generating pdf.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao gerar PDF: {error}'**
  String errorGeneratingPdf(String error);

  /// Title text for delete rating.
  ///
  /// In pt, this message translates to:
  /// **'Excluir Avaliação'**
  String get deleteRatingTitle;

  /// Localized text for delete rating confirm.
  ///
  /// In pt, this message translates to:
  /// **'Tem certeza que deseja excluir a avaliação do navio \"{shipName}\"?'**
  String deleteRatingConfirm(String shipName);

  /// Localized text for delete warning.
  ///
  /// In pt, this message translates to:
  /// **'Esta ação não pode ser desfeita!'**
  String get deleteWarning;

  /// Button label for delete.
  ///
  /// In pt, this message translates to:
  /// **'Excluir'**
  String get deleteButton;

  /// Title text for rating detail.
  ///
  /// In pt, this message translates to:
  /// **'Detalhes da Avaliação'**
  String get ratingDetailTitle;

  /// Localized text for export pdf.
  ///
  /// In pt, this message translates to:
  /// **'Exportar PDF'**
  String get exportPdf;

  /// Error message for loading ship data.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao carregar dados do navio'**
  String get errorLoadingShipData;

  /// Localized text for default ship name.
  ///
  /// In pt, this message translates to:
  /// **'Navio'**
  String get defaultShipName;

  /// Localized text for rated on.
  ///
  /// In pt, this message translates to:
  /// **'Avaliado em: {date}'**
  String ratedOn(String date);

  /// Localized text for disembarkation date value.
  ///
  /// In pt, this message translates to:
  /// **'Data de desembarque: {date}'**
  String disembarkationDateValue(String date);

  /// Localized text for cabin type value.
  ///
  /// In pt, this message translates to:
  /// **'Tipo da cabine: {type}'**
  String cabinTypeValue(String type);

  /// Localized text for cabin deck value.
  ///
  /// In pt, this message translates to:
  /// **'Deck da cabine: {deck}'**
  String cabinDeckValue(String deck);

  /// Localized text for imo value.
  ///
  /// In pt, this message translates to:
  /// **'IMO: {imo}'**
  String imoValue(String imo);

  /// Localized text for ship info.
  ///
  /// In pt, this message translates to:
  /// **'Informações do Navio'**
  String get shipInfo;

  /// Localized text for general observations.
  ///
  /// In pt, this message translates to:
  /// **'Observações Gerais'**
  String get generalObservations;

  /// Localized text for cabin section.
  ///
  /// In pt, this message translates to:
  /// **'Cabine'**
  String get cabinSection;

  /// Localized text for bridge section.
  ///
  /// In pt, this message translates to:
  /// **'Passadiço'**
  String get bridgeSection;

  /// Localized text for other section.
  ///
  /// In pt, this message translates to:
  /// **'Outros'**
  String get otherSection;

  /// Label text for score.
  ///
  /// In pt, this message translates to:
  /// **'Nota: {score}'**
  String scoreLabel(String score);

  /// Localized text for anonymous.
  ///
  /// In pt, this message translates to:
  /// **'Anônimo'**
  String get anonymous;

  /// Localized text for not available.
  ///
  /// In pt, this message translates to:
  /// **'N/A'**
  String get notAvailable;

  /// Localized text for criteria cabin temp.
  ///
  /// In pt, this message translates to:
  /// **'Temperatura da Cabine'**
  String get criteriaCabinTemp;

  /// Localized text for criteria cabin cleanliness.
  ///
  /// In pt, this message translates to:
  /// **'Limpeza da Cabine'**
  String get criteriaCabinCleanliness;

  /// Localized text for criteria bridge equipment.
  ///
  /// In pt, this message translates to:
  /// **'Passadiço - Equipamentos'**
  String get criteriaBridgeEquipment;

  /// Localized text for criteria bridge temp.
  ///
  /// In pt, this message translates to:
  /// **'Passadiço - Temperatura'**
  String get criteriaBridgeTemp;

  /// Localized text for criteria device.
  ///
  /// In pt, this message translates to:
  /// **'Dispositivo de Embarque/Desembarque'**
  String get criteriaDevice;

  /// Localized text for criteria food.
  ///
  /// In pt, this message translates to:
  /// **'Comida'**
  String get criteriaFood;

  /// Localized text for criteria relationship.
  ///
  /// In pt, this message translates to:
  /// **'Relacionamento com comandante/tripulação'**
  String get criteriaRelationship;

  /// Title text for send suggestion.
  ///
  /// In pt, this message translates to:
  /// **'Enviar Sugestão'**
  String get sendSuggestionTitle;

  /// Localized text for your opinion matters.
  ///
  /// In pt, this message translates to:
  /// **'Sua opinião é importante'**
  String get yourOpinionMatters;

  /// Localized text for help improve app.
  ///
  /// In pt, this message translates to:
  /// **'Ajude a melhorar o ShipRate com sugestões e ideias.'**
  String get helpImproveApp;

  /// Localized text for suggestion type.
  ///
  /// In pt, this message translates to:
  /// **'Sugestão'**
  String get suggestionType;

  /// Localized text for complaint type.
  ///
  /// In pt, this message translates to:
  /// **'Crítica'**
  String get complaintType;

  /// Localized text for compliment type.
  ///
  /// In pt, this message translates to:
  /// **'Elogio'**
  String get complimentType;

  /// Label text for message.
  ///
  /// In pt, this message translates to:
  /// **'Mensagem'**
  String get messageLabel;

  /// Button label for send.
  ///
  /// In pt, this message translates to:
  /// **'Enviar'**
  String get sendButton;

  /// Localized text for message sent success.
  ///
  /// In pt, this message translates to:
  /// **'Mensagem enviada com sucesso!'**
  String get messageSentSuccess;

  /// Error message for sending message.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao enviar mensagem.'**
  String get errorSendingMessage;

  /// Localized text for dashboard app stats.
  ///
  /// In pt, this message translates to:
  /// **'ShipRate em números'**
  String get dashboardAppStats;

  /// Localized text for dashboard your activity.
  ///
  /// In pt, this message translates to:
  /// **'Sua Atividade'**
  String get dashboardYourActivity;

  /// Label text for total ships.
  ///
  /// In pt, this message translates to:
  /// **'Navios'**
  String get totalShipsLabel;

  /// Label text for total ratings.
  ///
  /// In pt, this message translates to:
  /// **'Avaliações'**
  String get totalRatingsLabel;

  /// Label text for total ship crossings.
  ///
  /// In pt, this message translates to:
  /// **'Cruzamentos'**
  String get totalCrossingsLabel;

  /// Label text for active pilots.
  ///
  /// In pt, this message translates to:
  /// **'Práticos'**
  String get activePilotsLabel;

  /// Label text for your ratings.
  ///
  /// In pt, this message translates to:
  /// **'Suas Avaliações'**
  String get yourRatingsLabel;

  /// Localized text for your contribution.
  ///
  /// In pt, this message translates to:
  /// **'Sua Contribuição'**
  String get yourContribution;

  /// Localized text for contribution progress.
  ///
  /// In pt, this message translates to:
  /// **'{percent}% das avaliações'**
  String contributionProgress(String percent);

  /// Localized text for contribution summary.
  ///
  /// In pt, this message translates to:
  /// **'Você avaliou {userCount} de {totalCount}'**
  String contributionSummary(String userCount, String totalCount);

  /// Localized text for top rater info.
  ///
  /// In pt, this message translates to:
  /// **'O prático que mais avaliou registrou {count} avaliações'**
  String topRaterInfo(String count);

  /// Localized text for user ranking position.
  ///
  /// In pt, this message translates to:
  /// **'Sua posição: #{position} de {total} práticos'**
  String userRankingPosition(String position, String total);

  /// Localized text for recent activity.
  ///
  /// In pt, this message translates to:
  /// **'Atividade Recente'**
  String get recentActivity;

  /// Empty-state or negative message for recent activity.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma atividade recente'**
  String get noRecentActivity;

  /// Localized text for last rated ship.
  ///
  /// In pt, this message translates to:
  /// **'Última Avaliação'**
  String get lastRatedShip;

  /// Title text for last rated ships.
  ///
  /// In pt, this message translates to:
  /// **'Últimas Avaliações'**
  String get lastRatedShipsTitle;

  /// Empty-state or negative message for recent ratings.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma avaliação recente'**
  String get noRecentRatings;

  /// Title text for pdf report.
  ///
  /// In pt, this message translates to:
  /// **'Relatório de Avaliação de Navio'**
  String get pdfReportTitle;

  /// Localized text for pdf evaluation info.
  ///
  /// In pt, this message translates to:
  /// **'Informações da Avaliação'**
  String get pdfEvaluationInfo;

  /// Localized text for pdf evaluator.
  ///
  /// In pt, this message translates to:
  /// **'Prático Avaliador'**
  String get pdfEvaluator;

  /// Localized text for pdf evaluation date.
  ///
  /// In pt, this message translates to:
  /// **'Data da Avaliação'**
  String get pdfEvaluationDate;

  /// Localized text for pdf cabin type.
  ///
  /// In pt, this message translates to:
  /// **'Tipo de Cabine'**
  String get pdfCabinType;

  /// Localized text for pdf disembarkation date.
  ///
  /// In pt, this message translates to:
  /// **'Data de Desembarque'**
  String get pdfDisembarkationDate;

  /// Localized text for pdf overall average.
  ///
  /// In pt, this message translates to:
  /// **'Nota Média Geral'**
  String get pdfOverallAverage;

  /// Localized text for pdf crew nationality.
  ///
  /// In pt, this message translates to:
  /// **'Nacionalidade da Tripulação'**
  String get pdfCrewNationality;

  /// Localized text for pdf cabin count.
  ///
  /// In pt, this message translates to:
  /// **'Quantidade de Cabines'**
  String get pdfCabinCount;

  /// Localized text for pdf ratings by criteria.
  ///
  /// In pt, this message translates to:
  /// **'Avaliações por Critério'**
  String get pdfRatingsByCriteria;

  /// Localized text for pdf general observation.
  ///
  /// In pt, this message translates to:
  /// **'Observação Geral'**
  String get pdfGeneralObservation;

  /// Localized text for pdf generated by.
  ///
  /// In pt, this message translates to:
  /// **'Gerado por ShipRate'**
  String get pdfGeneratedBy;

  /// Label text for pdf date.
  ///
  /// In pt, this message translates to:
  /// **'Data'**
  String get pdfDateLabel;

  /// Localized text for rating saved success.
  ///
  /// In pt, this message translates to:
  /// **'Avaliação salva com sucesso!'**
  String get ratingSavedSuccess;

  /// Localized text for rate this ship.
  ///
  /// In pt, this message translates to:
  /// **'Avaliar este Navio'**
  String get rateThisShip;

  /// Localized text for welcome pilot.
  ///
  /// In pt, this message translates to:
  /// **'Bem-vindo, {name}'**
  String welcomePilot(String name);

  /// Localized text for select module.
  ///
  /// In pt, this message translates to:
  /// **'Selecione o módulo'**
  String get selectModule;

  /// Localized text for ship rating module.
  ///
  /// In pt, this message translates to:
  /// **'Avaliação de Navios'**
  String get shipRatingModule;

  /// Description text for ship rating.
  ///
  /// In pt, this message translates to:
  /// **'Avalie navios e compartilhe experiências'**
  String get shipRatingDesc;

  /// Localized text for nav safety module.
  ///
  /// In pt, this message translates to:
  /// **'Profundidades - Registro'**
  String get navSafetyModule;

  /// Description text for nav safety.
  ///
  /// In pt, this message translates to:
  /// **'Profundidades, calado e condições dos trechos'**
  String get navSafetyDesc;

  /// Localized text for latest depths.
  ///
  /// In pt, this message translates to:
  /// **'Últimas Profundidades'**
  String get latestDepths;

  /// Localized text for locations.
  ///
  /// In pt, this message translates to:
  /// **'Locais'**
  String get locations;

  /// Localized text for new record.
  ///
  /// In pt, this message translates to:
  /// **'Novo Registro'**
  String get newRecord;

  /// Localized text for latest depths registered.
  ///
  /// In pt, this message translates to:
  /// **'Últimas profundidades registradas'**
  String get latestDepthsRegistered;

  /// Empty-state or negative message for records.
  ///
  /// In pt, this message translates to:
  /// **'Sem registros'**
  String get noRecords;

  /// Localized text for last depth.
  ///
  /// In pt, this message translates to:
  /// **'ÚLTIMA PROFUNDIDADE'**
  String get lastDepth;

  /// Localized text for history.
  ///
  /// In pt, this message translates to:
  /// **'Histórico'**
  String get history;

  /// Localized text for back.
  ///
  /// In pt, this message translates to:
  /// **'Voltar'**
  String get back;

  /// Small in-page back button label.
  ///
  /// In pt, this message translates to:
  /// **'Voltar'**
  String get goBack;

  /// Localized text for total depth.
  ///
  /// In pt, this message translates to:
  /// **'PROF. TOTAL'**
  String get totalDepth;

  /// Localized text for max draft.
  ///
  /// In pt, this message translates to:
  /// **'CALADO MÁX.'**
  String get maxDraft;

  /// Localized text for ukc.
  ///
  /// In pt, this message translates to:
  /// **'UKC'**
  String get ukc;

  /// Localized text for direction.
  ///
  /// In pt, this message translates to:
  /// **'DIREÇÃO'**
  String get direction;

  /// Localized text for passage data.
  ///
  /// In pt, this message translates to:
  /// **'Dados da Passagem'**
  String get passageData;

  /// Localized text for select location.
  ///
  /// In pt, this message translates to:
  /// **'Selecionar local'**
  String get selectLocation;

  /// Localized text for add new location.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar novo local'**
  String get addNewLocation;

  /// Localized text for new location name.
  ///
  /// In pt, this message translates to:
  /// **'Nome do novo local'**
  String get newLocationName;

  /// Localized text for anchorage pt.
  ///
  /// In pt, this message translates to:
  /// **'Ponto (1-15)'**
  String get anchoragePt;

  /// Localized text for ship name optional.
  ///
  /// In pt, this message translates to:
  /// **'Nome do navio (opcional)'**
  String get shipNameOptional;

  /// Localized text for passage date.
  ///
  /// In pt, this message translates to:
  /// **'Data da passagem'**
  String get passageDate;

  /// Localized text for going up.
  ///
  /// In pt, this message translates to:
  /// **'Subindo'**
  String get goingUp;

  /// Localized text for going down.
  ///
  /// In pt, this message translates to:
  /// **'Baixando'**
  String get goingDown;

  /// Label text for total depth.
  ///
  /// In pt, this message translates to:
  /// **'PROFUNDIDADE TOTAL'**
  String get totalDepthLabel;

  /// Localized text for complementary data.
  ///
  /// In pt, this message translates to:
  /// **'Dados Complementares'**
  String get complementaryData;

  /// Localized text for max draft input.
  ///
  /// In pt, this message translates to:
  /// **'Calado Máximo (m)'**
  String get maxDraftInput;

  /// Localized text for ukc input.
  ///
  /// In pt, this message translates to:
  /// **'UKC (m)'**
  String get ukcInput;

  /// Localized text for speed optional.
  ///
  /// In pt, this message translates to:
  /// **'Velocidade (nós)'**
  String get speedOptional;

  /// Localized text for optional.
  ///
  /// In pt, this message translates to:
  /// **'opcional'**
  String get optional;

  /// Localized text for squat considered.
  ///
  /// In pt, this message translates to:
  /// **'Squat considerado?'**
  String get squatConsidered;

  /// Localized text for sonar position.
  ///
  /// In pt, this message translates to:
  /// **'Posição da Sonda'**
  String get sonarPosition;

  /// Localized text for bow.
  ///
  /// In pt, this message translates to:
  /// **'Proa'**
  String get bow;

  /// Localized text for stern.
  ///
  /// In pt, this message translates to:
  /// **'Popa'**
  String get stern;

  /// Localized text for position lat long.
  ///
  /// In pt, this message translates to:
  /// **'Posição (LAT/LONG)'**
  String get positionLatLong;

  /// Localized text for observations.
  ///
  /// In pt, this message translates to:
  /// **'Observações / Referências'**
  String get observations;

  /// Localized text for additional info.
  ///
  /// In pt, this message translates to:
  /// **'Informações adicionais...'**
  String get additionalInfo;

  /// Localized text for register passage.
  ///
  /// In pt, this message translates to:
  /// **'Registrar Passagem'**
  String get registerPassage;

  /// Localized text for record saved success.
  ///
  /// In pt, this message translates to:
  /// **'Registro salvo com sucesso!'**
  String get recordSavedSuccess;

  /// Localized text for location required.
  ///
  /// In pt, this message translates to:
  /// **'Selecione um local'**
  String get locationRequired;

  /// Localized text for depth required.
  ///
  /// In pt, this message translates to:
  /// **'Informe a profundidade total'**
  String get depthRequired;

  /// Localized text for draft required.
  ///
  /// In pt, this message translates to:
  /// **'Informe o calado máximo'**
  String get draftRequired;

  /// Localized text for ukc required.
  ///
  /// In pt, this message translates to:
  /// **'Informe o UKC'**
  String get ukcRequired;

  /// Localized text for direction required.
  ///
  /// In pt, this message translates to:
  /// **'Selecione a direção'**
  String get directionRequired;

  /// Localized text for sonar required.
  ///
  /// In pt, this message translates to:
  /// **'Selecione a posição da sonda'**
  String get sonarRequired;

  /// Localized text for my records.
  ///
  /// In pt, this message translates to:
  /// **'Meus Registros'**
  String get myRecords;

  /// Localized text for drawer my records.
  ///
  /// In pt, this message translates to:
  /// **'Meus Registros'**
  String get drawerMyRecords;

  /// Localized text for your records.
  ///
  /// In pt, this message translates to:
  /// **'Seus Registros'**
  String get yourRecords;

  /// Label text for records.
  ///
  /// In pt, this message translates to:
  /// **'registros'**
  String get recordsLabel;

  /// Label text for locations.
  ///
  /// In pt, this message translates to:
  /// **'locais'**
  String get locationsLabel;

  /// Label text for contribution.
  ///
  /// In pt, this message translates to:
  /// **'contribuição'**
  String get contributionLabel;

  /// Localized text for edit record.
  ///
  /// In pt, this message translates to:
  /// **'Editar'**
  String get editRecord;

  /// Localized text for delete record.
  ///
  /// In pt, this message translates to:
  /// **'Excluir'**
  String get deleteRecord;

  /// Title text for delete record.
  ///
  /// In pt, this message translates to:
  /// **'Excluir Registro'**
  String get deleteRecordTitle;

  /// Localized text for delete record confirm.
  ///
  /// In pt, this message translates to:
  /// **'Tem certeza que deseja excluir este registro? Esta ação não pode ser desfeita.'**
  String get deleteRecordConfirm;

  /// Localized text for record deleted success.
  ///
  /// In pt, this message translates to:
  /// **'Registro excluído com sucesso!'**
  String get recordDeletedSuccess;

  /// Localized text for record updated success.
  ///
  /// In pt, this message translates to:
  /// **'Registro atualizado com sucesso!'**
  String get recordUpdatedSuccess;

  /// Localized text for update passage.
  ///
  /// In pt, this message translates to:
  /// **'Atualizar Passagem'**
  String get updatePassage;

  /// Empty-state or negative message for records yet.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum registro ainda'**
  String get noRecordsYet;

  /// Subtitle text for no records.
  ///
  /// In pt, this message translates to:
  /// **'Você ainda não registrou nenhuma passagem.\nComece registrando sua próxima passagem!'**
  String get noRecordsSubtitle;

  /// Localized text for record details.
  ///
  /// In pt, this message translates to:
  /// **'Detalhes do Registro'**
  String get recordDetails;

  /// Localized text for passage info.
  ///
  /// In pt, this message translates to:
  /// **'Informações da Passagem'**
  String get passageInfo;

  /// Localized text for by.
  ///
  /// In pt, this message translates to:
  /// **'Por'**
  String get by;

  /// Localized text for technical data.
  ///
  /// In pt, this message translates to:
  /// **'Dados Técnicos'**
  String get technicalData;

  /// Localized text for position.
  ///
  /// In pt, this message translates to:
  /// **'Posição'**
  String get position;

  /// Localized text for anchorage point.
  ///
  /// In pt, this message translates to:
  /// **'Ponto do Fundeadouro'**
  String get anchoragePoint;

  /// Localized text for total depth short.
  ///
  /// In pt, this message translates to:
  /// **'Prof. Total'**
  String get totalDepthShort;

  /// Localized text for modules.
  ///
  /// In pt, this message translates to:
  /// **'Módulos'**
  String get modules;

  /// Localized text for last record by.
  ///
  /// In pt, this message translates to:
  /// **'Último registro por: {name}'**
  String lastRecordBy(String name);

  /// Label text for nav ship.
  ///
  /// In pt, this message translates to:
  /// **'Navio: {name}'**
  String navShipLabel(String name);

  /// Localized text for enter email.
  ///
  /// In pt, this message translates to:
  /// **'Entre com seu email'**
  String get enterEmail;

  /// Localized text for send code.
  ///
  /// In pt, this message translates to:
  /// **'Enviar código'**
  String get sendCode;

  /// Localized text for email not authorized.
  ///
  /// In pt, this message translates to:
  /// **'Email não autorizado. Entre em contato com a ZP01.'**
  String get emailNotAuthorized;

  /// Localized text for code sent to.
  ///
  /// In pt, this message translates to:
  /// **'Código enviado para {email}'**
  String codeSentTo(String email);

  /// Localized text for enter code.
  ///
  /// In pt, this message translates to:
  /// **'Digite o código de 6 dígitos'**
  String get enterCode;

  /// Localized text for verify.
  ///
  /// In pt, this message translates to:
  /// **'Verificar'**
  String get verify;

  /// Localized text for resend code.
  ///
  /// In pt, this message translates to:
  /// **'Reenviar código'**
  String get resendCode;

  /// Localized text for invalid code.
  ///
  /// In pt, this message translates to:
  /// **'Código inválido'**
  String get invalidCode;

  /// Localized text for expired code.
  ///
  /// In pt, this message translates to:
  /// **'Código expirado. Solicite um novo.'**
  String get expiredCode;

  /// Localized text for rate limited.
  ///
  /// In pt, this message translates to:
  /// **'Muitas tentativas. Aguarde 15 minutos.'**
  String get rateLimited;

  /// Localized text for too many attempts.
  ///
  /// In pt, this message translates to:
  /// **'Muitas tentativas incorretas. Aguarde 15 minutos.'**
  String get tooManyAttempts;

  /// Localized text for resend in.
  ///
  /// In pt, this message translates to:
  /// **'Reenviar em {seconds}s'**
  String resendIn(String seconds);

  /// Empty-state or negative message for account.
  ///
  /// In pt, this message translates to:
  /// **'Não tem conta? Registrar'**
  String get noAccount;

  /// Localized text for register.
  ///
  /// In pt, this message translates to:
  /// **'Registrar'**
  String get register;

  /// Localized text for create password.
  ///
  /// In pt, this message translates to:
  /// **'Criar senha'**
  String get createPassword;

  /// Hint text for password.
  ///
  /// In pt, this message translates to:
  /// **'Mínimo 6 caracteres'**
  String get passwordHint;

  /// Localized text for account created.
  ///
  /// In pt, this message translates to:
  /// **'Conta criada com sucesso!'**
  String get accountCreated;

  /// Localized text for invalid credentials.
  ///
  /// In pt, this message translates to:
  /// **'Email ou senha incorretos'**
  String get invalidCredentials;

  /// Localized text for passwords do not match.
  ///
  /// In pt, this message translates to:
  /// **'As senhas não coincidem'**
  String get passwordsDoNotMatch;

  /// Localized text for password too short.
  ///
  /// In pt, this message translates to:
  /// **'A senha deve ter pelo menos 6 caracteres'**
  String get passwordTooShort;

  /// Localized text for email already registered.
  ///
  /// In pt, this message translates to:
  /// **'Este email já possui uma conta. Use a tela de login.'**
  String get emailAlreadyRegistered;

  /// Localized text for settings.
  ///
  /// In pt, this message translates to:
  /// **'Configurações'**
  String get settings;

  /// Localized text for push notifications.
  ///
  /// In pt, this message translates to:
  /// **'Notificações push'**
  String get pushNotifications;

  /// Localized text for email notifications.
  ///
  /// In pt, this message translates to:
  /// **'Notificações por email'**
  String get emailNotifications;

  /// Notification-related text for permission denied.
  ///
  /// In pt, this message translates to:
  /// **'Permissão de notificação negada'**
  String get notificationPermissionDenied;

  /// Localized text for invalid email.
  ///
  /// In pt, this message translates to:
  /// **'Email inválido'**
  String get invalidEmail;

  /// Localized text for nav safety blocked.
  ///
  /// In pt, this message translates to:
  /// **'Para ter acesso à área de segurança da navegação, registre-se novamente no aplicativo usando seu e-mail da Unipilot.'**
  String get navSafetyBlocked;

  /// Localized text for photos.
  ///
  /// In pt, this message translates to:
  /// **'Fotos'**
  String get photos;

  /// Localized text for add photo.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar foto'**
  String get addPhoto;

  /// Localized text for max photos reached.
  ///
  /// In pt, this message translates to:
  /// **'Máximo de 3 fotos'**
  String get maxPhotosReached;

  /// Notification-related text for dialog title.
  ///
  /// In pt, this message translates to:
  /// **'Notificações'**
  String get notificationDialogTitle;

  /// Notification-related text for dialog body.
  ///
  /// In pt, this message translates to:
  /// **'Deseja receber notificações quando novos registros de profundidade forem adicionados?'**
  String get notificationDialogBody;

  /// Notification-related text for dialog enable.
  ///
  /// In pt, this message translates to:
  /// **'Ativar'**
  String get notificationDialogEnable;

  /// Notification-related text for dialog not now.
  ///
  /// In pt, this message translates to:
  /// **'Agora não'**
  String get notificationDialogNotNow;

  /// Notification-related text shown after notifications are enabled.
  ///
  /// In pt, this message translates to:
  /// **'Notificações ativadas!'**
  String get notificationsEnabled;

  /// Localized text for liked by.
  ///
  /// In pt, this message translates to:
  /// **'Curtido por {names}'**
  String likedBy(String names);

  /// Localized text for and word.
  ///
  /// In pt, this message translates to:
  /// **'e'**
  String get andWord;

  /// Localized text for and more.
  ///
  /// In pt, this message translates to:
  /// **'e mais {count}'**
  String andMore(int count);

  /// Localized text for like notification.
  ///
  /// In pt, this message translates to:
  /// **'{name} curtiu seu registro de profundidade'**
  String likeNotification(String name);

  /// Localized text for rating like notification.
  ///
  /// In pt, this message translates to:
  /// **'{name} curtiu sua avaliação'**
  String ratingLikeNotification(String name);

  /// Drawer item to switch to nav safety module.
  ///
  /// In pt, this message translates to:
  /// **'Alternar para Profundidades - Registro'**
  String get switchToNavSafety;

  /// Drawer item to switch to ship rating module.
  ///
  /// In pt, this message translates to:
  /// **'Alternar para Avaliação de Navios'**
  String get switchToShipRating;

  /// Dialog title after saving a depth record.
  ///
  /// In pt, this message translates to:
  /// **'Registro salvo!'**
  String get recordSaved;

  /// Dialog body asking to share depth record.
  ///
  /// In pt, this message translates to:
  /// **'Deseja compartilhar esta profundidade com outros práticos?'**
  String get shareRecordPrompt;

  /// Button label to share a record.
  ///
  /// In pt, this message translates to:
  /// **'Compartilhar'**
  String get shareRecord;

  /// Button label to dismiss share dialog.
  ///
  /// In pt, this message translates to:
  /// **'Não, obrigado'**
  String get noThanks;

  /// Title text for pdf ship report.
  ///
  /// In pt, this message translates to:
  /// **'Relatório do Navio'**
  String get pdfShipReportTitle;

  /// Section title for rating averages in ship report PDF.
  ///
  /// In pt, this message translates to:
  /// **'Médias das Avaliações'**
  String get pdfAveragesSection;

  /// Section title for individual ratings in ship report PDF.
  ///
  /// In pt, this message translates to:
  /// **'Avaliações Individuais'**
  String get pdfIndividualRatings;

  /// Label for total ratings count in ship report PDF.
  ///
  /// In pt, this message translates to:
  /// **'Total de Avaliações'**
  String get pdfTotalRatingsCount;

  /// Label for observation in ship report PDF.
  ///
  /// In pt, this message translates to:
  /// **'Observação'**
  String get pdfObservation;

  /// Label for rated by in ship report PDF.
  ///
  /// In pt, this message translates to:
  /// **'Avaliado por'**
  String get pdfRatedBy;

  /// Button label for exporting ship report PDF.
  ///
  /// In pt, this message translates to:
  /// **'Exportar Relatório'**
  String get exportShipReport;

  /// Module name for ship crossing.
  ///
  /// In pt, this message translates to:
  /// **'Cruzamento de Navios'**
  String get cruzamentoModule;

  /// Description for ship crossing module.
  ///
  /// In pt, this message translates to:
  /// **'Registre e acompanhe cruzamentos'**
  String get cruzamentoDesc;

  /// Header for active crossings list.
  ///
  /// In pt, this message translates to:
  /// **'Cruzamentos ativos'**
  String get activeCrossings;

  /// Empty state for crossings.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum cruzamento registrado'**
  String get noCrossings;

  /// Button label for new crossing.
  ///
  /// In pt, this message translates to:
  /// **'Novo cruzamento'**
  String get newCrossing;

  /// Label for crossing location field.
  ///
  /// In pt, this message translates to:
  /// **'Local'**
  String get crossingLocation;

  /// Label for crossing time field.
  ///
  /// In pt, this message translates to:
  /// **'Horário previsto (Brasília)'**
  String get crossingTime;

  /// Label for ship name in crossing form.
  ///
  /// In pt, this message translates to:
  /// **'Nome do navio'**
  String get crossingShipName;

  /// Label for ship draft in crossing form.
  ///
  /// In pt, this message translates to:
  /// **'Calado do navio'**
  String get draftLabel;

  /// Draft range option up to 6.5 meters.
  ///
  /// In pt, this message translates to:
  /// **'Até 6,5m'**
  String get draftUpTo65;

  /// Draft range option from 6.5 to 9.5 meters.
  ///
  /// In pt, this message translates to:
  /// **'6,5 a 9,5m'**
  String get draft65To95;

  /// Draft range option above 9.5 meters.
  ///
  /// In pt, this message translates to:
  /// **'Acima de 9,5m'**
  String get draftAbove95;

  /// Option for custom crossing location.
  ///
  /// In pt, this message translates to:
  /// **'Outro'**
  String get otherLocation;

  /// Direction option going upstream.
  ///
  /// In pt, this message translates to:
  /// **'Subindo'**
  String get directionUp;

  /// Direction option going downstream.
  ///
  /// In pt, this message translates to:
  /// **'Baixando'**
  String get directionDown;

  /// Label for pilots to contact field.
  ///
  /// In pt, this message translates to:
  /// **'Práticos para contactar'**
  String get pilotsToContact;

  /// Label for crossing observations field.
  ///
  /// In pt, this message translates to:
  /// **'Observações'**
  String get crossingObservations;

  /// Button label for registering a crossing.
  ///
  /// In pt, this message translates to:
  /// **'Registrar cruzamento'**
  String get registerCrossing;

  /// Button label for updating a crossing.
  ///
  /// In pt, this message translates to:
  /// **'Atualizar cruzamento'**
  String get updateCrossing;

  /// Notification text for updated crossing time.
  ///
  /// In pt, this message translates to:
  /// **'{name} atualizou o horário do cruzamento em {location}'**
  String crossingTimeUpdated(String name, String location);

  /// Label for crossing alert expiry date.
  ///
  /// In pt, this message translates to:
  /// **'Alertas ativos até'**
  String get alertsActiveUntil;

  /// Button label for selecting the crossing alert expiry date.
  ///
  /// In pt, this message translates to:
  /// **'Selecionar data'**
  String get selectEndDate;

  /// Label for receive alerts toggle.
  ///
  /// In pt, this message translates to:
  /// **'Receber alertas'**
  String get receiveAlerts;

  /// Button label for sharing a crossing.
  ///
  /// In pt, this message translates to:
  /// **'Compartilhar'**
  String get shareCrossing;

  /// Success message after saving crossing.
  ///
  /// In pt, this message translates to:
  /// **'Cruzamento registrado!'**
  String get crossingSaved;

  /// Erro exibido quando o cruzamento e salvo com horario atual ou passado.
  ///
  /// In pt, this message translates to:
  /// **'O horario previsto do cruzamento deve estar no futuro.'**
  String get crossingTimeMustBeFuture;

  /// Dialog body asking to share crossing.
  ///
  /// In pt, this message translates to:
  /// **'Deseja compartilhar este cruzamento com outros práticos?'**
  String get shareCrossingPrompt;

  /// Label for nav safety push toggle.
  ///
  /// In pt, this message translates to:
  /// **'Profundidades - Registro'**
  String get pushNavSafetyLabel;

  /// Label for ratings push toggle.
  ///
  /// In pt, this message translates to:
  /// **'Avaliações e Likes'**
  String get pushRatingsLabel;

  /// Label for my crossings section.
  ///
  /// In pt, this message translates to:
  /// **'Meus cruzamentos'**
  String get myCrossings;

  /// User crossing ranking position shown on the my crossings tab.
  ///
  /// In pt, this message translates to:
  /// **'Sua posição: {position} de {total} práticos'**
  String crossingRankingPosition(String position, int total);

  /// Top crossing count shown on the my crossings tab.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{O prático que mais registrou cruzamentos: 1 cruzamento} other{O prático que mais registrou cruzamentos: {count} cruzamentos}}'**
  String crossingTopCrosser(int count);

  /// Motivational message about crossings shown on the dashboard.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{1 cruzamento realizado com segurança, graças à sua participação} other{{count} cruzamentos realizados com segurança, graças à sua participação}}'**
  String crossingsMotivational(int count);

  /// Section title for crossings on the dashboard.
  ///
  /// In pt, this message translates to:
  /// **'Cruzamentos'**
  String get crossingsDashboardTitle;

  /// Message shown when notification permission is denied.
  ///
  /// In pt, this message translates to:
  /// **'Para receber notificações, permita o envio de notificações nas configurações do seu dispositivo'**
  String get enableNotificationsMessage;

  /// Banner text prompting to enable notifications.
  ///
  /// In pt, this message translates to:
  /// **'Ative as notificações para receber alertas'**
  String get enableNotificationsBanner;

  /// Message shown when notification permission is denied on settings page.
  ///
  /// In pt, this message translates to:
  /// **'Permissão negada. Ative as notificações nas configurações do navegador/sistema.'**
  String get permissionDeniedSettings;

  /// Prompt to enable notifications for depth record alerts.
  ///
  /// In pt, this message translates to:
  /// **'Ative as notificações para receber alertas quando novos registros de profundidade forem adicionados.'**
  String get enableNotificationsDepthPrompt;

  /// Button label for enabling notifications.
  ///
  /// In pt, this message translates to:
  /// **'Ativar notificações'**
  String get enableNotificationsButtonLabel;

  /// Tooltip or button label for closing.
  ///
  /// In pt, this message translates to:
  /// **'Fechar'**
  String get close;

  /// Button label for deleting user account.
  ///
  /// In pt, this message translates to:
  /// **'Excluir minha conta'**
  String get deleteAccount;

  /// Title for delete account confirmation dialog.
  ///
  /// In pt, this message translates to:
  /// **'Excluir conta'**
  String get deleteAccountTitle;

  /// Body text for delete account confirmation dialog.
  ///
  /// In pt, this message translates to:
  /// **'Tem certeza que deseja excluir sua conta? Esta ação não pode ser desfeita. Suas avaliações e registros continuarão disponíveis para outros práticos.'**
  String get deleteAccountBody;

  /// Confirm button for delete account dialog.
  ///
  /// In pt, this message translates to:
  /// **'Excluir'**
  String get deleteAccountConfirm;

  /// Cancel button for delete account dialog.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar'**
  String get deleteAccountCancel;

  /// Password prompt for delete account confirmation.
  ///
  /// In pt, this message translates to:
  /// **'Para confirmar, digite sua senha'**
  String get deleteAccountPassword;

  /// Hint text for password field in delete account dialog.
  ///
  /// In pt, this message translates to:
  /// **'Sua senha'**
  String get deleteAccountPasswordHint;

  /// Button label for confirming account deletion with password.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar exclusão'**
  String get deleteAccountConfirmButton;

  /// Success message after account deletion.
  ///
  /// In pt, this message translates to:
  /// **'Conta excluída com sucesso'**
  String get deleteAccountSuccess;

  /// Error message for wrong password during account deletion.
  ///
  /// In pt, this message translates to:
  /// **'Senha incorreta'**
  String get deleteAccountWrongPassword;

  /// Error message for network error during account deletion.
  ///
  /// In pt, this message translates to:
  /// **'Erro de conexão. Tente novamente.'**
  String get deleteAccountNetworkError;

  /// Generic error message for account deletion failure.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao excluir conta. Tente novamente.'**
  String get deleteAccountError;

  /// Prompt for non-email users to type DELETE to confirm account deletion.
  ///
  /// In pt, this message translates to:
  /// **'Para confirmar, digite DELETE abaixo'**
  String get deleteAccountTypeConfirm;

  /// Hint text for the DELETE confirmation field.
  ///
  /// In pt, this message translates to:
  /// **'Digite DELETE'**
  String get deleteAccountTypeHint;

  /// Error message when not all fields are filled.
  ///
  /// In pt, this message translates to:
  /// **'Preencha todos os campos.'**
  String get fillAllFields;

  /// Relative time label for just-now ratings.
  ///
  /// In pt, this message translates to:
  /// **'Avaliado agora'**
  String get ratedNow;

  /// Relative time label for ratings made minutes ago.
  ///
  /// In pt, this message translates to:
  /// **'Avaliado há {count} min'**
  String ratedMinutesAgo(int count);

  /// Relative time label for ratings made hours ago.
  ///
  /// In pt, this message translates to:
  /// **'Avaliado há {count}h'**
  String ratedHoursAgo(int count);

  /// Relative time label for yesterday's ratings.
  ///
  /// In pt, this message translates to:
  /// **'Avaliado ontem'**
  String get ratedYesterday;

  /// Relative time label for ratings made days ago.
  ///
  /// In pt, this message translates to:
  /// **'Avaliado há {count} dias'**
  String ratedDaysAgo(int count);

  /// Relative time label for older ratings with date.
  ///
  /// In pt, this message translates to:
  /// **'Avaliado em {date}'**
  String ratedOnDate(String date);

  /// Default pilot name when call sign is not available.
  ///
  /// In pt, this message translates to:
  /// **'Prático'**
  String get defaultPilotName;

  /// Default text when no observations are present in PDF.
  ///
  /// In pt, this message translates to:
  /// **'Sem observações'**
  String get pdfNoObservations;

  /// Default update message shown in update banner.
  ///
  /// In pt, this message translates to:
  /// **'Nova atualização disponível. Por favor, feche e reabra o app para aplicar as melhorias.'**
  String get defaultUpdateMessage;

  /// Error message for empty image selection.
  ///
  /// In pt, this message translates to:
  /// **'A imagem selecionada está vazia.'**
  String get imageEmptyError;

  /// Error message for unsupported image format.
  ///
  /// In pt, this message translates to:
  /// **'Formato não suportado. Use apenas JPG, PNG ou WEBP.'**
  String get formatNotSupportedError;

  /// Error message for oversized image.
  ///
  /// In pt, this message translates to:
  /// **'Cada imagem deve ter no máximo 20 MB.'**
  String get imageTooLargeError;

  /// Error message for exceeding max images per record.
  ///
  /// In pt, this message translates to:
  /// **'Você pode anexar no máximo 3 imagens por registro.'**
  String get maxImagesExceededError;

  /// Title line in WhatsApp share message for depth records.
  ///
  /// In pt, this message translates to:
  /// **'Nova profundidade registrada'**
  String get shareDepthTitle;

  /// Footer line in WhatsApp share message for depth records.
  ///
  /// In pt, this message translates to:
  /// **'Abra o app para ver os históricos de profundidades'**
  String get shareDepthFooter;

  /// Message shown when Firebase initialization fails.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível conectar. Por favor, feche e reabra o aplicativo.'**
  String get firebaseUnavailable;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'pt': return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
