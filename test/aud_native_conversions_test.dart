// @license
// Copyright (c) Audanika. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:ffi';

import 'package:aud_audio_core/aud_audio_core_ffi.dart';
import 'package:aud_audio_core/aud_audio_core_bindings.dart' as native;
import 'package:aud_midi_standard/aud_midi_standard.dart';
import 'package:ffi/ffi.dart';
import 'package:test/test.dart';

import 'fake_host.dart';

void main() {
  const noteOn = MidiNoteOn(channel: 0, note: 60, velocity: 100);
  final ump = AudUmpEvent.fromMessage(noteOn, sampleOffset: 3, port: 1).single;
  final control = AudControlEvent(
    control: 7,
    value: 0.5,
    sampleOffset: 4,
    live: true,
  );
  const param = AudParamEvent(
    paramIndex: 2,
    value: 0.25,
    rampFrames: 64,
    sampleOffset: 5,
  );

  group('AudEvent', () {
    test('writeTo(pointer) and toDart() round trip', () {
      final pointer = calloc<native.AudEvent>();
      final events = <AudEvent>[
        ump,
        control,
        AudControlEvent(control: 1, value: -5),
        AudControlEvent(control: 1, value: true),
        AudControlEvent(control: 1, value: false),
        AudControlEvent(control: 1, value: null),
        AudControlEvent(control: 1, value: AudImpulse.instance),
        param,
      ];
      for (final event in events) {
        event.writeTo(pointer);
        expect(pointer.ref.struct_size, sizeOf<native.AudEvent>());
        expect(pointer.ref.toDart(), event, reason: '$event');
        expect(AudEvent.fromJson(event.toJson()), event, reason: '$event');
        expect(event.hashCode, AudEvent.fromJson(event.toJson()).hashCode);
      }
      expect(pointer.ref.flags, 0);
      control.writeTo(pointer);
      expect(pointer.ref.flags, AUD_EVENT_FLAG_LIVE);
      pointer.ref.type = 99;
      expect(() => pointer.ref.toDart(), throwsArgumentError);
      calloc.free(pointer);
      expect(() => AudEvent.fromJson({'type': 'x'}), throwsFormatException);
    });
  });

  group('AudTimestamp', () {
    test('writeTo(pointer) and toDart() round trip', () {
      final pointer = calloc<native.AudTimestamp>();
      for (final stamp in [
        const AudTimestamp.immediate(),
        const AudTimestamp.sample(7),
        const AudTimestamp.host(9),
        AudTimestamp.beat(1.25),
      ]) {
        stamp.writeTo(pointer);
        expect(pointer.ref.struct_size, sizeOf<native.AudTimestamp>());
        expect(pointer.ref.toDart(), stamp);
      }
      calloc.free(pointer);
    });
  });

  group('AudNodeDescriptor', () {
    test('toDart() reads the gain node of the core', () {
      final host = FakeHost();
      AudCoreGain.register(host.api);
      final gain = host.descriptors.single.ref.toDart();
      host.dispose();
      expect(gain.typeId, AudCoreGain.typeId);
      expect(gain.name, 'Gain');
      expect(gain.vendor, 'Audanika');
      expect(gain.abiMajor, AudAbi.major);
      expect(gain.abiMinor, AudAbi.minor);
      expect(
        gain.capabilities,
        const AudNodeCapabilities(
          inPlace: true,
          variableBlock: true,
          events: true,
          state: true,
          latency: true,
          tail: true,
        ),
      );
      expect(gain.stateVersion, AudCoreGain.stateVersion);
      expect(
        gain.inputBuses.single,
        const AudBusDescriptor(id: 'in', name: 'Input'),
      );
      expect(gain.outputBuses.single.id, 'out');
      expect(
        gain.eventInputs.single,
        const AudEventPortDescriptor(
          id: 'events',
          name: 'Events',
          control: true,
        ),
      );
      expect(gain.eventOutputs, isEmpty);
      expect(
        gain.params.single,
        const AudParamDescriptor(
          id: 'gain',
          name: 'Gain',
          max: 2,
          defaultValue: 1,
          ramped: true,
        ),
      );
      expect(gain.stringKeys, isEmpty);
    });

    test('reads every array', () {
      final pointer = calloc<native.AudNodeDescriptor>();
      final outlet = calloc<native.AudEventPortDescriptor>();
      final key = calloc<native.AudStringKeyDescriptor>();
      final outletId = 'out'.toNativeUtf8();
      final keyId = 'file'.toNativeUtf8();
      outlet.ref
        ..id = outletId.cast()
        ..flags = AUD_EVENT_PORT_CONTROL;
      key.ref
        ..key = 7
        ..id = keyId.cast();
      pointer.ref
        ..num_event_outputs = 1
        ..event_outputs = outlet
        ..num_string_keys = 1
        ..string_keys = key;
      final descriptor = pointer.ref.toDart();
      expect(
        descriptor.eventOutputs.single,
        const AudEventPortDescriptor(id: 'out', control: true),
      );
      expect(
        descriptor.stringKeys.single,
        const AudStringKeyDescriptor(key: 7, id: 'file'),
      );
      calloc.free(outletId);
      calloc.free(keyId);
      calloc.free(outlet);
      calloc.free(key);
      calloc.free(pointer);
    });

    test('toDart() reads the flags of a bus and an empty id', () {
      final pointer = calloc<native.AudBusDescriptor>();
      pointer.ref
        ..flags = AUD_BUS_SIDECHAIN | AUD_BUS_OPTIONAL
        ..min_channels = 2
        ..max_channels = 2
        ..default_channels = 2;
      final read = pointer.ref.toDart();
      expect(read.id, '');
      expect(read.sidechain, isTrue);
      expect(read.optional, isTrue);
      expect(read.main, isFalse);
      calloc.free(pointer);
    });
  });

  group('AudStreamTime', () {
    test('writeTo(pointer) and toDart() round trip', () {
      const time = AudStreamTime(
        frames: 512,
        sampleRate: 48000,
        samplePosition: 96000,
        hostTimeNs: 1000000000,
        hostTimeSource: AudTimeSource.hardware,
        hostTimeAccuracyNs: 1000,
        outputLatencyFrames: 256,
        inputLatencyFrames: 128,
      );
      final pointer = calloc<native.AudStreamTime>();
      time.writeTo(pointer);
      expect(pointer.ref.struct_size, sizeOf<native.AudStreamTime>());
      expect(pointer.ref.toDart(), time);
      calloc.free(pointer);
    });
  });

  group('AudTransportSegment and AudTransportSnapshot', () {
    test('writeToRef(ref) and toDart() round trip', () {
      final segments = [
        const AudTransportSegment(
          sampleOffset: 0,
          frames: 256,
          beatTicks: AudBeats.factor,
          tempo: 120,
          playing: true,
          looping: true,
          seek: true,
          discontinuity: true,
          loopEndTicks: 4 * AudBeats.factor,
        ),
        const AudTransportSegment(
          sampleOffset: 256,
          frames: 256,
          tempo: 120,
          tempoIncrement: 0.01,
        ),
      ];
      final snapshot = calloc<native.AudTransportSnapshot>();
      final array = calloc<native.AudTransportSegment>(2);
      for (var i = 0; i < 2; i++) {
        segments[i].writeToRef(array[i]);
        expect(array[i].toDart(), segments[i]);
      }
      snapshot.ref
        ..capabilities = AUD_TRANSPORT_CAP_TEMPO
        ..num_segments = 2
        ..segments = array;
      const AudStreamTime(
        frames: 512,
        sampleRate: 48000,
        samplePosition: 0,
      ).writeToRef(snapshot.ref.time);
      final read = snapshot.ref.toDart();
      expect(read.segments, segments);
      expect(read.capabilities.tempo, isTrue);
      expect(read.time.frames, 512);
      calloc.free(array);
      calloc.free(snapshot);
    });
  });

  group('AudTransportRequest', () {
    test('writeTo(pointer) and toDart() round trip', () {
      final pointer = calloc<native.AudTransportRequest>();
      for (final request in [
        const AudTransportRequest.start(),
        const AudTransportRequest.stop(at: AudTimestamp.sample(5)),
        AudTransportRequest.seek(4),
        AudTransportRequest.setLoop(start: 1, end: 5),
      ]) {
        request.writeTo(pointer);
        expect(pointer.ref.struct_size, sizeOf<native.AudTransportRequest>());
        expect(pointer.ref.toDart(), request);
      }
      calloc.free(pointer);
    });
  });
}
