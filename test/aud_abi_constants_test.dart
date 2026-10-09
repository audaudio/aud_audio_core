// @license
// Copyright (c) Audanika. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:aud_audio_core/aud_audio_core.dart';
import 'package:aud_audio_core/aud_audio_core_bindings.dart' as bindings;
import 'package:test/test.dart';

void main() {
  group('aud_abi_constants.dart', () {
    test('matches the ffigen bindings', () async {
      final result = await Process.run('node', [
        'scripts/generate-abi-constants.js',
        'lib/src/aud_audio_core_bindings_generated.dart',
        'lib/src/aud_abi_constants.dart',
        '--check',
      ]);
      expect(result.exitCode, 0, reason: '${result.stderr}');
    });

    test('carries the values of the native header', () {
      expect(AUD_ABI_VERSION_MAJOR, bindings.AUD_ABI_VERSION_MAJOR);
      expect(AUD_ERROR_OVERLOAD, bindings.AUD_ERROR_OVERLOAD);
      expect(AUD_CORE_GAIN_TYPE_ID, bindings.AUD_CORE_GAIN_TYPE_ID);
    });
  });
}
