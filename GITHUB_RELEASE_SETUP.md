# GitHub Actions Release Setup – Memory AI 1.0.0

Dieser Guide richtet **manuelle / Tag-basierte** Builds ein:

- Android APK
- Android AAB
- iOS IPA

**Kein** automatischer Upload zu Play Store, TestFlight oder App Store.

Workflow-Datei: `.github/workflows/release.yml`

---

## 1. Wie der Workflow funktioniert

Trigger:

- manuell unter **Actions → Release Builds → Run workflow**
- oder Push eines Tags `v*` (z. B. `v1.0.0`)

Zwei Jobs:

| Job | Runner | Artefakte |
|---|---|---|
| `build_android` | `ubuntu-latest` | APK + AAB |
| `build_ios` | `macos-15` | IPA |

Fehlende Secrets oder fehlende Build-Dateien → Job schlägt fehl (`if-no-files-found: error`).

---

## 2. GitHub Secrets öffnen

1. Repository auf GitHub öffnen  
2. **Settings**  
3. **Secrets and variables** → **Actions**  
4. **New repository secret**

---

## 3. Welche Secrets eingetragen werden müssen

### Pflicht (App-Konfiguration)

| Secret | Inhalt |
|---|---|
| `DOTENV_FILE` | Kompletter Inhalt der lokalen `.env` (inkl. `SUPABASE_URL` und `SUPABASE_PUBLISHABLE_KEY`) |

### Android

| Secret | Inhalt |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | Base64 der `.jks` / `.keystore` |
| `ANDROID_KEYSTORE_PASSWORD` | Keystore-Passwort |
| `ANDROID_KEY_ALIAS` | Key-Alias |
| `ANDROID_KEY_PASSWORD` | Key-Passwort |

### iOS

| Secret | Inhalt |
|---|---|
| `IOS_CERTIFICATE_BASE64` | Base64 der `.p12` (Distribution/Development) |
| `IOS_CERTIFICATE_PASSWORD` | Passwort der `.p12` |
| `IOS_PROVISIONING_PROFILE_BASE64` | Base64 der `.mobileprovision` |
| `IOS_KEYCHAIN_PASSWORD` | beliebiges Passwort für temporäres Runner-Keychain |
| `IOS_TEAM_ID` | 10-stellige Apple Team ID |
| `IOS_BUNDLE_ID` | (nur für signierte Builds) `com.johny92013.memoryai` |

Optional (nicht für diesen Workflow nötig): `APPLE_ID`, `APP_SPECIFIC_PASSWORD`, App Store Connect API Keys.

---

## 4. Android Keystore → Base64 (Windows PowerShell)

```powershell
[Convert]::ToBase64String(
    [IO.File]::ReadAllBytes("C:\Pfad\upload-keystore.jks")
) | Set-Content "android-keystore-base64.txt"
```

Den **gesamten Inhalt** von `android-keystore-base64.txt` in Secret `ANDROID_KEYSTORE_BASE64` kopieren.

---

## 5. Apple-Zertifikat (.p12) → Base64

```powershell
[Convert]::ToBase64String(
    [IO.File]::ReadAllBytes("C:\Pfad\distribution-certificate.p12")
) | Set-Content "ios-certificate-base64.txt"
```

Inhalt → Secret `IOS_CERTIFICATE_BASE64`.

---

## 6. Provisioning Profile → Base64

```powershell
[Convert]::ToBase64String(
    [IO.File]::ReadAllBytes("C:\Pfad\AppStore.mobileprovision")
) | Set-Content "ios-profile-base64.txt"
```

Inhalt → Secret `IOS_PROVISIONING_PROFILE_BASE64`.

---

## 7. Build manuell starten

1. GitHub → **Actions**  
2. Workflow **Release Builds**  
3. **Run workflow**  
4. Branch wählen → **Run workflow**

---

## 8. Artefakte herunterladen

Nach grünem Lauf:

**Actions → konkreter Workflow-Lauf → Artifacts**

- `memoryai-1.0.0-android-apk`
- `memoryai-1.0.0-android-aab`
- `memoryai-1.0.0-ios-ipa`

Retention: 14 Tage.

---

## 9. Git-Tag erstellen

Wenn ein Git-Remote existiert:

```bash
git tag v1.0.0
git push origin v1.0.0
```

Das startet denselben Workflow.

---

## 10. Build-Fehler prüfen

1. Actions → fehlgeschlagener Lauf  
2. Job `build_android` oder `build_ios` öffnen  
3. Roter Step → Log lesen  

Häufig:

- Secret fehlt (klare Fehlermeldung am Anfang)
- Bundle ID ≠ `IOS_BUNDLE_ID` / Profile
- `.env` / `DOTENV_FILE` unvollständig
- Certificate/Profile-Typ passt nicht zu `ios/ExportOptions.plist` (`method = app-store`)

---

## Bundle Identifier Hinweis (Blocker für Store)

Aktuell im Projekt:

- Android `applicationId`: `com.example.memory_ai`
- iOS Bundle ID: `com.johny92013.memoryai`

Das sind Flutter-Platzhalter. Für echte Store-Einreichung eigene IDs registrieren und im Projekt + Secrets anpassen. Für CI muss `IOS_BUNDLE_ID` dem Xcode-Wert entsprechen und das Provisioning Profile denselben Identifier abdecken.

---

## Git Remote einrichten (falls noch keins)

Dieses Workspace hatte zum Zeitpunkt der Einrichtung **kein** `.git`-Verzeichnis.

```bash
cd "C:\Users\dpc98\MemoryAi by John"
git init
git add .
git commit -m "chore: add GitHub Actions release builds for Android and iOS"
# Eigenes leeres GitHub-Repo erstellen, dann:
git remote add origin https://github.com/DEIN_USER/DEIN_REPO.git
git branch -M main
git push -u origin main
```

Danach Secrets setzen und Workflow starten.
