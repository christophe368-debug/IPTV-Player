# IPTV Player

Eigener IPTV-Player fuer Android und iOS, inspiriert von SwipTV. Mit Flutter
gebaut, laeuft auf einer gemeinsamen Codebasis fuer beide Plattformen (und
grundsaetzlich auch auf Android TV).

## Funktionsumfang

- **Login/Profile:** Xtream Codes API, M3U-Playlist (URL), lokale M3U-Datei.
  Mehrere Profile gleichzeitig moeglich, jederzeit wechselbar.
- **Live-TV:** Kategorien, Senderliste mit Logos, Vollbild-Player.
- **EPG:** Programmfuehrer pro Sender ("Jetzt" + kommende Sendungen) und ein
  TV-Guide-Raster (Sender untereinander, Zeitleiste quer) fuer eine ganze
  Kategorie auf einmal. Bei Xtream ueber `get_short_epg`/`xmltv.php`, bei
  M3U ueber die im Playlist-Header referenzierte XMLTV-Datei (`url-tvg`),
  falls vorhanden.
- **Timeshift/Catchup:** Vergangene Sendungen erneut abspielen, wenn der
  Sender das unterstuetzt (`tv_archive` bei Xtream).
- **VOD & Serien:** Nur bei Xtream-Profilen (M3U-Playlists liefern keine
  getrennte Struktur dafuer). Poster-Grid, Detailseite mit Beschreibung,
  Staffel-/Episodenauswahl bei Serien.
- **Favoriten:** Sender, Filme und Serien favorisieren, geraeteweise
  gespeichert.
- **Suche:** Uebergreifend ueber Live-TV (+ VOD/Serien bei Xtream).
- **Kindersicherung:** Eltern-PIN (gehasht gespeichert). Ganze Kategorien
  oder einzelne Sender/Filme/Serien lassen sich sperren - die PIN wird
  ueberall abgefragt, egal ob man ueber Kategorie, Favoriten oder Suche
  dorthin gelangt.
- **Ausblenden & Umbenennen:** Kategorien und einzelne Inhalte lassen sich
  ausblenden (ohne PIN, reine Uebersicht) und Kategorien umbenennen.
- **Darstellung:** System-/Hell-/Dunkelmodus. Eigenes Design (kein
  generisches Material-Lila): dunkler blaustichiger Hintergrund, warmer
  Signalrot-Akzent, Space Grotesk/Inter-Typografie, ein durchgaengiges
  "Live-Puls"-Symbol fuer alles, was gerade laeuft.
- **Start-Bildschirm:** Hero-Bereich (Favorit) + horizontal scrollbare
  Reihen (Favoriten, Kategorien) statt direkt in einer Liste zu landen.
- **Picture-in-Picture:** Auf Android ueber den PiP-Button im Player.

**Bewusst zurueckgestellt:** Chromecast (braucht natives Google-Cast-SDK-Setup
auf beiden Plattformen - separater Folgeschritt).

## Tech-Stack

| Bereich | Wahl | Warum |
|---|---|---|
| Framework | Flutter | Eine Codebasis fuer Android/iOS/(TV) |
| State Management | Riverpod | Testbar, kein BuildContext noetig fuer Provider-Zugriff |
| Video-Wiedergabe | media_kit (libmpv) | Spielt im Gegensatz zu `video_player` auch rohes MPEG-TS zuverlaessig ab - bei IPTV sehr haeufig |
| Lokale Speicherung | Hive | Simple Key-Value-Speicherung ohne Code-Generierung |
| Sichere Speicherung | flutter_secure_storage | Fuer sensible Daten (aktuell vorbereitet, noch nicht aktiv genutzt) |

## Projektstruktur

```
lib/
  models/         Datenklassen (Profile, Channel, Category, EpgProgram, ...)
  services/       API-Clients (Xtream, M3U-Parser, XMLTV-Parser, Storage)
  repositories/   Einheitliche Content-Schnittstelle ueber Xtream/M3U hinweg
  providers/      Riverpod-Provider (State-Management)
  screens/        UI, nach Feature-Bereich sortiert (auth, live_tv, vod, ...)
  widgets/        Wiederverwendbare UI-Bausteine
third_party/      Lokal gepatchte Pub-Pakete (siehe third_party/README.md)
```

## Entwicklung

### Voraussetzungen

- Flutter SDK (aktuell installiert unter `C:\src\flutter`)
- Android Studio + Android SDK (aktuell unter `E:\dev-tools\Android\Sdk`,
  auf externem Laufwerk wegen Speicherplatz)
- JDK 17 fuer Gradle-Builds (`E:\dev-tools\jdk-17` - **nicht** die von
  Android Studio mitgelieferte JBR/Java 25 verwenden, die ist zu neu fuer
  manche Gradle-Versionen)

### Umgebungsvariablen (fuer jede neue Terminal-Sitzung)

```powershell
$env:ANDROID_HOME = "E:\dev-tools\Android\Sdk"
$env:ANDROID_SDK_ROOT = "E:\dev-tools\Android\Sdk"
$env:GRADLE_USER_HOME = "E:\dev-tools\gradle"
$env:JAVA_HOME = "C:\Program Files\Android\Android Studio\jbr"
$env:Path += ";C:\src\flutter\bin"
```

(Diese sind auch als User-Umgebungsvariablen dauerhaft gesetzt - ein neu
geoeffnetes Terminal sollte sie automatisch haben.)

### Wichtige Befehle

```bash
flutter pub get              # Abhaengigkeiten installieren
flutter analyze              # Statische Code-Analyse
flutter test                 # Tests ausfuehren
flutter build apk --debug    # Debug-APK bauen (build/app/outputs/flutter-apk/)
flutter run -d <device-id>   # Auf Emulator/Geraet starten
```

### Bekannte Stolpersteine auf diesem Rechner

- **Nur 7 GB RAM:** Gradle-Heap ist in `android/gradle.properties` bewusst
  klein gehalten (`-Xmx1536m`). Nach jedem Build lohnt sich
  `./android/gradlew --stop`, um den Gradle-Daemon-Speicher wieder
  freizugeben, bevor der Android-Emulator gestartet wird.
- **AGP 9 / Built-in Kotlin:** `android.builtInKotlin=true` ist noetig,
  weil Flutter mittlerweile AGP 9+ voraussetzt. Manche Plugins hinken bei
  der Umstellung hinterher - siehe `third_party/README.md` fuer den
  wakelock_plus-Workaround.

## iOS-Build

Es steht kein Mac zur Verfuegung. iOS-Builds laufen ueber
[Codemagic](https://codemagic.io) (Cloud-CI mit macOS-Runnern), konfiguriert
in `codemagic.yaml`. Dafuer noetig:

1. GitHub-Repo (Code dorthin pushen)
2. Codemagic-Account, Repo verbinden
3. Apple Developer Account (99 $/Jahr) fuer Code-Signierung - nur noetig,
   um auf einem echten iPhone zu testen oder im App Store zu veroeffentlichen

## Android TV

- Manifest ist vorbereitet (Leanback-Launcher-Eintrag, Banner, kein
  Touchscreen vorausgesetzt).
- Laufzeit-Erkennung, ob die App auf einem TV-Geraet laeuft
  (`UiModeManager` in `MainActivity.kt`, gespiegelt nach Dart ueber
  `isAndroidTvProvider`).
- Auf einem erkannten TV-Geraet:
  - **Seiten-Navigation** (`NavigationRail`) statt Bottom-Navigation -
    mit dem D-Pad rauf/runter viel natuerlicher zu bedienen als eine
    Leiste am unteren Bildschirmrand.
  - **Sichtbare Fokus-Hervorhebung** (`TvFocusHighlight`-Widget) in
    Profil-, Kategorie-, Sender- und Poster-Listen, damit man beim
    Navigieren mit der Fernbedienung aus mehreren Metern Entfernung
    erkennt, wo man gerade ist. Automatischer Fokus auf dem ersten
    Listenelement, wenn ein Bildschirm oeffnet.
  - Etwas groessere Schrift/Icons (`VisualDensity.comfortable` +
    Text-Skalierung).
  - Picture-in-Picture-Button im Player ist ausgeblendet (auf TV ohne
    Fenster-Konzept nicht sinnvoll).
- **Noch offen:** kein komplett eigener 10-Fuss-Layout-Pfad (z.B.
  groessere Poster-Grids, andere Abstaende auf Formular-Screens wie
  Login/Einstellungen). Fuer den Alltag (Sender/Filme/Serien durchsuchen
  und abspielen) sollte es sich aber schon gut mit einer Fernbedienung
  bedienen lassen.
