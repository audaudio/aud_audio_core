// @license
// Copyright (c) Audanika. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:aud_audio_core/aud_audio_core.dart';
import 'package:aud_midi_standard/aud_midi_standard.dart';
import 'package:test/test.dart';

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
    test('toJson() and fromJson(json) round trip', () {
      for (final event in <AudEvent>[
        ump,
        control,
        AudControlEvent(control: 1, value: -5),
        AudControlEvent(control: 1, value: true),
        AudControlEvent(control: 1, value: false),
        AudControlEvent(control: 1, value: null),
        AudControlEvent(control: 1, value: AudImpulse.instance),
        param,
      ]) {
        expect(AudEvent.fromJson(event.toJson()), event, reason: '$event');
        expect(event.hashCode, AudEvent.fromJson(event.toJson()).hashCode);
      }
      expect(() => AudEvent.fromJson({'type': 'x'}), throwsFormatException);
    });

    test('fromWords(...) reads the fields of the native struct', () {
      for (final event in [ump, control, param]) {
        expect(
          AudEvent.fromWords(
            type: event.type,
            words: event.words,
            sampleOffset: event.sampleOffset,
            port: event.port,
            flags: event.flags,
          ),
          event,
        );
      }
      expect(control.flags, AUD_EVENT_FLAG_LIVE);
      expect(param.flags, 0);
      expect(
        () => AudEvent.fromWords(type: 99, words: const [0, 0, 0, 0]),
        throwsArgumentError,
      );
    });

    test('float bits round trip', () {
      for (final value in [0.0, 1.0, -2.5, 1024.5]) {
        expect(AudEvent.floatOfBits(AudEvent.bitsOfFloat(value)), value);
      }
      expect(AudEvent.bitsOfFloat(1), 0x3F800000);
    });
  });

  group('AudUmpEvent', () {
    test('carries the packet of a message', () {
      expect(ump.type, AUD_EVENT_UMP);
      expect(ump.words, [0x20903C64, 0, 0, 0]);
      expect(ump.message, noteOn);
      expect(ump.isNoteOn, isTrue);
      expect(ump.isNoteOff, isFalse);
      expect(ump.sampleOffset, 3);
      expect(ump.port, 1);
      expect(ump.toString(), contains('20903c64'));
      expect(ump, isNot(AudUmpEvent(ump.packet)));
    });

    test(
      'splits a long message into packets and reports no message for a part',
      () {
        final sysEx = MidiSysEx(List.filled(20, 1));
        final events = AudUmpEvent.fromMessage(sysEx);
        expect(events.length, greaterThan(1));
        expect(events.first.message, isNull);
      },
    );
  });

  group('AudControlEvent', () {
    test('tags its argument', () {
      expect(control.type, AUD_EVENT_CONTROL);
      expect(control.typeTag, AUD_ARG_FLOAT);
      expect(AudControlEvent(control: 1, value: 3).typeTag, AUD_ARG_INT32);
      expect(AudControlEvent(control: 1, value: true).words[1], AUD_ARG_TRUE);
      expect(AudControlEvent(control: 1, value: 3).words[2], 3);
      expect(
        () => AudControlEvent(control: 1, value: 'x'),
        throwsArgumentError,
      );
      expect(
        () => AudControlEvent.valueOf(typeTag: 0, bits: 0),
        throwsArgumentError,
      );
      expect(() => AudControlEvent.valueFromJson('x'), throwsFormatException);
      expect(
        AudControlEvent.valueOf(typeTag: AUD_ARG_INT32, bits: 0xFFFFFFFF),
        -1,
      );
      expect(control.toString(), contains('float'));
      expect(AudImpulse.instance.toString(), 'AudImpulse');
    });
  });

  group('AudParamEvent', () {
    test('encodes index, value and ramp', () {
      expect(param.type, AUD_EVENT_PARAM);
      expect(param.words, [2, AudEvent.bitsOfFloat(0.25), 64, 0]);
      expect(param.toString(), contains('rampFrames'));
      expect(
        AudEvent.fromJson({'type': 'param', 'paramIndex': 1, 'value': 2}),
        const AudParamEvent(paramIndex: 1, value: 2),
      );
    });
  });
}
