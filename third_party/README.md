# third_party/

Enthaelt lokal gepatchte Kopien von Pub-Paketen, bei denen ein Upstream-Bug
den Build mit unserer aktuellen Toolchain (Flutter 3.47 / AGP 9+) verhindert.
Wird per `dependency_overrides` in `pubspec.yaml` eingebunden.

## wakelock_plus (Basis: Version 1.7.0)

**Bug:** Die von Pigeon generierte Datei
`android/src/main/kotlin/dev/fluttercommunity/plus/wakelock/WakelockPlusMessages.g.kt`
hat keine `package`-Deklaration, obwohl die abhaengigen Dateien (`Wakelock.kt`,
`WakelockPlusPlugin.kt`) sie ueber unqualifizierte Imports wie
`import IsEnabledMessage` referenzieren. Das fuehrt zu
"Unresolved reference"-Fehlern beim Android-Build.

**Fix:** `package dev.fluttercommunity.plus.wakelock` in der generierten Datei
ergaenzt und die kaputten Imports in den beiden anderen Dateien entfernt
(nicht mehr noetig, da alle drei Dateien jetzt im selben Package liegen).

**TODO:** Sobald eine neue `wakelock_plus`-Version diesen Bug offiziell
behebt (siehe https://pub.dev/packages/wakelock_plus/changelog), sollte
dieser Override entfernt und wieder die normale Pub-Version genutzt werden.
