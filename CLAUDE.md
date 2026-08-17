# Projektkontext fuer Claude Code

IPTV-Player-App (Flutter, Android + iOS), inspiriert von SwipTV. Siehe
`README.md` fuer Funktionsumfang, Architektur und Tech-Stack-Begruendung -
das hier ist nur der Arbeitsstand/TODO-Teil, der sich schneller aendert.

## Stand

Alle Kernfunktionen sind fertig und auf Android getestet (Emulator):
Login (Xtream/M3U-URL/lokale Datei), Live-TV mit EPG/Timeshift, VOD/Serien
(Xtream), Favoriten, Suche, Eltern-PIN, Themes, Picture-in-Picture,
Android TV (Erkennung + Seiten-Navigation + Fokus-Hervorhebung fuer
D-Pad). 8 Tests gruen, `flutter analyze` sauber.

## Offen

- **iOS-Build (Task #12):** `codemagic.yaml` liegt bereit. Braucht in der
  Codemagic-Weboberflaeche noch: Repo verbinden, Code-Signing (Apple
  Developer Account, 99 $/Jahr - nur fuer echtes iPhone/App-Store-Test
  noetig). Der Nutzer macht das selbst (Konto-/Zahlungsdaten gehoeren
  nicht in Claude-Haende).
- **Chromecast:** Bewusst zurueckgestellt - braucht natives Google-Cast-SDK-
  Setup auf beiden Plattformen (CastOptionsProvider etc.), eigener
  Folgeschritt.
- **Android TV Feinschliff (Task #13, erledigt):** TV-Erkennung
  (`UiModeManager` -> `isAndroidTvProvider`), `NavigationRail` statt
  Bottom-Nav, `TvFocusHighlight`-Widget fuer sichtbaren D-Pad-Fokus in
  Profil-/Kategorie-/Sender-/Poster-Listen, PiP-Button auf TV ausgeblendet.
  Noch nicht gemacht: ein wirklich eigener 10-Fuss-Layout-Pfad (groessere
  Grids/Abstaende speziell fuer TV) - bisher nur Skalierung ueber
  VisualDensity/TextScaler, kein separates Layout.
- Keine echten IPTV-Zugangsdaten zum Testen vorhanden - bisher nur mit
  einer oeffentlichen Test-Playlist (`https://iptv-org.github.io/iptv/
  countries/de.m3u`, Live-TV-only, kein Xtream) durchgetestet. VOD/Serien-
  Pfad (Xtream-only) ist nur durch Code-Review + Unit-Tests abgesichert,
  nicht end-to-end mit echten Daten.

## Falls hier auf einem neuen Rechner/VPS weitergearbeitet wird

- `flutter pub get` reicht fuer die Dart-Seite. Fuer Android-Builds:
  Flutter SDK + Android SDK (cmdline-tools + platform-tools + mindestens
  ein API-34-Image) + ein JDK, das zur Gradle-Version passt (siehe
  `android/gradle/wrapper/gradle-wrapper.properties`, aktuell Gradle 9.3.1
  -> braucht ein recht neues JDK, 17 ist zu alt dafuer, siehe unten).
- `android.builtInKotlin=true` in `android/gradle.properties` ist mit
  Absicht gesetzt (AGP 9 verlangt das). `third_party/wakelock_plus`
  enthaelt einen lokal gepatchten Upstream-Bug (siehe
  `third_party/README.md`) - beim `flutter pub get` wird das automatisch
  ueber `dependency_overrides` in `pubspec.yaml` eingebunden, keine
  manuelle Aktion noetig.
- Auf dem urspruenglichen Windows-Entwicklungsrechner (nur 7 GB RAM)
  mussten Android-SDK/Gradle-Cache auf ein externes Laufwerk ausgelagert
  und der Gradle-Heap klein gehalten werden (`-Xmx1536m` in
  `android/gradle.properties`). Auf einem VPS mit mehr RAM kann das
  grosszuegiger eingestellt werden, wenn es die Build-Zeit verbessert.
- **Android-Emulator auf einem VPS:** Braucht Hardware-Virtualisierung
  (KVM). Viele guenstige VPS-Angebote unterstuetzen kein nested
  virtualization - dann laeuft `flutter build apk` zwar problemlos, aber
  kein Emulator. Alternativen: `adb connect` zu einem echten Android-Handy
  im selben Netzwerk, oder Firebase Test Lab / vergleichbarer Cloud-
  Geraete-Dienst.
- iOS lokal bauen/testen geht nur mit einem Mac - deshalb Codemagic
  (siehe oben).
