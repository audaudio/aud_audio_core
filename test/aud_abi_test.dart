// @license
// Copyright (c) Audanika. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:aud_audio_core/aud_audio_core.dart';
import 'package:test/test.dart';

void main() {
  group('AudAbi', () {
    test('major and minor match the native core', () {
      expect(AudAbi.nativeMajor, AudAbi.major);
      expect(AudAbi.nativeMinor, AudAbi.minor);
      expect(AudAbi.major, 0);
      expect(AudAbi.minor, 1);
    });

    test('struct sizes agree between Dart and C', () {
      expect(AudAbi.dartStructSizes, AudAbi.nativeStructSizes);
      expect(AudAbi.dartStructSizes.keys, hasLength(6));
    });

    test('resultName(code) names every result code', () {
      final names = {
        AUD_OK: 'AUD_OK',
        AUD_ERROR_INVALID_ARGUMENT: 'AUD_ERROR_INVALID_ARGUMENT',
        AUD_ERROR_ABI_MAJOR: 'AUD_ERROR_ABI_MAJOR',
        AUD_ERROR_ABI_MINOR: 'AUD_ERROR_ABI_MINOR',
        AUD_ERROR_DUPLICATE_TYPE: 'AUD_ERROR_DUPLICATE_TYPE',
        AUD_ERROR_UNKNOWN_TYPE: 'AUD_ERROR_UNKNOWN_TYPE',
        AUD_ERROR_QUEUE_FULL: 'AUD_ERROR_QUEUE_FULL',
        AUD_ERROR_OUT_OF_MEMORY: 'AUD_ERROR_OUT_OF_MEMORY',
        AUD_ERROR_STATE: 'AUD_ERROR_STATE',
        AUD_ERROR_FAILED: 'AUD_ERROR_FAILED',
        -99: 'AUD_RESULT_-99',
      };
      for (final entry in names.entries) {
        expect(AudAbi.resultName(entry.key), entry.value);
      }
    });

    group('isCompatible(...)', () {
      test('accepts the same major and an older or equal package minor', () {
        for (final minor in [0, 1]) {
          expect(
            AudAbi.isCompatible(
              packageMajor: 0,
              packageMinor: minor,
              engineMajor: 0,
              engineMinor: 1,
            ),
            isTrue,
            reason: 'package minor $minor',
          );
        }
      });

      test('refuses another major or a newer package minor', () {
        expect(
          AudAbi.isCompatible(
            packageMajor: 1,
            packageMinor: 0,
            engineMajor: 0,
            engineMinor: 1,
          ),
          isFalse,
        );
        expect(
          AudAbi.isCompatible(
            packageMajor: 0,
            packageMinor: 2,
            engineMajor: 0,
            engineMinor: 1,
          ),
          isFalse,
        );
      });
    });
  });
}
