/// Löscht geräte- bzw. nutzerbezogene Gesichtserkennungsdaten.
///
/// Die konkrete Tabelle wird in einem späteren Prompt angelegt.
/// Hier nur das Interface, damit Widerruf der Einwilligung bereits
/// die Löschung auslösen kann.
abstract class FaceRecognitionDataStore {
  /// Löscht alle Gesichtserkennungs-Datensätze des Nutzers [userId].
  Future<void> deleteAllForUser(String userId);
}

/// No-Op-Implementierung, bis die Speichertabelle existiert.
class NoOpFaceRecognitionDataStore implements FaceRecognitionDataStore {
  const NoOpFaceRecognitionDataStore();

  @override
  Future<void> deleteAllForUser(String userId) async {
    // Platzhalter: wird in Prompt 2 durch echte Löschung ersetzt.
  }
}
