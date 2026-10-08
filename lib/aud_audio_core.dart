// @license
// Copyright (c) Audanika. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

/// Core of the Audanika Audio Engine: the C ABI, buffer and event formats,
/// node contracts, timing contract and OSC message model.
library;

export 'src/aud_abi.dart';
export 'src/aud_audio_core_bindings_generated.dart'
    hide
        AudBusDescriptor,
        AudEvent,
        AudEventPortDescriptor,
        AudNodeDescriptor,
        AudParamDescriptor,
        AudStreamTime,
        AudStringKeyDescriptor,
        AudTimestamp,
        AudTransportRequest,
        AudTransportSegment,
        AudTransportSnapshot;
export 'src/aud_audio_core_version.dart';
export 'src/aud_command.dart';
export 'src/aud_core_exception.dart';
export 'src/aud_core_gain.dart';
export 'src/aud_event.dart';
export 'src/aud_fixed_block_adapter.dart';
export 'src/aud_node_descriptor.dart';
export 'src/aud_node_preset.dart';
export 'src/aud_osc_adapter.dart';
export 'src/aud_osc_address.dart';
export 'src/aud_osc_message.dart';
export 'src/aud_param_ramp.dart';
export 'src/aud_time.dart';
export 'src/aud_time_filter.dart';
export 'src/aud_transport.dart';
export 'src/aud_ump.dart';
