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

  /// No description provided for @appTitle.
  ///
  /// In pt, this message translates to:
  /// **'ShipRate'**
  String get appTitle;

  /// No description provided for @email.
  ///
  /// In pt, this message translates to:
  /// **'E-mail'**
  String get email;

  /// No description provided for @password.
  ///
  /// In pt, this message translates to:
  /// **'Senha'**
  String get password;

  /// No description provided for @yes.
  ///
  /// In pt, this message translates to:
  /// **'Sim'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In pt, this message translates to:
  /// **'Não'**
  String get no;

  /// No description provided for @cancel.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar'**
  String get cancel;

  /// No description provided for @ratings.
  ///
  /// In pt, this message translates to:
  /// **'Avaliações'**
  String get ratings;

  /// No description provided for @cabin.
  ///
  /// In pt, this message translates to:
  /// **'Cabine'**
  String get cabin;

  /// No description provided for @bridge.
  ///
  /// In pt, this message translates to:
  /// **'Passadiço'**
  String get bridge;

  /// No description provided for @pilot.
  ///
  /// In pt, this message translates to:
  /// **'Prático'**
  String get pilot;

  /// No description provided for @loginSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Entre com seu e-mail e senha para continuar'**
  String get loginSubtitle;

  /// No description provided for @loginButton.
  ///
  /// In pt, this message translates to:
  /// **'Entrar'**
  String get loginButton;

  /// No description provided for @loginSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Login realizado com sucesso'**
  String get loginSuccess;

  /// No description provided for @forgotPassword.
  ///
  /// In pt, this message translates to:
  /// **'Esqueci minha senha'**
  String get forgotPassword;

  /// No description provided for @createAccount.
  ///
  /// In pt, this message translates to:
  /// **'Criar nova conta'**
  String get createAccount;

  /// No description provided for @createAccountTitle.
  ///
  /// In pt, this message translates to:
  /// **'Criar conta'**
  String get createAccountTitle;

  /// No description provided for @registerSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Preencha os dados para continuar'**
  String get registerSubtitle;

  /// No description provided for @callSign.
  ///
  /// In pt, this message translates to:
  /// **'Nome de guerra'**
  String get callSign;

  /// No description provided for @confirmPassword.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar senha'**
  String get confirmPassword;

  /// No description provided for @registerButton.
  ///
  /// In pt, this message translates to:
  /// **'Cadastrar'**
  String get registerButton;

  /// No description provided for @registerSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Cadastro realizado com sucesso'**
  String get registerSuccess;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In pt, this message translates to:
  /// **'Já tenho uma conta'**
  String get alreadyHaveAccount;

  /// No description provided for @recoverPassword.
  ///
  /// In pt, this message translates to:
  /// **'Recuperar senha'**
  String get recoverPassword;

  /// No description provided for @recoverPasswordSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Informe seu e-mail para receber o link de redefinição'**
  String get recoverPasswordSubtitle;

  /// No description provided for @sendLink.
  ///
  /// In pt, this message translates to:
  /// **'Enviar link'**
  String get sendLink;

  /// No description provided for @resetEmailSent.
  ///
  /// In pt, this message translates to:
  /// **'Enviamos um link de recuperação para o seu e-mail.'**
  String get resetEmailSent;

  /// No description provided for @spamNotice.
  ///
  /// In pt, this message translates to:
  /// **'Caso não encontre o e-mail, verifique também sua caixa de SPAM ou Lixo Eletrônico.'**
  String get spamNotice;

  /// No description provided for @backToLogin.
  ///
  /// In pt, this message translates to:
  /// **'Voltar para o login'**
  String get backToLogin;

  /// No description provided for @appSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Avaliação profissional de navios'**
  String get appSubtitle;

  /// No description provided for @drawerSearchRate.
  ///
  /// In pt, this message translates to:
  /// **'Buscar / Avaliar Navios'**
  String get drawerSearchRate;

  /// No description provided for @drawerMyRatings.
  ///
  /// In pt, this message translates to:
  /// **'Minhas Avaliações'**
  String get drawerMyRatings;

  /// No description provided for @drawerSendSuggestion.
  ///
  /// In pt, this message translates to:
  /// **'Enviar Sugestão'**
  String get drawerSendSuggestion;

  /// No description provided for @drawerShareApp.
  ///
  /// In pt, this message translates to:
  /// **'Compartilhar App'**
  String get drawerShareApp;

  /// No description provided for @drawerLogout.
  ///
  /// In pt, this message translates to:
  /// **'Sair'**
  String get drawerLogout;

  /// No description provided for @linkCopied.
  ///
  /// In pt, this message translates to:
  /// **'Link copiado para a área de transferência!'**
  String get linkCopied;

  /// No description provided for @updateAvailable.
  ///
  /// In pt, this message translates to:
  /// **'Atualização Disponível'**
  String get updateAvailable;

  /// No description provided for @shareShipRate.
  ///
  /// In pt, this message translates to:
  /// **'Compartilhar ShipRate'**
  String get shareShipRate;

  /// No description provided for @copyLink.
  ///
  /// In pt, this message translates to:
  /// **'Copiar Link'**
  String get copyLink;

  /// No description provided for @shareText.
  ///
  /// In pt, this message translates to:
  /// **'Conheça o ShipRate! O app de avaliação profissional de navios para práticos. Acesse: https://shiprate-daf18.web.app/'**
  String get shareText;

  /// No description provided for @shipRatingTitle.
  ///
  /// In pt, this message translates to:
  /// **'Avaliação de Navios'**
  String get shipRatingTitle;

  /// No description provided for @searchSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Pesquise avaliações ou registre sua experiência'**
  String get searchSubtitle;

  /// No description provided for @searchTab.
  ///
  /// In pt, this message translates to:
  /// **'Buscar'**
  String get searchTab;

  /// No description provided for @rateTab.
  ///
  /// In pt, this message translates to:
  /// **'Avaliar'**
  String get rateTab;

  /// No description provided for @searchHint.
  ///
  /// In pt, this message translates to:
  /// **'Buscar por nome do navio ou IMO'**
  String get searchHint;

  /// No description provided for @newShipRating.
  ///
  /// In pt, this message translates to:
  /// **'Nova Avaliação de Navio'**
  String get newShipRating;

  /// No description provided for @rateSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Registre sua avaliação técnica de forma rápida e segura'**
  String get rateSubtitle;

  /// No description provided for @startRating.
  ///
  /// In pt, this message translates to:
  /// **'Iniciar avaliação'**
  String get startRating;

  /// No description provided for @generalInfo.
  ///
  /// In pt, this message translates to:
  /// **'Informações Gerais'**
  String get generalInfo;

  /// No description provided for @ratingAverages.
  ///
  /// In pt, this message translates to:
  /// **'Médias das Avaliações'**
  String get ratingAverages;

  /// No description provided for @viewOnMarineTraffic.
  ///
  /// In pt, this message translates to:
  /// **'Ver Detalhes no MarineTraffic'**
  String get viewOnMarineTraffic;

  /// No description provided for @marineTrafficError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível abrir MarineTraffic'**
  String get marineTrafficError;

  /// No description provided for @crew.
  ///
  /// In pt, this message translates to:
  /// **'Tripulação'**
  String get crew;

  /// No description provided for @cabins.
  ///
  /// In pt, this message translates to:
  /// **'Cabines'**
  String get cabins;

  /// No description provided for @minibar.
  ///
  /// In pt, this message translates to:
  /// **'Frigobar'**
  String get minibar;

  /// No description provided for @sink.
  ///
  /// In pt, this message translates to:
  /// **'Pia'**
  String get sink;

  /// No description provided for @microwave.
  ///
  /// In pt, this message translates to:
  /// **'Micro-ondas'**
  String get microwave;

  /// No description provided for @avgCabinTemp.
  ///
  /// In pt, this message translates to:
  /// **'Temp. Cabine'**
  String get avgCabinTemp;

  /// No description provided for @avgCabinCleanliness.
  ///
  /// In pt, this message translates to:
  /// **'Limpeza Cabine'**
  String get avgCabinCleanliness;

  /// No description provided for @avgBridgeEquipment.
  ///
  /// In pt, this message translates to:
  /// **'Equip. Passadiço'**
  String get avgBridgeEquipment;

  /// No description provided for @avgBridgeTemp.
  ///
  /// In pt, this message translates to:
  /// **'Temp. Passadiço'**
  String get avgBridgeTemp;

  /// No description provided for @avgFood.
  ///
  /// In pt, this message translates to:
  /// **'Alimentação'**
  String get avgFood;

  /// No description provided for @avgRelationship.
  ///
  /// In pt, this message translates to:
  /// **'Relacionamento'**
  String get avgRelationship;

  /// No description provided for @avgDevice.
  ///
  /// In pt, this message translates to:
  /// **'Dispositivo'**
  String get avgDevice;

  /// No description provided for @pilotCallSign.
  ///
  /// In pt, this message translates to:
  /// **'Prático: {callSign}'**
  String pilotCallSign(String callSign);

  /// No description provided for @viewRating.
  ///
  /// In pt, this message translates to:
  /// **'Visualizar avaliação'**
  String get viewRating;

  /// No description provided for @rateShipTitle.
  ///
  /// In pt, this message translates to:
  /// **'Avaliar Navio'**
  String get rateShipTitle;

  /// No description provided for @saveRating.
  ///
  /// In pt, this message translates to:
  /// **'Salvar Avaliação'**
  String get saveRating;

  /// No description provided for @shipData.
  ///
  /// In pt, this message translates to:
  /// **'Dados do Navio'**
  String get shipData;

  /// No description provided for @shipName.
  ///
  /// In pt, this message translates to:
  /// **'Nome do navio'**
  String get shipName;

  /// No description provided for @enterShipName.
  ///
  /// In pt, this message translates to:
  /// **'Informe o nome do navio'**
  String get enterShipName;

  /// No description provided for @imoOptional.
  ///
  /// In pt, this message translates to:
  /// **'IMO (opcional)'**
  String get imoOptional;

  /// No description provided for @disembarkationDate.
  ///
  /// In pt, this message translates to:
  /// **'Data de desembarque'**
  String get disembarkationDate;

  /// No description provided for @tapToSelect.
  ///
  /// In pt, this message translates to:
  /// **'Toque para selecionar'**
  String get tapToSelect;

  /// No description provided for @crewNationality.
  ///
  /// In pt, this message translates to:
  /// **'Nacionalidade da tripulação'**
  String get crewNationality;

  /// No description provided for @nationalityFilipino.
  ///
  /// In pt, this message translates to:
  /// **'Filipina'**
  String get nationalityFilipino;

  /// No description provided for @nationalityRussian.
  ///
  /// In pt, this message translates to:
  /// **'Russa'**
  String get nationalityRussian;

  /// No description provided for @nationalityUkrainian.
  ///
  /// In pt, this message translates to:
  /// **'Ucraniana'**
  String get nationalityUkrainian;

  /// No description provided for @nationalityIndian.
  ///
  /// In pt, this message translates to:
  /// **'Indiana'**
  String get nationalityIndian;

  /// No description provided for @nationalityChinese.
  ///
  /// In pt, this message translates to:
  /// **'Chinesa'**
  String get nationalityChinese;

  /// No description provided for @nationalityBrazilian.
  ///
  /// In pt, this message translates to:
  /// **'Brasileira'**
  String get nationalityBrazilian;

  /// No description provided for @nationalityOther.
  ///
  /// In pt, this message translates to:
  /// **'Outro'**
  String get nationalityOther;

  /// No description provided for @specifyNationality.
  ///
  /// In pt, this message translates to:
  /// **'Especifique a nacionalidade'**
  String get specifyNationality;

  /// No description provided for @cabinCount.
  ///
  /// In pt, this message translates to:
  /// **'Quantidade de cabines'**
  String get cabinCount;

  /// No description provided for @cabinCountOne.
  ///
  /// In pt, this message translates to:
  /// **'Uma'**
  String get cabinCountOne;

  /// No description provided for @cabinCountTwo.
  ///
  /// In pt, this message translates to:
  /// **'Duas'**
  String get cabinCountTwo;

  /// No description provided for @cabinCountMoreThanTwo.
  ///
  /// In pt, this message translates to:
  /// **'Mais de duas'**
  String get cabinCountMoreThanTwo;

  /// No description provided for @cabinType.
  ///
  /// In pt, this message translates to:
  /// **'Tipo da cabine'**
  String get cabinType;

  /// No description provided for @cabinDeck.
  ///
  /// In pt, this message translates to:
  /// **'Deck da cabine'**
  String get cabinDeck;

  /// No description provided for @deckBridge.
  ///
  /// In pt, this message translates to:
  /// **'Deck do passadiço'**
  String get deckBridge;

  /// No description provided for @deck1Below.
  ///
  /// In pt, this message translates to:
  /// **'1 deck abaixo do passadiço'**
  String get deck1Below;

  /// No description provided for @deck2Below.
  ///
  /// In pt, this message translates to:
  /// **'2 decks abaixo do passadiço'**
  String get deck2Below;

  /// No description provided for @deck3Below.
  ///
  /// In pt, this message translates to:
  /// **'3 decks abaixo do passadiço'**
  String get deck3Below;

  /// No description provided for @deck4PlusBelow.
  ///
  /// In pt, this message translates to:
  /// **'4+ decks abaixo do passadiço'**
  String get deck4PlusBelow;

  /// No description provided for @deckLabel.
  ///
  /// In pt, this message translates to:
  /// **'Deck {deck}'**
  String deckLabel(String deck);

  /// No description provided for @hasMinibar.
  ///
  /// In pt, this message translates to:
  /// **'Possui frigobar'**
  String get hasMinibar;

  /// No description provided for @hasSink.
  ///
  /// In pt, this message translates to:
  /// **'Possui pia'**
  String get hasSink;

  /// No description provided for @hasMicrowave.
  ///
  /// In pt, this message translates to:
  /// **'Possui micro-ondas'**
  String get hasMicrowave;

  /// No description provided for @otherRatings.
  ///
  /// In pt, this message translates to:
  /// **'Outras Avaliações'**
  String get otherRatings;

  /// No description provided for @generalObservation.
  ///
  /// In pt, this message translates to:
  /// **'Observação Geral'**
  String get generalObservation;

  /// No description provided for @generalObservationHint.
  ///
  /// In pt, this message translates to:
  /// **'Comentários adicionais sobre a experiência geral no navio...'**
  String get generalObservationHint;

  /// No description provided for @observationsOptional.
  ///
  /// In pt, this message translates to:
  /// **'Observações (opcional)'**
  String get observationsOptional;

  /// No description provided for @shipFoundTapToRate.
  ///
  /// In pt, this message translates to:
  /// **'Navio encontrado — toque para selecionar da lista'**
  String get shipFoundTapToRate;

  /// No description provided for @shipExistsSelectFromList.
  ///
  /// In pt, this message translates to:
  /// **'Este navio já existe. Selecione-o na lista suspensa.'**
  String get shipExistsSelectFromList;

  /// No description provided for @fillRequiredFields.
  ///
  /// In pt, this message translates to:
  /// **'Preencha todos os campos obrigatórios'**
  String get fillRequiredFields;

  /// No description provided for @editRatingTitle.
  ///
  /// In pt, this message translates to:
  /// **'Editar Avaliação'**
  String get editRatingTitle;

  /// No description provided for @saveChanges.
  ///
  /// In pt, this message translates to:
  /// **'Salvar Alterações'**
  String get saveChanges;

  /// No description provided for @editWarningBanner.
  ///
  /// In pt, this message translates to:
  /// **'Edite apenas erros de digitação. Para mudanças no navio, crie nova avaliação.'**
  String get editWarningBanner;

  /// No description provided for @ratingUpdatedSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Avaliação atualizada com sucesso!'**
  String get ratingUpdatedSuccess;

  /// No description provided for @errorLoadingData.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao carregar dados: {error}'**
  String errorLoadingData(String error);

  /// No description provided for @errorSaving.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao salvar: {error}'**
  String errorSaving(String error);

  /// No description provided for @shipNameRequired.
  ///
  /// In pt, this message translates to:
  /// **'Nome do navio *'**
  String get shipNameRequired;

  /// No description provided for @disembarkationDateRequired.
  ///
  /// In pt, this message translates to:
  /// **'Data de desembarque *'**
  String get disembarkationDateRequired;

  /// No description provided for @cabinTypeRequired.
  ///
  /// In pt, this message translates to:
  /// **'Tipo da cabine *'**
  String get cabinTypeRequired;

  /// No description provided for @myRatingsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Minhas Avaliações'**
  String get myRatingsTitle;

  /// No description provided for @loadingRatings.
  ///
  /// In pt, this message translates to:
  /// **'Carregando suas avaliações...'**
  String get loadingRatings;

  /// No description provided for @tryAgain.
  ///
  /// In pt, this message translates to:
  /// **'Tentar Novamente'**
  String get tryAgain;

  /// No description provided for @noRatingsYet.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma avaliação ainda'**
  String get noRatingsYet;

  /// No description provided for @noRatingsSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Você ainda não avaliou nenhum navio.\nComece avaliando sua próxima viagem!'**
  String get noRatingsSubtitle;

  /// No description provided for @totalRatings.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{Total: 1 avaliação} other{Total: {count} avaliações}}'**
  String totalRatings(int count);

  /// No description provided for @newestFirst.
  ///
  /// In pt, this message translates to:
  /// **'Mais recentes primeiro'**
  String get newestFirst;

  /// No description provided for @averageScore.
  ///
  /// In pt, this message translates to:
  /// **'Nota Média'**
  String get averageScore;

  /// No description provided for @ratingDate.
  ///
  /// In pt, this message translates to:
  /// **'Data de Avaliação'**
  String get ratingDate;

  /// No description provided for @deleteLabel.
  ///
  /// In pt, this message translates to:
  /// **'Excluir'**
  String get deleteLabel;

  /// No description provided for @editLabel.
  ///
  /// In pt, this message translates to:
  /// **'Editar'**
  String get editLabel;

  /// No description provided for @ratingDeletedSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Avaliação excluída com sucesso!'**
  String get ratingDeletedSuccess;

  /// No description provided for @errorDeleting.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao excluir: {error}'**
  String errorDeleting(String error);

  /// No description provided for @pdfGeneratedSuccess.
  ///
  /// In pt, this message translates to:
  /// **'PDF gerado com sucesso!'**
  String get pdfGeneratedSuccess;

  /// No description provided for @errorGeneratingPdf.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao gerar PDF: {error}'**
  String errorGeneratingPdf(String error);

  /// No description provided for @editWarningTitle.
  ///
  /// In pt, this message translates to:
  /// **'Atenção'**
  String get editWarningTitle;

  /// No description provided for @editWarningCorrectionsOnly.
  ///
  /// In pt, this message translates to:
  /// **'Edite apenas para corrigir erros'**
  String get editWarningCorrectionsOnly;

  /// No description provided for @editWarningDescription.
  ///
  /// In pt, this message translates to:
  /// **'Esta função serve para corrigir erros de digitação ou informações incorretas.'**
  String get editWarningDescription;

  /// No description provided for @editWarningImportant.
  ///
  /// In pt, this message translates to:
  /// **'Importante: Use apenas para correções, não para atualizar mudanças no navio ao longo do tempo.'**
  String get editWarningImportant;

  /// No description provided for @editWarningNewRating.
  ///
  /// In pt, this message translates to:
  /// **'Se o navio mudou de condição desde sua última avaliação, crie uma NOVA avaliação em vez de editar esta.'**
  String get editWarningNewRating;

  /// No description provided for @editWarningHistory.
  ///
  /// In pt, this message translates to:
  /// **'Manter histórico ajuda outros práticos!'**
  String get editWarningHistory;

  /// No description provided for @editWarningConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Entendi, quero editar'**
  String get editWarningConfirm;

  /// No description provided for @deleteRatingTitle.
  ///
  /// In pt, this message translates to:
  /// **'Excluir Avaliação'**
  String get deleteRatingTitle;

  /// No description provided for @deleteRatingConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Tem certeza que deseja excluir a avaliação do navio \"{shipName}\"?'**
  String deleteRatingConfirm(String shipName);

  /// No description provided for @deleteWarning.
  ///
  /// In pt, this message translates to:
  /// **'Esta ação não pode ser desfeita!'**
  String get deleteWarning;

  /// No description provided for @deleteButton.
  ///
  /// In pt, this message translates to:
  /// **'Excluir'**
  String get deleteButton;

  /// No description provided for @ratingDetailTitle.
  ///
  /// In pt, this message translates to:
  /// **'Detalhes da Avaliação'**
  String get ratingDetailTitle;

  /// No description provided for @exportPdf.
  ///
  /// In pt, this message translates to:
  /// **'Exportar PDF'**
  String get exportPdf;

  /// No description provided for @errorLoadingShipData.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao carregar dados do navio'**
  String get errorLoadingShipData;

  /// No description provided for @defaultShipName.
  ///
  /// In pt, this message translates to:
  /// **'Navio'**
  String get defaultShipName;

  /// No description provided for @ratedOn.
  ///
  /// In pt, this message translates to:
  /// **'Avaliado em: {date}'**
  String ratedOn(String date);

  /// No description provided for @disembarkationDateValue.
  ///
  /// In pt, this message translates to:
  /// **'Data de desembarque: {date}'**
  String disembarkationDateValue(String date);

  /// No description provided for @cabinTypeValue.
  ///
  /// In pt, this message translates to:
  /// **'Tipo da cabine: {type}'**
  String cabinTypeValue(String type);

  /// No description provided for @cabinDeckValue.
  ///
  /// In pt, this message translates to:
  /// **'Deck da cabine: {deck}'**
  String cabinDeckValue(String deck);

  /// No description provided for @imoValue.
  ///
  /// In pt, this message translates to:
  /// **'IMO: {imo}'**
  String imoValue(String imo);

  /// No description provided for @shipInfo.
  ///
  /// In pt, this message translates to:
  /// **'Informações do Navio'**
  String get shipInfo;

  /// No description provided for @generalObservations.
  ///
  /// In pt, this message translates to:
  /// **'Observações Gerais'**
  String get generalObservations;

  /// No description provided for @cabinSection.
  ///
  /// In pt, this message translates to:
  /// **'Cabine'**
  String get cabinSection;

  /// No description provided for @bridgeSection.
  ///
  /// In pt, this message translates to:
  /// **'Passadiço'**
  String get bridgeSection;

  /// No description provided for @otherSection.
  ///
  /// In pt, this message translates to:
  /// **'Outros'**
  String get otherSection;

  /// No description provided for @scoreLabel.
  ///
  /// In pt, this message translates to:
  /// **'Nota: {score}'**
  String scoreLabel(String score);

  /// No description provided for @anonymous.
  ///
  /// In pt, this message translates to:
  /// **'Anônimo'**
  String get anonymous;

  /// No description provided for @notAvailable.
  ///
  /// In pt, this message translates to:
  /// **'N/A'**
  String get notAvailable;

  /// No description provided for @criteriaCabinTemp.
  ///
  /// In pt, this message translates to:
  /// **'Temperatura da Cabine'**
  String get criteriaCabinTemp;

  /// No description provided for @criteriaCabinCleanliness.
  ///
  /// In pt, this message translates to:
  /// **'Limpeza da Cabine'**
  String get criteriaCabinCleanliness;

  /// No description provided for @criteriaBridgeEquipment.
  ///
  /// In pt, this message translates to:
  /// **'Passadiço - Equipamentos'**
  String get criteriaBridgeEquipment;

  /// No description provided for @criteriaBridgeTemp.
  ///
  /// In pt, this message translates to:
  /// **'Passadiço - Temperatura'**
  String get criteriaBridgeTemp;

  /// No description provided for @criteriaDevice.
  ///
  /// In pt, this message translates to:
  /// **'Dispositivo de Embarque/Desembarque'**
  String get criteriaDevice;

  /// No description provided for @criteriaFood.
  ///
  /// In pt, this message translates to:
  /// **'Comida'**
  String get criteriaFood;

  /// No description provided for @criteriaRelationship.
  ///
  /// In pt, this message translates to:
  /// **'Relacionamento com comandante/tripulação'**
  String get criteriaRelationship;

  /// No description provided for @sendSuggestionTitle.
  ///
  /// In pt, this message translates to:
  /// **'Enviar Sugestão'**
  String get sendSuggestionTitle;

  /// No description provided for @yourOpinionMatters.
  ///
  /// In pt, this message translates to:
  /// **'Sua opinião é importante'**
  String get yourOpinionMatters;

  /// No description provided for @helpImproveApp.
  ///
  /// In pt, this message translates to:
  /// **'Ajude a melhorar o ShipRate com sugestões e ideias.'**
  String get helpImproveApp;

  /// No description provided for @suggestionType.
  ///
  /// In pt, this message translates to:
  /// **'Sugestão'**
  String get suggestionType;

  /// No description provided for @complaintType.
  ///
  /// In pt, this message translates to:
  /// **'Crítica'**
  String get complaintType;

  /// No description provided for @complimentType.
  ///
  /// In pt, this message translates to:
  /// **'Elogio'**
  String get complimentType;

  /// No description provided for @messageLabel.
  ///
  /// In pt, this message translates to:
  /// **'Mensagem'**
  String get messageLabel;

  /// No description provided for @sendButton.
  ///
  /// In pt, this message translates to:
  /// **'Enviar'**
  String get sendButton;

  /// No description provided for @messageSentSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Mensagem enviada com sucesso!'**
  String get messageSentSuccess;

  /// No description provided for @errorSendingMessage.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao enviar mensagem.'**
  String get errorSendingMessage;

  /// No description provided for @dashboardAppStats.
  ///
  /// In pt, this message translates to:
  /// **'ShipRate em números'**
  String get dashboardAppStats;

  /// No description provided for @dashboardYourActivity.
  ///
  /// In pt, this message translates to:
  /// **'Sua Atividade'**
  String get dashboardYourActivity;

  /// No description provided for @totalShipsLabel.
  ///
  /// In pt, this message translates to:
  /// **'Navios'**
  String get totalShipsLabel;

  /// No description provided for @totalRatingsLabel.
  ///
  /// In pt, this message translates to:
  /// **'Avaliações'**
  String get totalRatingsLabel;

  /// No description provided for @yourRatingsLabel.
  ///
  /// In pt, this message translates to:
  /// **'Suas Avaliações'**
  String get yourRatingsLabel;

  /// No description provided for @yourContribution.
  ///
  /// In pt, this message translates to:
  /// **'Sua Contribuição'**
  String get yourContribution;

  /// No description provided for @contributionProgress.
  ///
  /// In pt, this message translates to:
  /// **'{percent}% das avaliações'**
  String contributionProgress(String percent);

  /// No description provided for @contributionSummary.
  ///
  /// In pt, this message translates to:
  /// **'Você avaliou {userCount} de {totalCount}'**
  String contributionSummary(String userCount, String totalCount);

  /// No description provided for @recentActivity.
  ///
  /// In pt, this message translates to:
  /// **'Atividade Recente'**
  String get recentActivity;

  /// No description provided for @noRecentActivity.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma atividade recente'**
  String get noRecentActivity;

  /// No description provided for @pdfReportTitle.
  ///
  /// In pt, this message translates to:
  /// **'Relatório de Avaliação de Navio'**
  String get pdfReportTitle;

  /// No description provided for @pdfEvaluationInfo.
  ///
  /// In pt, this message translates to:
  /// **'Informações da Avaliação'**
  String get pdfEvaluationInfo;

  /// No description provided for @pdfEvaluator.
  ///
  /// In pt, this message translates to:
  /// **'Prático Avaliador'**
  String get pdfEvaluator;

  /// No description provided for @pdfEvaluationDate.
  ///
  /// In pt, this message translates to:
  /// **'Data da Avaliação'**
  String get pdfEvaluationDate;

  /// No description provided for @pdfCabinType.
  ///
  /// In pt, this message translates to:
  /// **'Tipo de Cabine'**
  String get pdfCabinType;

  /// No description provided for @pdfDisembarkationDate.
  ///
  /// In pt, this message translates to:
  /// **'Data de Desembarque'**
  String get pdfDisembarkationDate;

  /// No description provided for @pdfOverallAverage.
  ///
  /// In pt, this message translates to:
  /// **'Nota Média Geral'**
  String get pdfOverallAverage;

  /// No description provided for @pdfCrewNationality.
  ///
  /// In pt, this message translates to:
  /// **'Nacionalidade da Tripulação'**
  String get pdfCrewNationality;

  /// No description provided for @pdfCabinCount.
  ///
  /// In pt, this message translates to:
  /// **'Quantidade de Cabines'**
  String get pdfCabinCount;

  /// No description provided for @pdfRatingsByCriteria.
  ///
  /// In pt, this message translates to:
  /// **'Avaliações por Critério'**
  String get pdfRatingsByCriteria;

  /// No description provided for @pdfGeneralObservation.
  ///
  /// In pt, this message translates to:
  /// **'Observação Geral'**
  String get pdfGeneralObservation;

  /// No description provided for @pdfGeneratedBy.
  ///
  /// In pt, this message translates to:
  /// **'Gerado por ShipRate'**
  String get pdfGeneratedBy;

  /// No description provided for @pdfDateLabel.
  ///
  /// In pt, this message translates to:
  /// **'Data'**
  String get pdfDateLabel;

  /// No description provided for @ratingSavedSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Avaliação salva com sucesso!'**
  String get ratingSavedSuccess;

  /// No description provided for @rateThisShip.
  ///
  /// In pt, this message translates to:
  /// **'Avaliar este Navio'**
  String get rateThisShip;

  /// No description provided for @welcomePilot.
  ///
  /// In pt, this message translates to:
  /// **'Bem-vindo, {name}'**
  String welcomePilot(String name);

  /// No description provided for @selectModule.
  ///
  /// In pt, this message translates to:
  /// **'Selecione o módulo'**
  String get selectModule;

  /// No description provided for @shipRatingModule.
  ///
  /// In pt, this message translates to:
  /// **'Avaliação de Navios'**
  String get shipRatingModule;

  /// No description provided for @shipRatingDesc.
  ///
  /// In pt, this message translates to:
  /// **'Avalie navios e compartilhe experiências'**
  String get shipRatingDesc;

  /// No description provided for @navSafetyModule.
  ///
  /// In pt, this message translates to:
  /// **'Segurança da Navegação'**
  String get navSafetyModule;

  /// No description provided for @navSafetyDesc.
  ///
  /// In pt, this message translates to:
  /// **'Profundidades, calado e condições dos trechos'**
  String get navSafetyDesc;

  /// No description provided for @latestDepths.
  ///
  /// In pt, this message translates to:
  /// **'Últimas Profundidades'**
  String get latestDepths;

  /// No description provided for @locations.
  ///
  /// In pt, this message translates to:
  /// **'Locais'**
  String get locations;

  /// No description provided for @newRecord.
  ///
  /// In pt, this message translates to:
  /// **'Novo Registro'**
  String get newRecord;

  /// No description provided for @latestDepthsRegistered.
  ///
  /// In pt, this message translates to:
  /// **'Últimas profundidades registradas'**
  String get latestDepthsRegistered;

  /// No description provided for @noRecords.
  ///
  /// In pt, this message translates to:
  /// **'Sem registros'**
  String get noRecords;

  /// No description provided for @lastDepth.
  ///
  /// In pt, this message translates to:
  /// **'ÚLTIMA PROFUNDIDADE'**
  String get lastDepth;

  /// No description provided for @history.
  ///
  /// In pt, this message translates to:
  /// **'Histórico'**
  String get history;

  /// No description provided for @back.
  ///
  /// In pt, this message translates to:
  /// **'Voltar'**
  String get back;

  /// No description provided for @totalDepth.
  ///
  /// In pt, this message translates to:
  /// **'PROF. TOTAL'**
  String get totalDepth;

  /// No description provided for @maxDraft.
  ///
  /// In pt, this message translates to:
  /// **'CALADO MÁX.'**
  String get maxDraft;

  /// No description provided for @ukc.
  ///
  /// In pt, this message translates to:
  /// **'UKC'**
  String get ukc;

  /// No description provided for @direction.
  ///
  /// In pt, this message translates to:
  /// **'DIREÇÃO'**
  String get direction;

  /// No description provided for @passageData.
  ///
  /// In pt, this message translates to:
  /// **'Dados da Passagem'**
  String get passageData;

  /// No description provided for @selectLocation.
  ///
  /// In pt, this message translates to:
  /// **'Selecionar local'**
  String get selectLocation;

  /// No description provided for @addNewLocation.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar novo local'**
  String get addNewLocation;

  /// No description provided for @newLocationName.
  ///
  /// In pt, this message translates to:
  /// **'Nome do novo local'**
  String get newLocationName;

  /// No description provided for @anchoragePt.
  ///
  /// In pt, this message translates to:
  /// **'Ponto (1-15)'**
  String get anchoragePt;

  /// No description provided for @shipNameOptional.
  ///
  /// In pt, this message translates to:
  /// **'Nome do navio (opcional)'**
  String get shipNameOptional;

  /// No description provided for @passageDate.
  ///
  /// In pt, this message translates to:
  /// **'Data da passagem'**
  String get passageDate;

  /// No description provided for @goingUp.
  ///
  /// In pt, this message translates to:
  /// **'Subindo'**
  String get goingUp;

  /// No description provided for @goingDown.
  ///
  /// In pt, this message translates to:
  /// **'Baixando'**
  String get goingDown;

  /// No description provided for @totalDepthLabel.
  ///
  /// In pt, this message translates to:
  /// **'PROFUNDIDADE TOTAL'**
  String get totalDepthLabel;

  /// No description provided for @complementaryData.
  ///
  /// In pt, this message translates to:
  /// **'Dados Complementares'**
  String get complementaryData;

  /// No description provided for @maxDraftInput.
  ///
  /// In pt, this message translates to:
  /// **'Calado Máximo (m)'**
  String get maxDraftInput;

  /// No description provided for @ukcInput.
  ///
  /// In pt, this message translates to:
  /// **'UKC (m)'**
  String get ukcInput;

  /// No description provided for @speedOptional.
  ///
  /// In pt, this message translates to:
  /// **'Velocidade (nós)'**
  String get speedOptional;

  /// No description provided for @optional.
  ///
  /// In pt, this message translates to:
  /// **'opcional'**
  String get optional;

  /// No description provided for @squatConsidered.
  ///
  /// In pt, this message translates to:
  /// **'Squat considerado?'**
  String get squatConsidered;

  /// No description provided for @sonarPosition.
  ///
  /// In pt, this message translates to:
  /// **'Posição da Sonda'**
  String get sonarPosition;

  /// No description provided for @bow.
  ///
  /// In pt, this message translates to:
  /// **'Proa'**
  String get bow;

  /// No description provided for @stern.
  ///
  /// In pt, this message translates to:
  /// **'Popa'**
  String get stern;

  /// No description provided for @positionLatLong.
  ///
  /// In pt, this message translates to:
  /// **'Posição (LAT/LONG)'**
  String get positionLatLong;

  /// No description provided for @observations.
  ///
  /// In pt, this message translates to:
  /// **'Observações / Referências'**
  String get observations;

  /// No description provided for @additionalInfo.
  ///
  /// In pt, this message translates to:
  /// **'Informações adicionais...'**
  String get additionalInfo;

  /// No description provided for @registerPassage.
  ///
  /// In pt, this message translates to:
  /// **'Registrar Passagem'**
  String get registerPassage;

  /// No description provided for @recordSavedSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Registro salvo com sucesso!'**
  String get recordSavedSuccess;

  /// No description provided for @locationRequired.
  ///
  /// In pt, this message translates to:
  /// **'Selecione um local'**
  String get locationRequired;

  /// No description provided for @depthRequired.
  ///
  /// In pt, this message translates to:
  /// **'Informe a profundidade total'**
  String get depthRequired;

  /// No description provided for @draftRequired.
  ///
  /// In pt, this message translates to:
  /// **'Informe o calado máximo'**
  String get draftRequired;

  /// No description provided for @ukcRequired.
  ///
  /// In pt, this message translates to:
  /// **'Informe o UKC'**
  String get ukcRequired;

  /// No description provided for @directionRequired.
  ///
  /// In pt, this message translates to:
  /// **'Selecione a direção'**
  String get directionRequired;

  /// No description provided for @sonarRequired.
  ///
  /// In pt, this message translates to:
  /// **'Selecione a posição da sonda'**
  String get sonarRequired;
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
