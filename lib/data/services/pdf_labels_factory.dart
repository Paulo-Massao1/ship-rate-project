import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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
    minibar: l10n.minibar,
    sink: l10n.sink,
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
      'Passadiço – Equipamentos': l10n.criteriaBridgeEquipment,
      'Passadiço – Temperatura': l10n.criteriaBridgeTemp,
      'Dispositivo de Embarque/Desembarque': l10n.criteriaDevice,
      'Comida': l10n.criteriaFood,
      'Relacionamento com comandante/tripulação': l10n.criteriaRelationship,
    },
  );
}
