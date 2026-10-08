// @license
// Copyright (c) Audanika. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

// The C ABI between the Audanika Audio Engine and its DSP packages.
//
// Spike version (ticket 5, S0-mobile): the subset of decision abi-001 that
// the mobile spike needs - sized structs, an ABI version with a major and a
// minor, capabilities, thread affinity tags on every vtable entry, host
// callbacks with allocator ownership, and the node vtable. Ticket S1 grows
// it into the full contract (state serialization, latency and tail
// reporting, descriptors with presets, the timing contract).
//
// Packages compile against this header and never link the engine: they
// receive an AudHostApi and register their node types through it.

#ifndef AUD_ABI_H
#define AUD_ABI_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

#if _WIN32
#define AUD_EXPORT __declspec(dllexport)
#else
#define AUD_EXPORT __attribute__((visibility("default")))
#endif

// The ABI version. A package built against major N runs on every engine of
// major N whose minor is at least the package's minor.
#define AUD_ABI_VERSION_MAJOR 0
#define AUD_ABI_VERSION_MINOR 1

// Result codes of ABI calls and engine functions.
enum {
  AUD_OK = 0,
  AUD_ERROR_INVALID_ARGUMENT = -1,
  AUD_ERROR_ABI_MAJOR = -2,
  AUD_ERROR_ABI_MINOR = -3,
  AUD_ERROR_DUPLICATE_TYPE = -4,
  AUD_ERROR_UNKNOWN_TYPE = -5,
  AUD_ERROR_QUEUE_FULL = -6,
  AUD_ERROR_OUT_OF_MEMORY = -7,
  AUD_ERROR_STATE = -8,
  AUD_ERROR_FAILED = -9,
};

// Capabilities a node type declares.
enum {
  // The node renders its input bus in place: inputs and outputs alias.
  AUD_NODE_CAP_IN_PLACE = 1 << 0,
  // The node accepts any frame count up to the prepared maximum.
  AUD_NODE_CAP_VARIABLE_BLOCK = 1 << 1,
  // The node consumes events (notes, controls).
  AUD_NODE_CAP_EVENTS = 1 << 2,
  // The node accepts string settings on the control thread.
  AUD_NODE_CAP_STRINGS = 1 << 3,
};

// Thread affinity tags. Every vtable entry is documented with the thread
// that calls it.
enum {
  AUD_THREAD_CONTROL = 0,
  AUD_THREAD_REALTIME = 1,
};

// Log levels of AudHostApi.log.
enum {
  AUD_LOG_DEBUG = 0,
  AUD_LOG_INFO = 1,
  AUD_LOG_WARNING = 2,
  AUD_LOG_ERROR = 3,
};

// Event types.
enum {
  AUD_EVENT_NOTE_ON = 1,
  AUD_EVENT_NOTE_OFF = 2,
  AUD_EVENT_CONTROL = 3,
};

// An event delivered to a node before the block it belongs to.
typedef struct AudEvent {
  uint32_t struct_size;
  uint32_t type;           // AUD_EVENT_*
  uint32_t sample_offset;  // offset inside the block; the spike applies 0
  uint32_t channel;        // MIDI channel 0..15
  uint32_t number;         // note number or controller number
  float value;             // velocity 0..1 or controller value
} AudEvent;

// A parameter of a node type.
typedef struct AudParamDescriptor {
  uint32_t struct_size;
  const char* id;    // stable identifier, e.g. "frequency"
  const char* name;  // display name
  const char* unit;  // "Hz", "dB" or ""
  float min_value;
  float max_value;
  float default_value;
} AudParamDescriptor;

// The block a node renders. Buses are planar: one float array per channel.
typedef struct AudProcessContext {
  uint32_t struct_size;
  uint32_t frames;        // frames in this block, at most the prepared maximum
  uint32_t channels;      // channels per bus
  double sample_rate;
  float* const* inputs;   // input bus; NULL for a source node
  float* const* outputs;  // output bus
} AudProcessContext;

typedef struct AudNodeDescriptor AudNodeDescriptor;
typedef struct AudHostApi AudHostApi;

// The functions of a node type. The tag in brackets names the calling
// thread.
typedef struct AudNodeVTable {
  uint32_t struct_size;
  // [control] Creates an instance; returns NULL on failure.
  void* (*create)(const AudNodeDescriptor* descriptor, const AudHostApi* host);
  // [control] Destroys an instance.
  void (*destroy)(void* instance);
  // [control] Prepares the instance for a sample rate, a largest block and a
  // channel count; called before the first process call and on every change.
  int32_t (*prepare)(void* instance, double sample_rate, uint32_t max_frames,
                     uint32_t channels);
  // [realtime] Resets the state (stop, seek).
  void (*reset)(void* instance);
  // [realtime] Sets a parameter by its index in the descriptor.
  void (*set_param)(void* instance, uint32_t param_index, float value);
  // [realtime] Delivers an event; NULL unless AUD_NODE_CAP_EVENTS is set.
  void (*event)(void* instance, const AudEvent* event);
  // [realtime] Renders one block; no allocation, no lock, no I/O.
  void (*process)(void* instance, const AudProcessContext* context);
  // [control] Applies a string setting; NULL unless AUD_NODE_CAP_STRINGS is
  // set. May block.
  int32_t (*set_string)(void* instance, uint32_t key, const char* value);
} AudNodeVTable;

// A node type a package registers.
struct AudNodeDescriptor {
  uint32_t struct_size;
  uint32_t abi_major;  // the ABI the package was built against
  uint32_t abi_minor;
  const char* type_id;  // e.g. "aud.effects.tremolo"
  const char* name;     // display name
  uint32_t capabilities;  // AUD_NODE_CAP_* flags
  uint32_t num_inputs;    // audio buses; 0 or 1 in the spike
  uint32_t num_outputs;   // audio buses; 1 in the spike
  uint32_t num_params;
  const AudParamDescriptor* params;
  const AudNodeVTable* vtable;
};

// What the engine offers a package. Memory crossing the ABI is owned by the
// engine's allocator.
struct AudHostApi {
  uint32_t struct_size;
  uint32_t abi_major;  // the engine's ABI
  uint32_t abi_minor;
  void* host;  // opaque engine handle, passed back to every callback
  // [control] Registers a node type; AUD_OK or an error code.
  int32_t (*register_node_type)(void* host,
                                const AudNodeDescriptor* descriptor);
  // [control] Allocates memory for non-realtime work.
  void* (*alloc)(void* host, size_t bytes);
  // [control] Frees memory from alloc.
  void (*free)(void* host, void* memory);
  // [control] Logs a message; never called on the realtime thread.
  void (*log)(void* host, int32_t level, const char* message);
};

// The signature of the registration entry point every DSP package exports
// as `int32_t aud_<package>_register(const AudHostApi* host)`.
typedef int32_t (*AudRegisterFunction)(const AudHostApi* host);

// [realtime] The render interface between a host of the engine and the
// engine (plugin-002): the host supplies an interleaved output buffer, the
// engine fills `frames` frames of `channels` channels. aud_audio_io calls
// it from its stream callback.
typedef void (*AudRenderCallback)(void* user, float* interleaved_output,
                                  uint32_t frames, uint32_t channels);

#ifdef __cplusplus
}
#endif

#endif  // AUD_ABI_H
