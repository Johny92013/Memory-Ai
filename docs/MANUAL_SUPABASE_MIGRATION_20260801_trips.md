# Manuelle Supabase-Migration: Trip-Mitreisende & Einladungen

## Datei

`supabase/migrations/20260801_trip_companions_and_invites.sql`

## Was wird angelegt

- Tabelle `trip_companions` – Mitreisende ohne Account (`display_name`, `notes`)
- Tabelle `trip_invites` – optionale Share-Codes (`code`, `role`, `expires_at`)
- RLS: Companion-Lesen für akzeptierte Trip-Mitglieder; Verwalten für Owner/Editor (`private.can_edit_trip`)
- RLS: Invite-Codes lesbar für Mitglieder; Verwalten nur Owner
- `GRANT` auf `trip_companions` / `trip_invites` für `authenticated`
- Policies: eigene `trip_members`-Zeilen sehen; eigene `pending`-Einladung annehmen/ablehnen
- Policy: Pending-Eingeladene dürfen die Reise (`trips`) sehen
- Funktion `redeem_trip_invite(p_code)` → legt/aktualisiert `trip_members` mit `invitation_status = 'pending'` (akzeptierte bleiben accepted)

E-Mail-/User-Einladungen laufen weiter über `trip_members` mit Status `pending` (kein zweites Membership-Modell).

## Schritte

1. Supabase Dashboard öffnen → SQL Editor
2. Inhalt der Migrationsdatei einfügen und ausführen
3. Prüfen:
   - Tabellen `trip_companions`, `trip_invites`
   - Policies auf beiden Tabellen + erweiterte `trip_members`/`trips`-Policies
   - Funktion `public.redeem_trip_invite`

## App-seitig

Nach dem SQL-Lauf: App neu starten. Kein Storage-/File-Copy nötig.

## Rollback (Hinweise)

```sql
drop function if exists public.redeem_trip_invite(text);
drop policy if exists "Pending invitees can view invited trips" on public.trips;
drop policy if exists "Users can update own pending invite" on public.trip_members;
drop policy if exists "Users can view own membership" on public.trip_members;
drop table if exists public.trip_invites;
drop table if exists public.trip_companions;
```

Nicht automatisch auf Produktion anwenden. Bestehende Trip-Tabellen nicht löschen.
