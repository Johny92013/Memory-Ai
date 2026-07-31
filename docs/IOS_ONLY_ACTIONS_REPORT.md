# iOS-only GitHub Actions – Bericht

## Ergebnis der Umstellung

| Punkt | Wert |
|---|---|
| Workflow-Datei | `.github/workflows/release.yml` |
| macOS-Runner | `macos-15` |
| Flutter-Version | `3.44.1` (lokal bestätigt; kein FVM) |
| iOS Bundle Identifier | `com.johny92013.memoryai` |
| Apple Team ID vorhanden | unbekannt (Secret `IOS_TEAM_ID` erforderlich) |
| DOTENV_FILE vorhanden | erforderlich / Status in GitHub unbekannt |
| Android-Job entfernt | Ja |
| Alter Workflow | `ios-ipa.yml` → `ios-ipa.yml.deprecated` |
| iOS-Workflow gepusht | (nach Push prüfen) |
| Workflow gestartet | Nein |
| IPA erzeugt | Nein (kein CI-Lauf; Platzhalter-Bundle-ID blockiert produktiv) |
| IPA-Speicherort (bei Erfolg) | Artifact `memory-ai-1.0.0-ios-ipa` → `build/ios/ipa/*.ipa` |

## Lokale Kontrolle (Windows)

- `flutter analyze`: keine Issues
- `flutter test`: alle Tests bestanden
- `flutter build apk --release`: `build/app/outputs/flutter-apk/app-release.apk` (92.7MB)

## Benötigte iOS-Secrets

- `DOTENV_FILE`
- `IOS_CERTIFICATE_BASE64`
- `IOS_CERTIFICATE_PASSWORD`
- `IOS_PROVISIONING_PROFILE_BASE64`
- `IOS_KEYCHAIN_PASSWORD`
- `IOS_TEAM_ID`
- `IOS_BUNDLE_ID`

## Verbleibende manuelle Schritte

1. Produktive Bundle-ID in Xcode setzen (kein `com.example.*`)
2. `IOS_BUNDLE_ID` und Provisioning Profile darauf abstimmen
3. Secrets unter GitHub → Settings → Secrets and variables → Actions eintragen
4. Actions → **iOS IPA Release** → Run workflow
5. Artifact herunterladen

Hinweis: `flutter build ipa` kennt kein `--release`-Flag (immer Release). Der Workflow nutzt `--build-name` / `--build-number` / `--export-options-plist`. Export-Methode: `app-store-connect`.
