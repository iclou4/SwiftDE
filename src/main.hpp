#pragma once

#include <wayfire/util/log.hpp>

extern struct wf_runtime_config
{
    bool no_damage_track = false;
    bool legacy_wl_drm   = false;
    bool damage_debug    = false;
} runtime_config;

namespace wf
{
wf::log::color_mode_t detect_color_mode();
}
