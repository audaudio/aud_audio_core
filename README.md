# aud_audio_core

English | [Deutsch](README.de.md)

[![CI](https://github.com/audaudio/aud_audio_core/actions/workflows/quick_check.yaml/badge.svg)](https://github.com/audaudio/aud_audio_core/actions/workflows/quick_check.yaml)

Core of the Audanika Audio Engine: the C ABI, buffer and event formats, node contracts, timing contract and OSC message model.

Part of the Audanika Audio Engine; planned in
[aud_audio_pm](https://github.com/audaudio/aud_audio_pm). The Dart library
`aud_audio_core.dart` is platform-neutral and compiles for the web; the
native parts in `aud_audio_core_ffi.dart` need a native platform.

## Motivation

Every package of the Audanika Audio Engine — the graph, the device IO, the
MIDI bridge and the DSP nodes — has to agree on the same buffers, events,
timestamps and node lifecycle. This package holds that contract once:

- As header-only C and C++ in `src/`, included by every package of the
  family and never linked, so that a node built against the ABI runs in
  every engine of the same ABI minor
- As Dart types that mirror the ABI, so that hosts, tools and tests speak
  the same language as the native code
- With a versioned ABI: in major 0 the minors must match exactly, from 1.0
  on an engine accepts older minors

## Installation

The package is not published to pub.dev. Add it as a git dependency,
resolved by its version tag:

```yaml
dependencies:
  aud_audio_core:
    git:
      url: git@github.com:audaudio/aud_audio_core.git
      tag_pattern: "{{version}}"
    version: ^0.5.4
```

Then run `dart pub get`. The native library is built by the build hook of
the package when the app is built.

## Usage

The example in `example/` shows the ABI version of the Dart side and of the
native core and checks that both agree on the sizes of the ABI structs:

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

It prints:

```text
ABI version (Dart): 0.4
ABI version (native): 0.4
Struct sizes agree: true
```

## Limitations

- The package holds contracts and helpers, not an engine: rendering,
  scheduling and transport live in `aud_audio_graph`, the device IO in
  `aud_audio_io`
- In major 0 the ABI minors of a node and an engine must match exactly
- `aud_audio_core_ffi.dart`, the bindings and the reference node
  `aud.core.gain` need a native platform; only `aud_audio_core.dart`
  compiles for the web
- The native library is header-only for its consumers; it exports the ABI
  version, the struct sizes and the handle APIs of the helpers, nothing
  else

## Documentation

- [Notices guide](doc/guides/notices-guide.md) — the notices convention
  that `node scripts/check-notices.js` checks
- [JSON schema of a node preset](doc/schemas/aud_node_preset.schema.json)
- [Blog](doc/blog) — one post per change
- [aud_audio_pm](https://github.com/audaudio/aud_audio_pm) — the plans and
  decisions of the Audanika Audio Engine

## How it works

### What the package holds (ABI 0.4, tickets 18, 19, 25 and 37)

Header-only C and C++ in `src/`, included by every package of the family
and never linked:

- `aud_abi.h` — the versioned C ABI (abi-001): sized structs, result codes
  (since 0.3 also cycle, format, lookahead, capacity, retired and overload
  for the graph, since 0.4 cancelled and underflow), capabilities, thread
  affinity tags, bus, event port, parameter and string key descriptors,
  `AudEvent` (UMP, control, parameter and message events), `AudMessage`
  with the OSC 1.1 argument tags i, f, h, d, s, b, T, F, N and I,
  `AudProcessContext` with planar buses, `AudTimestamp` with the domains
  immediate, sample, host and beat, `AudStreamTime`, the transport segments,
  snapshot, requests and provider vtable (time-001), the node vtable with
  reset reasons, latency, tail and state blobs, `AudHostApi` and the
  `AudRenderRequest` of the headless host (plugin-002). In major 0 the
  minors must match exactly; from 1.0 on an engine accepts older minors.
  Since 0.4 (ticket 25, lifecycle-002, osc-002) the host api offers worker
  tasks (`post_task`, also from the audio thread), loads with ids,
  progress and cancellation, sample caches under the budget of the
  process (`register_cache`, `cache_changed`, `cache_budget`), per-block
  reports of a node and `emit_message`; a node with
  `AUD_NODE_CAP_MESSAGES` takes OSC messages as `AUD_EVENT_MESSAGE` events
  (`AudMessage`, `AudMessageArg`). The thread tags `[worker]` and
  `[any thread]` say what runs on the workers and what every thread may
  call. Ticket 37 adds `AUD_NODE_CAP_PASSES_EVENTS` within 0.4, since an
  engine without it ignores the flag: a node with it, e.g. a MIDI thru or
  a channel split, passes its notes on unchanged but for their port
  (`AudNodeCapabilities.passesEvents`); the nodes behind it close them on
  a stop or a prepare, and the engine closes those it handed out of the
  graph, one note off each.
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

### Dart API

`aud_audio_core.dart` is platform-neutral and compiles for the web
(web-001); `aud_audio_core_ffi.dart` adds the native parts: `AudAbiNative`,
the conversions from and to the ABI structs (`native.toDart()`,
`event.writeTo(pointer)`), `AudTimeFilter`, `AudParamRamp`,
`AudFixedBlockAdapter`, `AudCoreGain` and `AudNativeTransportSnapshot`.

A node with `AudNodeCapabilities.messages` gets the message route
`AudOscAddress.message` (`/graph/<g>/node/<n>/msg`, osc-002):
`AudOscRouter.resolveMessage` finds the `AudMessageTarget`s of an address
below it and the path that remains, and `AudOscAdapter` turns the message
into an `AudMessageCommand`.

An overview of the API, with a transport `snapshot` and a node
`descriptor` from the caller:

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

`package:aud_audio_core/aud_audio_core_bindings.dart` exports the raw
ffigen bindings with the native structs for hosts and node tests.

## Status

Version 0.5.4 on ABI 0.4. Before 1.0 — the API and the ABI may change
between minor versions.

## Contributing

- Follow the [develop guide](doc/guides/develop-guide.md), the
  [code guide](doc/guides/code-guide.md) and the
  [test guide](doc/guides/test-guide.md)
- Regenerate the bindings with `dart run ffigen --config ffigen.yaml`
- Check the notices convention with `node scripts/check-notices.js`, see
  the [notices guide](doc/guides/notices-guide.md)

## License

MIT — see [LICENSE](LICENSE).
