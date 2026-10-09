# Changelog

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
