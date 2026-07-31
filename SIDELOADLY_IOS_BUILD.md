# Unsignierte iOS-IPA mit Sideloadly installieren

Dieser Guide beschreibt, wie du die **unsignierte** Memory-AI-IPA von GitHub Actions herunterlädst und mit **Sideloadly** plus kostenloser Apple-ID auf deinem eigenen iPhone installierst.

Die IPA ist **nicht** für App Store oder TestFlight gedacht. Sideloadly übernimmt die Signierung.

## Voraussetzungen

- Windows-PC
- [Sideloadly](https://sideloadly.io/) installiert
- kostenlose Apple-ID
- iPhone per USB
- GitHub-Secret `DOTENV_FILE` im Repository gesetzt (die App braucht `.env` als Asset)

## Schritte

1. GitHub öffnen: https://github.com/
2. Repository **Memory-Ai** öffnen: https://github.com/Johny92013/Memory-Ai
3. **Actions** anklicken
4. Workflow **iOS Unsigned IPA for Sideloadly** auswählen
5. **Run workflow** anklicken (Branch `main`)
6. Build abwarten (macOS-Runner, ca. mehrere Minuten)
7. Nach Erfolg Artifact **memory-ai-1.0.0-unsigned-ipa-sideloadly** herunterladen
8. ZIP-Artefakt entpacken
9. Die darin enthaltene Datei `Memory-AI-1.0.0-unsigned.ipa` auswählen
10. Sideloadly unter Windows öffnen
11. iPhone per USB anschließen
12. Apple-ID in Sideloadly eintragen
13. IPA in Sideloadly ziehen
14. **Start** anklicken
15. Gegebenenfalls Apple-ID-Bestätigung (2FA / App-spezifisches Passwort) durchführen
16. Auf dem iPhone unter **Einstellungen → Allgemein → VPN & Geräteverwaltung** der Entwickler-App vertrauen
17. **Entwicklermodus** aktivieren, falls iOS dies verlangt
18. App starten

## Wichtige Hinweise

- Kostenlose Apple-ID-Signierung ist normalerweise **7 Tage** gültig.
- Danach muss die App erneut signiert/installiert werden.
- App-Daten können bei einer normalen Aktualisierung erhalten bleiben, sollten aber vorher gesichert werden.
- Kostenlose Apple-Konten haben Begrenzungen bei Apps und Geräten.
- Keine App-Store- oder TestFlight-Nutzung möglich.
- Bundle-IDs wie `com.example.*` sind für Sideloading oft akzeptabel; Sideloadly kann neu signieren. Die App ist dadurch **nicht** App-Store-fertig.

## Technischer Hintergrund (GitHub Actions)

- Workflow: `.github/workflows/release.yml`
- Build: `flutter build ios --release --no-codesign`
- IPA-Struktur: `Payload/Runner.app/`
- Keine Apple-Zertifikate, kein Provisioning Profile, kein Distribution Signing
- Android wird **nicht** in GitHub Actions gebaut

## Secret

| Secret | Pflicht | Zweck |
|---|---|---|
| `DOTENV_FILE` | Ja | Inhalt der `.env` (Supabase-URL/Key); nie im Log ausgeben |
