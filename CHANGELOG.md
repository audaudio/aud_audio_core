# Changelog

## Unreleased

### Added

- Add ABI 0.4 with tasks, loads, caches and messages

- AudHostApi minor 4: post_task, begin_load, load_progress, end_load, load_cancelled, register_cache, unregister_cache, cache_changed, cache_budget, report and emit_message

- AUD_EVENT_MESSAGE with AudMessage and AudMessageArg, AUD_NODE_CAP_MESSAGES, AUD_ERROR_CANCELLED and AUD_ERROR_UNDERFLOW, the OSC tags h, d, s and b

- AudTask and AudCacheVTable for the worker threads and the sample cache of lifecycle-001

- The engine reads get_tail after prepare and at every commit; end_load takes a message for a load that ended well

- AudMessageCommand, the message route /graph/<g>/node/<n>/msg and AudOscRouter.resolveMessage

- AudNodeCapabilities.messages and the new struct sizes and result names

- Add the thread and lifetime rules of ABI 0.4

- aud_abi.h: the thread tags [worker] and [any thread]; AudTask.run, trim, post_task, cache_changed, the load calls, alloc, free and log name the threads the engine calls them on
- aud_abi.h: when tasks run, how loads end, how long caches stay registered, where report and emit_message work and what emit_message copies and drops
- Cite lifecycle-002 and osc-002 where they decided: aud_abi.h, the Dart docs and the message tests
- README.md names the result codes of 0.4, the message events, the argument tags and the message route; README.de.md catches up with ABI 0.4
- index.jsonc names the message events and AudMessageCommand
- The capabilities test compares the whole JSON list

## 0.4.0 - 2026-10-09

### Changed

- Split the Dart API into neutral and ffi parts
- Describe the neutral and ffi APIs in the README

## 0.3.0 - 2026-10-08

### Changed

- Move the core to ABI 0.3 for the audio graph (ticket 19, step S2)
- Add the result codes cycle, format, lookahead, capacity, retired and
overload with their Dart names
- Name the result codes of 0.3 in the README
- Describe ABI 0.3 in the changelog

## 0.2.0 - 2026-10-08

### Added

- Define the core contracts of ABI 0.2 (ticket 18, step S1)
- Versioned C ABI with descriptors, events, timing and transport contracts
- Header-only time filter, transport conversions and UMP helpers
- Node base class, parameter ramp and fixed-block adapter in C++
- Dart contracts: time, transport, events, descriptors, presets, OSC
- Typed commands with the OSC router and adapter
- Reference node aud.core.gain registered by the native core
- Notices convention with scripts/check-notices.js

## 0.1.0 - 2026-10-08

### Changed

- Seed the C ABI and the Dart contracts

## 0.0.2 - 2026-10-08

### Added

- Initial boilerplate

### Changed

- Record the gg commit state
- Set up GitHub repo settings and branch rules
- Update dev dependencies
