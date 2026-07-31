# iOS IPA Build – Memory AI 1.0.0+1

## Status auf diesem Rechner

- OS: **Windows** → lokaler `flutter build ipa` **nicht möglich**
- Kein Xcode, kein CocoaPods-macOS-Host
- Kein Git-Remote / kein laufender CI-Job in dieser Session
- **Es wurde keine IPA-Datei erzeugt.**

## Empfohlener Weg für Sideloadly (Priorität)

Sideloadly kann eine **unsigned IPA** mit deiner Apple-ID neu signieren.

1. Repo auf GitHub pushen (oder Mac nutzen).
2. GitHub Secret setzen: `DOTENV_FILE` = kompletter Inhalt deiner `.env`
3. Actions → Workflow **iOS IPA 1.0.0** → Run workflow → `signed = false`
4. Artifact `MemoryAI-1.0.0-ipa` herunterladen
5. Datei nach `release/1.0.0/` legen und in Sideloadly öffnen

Alternativ auf einem Mac:

```bash
chmod +x tool/build_ios_ipa_macos.sh
./tool/build_ios_ipa_macos.sh
```

Ergebnis: `release/1.0.0/MemoryAI-1.0.0+1-unsigned.ipa`

## Signierte IPA (Apple Developer / Provisioning)

Zusätzlich nötig:

| Secret / Datei | Beschreibung |
|---|---|
| `APPLE_CERTIFICATE_BASE64` | `.p12` Zertifikat, Base64 |
| `APPLE_CERTIFICATE_PASSWORD` | Passwort der `.p12` |
| `APPLE_PROVISIONING_PROFILE_BASE64` | `.mobileprovision`, Base64 |
| `KEYCHAIN_PASSWORD` | beliebiges Keychain-Passwort für den Runner |
| `APPLE_TEAM_ID` | 10-stellige Team-ID |
| `DOTENV_FILE` | `.env`-Inhalt |

In `ios/ExportOptions-*.plist` Platzhalter `YOUR_APPLE_TEAM_ID` ersetzen.

Workflow mit `signed = true` und gewünschter `export_method` starten  
oder auf dem Mac:

```bash
./tool/build_ios_ipa_macos.sh signed development
```

## Codemagic

1. Repo in Codemagic verbinden
2. `codemagic.yaml` wird erkannt
3. Secret `DOTENV_FILE` setzen
4. Workflow `ios-ipa-unsigned-sideloadly` starten
5. Für signed: App Store Connect Integration + Zertifikate in Codemagic hinterlegen, Workflow `ios-ipa-signed`

## Bundle Identifier

Aktuell: `com.johny92013.memoryai`  
Für echte Distribution später ändern; für Sideloadly/lokales Testen oft ok.

## Was fehlt aktuell zum erfolgreichen CI-Build

1. Git-Repository + Remote (z. B. GitHub)
2. Secret `DOTENV_FILE`
3. Workflow manuell starten **oder** Mac mit Xcode
4. Für signierte Builds: Zertifikat + Provisioning Profile + Team-ID

## Angelegte Dateien

- `.github/workflows/ios-ipa.yml`
- `codemagic.yaml`
- `ios/ExportOptions-development.plist`
- `ios/ExportOptions-ad-hoc.plist`
- `ios/ExportOptions-app-store.plist`
- `tool/build_ios_ipa_macos.sh`
- `release/1.0.0/README.md`
