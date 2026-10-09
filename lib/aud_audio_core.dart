// @license
// Copyright (c) Audanika. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.
/// The platform-neutral contracts of the Audanika Audio Engine: the ABI
/// constants and version, commands, events, node descriptors and presets,
/// time, transport and the OSC model. Imports no `dart:ffi`, so it compiles
/// for the web (web-001); `aud_audio_core_ffi.dart` adds the native parts.
library;

export 'src/aud_abi.dart';
export 'src/aud_abi_constants.dart';
export 'src/aud_audio_core_version.dart';
export 'src/aud_clock.dart';
export 'src/aud_command.dart';
export 'src/aud_core_exception.dart';
export 'src/aud_event.dart';
export 'src/aud_node_descriptor.dart';
export 'src/aud_node_preset.dart';
export 'src/aud_osc_adapter.dart';
export 'src/aud_osc_address.dart';
export 'src/aud_osc_message.dart';
export 'src/aud_time.dart';
export 'src/aud_transport.dart';
export 'src/aud_ump.dart';
