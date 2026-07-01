class TideEntry {
  final String time;
  final double height;
  final String type;

  const TideEntry({
    required this.time,
    required this.height,
    required this.type,
  });

  bool get isHighTide => type == 'preamar';

  factory TideEntry.fromJson(Map<String, dynamic> json) {
    final rawHeight = json['height'];

    return TideEntry(
      time: json['time'] as String,
      height: rawHeight is num
          ? rawHeight.toDouble()
          : double.parse(rawHeight.toString()),
      type: json['type'] as String,
    );
  }
}

class TideDay {
  final DateTime date;
  final List<TideEntry> entries;

  const TideDay({
    required this.date,
    required this.entries,
  });
}

class TideLocation {
  final String name;
  final String latitude;
  final String longitude;
  final String timezone;
  final double meanLevel;
  final Map<DateTime, List<TideEntry>> data;

  const TideLocation({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.timezone,
    required this.meanLevel,
    required this.data,
  });

  factory TideLocation.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'] as Map<String, dynamic>;
    final parsedData = <DateTime, List<TideEntry>>{};

    for (final entry in rawData.entries) {
      final date = DateTime.parse(entry.key);
      final tides = (entry.value as List<dynamic>)
          .map((item) => TideEntry.fromJson(item as Map<String, dynamic>))
          .toList(growable: false);
      parsedData[DateTime(date.year, date.month, date.day)] = tides;
    }

    final rawMeanLevel = json['meanLevel'];

    return TideLocation(
      name: json['location'] as String,
      latitude: json['latitude'] as String,
      longitude: json['longitude'] as String,
      timezone: json['timezone'] as String,
      meanLevel: rawMeanLevel is num
          ? rawMeanLevel.toDouble()
          : double.parse(rawMeanLevel.toString()),
      data: Map.unmodifiable(parsedData),
    );
  }

  List<TideEntry> entriesForDate(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return data[normalized] ?? const [];
  }
}
