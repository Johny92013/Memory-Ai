# GitHub Release Build Report – Memory AI

Stand der Einrichtung (lokal unter Windows). **Keine CI-Artefakte wurden in dieser Session erzeugt.**

## Audit (Kurz)

| Punkt | Ergebnis |
|---|---|
| Flutter | 3.44.1 stable |
| Dart | 3.12.1 |
| `pubspec.yaml` version | `1.0.0+1` |
| Android applicationId | `com.johny92013.memoryai` |
| iOS Bundle ID | `com.johny92013.memoryai` |
| Flavors | keine |
| FVM | nicht verwendet |
| Firebase | nicht verwendet |
| Supabase | via `.env` (`SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY`) |
| Info.plist Permissions | Camera, Photo Library, Photo Add, Location When In Use |
| `ios/Podfile` | fehlte → **neu angelegt** |
| Git | **kein** `.git` / kein GitHub-Remote |
| `gh` CLI | nicht verfügbar / nicht angemeldet |
| Vorhandener Workflow | `.github/workflows/ios-ipa.yml` (älter, belassen) |
| Android Signing lokal | `android/key.properties` + lokaler Test-Keystore (gitignored) |
| iOS Signing lokal | kein Team / keine Profiles im Repo |

## Berichtstabelle

1. **Projektname:** Memory AI (`memory_ai`)  
2. **Version:** 1.0.0  
3. **Build-Nummer:** 1  
4. **GitHub Repository:** *nicht verbunden*  
5. **Workflow-Datei:** `.github/workflows/release.yml`  
6. **Android Job eingerichtet:** Ja  
7. **iOS Job eingerichtet:** Ja  
8. **APK-Build eingerichtet:** Ja  
9. **AAB-Build eingerichtet:** Ja  
10. **IPA-Build eingerichtet:** Ja  
11. **Android Signing vollständig:** Nein (Secrets müssen in GitHub hinterlegt werden)  
12. **iOS Signing vollständig:** Nein (Secrets müssen in GitHub hinterlegt werden)  
13. **Fehlende GitHub Secrets:**  
    `DOTENV_FILE`,  
    `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`,  
    `IOS_CERTIFICATE_BASE64`, `IOS_CERTIFICATE_PASSWORD`, `IOS_PROVISIONING_PROFILE_BASE64`, `IOS_KEYCHAIN_PASSWORD`, `IOS_TEAM_ID`, `IOS_BUNDLE_ID`  
14. **Bundle Identifier:** `com.johny92013.memoryai`  
15. **Android applicationId:** `com.johny92013.memoryai`  
16. **Bekannte Fehler:** `video_thumbnail` braucht Pub-Cache-Patch (im Workflow enthalten)  
17. **Bekannte Blocker:** kein GitHub-Remote; Platzhalter-Bundle-IDs; Apple/Android Signing-Secrets fehlen  
18. **Workflow gestartet?** Nein  
19. **Workflow-Ergebnis:** nicht ausgeführt  
20. **Download-Stelle:** nach erfolgreichem Lauf unter Actions → Artifacts (`memoryai-1.0.0-android-apk` / `-aab` / `-ios-ipa`)

Zusatz (lokal unter Windows, nicht GitHub Actions):

- `flutter analyze`: keine Issues  
- `flutter test`: 141 Tests bestanden  
- lokale APK: `build/app/outputs/flutter-apk/app-release.apk` (~92,7 MB) – **kein** GitHub-Artefakt  

## Bewertung

**PARTIALLY READY** – Workflow ist eingerichtet, aber Signing-Secrets und GitHub-Remote fehlen; es wurde noch keine APK/AAB/IPA über Actions erzeugt.
