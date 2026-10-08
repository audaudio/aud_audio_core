// @license
// Copyright (c) Audanika. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

// The C ABI between the Audanika Audio Engine and its DSP packages
// (decision abi-001), with the event formats (midi-001, osc-001) and the
// timing contract (time-001).
//
// Rules of the contract:
//
// - Every struct starts with its size, so that a newer side recognizes an
//   older struct and reads only what it holds.
// - The ABI carries a major and a minor version. A package registers its
//   node types with the version it was built against. In major 0 the minors
//   must match exactly (the contract still moves). From major 1 on, a
//   package built against major N runs on every engine of major N whose
//   minor is at least the package's; the engine reports the oldest package
//   minor it still accepts.
// - Every function is tagged with the thread that calls it: [control] the
//   control thread, [realtime] the audio thread (no allocation, no lock,
//   no I/O, no exception), [offline] any thread while no realtime call of
//   the instance is in flight (may block).
// - Memory crossing the ABI is owned by the engine: packages allocate
//   through the host's allocator for non-realtime work and never in a
//   realtime call.
// - No C++ exception crosses the boundary; errors are result codes and a
//   message through the host's log.
// - A DSP package exports one registration symbol,
//   `int32_t aud_<package>_register(const AudHostApi* host)`, keeps every
//   other symbol namespaced and never links the engine.
//
// Packages compile against this header and never link the core.

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

// The ABI version.
#define AUD_ABI_VERSION_MAJOR 0
#define AUD_ABI_VERSION_MINOR 3

// Result codes of ABI calls and engine functions.
enum {
  AUD_OK = 0,
  // The time lies after the block being rendered; try again next block.
  AUD_PENDING = 1,
  AUD_ERROR_INVALID_ARGUMENT = -1,
  AUD_ERROR_ABI_MAJOR = -2,
  AUD_ERROR_ABI_MINOR = -3,
  AUD_ERROR_DUPLICATE_TYPE = -4,
  AUD_ERROR_UNKNOWN_TYPE = -5,
  AUD_ERROR_QUEUE_FULL = -6,
  AUD_ERROR_OUT_OF_MEMORY = -7,
  AUD_ERROR_STATE = -8,
  AUD_ERROR_FAILED = -9,
  // The call is not supported by the instance, e.g. no state.
  AUD_ERROR_UNSUPPORTED = -10,
  // The buffer is too small; the needed size is reported.
  AUD_ERROR_BUFFER_TOO_SMALL = -11,
  // A state blob of a version the node cannot read.
  AUD_ERROR_STATE_VERSION = -12,
  // The timestamp lies before the block being rendered.
  AUD_ERROR_LATE = -13,
  // The handle, id or address names nothing.
  AUD_ERROR_NOT_FOUND = -14,
  // The connection would close a cycle; feedback runs through a feedback
  // node (graph-001).
  AUD_ERROR_CYCLE = -15,
  // A bus format the node or the connection does not accept.
  AUD_ERROR_FORMAT = -16,
  // The timestamp lies beyond the scheduling lookahead (interop-002).
  AUD_ERROR_LOOKAHEAD = -17,
  // A fixed capacity is exhausted: nodes, connections, scheduled events.
  AUD_ERROR_CAPACITY = -18,
  // The node is retired: a transaction removed it (graph-003).
  AUD_ERROR_RETIRED = -19,
  // The render of a block took longer than the block lasts; a diagnostic.
  AUD_ERROR_OVERLOAD = -20,
};

// Capabilities a node type declares.
enum {
  // The node renders its main input bus in place: inputs and outputs alias.
  AUD_NODE_CAP_IN_PLACE = 1 << 0,
  // The node accepts any frame count up to the prepared maximum; without
  // it the engine wraps the node in the fixed-block adapter.
  AUD_NODE_CAP_VARIABLE_BLOCK = 1 << 1,
  // The node consumes events on its event inputs.
  AUD_NODE_CAP_EVENTS = 1 << 2,
  // The node accepts string settings on the control thread.
  AUD_NODE_CAP_STRINGS = 1 << 3,
  // The node saves and loads its state as a versioned blob.
  AUD_NODE_CAP_STATE = 1 << 4,
  // The node reports a latency in frames.
  AUD_NODE_CAP_LATENCY = 1 << 5,
  // The node reports a tail in frames.
  AUD_NODE_CAP_TAIL = 1 << 6,
  // The node reads the transport snapshot of the block.
  AUD_NODE_CAP_TRANSPORT = 1 << 7,
  // The node emits events through the host on its event outputs.
  AUD_NODE_CAP_EVENT_OUTPUT = 1 << 8,
  // The engine resets the node when the transport stops.
  AUD_NODE_CAP_RESET_ON_STOP = 1 << 9,
  // The engine resets the node when the transport seeks.
  AUD_NODE_CAP_RESET_ON_SEEK = 1 << 10,
};

// Thread affinity tags. Every function is documented with the thread that
// calls it.
enum {
  AUD_THREAD_CONTROL = 0,
  AUD_THREAD_REALTIME = 1,
  AUD_THREAD_OFFLINE = 2,
};

// Log levels of AudHostApi.log.
enum {
  AUD_LOG_DEBUG = 0,
  AUD_LOG_INFO = 1,
  AUD_LOG_WARNING = 2,
  AUD_LOG_ERROR = 3,
};

// Reasons of a reset.
enum {
  AUD_RESET_STOP = 0,
  AUD_RESET_SEEK = 1,
  AUD_RESET_PREPARE = 2,
  AUD_RESET_RECOVERY = 3,
};

// ............................................................................
// Time (time-001)

// The time domains. Sample time is always available and authoritative for
// scheduling; host time is the monotonic clock of aud_clock.h and valid
// only with a source; beat time runs through the transport.
enum {
  AUD_TIME_IMMEDIATE = 0,
  AUD_TIME_SAMPLE = 1,
  AUD_TIME_HOST = 2,
  AUD_TIME_BEAT = 3,
};

// Where a host time comes from: the hardware, an estimate of the backend,
// or synthesized by the engine from the sample clock.
enum {
  AUD_TIME_SOURCE_NONE = 0,
  AUD_TIME_SOURCE_HARDWARE = 1,
  AUD_TIME_SOURCE_ESTIMATED = 2,
  AUD_TIME_SOURCE_SYNTHESIZED = 3,
};

// Beats are fixed point: one beat is AUD_BEAT_FACTOR ticks, as CLAP does.
#define AUD_BEAT_FACTOR ((int64_t)1 << 31)

// A point in time in one of the domains. `value` is a sample position, a
// host time in nanoseconds or a beat position in ticks; immediate ignores
// it.
typedef struct AudTimestamp {
  uint32_t struct_size;
  uint32_t domain;  // AUD_TIME_*
  uint32_t source;  // AUD_TIME_SOURCE_*, for host times
  uint32_t flags;   // reserved, 0
  int64_t value;
} AudTimestamp;

// What a stream delivers with every callback: the sample position of the
// block, the host time at which its first frame reaches the output (for
// input: was captured), with its source and accuracy, and the latencies.
typedef struct AudStreamTime {
  uint32_t struct_size;
  uint32_t frames;
  double sample_rate;
  int64_t sample_position;
  int64_t host_time_ns;
  uint32_t host_time_source;  // AUD_TIME_SOURCE_*
  uint32_t reserved;
  int64_t host_time_accuracy_ns;  // 0 when unknown
  uint32_t output_latency_frames;
  uint32_t input_latency_frames;
} AudStreamTime;

// Capabilities a transport provider declares.
enum {
  AUD_TRANSPORT_CAP_TEMPO = 1 << 0,
  AUD_TRANSPORT_CAP_SEEK = 1 << 1,
  AUD_TRANSPORT_CAP_START_STOP = 1 << 2,
  AUD_TRANSPORT_CAP_TIME_SIGNATURE = 1 << 3,
  AUD_TRANSPORT_CAP_HOST_TIME = 1 << 4,
  AUD_TRANSPORT_CAP_LOOP = 1 << 5,
};

// Flags of a transport segment.
enum {
  AUD_SEGMENT_PLAYING = 1 << 0,
  AUD_SEGMENT_LOOPING = 1 << 1,
  // The segment starts with a seek.
  AUD_SEGMENT_SEEK = 1 << 2,
  // The musical position is discontinuous to the previous segment.
  AUD_SEGMENT_DISCONTINUITY = 1 << 3,
};

// A segment of the transport timeline inside one block: a range of frames
// with a musical position, a tempo and a tempo slope. The beat at frame k
// of the segment is `beat + (tempo * k + tempo_increment * k * k / 2) /
// (60 * sample_rate)` beats while playing; a stopped segment holds its
// position.
typedef struct AudTransportSegment {
  uint32_t struct_size;
  uint32_t sample_offset;  // first frame of the segment inside the block
  uint32_t frames;         // frames of the segment
  uint32_t flags;          // AUD_SEGMENT_*
  int64_t beat;            // musical position at the first frame, ticks
  double tempo;            // beats per minute at the first frame
  double tempo_increment;  // beats per minute per frame
  int64_t bar_start;       // beat of the current bar's start, ticks
  uint32_t time_signature_numerator;
  uint32_t time_signature_denominator;
  int64_t loop_start;  // ticks; valid with AUD_SEGMENT_LOOPING
  int64_t loop_end;    // ticks; valid with AUD_SEGMENT_LOOPING
} AudTransportSegment;

// The per-block snapshot the callback thread captures once before the
// render program runs: the stream's time and the segments covering the
// block. Every conversion between the domains runs over it.
typedef struct AudTransportSnapshot {
  uint32_t struct_size;
  uint32_t capabilities;  // AUD_TRANSPORT_CAP_* of the provider
  uint32_t num_segments;
  uint32_t reserved;
  const AudTransportSegment* segments;
  AudStreamTime time;
} AudTransportSnapshot;

// Requests to a transport provider.
enum {
  AUD_TRANSPORT_REQUEST_START = 1,
  AUD_TRANSPORT_REQUEST_STOP = 2,
  AUD_TRANSPORT_REQUEST_SEEK = 3,
  AUD_TRANSPORT_REQUEST_SET_TEMPO = 4,
  AUD_TRANSPORT_REQUEST_SET_TIME_SIGNATURE = 5,
  AUD_TRANSPORT_REQUEST_SET_LOOP = 6,
  AUD_TRANSPORT_REQUEST_SET_QUANTUM = 7,
};

// A request to the transport: start or stop at a time, seek to a beat, set
// the tempo, the time signature, the loop or the quantum.
typedef struct AudTransportRequest {
  uint32_t struct_size;
  uint32_t type;   // AUD_TRANSPORT_REQUEST_*
  AudTimestamp at;  // when the request takes effect; immediate by default
  int64_t beat;     // seek target, loop start, in ticks
  int64_t beat_end;  // loop end, in ticks
  double value;      // tempo in beats per minute, quantum in beats
  uint32_t numerator;
  uint32_t denominator;
} AudTransportRequest;

typedef struct AudHostApi AudHostApi;

// A transport provider behind the ABI: the internal clock, Ableton Link or
// a plugin host. The engine captures the segments of every block on the
// callback thread; requests reach the provider on the same thread, so a
// provider commits its session state on one thread only.
typedef struct AudTransportProviderVTable {
  uint32_t struct_size;
  // [control] Creates a provider; returns NULL on failure.
  void* (*create)(const AudHostApi* host);
  // [control] Destroys a provider.
  void (*destroy)(void* provider);
  // [control] The AUD_TRANSPORT_CAP_* flags of the provider.
  uint32_t (*capabilities)(void* provider);
  // [realtime] Writes the segments covering the block described by `time`
  // into `segments` (at most `max_segments`) and their number into
  // `num_segments`; AUD_OK or an error code.
  int32_t (*capture)(void* provider, const AudStreamTime* time,
                     AudTransportSegment* segments, uint32_t max_segments,
                     uint32_t* num_segments);
  // [realtime] Applies a request; AUD_ERROR_UNSUPPORTED for a request the
  // capabilities exclude.
  int32_t (*request)(void* provider, const AudTransportRequest* request);
} AudTransportProviderVTable;

// ............................................................................
// Events (midi-001, osc-001, interop-002)

// Event types.
enum {
  // A Universal MIDI Packet: `words` holds one to four words.
  AUD_EVENT_UMP = 1,
  // A numeric control message: words[0] the control id, words[1] the OSC
  // type tag of the argument, words[2] its bits.
  AUD_EVENT_CONTROL = 2,
  // A parameter change: words[0] the parameter index, words[1] the target
  // value as float bits, words[2] the ramp length in frames.
  AUD_EVENT_PARAM = 3,
};

// Flags of an event.
enum {
  // A live event (MIDI input, UI): delivered as early as possible.
  AUD_EVENT_FLAG_LIVE = 1 << 0,
};

// Argument type tags of a control event, the OSC 1.1 type tags.
enum {
  AUD_ARG_INT32 = 'i',
  AUD_ARG_FLOAT = 'f',
  AUD_ARG_TRUE = 'T',
  AUD_ARG_FALSE = 'F',
  AUD_ARG_NIL = 'N',
  AUD_ARG_IMPULSE = 'I',
};

// An event inside a block: a UMP, a control or a parameter event at a
// sample offset on an event port of the node.
typedef struct AudEvent {
  uint32_t struct_size;
  uint32_t type;           // AUD_EVENT_*
  uint32_t sample_offset;  // offset inside the block
  uint32_t port;           // index of the event input of the node
  uint32_t flags;          // AUD_EVENT_FLAG_*
  uint32_t words[4];       // the payload, see the event types
} AudEvent;

// ............................................................................
// Descriptors

// Flags of an audio bus.
enum {
  AUD_BUS_MAIN = 1 << 0,
  AUD_BUS_SIDECHAIN = 1 << 1,
  // The bus may stay unconnected; the node then treats it as silent.
  AUD_BUS_OPTIONAL = 1 << 2,
};

// An audio bus of a node type: a range of channel counts the node accepts.
typedef struct AudBusDescriptor {
  uint32_t struct_size;
  const char* id;    // stable identifier, e.g. "in"
  const char* name;  // display name
  uint32_t flags;    // AUD_BUS_*
  uint32_t min_channels;
  uint32_t max_channels;
  uint32_t default_channels;
} AudBusDescriptor;

// Flags of an event port.
enum {
  AUD_EVENT_PORT_MIDI = 1 << 0,
  AUD_EVENT_PORT_CONTROL = 1 << 1,
};

// An event port of a node type.
typedef struct AudEventPortDescriptor {
  uint32_t struct_size;
  const char* id;    // stable identifier, e.g. "midi"
  const char* name;  // display name
  uint32_t flags;    // AUD_EVENT_PORT_*
  uint32_t reserved;
} AudEventPortDescriptor;

// Flags of a parameter.
enum {
  AUD_PARAM_AUTOMATABLE = 1 << 0,
  // Changes ramp over the frames an AUD_EVENT_PARAM names.
  AUD_PARAM_RAMPED = 1 << 1,
  // The value takes `steps` discrete values between min and max.
  AUD_PARAM_STEPPED = 1 << 2,
  AUD_PARAM_LOGARITHMIC = 1 << 3,
  AUD_PARAM_BOOLEAN = 1 << 4,
  AUD_PARAM_HIDDEN = 1 << 5,
};

// A parameter of a node type.
typedef struct AudParamDescriptor {
  uint32_t struct_size;
  const char* id;    // stable identifier, e.g. "frequency"
  const char* name;  // display name
  const char* unit;  // "Hz", "dB" or ""
  float min_value;
  float max_value;
  float default_value;
  uint32_t flags;  // AUD_PARAM_*
  uint32_t steps;  // with AUD_PARAM_STEPPED
  uint32_t reserved;
} AudParamDescriptor;

// A key of a string setting a node type accepts on the control thread.
typedef struct AudStringKeyDescriptor {
  uint32_t struct_size;
  uint32_t key;      // the key passed to set_string
  const char* id;    // stable identifier, e.g. "sfz_file"
  const char* name;  // display name
} AudStringKeyDescriptor;

// ............................................................................
// Rendering

// A bus of planar audio: one float array per channel.
typedef struct AudAudioBus {
  uint32_t struct_size;
  uint32_t num_channels;
  float* const* channels;
} AudAudioBus;

// Flags of prepare and process.
enum {
  // Rendering runs offline, faster or slower than real time.
  AUD_PROCESS_OFFLINE = 1 << 0,
};

// What an instance is prepared for: the sample rate, the largest block and
// the channel count of every bus.
typedef struct AudPrepareInfo {
  uint32_t struct_size;
  uint32_t max_frames;
  double sample_rate;
  uint32_t flags;  // AUD_PROCESS_*
  uint32_t num_input_buses;
  const uint32_t* input_channels;  // channels per input bus
  uint32_t num_output_buses;
  uint32_t reserved;
  const uint32_t* output_channels;  // channels per output bus
} AudPrepareInfo;

// The block a node renders: its buses, the events that fall into it in
// ascending sample offset, and the transport snapshot for nodes that
// declare AUD_NODE_CAP_TRANSPORT (NULL otherwise).
typedef struct AudProcessContext {
  uint32_t struct_size;
  uint32_t frames;  // frames in this block, at most the prepared maximum
  double sample_rate;
  int64_t sample_position;  // sample position of the first frame
  uint32_t flags;           // AUD_PROCESS_*
  uint32_t num_input_buses;
  const AudAudioBus* inputs;  // NULL for a source node
  uint32_t num_output_buses;
  uint32_t num_events;
  const AudAudioBus* outputs;
  const AudEvent* events;
  const AudTransportSnapshot* transport;
} AudProcessContext;

// A tail that never ends, e.g. a feedback delay or a running generator.
#define AUD_TAIL_INFINITE UINT32_MAX

typedef struct AudNodeDescriptor AudNodeDescriptor;

// The functions of a node type. The tag in brackets names the calling
// thread; an entry a node does not provide is NULL unless the capability
// requires it.
typedef struct AudNodeVTable {
  uint32_t struct_size;
  // [control] Creates an instance; returns NULL on failure.
  void* (*create)(const AudNodeDescriptor* descriptor, const AudHostApi* host);
  // [control] Destroys an instance.
  void (*destroy)(void* instance);
  // [control] Prepares the instance; called before the first process call
  // and on every change of the sample rate, the block size or the buses.
  int32_t (*prepare)(void* instance, const AudPrepareInfo* info);
  // [realtime] Resets the state for a reason (AUD_RESET_*).
  void (*reset)(void* instance, uint32_t reason);
  // [realtime] Sets a parameter immediately by its index in the descriptor.
  void (*set_param)(void* instance, uint32_t param_index, float value);
  // [realtime] Renders one block; no allocation, no lock, no I/O.
  void (*process)(void* instance, const AudProcessContext* context);
  // [control] Applies a string setting; NULL unless AUD_NODE_CAP_STRINGS is
  // set. May block.
  int32_t (*set_string)(void* instance, uint32_t key, const char* value);
  // [control] The latency in frames after prepare; NULL means 0.
  uint32_t (*get_latency)(void* instance);
  // [control] The tail in frames after the input stops, or
  // AUD_TAIL_INFINITE; NULL means 0.
  uint32_t (*get_tail)(void* instance);
  // [offline] Writes the state into `buffer` and its size into `size`;
  // AUD_ERROR_BUFFER_TOO_SMALL with the needed size when `capacity` is
  // too small. NULL unless AUD_NODE_CAP_STATE is set.
  int32_t (*save_state)(void* instance, void* buffer, size_t capacity,
                        size_t* size);
  // [offline] Restores a state saved by `version` of the state format;
  // AUD_ERROR_STATE_VERSION when the node cannot read it. NULL unless
  // AUD_NODE_CAP_STATE is set.
  int32_t (*load_state)(void* instance, const void* data, size_t size,
                        uint32_t version);
} AudNodeVTable;

// A node type a package registers.
struct AudNodeDescriptor {
  uint32_t struct_size;
  uint32_t abi_major;  // the ABI the package was built against
  uint32_t abi_minor;
  uint32_t version;       // the version of the node type
  const char* type_id;    // e.g. "aud.effects.tremolo"
  const char* name;       // display name
  const char* vendor;     // e.g. "Audanika"
  uint32_t capabilities;  // AUD_NODE_CAP_* flags
  uint32_t state_version;  // version of the state blobs it writes
  uint32_t num_input_buses;
  uint32_t num_output_buses;
  const AudBusDescriptor* input_buses;
  const AudBusDescriptor* output_buses;
  uint32_t num_event_inputs;
  uint32_t num_event_outputs;
  const AudEventPortDescriptor* event_inputs;
  const AudEventPortDescriptor* event_outputs;
  uint32_t num_params;
  uint32_t num_string_keys;
  const AudParamDescriptor* params;
  const AudStringKeyDescriptor* string_keys;
  const AudNodeVTable* vtable;
};

// What the engine offers a package. Memory crossing the ABI is owned by the
// engine's allocator.
struct AudHostApi {
  uint32_t struct_size;
  uint32_t abi_major;  // the engine's ABI
  uint32_t abi_minor;
  uint32_t abi_oldest_minor;  // the oldest package minor the engine accepts
  void* host;  // opaque engine handle, passed back to every callback
  // [control] Registers a node type; AUD_OK or an error code.
  int32_t (*register_node_type)(void* host,
                                const AudNodeDescriptor* descriptor);
  // [control] Registers a transport provider under an id, e.g.
  // "aud.link"; AUD_OK or an error code.
  int32_t (*register_transport_provider)(
      void* host, const char* id, const AudTransportProviderVTable* vtable);
  // [control, offline] Allocates memory for non-realtime work.
  void* (*alloc)(void* host, size_t bytes);
  // [control, offline] Frees memory from alloc.
  void (*free)(void* host, void* memory);
  // [control, offline] Logs a message; never called on the realtime thread.
  void (*log)(void* host, int32_t level, const char* message);
  // [realtime] Emits an event on an event output of the instance; only for
  // nodes with AUD_NODE_CAP_EVENT_OUTPUT. `event->port` names the output.
  void (*emit_event)(void* host, void* instance, const AudEvent* event);
};

// The signature of the registration entry point every DSP package exports
// as `int32_t aud_<package>_register(const AudHostApi* host)`.
typedef int32_t (*AudRegisterFunction)(const AudHostApi* host);

// What a host of the engine hands to one render call (plugin-002): the
// buses it supplies, the stream time of the block, the events of the block
// and, for plugin hosts, the transport segments; NULL lets the engine's own
// provider run.
typedef struct AudRenderRequest {
  uint32_t struct_size;
  uint32_t frames;
  uint32_t num_input_buses;
  uint32_t num_output_buses;
  const AudAudioBus* inputs;
  const AudAudioBus* outputs;
  const AudStreamTime* time;
  uint32_t num_events;
  uint32_t reserved;
  const AudEvent* events;
  const AudTransportSnapshot* transport;
} AudRenderRequest;

// [realtime] The render interface between a host of the engine and the
// engine: aud_audio_io calls it from its stream callback, the plugin shells
// from the host's process call, the offline renderer from its loop.
typedef int32_t (*AudRenderFunction)(void* user,
                                     const AudRenderRequest* request);

// ............................................................................
// Helpers

// Builds a parameter event.
static inline AudEvent aud_event_param(uint32_t param_index, float value,
                                       uint32_t ramp_frames,
                                       uint32_t sample_offset) {
  union {
    float f;
    uint32_t u;
  } bits;
  bits.f = value;
  AudEvent event = {sizeof(AudEvent), AUD_EVENT_PARAM, sample_offset, 0, 0,
                    {param_index, bits.u, ramp_frames, 0}};
  return event;
}

// The target value of a parameter event.
static inline float aud_event_param_value(const AudEvent* event) {
  union {
    float f;
    uint32_t u;
  } bits;
  bits.u = event->words[1];
  return bits.f;
}

// Builds a control event with a float argument.
static inline AudEvent aud_event_control_float(uint32_t control, float value,
                                               uint32_t sample_offset,
                                               uint32_t port) {
  union {
    float f;
    uint32_t u;
  } bits;
  bits.f = value;
  AudEvent event = {sizeof(AudEvent), AUD_EVENT_CONTROL, sample_offset, port,
                    0, {control, AUD_ARG_FLOAT, bits.u, 0}};
  return event;
}

// Builds a UMP event from `num_words` words (1 to 4).
static inline AudEvent aud_event_ump(const uint32_t* words, uint32_t num_words,
                                     uint32_t sample_offset, uint32_t port) {
  AudEvent event = {sizeof(AudEvent), AUD_EVENT_UMP, sample_offset, port, 0,
                    {0, 0, 0, 0}};
  uint32_t i;
  for (i = 0; i < num_words && i < 4; ++i) event.words[i] = words[i];
  return event;
}

// Whether a package built against `package_major.package_minor` runs on an
// engine of `engine_major.engine_minor`: the majors are equal and, in
// major 0, the minors too; from major 1 on the engine's minor is at least
// the package's.
static inline int aud_abi_is_compatible(uint32_t package_major,
                                        uint32_t package_minor,
                                        uint32_t engine_major,
                                        uint32_t engine_minor) {
  if (package_major != engine_major) return 0;
  if (package_major == 0) return package_minor == engine_minor;
  return package_minor <= engine_minor;
}

#ifdef __cplusplus
}
#endif

#endif  // AUD_ABI_H
