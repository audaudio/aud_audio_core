// @license
// Copyright (c) Audanika. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

/// The raw ffigen bindings of the native core, including the native structs
/// whose names the Dart contracts of `aud_audio_core.dart` reuse
/// (`AudEvent`, `AudNodeDescriptor`, ...). Import this library to build or
/// read the native structs, e.g. in a host or a node test.
library;

export 'src/aud_audio_core_bindings_generated.dart';
