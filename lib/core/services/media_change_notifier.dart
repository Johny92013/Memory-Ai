import 'package:flutter/foundation.dart';

/// Einfacher App-weiter Signalgeber nach Medien-Metadaten-/Personen-Änderungen.
/// Galerie, Timeline und Filter können darauf hören und neu laden.
class MediaChangeNotifier extends ChangeNotifier {
  MediaChangeNotifier._();

  static final MediaChangeNotifier instance = MediaChangeNotifier._();

  int _revision = 0;
  int get revision => _revision;

  void notifyMediaChanged() {
    _revision++;
    notifyListeners();
  }
}
