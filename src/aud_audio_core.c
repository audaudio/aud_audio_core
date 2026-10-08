// @license
// Copyright (c) Audanika. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

#include "aud_audio_core.h"

AUD_EXPORT int32_t aud_abi_version_major(void) { return AUD_ABI_VERSION_MAJOR; }

AUD_EXPORT int32_t aud_abi_version_minor(void) { return AUD_ABI_VERSION_MINOR; }

AUD_EXPORT int32_t aud_abi_sizeof_event(void) { return (int32_t)sizeof(AudEvent); }

AUD_EXPORT int32_t aud_abi_sizeof_param_descriptor(void) {
  return (int32_t)sizeof(AudParamDescriptor);
}

AUD_EXPORT int32_t aud_abi_sizeof_process_context(void) {
  return (int32_t)sizeof(AudProcessContext);
}

AUD_EXPORT int32_t aud_abi_sizeof_node_vtable(void) {
  return (int32_t)sizeof(AudNodeVTable);
}

AUD_EXPORT int32_t aud_abi_sizeof_node_descriptor(void) {
  return (int32_t)sizeof(AudNodeDescriptor);
}

AUD_EXPORT int32_t aud_abi_sizeof_host_api(void) {
  return (int32_t)sizeof(AudHostApi);
}
