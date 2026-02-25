import 'package:ship_rate/l10n/app_localizations.dart';
import 'pdf_service.dart';

/// Factory for creating [PdfLabels] from [AppLocalizations].
///
/// Centralizes the mapping between l10n keys and PDF labels,
/// avoiding duplication across callers.
PdfLabels buildPdfLabels(AppLocalizations l10n) {
  return PdfLabels(
    reportTitle: l10n.pdfReportTitle,
    evaluationInfo: l10n.pdfEvaluationInfo,
    evaluator: l10n.pdfEvaluator,
    evaluationDate: l10n.pdfEvaluationDate,
    cabinType: l10n.pdfCabinType,
    disembarkationDate: l10n.pdfDisembarkationDate,
    overallAverage: l10n.pdfOverallAverage,
    shipInfo: l10n.shipInfo,
    crewNationality: l10n.pdfCrewNationality,
    cabinCount: l10n.pdfCabinCount,
    cabinCountOne: l10n.cabinCountOne,
    cabinCountTwo: l10n.cabinCountTwo,
    cabinCountMoreThanTwo: l10n.cabinCountMoreThanTwo,
    minibar: l10n.minibar,
    sink: l10n.sink,
    microwave: l10n.microwave,
    cabinDeck: l10n.cabinDeck,
    deckLabels: {
      'bridge': l10n.deckBridge,
      '1_below': l10n.deck1Below,
      '2_below': l10n.deck2Below,
      '3_below': l10n.deck3Below,
      '4+_below': l10n.deck4PlusBelow,
    },
    notAvailable: l10n.notAvailable,
    ratingsByCriteria: l10n.pdfRatingsByCriteria,
    generalObservation: l10n.pdfGeneralObservation,
    generatedBy: l10n.pdfGeneratedBy,
    dateLabel: l10n.pdfDateLabel,
    yes: l10n.yes,
    no: l10n.no,
    criteriaLabels: {
      'Temperatura da Cabine': l10n.criteriaCabinTemp,
      'Limpeza da Cabine': l10n.criteriaCabinCleanliness,
      'Passadiço \u2013 Equipamentos': l10n.criteriaBridgeEquipment,
      'Passadiço \u2013 Temperatura': l10n.criteriaBridgeTemp,
      'Dispositivo de Embarque/Desembarque': l10n.criteriaDevice,
      'Comida': l10n.criteriaFood,
      'Relacionamento com comandante/tripulação': l10n.criteriaRelationship,
    },
    nationalityLabels: {
      'Filipino': l10n.nationalityFilipino,
      'Russian': l10n.nationalityRussian,
      'Ukrainian': l10n.nationalityUkrainian,
      'Indian': l10n.nationalityIndian,
      'Chinese': l10n.nationalityChinese,
      'Brazilian': l10n.nationalityBrazilian,
    },
  );
}
