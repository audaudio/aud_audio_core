<!--
@license
Copyright (c) Audanika. All Rights Reserved.

Use of this source code is governed by terms that can be
found in the LICENSE file in the root of this package.
-->

# Notices Guide

How a package of the Audanika Audio Engine records the third-party code it
ships (decision license-001) and how the check verifies it.

## Keep third-party code in one place

- Put every copied or vendored C and C++ component under
  `src/third_party/<component>` together with its license file
- Keep the original headers of the copied files
- Copy only from permissive sources: MIT, MIT-0, BSD-2-Clause,
  BSD-3-Clause, Apache-2.0, ISC, Zlib, Unlicense, CC0, BSL-1.0, WTFPL, the
  STK license, the FFTPACK license or public domain; never LGPL or GPL

## Write src/third_party/NOTICES.md

- Open with `# Third-party notices of <package>` and a paragraph on the
  origin: repository, commit or version, date and ticket of the vendoring
- Add one table with the columns `Component`, `Path` and `License`;
  further columns such as `Version` may sit between them
- Name the component directory in the `Path` column in backticks
- Name the SPDX id in the `License` column, then the license file in
  backticks, e.g. `` MIT, `lib/LICENSE` ``; write `header of the file` when a
  single-file library carries its license in its header
- Record for a dual-licensed dependency which license was chosen
- Register the notices with `LicenseRegistry.addLicense` in Flutter apps

## Open every own source file with the license header

- Every `.c`, `.cc`, `.cpp`, `.h`, `.hpp`, `.mm`, `.dart`, `.js` and `.ts`
  file under `src`, `lib`, `hook`, `scripts`, `test` and `bin` starts with
  the `@license` header; generated files carry it through their preamble

## Run the check

```bash
node scripts/check-notices.js
```

The script fails with the list of problems: a component without a row, a
license outside the list, a component without a license file, a source file
without the header. Every repo runs it before a commit; the CI matrix of S22
runs it on every push.
