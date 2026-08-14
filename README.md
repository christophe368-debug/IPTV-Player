# IPTV Player

Eigener IPTV-Player fuer Android und iOS, inspiriert von SwipTV. Mit Flutter
gebaut, laeuft auf einer gemeinsamen Codebasis fuer beide Plattformen (und
grundsaetzlich auch auf Android TV).

## Funktionsumfang

- **Login/Profile:** Xtream Codes API, M3U-Playlist (URL), lokale M3U-Datei.
  Mehrere Profile gleichzeitig moeglich, jederzeit wechselbar.
- **Live-TV:** Kategorien, Senderliste mit Logos, Vollbild-Player.
- **EPG:** Programmfuehrer pro Sender ("Jetzt" + kommende Sendungen). Bei
  Xtream ueber `get_short_epg`, bei M3U ueber die im Playlist-Header
  referenzierte XMLTV-Datei (`url-tvg`), falls vorhanden.
- **Timeshift/Catchup:** Vergangene Sendungen erneut abspielen, wenn der
  Sender das unterstuetzt (`tv_archive` bei Xtream).
- **VOD & Serien:** Nur bei Xtream-Profilen (M3U-Playlists liefern keine
  getrennte Struktur dafuer). Poster-Grid, Detailseite mit Beschreibung,
  Staffel-/Episodenauswahl bei Serien.
- **Favoriten:** Sender, Filme und Serien favorisieren, geraeteweise
  gespeichert.
- **Suche:** Uebergreifend ueber Live-TV (+ VOD/Serien bei Xtream).
- **Kindersicherung:** Eltern-PIN (gehasht gespeichert), einzelne
  Kategorien lassen sich damit sperren.
- **Darstellung:** System-/Hell-/Dunkelmodus, in den Einstellungen wechselbar.
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

Manifest ist fuer Android TV vorbereitet (Leanback-Launcher-Eintrag,
Banner, kein Touchscreen vorausgesetzt). Die UI selbst ist aber noch auf
Touch/Handy optimiert (Bottom-Navigation, kein dediziertes 10-Fuss-Design) -
Fernbedienungs-Navigation funktioniert ueber Flutters eingebaute
Fokus-Traversierung (Pfeiltasten/D-Pad), aber ohne die grosszuegigen
Fokus-Hervorhebungen, die ein richtiges TV-UI braucht. Fuer eine wirklich
gute TV-Erfahrung waere ein eigener, groesser dimensionierter TV-Layout-Pfad
ein sinnvoller naechster Schritt.
