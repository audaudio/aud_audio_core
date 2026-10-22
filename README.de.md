# aud_audio_core

Kern der Audanika Audio Engine: die C-ABI, Buffer- und Event-Formate, Node-Verträge, Timing-Vertrag und OSC-Nachrichtenmodell.

Teil der Audanika Audio Engine; geplant in [aud_audio_pm](https://github.com/audaudio/aud_audio_pm).

## Was das Paket enthält (ABI 0.4, Tickets 18, 19, 25 und 37)

Header-only C und C++ in `src/`, von jedem Paket der Familie eingebunden
und nie gelinkt: `aud_abi.h` (die versionierte C-ABI (abi-001) mit
Capabilities, Thread-Tags, Deskriptoren, UMP-, Control-, Parameter- und
Message-Events, `AudMessage` mit den OSC-1.1-Typ-Tags i, f, h, d, s, b, T,
F, N und I, Prozesskontext, Zeitstempeln, Transport-Verträgen (time-001),
Node-Vtable, Host-API und dem `AudRenderRequest` des Headless Hosts
(plugin-002); seit 0.3 mit den
Ergebniscodes cycle, format, lookahead, capacity, retired und overload für
den Graphen, seit 0.4 mit cancelled und underflow; in Major 0 müssen die
Minors exakt übereinstimmen, ab 1.0 akzeptiert eine Engine ältere Minors),
`aud_clock.h`, `aud_time_filter.h` (Sample-zu-Hostzeit-Filter),
`aud_transport.h` (Beat-, Sample- und Hostzeit-Umrechnung), `aud_ump.h`
(UMP-Felder inklusive Per-Note-Controller), `aud_spsc_queue.hpp`,
`aud_param_ramp.hpp`, `aud_node_base.hpp` (Blockteilung an Event-Offsets
in Subranges von 16 Frames) und `aud_fixed_block_adapter.hpp`.

Seit 0.4 (Ticket 25, lifecycle-002, osc-002) bietet die Host-API
Worker-Tasks (`post_task`, auch aus dem Audio-Thread), Loads mit IDs,
Fortschritt und Abbruch, Sample-Caches unter dem Budget des Prozesses
(`register_cache`, `cache_changed`, `cache_budget`), Reports eines Nodes
pro Block und `emit_message`; ein Node mit `AUD_NODE_CAP_MESSAGES` nimmt
OSC-Nachrichten als `AUD_EVENT_MESSAGE`-Events an (`AudMessage`,
`AudMessageArg`). Die Thread-Tags `[worker]` und `[any thread]` sagen, was
auf den Workern läuft und was jeder Thread aufrufen darf. Ticket 37
ergänzt `AUD_NODE_CAP_PASSES_EVENTS` innerhalb von 0.4, da eine Engine
ohne es das Flag ignoriert: Ein Node damit, etwa ein MIDI-Thru oder ein
Channel-Split, gibt seine Noten unverändert bis auf ihren Port weiter
(`AudNodeCapabilities.passesEvents`); die Nodes dahinter schließen sie bei
einem Stopp oder einem Prepare, und die Engine schließt die, die er aus dem
Graphen gab, mit je einem Note-Off.

Die native Bibliothek exportiert ABI-Version und Strukturgrößen, die
Handle-APIs von Filter, Umrechnung, Ramp und Adapter und registriert den
Referenzknoten `aud.core.gain` über `aud_audio_core_register`.

## Dart-API

Siehe das Beispiel in [README.md](README.md): `AudAbi`, `AudTimestamp`,
`AudTransportSnapshot`, `AudTimeFilter`, `AudEvent` (aus
`aud_midi_standard`-Nachrichten), `AudNodeDescriptor`, `AudNodePreset`
(JSON-Schema in `doc/schemas`), `AudOscAddress`, `AudOscMessage`,
`AudCommand`, `AudMessageCommand`, `AudOscRouter` und `AudOscAdapter`.
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

`package:aud_audio_core/aud_audio_core_bindings.dart` exportiert die
rohen ffigen-Bindings mit den nativen Strukturen für Hosts und Node-Tests.

## Notices

`node scripts/check-notices.js` prüft die Notices-Konvention von
license-001, siehe [doc/guides/notices-guide.md](doc/guides/notices-guide.md).

Die Bindings neu erzeugen mit `dart run ffigen --config ffigen.yaml`.
