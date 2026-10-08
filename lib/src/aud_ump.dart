// @license
// Copyright (c) Audanika. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:aud_midi_standard/aud_midi_standard.dart';

// #############################################################################
/// Universal MIDI Packet helpers, the Dart twin of `aud_ump.h`: the packet
/// size and the fields of channel voice messages, including the MIDI 2.0
/// per-note controllers of MPE and MIDI 2.0. Messages are built with
/// `aud_midi_standard` (decision midi-001); these helpers read and build
/// the raw words the ABI carries.
abstract final class AudUmp {
  /// The message type of a utility message.
  static const int typeUtility = 0x0;

  /// The message type of a system message.
  static const int typeSystem = 0x1;

  /// The message type of a MIDI 1.0 channel voice message.
  static const int typeMidi1ChannelVoice = 0x2;

  /// The message type of a 64-bit data message.
  static const int typeData64 = 0x3;

  /// The message type of a MIDI 2.0 channel voice message.
  static const int typeMidi2ChannelVoice = 0x4;

  /// The message type of a 128-bit data message.
  static const int typeData128 = 0x5;

  /// The message type of a flex data message.
  static const int typeFlexData = 0xD;

  /// The message type of a UMP stream message.
  static const int typeStream = 0xF;

  /// The status of a registered per-note controller (MIDI 2.0).
  static const int statusRegisteredPerNoteController = 0x0;

  /// The status of an assignable per-note controller (MIDI 2.0).
  static const int statusAssignablePerNoteController = 0x1;

  /// The status of a registered controller (MIDI 2.0).
  static const int statusRegisteredController = 0x2;

  /// The status of an assignable controller (MIDI 2.0).
  static const int statusAssignableController = 0x3;

  /// The status of a per-note pitch bend (MIDI 2.0).
  static const int statusPerNotePitchBend = 0x6;

  /// The status of a note off.
  static const int statusNoteOff = 0x8;

  /// The status of a note on.
  static const int statusNoteOn = 0x9;

  /// The status of a poly pressure.
  static const int statusPolyPressure = 0xA;

  /// The status of a control change.
  static const int statusControlChange = 0xB;

  /// The status of a program change.
  static const int statusProgramChange = 0xC;

  /// The status of a channel pressure.
  static const int statusChannelPressure = 0xD;

  /// The status of a pitch bend.
  static const int statusPitchBend = 0xE;

  /// The status of a per-note management message (MIDI 2.0).
  static const int statusPerNoteManagement = 0xF;

  static const List<int> _wordCounts = [
    1, 1, 1, 2, 2, 4, 1, 1, 2, 2, 2, 3, 3, 4, 4, 4, //
  ];

  // ...........................................................................
  /// The message type of a packet, its top four bits.
  static int messageType(int word0) => (word0 >> 28) & 0xF;

  /// The number of words of a packet, 1 to 4, by its message type.
  static int wordCount(int word0) => _wordCounts[messageType(word0)];

  /// The group of a packet, 0 to 15.
  static int group(int word0) => (word0 >> 24) & 0xF;

  /// The status nibble of a channel voice message.
  static int status(int word0) => (word0 >> 20) & 0xF;

  /// The channel of a channel voice message, 0 to 15.
  static int channel(int word0) => (word0 >> 16) & 0xF;

  /// Whether a packet is a MIDI 1.0 or MIDI 2.0 channel voice message.
  static bool isChannelVoice(int word0) {
    final type = messageType(word0);
    return type == typeMidi1ChannelVoice || type == typeMidi2ChannelVoice;
  }

  /// The note number of a note, poly pressure or per-note message.
  static int note(int word0) => (word0 >> 8) & 0x7F;

  /// The first data byte of a MIDI 1.0 channel voice message.
  static int midi1Data1(int word0) => (word0 >> 8) & 0x7F;

  /// The second data byte of a MIDI 1.0 channel voice message.
  static int midi1Data2(int word0) => word0 & 0x7F;

  // ...........................................................................
  /// Whether a packet is a note on with a velocity above zero.
  static bool isNoteOn(int word0, int word1) {
    if (!isChannelVoice(word0) || status(word0) != statusNoteOn) return false;
    if (messageType(word0) == typeMidi1ChannelVoice) {
      return midi1Data2(word0) != 0;
    }
    return (word1 >> 16) & 0xFFFF != 0;
  }

  /// Whether a packet is a note off, including a MIDI 1.0 note on with
  /// velocity zero.
  static bool isNoteOff(int word0, int word1) {
    if (!isChannelVoice(word0)) return false;
    final s = status(word0);
    if (s == statusNoteOff) return true;
    if (s != statusNoteOn) return false;
    if (messageType(word0) == typeMidi1ChannelVoice) {
      return midi1Data2(word0) == 0;
    }
    return (word1 >> 16) & 0xFFFF == 0;
  }

  /// The velocity of a note message as a unit value, 0 to 1.
  static double noteVelocity(int word0, int word1) {
    if (messageType(word0) == typeMidi1ChannelVoice) {
      return midi1Data2(word0) / 127.0;
    }
    return ((word1 >> 16) & 0xFFFF) / 65535.0;
  }

  /// Whether a packet is a registered or assignable per-note controller.
  static bool isPerNoteController(int word0) {
    if (messageType(word0) != typeMidi2ChannelVoice) return false;
    final s = status(word0);
    return s == statusRegisteredPerNoteController ||
        s == statusAssignablePerNoteController;
  }

  /// The controller index of a per-note controller message, 0 to 255.
  static int perNoteControllerIndex(int word0) => word0 & 0xFF;

  /// A 32-bit controller or pitch bend value as a unit value, 0 to 1.
  static double unitValue(int word1) => (word1 & 0xFFFFFFFF) / 4294967295.0;

  // ...........................................................................
  /// The word of a MIDI 1.0 channel voice message, e.g.
  /// `midi1Word(group: 0, statusByte: 0x90, data1: 60, data2: 100)`.
  static int midi1Word({
    required int group,
    required int statusByte,
    required int data1,
    required int data2,
  }) =>
      (typeMidi1ChannelVoice << 28) |
      ((group & 0xF) << 24) |
      ((statusByte & 0xFF) << 16) |
      ((data1 & 0x7F) << 8) |
      (data2 & 0x7F);

  /// The first word of a MIDI 2.0 channel voice message.
  static int midi2Word0({
    required int group,
    required int status,
    required int channel,
    required int index,
    int byte4 = 0,
  }) =>
      (typeMidi2ChannelVoice << 28) |
      ((group & 0xF) << 24) |
      ((status & 0xF) << 20) |
      ((channel & 0xF) << 16) |
      ((index & 0xFF) << 8) |
      (byte4 & 0xFF);

  /// The two words of a MIDI 2.0 note on or off.
  static List<int> midi2Note({
    required int group,
    required int channel,
    required bool noteOn,
    required int note,
    required int velocity16,
    int attributeType = 0,
    int attribute16 = 0,
  }) => [
    midi2Word0(
      group: group,
      status: noteOn ? statusNoteOn : statusNoteOff,
      channel: channel,
      index: note,
      byte4: attributeType,
    ),
    ((velocity16 & 0xFFFF) << 16) | (attribute16 & 0xFFFF),
  ];

  /// The two words of a MIDI 2.0 registered per-note controller.
  static List<int> midi2PerNoteController({
    required int group,
    required int channel,
    required int note,
    required int index,
    required int value32,
  }) => [
    midi2Word0(
      group: group,
      status: statusRegisteredPerNoteController,
      channel: channel,
      index: note,
      byte4: index,
    ),
    value32 & 0xFFFFFFFF,
  ];

  // ...........................................................................
  /// The packets of a message of `aud_midi_standard` on [group].
  static List<Ump> packetsOf(MidiMessage message, {int group = 0}) =>
      message.toUmp(group: group);
}
