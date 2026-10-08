// @license
// Copyright (c) Audanika. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:ffi';

import 'aud_audio_core_bindings_generated.dart' as bindings;
import 'aud_core_exception.dart';

// #############################################################################
/// The reference node `aud.core.gain` the native core registers: a gain
/// with one ramped parameter, built on `AudNodeBase` of `aud_node_base.hpp`.
/// It is the proof of the base class and the pattern every DSP package
/// follows.
abstract final class AudCoreGain {
  /// The type id of the node.
  static const String typeId = bindings.AUD_CORE_GAIN_TYPE_ID;

  /// The index of the parameter `gain`.
  static const int gain = bindings.AUD_CORE_GAIN_PARAM_GAIN;

  /// The version of the state blob the node writes: one float, the gain.
  static const int stateVersion = bindings.AUD_CORE_GAIN_STATE_VERSION;

  // ...........................................................................
  /// Registers the node with the engine behind [host].
  ///
  /// - [host] the `AudHostApi` of the engine
  ///
  /// Throws an [AudCoreException] when the host refuses the node.
  static void register(Pointer<bindings.AudHostApi> host) {
    final result = bindings.aud_audio_core_register(host);
    if (result != bindings.AUD_OK) {
      throw AudCoreException(result, 'The host refused aud.core.gain');
    }
  }
}
