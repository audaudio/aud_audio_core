# aud_audio_core

Kern der Audanika Audio Engine: die C-ABI, Buffer- und Event-Formate, Node-Verträge, Timing-Vertrag und OSC-Nachrichtenmodell.

Teil der Audanika Audio Engine; geplant in [aud_audio_pm](https://github.com/audaudio/aud_audio_pm).

## Was das Paket enthält (ABI 0.2, Ticket 18)

Header-only C und C++ in `src/`, von jedem Paket der Familie eingebunden
und nie gelinkt: `aud_abi.h` (die versionierte C-ABI mit Deskriptoren,
Events, Prozesskontext, Zeitstempeln, Transport-Verträgen, Node-Vtable und
Host-API; in Major 0 müssen die Minors exakt übereinstimmen),
`aud_clock.h`, `aud_time_filter.h` (Sample-zu-Hostzeit-Filter),
`aud_transport.h` (Beat-, Sample- und Hostzeit-Umrechnung), `aud_ump.h`
(UMP-Felder inklusive Per-Note-Controller), `aud_spsc_queue.hpp`,
`aud_param_ramp.hpp`, `aud_node_base.hpp` (Blockteilung an Event-Offsets
in Subranges von 16 Frames) und `aud_fixed_block_adapter.hpp`.

Die native Bibliothek exportiert ABI-Version und Strukturgrößen, die
Handle-APIs von Filter, Umrechnung, Ramp und Adapter und registriert den
Referenzknoten `aud.core.gain`.

## Dart-API

Siehe das Beispiel in [README.md](README.md): `AudAbi`, `AudTimestamp`,
`AudTransportSnapshot`, `AudTimeFilter`, `AudEvent` (aus
`aud_midi_standard`-Nachrichten), `AudNodeDescriptor`, `AudNodePreset`
(JSON-Schema in `doc/schemas`), `AudOscAddress`, `AudOscMessage`,
`AudCommand`, `AudOscRouter` und `AudOscAdapter`.
`package:aud_audio_core/aud_audio_core_bindings.dart` exportiert die
rohen ffigen-Bindings mit den nativen Strukturen.

## Notices

`node scripts/check-notices.js` prüft die Notices-Konvention von
license-001, siehe [doc/guides/notices-guide.md](doc/guides/notices-guide.md).
