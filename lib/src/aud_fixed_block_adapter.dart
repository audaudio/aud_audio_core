// @license
// Copyright (c) Audanika. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import 'aud_audio_core_bindings_generated.dart' as bindings;

/// Renders one fixed block from [input] to [output], one list per channel.
typedef AudRenderBlock =
    void Function(List<Float32List> input, List<Float32List> output);

// #############################################################################
/// The fixed-block adapter of decision graph-002,
/// `aud_fixed_block_adapter.hpp` of the native core: re-blocks variable
/// blocks into blocks of a fixed size for processing that needs a constant
/// frame count. The output lags the input by one block, the [latency].
class AudFixedBlockAdapter {
  /// Creates an adapter for [blockSize] frames and [channels] channels.
  AudFixedBlockAdapter({required this.blockSize, required this.channels})
    : _adapter = bindings.aud_core_fixed_block_adapter_create(
        blockSize,
        channels,
      ) {
    if (_adapter == nullptr) {
      throw ArgumentError('blockSize and channels must be positive');
    }
    _callable =
        NativeCallable<
          bindings.AudCoreRenderBlockFunctionFunction
        >.isolateLocal(_onRenderBlock);
  }

  // ...........................................................................
  /// The block size in frames.
  final int blockSize;

  /// The channel count.
  final int channels;

  /// The latency the adapter adds, in frames: one block.
  int get latency {
    _checkNotDisposed();
    return bindings.aud_core_fixed_block_adapter_latency(_adapter);
  }

  // ...........................................................................
  /// Processes the frames of [input] into [output] (one list per channel,
  /// equal lengths); [renderBlock] renders every full block.
  void process({
    required List<Float32List> input,
    required List<Float32List> output,
    required AudRenderBlock renderBlock,
  }) {
    _checkNotDisposed();
    if (input.length != channels || output.length != channels) {
      throw ArgumentError('input and output need $channels channels');
    }
    final frames = input.first.length;
    if (input.any((c) => c.length != frames) ||
        output.any((c) => c.length != frames)) {
      throw ArgumentError('every channel needs $frames frames');
    }
    final inPointers = calloc<Pointer<Float>>(channels);
    final outPointers = calloc<Pointer<Float>>(channels);
    try {
      for (var c = 0; c < channels; c++) {
        inPointers[c] = calloc<Float>(frames);
        outPointers[c] = calloc<Float>(frames);
        inPointers[c].asTypedList(frames).setAll(0, input[c]);
      }
      _renderBlock = renderBlock;
      bindings.aud_core_fixed_block_adapter_process(
        _adapter,
        inPointers,
        outPointers,
        frames,
        _callable.nativeFunction,
        nullptr,
      );
      for (var c = 0; c < channels; c++) {
        output[c].setAll(0, outPointers[c].asTypedList(frames));
      }
    } finally {
      _renderBlock = null;
      for (var c = 0; c < channels; c++) {
        calloc.free(inPointers[c]);
        calloc.free(outPointers[c]);
      }
      calloc.free(inPointers);
      calloc.free(outPointers);
    }
  }

  /// Clears the collected input and the pending output.
  void reset() {
    _checkNotDisposed();
    bindings.aud_core_fixed_block_adapter_reset(_adapter);
  }

  // ...........................................................................
  /// Frees the native adapter.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _callable.close();
    bindings.aud_core_fixed_block_adapter_destroy(_adapter);
  }

  final Pointer<bindings.AudCoreFixedBlockAdapter> _adapter;
  late final NativeCallable<bindings.AudCoreRenderBlockFunctionFunction>
  _callable;
  AudRenderBlock? _renderBlock;
  bool _disposed = false;

  void _onRenderBlock(
    Pointer<Void> user,
    Pointer<Pointer<Float>> input,
    Pointer<Pointer<Float>> output,
    int blockSize,
  ) {
    final inLists = [
      for (var c = 0; c < channels; c++) input[c].asTypedList(blockSize),
    ];
    final outLists = [
      for (var c = 0; c < channels; c++) output[c].asTypedList(blockSize),
    ];
    _renderBlock!(inLists, outLists);
  }

  void _checkNotDisposed() {
    if (_disposed) throw StateError('The adapter is disposed');
  }
}
