// @license
// Copyright (c) Audanika. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:aud_audio_core/aud_audio_core.dart';
import 'package:test/test.dart';

void main() {
  group('AudAbi', () {
    test('resultName(code) names every result code', () {
      final names = {
        AUD_OK: 'AUD_OK',
        AUD_PENDING: 'AUD_PENDING',
        AUD_ERROR_INVALID_ARGUMENT: 'AUD_ERROR_INVALID_ARGUMENT',
        AUD_ERROR_ABI_MAJOR: 'AUD_ERROR_ABI_MAJOR',
        AUD_ERROR_ABI_MINOR: 'AUD_ERROR_ABI_MINOR',
        AUD_ERROR_DUPLICATE_TYPE: 'AUD_ERROR_DUPLICATE_TYPE',
        AUD_ERROR_UNKNOWN_TYPE: 'AUD_ERROR_UNKNOWN_TYPE',
        AUD_ERROR_QUEUE_FULL: 'AUD_ERROR_QUEUE_FULL',
        AUD_ERROR_OUT_OF_MEMORY: 'AUD_ERROR_OUT_OF_MEMORY',
        AUD_ERROR_STATE: 'AUD_ERROR_STATE',
        AUD_ERROR_FAILED: 'AUD_ERROR_FAILED',
        AUD_ERROR_UNSUPPORTED: 'AUD_ERROR_UNSUPPORTED',
        AUD_ERROR_BUFFER_TOO_SMALL: 'AUD_ERROR_BUFFER_TOO_SMALL',
        AUD_ERROR_STATE_VERSION: 'AUD_ERROR_STATE_VERSION',
        AUD_ERROR_LATE: 'AUD_ERROR_LATE',
        AUD_ERROR_NOT_FOUND: 'AUD_ERROR_NOT_FOUND',
        AUD_ERROR_CYCLE: 'AUD_ERROR_CYCLE',
        AUD_ERROR_FORMAT: 'AUD_ERROR_FORMAT',
        AUD_ERROR_LOOKAHEAD: 'AUD_ERROR_LOOKAHEAD',
        AUD_ERROR_CAPACITY: 'AUD_ERROR_CAPACITY',
        AUD_ERROR_RETIRED: 'AUD_ERROR_RETIRED',
        AUD_ERROR_OVERLOAD: 'AUD_ERROR_OVERLOAD',
        -99: 'AUD_RESULT_-99',
      };
      for (final entry in names.entries) {
        expect(AudAbi.resultName(entry.key), entry.value);
      }
    });

    test('threadName(tag) names the thread affinity tags', () {
      expect(AudAbi.threadName(AUD_THREAD_CONTROL), 'control');
      expect(AudAbi.threadName(AUD_THREAD_REALTIME), 'realtime');
      expect(AudAbi.threadName(AUD_THREAD_OFFLINE), 'offline');
      expect(AudAbi.threadName(7), 'thread_7');
    });

    group('isCompatible(...)', () {
      // (package major, package minor, engine major, engine minor, result)
      const cases = [
        (0, 3, 0, 3, true),
        (0, 2, 0, 3, false),
        (0, 4, 0, 3, false),
        (1, 0, 1, 0, true),
        (1, 0, 1, 3, true),
        (1, 3, 1, 2, false),
        (1, 0, 2, 0, false),
        (2, 0, 1, 5, false),
      ];

      for (final (pm, pn, em, en, expected) in cases) {
        test('package $pm.$pn on engine $em.$en is $expected', () {
          final named = (
            packageMajor: pm,
            packageMinor: pn,
            engineMajor: em,
            engineMinor: en,
          );
          expect(
            AudAbi.isCompatible(
              packageMajor: named.packageMajor,
              packageMinor: named.packageMinor,
              engineMajor: named.engineMajor,
              engineMinor: named.engineMinor,
            ),
            expected,
          );
        });
      }
    });
  });
}
