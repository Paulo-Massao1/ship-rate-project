import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:ship_rate/data/models/tide_entry.dart';

class TideDataService {
  TideDataService._();

  static const Map<String, String> _assetPaths = {
    'santana': 'assets/tide_data/santana.json',
    'arco_lamoso': 'assets/tide_data/arco_lamoso.json',
    'pem15': 'assets/tide_data/pem15.json',
    'curua': 'assets/tide_data/curua.json',
    'breves': 'assets/tide_data/breves.json',
  };

  static final Map<String, TideLocation> _cache = {};

  static Future<TideLocation> getLocation(String location) async {
    final cached = _cache[location];
    if (cached != null) return cached;

    final assetPath = _assetPaths[location];
    if (assetPath == null) {
      throw ArgumentError.value(location, 'location', 'Unknown tide location');
    }

    final rawJson = await rootBundle.loadString(assetPath);
    final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
    final tideLocation = TideLocation.fromJson(decoded);
    _cache[location] = tideLocation;
    return tideLocation;
  }

  static Future<List<TideDay>> getTides(String location, DateTime date) async {
    final tideLocation = await getLocation(location);
    final selectedDate = DateTime(date.year, date.month, date.day);

    return List.generate(5, (index) {
      final day = selectedDate.add(Duration(days: index - 1));
      return TideDay(
        date: day,
        entries: tideLocation.entriesForDate(day),
      );
    }, growable: false);
  }
}
