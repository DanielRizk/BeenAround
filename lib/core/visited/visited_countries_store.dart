import 'package:flutter/foundation.dart';

class VisitedCountriesStore extends ChangeNotifier {
  final Set<String> _visited = <String>{};

  Set<String> get visited => Set.unmodifiable(_visited);

  bool isVisited(String countryCode) => _visited.contains(countryCode);

  void setVisited(String countryCode, bool value) {
    final changed = value ? _visited.add(countryCode) : _visited.remove(countryCode);
    if (changed) notifyListeners();
  }

  void toggle(String countryCode) {
    if (_visited.contains(countryCode)) {
      _visited.remove(countryCode);
    } else {
      _visited.add(countryCode);
    }
    notifyListeners();
  }
}
