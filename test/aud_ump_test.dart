// @license
// Copyright (c) Audanika. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:ffi';

import 'package:aud_audio_core/aud_audio_core.dart';
import 'package:aud_audio_core/aud_audio_core_bindings.dart' as native;
import 'package:aud_midi_standard/aud_midi_standard.dart';
import 'package:ffi/ffi.dart';
import 'package:test/test.dart';

void main() {
  final noteOn1 = AudUmp.midi1Word(
    group: 1,
    statusByte: 0x93,
    data1: 60,
    data2: 100,
  );
  final noteOnZero = AudUmp.midi1Word(
    group: 0,
    statusByte: 0x90,
    data1: 60,
    data2: 0,
  );
  final noteOff1 = AudUmp.midi1Word(
    group: 0,
    statusByte: 0x80,
    data1: 60,
    data2: 64,
  );
  final noteOn2 = AudUmp.midi2Note(
    group: 2,
    channel: 5,
    noteOn: true,
    note: 64,
    velocity16: 0x8000,
    attributeType: 1,
    attribute16: 7,
  );
  final noteOff2 = AudUmp.midi2Note(
    group: 2,
    channel: 5,
    noteOn: false,
    note: 64,
    velocity16: 0,
  );
  final silentOn2 = AudUmp.midi2Note(
    group: 2,
    channel: 5,
    noteOn: true,
    note: 64,
    velocity16: 0,
  );
  final pnc = AudUmp.midi2PerNoteController(
    group: 0,
    channel: 1,
    note: 60,
    index: MidiPerNoteControllers.pitch,
    value32: 0x80000000,
  );

  group('AudUmp', () {
    test('reads the fields of channel voice messages', () {
      expect(AudUmp.messageType(noteOn1), AudUmp.typeMidi1ChannelVoice);
      expect(AudUmp.wordCount(noteOn1), 1);
      expect(AudUmp.wordCount(noteOn2[0]), 2);
      expect(AudUmp.wordCount(0xD0000000), 4);
      expect(AudUmp.group(noteOn1), 1);
      expect(AudUmp.status(noteOn1), AudUmp.statusNoteOn);
      expect(AudUmp.channel(noteOn1), 3);
      expect(AudUmp.note(noteOn1), 60);
      expect(AudUmp.midi1Data1(noteOn1), 60);
      expect(AudUmp.midi1Data2(noteOn1), 100);
      expect(AudUmp.isChannelVoice(noteOn1), isTrue);
      expect(AudUmp.isChannelVoice(0x10000000), isFalse);
      expect(noteOn2[0] >> 28, AudUmp.typeMidi2ChannelVoice);
      expect(AudUmp.channel(noteOn2[0]), 5);
      expect(AudUmp.note(noteOn2[0]), 64);
      expect(noteOn2[0] & 0xFF, 1);
      expect(noteOn2[1], 0x80000007);
    });

    test('classifies note ons and offs including velocity zero', () {
      expect(AudUmp.isNoteOn(noteOn1, 0), isTrue);
      expect(AudUmp.isNoteOff(noteOn1, 0), isFalse);
      expect(AudUmp.isNoteOn(noteOnZero, 0), isFalse);
      expect(AudUmp.isNoteOff(noteOnZero, 0), isTrue);
      expect(AudUmp.isNoteOff(noteOff1, 0), isTrue);
      expect(AudUmp.isNoteOn(noteOn2[0], noteOn2[1]), isTrue);
      expect(AudUmp.isNoteOff(noteOff2[0], noteOff2[1]), isTrue);
      expect(AudUmp.isNoteOn(silentOn2[0], silentOn2[1]), isFalse);
      expect(AudUmp.isNoteOff(silentOn2[0], silentOn2[1]), isTrue);
      expect(AudUmp.isNoteOn(0x10000000, 0), isFalse);
      expect(AudUmp.isNoteOff(0x10000000, 0), isFalse);
      expect(AudUmp.isNoteOff(pnc[0], pnc[1]), isFalse);
      expect(AudUmp.noteVelocity(noteOn1, 0), closeTo(100 / 127, 1e-6));
      expect(
        AudUmp.noteVelocity(noteOn2[0], noteOn2[1]),
        closeTo(0x8000 / 65535, 1e-6),
      );
    });

    test('reads per-note controllers', () {
      expect(AudUmp.isPerNoteController(pnc[0]), isTrue);
      expect(AudUmp.isPerNoteController(noteOn2[0]), isFalse);
      expect(AudUmp.isPerNoteController(noteOn1), isFalse);
      expect(
        AudUmp.perNoteControllerIndex(pnc[0]),
        MidiPerNoteControllers.pitch,
      );
      expect(AudUmp.unitValue(pnc[1]), closeTo(0.5, 1e-6));
    });

    test('agrees with aud_ump.h', () {
      for (final (w0, w1) in [
        (noteOn1, 0),
        (noteOnZero, 0),
        (noteOff1, 0),
        (noteOn2[0], noteOn2[1]),
        (silentOn2[0], silentOn2[1]),
        (pnc[0], pnc[1]),
      ]) {
        expect(native.aud_core_ump_word_count(w0), AudUmp.wordCount(w0));
        expect(native.aud_core_ump_message_type(w0), AudUmp.messageType(w0));
        expect(native.aud_core_ump_group(w0), AudUmp.group(w0));
        expect(native.aud_core_ump_status(w0), AudUmp.status(w0));
        expect(native.aud_core_ump_channel(w0), AudUmp.channel(w0));
        expect(native.aud_core_ump_note(w0), AudUmp.note(w0));
        expect(
          native.aud_core_ump_is_note_on(w0, w1) != 0,
          AudUmp.isNoteOn(w0, w1),
        );
        expect(
          native.aud_core_ump_is_note_off(w0, w1) != 0,
          AudUmp.isNoteOff(w0, w1),
        );
        expect(
          native.aud_core_ump_note_velocity(w0, w1),
          closeTo(AudUmp.noteVelocity(w0, w1), 1e-6),
        );
        expect(
          native.aud_core_ump_is_per_note_controller(w0) != 0,
          AudUmp.isPerNoteController(w0),
        );
        expect(
          native.aud_core_ump_per_note_controller_index(w0),
          AudUmp.perNoteControllerIndex(w0),
        );
        expect(
          native.aud_core_ump_unit_value(w1),
          closeTo(AudUmp.unitValue(w1), 1e-6),
        );
      }
      expect(native.aud_core_ump_midi1_word(1, 0x93, 60, 100), noteOn1);
      final words = calloc<Uint32>(2);
      native.aud_core_ump_midi2_note(2, 5, 1, 64, 0x8000, 1, 7, words);
      expect([words[0], words[1]], noteOn2);
      native.aud_core_ump_midi2_per_note_controller(
        0,
        1,
        60,
        MidiPerNoteControllers.pitch,
        0x80000000,
        words,
      );
      expect([words[0], words[1]], pnc);
      calloc.free(words);
    });

    test('packetsOf(message) uses aud_midi_standard', () {
      const message = MidiNoteOn(channel: 3, note: 60, velocity: 100);
      final packets = AudUmp.packetsOf(message, group: 1);
      expect(packets.single.words, [noteOn1]);
    });
  });
}
