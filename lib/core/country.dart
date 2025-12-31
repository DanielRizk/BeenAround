class Country {
  final String iso2;
  final String name;

  const Country({required this.iso2, required this.name});

  factory Country.fromJson(Map<String, dynamic> j) {
    return Country(
      iso2: (j['iso2'] as String).toUpperCase(),
      name: j['name'] as String,
    );
  }
}
