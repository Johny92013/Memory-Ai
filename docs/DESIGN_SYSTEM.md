# Design-System – Datei-Struktur

## Organisation (eine Quelle der Wahrheit, keine doppelten Themes)

| Datei | Inhalt |
|-------|--------|
| `lib/app/app_colors.dart` | Alle Farbkonstanten (#141B2E, #1F2A47, #F2A34C, #3DDBC4, …) |
| `lib/app/app_spacing.dart` | 4px-Raster: `xs` 4, `sm` 8, `md` 12, `lg` 16, `xl` 24, `xxl` 32, `xxxl` 48 |
| `lib/app/app_radius.dart` | `chip` 8, `card` 16, `photo` 20, `sheet` 24 |
| `lib/app/app_typography.dart` | `AppTypography` – Space Grotesk (Display), Inter (Body), JetBrains Mono (Stats) |
| `lib/app/app_theme.dart` | Einziges `ThemeData` (`AppTheme.dark`) – referenziert nur AppColors/Spacing/Radius/Typography |
| `lib/app/theme_extensions.dart` | `AppThemeExtension` für Mono-Stats + Akzentfarben via `Theme.of(context).extension` |

**Keine zweite Theme-Definition:** Screens nutzen `Theme.of(context)` + `AppColors`/`AppSpacing`. Lokale Overrides nur für Layout (Padding), nicht für konkurrierende Farb-/Font-Themes.

## Typografie-Skala (in `AppTheme.dark`)

- `displayLarge` – Space Grotesk 32/700 (Start-Begrüßung)
- `headlineMedium` – Space Grotesk 22/700 (Screen-Titel)
- `titleMedium` – Space Grotesk 16/500 (Karten-Titel)
- `bodyMedium` – Inter 14/400
- `labelSmall` – Inter 12/500 (Chips, Nav)
- `extension.statsMono` – JetBrains Mono 13/500 (Daten, Tickets)

## Shared UI (wiederverwendbar)

- `boarding_pass_trip_card.dart` – Bordkarten-Reisekarte
- `perforated_divider.dart` – Perforationslinie (CustomPainter)
- `app_button.dart`, `app_scaffold.dart`, `app_card.dart` – an Theme angebunden

## Scope dieses Redesigns

Kern-Screens: Home, TripsOverview, TripDetail, WorldMap, Upload (PhotoMetadata + UploadPhotos), Profil, MainNavigation.

Legacy-Screens (Familie, Chat, Admin) erben automatisch neues globales Theme, ohne Screen-spezifisches Redesign.

## Visuelle Referenz (Kern-Screens)

### Home
Dunkler Hintergrund (#141B2E), große Space-Grotesk-Begrüßung. Darunter eine Zeile mit vier gleich breiten Stat-Karten (Surface #1F2A47, JetBrains Mono-Zahlen). Dominantes Element: kompakte Boarding-Pass-Karte der letzten Reise (Cover-Gradient, Perforation, Ticket-Daten). Darunter scrollbare Foto-Grids und horizontale Länder-/Ort-Chips. Schnellzugriff: zwei ruhige Karten mit warmem (Reisen) bzw. kühlem (Karte) Icon-Akzent.

### TripDetail
App-Bar mit Reise-Titel. Großer Boarding-Pass-Header (nicht tappbar): Cover-Bereich mit Flug-Icon-Wasserzeichen, gepunktete Trennlinie, Mono-Felder VON/BIS/DEST/FOTOS. Darunter Beschreibung in gedämpftem Inter, Nav-Chips (Karte in Türkis), warmer Upload-Button.

### WorldMap
Titel + Mono-Statzeile, horizontale Filter-Chips (warm wenn aktiv). Karte mit abgerundeter Oberkante; bei Zoom ≥6 gepunktete türkise Flugrouten zwischen GPS-Punkten einer Reise. Länder-Marker warm-orange, Cluster-Marker kühl-türkis. Unten horizontale Länder-Karten mit Mono-Fotozähler.
