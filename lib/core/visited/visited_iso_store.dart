import 'package:flutter/foundation.dart';

class VisitedIsoStore extends ChangeNotifier {
  final Set<String> _visitedIso2 = {};

  Set<String> get visited => Set.unmodifiable(_visitedIso2);

  bool isVisited(String iso2) => _visitedIso2.contains(iso2);

  void setVisited(String iso2, bool value) {
    final u = iso2.toUpperCase();
    final changed = value ? _visitedIso2.add(u) : _visitedIso2.remove(u);
    if (changed) notifyListeners();
  }
}
