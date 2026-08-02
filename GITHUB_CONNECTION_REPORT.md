# GitHub Connection Audit – Memory-AI

Datum: 2026-07-31

## 1. Audit

| Prüfung | Ergebnis |
|---|---|
| Git installiert | Ja (`git version 2.54.0.windows.1`) |
| Lokales Git-Repo | Ja |
| Branch | `main` |
| Commits | `8b371ef` Initial release setup 1.0.0, `48fffb0` GitHub Actions Release Setup |
| Remote `origin` | `https://github.com/Johny92013/Memory-Ai.git` |
| Repo erreichbar / Push | Ja – `main` erfolgreich gepusht |
| GitHub CLI (`gh`) | Nicht installiert |
| Workflows | `.github/workflows/release.yml`, `.github/workflows/ios-ipa.yml` |
| `.gitignore` Secrets | `.env`, Keystores, `key.properties`, `.p12`, Profiles ausgeschlossen |
| Secrets im Commit | Nein |

## 2. App Identifier (nicht geändert)

| Plattform | Aktueller Wert | Vorschlag produktiv |
|---|---|---|
| Android `applicationId` | `com.johny92013.memoryai` | — |
| iOS Bundle ID | `com.johny92013.memoryai` | — |

Platzhalter belassen (laut Auftrag nicht automatisch ändern). Vor Store-Release vereinheitlichen.

## 3. Lokale Builds

| Schritt | Ergebnis |
|---|---|
| `flutter clean` / `pub get` | ok |
| `flutter analyze` | No issues |
| `flutter test` | 141 passed |
| `flutter build apk --release` | ok → `build/app/outputs/flutter-apk/app-release.apk` (~92,7 MB) |

## 4. Fehlende GitHub Secrets (nur Liste)

- `DOTENV_FILE`
- `ANDROID_KEYSTORE_BASE64`
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`
- `IOS_CERTIFICATE_BASE64`
- `IOS_CERTIFICATE_PASSWORD`
- `IOS_PROVISIONING_PROFILE_BASE64`
- `IOS_KEYCHAIN_PASSWORD`
- `IOS_TEAM_ID`
- `IOS_BUNDLE_ID`

## 5. Links

- Repository: https://github.com/Johny92013/Memory-Ai
- Actions: https://github.com/Johny92013/Memory-Ai/actions
- Secrets: https://github.com/Johny92013/Memory-Ai/settings/secrets/actions
- Workflow-Datei: `.github/workflows/release.yml`
