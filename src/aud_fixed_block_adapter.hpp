// @license
// Copyright (c) Audanika. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

// The fixed-block adapter of decision graph-002: a node that needs a
// constant frame count (FFT, partitioned convolution) re-blocks the
// variable blocks of the engine inside itself. Input frames collect until
// a full block exists, the block is rendered, and its output is handed out
// frame by frame while the next block collects; the output therefore lags
// the input by one block, the latency the node reports to the compiler.
// Allocates in the constructor only.

#ifndef AUD_FIXED_BLOCK_ADAPTER_HPP
#define AUD_FIXED_BLOCK_ADAPTER_HPP

#include <cstdint>
#include <vector>

class AudFixedBlockAdapter {
 public:
  // Creates an adapter for blocks of `blockSize` frames and `channels`
  // channels.
  AudFixedBlockAdapter(uint32_t blockSize, uint32_t channels)
      : blockSize_(blockSize),
        channels_(channels),
        input_(channels, std::vector<float>(blockSize, 0)),
        output_(channels, std::vector<float>(blockSize, 0)),
        inputPointers_(channels),
        outputPointers_(channels) {
    for (uint32_t c = 0; c < channels; ++c) {
      inputPointers_[c] = input_[c].data();
      outputPointers_[c] = output_[c].data();
    }
  }

  // The latency the adapter adds, in frames: one block.
  uint32_t latency() const { return blockSize_; }

  // The block size in frames.
  uint32_t blockSize() const { return blockSize_; }

  // The channel count.
  uint32_t channels() const { return channels_; }

  // Clears the collected input and the pending output.
  void reset() {
    position_ = 0;
    for (auto& channel : input_) channel.assign(blockSize_, 0);
    for (auto& channel : output_) channel.assign(blockSize_, 0);
  }

  // Processes `frames` frames from `in` to `out` (planar, `channels()`
  // arrays each; `in` and `out` may alias). Whenever a block is full,
  // `renderBlock(const float* const* in, float* const* out, uint32_t
  // blockSize)` renders it.
  template <class RenderBlock>
  void process(const float* const* in, float* const* out, uint32_t frames,
               RenderBlock renderBlock) {
    for (uint32_t i = 0; i < frames; ++i) {
      for (uint32_t c = 0; c < channels_; ++c) {
        const float sample = in[c][i];
        out[c][i] = output_[c][position_];
        input_[c][position_] = sample;
      }
      if (++position_ == blockSize_) {
        renderBlock(static_cast<const float* const*>(inputPointers_.data()),
                    outputPointers_.data(), blockSize_);
        position_ = 0;
      }
    }
  }

 private:
  uint32_t blockSize_;
  uint32_t channels_;
  uint32_t position_ = 0;
  std::vector<std::vector<float>> input_;
  std::vector<std::vector<float>> output_;
  std::vector<const float*> inputPointers_;
  std::vector<float*> outputPointers_;
};

#endif  // AUD_FIXED_BLOCK_ADAPTER_HPP
