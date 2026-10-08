// @license
// Copyright (c) Audanika. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:ffi';

import 'package:aud_audio_core/aud_audio_core.dart';
import 'package:aud_audio_core/aud_audio_core_bindings.dart' as native;
import 'package:ffi/ffi.dart';
import 'package:test/test.dart';

import 'fake_host.dart';

void main() {
  _nativeExtras();
  const descriptor = AudNodeDescriptor(
    typeId: 'aud.test.node',
    name: 'Test',
    vendor: 'Audanika',
    version: 3,
    capabilities: AudNodeCapabilities(inPlace: true, events: true, state: true),
    stateVersion: 2,
    inputBuses: [AudBusDescriptor(id: 'in', name: 'In')],
    outputBuses: [AudBusDescriptor(id: 'out', sidechain: true, optional: true)],
    eventInputs: [AudEventPortDescriptor(id: 'midi', midi: true)],
    eventOutputs: [AudEventPortDescriptor(id: 'out', control: true)],
    params: [
      AudParamDescriptor(
        id: 'gain',
        name: 'Gain',
        max: 2,
        defaultValue: 1,
        ramped: true,
      ),
      AudParamDescriptor(
        id: 'mode',
        stepped: true,
        steps: 3,
        boolean: true,
        logarithmic: true,
        hidden: true,
        automatable: false,
      ),
    ],
    stringKeys: [AudStringKeyDescriptor(key: 1, id: 'file', name: 'File')],
  );

  group('AudNodeDescriptor', () {
    test('json round trip, equality and lookups', () {
      final copy = AudNodeDescriptor.fromJson(descriptor.toJson());
      expect(copy, descriptor);
      expect(copy.hashCode, descriptor.hashCode);
      expect(descriptor.paramIndex('mode'), 1);
      expect(descriptor.param('gain')!.max, 2);
      expect(descriptor.param('x'), isNull);
      expect(descriptor.eventInputIndex('midi'), 0);
      expect(descriptor.eventOutputIndex('out'), 0);
      expect(descriptor.eventOutputIndex('x'), isNull);
      expect(descriptor.stringKey('file')!.key, 1);
      expect(descriptor.stringKey('x'), isNull);
      expect(descriptor.toString(), 'AudNodeDescriptor(aud.test.node)');
      final minimal = AudNodeDescriptor.fromJson({'typeId': 'a.b'});
      expect(minimal.abiMajor, AudAbi.major);
      expect(minimal, isNot(descriptor));
    });

    test('fromNative(native) reads the gain node of the core', () {
      final host = FakeHost();
      AudCoreGain.register(host.api);
      final gain = AudNodeDescriptor.fromNative(host.descriptors.single.ref);
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
  });

  group('AudBusDescriptor', () {
    test('flags, native and json', () {
      const bus = AudBusDescriptor(
        id: 'sc',
        sidechain: true,
        optional: true,
        main: false,
        minChannels: 2,
        maxChannels: 2,
        defaultChannels: 2,
      );
      expect(bus.flags, AUD_BUS_SIDECHAIN | AUD_BUS_OPTIONAL);
      expect(AudBusDescriptor.fromJson(bus.toJson()), bus);
      expect(bus.hashCode, AudBusDescriptor.fromJson(bus.toJson()).hashCode);
      expect(bus.toString(), contains('sc'));
      final pointer = calloc<native.AudBusDescriptor>();
      pointer.ref
        ..flags = bus.flags
        ..min_channels = 2
        ..max_channels = 2
        ..default_channels = 2;
      final read = AudBusDescriptor.fromNative(pointer.ref);
      expect(read.id, '');
      expect(read.sidechain, isTrue);
      calloc.free(pointer);
      expect(AudBusDescriptor.fromJson({'id': 'x'}).main, isTrue);
    });
  });

  group('AudEventPortDescriptor', () {
    test('flags and json', () {
      const port = AudEventPortDescriptor(id: 'p', midi: true, control: true);
      expect(port.flags, AUD_EVENT_PORT_MIDI | AUD_EVENT_PORT_CONTROL);
      expect(AudEventPortDescriptor.fromJson(port.toJson()), port);
      expect(
        port.hashCode,
        AudEventPortDescriptor.fromJson(port.toJson()).hashCode,
      );
      expect(port.toString(), contains('midi: true'));
    });
  });

  group('AudParamDescriptor', () {
    test('flags, range, json', () {
      const param = AudParamDescriptor(
        id: 'f',
        unit: 'Hz',
        min: 20,
        max: 20000,
        defaultValue: 440,
        logarithmic: true,
      );
      expect(param.flags, AUD_PARAM_AUTOMATABLE | AUD_PARAM_LOGARITHMIC);
      expect(param.contains(440), isTrue);
      expect(param.contains(1), isFalse);
      expect(param.clamp(1), 20);
      expect(param.clamp(30000), 20000);
      expect(AudParamDescriptor.fromJson(param.toJson()), param);
      expect(
        param.hashCode,
        AudParamDescriptor.fromJson(param.toJson()).hashCode,
      );
      expect(param.toString(), contains('Hz'));
      expect(descriptor.params[1].flags & AUD_PARAM_STEPPED, isNonZero);
      expect(AudParamDescriptor.fromJson({'id': 'x'}).automatable, isTrue);
    });
  });

  group('AudStringKeyDescriptor', () {
    test('json and equality', () {
      const key = AudStringKeyDescriptor(key: 2, id: 'text');
      expect(AudStringKeyDescriptor.fromJson(key.toJson()), key);
      expect(
        key.hashCode,
        AudStringKeyDescriptor.fromJson(key.toJson()).hashCode,
      );
      expect(key.toString(), contains('text'));
    });
  });

  group('AudNodeCapabilities', () {
    test('flags and json round trip', () {
      const all = AudNodeCapabilities(
        inPlace: true,
        variableBlock: true,
        events: true,
        strings: true,
        state: true,
        latency: true,
        tail: true,
        transport: true,
        eventOutput: true,
        resetOnStop: true,
        resetOnSeek: true,
      );
      expect(all.flags, (1 << 11) - 1);
      expect(AudNodeCapabilities.fromFlags(all.flags), all);
      expect(AudNodeCapabilities.fromJson(all.toJson()), all);
      expect(all.toJson(), hasLength(11));
      expect(all.hashCode, all.flags);
      expect(all.toString(), contains('inPlace'));
      expect(const AudNodeCapabilities().flags, 0);
    });
  });
}

void _nativeExtras() {
  group('AudNodeDescriptor.fromNative with event outputs and string keys', () {
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
      final descriptor = AudNodeDescriptor.fromNative(pointer.ref);
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
  });
}
