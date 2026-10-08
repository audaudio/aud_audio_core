// @license
// Copyright (c) Audanika. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:aud_audio_core/aud_audio_core.dart';
import 'package:test/test.dart';

void main() {
  group('AudCommand', () {
    test('json round trip and equality of every command', () {
      final commands = <AudCommand>[
        const AudSetParamCommand(
          node: 1,
          paramIndex: 0,
          value: 0.5,
          rampFrames: 8,
          at: AudTimestamp.sample(10),
        ),
        const AudEventCommand(
          node: 1,
          event: AudParamEvent(paramIndex: 0, value: 1),
          at: AudTimestamp.host(5),
          id: 3,
        ),
        const AudCancelCommand(node: 1),
        const AudCancelCommand(id: 3),
        const AudSetStringCommand(node: 1, key: 2, value: 'x'),
        const AudTransportCommand(
          graph: 1,
          request: AudTransportRequest.start(),
        ),
      ];
      for (final command in commands) {
        final copy = AudCommand.fromJson(command.toJson());
        expect(copy, command, reason: '$command');
        expect(copy.hashCode, command.hashCode);
        expect(command.toString(), contains(command.runtimeType.toString()));
      }
      expect(
        () => AudCommand.fromJson({'command': 'x'}),
        throwsFormatException,
      );
      expect(() => AudCancelCommand(), throwsA(isA<AssertionError>()));
      expect(
        AudCommand.fromJson({'command': 'cancel', 'id': 1}),
        const AudCancelCommand(id: 1),
      );
      expect(commands[0], isNot(commands[1]));
    });
  });

  group('AudReply and AudNotification', () {
    test('speak the vocabulary', () {
      expect(
        const AudDone('/a', [1]).toOsc(),
        AudOscMessage('/done', ['/a', 1]),
      );
      expect(
        const AudFail('/a', AUD_ERROR_NOT_FOUND, 'no').toOsc(),
        AudOscMessage('/fail', ['/a', AUD_ERROR_NOT_FOUND, 'no']),
      );
      expect(const AudDone('/a'), const AudDone('/a'));
      expect(const AudDone('/a').hashCode, const AudDone('/a').hashCode);
      expect(const AudFail('/a', 1, 'x'), const AudFail('/a', 1, 'x'));
      expect(
        const AudFail('/a', 1, 'x').hashCode,
        const AudFail('/a', 1, 'x').hashCode,
      );
      expect(const AudDone('/a').toString(), contains('/done'));
      final notifications = <AudNotification, AudOscMessage>{
        const AudNodeCreated(graph: 1, node: 2, typeId: 'a.b'): AudOscMessage(
          AudOscVocabulary.nodeCreated,
          [1, 2, 'a.b'],
        ),
        const AudNodeRetired(graph: 1, node: 2): AudOscMessage(
          AudOscVocabulary.nodeRetired,
          [1, 2],
        ),
        const AudRevisionAdopted(graph: 1, revision: 7): AudOscMessage(
          AudOscVocabulary.revisionAdopted,
          [1, 7],
        ),
        const AudMeter(address: '/a', peak: 0.5, rms: 0.1): AudOscMessage(
          AudOscVocabulary.meter,
          ['/a', 0.5, 0.1],
        ),
        const AudDiagnostic(
          code: AUD_ERROR_LATE,
          message: 'late',
          address: '/a',
        ): AudOscMessage(AudOscVocabulary.diagnostic, [
          AUD_ERROR_LATE,
          'late',
          '/a',
        ]),
        const AudDiagnostic(
          code: AUD_ERROR_QUEUE_FULL,
          message: 'full',
        ): AudOscMessage(AudOscVocabulary.diagnostic, [
          AUD_ERROR_QUEUE_FULL,
          'full',
        ]),
      };
      for (final entry in notifications.entries) {
        expect(entry.key.toOsc(), entry.value);
        expect(entry.key.hashCode, entry.value.hashCode);
        expect(entry.key.toString(), contains('/notify'));
      }
      expect(
        const AudNodeRetired(graph: 1, node: 2),
        const AudNodeRetired(graph: 1, node: 2),
      );
    });
  });
}
