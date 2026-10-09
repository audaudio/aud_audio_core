// @license
// Copyright (c) Audanika. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import 'aud_abi.dart';
import 'aud_audio_core_bindings_generated.dart' as bindings;

// #############################################################################
/// The checks that the Dart contracts of [AudAbi] agree with the native core.
abstract final class AudAbiNative {
  /// The major ABI version compiled into the native core library.
  static int get nativeMajor => bindings.aud_abi_version_major();

  /// The minor ABI version compiled into the native core library.
  static int get nativeMinor => bindings.aud_abi_version_minor();

  /// The sizes of the ABI structs as the Dart side lays them out, by name.
  static Map<String, int> get dartStructSizes => {
    'AudTimestamp': sizeOf<bindings.AudTimestamp>(),
    'AudStreamTime': sizeOf<bindings.AudStreamTime>(),
    'AudTransportSegment': sizeOf<bindings.AudTransportSegment>(),
    'AudTransportSnapshot': sizeOf<bindings.AudTransportSnapshot>(),
    'AudTransportRequest': sizeOf<bindings.AudTransportRequest>(),
    'AudTransportProviderVTable': sizeOf<bindings.AudTransportProviderVTable>(),
    'AudEvent': sizeOf<bindings.AudEvent>(),
    'AudBusDescriptor': sizeOf<bindings.AudBusDescriptor>(),
    'AudEventPortDescriptor': sizeOf<bindings.AudEventPortDescriptor>(),
    'AudParamDescriptor': sizeOf<bindings.AudParamDescriptor>(),
    'AudStringKeyDescriptor': sizeOf<bindings.AudStringKeyDescriptor>(),
    'AudAudioBus': sizeOf<bindings.AudAudioBus>(),
    'AudPrepareInfo': sizeOf<bindings.AudPrepareInfo>(),
    'AudProcessContext': sizeOf<bindings.AudProcessContext>(),
    'AudNodeVTable': sizeOf<bindings.AudNodeVTable>(),
    'AudNodeDescriptor': sizeOf<bindings.AudNodeDescriptor>(),
    'AudHostApi': sizeOf<bindings.AudHostApi>(),
    'AudRenderRequest': sizeOf<bindings.AudRenderRequest>(),
  };

  /// The sizes of the ABI structs as the C compiler lays them out, by name.
  static Map<String, int> get nativeStructSizes => {
    for (final name in AudAbi.structNames) name: nativeSizeOf(name),
  };

  /// The size of the ABI struct [name] as the C compiler lays it out, or -1
  /// for a name the native core does not know.
  static int nativeSizeOf(String name) {
    final native = name.toNativeUtf8();
    try {
      return bindings.aud_abi_sizeof(native.cast());
    } finally {
      calloc.free(native);
    }
  }

  /// [isCompatible] as the native core decides it.
  static bool nativeIsCompatible({
    required int packageMajor,
    required int packageMinor,
    required int engineMajor,
    required int engineMinor,
  }) =>
      bindings.aud_abi_compatible(
        packageMajor,
        packageMinor,
        engineMajor,
        engineMinor,
      ) !=
      0;
}
