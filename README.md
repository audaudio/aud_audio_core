# aud_audio_core

Core of the Audanika Audio Engine: the C ABI, buffer and event formats, node contracts, timing contract and OSC message model.

Part of the Audanika Audio Engine; planned in [aud_audio_pm](https://github.com/audaudio/aud_audio_pm).

## What the package holds (ABI 0.3, tickets 18 and 19)

Header-only C and C++ in `src/`, included by every package of the family
and never linked:

- `aud_abi.h` — the versioned C ABI (abi-001): sized structs, result codes
  (since 0.3 also cycle, format, lookahead, capacity, retired and overload
  for the graph), capabilities, thread affinity tags, bus, event port,
  parameter and string
  key descriptors, `AudEvent` (UMP, control and parameter events),
  `AudProcessContext` with planar buses, `AudTimestamp` with the domains
  immediate, sample, host and beat, `AudStreamTime`, the transport segments,
  snapshot, requests and provider vtable (time-001), the node vtable with
  reset reasons, latency, tail and state blobs, `AudHostApi` and the
  `AudRenderRequest` of the headless host (plugin-002). In major 0 the
  minors must match exactly; from 1.0 on an engine accepts older minors.
- `aud_clock.h` — the monotonic host clock.
- `aud_time_filter.h` — the sample-to-host-time filter with its reset rules.
- `aud_transport.h` — beat, sample and host time conversions over a snapshot.
- `aud_ump.h` — Universal MIDI Packet fields, per-note controllers included.
- `aud_spsc_queue.hpp` — the lock-free single-producer queue (interop-002).
- `aud_param_ramp.hpp`, `aud_node_base.hpp`, `aud_fixed_block_adapter.hpp`
  — the ramp, the node base class that splits blocks at event offsets in
  sub-ranges of 16 frames (graph-002), and the fixed-block adapter.

The native library exports the ABI version and struct sizes, handle APIs
of the filter, the conversions, the ramp and the adapter, and registers the
reference node `aud.core.gain` through `aud_audio_core_register`.

## Dart API

```dart
import 'package:aud_audio_core/aud_audio_core.dart';

AudAbi.major;                              // 0; AudAbi.minor is 3
AudAbi.dartStructSizes == AudAbi.nativeStructSizes;

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

final preset = AudNodePreset.defaults(descriptor);  // JSON schema in doc/schemas
preset.validate(descriptor);                        // [] when it fits
```

`package:aud_audio_core/aud_audio_core_bindings.dart` exports the raw
ffigen bindings with the native structs for hosts and node tests.

## Notices

`node scripts/check-notices.js` checks the notices convention of
license-001; see [doc/guides/notices-guide.md](doc/guides/notices-guide.md).

Regenerate the bindings with `dart run ffigen --config ffigen.yaml`.
