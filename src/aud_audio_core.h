// @license
// Copyright (c) Audanika. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

// The native entry points of aud_audio_core: the ABI version and the struct
// sizes, so that the Dart side can check that it agrees with the C side.

#ifndef AUD_AUDIO_CORE_H
#define AUD_AUDIO_CORE_H

#include <stdint.h>

#include "aud_abi.h"

#ifdef __cplusplus
extern "C" {
#endif

// The major ABI version compiled into the native core.
AUD_EXPORT int32_t aud_abi_version_major(void);

// The minor ABI version compiled into the native core.
AUD_EXPORT int32_t aud_abi_version_minor(void);

// sizeof the ABI structs as the C compiler lays them out.
AUD_EXPORT int32_t aud_abi_sizeof_event(void);
AUD_EXPORT int32_t aud_abi_sizeof_param_descriptor(void);
AUD_EXPORT int32_t aud_abi_sizeof_process_context(void);
AUD_EXPORT int32_t aud_abi_sizeof_node_vtable(void);
AUD_EXPORT int32_t aud_abi_sizeof_node_descriptor(void);
AUD_EXPORT int32_t aud_abi_sizeof_host_api(void);

#ifdef __cplusplus
}
#endif

#endif  // AUD_AUDIO_CORE_H
