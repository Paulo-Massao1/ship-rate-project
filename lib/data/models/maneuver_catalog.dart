import 'package:flutter/widgets.dart';

enum ManeuverCargoType { general, dangerous }

/// Text supplied by an operational source, rather than by the application UI.
class ManeuverLocalizedText {
  const ManeuverLocalizedText({required this.pt, required this.en});

  final String pt;
  final String en;

  String resolve(Locale locale) => locale.languageCode == 'pt' ? pt : en;
}

class ManeuverDraftLimit {
  const ManeuverDraftLimit.single(this.minimum) : maximum = null;

  const ManeuverDraftLimit.range(this.minimum, this.maximum);

  const ManeuverDraftLimit.unavailable() : minimum = null, maximum = null;

  final double? minimum;
  final double? maximum;
}

class ManeuverDraftTableDefinition {
  const ManeuverDraftTableDefinition({
    required this.cargoType,
    required this.dryOptional,
    required this.floodOptional,
    required this.dryMandatory,
    required this.floodMandatory,
  });

  final ManeuverCargoType cargoType;
  final ManeuverDraftLimit dryOptional;
  final ManeuverDraftLimit floodOptional;
  final ManeuverDraftLimit dryMandatory;
  final ManeuverDraftLimit floodMandatory;
}

class ManeuverMooringDefinition {
  const ManeuverMooringDefinition({
    required this.vesselClass,
    required this.lineGroups,
    this.finalPosition,
  });

  final String vesselClass;
  final List<int> lineGroups;
  final ManeuverLocalizedText? finalPosition;
}

class ManeuverOperationalInfo {
  const ManeuverOperationalInfo({
    required this.maximumLengthMeters,
    required this.beamRestriction,
    required this.pierLengthMeters,
    required this.maximumDwtTons,
    required this.airDraftMeters,
    required this.airDraftDetail,
    required this.maximumWindKnots,
    required this.minimumVisibilityMeters,
    required this.scheduleRestriction,
    required this.crossingRestriction,
    required this.berthingSide,
    required this.draftTables,
    required this.draftFootnote,
    required this.vhfChannel,
    required this.launchArrangement,
    required this.simultaneousLines,
    required this.quayAlignmentDegrees,
    required this.tugboatsMandatory,
    required this.tugRequirementDetail,
    required this.tugMinimumNote,
    required this.navigation,
    required this.mooring,
  });

  final double maximumLengthMeters;
  final ManeuverLocalizedText? beamRestriction;
  final double pierLengthMeters;
  final int maximumDwtTons;
  final double airDraftMeters;
  final ManeuverLocalizedText airDraftDetail;
  final double maximumWindKnots;
  final int minimumVisibilityMeters;
  final ManeuverLocalizedText? scheduleRestriction;
  final ManeuverLocalizedText? crossingRestriction;
  final ManeuverLocalizedText berthingSide;
  final List<ManeuverDraftTableDefinition> draftTables;
  final ManeuverLocalizedText draftFootnote;
  final int vhfChannel;
  final ManeuverLocalizedText launchArrangement;
  final int simultaneousLines;
  final int quayAlignmentDegrees;
  final bool tugboatsMandatory;
  final ManeuverLocalizedText tugRequirementDetail;
  final ManeuverLocalizedText tugMinimumNote;
  final ManeuverLocalizedText navigation;
  final List<ManeuverMooringDefinition> mooring;
}

class ManeuverTerminalDefinition {
  const ManeuverTerminalDefinition({
    required this.id,
    required this.name,
    this.operationalInfo,
    this.preparationRequiresPlus = true,
  });

  final String id;
  final String name;
  final ManeuverOperationalInfo? operationalInfo;
  final bool preparationRequiresPlus;

  bool get hasPreparationInfo => operationalInfo != null;
}

class ManeuverPortDefinition {
  const ManeuverPortDefinition({
    required this.name,
    required this.code,
    required this.terminals,
  });

  final String name;
  final String code;
  final List<ManeuverTerminalDefinition> terminals;
}

/// Maneuver terminals available for reports and the phased preparation data.
abstract final class ManeuverCatalog {
  static const ports = <ManeuverPortDefinition>[
    ManeuverPortDefinition(
      name: 'Santana',
      code: 'SAN',
      terminals: [
        ManeuverTerminalDefinition(id: 'san_cdsa_1', name: 'CDSA 1'),
        ManeuverTerminalDefinition(id: 'san_cdsa_2', name: 'CDSA 2'),
      ],
    ),
    ManeuverPortDefinition(
      name: 'Santarém',
      code: 'STM',
      terminals: [
        ManeuverTerminalDefinition(
          id: 'stm_cargill',
          name: 'Cargill',
          operationalInfo: _cargillOperationalInfo,
          preparationRequiresPlus: false,
        ),
        ManeuverTerminalDefinition(id: 'stm_cdp_101', name: 'CDP 101'),
        ManeuverTerminalDefinition(id: 'stm_cdp_201', name: 'CDP 201'),
        ManeuverTerminalDefinition(id: 'stm_atem', name: 'ATEM'),
        ManeuverTerminalDefinition(
          id: 'stm_transbordo_1',
          name: 'Transbordo 1',
        ),
        ManeuverTerminalDefinition(
          id: 'stm_transbordo_2',
          name: 'Transbordo 2',
        ),
      ],
    ),
    ManeuverPortDefinition(
      name: 'Jari',
      code: 'JAR',
      terminals: [
        ManeuverTerminalDefinition(id: 'jar_cadam', name: 'CADAM'),
        ManeuverTerminalDefinition(id: 'jar_jarcel', name: 'JARCEL'),
      ],
    ),
    ManeuverPortDefinition(
      name: 'Juruti',
      code: 'JUR',
      terminals: [ManeuverTerminalDefinition(id: 'jur_alcoa', name: 'ALCOA')],
    ),
    ManeuverPortDefinition(
      name: 'Trombetas',
      code: 'PTR',
      terminals: [
        ManeuverTerminalDefinition(id: 'ptr_mrn', name: 'MRN'),
        ManeuverTerminalDefinition(id: 'ptr_boia_1', name: 'Boia 1'),
        ManeuverTerminalDefinition(id: 'ptr_boia_2', name: 'Boia 2'),
        ManeuverTerminalDefinition(id: 'ptr_boia_3', name: 'Boia 3'),
      ],
    ),
    ManeuverPortDefinition(
      name: 'Itacoatiara',
      code: 'ITA',
      terminals: [
        ManeuverTerminalDefinition(id: 'ita_hermasa_1', name: 'Hermasa 1'),
        ManeuverTerminalDefinition(id: 'ita_hermasa_2', name: 'Hermasa 2'),
        ManeuverTerminalDefinition(id: 'ita_hermasa_3', name: 'Hermasa 3'),
        ManeuverTerminalDefinition(id: 'ita_tfb', name: 'TFB'),
        ManeuverTerminalDefinition(id: 'ita_chibatao', name: 'Chibatão'),
        ManeuverTerminalDefinition(
          id: 'ita_superterminais',
          name: 'Superterminais',
        ),
      ],
    ),
  ];

  static const _cargillOperationalInfo = ManeuverOperationalInfo(
    maximumLengthMeters: 260,
    beamRestriction: null,
    pierLengthMeters: 250,
    maximumDwtTons: 120000,
    airDraftMeters: 90,
    airDraftDetail: ManeuverLocalizedText(
      pt: 'Limitado pela linha de transmissão Almeirim/Jurupari.',
      en: 'Limited by the Almeirim/Jurupari power line.',
    ),
    maximumWindKnots: 15,
    minimumVisibilityMeters: 500,
    scheduleRestriction: null,
    crossingRestriction: null,
    berthingSide: ManeuverLocalizedText(
      pt: 'BB e BE',
      en: 'Port and starboard',
    ),
    draftTables: [
      ManeuverDraftTableDefinition(
        cargoType: ManeuverCargoType.general,
        dryOptional: ManeuverDraftLimit.single(11.55),
        floodOptional: ManeuverDraftLimit.single(11.60),
        dryMandatory: ManeuverDraftLimit.range(11.56, 11.75),
        floodMandatory: ManeuverDraftLimit.range(11.61, 11.90),
      ),
      ManeuverDraftTableDefinition(
        cargoType: ManeuverCargoType.dangerous,
        dryOptional: ManeuverDraftLimit.single(11.55),
        floodOptional: ManeuverDraftLimit.single(11.60),
        dryMandatory: ManeuverDraftLimit.unavailable(),
        floodMandatory: ManeuverDraftLimit.range(11.61, 11.70),
      ),
    ],
    draftFootnote: ManeuverLocalizedText(
      pt:
          'Subtrair 5 cm dos calados conforme Portaria nº 223/Com4ºDN, de 24/04/2026.',
      en:
          'Subtract 5 cm from drafts according to Ordinance No. 223/Com4ºDN, dated 24 Apr 2026.',
    ),
    vhfChannel: 12,
    launchArrangement: ManeuverLocalizedText(
      pt: 'Proa e popa',
      en: 'Bow and stern',
    ),
    simultaneousLines: 2,
    quayAlignmentDegrees: 288,
    tugboatsMandatory: true,
    tugRequirementDetail: ManeuverLocalizedText(
      pt:
          'O uso de rebocadores é obrigatório. Consulte abaixo os rebocadores informados para Santarém.',
      en: 'Tugboat use is mandatory. See below the tugboats listed for Santarém.',
    ),
    tugMinimumNote: ManeuverLocalizedText(
      pt:
          'O documento não especifica quantidade mínima nem BP total mínimo para a Cargill.',
      en:
          'The document does not specify a minimum quantity or total bollard pull for Cargill.',
    ),
    navigation: ManeuverLocalizedText(
      pt:
          'No rio Tapajós, recomenda-se no máximo meia força adiante, sem exceder “devagar adiante”.',
      en:
          'On the Tapajós River, a maximum of half ahead is recommended, without exceeding slow ahead.',
    ),
    mooring: [
      ManeuverMooringDefinition(vesselClass: 'Panamax', lineGroups: [2, 2, 2]),
      ManeuverMooringDefinition(vesselClass: 'Handmax', lineGroups: [4, 2]),
    ],
  );
}
