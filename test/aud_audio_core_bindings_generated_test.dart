// @license
// Copyright (c) Audanika. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:ffi';

import 'package:aud_audio_core/aud_audio_core.dart';
import 'package:ffi/ffi.dart';
import 'package:test/test.dart';

void main() {
  group('aud_audio_core_bindings_generated.dart', () {
    test('exposes the result codes and capabilities of aud_abi.h', () {
      expect(AUD_OK, 0);
      expect(AUD_ERROR_ABI_MAJOR, -2);
      expect(AUD_ERROR_QUEUE_FULL, -6);
      expect(AUD_NODE_CAP_IN_PLACE | AUD_NODE_CAP_EVENTS, 5);
      expect(AUD_EVENT_NOTE_ON, 1);
      expect(AUD_THREAD_REALTIME, 1);
      expect(AUD_LOG_ERROR, 3);
    });

    test('lays out AudHostApi and AudNodeDescriptor as C does', () {
      final host = calloc<AudHostApi>();
      host.ref
        ..struct_size = sizeOf<AudHostApi>()
        ..abi_major = AUD_ABI_VERSION_MAJOR
        ..abi_minor = AUD_ABI_VERSION_MINOR;
      expect(host.ref.struct_size, aud_abi_sizeof_host_api());
      expect(host.ref.register_node_type, nullptr);
      calloc.free(host);

      final descriptor = calloc<AudNodeDescriptor>();
      final typeId = 'aud.test.node'.toNativeUtf8();
      descriptor.ref
        ..struct_size = sizeOf<AudNodeDescriptor>()
        ..type_id = typeId.cast()
        ..num_params = 0;
      expect(descriptor.ref.struct_size, aud_abi_sizeof_node_descriptor());
      expect(
        descriptor.ref.type_id.cast<Utf8>().toDartString(),
        'aud.test.node',
      );
      calloc.free(typeId);
      calloc.free(descriptor);
    });
  });
}
