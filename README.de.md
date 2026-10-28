# aud_audio_core

[English](README.md) | Deutsch

[![CI](https://github.com/audaudio/aud_audio_core/actions/workflows/quick_check.yaml/badge.svg)](https://github.com/audaudio/aud_audio_core/actions/workflows/quick_check.yaml)

Kern der Audanika Audio Engine: die C-ABI, Buffer- und Event-Formate, Node-Verträge, Timing-Vertrag und OSC-Nachrichtenmodell.

Teil der Audanika Audio Engine; geplant in
[aud_audio_pm](https://github.com/audaudio/aud_audio_pm). Die Dart-Bibliothek
`aud_audio_core.dart` ist plattformneutral und kompiliert fürs Web; die
nativen Teile in `aud_audio_core_ffi.dart` brauchen eine native Plattform.

## Motivation

Jedes Paket der Audanika Audio Engine — der Graph, das Geräte-IO, die
MIDI-Brücke und die DSP-Nodes — muss sich auf dieselben Buffer, Events,
Zeitstempel und denselben Node-Lebenszyklus verständigen. Dieses Paket hält
diesen Vertrag ein einziges Mal:

- Als Header-only C und C++ in `src/`, von jedem Paket der Familie
  eingebunden und nie gelinkt, damit ein gegen die ABI gebauter Node in
  jeder Engine desselben ABI-Minors läuft
- Als Dart-Typen, die die ABI spiegeln, damit Hosts, Werkzeuge und Tests
  dieselbe Sprache sprechen wie der native Code
- Mit einer versionierten ABI: in Major 0 müssen die Minors exakt
  übereinstimmen, ab 1.0 akzeptiert eine Engine ältere Minors

## Installation

Das Paket ist nicht auf pub.dev veröffentlicht. Füge es als
Git-Abhängigkeit hinzu, aufgelöst über seinen Versions-Tag:

```yaml
dependencies:
  aud_audio_core:
    git:
      url: git@github.com:audaudio/aud_audio_core.git
      tag_pattern: "{{version}}"
    version: ^0.5.4
```

Dann `dart pub get` ausführen. Die native Bibliothek baut der Build-Hook
des Pakets, wenn die App gebaut wird.

## Verwendung

Das Beispiel in `example/` zeigt die ABI-Version der Dart-Seite und des
nativen Kerns und prüft, dass beide sich auf die Größen der ABI-Strukturen
einigen:

```dart
import 'package:aud_audio_core/aud_audio_core_ffi.dart';

void main() {
  // The ABI version the Dart side and the native core were built for
  print('ABI version (Dart): ${AudAbi.major}.${AudAbi.minor}');
  print(
    'ABI version (native): '
    '${AudAbiNative.nativeMajor}.${AudAbiNative.nativeMinor}',
  );

  // Both sides must agree on the sizes of the ABI structs
  final sizesAgree =
      AudAbiNative.dartStructSizes.toString() ==
      AudAbiNative.nativeStructSizes.toString();
  print('Struct sizes agree: $sizesAgree');
}
```

Es gibt aus:

```text
ABI version (Dart): 0.4
ABI version (native): 0.4
Struct sizes agree: true
```

## Grenzen

- Das Paket enthält Verträge und Helfer, keine Engine: Rendern, Scheduling
  und Transport liegen in `aud_audio_graph`, das Geräte-IO in
  `aud_audio_io`
- In Major 0 müssen die ABI-Minors eines Nodes und einer Engine exakt
  übereinstimmen
- `aud_audio_core_ffi.dart`, die Bindings und der Referenzknoten
  `aud.core.gain` brauchen eine native Plattform; nur `aud_audio_core.dart`
  kompiliert fürs Web
- Die native Bibliothek ist für ihre Nutzer Header-only; sie exportiert die
  ABI-Version, die Strukturgrößen und die Handle-APIs der Helfer, sonst
  nichts

## Dokumentation

- [Notices-Guide](doc/guides/notices-guide.md) — die Notices-Konvention,
  die `node scripts/check-notices.js` prüft
- [JSON-Schema eines Node-Presets](doc/schemas/aud_node_preset.schema.json)
- [Blog](doc/de/blog) — ein Beitrag pro Änderung
- [aud_audio_pm](https://github.com/audaudio/aud_audio_pm) — die Pläne und
  Entscheidungen der Audanika Audio Engine

## Wie es funktioniert

### Was das Paket enthält (ABI 0.4, Tickets 18, 19, 25 und 37)

Header-only C und C++ in `src/`, von jedem Paket der Familie eingebunden
und nie gelinkt:

- `aud_abi.h` — die versionierte C-ABI (abi-001): Strukturen mit Größe,
  Ergebniscodes (seit 0.3 auch cycle, format, lookahead, capacity, retired
  und overload für den Graphen, seit 0.4 cancelled und underflow),
  Capabilities, Thread-Affinitäts-Tags, Bus-, Event-Port-, Parameter- und
  String-Key-Deskriptoren, `AudEvent` (UMP-, Control-, Parameter- und
  Message-Events), `AudMessage` mit den OSC-1.1-Argument-Tags i, f, h, d,
  s, b, T, F, N und I, `AudProcessContext` mit planaren Bussen,
  `AudTimestamp` mit den Domänen immediate, sample, host und beat,
  `AudStreamTime`, die Transport-Segmente, Snapshot, Requests und
  Provider-Vtable (time-001), die Node-Vtable mit Reset-Gründen, Latenz,
  Tail und State-Blobs, `AudHostApi` und der `AudRenderRequest` des
  Headless Hosts (plugin-002). In Major 0 müssen die Minors exakt
  übereinstimmen; ab 1.0 akzeptiert eine Engine ältere Minors. Seit 0.4
  (Ticket 25, lifecycle-002, osc-002) bietet die Host-API Worker-Tasks
  (`post_task`, auch aus dem Audio-Thread), Loads mit IDs, Fortschritt und
  Abbruch, Sample-Caches unter dem Budget des Prozesses (`register_cache`,
  `cache_changed`, `cache_budget`), Reports eines Nodes pro Block und
  `emit_message`; ein Node mit `AUD_NODE_CAP_MESSAGES` nimmt
  OSC-Nachrichten als `AUD_EVENT_MESSAGE`-Events an (`AudMessage`,
  `AudMessageArg`). Die Thread-Tags `[worker]` und `[any thread]` sagen,
  was auf den Workern läuft und was jeder Thread aufrufen darf. Ticket 37
  ergänzt `AUD_NODE_CAP_PASSES_EVENTS` innerhalb von 0.4, da eine Engine
  ohne es das Flag ignoriert: Ein Node damit, etwa ein MIDI-Thru oder ein
  Channel-Split, gibt seine Noten unverändert bis auf ihren Port weiter
  (`AudNodeCapabilities.passesEvents`); die Nodes dahinter schließen sie
  bei einem Stopp oder einem Prepare, und die Engine schließt die, die er
  aus dem Graphen gab, mit je einem Note-Off.
- `aud_clock.h` — die monotone Host-Uhr.
- `aud_time_filter.h` — der Sample-zu-Hostzeit-Filter mit seinen
  Reset-Regeln.
- `aud_transport.h` — Beat-, Sample- und Hostzeit-Umrechnung über einen
  Snapshot.
- `aud_ump.h` — die Felder des Universal MIDI Packet, Per-Note-Controller
  inklusive.
- `aud_spsc_queue.hpp` — die lock-freie Single-Producer-Queue (interop-002).
- `aud_param_ramp.hpp`, `aud_node_base.hpp`, `aud_fixed_block_adapter.hpp`
  — die Ramp, die Node-Basisklasse, die Blöcke an Event-Offsets in
  Subranges von 16 Frames teilt (graph-002), und der Fixed-Block-Adapter.

Die native Bibliothek exportiert ABI-Version und Strukturgrößen, die
Handle-APIs von Filter, Umrechnung, Ramp und Adapter und registriert den
Referenzknoten `aud.core.gain` über `aud_audio_core_register`.

### Dart-API

`aud_audio_core.dart` ist plattformneutral und kompiliert fürs Web
(web-001); `aud_audio_core_ffi.dart` ergänzt die nativen Teile:
`AudAbiNative`, die Umwandlungen von und in die ABI-Strukturen
(`native.toDart()`, `event.writeTo(pointer)`), `AudTimeFilter`,
`AudParamRamp`, `AudFixedBlockAdapter`, `AudCoreGain` und
`AudNativeTransportSnapshot`.

Ein Node mit `AudNodeCapabilities.messages` bekommt die Message-Route
`AudOscAddress.message` (`/graph/<g>/node/<n>/msg`, osc-002):
`AudOscRouter.resolveMessage` findet die `AudMessageTarget`s einer
Adresse darunter und den Pfad, der übrig bleibt, und `AudOscAdapter` macht
aus der Nachricht einen `AudMessageCommand`.

Ein Überblick über die API, mit einem Transport-`snapshot` und einem
Node-`descriptor` des Aufrufers:

```dart
import 'package:aud_audio_core/aud_audio_core_ffi.dart';

AudAbi.major;                              // 0; AudAbi.minor is 4
AudAbiNative.dartStructSizes == AudAbiNative.nativeStructSizes;

final at = AudTimestamp.beat(4);           // or .sample(n), .host(ns), .immediate()
snapshot.resolve(at);                      // AudResolution: ok(offset), late, pending

final filter = AudTimeFilter(sampleRate: 48000);
filter.add(samplePosition: 0, frames: 256, hostTimeNs: AudClock.nowNs());
filter.hostTimeAt(48000);

final events = AudUmpEvent.fromMessage(      // aud_midi_standard messages (midi-001)
  const MidiNoteOn(channel: 0, note: 60, velocity: 100),
);
const ramp = AudParamEvent(paramIndex: 0, value: 0.5, rampFrames: 64);

final router = AudOscRouter()
  ..registerNode(graph: 1, node: 2, handle: 20, descriptor: descriptor);
final adapter = AudOscAdapter(router: router);
adapter.convert(AudOscMessage('/graph/1/node/2/param/gain', [0.5]));
// [AudSetParamCommand(node: 20, paramIndex: 0, value: 0.5)]
adapter.convert(AudOscMessage('/graph/1/node/2/msg/num_regions'));
// [AudMessageCommand(node: 20, message: /num_regions)], for a node with
// messages (osc-002)

final preset = AudNodePreset.defaults(descriptor);  // JSON schema in doc/schemas
preset.validate(descriptor);                        // [] when it fits
```

`package:aud_audio_core/aud_audio_core_bindings.dart` exportiert die
rohen ffigen-Bindings mit den nativen Strukturen für Hosts und Node-Tests.

## Status

Version 0.5.4 auf ABI 0.4. Vor 1.0 — die API und die ABI können sich
zwischen Minor-Versionen ändern.

## Mitwirken

- Folge dem [Develop-Guide](doc/guides/develop-guide.md), dem
  [Code-Guide](doc/guides/code-guide.md) und dem
  [Test-Guide](doc/guides/test-guide.md)
- Die Bindings neu erzeugen mit `dart run ffigen --config ffigen.yaml`
- Die Notices-Konvention prüfen mit `node scripts/check-notices.js`, siehe
  den [Notices-Guide](doc/guides/notices-guide.md)

## Lizenz

MIT — siehe [LICENSE](LICENSE).
