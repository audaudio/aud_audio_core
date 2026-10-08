// @license
// Copyright (c) Audanika. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:ffi';
import 'dart:typed_data';

import 'package:aud_midi_standard/aud_midi_standard.dart';

import 'aud_audio_core_bindings_generated.dart' as bindings;
import 'aud_ump.dart';

// #############################################################################
/// The impulse argument of a control event, the OSC `I` type.
final class AudImpulse {
  const AudImpulse._();

  /// The impulse.
  static const AudImpulse instance = AudImpulse._();

  @override
  String toString() => 'AudImpulse';
}

// #############################################################################
/// An event inside a block: `AudEvent` of the ABI, a UMP, a control or a
/// parameter event at a sample offset on an event port of a node.
sealed class AudEvent {
  const AudEvent({this.sampleOffset = 0, this.port = 0, this.live = false});

  /// An event from its native struct.
  factory AudEvent.fromNative(bindings.AudEvent native) {
    final words = [for (var i = 0; i < 4; i++) native.words[i]];
    final live = native.flags & bindings.AUD_EVENT_FLAG_LIVE != 0;
    return switch (native.type) {
      bindings.AUD_EVENT_UMP => AudUmpEvent(
        Ump(words.take(AudUmp.wordCount(words[0]))),
        sampleOffset: native.sample_offset,
        port: native.port,
        live: live,
      ),
      bindings.AUD_EVENT_CONTROL => AudControlEvent(
        control: words[0],
        value: AudControlEvent.valueOf(typeTag: words[1], bits: words[2]),
        sampleOffset: native.sample_offset,
        port: native.port,
        live: live,
      ),
      bindings.AUD_EVENT_PARAM => AudParamEvent(
        paramIndex: words[0],
        value: floatOfBits(words[1]),
        rampFrames: words[2],
        sampleOffset: native.sample_offset,
        port: native.port,
        live: live,
      ),
      _ => throw ArgumentError.value(native.type, 'type', 'Unknown event'),
    };
  }

  /// An event from [toJson].
  factory AudEvent.fromJson(Map<String, Object?> json) {
    final sampleOffset = (json['sampleOffset'] as num?)?.toInt() ?? 0;
    final port = (json['port'] as num?)?.toInt() ?? 0;
    final live = json['live'] == true;
    return switch (json['type']) {
      'ump' => AudUmpEvent(
        Ump.fromHex(json['packet']! as String),
        sampleOffset: sampleOffset,
        port: port,
        live: live,
      ),
      'control' => AudControlEvent(
        control: (json['control']! as num).toInt(),
        value: AudControlEvent.valueFromJson(json['value']),
        sampleOffset: sampleOffset,
        port: port,
        live: live,
      ),
      'param' => AudParamEvent(
        paramIndex: (json['paramIndex']! as num).toInt(),
        value: (json['value']! as num).toDouble(),
        rampFrames: (json['rampFrames'] as num?)?.toInt() ?? 0,
        sampleOffset: sampleOffset,
        port: port,
        live: live,
      ),
      _ => throw FormatException('Unknown event type', json),
    };
  }

  // ...........................................................................
  /// The offset inside the block.
  final int sampleOffset;

  /// The event input of the node.
  final int port;

  /// Whether the event is live (MIDI input, UI): delivered as early as
  /// possible.
  final bool live;

  /// The `AUD_EVENT_*` type.
  int get type;

  /// The four payload words of the native struct.
  List<int> get words;

  // ...........................................................................
  /// Writes the event into its native struct.
  void writeTo(Pointer<bindings.AudEvent> pointer) => writeToRef(pointer.ref);

  /// Writes the event into a native struct reference.
  void writeToRef(bindings.AudEvent ref) {
    ref
      ..struct_size = sizeOf<bindings.AudEvent>()
      ..type = type
      ..sample_offset = sampleOffset
      ..port = port
      ..flags = live ? bindings.AUD_EVENT_FLAG_LIVE : 0;
    final payload = words;
    for (var i = 0; i < 4; i++) {
      ref.words[i] = payload[i];
    }
  }

  /// The event as JSON.
  Map<String, Object?> toJson();

  Map<String, Object?> _baseJson(String type) => {
    'type': type,
    'sampleOffset': sampleOffset,
    'port': port,
    if (live) 'live': true,
  };

  // ...........................................................................
  /// The IEEE 754 bits of a 32-bit float.
  static int bitsOfFloat(double value) {
    final data = ByteData(4)..setFloat32(0, value, Endian.little);
    return data.getUint32(0, Endian.little);
  }

  /// The 32-bit float with the IEEE 754 [bits].
  static double floatOfBits(int bits) {
    final data = ByteData(4)..setUint32(0, bits & 0xFFFFFFFF, Endian.little);
    return data.getFloat32(0, Endian.little);
  }
}

// #############################################################################
/// A Universal MIDI Packet on an event port.
final class AudUmpEvent extends AudEvent {
  /// Creates an event carrying [packet].
  const AudUmpEvent(this.packet, {super.sampleOffset, super.port, super.live});

  /// One event per packet of [message] of `aud_midi_standard` on [group].
  static List<AudUmpEvent> fromMessage(
    MidiMessage message, {
    int group = 0,
    int sampleOffset = 0,
    int port = 0,
    bool live = false,
  }) => [
    for (final packet in message.toUmp(group: group))
      AudUmpEvent(packet, sampleOffset: sampleOffset, port: port, live: live),
  ];

  // ...........................................................................
  /// The packet.
  final Ump packet;

  @override
  int get type => bindings.AUD_EVENT_UMP;

  @override
  List<int> get words => [
    for (var i = 0; i < 4; i++) i < packet.words.length ? packet.words[i] : 0,
  ];

  /// The message of the packet, or null when the packet is only a part of
  /// a longer message.
  MidiMessage? get message {
    final decoded = UmpDecoder().add(packet.words);
    return decoded.isEmpty ? null : decoded.single.message;
  }

  /// Whether the packet is a note on with a velocity above zero.
  bool get isNoteOn => AudUmp.isNoteOn(words[0], words[1]);

  /// Whether the packet is a note off.
  bool get isNoteOff => AudUmp.isNoteOff(words[0], words[1]);

  // ...........................................................................
  @override
  Map<String, Object?> toJson() => {
    ..._baseJson('ump'),
    'packet': packet.toHex(),
  };

  @override
  bool operator ==(Object other) =>
      other is AudUmpEvent &&
      other.packet == packet &&
      other.sampleOffset == sampleOffset &&
      other.port == port &&
      other.live == live;

  @override
  int get hashCode => Object.hash(packet, sampleOffset, port, live);

  @override
  String toString() => 'AudUmpEvent(${toJson()})';
}

// #############################################################################
/// A numeric control message on an event port: a control id with one
/// OSC-typed argument — an int, a double, a bool, null or [AudImpulse].
final class AudControlEvent extends AudEvent {
  /// Creates a control event of [control] with [value].
  AudControlEvent({
    required this.control,
    required this.value,
    super.sampleOffset,
    super.port,
    super.live,
  }) {
    typeTagOf(value);
  }

  /// The OSC type tag of [value] as the ABI carries it.
  static int typeTagOf(Object? value) => switch (value) {
    int() => bindings.AUD_ARG_INT32,
    double() => bindings.AUD_ARG_FLOAT,
    true => bindings.AUD_ARG_TRUE,
    false => bindings.AUD_ARG_FALSE,
    null => bindings.AUD_ARG_NIL,
    AudImpulse() => bindings.AUD_ARG_IMPULSE,
    _ => throw ArgumentError.value(value, 'value', 'Not a control argument'),
  };

  /// The value with [typeTag] and payload [bits].
  static Object? valueOf({required int typeTag, required int bits}) =>
      switch (typeTag) {
        bindings.AUD_ARG_INT32 => bits.toSigned(32),
        bindings.AUD_ARG_FLOAT => AudEvent.floatOfBits(bits),
        bindings.AUD_ARG_TRUE => true,
        bindings.AUD_ARG_FALSE => false,
        bindings.AUD_ARG_NIL => null,
        bindings.AUD_ARG_IMPULSE => AudImpulse.instance,
        _ => throw ArgumentError.value(typeTag, 'typeTag', 'Unknown tag'),
      };

  /// The value from its JSON form of [valueToJson].
  static Object? valueFromJson(Object? json) => switch (json) {
    {'impulse': true} => AudImpulse.instance,
    {'int': final num value} => value.toInt(),
    {'float': final num value} => value.toDouble(),
    bool() => json,
    null => null,
    _ => throw FormatException('Not a control value', json),
  };

  /// The JSON form of a control [value].
  static Object? valueToJson(Object? value) => switch (value) {
    int() => {'int': value},
    double() => {'float': value},
    AudImpulse() => {'impulse': true},
    _ => value,
  };

  // ...........................................................................
  /// The control id.
  final int control;

  /// The argument: an int, a double, a bool, null or [AudImpulse].
  final Object? value;

  /// The OSC type tag of the argument.
  int get typeTag => typeTagOf(value);

  @override
  int get type => bindings.AUD_EVENT_CONTROL;

  @override
  List<int> get words => [
    control,
    typeTag,
    switch (value) {
      final int v => v & 0xFFFFFFFF,
      final double v => AudEvent.bitsOfFloat(v),
      _ => 0,
    },
    0,
  ];

  // ...........................................................................
  @override
  Map<String, Object?> toJson() => {
    ..._baseJson('control'),
    'control': control,
    'value': valueToJson(value),
  };

  @override
  bool operator ==(Object other) =>
      other is AudControlEvent &&
      other.control == control &&
      other.value == value &&
      other.sampleOffset == sampleOffset &&
      other.port == port &&
      other.live == live;

  @override
  int get hashCode => Object.hash(control, value, sampleOffset, port, live);

  @override
  String toString() => 'AudControlEvent(${toJson()})';
}

// #############################################################################
/// A parameter change: the parameter moves to a value over a ramp.
final class AudParamEvent extends AudEvent {
  /// Creates a change of parameter [paramIndex] to [value] over
  /// [rampFrames] frames.
  const AudParamEvent({
    required this.paramIndex,
    required this.value,
    this.rampFrames = 0,
    super.sampleOffset,
    super.port,
    super.live,
  });

  // ...........................................................................
  /// The index of the parameter in the descriptor.
  final int paramIndex;

  /// The target value.
  final double value;

  /// The ramp length in frames; 0 jumps at once.
  final int rampFrames;

  @override
  int get type => bindings.AUD_EVENT_PARAM;

  @override
  List<int> get words => [
    paramIndex,
    AudEvent.bitsOfFloat(value),
    rampFrames,
    0,
  ];

  // ...........................................................................
  @override
  Map<String, Object?> toJson() => {
    ..._baseJson('param'),
    'paramIndex': paramIndex,
    'value': value,
    'rampFrames': rampFrames,
  };

  @override
  bool operator ==(Object other) =>
      other is AudParamEvent &&
      other.paramIndex == paramIndex &&
      other.value == value &&
      other.rampFrames == rampFrames &&
      other.sampleOffset == sampleOffset &&
      other.port == port &&
      other.live == live;

  @override
  int get hashCode =>
      Object.hash(paramIndex, value, rampFrames, sampleOffset, port, live);

  @override
  String toString() => 'AudParamEvent(${toJson()})';
}
