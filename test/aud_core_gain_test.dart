// @license
// Copyright (c) Audanika. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:ffi';

import 'package:aud_audio_core/aud_audio_core_ffi.dart';
import 'package:aud_audio_core/aud_audio_core_bindings.dart' as native;
import 'package:ffi/ffi.dart';
import 'package:test/test.dart';

import 'fake_host.dart';

/// Drives a node instance through its vtable from Dart, as the engine does.
class NodeDriver {
  NodeDriver(this.host, this.descriptor) {
    vtable = descriptor.ref.vtable.ref;
    instance = vtable.create
        .asFunction<
          Pointer<Void> Function(
            Pointer<native.AudNodeDescriptor>,
            Pointer<native.AudHostApi>,
          )
        >()(descriptor, host.api);
  }

  final FakeHost host;
  final Pointer<native.AudNodeDescriptor> descriptor;
  late final native.AudNodeVTable vtable;
  late final Pointer<Void> instance;

  int prepare({
    double sampleRate = 48000,
    int maxFrames = 64,
    int channels = 2,
  }) {
    final info = calloc<native.AudPrepareInfo>();
    final inputs = calloc<Uint32>(1)..value = channels;
    final outputs = calloc<Uint32>(1)..value = channels;
    info.ref
      ..struct_size = sizeOf<native.AudPrepareInfo>()
      ..max_frames = maxFrames
      ..sample_rate = sampleRate
      ..num_input_buses = 1
      ..input_channels = inputs
      ..num_output_buses = 1
      ..output_channels = outputs;
    final result = vtable.prepare
        .asFunction<
          int Function(Pointer<Void>, Pointer<native.AudPrepareInfo>)
        >()(instance, info);
    calloc.free(inputs);
    calloc.free(outputs);
    calloc.free(info);
    return result;
  }

  void setParam(int index, double value) =>
      vtable.set_param.asFunction<void Function(Pointer<Void>, int, double)>()(
        instance,
        index,
        value,
      );

  void reset(int reason) => vtable.reset
      .asFunction<void Function(Pointer<Void>, int)>()(instance, reason);

  /// Renders [frames] frames of ones through the node with [events].
  List<List<double>> process(
    int frames,
    List<AudEvent> events, {
    int channels = 2,
  }) {
    final inBus = calloc<native.AudAudioBus>();
    final outBus = calloc<native.AudAudioBus>();
    final inChannels = calloc<Pointer<Float>>(channels);
    final outChannels = calloc<Pointer<Float>>(channels);
    for (var c = 0; c < channels; c++) {
      inChannels[c] = calloc<Float>(frames);
      inChannels[c].asTypedList(frames).fillRange(0, frames, 1);
      outChannels[c] = calloc<Float>(frames);
    }
    inBus.ref
      ..struct_size = sizeOf<native.AudAudioBus>()
      ..num_channels = channels
      ..channels = inChannels;
    outBus.ref
      ..struct_size = sizeOf<native.AudAudioBus>()
      ..num_channels = channels
      ..channels = outChannels;
    final nativeEvents = calloc<native.AudEvent>(events.length + 1);
    for (var i = 0; i < events.length; i++) {
      events[i].writeToRef(nativeEvents[i]);
    }
    final context = calloc<native.AudProcessContext>();
    context.ref
      ..struct_size = sizeOf<native.AudProcessContext>()
      ..frames = frames
      ..sample_rate = 48000
      ..sample_position = 0
      ..num_input_buses = 1
      ..inputs = inBus
      ..num_output_buses = 1
      ..num_events = events.length
      ..outputs = outBus
      ..events = nativeEvents;
    vtable.process
        .asFunction<
          void Function(Pointer<Void>, Pointer<native.AudProcessContext>)
        >()(instance, context);
    final output = [
      for (var c = 0; c < channels; c++)
        outChannels[c].asTypedList(frames).toList(),
    ];
    for (var c = 0; c < channels; c++) {
      calloc.free(inChannels[c]);
      calloc.free(outChannels[c]);
    }
    calloc.free(inChannels);
    calloc.free(outChannels);
    calloc.free(inBus);
    calloc.free(outBus);
    calloc.free(nativeEvents);
    calloc.free(context);
    return output;
  }

  int latency() =>
      vtable.get_latency.asFunction<int Function(Pointer<Void>)>()(instance);
  int tail() =>
      vtable.get_tail.asFunction<int Function(Pointer<Void>)>()(instance);

  int setString(int key, String value) {
    final text = value.toNativeUtf8();
    final result =
        vtable.set_string
            .asFunction<int Function(Pointer<Void>, int, Pointer<Char>)>()(
          instance,
          key,
          text.cast(),
        );
    calloc.free(text);
    return result;
  }

  (int, List<int>) saveState(int capacity) {
    final buffer = calloc<Uint8>(capacity + 1);
    final size = calloc<Size>();
    final result = vtable.save_state
        .asFunction<
          int Function(Pointer<Void>, Pointer<Void>, int, Pointer<Size>)
        >()(instance, buffer.cast(), capacity, size);
    final bytes = buffer
        .asTypedList(size.value > capacity ? 0 : size.value)
        .toList();
    final written = size.value;
    calloc.free(buffer);
    calloc.free(size);
    return (result, result == AUD_OK ? bytes : [written]);
  }

  int loadState(List<int> bytes, int version) {
    final buffer = calloc<Uint8>(bytes.length + 1);
    buffer.asTypedList(bytes.length + 1).setAll(0, bytes);
    final result =
        vtable.load_state
            .asFunction<int Function(Pointer<Void>, Pointer<Void>, int, int)>()(
          instance,
          buffer.cast(),
          bytes.length,
          version,
        );
    calloc.free(buffer);
    return result;
  }

  void dispose() =>
      vtable.destroy.asFunction<void Function(Pointer<Void>)>()(instance);
}

void main() {
  group('AudCoreGain.register(host)', () {
    late FakeHost host;
    tearDown(() => host.dispose());

    test('registers the gain with the ABI it was built against', () {
      host = FakeHost();
      AudCoreGain.register(host.api);
      final d = host.descriptors.single.ref;
      expect(d.struct_size, sizeOf<native.AudNodeDescriptor>());
      expect(d.type_id.cast<Utf8>().toDartString(), AudCoreGain.typeId);
      expect(d.vtable.ref.struct_size, sizeOf<native.AudNodeVTable>());
      expect(AudCoreGain.gain, 0);
    });

    test('throws when the host refuses', () {
      host = FakeHost(result: AUD_ERROR_DUPLICATE_TYPE);
      expect(
        () => AudCoreGain.register(host.api),
        throwsA(
          isA<AudCoreException>().having(
            (e) => e.code,
            'code',
            AUD_ERROR_DUPLICATE_TYPE,
          ),
        ),
      );
    });

    test(
      'refuses hosts of another major, another minor, a short struct or null',
      () {
        host = FakeHost(abiMajor: AudAbi.major + 1);
        expect(
          () => AudCoreGain.register(host.api),
          throwsA(
            isA<AudCoreException>().having(
              (e) => e.code,
              'code',
              AUD_ERROR_ABI_MAJOR,
            ),
          ),
        );
        final minor = FakeHost(abiMinor: AudAbi.minor + 1);
        expect(
          () => AudCoreGain.register(minor.api),
          throwsA(
            isA<AudCoreException>().having(
              (e) => e.code,
              'code',
              AUD_ERROR_ABI_MINOR,
            ),
          ),
        );
        minor.dispose();
        final short = FakeHost(structSize: 4);
        expect(
          () => AudCoreGain.register(short.api),
          throwsA(
            isA<AudCoreException>().having(
              (e) => e.code,
              'code',
              AUD_ERROR_INVALID_ARGUMENT,
            ),
          ),
        );
        short.dispose();
        expect(
          () => AudCoreGain.register(nullptr),
          throwsA(
            isA<AudCoreException>().having(
              (e) => e.code,
              'code',
              AUD_ERROR_INVALID_ARGUMENT,
            ),
          ),
        );
        expect(host.descriptors, isEmpty);
      },
    );
  });

  group('aud.core.gain through its vtable', () {
    late FakeHost host;
    late NodeDriver node;
    setUp(() {
      host = FakeHost();
      AudCoreGain.register(host.api);
      node = NodeDriver(host, host.descriptors.single);
      expect(node.prepare(), AUD_OK);
    });
    tearDown(() {
      node.dispose();
      host.dispose();
    });

    test('renders at the gain set at once', () {
      node.setParam(AudCoreGain.gain, 0.5);
      final output = node.process(8, const []);
      expect(output[0], everyElement(0.5));
      expect(output[1], everyElement(0.5));
      node.reset(AUD_RESET_STOP);
      expect(node.latency(), 0);
      expect(node.tail(), 0);
      expect(node.setString(0, 'x'), AUD_ERROR_UNSUPPORTED);
    });

    test(
      'ramps a parameter event at its offset in sub-ranges of 16 frames',
      () {
        final output = node.process(64, const [
          AudParamEvent(
            paramIndex: AudCoreGain.gain,
            value: 0,
            rampFrames: 32,
            sampleOffset: 16,
          ),
        ])[0];
        expect(output.sublist(0, 16), everyElement(1));
        for (var i = 0; i < 32; i++) {
          expect(
            output[16 + i],
            closeTo(1 - i / 32, 1e-5),
            reason: 'frame ${16 + i}',
          );
        }
        expect(output.sublist(48), everyElement(0));
      },
    );

    test(
      'delivers an event inside a sub-range at its end, and late events at the block end',
      () {
        final output = node.process(32, const [
          AudParamEvent(
            paramIndex: AudCoreGain.gain,
            value: 0,
            sampleOffset: 5,
          ),
          AudParamEvent(
            paramIndex: AudCoreGain.gain,
            value: 0.25,
            sampleOffset: 40,
          ),
        ])[0];
        expect(output.sublist(0, 16), everyElement(1));
        expect(output.sublist(16), everyElement(0));
        expect(node.process(4, const [])[0], everyElement(0.25));
      },
    );

    test('ignores other events and unknown parameters', () {
      final output = node.process(8, [
        AudControlEvent(control: 1, value: 1),
        const AudParamEvent(paramIndex: 9, value: 0),
      ])[0];
      expect(output, everyElement(1));
      node.setParam(9, 0);
      expect(node.process(8, const [])[0], everyElement(1));
    });

    test('renders only the channels both buses have', () {
      expect(node.process(4, const [], channels: 1), hasLength(1));
    });

    test('saves and loads its state', () {
      node.setParam(AudCoreGain.gain, 0.75);
      final (tooSmall, needed) = node.saveState(1);
      expect(tooSmall, AUD_ERROR_BUFFER_TOO_SMALL);
      expect(needed, [4]);
      final (ok, bytes) = node.saveState(8);
      expect(ok, AUD_OK);
      expect(bytes, hasLength(4));
      node.setParam(AudCoreGain.gain, 0);
      expect(
        node.loadState(bytes, AudCoreGain.stateVersion + 1),
        AUD_ERROR_STATE_VERSION,
      );
      expect(
        node.loadState([1], AudCoreGain.stateVersion),
        AUD_ERROR_INVALID_ARGUMENT,
      );
      expect(node.loadState(bytes, AudCoreGain.stateVersion), AUD_OK);
      expect(node.process(4, const [])[0], everyElement(0.75));
    });
  });
}
