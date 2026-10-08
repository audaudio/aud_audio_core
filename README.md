# aud_audio_core

Core of the Audanika Audio Engine: the C ABI, buffer and event formats, node contracts, timing contract and OSC message model.

Part of the Audanika Audio Engine; planned in [aud_audio_pm](https://github.com/audaudio/aud_audio_pm).

## What the package holds (spike state, ticket 5)

- `src/aud_abi.h` — the C ABI between the engine and the DSP packages:
  sized structs, the ABI version `AUD_ABI_VERSION_MAJOR.MINOR`, result
  codes, node capabilities, thread affinity tags, `AudEvent`,
  `AudParamDescriptor`, `AudProcessContext` (planar buses),
  `AudNodeVTable`, `AudNodeDescriptor`, `AudHostApi` (registration,
  allocator, log) and `AudRenderCallback`, the render interface a host
  uses to pull blocks from the engine.
- `src/aud_clock.h` — `aud_clock_now_ns()`, the monotonic host clock.
- `src/aud_spsc_queue.hpp` — a lock-free single-producer single-consumer
  queue with a fixed capacity.
- The headers are included by the other packages through their build
  hooks; nothing links the core. The native library only reports the ABI
  version and the struct sizes.

## Dart API

```dart
import 'package:aud_audio_core/aud_audio_core.dart';

AudAbi.major;                 // the ABI version of the Dart side
AudAbi.nativeMajor;           // the ABI version of the native core
AudAbi.dartStructSizes;       // sizes of the ABI structs in Dart ...
AudAbi.nativeStructSizes;     // ... and in C; equal when the layouts agree
AudAbi.resultName(AUD_ERROR_QUEUE_FULL); // 'AUD_ERROR_QUEUE_FULL'
AudAbi.isCompatible(packageMajor: 0, packageMinor: 1, engineMajor: 0, engineMinor: 1);
```

The generated bindings export the ABI structs (`AudHostApi`,
`AudNodeDescriptor`, ...) and the constants (`AUD_OK`, `AUD_NODE_CAP_*`,
`AUD_EVENT_*`) for tests and for packages that build hosts or nodes.

Regenerate the bindings with `dart run ffigen --config ffigen.yaml`.
