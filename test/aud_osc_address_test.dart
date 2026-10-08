// @license
// Copyright (c) Audanika. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:aud_audio_core/aud_audio_core.dart';
import 'package:test/test.dart';

void main() {
  group('AudOscAddress', () {
    test('builds the addresses of the scheme', () {
      expect(AudOscAddress.graph(1).value, '/graph/1');
      expect(AudOscAddress.transport(1).value, '/graph/1/transport');
      expect(
        AudOscAddress.node(graphId: 1, nodeId: 2).value,
        '/graph/1/node/2',
      );
      expect(
        AudOscAddress.param(graphId: 1, nodeId: 2, param: 'gain').value,
        '/graph/1/node/2/param/gain',
      );
      expect(
        AudOscAddress.inlet(graphId: 1, nodeId: 2, inlet: 'midi').value,
        '/graph/1/node/2/inlet/midi',
      );
      expect(
        AudOscAddress.outlet(graphId: 1, nodeId: 2, outlet: 'o').value,
        '/graph/1/node/2/outlet/o',
      );
      expect(
        AudOscAddress.string(graphId: 1, nodeId: 2, key: 'file').value,
        '/graph/1/node/2/string/file',
      );
    });

    test('validates the grammar', () {
      for (final bad in [
        '',
        '/',
        'graph',
        '/a//b',
        '/a/',
        '/a b',
        '/a*',
        '/a?',
        '/a[b]',
        '/a{b}',
        '/a,b',
        '/a#b',
      ]) {
        expect(AudOscAddress.isValid(bad), isFalse, reason: bad);
        expect(() => AudOscAddress(bad), throwsFormatException, reason: bad);
      }
      expect(AudOscAddress.isValid('/a/b-c.d_e'), isTrue);
    });

    test('segments, parent, child and isWithin', () {
      final address = AudOscAddress('/graph/1/node/2');
      expect(address.segments, ['graph', '1', 'node', '2']);
      expect(address.last, '2');
      expect(address.parent, AudOscAddress('/graph/1/node'));
      expect(AudOscAddress('/a').parent, isNull);
      expect(address.child('param'), AudOscAddress('/graph/1/node/2/param'));
      expect(address.isWithin(AudOscAddress('/graph/1')), isTrue);
      expect(address.isWithin(address), isTrue);
      expect(address.isWithin(AudOscAddress('/graph/10')), isFalse);
      expect(address.hashCode, AudOscAddress('/graph/1/node/2').hashCode);
      expect(address.toString(), '/graph/1/node/2');
    });
  });

  group('AudOscPattern', () {
    test('isPattern(address) detects pattern characters', () {
      expect(AudOscPattern.isPattern('/a/b'), isFalse);
      for (final p in ['/a/*', '/a?', '/a[b]', '/a{b,c}', '/a//b']) {
        expect(AudOscPattern.isPattern(p), isTrue, reason: p);
      }
    });

    test('matches the OSC 1.0 and 1.1 wildcards', () {
      final cases = <String, Map<String, bool>>{
        '/graph/*/node/*/param/gain': {
          '/graph/1/node/2/param/gain': true,
          '/graph/1/node/2/param/rate': false,
          '/graph/1/node/param/gain': false,
        },
        '/graph/1/node/?': {'/graph/1/node/2': true, '/graph/1/node/22': false},
        '/graph/1/node/[12]': {
          '/graph/1/node/1': true,
          '/graph/1/node/3': false,
        },
        '/graph/1/node/[!12]': {
          '/graph/1/node/3': true,
          '/graph/1/node/1': false,
        },
        '/graph/1/node/[a-c]x': {
          '/graph/1/node/bx': true,
          '/graph/1/node/dx': false,
        },
        '/graph/1/node/{2,3}': {
          '/graph/1/node/2': true,
          '/graph/1/node/4': false,
        },
        '/graph//gain': {
          '/graph/gain': true,
          '/graph/1/node/2/param/gain': true,
          '/graph/1/node/2/param/rate': false,
        },
        '//gain': {'/gain': true, '/a/b/gain': true, '/gain/x': false},
        '/a/b.c': {'/a/b.c': true, '/a/bxc': false},
      };
      for (final entry in cases.entries) {
        final pattern = AudOscPattern(entry.key);
        for (final test in entry.value.entries) {
          expect(
            pattern.matches(test.key),
            test.value,
            reason: '${entry.key} on ${test.key}',
          );
          expect(pattern.matches(AudOscAddress(test.key)), test.value);
        }
      }
      expect(AudOscPattern('/a').hashCode, AudOscPattern('/a').hashCode);
      expect(AudOscPattern('/a').toString(), '/a');
      expect(AudOscPattern('/a'), AudOscPattern('/a'));
    });

    test('rejects malformed patterns', () {
      for (final bad in ['', 'a', '/', '/a/', '/a///b', '/a[b', '/a{b']) {
        expect(() => AudOscPattern(bad), throwsFormatException, reason: bad);
      }
      expect(() => AudOscPattern('/a').matches(1), throwsArgumentError);
    });
  });
}
