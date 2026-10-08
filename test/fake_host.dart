// @license
// Copyright (c) Audanika. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:ffi';

import 'package:aud_audio_core/aud_audio_core.dart';
import 'package:aud_audio_core/aud_audio_core_bindings.dart' as native;
import 'package:ffi/ffi.dart';

/// A fake host: records the descriptors a package registers and answers
/// with a configurable result. Registration runs synchronously on the
/// calling thread, so an isolate-local callable serves as the callback.
class FakeHost {
  /// Creates a host answering [result] with the ABI [abiMajor].[abiMinor].
  FakeHost({
    this.result = AUD_OK,
    int abiMajor = AudAbi.major,
    int abiMinor = AudAbi.minor,
    int? structSize,
  }) {
    api = calloc<native.AudHostApi>();
    api.ref
      ..struct_size = structSize ?? sizeOf<native.AudHostApi>()
      ..abi_major = abiMajor
      ..abi_minor = abiMinor
      ..abi_oldest_minor = abiMinor
      ..host = api.cast()
      ..register_node_type = _register.nativeFunction;
  }

  /// The result the host answers.
  final int result;

  /// The native host api.
  late final Pointer<native.AudHostApi> api;

  /// The registered descriptors.
  final List<Pointer<native.AudNodeDescriptor>> descriptors = [];

  late final _register =
      NativeCallable<
        Int32 Function(Pointer<Void>, Pointer<native.AudNodeDescriptor>)
      >.isolateLocal(_onRegister, exceptionalReturn: AUD_ERROR_FAILED);

  int _onRegister(Pointer<Void> host, Pointer<native.AudNodeDescriptor> d) {
    if (host != api.cast<Void>()) return AUD_ERROR_INVALID_ARGUMENT;
    descriptors.add(d);
    return result;
  }

  /// Frees the host.
  void dispose() {
    _register.close();
    calloc.free(api);
  }
}
