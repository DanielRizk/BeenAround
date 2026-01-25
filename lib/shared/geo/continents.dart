const Map<String, String> iso2ToContinent = {
  'DE': 'Europe',
  'FR': 'Europe',
  'IT': 'Europe',
  'US': 'North America',
  'CA': 'North America',
  'BR': 'South America',
  'AR': 'South America',
  'EG': 'Africa',
  'ZA': 'Africa',
  'CN': 'Asia',
  'JP': 'Asia',
  'AU': 'Oceania',
};

Map<String, List<String>> groupCountriesByContinent(
    Iterable<String> iso2s,
    Map<String, String> iso2ToContinent,
    ) {
  final out = <String, List<String>>{};
  for (final iso in iso2s) {
    final c = iso2ToContinent[iso.toUpperCase()] ?? 'Other';
    out.putIfAbsent(c, () => []).add(iso);
  }
  return out;
}

