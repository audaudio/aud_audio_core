// @license
// Copyright (c) Audanika. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import 'aud_audio_core_bindings_generated.dart' as bindings;
import 'aud_event.dart';
import 'aud_node_descriptor.dart';
import 'aud_time.dart';
import 'aud_transport.dart';

// The conversions between the platform-neutral contracts and the structs of
// the ABI. They live apart from the contracts so that no dart:ffi reaches a
// web build (web-001): a native struct turns into its contract with
// `toDart()`, a contract writes itself into a struct with `writeTo` or
// `writeToRef`.

String _text(Pointer<Char> pointer) =>
    pointer == nullptr ? '' : pointer.cast<Utf8>().toDartString();

// #############################################################################
/// Reads an [AudEvent] from its native struct.
extension AudNativeEventToDart on bindings.AudEvent {
  /// The event of the struct.
  AudEvent toDart() => AudEvent.fromWords(
    type: type,
    words: [for (var i = 0; i < 4; i++) words[i]],
    sampleOffset: sample_offset,
    port: port,
    flags: flags,
  );
}

/// Writes an [AudEvent] into its native struct.
extension AudEventToNative on AudEvent {
  /// Writes the event into the struct at [pointer].
  void writeTo(Pointer<bindings.AudEvent> pointer) => writeToRef(pointer.ref);

  /// Writes the event into a struct reference.
  void writeToRef(bindings.AudEvent ref) {
    ref
      ..struct_size = sizeOf<bindings.AudEvent>()
      ..type = type
      ..sample_offset = sampleOffset
      ..port = port
      ..flags = flags;
    final payload = words;
    for (var i = 0; i < 4; i++) {
      ref.words[i] = payload[i];
    }
  }
}

// #############################################################################
/// Reads an [AudTimestamp] from its native struct.
extension AudNativeTimestampToDart on bindings.AudTimestamp {
  /// The timestamp of the struct.
  AudTimestamp toDart() =>
      AudTimestamp.fromCodes(domain: domain, value: value, source: source);
}

/// Writes an [AudTimestamp] into its native struct.
extension AudTimestampToNative on AudTimestamp {
  /// Writes the timestamp into the struct at [pointer].
  void writeTo(Pointer<bindings.AudTimestamp> pointer) =>
      writeToRef(pointer.ref);

  /// Writes the timestamp into a struct reference.
  void writeToRef(bindings.AudTimestamp ref) {
    ref
      ..struct_size = sizeOf<bindings.AudTimestamp>()
      ..domain = domain.code
      ..source = source.code
      ..flags = 0
      ..value = value;
  }
}

// #############################################################################
/// Reads an [AudStreamTime] from its native struct.
extension AudNativeStreamTimeToDart on bindings.AudStreamTime {
  /// The time of the struct.
  AudStreamTime toDart() => AudStreamTime(
    frames: frames,
    sampleRate: sample_rate,
    samplePosition: sample_position,
    hostTimeNs: host_time_ns,
    hostTimeSource: AudTimeSource.fromCode(host_time_source),
    hostTimeAccuracyNs: host_time_accuracy_ns,
    outputLatencyFrames: output_latency_frames,
    inputLatencyFrames: input_latency_frames,
  );
}

/// Writes an [AudStreamTime] into its native struct.
extension AudStreamTimeToNative on AudStreamTime {
  /// Writes the time into the struct at [pointer].
  void writeTo(Pointer<bindings.AudStreamTime> pointer) =>
      writeToRef(pointer.ref);

  /// Writes the time into a struct reference.
  void writeToRef(bindings.AudStreamTime ref) {
    ref
      ..struct_size = sizeOf<bindings.AudStreamTime>()
      ..frames = frames
      ..sample_rate = sampleRate
      ..sample_position = samplePosition
      ..host_time_ns = hostTimeNs
      ..host_time_source = hostTimeSource.code
      ..reserved = 0
      ..host_time_accuracy_ns = hostTimeAccuracyNs
      ..output_latency_frames = outputLatencyFrames
      ..input_latency_frames = inputLatencyFrames;
  }
}

// #############################################################################
/// Reads an [AudTransportSegment] from its native struct.
extension AudNativeTransportSegmentToDart on bindings.AudTransportSegment {
  /// The segment of the struct.
  AudTransportSegment toDart() => AudTransportSegment(
    sampleOffset: sample_offset,
    frames: frames,
    beatTicks: beat,
    tempo: tempo,
    tempoIncrement: tempo_increment,
    playing: flags & bindings.AUD_SEGMENT_PLAYING != 0,
    looping: flags & bindings.AUD_SEGMENT_LOOPING != 0,
    seek: flags & bindings.AUD_SEGMENT_SEEK != 0,
    discontinuity: flags & bindings.AUD_SEGMENT_DISCONTINUITY != 0,
    barStartTicks: bar_start,
    timeSignatureNumerator: time_signature_numerator,
    timeSignatureDenominator: time_signature_denominator,
    loopStartTicks: loop_start,
    loopEndTicks: loop_end,
  );
}

/// Writes an [AudTransportSegment] into its native struct.
extension AudTransportSegmentToNative on AudTransportSegment {
  /// Writes the segment into a struct reference.
  void writeToRef(bindings.AudTransportSegment ref) {
    ref
      ..struct_size = sizeOf<bindings.AudTransportSegment>()
      ..sample_offset = sampleOffset
      ..frames = frames
      ..flags = flags
      ..beat = beatTicks
      ..tempo = tempo
      ..tempo_increment = tempoIncrement
      ..bar_start = barStartTicks
      ..time_signature_numerator = timeSignatureNumerator
      ..time_signature_denominator = timeSignatureDenominator
      ..loop_start = loopStartTicks
      ..loop_end = loopEndTicks;
  }
}

/// Reads an [AudTransportSnapshot] from its native struct.
extension AudNativeTransportSnapshotToDart on bindings.AudTransportSnapshot {
  /// The snapshot of the struct.
  AudTransportSnapshot toDart() => AudTransportSnapshot(
    time: time.toDart(),
    capabilities: AudTransportCapabilities.fromFlags(capabilities),
    segments: [for (var i = 0; i < num_segments; i++) segments[i].toDart()],
  );
}

// #############################################################################
/// Reads an [AudTransportRequest] from its native struct.
extension AudNativeTransportRequestToDart on bindings.AudTransportRequest {
  /// The request of the struct.
  AudTransportRequest toDart() => AudTransportRequest(
    type: AudTransportRequestType.fromCode(type),
    at: at.toDart(),
    beatTicks: beat,
    beatEndTicks: beat_end,
    value: value,
    numerator: numerator,
    denominator: denominator,
  );
}

/// Writes an [AudTransportRequest] into its native struct.
extension AudTransportRequestToNative on AudTransportRequest {
  /// Writes the request into the struct at [pointer].
  void writeTo(Pointer<bindings.AudTransportRequest> pointer) {
    final ref = pointer.ref
      ..struct_size = sizeOf<bindings.AudTransportRequest>()
      ..type = type.code
      ..beat = beatTicks
      ..beat_end = beatEndTicks
      ..value = value
      ..numerator = numerator
      ..denominator = denominator;
    at.writeToRef(ref.at);
  }
}

// #############################################################################
/// Reads an [AudBusDescriptor] from its native struct.
extension AudNativeBusDescriptorToDart on bindings.AudBusDescriptor {
  /// The bus of the struct.
  AudBusDescriptor toDart() => AudBusDescriptor(
    id: _text(id),
    name: _text(name),
    main: flags & bindings.AUD_BUS_MAIN != 0,
    sidechain: flags & bindings.AUD_BUS_SIDECHAIN != 0,
    optional: flags & bindings.AUD_BUS_OPTIONAL != 0,
    minChannels: min_channels,
    maxChannels: max_channels,
    defaultChannels: default_channels,
  );
}

/// Reads an [AudEventPortDescriptor] from its native struct.
extension AudNativeEventPortDescriptorToDart
    on bindings.AudEventPortDescriptor {
  /// The port of the struct.
  AudEventPortDescriptor toDart() => AudEventPortDescriptor(
    id: _text(id),
    name: _text(name),
    midi: flags & bindings.AUD_EVENT_PORT_MIDI != 0,
    control: flags & bindings.AUD_EVENT_PORT_CONTROL != 0,
  );
}

/// Reads an [AudParamDescriptor] from its native struct.
extension AudNativeParamDescriptorToDart on bindings.AudParamDescriptor {
  /// The parameter of the struct.
  AudParamDescriptor toDart() => AudParamDescriptor(
    id: _text(id),
    name: _text(name),
    unit: _text(unit),
    min: min_value,
    max: max_value,
    defaultValue: default_value,
    automatable: flags & bindings.AUD_PARAM_AUTOMATABLE != 0,
    ramped: flags & bindings.AUD_PARAM_RAMPED != 0,
    stepped: flags & bindings.AUD_PARAM_STEPPED != 0,
    logarithmic: flags & bindings.AUD_PARAM_LOGARITHMIC != 0,
    boolean: flags & bindings.AUD_PARAM_BOOLEAN != 0,
    hidden: flags & bindings.AUD_PARAM_HIDDEN != 0,
    steps: steps,
  );
}

/// Reads an [AudStringKeyDescriptor] from its native struct.
extension AudNativeStringKeyDescriptorToDart
    on bindings.AudStringKeyDescriptor {
  /// The key of the struct.
  AudStringKeyDescriptor toDart() =>
      AudStringKeyDescriptor(key: key, id: _text(id), name: _text(name));
}

/// Reads an [AudNodeDescriptor] from its native struct.
extension AudNativeNodeDescriptorToDart on bindings.AudNodeDescriptor {
  /// The descriptor of the struct.
  AudNodeDescriptor toDart() => AudNodeDescriptor(
    typeId: _text(type_id),
    name: _text(name),
    vendor: _text(vendor),
    version: version,
    abiMajor: abi_major,
    abiMinor: abi_minor,
    capabilities: AudNodeCapabilities.fromFlags(capabilities),
    stateVersion: state_version,
    inputBuses: [
      for (var i = 0; i < num_input_buses; i++) input_buses[i].toDart(),
    ],
    outputBuses: [
      for (var i = 0; i < num_output_buses; i++) output_buses[i].toDart(),
    ],
    eventInputs: [
      for (var i = 0; i < num_event_inputs; i++) event_inputs[i].toDart(),
    ],
    eventOutputs: [
      for (var i = 0; i < num_event_outputs; i++) event_outputs[i].toDart(),
    ],
    params: [for (var i = 0; i < num_params; i++) params[i].toDart()],
    stringKeys: [
      for (var i = 0; i < num_string_keys; i++) string_keys[i].toDart(),
    ],
  );
}
