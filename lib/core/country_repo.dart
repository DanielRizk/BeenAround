import 'dart:convert';
import 'package:flutter/services.dart';
import 'country.dart';

class CountryRepo {
  static Future<List<Country>> loadCountries(String assetPath) async {
    final raw = await rootBundle.loadString(assetPath);
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    final countries = list.map(Country.fromJson).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return countries;
  }

  static Future<Map<String, String>> loadSvgToIso2(String assetPath) async {
    final raw = await rootBundle.loadString(assetPath);
    final map = (jsonDecode(raw) as Map).cast<String, dynamic>();
    return map.map((k, v) => MapEntry(k, (v as String).toUpperCase()));
  }
}
