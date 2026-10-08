// @license
// Copyright (c) Audanika. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:aud_audio_core/aud_audio_core.dart';
import 'package:aud_midi_standard/aud_midi_standard.dart';
import 'package:test/test.dart';

void main() {
  const descriptor = AudNodeDescriptor(
    typeId: 'aud.core.gain',
    params: [AudParamDescriptor(id: 'gain', max: 2, defaultValue: 1)],
    eventInputs: [
      AudEventPortDescriptor(id: 'events', control: true, midi: true),
      AudEventPortDescriptor(id: 'midi', midi: true),
    ],
    eventOutputs: [AudEventPortDescriptor(id: 'out')],
    stringKeys: [AudStringKeyDescriptor(key: 4, id: 'file')],
  );
  late AudOscRouter router;
  late AudOscAdapter adapter;
  setUp(() {
    router = AudOscRouter();
    router.registerNode(graph: 1, node: 2, handle: 20, descriptor: descriptor);
    router.registerNode(graph: 1, node: 3, handle: 30, descriptor: descriptor);
    adapter = AudOscAdapter(
      router: router,
      hostTimeNs: () => 5000,
      now: () => DateTime.fromMicrosecondsSinceEpoch(1, isUtc: true),
    );
  });

  group('AudOscRouter', () {
    test('registers graphs, nodes and everything below them', () {
      expect(router.addresses.map((a) => a.value), [
        '/graph/1',
        '/graph/1/transport',
        '/graph/1/node/2',
        '/graph/1/node/2/param/gain',
        '/graph/1/node/2/inlet/events',
        '/graph/1/node/2/inlet/midi',
        '/graph/1/node/2/outlet/out',
        '/graph/1/node/2/string/file',
        '/graph/1/node/3',
        '/graph/1/node/3/param/gain',
        '/graph/1/node/3/inlet/events',
        '/graph/1/node/3/inlet/midi',
        '/graph/1/node/3/outlet/out',
        '/graph/1/node/3/string/file',
      ]);
      expect(
        router.lookup('/graph/1'),
        isA<AudGraphTarget>().having((t) => t.graph, 'graph', 1),
      );
      expect(router.lookup('/graph/1/transport'), isA<AudTransportTarget>());
      expect(
        router.lookup('/graph/1/node/2'),
        isA<AudNodeTarget>()
            .having((t) => t.handle, 'handle', 20)
            .having((t) => t.node, 'node', 2),
      );
      expect(
        router.lookup('/graph/1/node/2/param/gain'),
        isA<AudParamTarget>().having((t) => t.index, 'index', 0),
      );
      expect(
        router.lookup('/graph/1/node/2/inlet/events'),
        isA<AudInletTarget>().having((t) => t.port, 'port', 0),
      );
      expect(
        router.lookup('/graph/1/node/2/outlet/out'),
        isA<AudOutletTarget>(),
      );
      expect(
        router.lookup('/graph/1/node/2/string/file'),
        isA<AudStringTarget>().having((t) => t.key, 'key', 4),
      );
      expect(router.lookup('/x'), isNull);
      expect(router.lookup('/graph/1').toString(), 'AudGraphTarget(/graph/1)');
    });

    test('resolve(pattern) finds every match', () {
      expect(router.resolve('/graph/1/node/*/param/gain').length, 2);
      expect(router.resolve('//gain').length, 2);
      expect(router.resolve('/graph/1/node/2').length, 1);
      expect(router.resolve('/nothing'), isEmpty);
    });

    test('unregisters nodes and graphs', () {
      router.unregisterNode(graph: 1, node: 2);
      expect(router.lookup('/graph/1/node/2/param/gain'), isNull);
      expect(router.lookup('/graph/1/node/3'), isNotNull);
      router.registerNode(
        graph: 1,
        node: 3,
        handle: 31,
        descriptor: descriptor,
      );
      expect((router.lookup('/graph/1/node/3')! as AudNodeTarget).handle, 31);
      router.unregisterGraph(1);
      expect(router.addresses, isEmpty);
      router.registerGraph(2);
      router.registerGraph(2);
      expect(router.addresses.length, 2);
    });
  });

  group('AudOscAdapter', () {
    test('converts timetags into host time through the calibrated offset', () {
      expect(adapter.offsetNs, 5000 - 1000);
      expect(adapter.timestampOf(AudOscTimetag.immediate).isImmediate, isTrue);
      final stamp = adapter.timestampOf(
        AudOscTimetag.fromUnixNanoseconds(1000000),
      );
      expect(stamp.domain, AudTimeDomain.host);
      expect(stamp.source, AudTimeSource.synthesized);
      expect(stamp.value, 1000000 + 4000);
      adapter.calibrate();
      expect(adapter.offsetNs, 4000);
      expect(AudOscAdapter(router: router).offsetNs, isA<int>());
    });

    test('converts the grammar into commands', () {
      final cases = <AudOscMessage, List<AudCommand>>{
        AudOscMessage('/graph/1/node/2/param/gain', [0.5]): [
          const AudSetParamCommand(node: 20, paramIndex: 0, value: 0.5),
        ],
        AudOscMessage('/graph/1/node/2/param/gain', [9.0, 64]): [
          const AudSetParamCommand(
            node: 20,
            paramIndex: 0,
            value: 2,
            rampFrames: 64,
          ),
        ],
        AudOscMessage('/graph/1/node/2/inlet/events', [0x20906064]): [
          AudEventCommand(node: 20, event: AudUmpEvent(Ump([0x20906064]))),
        ],
        AudOscMessage('/graph/1/node/2/inlet/events/note', [60, 1.0]): [
          AudEventCommand(node: 20, event: AudUmpEvent(Ump([0x20903C7F]))),
        ],
        AudOscMessage('/graph/1/node/2/inlet/events/note', [60, 0.0, 2]): [
          AudEventCommand(node: 20, event: AudUmpEvent(Ump([0x20823C00]))),
        ],
        AudOscMessage('/graph/1/node/2/inlet/events/noteoff', [60]): [
          AudEventCommand(node: 20, event: AudUmpEvent(Ump([0x20803C00]))),
        ],
        AudOscMessage('/graph/1/node/2/inlet/events/control', [7, 0.5]): [
          AudEventCommand(
            node: 20,
            event: AudControlEvent(control: 7, value: 0.5),
          ),
        ],
        AudOscMessage('/graph/1/node/2/inlet/events/control', [7]): [
          AudEventCommand(
            node: 20,
            event: AudControlEvent(control: 7, value: AudImpulse.instance),
          ),
        ],
        AudOscMessage('/graph/1/node/2/inlet/midi/note', [60, 1.0]): [
          AudEventCommand(
            node: 20,
            event: AudUmpEvent(Ump([0x20903C7F]), port: 1),
          ),
        ],
        AudOscMessage('/graph/1/node/2/cancel'): [
          const AudCancelCommand(node: 20),
        ],
        AudOscMessage('/graph/1/node/2/cancel', [5]): [
          const AudCancelCommand(node: 20, id: 5),
        ],
        AudOscMessage('/graph/1/node/2/string/file', ['a.sfz']): [
          const AudSetStringCommand(node: 20, key: 4, value: 'a.sfz'),
        ],
        AudOscMessage('/graph/1/transport/start'): [
          const AudTransportCommand(
            graph: 1,
            request: AudTransportRequest.start(),
          ),
        ],
        AudOscMessage('/graph/1/transport/stop'): [
          const AudTransportCommand(
            graph: 1,
            request: AudTransportRequest.stop(),
          ),
        ],
        AudOscMessage('/graph/1/transport/seek', [4.0]): [
          AudTransportCommand(graph: 1, request: AudTransportRequest.seek(4)),
        ],
        AudOscMessage('/graph/1/transport/tempo', [128]): [
          const AudTransportCommand(
            graph: 1,
            request: AudTransportRequest.setTempo(128),
          ),
        ],
        AudOscMessage('/graph/1/transport/loop', [1.0, 5.0]): [
          AudTransportCommand(
            graph: 1,
            request: AudTransportRequest.setLoop(start: 1, end: 5),
          ),
        ],
        AudOscMessage('/graph/1/transport/quantum', [4.0]): [
          const AudTransportCommand(
            graph: 1,
            request: AudTransportRequest.setQuantum(4),
          ),
        ],
        AudOscMessage('/graph/1/transport/timesig', [3, 4]): [
          const AudTransportCommand(
            graph: 1,
            request: AudTransportRequest.setTimeSignature(
              numerator: 3,
              denominator: 4,
            ),
          ),
        ],
        AudOscMessage('/graph/1/node/*/param/gain', [1.0]): [
          const AudSetParamCommand(node: 20, paramIndex: 0, value: 1),
          const AudSetParamCommand(node: 30, paramIndex: 0, value: 1),
        ],
        AudOscMessage('/graph/1/node/*/inlet/events/note', [61, 0.5]): [
          AudEventCommand(node: 20, event: AudUmpEvent(Ump([0x20903D40]))),
          AudEventCommand(node: 30, event: AudUmpEvent(Ump([0x20903D40]))),
        ],
      };
      for (final entry in cases.entries) {
        expect(adapter.convert(entry.key), entry.value, reason: '${entry.key}');
      }
    });

    test('schedules bundled messages with ids', () {
      final bundle = AudOscBundle(
        timetag: AudOscTimetag.fromUnixNanoseconds(1000000),
        elements: [
          AudOscMessage('/graph/1/node/2/inlet/events/note', [60, 1.0]),
          AudOscBundle(
            elements: [
              AudOscMessage('/graph/1/node/2/param/gain', [0.5]),
            ],
          ),
        ],
      );
      final commands = adapter.convertBundle(bundle);
      expect(commands, hasLength(2));
      final event = commands[0] as AudEventCommand;
      expect(event.id, 1);
      expect(
        event.at,
        const AudTimestamp.host(1004000, source: AudTimeSource.synthesized),
      );
      final param = commands[1] as AudSetParamCommand;
      expect(param.at.isImmediate, isTrue);
      final again = adapter.convertBundle(bundle);
      expect((again[0] as AudEventCommand).id, 2);
    });

    test('fails with a reply for unknown addresses and wrong arguments', () {
      final cases = <AudOscMessage, int>{
        AudOscMessage('/nothing'): AUD_ERROR_NOT_FOUND,
        AudOscMessage('/graph/1/node/2/outlet/out', [1]): AUD_ERROR_NOT_FOUND,
        AudOscMessage('/graph/1/node/2/param/gain/x', [1.0]):
            AUD_ERROR_NOT_FOUND,
        AudOscMessage('/graph/1/node/2/param/gain', ['x']):
            AUD_ERROR_INVALID_ARGUMENT,
        AudOscMessage('/graph/1/node/2/param/gain', [1.0, 'x']):
            AUD_ERROR_INVALID_ARGUMENT,
        AudOscMessage('/graph/1/node/2/inlet/events'):
            AUD_ERROR_INVALID_ARGUMENT,
        AudOscMessage('/graph/1/node/2/inlet/events', [1, 2, 3, 4, 5]):
            AUD_ERROR_INVALID_ARGUMENT,
        AudOscMessage('/graph/1/node/2/inlet/events/note', [200, 1.0]):
            AUD_ERROR_INVALID_ARGUMENT,
        AudOscMessage('/graph/1/node/2/inlet/events/note', [60, 2.0]):
            AUD_ERROR_INVALID_ARGUMENT,
        AudOscMessage('/graph/1/node/2/inlet/events/note', [60]):
            AUD_ERROR_INVALID_ARGUMENT,
        AudOscMessage('/graph/1/node/2/inlet/events/control', [7, 's']):
            AUD_ERROR_INVALID_ARGUMENT,
        AudOscMessage('/graph/1/node/2/string/file', [1]):
            AUD_ERROR_INVALID_ARGUMENT,
        AudOscMessage('/graph/1/node/2/string/file'):
            AUD_ERROR_INVALID_ARGUMENT,
        AudOscMessage('/graph/1/transport/fly'): AUD_ERROR_INVALID_ARGUMENT,
        AudOscMessage('/graph/1/transport/seek', ['x']):
            AUD_ERROR_INVALID_ARGUMENT,
        AudOscMessage('/graph/1/transport/timesig', [3]):
            AUD_ERROR_INVALID_ARGUMENT,
      };
      for (final entry in cases.entries) {
        expect(
          () => adapter.convert(entry.key),
          throwsA(
            isA<AudOscException>()
                .having((e) => e.code, 'code', entry.value)
                .having((e) => e.address, 'address', entry.key.address)
                .having((e) => e.toFail(), 'fail', isA<AudFail>())
                .having(
                  (e) => e.toString(),
                  'toString',
                  contains('AudOscException'),
                ),
          ),
          reason: '${entry.key}',
        );
      }
    });
  });
}
