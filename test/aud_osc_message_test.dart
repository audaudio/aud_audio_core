// @license
// Copyright (c) Audanika. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:typed_data';

import 'package:aud_audio_core/aud_audio_core.dart';
import 'package:test/test.dart';

void main() {
  group('AudOscTimetag', () {
    test('immediate is 1', () {
      expect(AudOscTimetag.immediate.isImmediate, isTrue);
      expect(const AudOscTimetag(seconds: 1, fraction: 0).isImmediate, isFalse);
      expect(AudOscTimetag.immediate.toString(), 'AudOscTimetag.immediate');
    });

    test('converts Unix time and DateTime within a nanosecond', () {
      const ns = 1700000000123456789;
      final tag = AudOscTimetag.fromUnixNanoseconds(ns);
      expect(tag.seconds, 1700000000 + AudOscTimetag.ntpEpochOffset);
      expect(tag.unixNanoseconds, closeTo(ns, 1));
      final time = DateTime.fromMicrosecondsSinceEpoch(ns ~/ 1000, isUtc: true);
      expect(AudOscTimetag.fromDateTime(time).toDateTime(), time);
      expect(AudOscTimetag.fromJson(tag.toJson()), tag);
      expect(tag.hashCode, AudOscTimetag.fromJson(tag.toJson()).hashCode);
      expect(tag.toString(), startsWith('AudOscTimetag('));
    });
  });

  group('AudOscTypeTags', () {
    test('tags every type and rejects others', () {
      final arguments = <Object?>[
        1,
        1.5,
        's',
        Uint8List.fromList([1]),
        true,
        false,
        null,
        AudImpulse.instance,
        AudOscTimetag.immediate,
      ];
      expect(AudOscTypeTags.ofArguments(arguments), ',ifsbTFNIt');
      expect(() => AudOscTypeTags.of(const []), throwsArgumentError);
      for (final argument in arguments) {
        final back = AudOscTypeTags.fromJson(AudOscTypeTags.toJson(argument));
        if (argument is Uint8List) {
          expect(back, argument);
        } else {
          expect(back, argument);
        }
      }
      expect(() => AudOscTypeTags.fromJson('x'), throwsFormatException);
    });
  });

  group('AudOscMessage', () {
    test('validates the address and the arguments', () {
      final message = AudOscMessage('/graph/1/node/2/param/gain', [0.5, 10]);
      expect(message.typeTags, ',fi');
      expect(message.hasPattern, isFalse);
      expect(AudOscMessage('/a/*').hasPattern, isTrue);
      expect(() => AudOscMessage('a'), throwsFormatException);
      expect(() => AudOscMessage('/a', [const []]), throwsArgumentError);
      expect(AudOscMessage.fromJson(message.toJson()), message);
      expect(
        message.hashCode,
        AudOscMessage.fromJson(message.toJson()).hashCode,
      );
      expect(
        message.toString(),
        'AudOscMessage(/graph/1/node/2/param/gain ,fi [0.5, 10])',
      );
      expect(AudOscMessage.fromJson({'address': '/a'}).arguments, isEmpty);
    });
  });

  group('AudOscBundle', () {
    test('nests messages and bundles', () {
      final inner = AudOscBundle(
        timetag: const AudOscTimetag(seconds: 5, fraction: 0),
        elements: [
          AudOscMessage('/a', [1]),
        ],
      );
      final bundle = AudOscBundle(elements: [AudOscMessage('/b'), inner]);
      expect(AudOscBundle.fromJson(bundle.toJson()), bundle);
      expect(bundle.hashCode, AudOscBundle.fromJson(bundle.toJson()).hashCode);
      expect(
        bundle.toString(),
        'AudOscBundle(AudOscTimetag.immediate, 2 elements)',
      );
      expect(() => AudOscBundle(elements: [1]), throwsArgumentError);
      expect(AudOscBundle.fromJson({}).elements, isEmpty);
    });
  });
}
