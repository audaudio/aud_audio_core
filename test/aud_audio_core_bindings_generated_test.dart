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

void main() {
  group('aud_audio_core_bindings_generated.dart', () {
    test('exposes the constants of aud_abi.h', () {
      expect(AUD_OK, 0);
      expect(AUD_PENDING, 1);
      expect(AUD_ERROR_NOT_FOUND, -14);
      expect(AUD_NODE_CAP_RESET_ON_SEEK, 1 << 10);
      expect(AUD_THREAD_OFFLINE, 2);
      expect(AUD_TIME_BEAT, 3);
      expect(AUD_BEAT_FACTOR, 1 << 31);
      expect(AUD_TAIL_INFINITE, 0xFFFFFFFF);
      expect(AUD_ARG_FLOAT, 'f'.codeUnitAt(0));
      expect(AUD_CORE_GAIN_TYPE_ID, 'aud.core.gain');
    });

    test('lays out AudHostApi and AudNodeDescriptor as C does', () {
      final host = calloc<native.AudHostApi>();
      host.ref
        ..struct_size = sizeOf<native.AudHostApi>()
        ..abi_major = AUD_ABI_VERSION_MAJOR
        ..abi_minor = AUD_ABI_VERSION_MINOR;
      expect(host.ref.struct_size, AudAbiNative.nativeSizeOf('AudHostApi'));
      expect(host.ref.register_node_type, nullptr);
      expect(host.ref.emit_event, nullptr);
      calloc.free(host);

      final descriptor = calloc<native.AudNodeDescriptor>();
      final typeId = 'aud.test.node'.toNativeUtf8();
      descriptor.ref
        ..struct_size = sizeOf<native.AudNodeDescriptor>()
        ..type_id = typeId.cast()
        ..num_params = 0;
      expect(
        descriptor.ref.struct_size,
        AudAbiNative.nativeSizeOf('AudNodeDescriptor'),
      );
      expect(
        descriptor.ref.type_id.cast<Utf8>().toDartString(),
        'aud.test.node',
      );
      calloc.free(typeId);
      calloc.free(descriptor);
    });
  });
}
