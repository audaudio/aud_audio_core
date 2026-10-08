// @license
// Copyright (c) Audanika. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:ffi';

import 'aud_audio_core_bindings_generated.dart' as bindings;

// #############################################################################
/// The version of the C ABI in `src/aud_abi.h` and the checks that the Dart
/// contracts agree with the native core.
abstract final class AudAbi {
  /// The major ABI version the Dart side was written against.
  static const int major = bindings.AUD_ABI_VERSION_MAJOR;

  /// The minor ABI version the Dart side was written against.
  static const int minor = bindings.AUD_ABI_VERSION_MINOR;

  // ...........................................................................
  /// The major ABI version compiled into the native core library.
  static int get nativeMajor => bindings.aud_abi_version_major();

  /// The minor ABI version compiled into the native core library.
  static int get nativeMinor => bindings.aud_abi_version_minor();

  // ...........................................................................
  /// The sizes of the ABI structs as the Dart side lays them out, by name.
  static Map<String, int> get dartStructSizes => {
    'AudEvent': sizeOf<bindings.AudEvent>(),
    'AudParamDescriptor': sizeOf<bindings.AudParamDescriptor>(),
    'AudProcessContext': sizeOf<bindings.AudProcessContext>(),
    'AudNodeVTable': sizeOf<bindings.AudNodeVTable>(),
    'AudNodeDescriptor': sizeOf<bindings.AudNodeDescriptor>(),
    'AudHostApi': sizeOf<bindings.AudHostApi>(),
  };

  /// The sizes of the ABI structs as the C compiler lays them out, by name.
  static Map<String, int> get nativeStructSizes => {
    'AudEvent': bindings.aud_abi_sizeof_event(),
    'AudParamDescriptor': bindings.aud_abi_sizeof_param_descriptor(),
    'AudProcessContext': bindings.aud_abi_sizeof_process_context(),
    'AudNodeVTable': bindings.aud_abi_sizeof_node_vtable(),
    'AudNodeDescriptor': bindings.aud_abi_sizeof_node_descriptor(),
    'AudHostApi': bindings.aud_abi_sizeof_host_api(),
  };

  // ...........................................................................
  /// The name of a result code of the ABI, e.g. `AUD_ERROR_QUEUE_FULL`.
  static String resultName(int code) => switch (code) {
    bindings.AUD_OK => 'AUD_OK',
    bindings.AUD_ERROR_INVALID_ARGUMENT => 'AUD_ERROR_INVALID_ARGUMENT',
    bindings.AUD_ERROR_ABI_MAJOR => 'AUD_ERROR_ABI_MAJOR',
    bindings.AUD_ERROR_ABI_MINOR => 'AUD_ERROR_ABI_MINOR',
    bindings.AUD_ERROR_DUPLICATE_TYPE => 'AUD_ERROR_DUPLICATE_TYPE',
    bindings.AUD_ERROR_UNKNOWN_TYPE => 'AUD_ERROR_UNKNOWN_TYPE',
    bindings.AUD_ERROR_QUEUE_FULL => 'AUD_ERROR_QUEUE_FULL',
    bindings.AUD_ERROR_OUT_OF_MEMORY => 'AUD_ERROR_OUT_OF_MEMORY',
    bindings.AUD_ERROR_STATE => 'AUD_ERROR_STATE',
    bindings.AUD_ERROR_FAILED => 'AUD_ERROR_FAILED',
    _ => 'AUD_RESULT_$code',
  };

  // ...........................................................................
  /// Whether a package built against [packageMajor].[packageMinor] runs on an
  /// engine of [engineMajor].[engineMinor]: the majors are equal and the
  /// engine's minor is at least the package's.
  static bool isCompatible({
    required int packageMajor,
    required int packageMinor,
    required int engineMajor,
    required int engineMinor,
  }) => packageMajor == engineMajor && packageMinor <= engineMinor;
}
