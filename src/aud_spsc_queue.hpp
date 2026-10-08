// @license
// Copyright (c) Audanika. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

// A fixed-capacity, lock-free single-producer single-consumer queue
// (decision interop-002): one producer thread pushes, the realtime thread
// pops. A full queue rejects the push; nothing is dropped silently. Header
// only; the capacity is a power of two.

#ifndef AUD_SPSC_QUEUE_HPP
#define AUD_SPSC_QUEUE_HPP

#include <atomic>
#include <cstddef>
#include <cstdint>
#include <memory>

template <typename T>
class AudSpscQueue {
 public:
  // Creates a queue whose capacity is the next power of two of `capacity`.
  explicit AudSpscQueue(size_t capacity)
      : capacity_(nextPowerOfTwo(capacity)),
        mask_(capacity_ - 1),
        slots_(new T[capacity_]),
        head_(0),
        tail_(0) {}

  // Pushes an item; returns false when the queue is full.
  bool push(const T& item) {
    const uint64_t tail = tail_.load(std::memory_order_relaxed);
    const uint64_t head = head_.load(std::memory_order_acquire);
    if (tail - head >= capacity_) return false;
    slots_[tail & mask_] = item;
    tail_.store(tail + 1, std::memory_order_release);
    return true;
  }

  // Pops an item; returns false when the queue is empty.
  bool pop(T& item) {
    const uint64_t head = head_.load(std::memory_order_relaxed);
    const uint64_t tail = tail_.load(std::memory_order_acquire);
    if (head == tail) return false;
    item = slots_[head & mask_];
    head_.store(head + 1, std::memory_order_release);
    return true;
  }

  // The number of items the queue can hold.
  size_t capacity() const { return capacity_; }

 private:
  static size_t nextPowerOfTwo(size_t value) {
    size_t result = 1;
    while (result < value) result <<= 1;
    return result;
  }

  const size_t capacity_;
  const size_t mask_;
  std::unique_ptr<T[]> slots_;
  alignas(64) std::atomic<uint64_t> head_;
  alignas(64) std::atomic<uint64_t> tail_;
};

#endif  // AUD_SPSC_QUEUE_HPP
