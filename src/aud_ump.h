// @license
// Copyright (c) Audanika. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

// Universal MIDI Packet helpers for nodes (decision midi-001): the packet
// size and the fields of channel voice messages, including the MIDI 2.0
// per-note controllers of MPE and MIDI 2.0, and the construction of the
// packets an engine or a test sends. The Dart side builds packets with
// aud_midi_standard; this header lets C and C++ nodes read them without a
// dependency. Field layouts follow M2-104-UM.

#ifndef AUD_UMP_H
#define AUD_UMP_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

// Message types, the top four bits of the first word.
enum {
  AUD_UMP_TYPE_UTILITY = 0x0,
  AUD_UMP_TYPE_SYSTEM = 0x1,
  AUD_UMP_TYPE_MIDI1_CHANNEL_VOICE = 0x2,
  AUD_UMP_TYPE_DATA64 = 0x3,
  AUD_UMP_TYPE_MIDI2_CHANNEL_VOICE = 0x4,
  AUD_UMP_TYPE_DATA128 = 0x5,
  AUD_UMP_TYPE_FLEX_DATA = 0xD,
  AUD_UMP_TYPE_STREAM = 0xF,
};

// Status nibbles of channel voice messages.
enum {
  AUD_UMP_STATUS_REGISTERED_PER_NOTE_CONTROLLER = 0x0,  // MIDI 2.0
  AUD_UMP_STATUS_ASSIGNABLE_PER_NOTE_CONTROLLER = 0x1,  // MIDI 2.0
  AUD_UMP_STATUS_REGISTERED_CONTROLLER = 0x2,           // MIDI 2.0
  AUD_UMP_STATUS_ASSIGNABLE_CONTROLLER = 0x3,           // MIDI 2.0
  AUD_UMP_STATUS_RELATIVE_REGISTERED_CONTROLLER = 0x4,  // MIDI 2.0
  AUD_UMP_STATUS_RELATIVE_ASSIGNABLE_CONTROLLER = 0x5,  // MIDI 2.0
  AUD_UMP_STATUS_PER_NOTE_PITCH_BEND = 0x6,             // MIDI 2.0
  AUD_UMP_STATUS_NOTE_OFF = 0x8,
  AUD_UMP_STATUS_NOTE_ON = 0x9,
  AUD_UMP_STATUS_POLY_PRESSURE = 0xA,
  AUD_UMP_STATUS_CONTROL_CHANGE = 0xB,
  AUD_UMP_STATUS_PROGRAM_CHANGE = 0xC,
  AUD_UMP_STATUS_CHANNEL_PRESSURE = 0xD,
  AUD_UMP_STATUS_PITCH_BEND = 0xE,
  AUD_UMP_STATUS_PER_NOTE_MANAGEMENT = 0xF,  // MIDI 2.0
};

// The message type of a packet.
static inline uint32_t aud_ump_message_type(uint32_t word0) {
  return word0 >> 28;
}

// The number of words of a packet, 1 to 4, by its message type.
static inline uint32_t aud_ump_word_count(uint32_t word0) {
  static const uint8_t counts[16] = {1, 1, 1, 2, 2, 4, 1, 1,
                                     2, 2, 2, 3, 3, 4, 4, 4};
  return counts[aud_ump_message_type(word0)];
}

// The group of a packet, 0 to 15.
static inline uint32_t aud_ump_group(uint32_t word0) {
  return (word0 >> 24) & 0xF;
}

// The status nibble of a channel voice message.
static inline uint32_t aud_ump_status(uint32_t word0) {
  return (word0 >> 20) & 0xF;
}

// The channel of a channel voice message, 0 to 15.
static inline uint32_t aud_ump_channel(uint32_t word0) {
  return (word0 >> 16) & 0xF;
}

// Whether a packet is a MIDI 1.0 or MIDI 2.0 channel voice message.
static inline int aud_ump_is_channel_voice(uint32_t word0) {
  const uint32_t type = aud_ump_message_type(word0);
  return type == AUD_UMP_TYPE_MIDI1_CHANNEL_VOICE ||
         type == AUD_UMP_TYPE_MIDI2_CHANNEL_VOICE;
}

// The note number of a note, poly pressure or per-note message.
static inline uint32_t aud_ump_note(uint32_t word0) {
  return (word0 >> 8) & 0x7F;
}

// The first data byte of a MIDI 1.0 channel voice message.
static inline uint32_t aud_ump_midi1_data1(uint32_t word0) {
  return (word0 >> 8) & 0x7F;
}

// The second data byte of a MIDI 1.0 channel voice message.
static inline uint32_t aud_ump_midi1_data2(uint32_t word0) {
  return word0 & 0x7F;
}

// Whether a packet is a note on with a velocity above zero (a MIDI 1.0
// note on with velocity zero is a note off).
static inline int aud_ump_is_note_on(uint32_t word0, uint32_t word1) {
  if (!aud_ump_is_channel_voice(word0)) return 0;
  if (aud_ump_status(word0) != AUD_UMP_STATUS_NOTE_ON) return 0;
  if (aud_ump_message_type(word0) == AUD_UMP_TYPE_MIDI1_CHANNEL_VOICE) {
    return aud_ump_midi1_data2(word0) != 0;
  }
  return (word1 >> 16) != 0;
}

// Whether a packet is a note off, including a MIDI 1.0 note on with
// velocity zero.
static inline int aud_ump_is_note_off(uint32_t word0, uint32_t word1) {
  if (!aud_ump_is_channel_voice(word0)) return 0;
  const uint32_t status = aud_ump_status(word0);
  if (status == AUD_UMP_STATUS_NOTE_OFF) return 1;
  if (status != AUD_UMP_STATUS_NOTE_ON) return 0;
  if (aud_ump_message_type(word0) == AUD_UMP_TYPE_MIDI1_CHANNEL_VOICE) {
    return aud_ump_midi1_data2(word0) == 0;
  }
  return (word1 >> 16) == 0;
}

// The velocity of a note message as a unit value, 0 to 1.
static inline float aud_ump_note_velocity(uint32_t word0, uint32_t word1) {
  if (aud_ump_message_type(word0) == AUD_UMP_TYPE_MIDI1_CHANNEL_VOICE) {
    return (float)aud_ump_midi1_data2(word0) / 127.0f;
  }
  return (float)(word1 >> 16) / 65535.0f;
}

// Whether a packet is a registered or assignable per-note controller.
static inline int aud_ump_is_per_note_controller(uint32_t word0) {
  if (aud_ump_message_type(word0) != AUD_UMP_TYPE_MIDI2_CHANNEL_VOICE) return 0;
  const uint32_t status = aud_ump_status(word0);
  return status == AUD_UMP_STATUS_REGISTERED_PER_NOTE_CONTROLLER ||
         status == AUD_UMP_STATUS_ASSIGNABLE_PER_NOTE_CONTROLLER;
}

// The controller index of a per-note controller message, 0 to 255.
static inline uint32_t aud_ump_per_note_controller_index(uint32_t word0) {
  return word0 & 0xFF;
}

// The 32-bit value of a per-note controller, a MIDI 2.0 control change
// or a per-note pitch bend as a unit value, 0 to 1.
static inline float aud_ump_unit_value(uint32_t word1) {
  return (float)((double)word1 / 4294967295.0);
}

// Builds the word of a MIDI 1.0 channel voice message in a packet, e.g.
// `aud_ump_midi1_word(0, 0x90, 60, 100)` for a note on.
static inline uint32_t aud_ump_midi1_word(uint32_t group, uint32_t status_byte,
                                          uint32_t data1, uint32_t data2) {
  return ((uint32_t)AUD_UMP_TYPE_MIDI1_CHANNEL_VOICE << 28) |
         ((group & 0xF) << 24) | ((status_byte & 0xFF) << 16) |
         ((data1 & 0x7F) << 8) | (data2 & 0x7F);
}

// Builds the first word of a MIDI 2.0 channel voice message.
static inline uint32_t aud_ump_midi2_word0(uint32_t group, uint32_t status,
                                           uint32_t channel, uint32_t index,
                                           uint32_t byte4) {
  return ((uint32_t)AUD_UMP_TYPE_MIDI2_CHANNEL_VOICE << 28) |
         ((group & 0xF) << 24) | ((status & 0xF) << 20) |
         ((channel & 0xF) << 16) | ((index & 0xFF) << 8) | (byte4 & 0xFF);
}

// Builds a MIDI 2.0 note on or off: `words[0]` and `words[1]`.
static inline void aud_ump_midi2_note(uint32_t group, uint32_t channel,
                                      int note_on, uint32_t note,
                                      uint32_t velocity16,
                                      uint32_t attribute_type,
                                      uint32_t attribute16, uint32_t* words) {
  words[0] = aud_ump_midi2_word0(
      group, note_on ? AUD_UMP_STATUS_NOTE_ON : AUD_UMP_STATUS_NOTE_OFF,
      channel, note, attribute_type);
  words[1] = ((velocity16 & 0xFFFF) << 16) | (attribute16 & 0xFFFF);
}

// Builds a MIDI 2.0 registered per-note controller: `words[0]` and
// `words[1]`.
static inline void aud_ump_midi2_per_note_controller(uint32_t group,
                                                     uint32_t channel,
                                                     uint32_t note,
                                                     uint32_t index,
                                                     uint32_t value32,
                                                     uint32_t* words) {
  words[0] = aud_ump_midi2_word0(
      group, AUD_UMP_STATUS_REGISTERED_PER_NOTE_CONTROLLER, channel, note,
      index);
  words[1] = value32;
}

#ifdef __cplusplus
}
#endif

#endif  // AUD_UMP_H
