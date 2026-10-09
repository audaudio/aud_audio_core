// @license
// Copyright (c) Audanika. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.
/// The native parts of the core on top of `aud_audio_core.dart`: the
/// checks against the native library, the conversions to and from the ABI
/// structs, and the native helpers (gain node, parameter ramp, time filter,
/// fixed-block adapter, transport snapshot). The raw bindings are in
/// `aud_audio_core_bindings.dart`.
library;

export 'aud_audio_core.dart';
export 'src/aud_abi_native.dart';
export 'src/aud_core_gain.dart';
export 'src/aud_fixed_block_adapter.dart';
export 'src/aud_native_conversions.dart';
export 'src/aud_native_transport_snapshot.dart';
export 'src/aud_param_ramp.dart';
export 'src/aud_time_filter.dart';
