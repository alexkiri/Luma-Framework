#pragma once

// "_DEBUG" might already be defined in debug?
// Setting it to 0 causes the compiler to still assume it as defined and that thus we are in debug mode (don't change this manually).
#ifndef NDEBUG
#define _DEBUG 1
#endif // !NDEBUG

// Enable when you are developing shaders or code (not debugging, there's "NDEBUG" for that).
// This brings out the "devkit", allowing you to trace draw calls and a lot more stuff.
#ifndef DEVELOPMENT
#define DEVELOPMENT 0
#endif // DEVELOPMENT
// Enable when you are testing shaders or code (e.g. to dump the shaders, logging warnings, etc etc).
// This is not mutually exclusive with "DEVELOPMENT", but it should be a sub-set of it.
// If neither of these are true, then we are in "shipping" mode, with code meant to be used by the final user.
#ifndef TEST
#define TEST 0
#endif // TEST

#define LOG_VERBOSE ((DEVELOPMENT || TEST) && 0)

// Disables loading the ReShade Addon code (useful to test the mod without any ReShade dependencies (e.g. optionally "Prey"))
#define DISABLE_RESHADE 0

#pragma comment(lib, "dxguid.lib")

#define _USE_MATH_DEFINES

#ifdef _WIN32
#define ImTextureID ImU64
#endif

#include <d3d11.h>
#include <dxgi.h>
#include <dxgi1_6.h>
#include <Windows.h>

#include <cstdio>
#include <filesystem>
#include <fstream>
#include <shared_mutex>
#include <string>
#include <unordered_map>
#include <unordered_set>
#include <set>
#include <vector>
#include <semaphore>
#include <utility>
#include <cstdint>
#include <functional>
#include <regex>

// DirectX dependencies
#include <DirectXMath.h>
#include <DirectXPackedVector.h>

// ReShade dependencies
#include <deps/imgui/imgui.h>
#include <include/reshade.hpp>
#include <source/com_ptr.hpp>
#include <examples/utils/crc32_hash.hpp>
#if 0 // Not needed atm
#include <source/d3d11/d3d11_impl_type_convert.hpp>
#endif

#ifndef FORCE_KEEP_CUSTOM_SHADERS_LOADED
#define FORCE_KEEP_CUSTOM_SHADERS_LOADED 1
#endif // FORCE_KEEP_CUSTOM_SHADERS_LOADED
#ifndef ALLOW_LOADING_DEV_SHADERS
#define ALLOW_LOADING_DEV_SHADERS 1
#endif // ALLOW_LOADING_DEV_SHADERS
#ifndef UPGRADE_SAMPLERS
#define UPGRADE_SAMPLERS 0
#endif // UPGRADE_SAMPLERS
#ifndef GEOMETRY_SHADER_SUPPORT
#define GEOMETRY_SHADER_SUPPORT 0
#endif // GEOMETRY_SHADER_SUPPORT
// Not used by mod engines (e.g. Prey)
#ifndef ENABLE_SHADER_CLASS_INSTANCES
#define ENABLE_SHADER_CLASS_INSTANCES 0
#endif // ENABLE_SHADER_CLASS_INSTANCES
// 64x only
#ifndef ENABLE_NGX
#define ENABLE_NGX 0
#endif // ENABLE_NGX
#ifndef ENABLE_FSR
#define ENABLE_FSR 0
#endif // ENABLE_FSR
#ifndef ENABLE_NVAPI
#define ENABLE_NVAPI 0
#endif // ENABLE_NVAPI
#ifndef PROJECT_NAME
// Matches "Globals::MOD_NAME"
#define PROJECT_NAME "Luma"
#endif // PROJECT_NAME
#ifndef ENABLE_GAME_PIPELINE_STATE_READBACK
#define ENABLE_GAME_PIPELINE_STATE_READBACK 0
#endif // ENABLE_GAME_PIPELINE_STATE_READBACK
#ifndef TEST_DUPLICATE_SHADER_HASH
#define TEST_DUPLICATE_SHADER_HASH 0
#endif // TEST_DUPLICATE_SHADER_HASH

#if DX12
constexpr bool OneShaderPerPipeline = false;
#else
#define DX11 1
constexpr bool OneShaderPerPipeline = true;
#endif

// This might not disable all shaders dumping related code, but it disables enough to remove any performance cost
#ifndef ALLOW_SHADERS_DUMPING
#define ALLOW_SHADERS_DUMPING (DEVELOPMENT || TEST)
#endif

// Depends on "DEVELOPMENT"
#define TEST_DLSS (DEVELOPMENT && 0)

#include "dlss/DLSS.h" // see "ENABLE_NGX"

#include "includes/globals.h"
#include "includes/debug.h"
#include "includes/cbuffers.h"
#include "includes/math.h"
#include "includes/matrix.h"
#include "includes/shader_types.h"
#include "includes/recursive_shared_mutex.h"
#include "includes/shaders.h"
#include "includes/shader_define.h"
#include "includes/instance_data.h"
#include "includes/game.h"

#include "utils/format.hpp"
#include "utils/pipeline.hpp"
#include "utils/shader_compiler.hpp"
#include "utils/display.hpp"
#include "utils/resource.hpp"
#include "utils/draw.hpp"
#include "utils/system.hpp"

#define ICON_FK_CANCEL reinterpret_cast<const char*>(u8"\uf00d")
#define ICON_FK_OK reinterpret_cast<const char*>(u8"\uf00c")
#define ICON_FK_PLUS reinterpret_cast<const char*>(u8"\uf067")
#define ICON_FK_MINUS reinterpret_cast<const char*>(u8"\uf068")
#define ICON_FK_REFRESH reinterpret_cast<const char*>(u8"\uf021")
#define ICON_FK_UNDO reinterpret_cast<const char*>(u8"\uf0e2")
#define ICON_FK_SEARCH reinterpret_cast<const char*>(u8"\uf002")
#define ICON_FK_WARNING reinterpret_cast<const char*>(u8"\uf071")
#define ICON_FK_FILE_CODE reinterpret_cast<const char*>(u8"\uf1c9")

#ifndef RESHADE_EXTERNS
// These are needed by ReShade
extern "C" __declspec(dllexport) const char* NAME = &Globals::MOD_NAME[0];
extern "C" __declspec(dllexport) const char* DESCRIPTION = &Globals::DESCRIPTION[0];
extern "C" __declspec(dllexport) const char* WEBSITE = &Globals::WEBSITE[0];
#endif

// Make sure we can use com_ptr as c arrays of pointers
static_assert(sizeof(com_ptr<ID3D11Resource>) == sizeof(void*));

using namespace Shader;
using namespace Math;

namespace
{
   constexpr uint32_t HASH_CHARACTERS_LENGTH = 8;
   const std::string NAME_ADVANCED_SETTINGS = std::string(NAME) + " Advanced";

   // A default "template" (empty) game data that we can fall back to in case we didn't specify any
   Game default_game = {};
   // The pointer to the current game implementation (data and code), it can be replaced
   Game* game = &default_game;

   // Mutexes:
   // For "pipeline_cache_by_pipeline_handle", "pipeline_cache_by_pipeline_clone_handle", "pipeline_caches_by_shader_hash", "pipelines_to_destroy", "cloned_pipeline_count"
   recursive_shared_mutex s_mutex_generic;
   // For "shaders_to_dump", "dumped_shaders", "shader_cache". In general for dumping shaders to disk (this almost always needs to be read and write locked together so there's no need for it to be a shared mutex)
   std::recursive_mutex s_mutex_dumping;
   // For "custom_shaders_cache", "pipelines_to_reload". In general for loading shaders from disk and compiling them
   recursive_shared_mutex s_mutex_loading;
   // Mutex for created shader DX objects (and "created_custom_shaders")
   std::shared_mutex s_mutex_shader_objects;
   // Mutex for shader defines ("shader_defines_data", "code_shaders_defines", "shader_defines_data_index")
   std::shared_mutex s_mutex_shader_defines;
   // Mutex to deal with data shader with ReShade, like ini/config saving and loading (including "cb_luma_global_settings" and "cb_luma_global_settings_dirty")
   std::shared_mutex s_mutex_reshade;
   // For "custom_sampler_by_original_sampler" and "texture_mip_lod_bias_offset"
   std::shared_mutex s_mutex_samplers;
   // For "global_native_devices", "global_devices_data", "game_window"
   recursive_shared_mutex s_mutex_device;
#if DEVELOPMENT
   // for "trace_count" and "trace_scheduled" and "trace_running"
   std::shared_mutex s_mutex_trace;
#endif

   // Dev or User settings:
   bool auto_dump = (bool)ALLOW_SHADERS_DUMPING;
   bool auto_load = true;
#if DEVELOPMENT
   bool trace_ignore_vertex_shaders = true;
   bool trace_ignore_buffer_writes = true;
   bool trace_ignore_bindings = true;
   bool trace_ignore_non_bound_shader_referenced_resources = true;
#endif // DEVELOPMENT
   constexpr bool precompile_custom_shaders = true; // Async shader compilation on boot
   constexpr bool block_draw_until_device_custom_shaders_creation = true; // Needs "precompile_custom_shaders". Note that drawing (and "Present()") could be blocked anyway due to other mutexes on boot if custom shaders are still compiling
   bool dlss_sr = true; // If true DLSS is enabled by the user (but not necessarily supported+initialized correctly, that's by device)
   const char* dlss_game_tooltip = "";
   bool hdr_enabled_display = false;
   bool hdr_supported_display = false;
   constexpr bool prevent_shader_cache_loading = false;
   bool prevent_shader_cache_saving = false;
#if DEVELOPMENT
   //TODOFT3: clean up the following vars
   int samplers_upgrade_mode = UPGRADE_SAMPLERS ? 5 : 0;
   int samplers_upgrade_mode_2 = 0;
   bool custom_texture_mip_lod_bias_offset = false; // Live edit
   int frame_sleep_ms = 0;
   int frame_sleep_interval = 1;
#endif // DEVELOPMENT
#if DEVELOPMENT || TEST
   int test_index = 0; //TODOFT5: remove most of the calls to this once Prey performance is fixed
#else
   constexpr int test_index = 0;
#endif // DEVELOPMENT || TEST

   // Upgrades
   namespace
   {
      bool enable_swapchain_upgrade = false;
      // 0 None (keep the original one, SDR or whatnot)
      // 1 scRGB HDR
      uint32_t swapchain_upgrade_type = 0;

      // For now, by default, we prevent fullscreen on boot and later, given that it's pointless.
      // If there were issues, we could exclusively do it when the swapchain resolution matched the monitor resolution.
      bool prevent_fullscreen_state = true;

      bool enable_texture_format_upgrades = false;
	   // List of render targets (and unordered access) textures that we upgrade to R16G16B16A16_FLOAT.
      // Most formats are supported but some might not act well when upgraded.
      std::unordered_set<reshade::api::format> texture_upgrade_formats;
      // Redirect incompatible copies between UNORM and FLOAT textures to a custom pixel shader that would do the same (not globally compatible).
      // This can happen if the game uses a temp texture that isn't either a render target nor is unordered access, so we don't upgrade it.
      bool enable_upgraded_texture_resource_copy_redirection = true;
      // TODO: add by swapchain width (Thumper), and swapchain height. Add a warning for textures we missed upgrading if the swapchain resolution changed later.
      enum class TextureFormatUpgrades2DSizeFilters : uint32_t
      {
         // If the flags are set to 0, we upgrade all textures independently of their size.
         All = 0,
         // The output resolution (usually matches the window resolution too).
         SwapchainResolution = 1 << 0,
         // The rendering resolution (e.g. for TAA and other types of upscaling).
         RenderResolution = 1 << 1,
         // The aspect ratio of the swapchain texture.
         // This can be useful for bloom or resolution scaling etc.
         // Ideally we'd also check the rendering resolution, but we can't really reliably determine it until rendering has started and textures have been created.
         SwapchainAspectRatio = 1 << 2,
         // A custom aspect ratio (defaulted to 16:9, because that's the global standard).
         // It can be useful for games that don't support UltraWide or 4:3 resolutions and internally force 16:9 rendering, while having a fullscreen swapchain with black bars.
         CustomAspectRatio = 1 << 3,
         // All mip chain sizes based starting from the highest resolution between rendering and swapchain resolution (they should generally have the same aspect ratio anyway) to 1.
         // This can be useful for blur passes etc.
         Mips = 1 << 4,
      };
      uint32_t texture_format_upgrades_2d_size_filters = 0 | (uint32_t)TextureFormatUpgrades2DSizeFilters::SwapchainResolution | (uint32_t)TextureFormatUpgrades2DSizeFilters::SwapchainAspectRatio;
      float texture_format_upgrades_2d_custom_aspect_ratio = 16.f / 9.f;
      // Most games do resolution scaling properly, with a maximum aspect ratio offset of 1 pixel, though occasionally it goes to 2 pixels of difference.
      // Set to 0 to only accept 100% matching aspect ratio.
      uint32_t texture_format_upgrades_2d_aspect_ratio_pixel_threshold = 1;
      // The size of the LUT we might want to upgrade, whether it's 1D, 2D or 3D.
      // LUTs in most games are 16x or 32x, though in some cases they might be 15x, 31x, 48x, 64x etc.
      uint32_t texture_format_upgrades_lut_size = -1;
      enum class LUTDimensions
      {
         _1D,
         _2D,
         _3D
      };
      LUTDimensions texture_format_upgrades_lut_dimensions = LUTDimensions::_2D;

      // If enabled, all the UI will be drawn onto a separate (e.g.) UNORM texture and composed back with the game scene later on.
      // This has multiple advantages:
      // - It allows the UI scene background to be tonemapped, increasing the UI readibility (this can be important in some games).
      // - The scene rendering can be kept in linear scRGB even after encoding, as it doesn't need to blend with UI in gamma space.
      // - The scene rendering doesn't needs to be scaled by the inverse of the UI brightness to allow UI brightness scaling.
      // - The UI avoids generating NaNs on the float upgraded float backbuffer.
      // - It avoids the UI subtracting colors as it did in SDR with UNORM textures (that were limited to 0), which cause large negative values with upgraded float textures.
      // - It can do AutoHDR on the game scene only given that the UI is in a different layer.
      // Note that drawing pre-multiplied UI on a separate texture can cause a slightly additional loss of quality, but the render target format can be upgraded to make it even better looking than vanilla.
      bool enable_ui_separation = false;
      // Leave unknown to automatically retrieve it from the swapchain, though that's not necessarily the right value,
      // especially if the UI used R8G8B8A8 instead of R10G10B10A2/R16G16B16A16F as the swapchain could have been, or in case it flipped sRGB views on or off compared to the swapchain.
      // It's important to pick a format that has the same "encoding" as the original game, to preserve the look of alpha blends, so keep linear space for linear space and gamma space for gamma space.
      // 
      // For high quality SDR use "DXGI_FORMAT_R16G16B16A16_UNORM", 16 bits might reduce banding. This is best for gamma space UI but can also work in linear.
      // For high quality HDR use "DXGI_FORMAT_R16G16B16A16_FLOAT", though this can trigger NaNs or negative luminances (that you might want to preserve). This is best for linear space UI but can also work in gamma.
      // For linear space SDR use "DXGI_FORMAT_R8G8B8A8_UNORM_SRGB", especially if there's no need to upgrade the bit depth, gamut and dynamic range of the UI.
      // For gamma space SDR use "DXGI_FORMAT_R8G8B8A8_UNORM", especially if there's no need to upgrade the bit depth, gamut and dynamic range of the UI.
      // For high quality gamma space SDR use "DXGI_FORMAT_R10G10B10A2_UNORM" can alternatively be used to improve the quality if you are sure the game doesn't read back alpha (you can try with "DXGI_FORMAT_R11G11B10_FLOAT" as a test, and see if any of the UI looks different, given it has no alpha).
      DXGI_FORMAT ui_separation_format = DXGI_FORMAT_UNKNOWN;
   }

   // In case this is a generic mod for multiple games, set this to the actual game name (e.g. "GAME_ROCKET_LEAGUE")
   const char* sub_game_shader_define = nullptr;
   // Optionally define an appended name for our current game, it might apply to shader names and dump folders etc
   std::string sub_game_shaders_appendix;

#if DEVELOPMENT
   // Allows games to hardcode in some shader names by hash, to easily identify them across reboots (we could just store this in the user ini, but that info wouldn't be persistent)
   std::unordered_map<uint32_t, std::string> forced_shader_names;

   // Replace the shaders load and dump directory
   std::filesystem::path custom_shaders_path;
#endif

   // Game specific constants (these are not expected to be changed at runtime)
   uint32_t luma_settings_cbuffer_index = 13;
   uint32_t luma_data_cbuffer_index = -1; // Needed, unless "POST_PROCESS_SPACE_TYPE" is 0 and we don't need the final display composition pass
	uint32_t luma_ui_cbuffer_index = -1; // Optional, for "UI_DRAW_TYPE" 1

   // Make sure these names are unique across the project by shader type, as they are used as hash
   const std::string shader_name_copy_vertex = "Luma_Copy";
   const std::string shader_name_copy_pixel = "Luma_Copy";
   const std::string shader_name_transform_function_copy_pixel = "Luma_DisplayComposition";
   const std::string shader_name_draw_purple_pixel = "Luma_DrawPurple";
   const std::string shader_name_draw_purple_compute = "Luma_DrawPurple";
   const std::string shader_name_normalize_lut_3d_compute = "Luma_NormalizeLUT3D";

   // Optionally add the UI shaders to this list, to make sure they draw to a separate render target for proper HDR composition
   ShaderHashesList shader_hashes_UI;
   // Shaders that might be running after "has_drawn_main_post_processing" has turned true, but that are still not UI (most games don't have a fixed last shader that runs on the scene rendering before UI, e.g. FXAA might add a pass based on user settings etc), so we have to exclude them like this
   ShaderHashesList shader_hashes_UI_excluded;

   // All the shaders the game ever loaded (including the ones that have been unloaded). Only used by shader dumping (if "ALLOW_SHADERS_DUMPING" is on) or to see their binary code in the ImGUI view. By originaly shader hash.
   // The data it contains is fully its own, so it's not by "Device". These are "immutable" once set.
   std::unordered_map<uint32_t, CachedShader*> shader_cache;
   // All the shaders the user has (and has had) as custom in the shader folders (whether they are game specific or Luma global shaders). By shader hash.
   // The data it contains is fully its own, so it's not by "Device".
   // The hash here is 64 bit instead of 32 to leave extra room for Luma native shaders, that have customly generated hashes (to not mix with the game ones).
   std::unordered_map<uint64_t, CachedCustomShader*> custom_shaders_cache;

   // Newly loaded shaders that still need to be (auto) dumped, by shader hash
   std::unordered_set<uint32_t> shaders_to_dump;
   // All the shaders we have already dumped, by shader hash
   std::unordered_set<uint32_t> dumped_shaders;

   std::string shaders_compilation_errors; // errors and warning log

   // List of define values read by our settings shaders
   std::unordered_map<std::string, uint8_t> code_shaders_defines;

   // These default should ideally match shaders values (Settings.hlsl), but it's not necessary because whatever the default values they have they will be overridden.
	// For further descriptions, see their shader declarations.
   // TODO: add grey out conditions (another define, by name, whether its value is > 0), and also add min/max values range (to limit the user insertable values), and "category"
   // TODO: add a user facing name (not just the tooltip)?
   std::vector<ShaderDefineData> shader_defines_data = {
       {"DEVELOPMENT", DEVELOPMENT ? '1' : '0', true, DEVELOPMENT ? false : true, "Enables some development/debug features that are otherwise not allowed (get a TEST or DEVELOPMENT build if you want to use this)"},
       // Usually if we store in gamma space, we also keep the paper white not multiplied in until we apply it on the final output, while if we store in linear space, we pre-multiply it in (and we might also pre-correct gamma before the final output).
       // NOTE: "POST_PROCESS_SPACE_TYPE" 2 is actually implemented as well but only used by Prey.
       {"POST_PROCESS_SPACE_TYPE", '0', true, DEVELOPMENT ? false : true, "Describes in what \"space\" (encoding) the game post processing color buffers are stored\n0 - SDR Gamma space\n1 - Linear space"},
       {"EARLY_DISPLAY_ENCODING", '0', true, DEVELOPMENT ? false : true, "Whether the main gamma correction and paper white scaling happens early in post processing or in the final display composition pass (only applies if \"POST_PROCESS_SPACE_TYPE\" is set to linear)"},
       // Sadly most games encoded with sRGB (or used linear sRGB buffers, similar thing), so that's the default here
       {"VANILLA_ENCODING_TYPE", '0', true, DEVELOPMENT ? false : true, "0 - sRGB\n1 - Gamma 2.2"},
       {"GAMMA_CORRECTION_TYPE", '1', true, false, "(HDR only) Emulates a specific SDR transfer function\nThis is best left to \"1\" (Gamma 2.2) unless you have crushed blacks or overly saturated colors\n0 - sRGB\n1 - Gamma 2.2\n2 - sRGB (color hues) with gamma 2.2 luminance (corrected by channel)\n3 - sRGB (color hues) with gamma 2.2 luminance (corrected by luminance)\n4 - Gamma 2.2 (corrected by luminance) with per channel correction chrominance"},
       {"GAMUT_MAPPING_TYPE", '0', true, DEVELOPMENT ? false : true, "The type of gamut mapping that is needed by the game.\nIf rendering and post processing don't generate any colors beyond the target gamut, there's no need to do gamut mapping.\n0 - None\n1 - Auto (SDR/HDR)\n2 - SDR (BT.709)\n3 - HDR (BT.2020)"},
       {"UI_DRAW_TYPE", '0', true, DEVELOPMENT ? false : true, "Describes how the UI draws in\n0 - Raw (original linear to linear or gamma to gamma draws) (no custom UI paper white control)\n1 - Direct Custom (gamma to linear adapted blends)\n2 - Direct (inverse scene brightness draws)\n3 - Separate (renders the UI on a separate texture, allows tonemapping of UI background)"},
#if DEVELOPMENT
       {"TEST_2X_ZOOM", '0', true, false, "Allows you to zoom in into the film image center to better analyze it"},
#endif
       {"TEST_SDR_HDR_SPLIT_VIEW_MODE", '0', true, false, "Allows you to clamp to SDR on a portion of the screen, to run quick comparisons between SDR and HDR\n(note that the tonemapper might still run in HDR mode and thus clip further than it would have had in SDR)"},
   };

   // TODO: if at runtime we can't edit "shader_defines_data" (e.g. in non dev modes), then we could directly set these to the index value of their respective "shader_defines_data" and skip the map?
   constexpr uint32_t DEVELOPMENT_HASH = char_ptr_crc32("DEVELOPMENT");
   constexpr uint32_t POST_PROCESS_SPACE_TYPE_HASH = char_ptr_crc32("POST_PROCESS_SPACE_TYPE");
   constexpr uint32_t EARLY_DISPLAY_ENCODING_HASH = char_ptr_crc32("EARLY_DISPLAY_ENCODING");
   constexpr uint32_t VANILLA_ENCODING_TYPE_HASH = char_ptr_crc32("VANILLA_ENCODING_TYPE");
   constexpr uint32_t GAMMA_CORRECTION_TYPE_HASH = char_ptr_crc32("GAMMA_CORRECTION_TYPE");
   constexpr uint32_t GAMUT_MAPPING_TYPE_HASH = char_ptr_crc32("GAMUT_MAPPING_TYPE");
   constexpr uint32_t UI_DRAW_TYPE_HASH = char_ptr_crc32("UI_DRAW_TYPE");

   // uint8_t is enough for MAX_SHADER_DEFINES
   std::unordered_map<uint32_t, uint8_t> shader_defines_data_index;

   // Global data (not device dependent really):

   // Directly from cbuffer
   CB::LumaGlobalSettingsPadded cb_luma_global_settings = { }; // Not in device data as this stores some users settings too // Set "cb_luma_global_settings_dirty" when changing within a frame (so it's uploaded again)

   bool has_init = false;
   bool asi_loaded = true; // Whether we've been loaded from an ASI loader or ReShade Addons system (we assume true until proven otherwise)
   std::thread thread_auto_dumping;
   std::atomic<bool> thread_auto_dumping_running = false;
   std::thread thread_auto_compiling;
   std::atomic<bool> thread_auto_compiling_running = false;
   bool last_pressed_unload = false;
   bool needs_unload_shaders = false;
   bool needs_load_shaders = false; // Load/compile or reload/recompile shaders, no need to default it to true, we have "auto_load" for that

   // There's only one swapchain and one device in most games (e.g. Prey), but the game changes its configuration from different threads.
   // A new device+swapchain can be created if the user resets the settings as the old one is still rendering (or is it?).
   // These are raw pointers that did not add a reference to the counter.
   std::vector<ID3D11Device*> global_native_devices; // Possibly unused
   std::vector<DeviceData*> global_devices_data;
   HWND game_window = 0; // This is fixed forever (in almost all games (e.g. Prey))
#if DEVELOPMENT
   HHOOK game_window_proc_hook = nullptr;
   WNDPROC game_window_original_proc = nullptr;
   WNDPROC game_window_custom_proc = nullptr;
#endif
   thread_local bool last_swapchain_linear_space = false;
   thread_local bool waiting_on_upgraded_resource_init = false;
   thread_local reshade::api::resource_desc upgraded_resource_init_desc = {};
   thread_local void* upgraded_resource_init_data = {};
   // ReShade specific design as we don't get a rejection between the create and init events if creation failed
   thread_local reshade::api::format last_attempted_upgraded_resource_creation_format = reshade::api::format::unknown;
   thread_local reshade::api::format last_attempted_upgraded_resource_view_creation_view_format = reshade::api::format::unknown;

#if DEVELOPMENT
   bool trace_scheduled = false; // For next frame
   bool trace_running = false; // For this frame
   uint32_t trace_count = 0; // Not exactly necessary but... it might help

   uint32_t shader_cache_count = 0; // For dumping

   std::string last_drawn_shader = ""; // Not exactly thread safe but it's fine...

   thread_local reshade::api::command_list* thread_local_cmd_list = nullptr; // Hacky global variable (possibly not cleared, stale), only use to quickly tell the command list of the thread

   // Textures debug drawing
   namespace
   {
      uint32_t debug_draw_shader_hash = 0;
      char debug_draw_shader_hash_string[HASH_CHARACTERS_LENGTH + 1] = {};
      uint64_t debug_draw_pipeline = 0;
      int32_t debug_draw_pipeline_target_instance = -1;

      std::atomic<int32_t> debug_draw_pipeline_instance = 0; // Theoretically should be within "CommandListData" but this should work for most cases

      DebugDrawMode debug_draw_mode = DebugDrawMode::RenderTarget;
      int32_t debug_draw_view_index = 0;
      uint32_t debug_draw_options = (uint32_t)DebugDrawTextureOptionsMask::Fullscreen | (uint32_t)DebugDrawTextureOptionsMask::BackgroundPassthrough | (uint32_t)DebugDrawTextureOptionsMask::Tonemap;
      bool debug_draw_auto_clear_texture = false;
      bool debug_draw_replaced_pass = false; // Whether we print the debugging of the original or replaced pass (the resources bindings etc might be different, though this won't forcefully run the original pass if it was skipped by the game's mod custom code)
      bool debug_draw_auto_gamma = true;
   }

   // Constant Buffers tracking
   namespace
   {
      uint64_t track_buffer_pipeline = 0; // Can be any type of shader
      int32_t track_buffer_pipeline_target_instance = -1;
      int32_t track_buffer_index = 0;

      std::atomic<int32_t> track_buffer_pipeline_instance = 0; // Theoretically should be within "CommandListData" but this should work for most cases
   }

   CB::LumaDevSettings cb_luma_dev_settings_default_value(0.f);
   CB::LumaDevSettings cb_luma_dev_settings_min_value(0.f);
   CB::LumaDevSettings cb_luma_dev_settings_max_value(1.f);
   std::array<std::string, CB::LumaDevSettings::SettingsNum> cb_luma_dev_settings_names;
#endif

   // Forward declares:
   void DumpShader(uint32_t shader_hash);
   void AutoDumpShaders();
   void AutoLoadShaders(DeviceData* device_data);

   // Quick and unsafe. Passing in the hash instead of the string is the only way make sure strings hashes are calculate them at compile time.
   __forceinline ShaderDefineData& GetShaderDefineData(uint32_t hash)
   {
#if 0 // We don't lock "s_mutex_shader_defines" here as it wouldn't be particularly relevant (it won't lead to crashes, as generaly they are not edited in random threads, though having it enabled could lead to deadlocks if there's nested locks!).
      const std::shared_lock lock(s_mutex_shader_defines);
#endif
      assert(shader_defines_data_index.contains(hash));
#if DEVELOPMENT // Just to avoid returning a random variable while developing
      if (!shader_defines_data_index.contains(hash))
      {
         static ShaderDefineData defaultShaderDefineData;
         return defaultShaderDefineData;
      }
#endif
      return shader_defines_data[shader_defines_data_index[hash]];
   }
   __forceinline uint8_t GetShaderDefineCompiledNumericalValue(uint32_t hash)
   {
      return GetShaderDefineData(hash).GetCompiledNumericalValue();
   }

   std::filesystem::path GetShadersRootPath()
   {
      wchar_t file_path[MAX_PATH] = L"";
      // We don't pass in any module handle, thus this will return the path of the executable that loaded our dll
      GetModuleFileNameW(nullptr, file_path, ARRAYSIZE(file_path));

      std::filesystem::path shaders_path = file_path;
      shaders_path = shaders_path.parent_path();
      std::string name_safe = Globals::MOD_NAME;
      // Remove the common invalid characters
      std::replace(name_safe.begin(), name_safe.end(), ' ', '-');
      std::replace(name_safe.begin(), name_safe.end(), ':', '-');
      std::replace(name_safe.begin(), name_safe.end(), '"', '-');
      std::replace(name_safe.begin(), name_safe.end(), '?', '-');
      std::replace(name_safe.begin(), name_safe.end(), '*', '-');
      std::replace(name_safe.begin(), name_safe.end(), '/', '-');
      std::replace(name_safe.begin(), name_safe.end(), '\\', '-');
      shaders_path /= name_safe;

#if DEVELOPMENT
      if (!custom_shaders_path.empty() && (!std::filesystem::is_directory(custom_shaders_path) || std::filesystem::is_empty(custom_shaders_path)))
      {
         shaders_path = custom_shaders_path;
      }
#endif

#if DEVELOPMENT && defined(SOLUTION_DIR) && (!defined(REMOTE_BUILD) || !REMOTE_BUILD)
      // Fall back on the solution "Shaders" folder if we are in development mode and there's no luma shaders folder created in the game side (or if it's empty, as it was accidentally quickly generated by a non dev build).
      // This will only work when built locally, and should be avoided on remote build machines!
      if (!std::filesystem::is_directory(shaders_path) || std::filesystem::is_empty(shaders_path))
      {
         std::filesystem::path solution_shaders_path = SOLUTION_DIR;
         solution_shaders_path /= "Shaders";
         if (std::filesystem::is_directory(solution_shaders_path))
         {
            shaders_path = solution_shaders_path;
         }
      }
#endif
      return shaders_path;
   }

   // TODO: if this was ever too slow, given we iterate through the shader folder which also contains (possibly hundreds of) dumps and our built binaries,
   // we could split it up in 3 main branches (shaders code, shaders binaries and shaders dump).
   // Alternatively we could make separate iterators for each main shaders folder.
   //
   // Note: the paths here might also be hardcoded in GitHub actions (build scripts)
   bool IsValidShadersSubPath(const std::filesystem::path& shader_directory, const std::filesystem::path& entry_path, bool& out_is_global)
   {
      const std::filesystem::path entry_directory = entry_path.parent_path();

      // Global shaders (game independent)
      const auto global_shader_directory = shader_directory / "Global";
      if (entry_directory == global_shader_directory)
      {
         out_is_global = true;
         return true;
      }
      
      const auto game_shader_directory = shader_directory / Globals::GAME_NAME;
      if (entry_directory == game_shader_directory)
      {
         return true;
      }
      // Note: we could add a sub game name path for generic mods (e.g. Unity, Unreal), but we already have an acronym in front of their shaders name, and support per game shader defines, so it's not particularly needed

#if DEVELOPMENT && ALLOW_LOADING_DEV_SHADERS
      // WIP and test and unused shaders (they expect ".../" in front of their include dirs, given the nested path)
      const auto dev_directory = game_shader_directory / "Dev";
      const auto unused_directory = game_shader_directory / "Unused";
      if (entry_directory == dev_directory || entry_path == unused_directory)
      {
         return true;
      }
#endif
      return false;
   }

   void ClearCustomShader(uint64_t shader_hash)
   {
      const std::unique_lock lock(s_mutex_loading);
      auto custom_shader = custom_shaders_cache.find(shader_hash);
      // TODO: why not just remove it from the array or call the default initializer?
      if (custom_shader != custom_shaders_cache.end() && custom_shader->second != nullptr)
      {
         custom_shader->second->code.clear();
         custom_shader->second->is_hlsl = false;
         custom_shader->second->is_luma_native = false;
         custom_shader->second->file_path.clear();
         custom_shader->second->preprocessed_hash = 0;
         custom_shader->second->compilation_errors.clear();
#if DEVELOPMENT || TEST
         custom_shader->second->compilation_error = false;
         custom_shader->second->preprocessed_code.clear();
#endif
      }
   }

   void UnloadCustomShaders(DeviceData& device_data, const std::unordered_set<uint64_t>& pipelines_filter = std::unordered_set<uint64_t>(), bool immediate = false, bool clean_custom_shader = true)
   {
      const std::unique_lock lock(s_mutex_generic);
      for (auto& pair : device_data.pipeline_cache_by_pipeline_handle)
      {
         auto& cached_pipeline = pair.second;
         if (cached_pipeline == nullptr || (!pipelines_filter.empty() && !pipelines_filter.contains(cached_pipeline->pipeline.handle))) continue;

         // In case this is a full "unload" of all shaders
         if (pipelines_filter.empty())
         {
            if (clean_custom_shader)
            {
               for (auto shader_hash : cached_pipeline->shader_hashes)
               {
                  ClearCustomShader(shader_hash);
               }
            }
         }

         if (!cached_pipeline->cloned) continue;
         cached_pipeline->cloned = false; // This stops the cloned pipeline from being used in the next frame, allowing us to destroy it
         device_data.cloned_pipeline_count--;
         device_data.cloned_pipelines_changed = true;

         if (immediate)
         {
            cached_pipeline->device->destroy_pipeline(reshade::api::pipeline{ cached_pipeline->pipeline_clone.handle });
         }
         else
         {
            device_data.pipelines_to_destroy[cached_pipeline->pipeline_clone.handle] = cached_pipeline->device;
         }
         cached_pipeline->pipeline_clone = { 0 };
         device_data.pipeline_cache_by_pipeline_clone_handle.erase(cached_pipeline->pipeline_clone.handle);
      }
   }

   // Expects "s_mutex_loading" to make sure we don't try to compile/load any other files we are currently deleting
   void CleanShadersCache()
   {
      const auto directory = GetShadersRootPath();
      if (!std::filesystem::exists(directory))
      {
         return;
      }
      
      for (const auto& entry : std::filesystem::recursive_directory_iterator(directory))
      {
         bool is_global = false;
         const auto& entry_path = entry.path();
         if (!IsValidShadersSubPath(directory, entry_path, is_global))
         {
            continue;
         }
         if (!entry.is_regular_file())
         {
            continue;
         }
         const bool is_cso = entry_path.extension().compare(".cso") == 0;
         if (!entry_path.has_extension() || !entry_path.has_stem() || !is_cso)
         {
            continue;
         }

         const auto filename_no_extension_string = entry_path.stem().string();

#if 1 // Optionally leave any "raw" cso that was likely copied from the dumped shaders folder (these were not compiled from a custom hlsl shader by the same hash)
         if (filename_no_extension_string.length() >= strlen("0x12345678") && filename_no_extension_string[0] == '0' && filename_no_extension_string[1] == 'x')
         {
            continue;
         }
#endif

         std::filesystem::remove(entry_path);
      }
   }

   // Expects "s_mutex_loading" and "s_mutex_shader_objects"
   template<typename T = ID3D11DeviceChild>
   void CreateShaderObject(ID3D11Device* native_device, const std::string& shader_name, com_ptr<T>& shader_object, const std::optional<std::set<std::string>>& shader_names_filter, bool force_delete_previous = !(bool)FORCE_KEEP_CUSTOM_SHADERS_LOADED, bool trigger_assert = false)
   {
      ASSERT_ONCE_MSG(shader_name.starts_with("Luma_") && !shader_name.contains("0x"), "Luma's native shaders (whether they are global or game specific) should ideally have \"Luma_\" in front of their name, and have no shader hash, otherwise they might not get detected/compiled.");
      if (!shader_names_filter.has_value() || shader_names_filter.value().contains(shader_name))
      {
         if (force_delete_previous)
         {
            // The shader changed, so we should clear its previous version resource anyway (to avoid keeping an outdated version)
            shader_object = nullptr;
         }

         reshade::api::pipeline_subobject_type shader_type = reshade::api::pipeline_subobject_type::unknown;
         if constexpr (typeid(T) == typeid(ID3D11GeometryShader))
            shader_type = reshade::api::pipeline_subobject_type::geometry_shader;
         else if constexpr (typeid(T) == typeid(ID3D11VertexShader))
            shader_type = reshade::api::pipeline_subobject_type::vertex_shader;
         else if constexpr (typeid(T) == typeid(ID3D11PixelShader))
            shader_type = reshade::api::pipeline_subobject_type::pixel_shader;
         else if constexpr (typeid(T) == typeid(ID3D11ComputeShader))
            shader_type = reshade::api::pipeline_subobject_type::compute_shader;
         else
            static_assert(false);

         const uint64_t shader_hash_64 = Shader::ShiftHash32ToHash64(Shader::StrToHash(shader_name + "_" + std::to_string(uint32_t(shader_type))));
         // No warning if this fails, it can happen on boot depending on the execution order
         if (custom_shaders_cache.contains(shader_hash_64))
         {
            // Delay the deletition
            if (!force_delete_previous)
            {
               shader_object = nullptr;
            }

            const CachedCustomShader* custom_shader_cache = custom_shaders_cache[shader_hash_64];

            if constexpr (typeid(T) == typeid(ID3D11GeometryShader))
            {
               HRESULT hr = native_device->CreateGeometryShader(custom_shader_cache->code.data(), custom_shader_cache->code.size(), nullptr, &shader_object);
               assert(!trigger_assert || SUCCEEDED(hr));
            }
            else if constexpr (typeid(T) == typeid(ID3D11VertexShader))
            {
               HRESULT hr = native_device->CreateVertexShader(custom_shader_cache->code.data(), custom_shader_cache->code.size(), nullptr, &shader_object);
               assert(!trigger_assert || SUCCEEDED(hr));
            }
            else if constexpr (typeid(T) == typeid(ID3D11PixelShader))
            {
               HRESULT hr = native_device->CreatePixelShader(custom_shader_cache->code.data(), custom_shader_cache->code.size(), nullptr, &shader_object);
               assert(!trigger_assert || SUCCEEDED(hr));
            }
            else if constexpr (typeid(T) == typeid(ID3D11ComputeShader))
            {
               HRESULT hr = native_device->CreateComputeShader(custom_shader_cache->code.data(), custom_shader_cache->code.size(), nullptr, &shader_object);
               assert(!trigger_assert || SUCCEEDED(hr));
            }
            else
            {
               static_assert(false);
            }
         }
      }
   }

   // Expects "s_mutex_loading"
   void CreateCustomDeviceShaders(DeviceData& device_data, std::optional<std::set<std::string>> shader_names_filter = std::nullopt, bool lock = true)
   {
      if (lock) s_mutex_shader_objects.lock();
      CreateShaderObject(device_data.native_device, shader_name_copy_vertex, device_data.copy_vertex_shader, shader_names_filter);
      CreateShaderObject(device_data.native_device, shader_name_copy_pixel, device_data.copy_pixel_shader, shader_names_filter);
      CreateShaderObject(device_data.native_device, shader_name_transform_function_copy_pixel, device_data.display_composition_pixel_shader, shader_names_filter);
      CreateShaderObject(device_data.native_device, shader_name_draw_purple_pixel, device_data.draw_purple_pixel_shader, shader_names_filter);
      CreateShaderObject(device_data.native_device, shader_name_draw_purple_compute, device_data.draw_purple_compute_shader, shader_names_filter);
      CreateShaderObject(device_data.native_device, shader_name_normalize_lut_3d_compute, device_data.normalize_lut_3d_compute_shader, shader_names_filter);
      game->CreateShaderObjects(device_data, shader_names_filter);
      device_data.created_custom_shaders = true; // Some of the shader object creations above might have failed due to filtering, but they will likely be compiled soon after anyway
      if (lock) s_mutex_shader_objects.unlock();
   }

   // Compiles all the "custom" shaders we have in our shaders folder
   void CompileCustomShaders(DeviceData* optional_device_data = nullptr, bool warn_about_duplicates = false, const std::unordered_set<uint64_t>& pipelines_filter = std::unordered_set<uint64_t>())
   {
      std::vector<std::string> shader_defines;
      // Cache them for consistency and to avoid threads from halting
      {
         const std::shared_lock lock(s_mutex_shader_defines);
         constexpr uint32_t cbuffer_defines = 3;
         uint32_t game_specific_defines = 1;
         if (sub_game_shader_define != nullptr)
         {
            game_specific_defines++;
         }
         const uint32_t total_extra_defines = cbuffer_defines + game_specific_defines;
         shader_defines.assign((shader_defines_data.size() + total_extra_defines) * 2, "");

         size_t shader_defines_index = shader_defines.size() - (total_extra_defines * 2);
         
         // Clean up the game name from non letter characters (including spaces), and make it all upper case
         std::string game_name = Globals::GAME_NAME;
			RemoveNonLetterOrNumberCharacters(game_name.data(), '_'); // Ideally we should remove all weird characters and turn spaces into underscores
         std::transform(game_name.begin(), game_name.end(), game_name.begin(),
            [](unsigned char c) { return std::toupper(c); });
         shader_defines[shader_defines_index++] = "GAME_" + game_name;
         shader_defines[shader_defines_index++] = "1";

         if (sub_game_shader_define != nullptr)
         {
            shader_defines[shader_defines_index++] = sub_game_shader_define;
            shader_defines[shader_defines_index++] = "1";
         }

         // Define 3 shader cbuffers indexes (e.g. "(b13)")
         // We automatically generate unique values for each cbuffer to make sure they don't overlap.
         // This is because in case the users disabled some of them, we don't want them to bother to
         // define unique indexes for each of them, but the shader compiler fails if two cbuffers have the same value,
         // so we have to find the "next" unique one.
         uint32_t luma_settings_cbuffer_define_index, luma_data_cbuffer_define_index, luma_ui_cbuffer_define_index;
         std::unordered_set<uint32_t> excluded_values;
         if (luma_settings_cbuffer_index <= D3D11_COMMONSHADER_CONSTANT_BUFFER_API_SLOT_COUNT - 1)
            luma_settings_cbuffer_define_index = luma_settings_cbuffer_index;
         else
            luma_settings_cbuffer_define_index = FindNextUniqueNumberInRange(D3D11_COMMONSHADER_CONSTANT_BUFFER_API_SLOT_COUNT / 2, 0, D3D11_COMMONSHADER_CONSTANT_BUFFER_API_SLOT_COUNT - 1, excluded_values);
         excluded_values.emplace(luma_settings_cbuffer_define_index);
         if (luma_data_cbuffer_index <= D3D11_COMMONSHADER_CONSTANT_BUFFER_API_SLOT_COUNT - 1)
            luma_data_cbuffer_define_index = luma_data_cbuffer_index;
         else
            luma_data_cbuffer_define_index = FindNextUniqueNumberInRange(D3D11_COMMONSHADER_CONSTANT_BUFFER_API_SLOT_COUNT / 2 - 1, 0, D3D11_COMMONSHADER_CONSTANT_BUFFER_API_SLOT_COUNT - 1, excluded_values);
         excluded_values.emplace(luma_data_cbuffer_define_index);
         if (luma_ui_cbuffer_index <= D3D11_COMMONSHADER_CONSTANT_BUFFER_API_SLOT_COUNT - 1)
            luma_ui_cbuffer_define_index = luma_ui_cbuffer_index;
         else
            luma_ui_cbuffer_define_index = FindNextUniqueNumberInRange(D3D11_COMMONSHADER_CONSTANT_BUFFER_API_SLOT_COUNT / 2 - 2, 0, D3D11_COMMONSHADER_CONSTANT_BUFFER_API_SLOT_COUNT - 1, excluded_values);
         excluded_values.emplace(luma_ui_cbuffer_define_index);

         shader_defines[shader_defines_index++] = "LUMA_SETTINGS_CB_INDEX";
         shader_defines[shader_defines_index++] = "b" + std::to_string(luma_settings_cbuffer_define_index);
         shader_defines[shader_defines_index++] = "LUMA_DATA_CB_INDEX";
         shader_defines[shader_defines_index++] = "b" + std::to_string(luma_data_cbuffer_define_index);
         shader_defines[shader_defines_index++] = "LUMA_UI_DATA_CB_INDEX";
         shader_defines[shader_defines_index++] = "b" + std::to_string(luma_ui_cbuffer_define_index);

			ASSERT_ONCE(shader_defines_index == shader_defines.size());

         for (uint32_t i = 0; i < shader_defines_data.size(); i++)
         {
            shader_defines[(i * 2)] = shader_defines_data[i].compiled_data.name;
            shader_defines[(i * 2) + 1] = shader_defines_data[i].compiled_data.value;
         }
      }

      // We need to clear this every time "CompileCustomShaders()" is called as we can't clear previous logs from it. We do this even if we have some "pipelines_filter"
      {
         const std::unique_lock lock(s_mutex_loading);
         shaders_compilation_errors.clear();
      }

      const auto directory = GetShadersRootPath();
      bool shaders_directory_created_or_empty = false;
      if (!std::filesystem::exists(directory))
      {
         if (!std::filesystem::create_directories(directory))
         {
            const std::unique_lock lock(s_mutex_loading);
            shaders_compilation_errors = "Cannot find nor create shaders directory";
            return;
         }
         shaders_directory_created_or_empty = true;
      }
      else if (!std::filesystem::is_directory(directory))
      {
         const std::unique_lock lock(s_mutex_loading);
         shaders_compilation_errors = "The shaders path is already taken by a file";
         return;
      }
      else if (std::filesystem::is_empty(directory))
      {
         shaders_directory_created_or_empty = true;
      }

      if (pipelines_filter.empty())
      {
         const std::unique_lock lock_shader_defines(s_mutex_shader_defines);

         code_shaders_defines.clear();
#if DEVELOPMENT
         const auto prev_cb_luma_dev_settings_default_value = cb_luma_dev_settings_default_value;
         cb_luma_dev_settings_default_value = CB::LumaDevSettings(0.f);
         cb_luma_dev_settings_min_value = CB::LumaDevSettings(0.f);
         cb_luma_dev_settings_max_value = CB::LumaDevSettings(1.f);
         cb_luma_dev_settings_names = {};
#endif

         // Add the global (generic) include and the game specific one
         auto settings_directories = { directory / "Includes" / "Settings.hlsl", directory / Globals::GAME_NAME / "Includes" / "Settings.hlsl" };
         bool is_global_settings = true;
         for (auto settings_directory : settings_directories)
         {
            if (std::filesystem::is_regular_file(settings_directory))
            {
               try
               {
                  std::ifstream file;
                  file.exceptions(std::ifstream::failbit | std::ifstream::badbit);
                  file.open(settings_directory.c_str()); // Open file
                  std::stringstream str_stream;
                  str_stream << file.rdbuf(); // Read the file (we could use "D3DReadFileToBlob" to append the hsls includes in the file, but then stuff that is defined out wouldn't be part of the text)
                  std::string str = str_stream.str(); // str holds the content of the file
                  size_t i = -1;
                  int settings_count = 0;
                  while (true)
                  {
                     // Iterate the string line (break) by line (break),
                     // and check for defines values.

                     size_t i0 = i + 1;
                     i = str.find('\n', i0);
                     bool finished = false;
                     if (i0 == i) continue;
                     if (i == std::string::npos)
                     {
                        i = str.length();
                        finished = true;
                     }

                     // TODO: make this more flexible, allowing spaces around "#" and "define" etc,
                     // and defines values that are not numerical (from 0 to 9)
                     std::string_view str_view(&str[i0], i - i0);
                     if (str_view.rfind("#define ", 0) == 0)
                     {
                        str_view = str_view.substr(strlen("#define "));
                        size_t space_index = str_view.find(' ');
                        if (space_index != std::string::npos)
                        {
                           std::string_view define_name = str_view.substr(0, space_index);
                           size_t second_space_index = str_view.find(' ', space_index);
                           if (second_space_index != std::string::npos)
                           {
                              std::string_view define_value = str_view.substr(space_index + 1, second_space_index);
                              uint8_t define_int_value = define_value[0] - '0';
                              if (define_int_value <= 9)
                              {
                                 code_shaders_defines.emplace(define_name, define_int_value);
                              }
                           }
                        }
                     }
#if DEVELOPMENT
                     // Reflections on dev settings.
                     // They can have a comment like "// Default, Min, Max, Name" next to them (e.g. "// 0.5, 0, 1.3, Custom Name").
                     const auto dev_setting_pos = str_view.find("float DevSetting");
                     if (is_global_settings && dev_setting_pos != std::string::npos)
                     {
                        if (settings_count >= CB::LumaDevSettings::SettingsNum) continue;
                        settings_count++;
                        const auto meta_data_pos = str_view.find("//");
                        if (meta_data_pos == std::string::npos || dev_setting_pos >= meta_data_pos) continue;
                        i0 += meta_data_pos + 2;
                        std::string str_line(&str[i0], i - i0);
                        std::stringstream ss(str_line);
                        if (!ss.good()) continue;

                        int settings_float_count = 0;
                        float str_float;
                        bool reached_end = false;
                        while (ss.peek() == ' ')
                        {
                           ss.ignore();
                           if (!ss.good()) { reached_end = true; break; }
                        }
                        // The float read would seemengly advance some state in the stream buffer even if it failed finding it, so skip it in case the next value is not a number (ignore ".3f" like definitions...).
                        // Float heading spaces are automatically ignored.
                        while (!reached_end && ss.peek() >= '0' && ss.peek() <= '9' && ss >> str_float)
                        {
                           if (settings_float_count == 0) cb_luma_dev_settings_default_value[settings_count - 1] = str_float;
                           else if (settings_float_count == 1) cb_luma_dev_settings_min_value[settings_count - 1] = str_float;
                           else if (settings_float_count == 2) cb_luma_dev_settings_max_value[settings_count - 1] = str_float;
                           settings_float_count++;
                           if (!ss.good()) { reached_end = true; break; };
                           // Remove known (supported) characters to ignore (spaces are already ignored above anyway)
                           while (ss.peek() == ',' || ss.peek() == ' ')
                           {
                              ss.ignore();
                              if (!ss.good()) { reached_end = true; break; }
                           }
                        }

                        std::string str;
                        auto ss_pos = ss.tellg();
                        // If we found a string, read the whole remaining stream buffer, otherwise the "str" string would end at the first space
                        if (!reached_end && ss >> str)
                        {
                           cb_luma_dev_settings_names[settings_count - 1] = ss.str();
                           cb_luma_dev_settings_names[settings_count - 1] = cb_luma_dev_settings_names[settings_count - 1].substr(ss_pos, cb_luma_dev_settings_names[settings_count - 1].length() - ss_pos);
                        }
                     }
   #endif

                     if (finished) break;
                  }
               }
               catch (const std::exception& e)
               {
               }
#if DEVELOPMENT
               // Re-apply the default settings if they changed
               if (is_global_settings && memcmp(&cb_luma_dev_settings_default_value, &prev_cb_luma_dev_settings_default_value, sizeof(cb_luma_dev_settings_default_value)) != 0)
               {
                  const std::unique_lock lock_reshade(s_mutex_reshade);
                  cb_luma_global_settings.DevSettings = cb_luma_dev_settings_default_value;
               }
#endif
            }
            else
            {
               ASSERT_ONCE(shaders_directory_created_or_empty || !is_global_settings); // Missing "Settings.hlsl" file (the game specific one doesn't need to exist) (ignored if we just created the shaders folder)
            }
            is_global_settings = false; // Only the first instance is the global settings
         }
      }

      std::set<std::string> changed_luma_native_shaders_names;
      for (const auto& entry : std::filesystem::recursive_directory_iterator(directory))
      {
         bool is_global = false;
         const auto& entry_path = entry.path();
         if (!IsValidShadersSubPath(directory, entry_path, is_global))
         {
            continue;
         }
         if (!entry.is_regular_file())
         {
#if _DEBUG && LOG_VERBOSE
            reshade::log::message(reshade::log::level::warning, "LoadCustomShaders(not a regular file)");
#endif
            continue;
         }
         const bool is_hlsl = entry_path.extension().compare(".hlsl") == 0;
         const bool is_cso = entry_path.extension().compare(".cso") == 0;
         if (!entry_path.has_extension() || !entry_path.has_stem() || (!is_hlsl && !is_cso))
         {
            std::stringstream s;
            s << "LoadCustomShaders(Missing extension or stem or unknown extension: ";
            s << entry_path.string();
            s << ")";
            reshade::log::message(reshade::log::level::warning, s.str().c_str());
            continue;
         }

         const auto filename_no_extension_string = entry_path.stem().string();
         std::vector<std::string> hash_strings;
         std::string shader_target;

         bool is_luma_native = is_global;
         std::string luma_native_name = "";

         if (is_hlsl)
         {
            const bool has_hash = filename_no_extension_string.find("0x") != std::string::npos;
            const bool is_custom_shader = filename_no_extension_string.starts_with("Luma_");
            if (!has_hash && is_custom_shader)
            {
               is_luma_native = true;
            }
            const auto length = filename_no_extension_string.length();
            const char* hash_sample = "0x12345678";
            const auto hash_length = strlen(hash_sample); // HASH_CHARACTERS_LENGTH+2
            const auto sm_length = strlen("xs_n_n"); // Shader Model
            const auto min_expected_length = (is_luma_native ? 0 : hash_length) + 1 + sm_length; // The shader model is appended after any name, so we add 1 for a dot (e.g. "0x12345678.ps_5_0")
            
            if (length < min_expected_length) continue;
            ASSERT_ONCE(length > min_expected_length); // HLSL files are expected to have a name in front of the hash or shader model. They can still be loaded, but they won't be distinguishable from raw cso files
            shader_target = filename_no_extension_string.substr(length - sm_length, sm_length);
            if (shader_target[2] != '_') continue;
            if (shader_target[4] != '_') continue;
            if (is_luma_native)
            {
               if (length <= min_expected_length) continue; // We couldn't identify it
               luma_native_name = filename_no_extension_string.substr(0, filename_no_extension_string.size() - (sm_length + 1));
               // Add the shader target type, to make sure the same luma native shader names can be used with different shader types (by generating a different hash for it)
               reshade::api::pipeline_subobject_type shader_type = Shader::ShaderIdentifierToType(shader_target);
               hash_strings.push_back(Shader::Hash_NumToStr(Shader::StrToHash(luma_native_name + "_" + std::to_string(uint32_t(shader_type)))));
            }
            else
            {
               size_t next_hash_pos = filename_no_extension_string.find("0x");
               if (next_hash_pos == std::string::npos) continue;
               do
               {
                  hash_strings.push_back(filename_no_extension_string.substr(next_hash_pos + 2 /*0x*/, HASH_CHARACTERS_LENGTH));
                  next_hash_pos = filename_no_extension_string.find("0x", next_hash_pos + 1);
               } while (next_hash_pos != std::string::npos);
            }
         }
         // We don't load global CSOs, given these are shaders we made ourselves (unless we wanted to ship pre-built global CSOs, but that's not wanted for now)
         else if (is_cso && !is_global)
         {
            // As long as cso starts from "0x12345678", it's good, they don't need the shader type specified
            if (filename_no_extension_string.size() < 10)
            {
               std::stringstream s;
               s << "LoadCustomShaders(Invalid cso file format: ";
               s << filename_no_extension_string;
               s << ")";
               reshade::log::message(reshade::log::level::warning, s.str().c_str());
               continue;
            }
            hash_strings.push_back(filename_no_extension_string.substr(2, HASH_CHARACTERS_LENGTH));

            // Only directly load the cso if no hlsl by the same name exists,
            // which implies that we either did not ship the hlsl and shipped the pre-compiled cso(s),
            // or that this is a vanilla cso dumped from the game.
            // If the hlsl also exists, we load the cso though the hlsl code loading below (by redirecting it).
            // 
            // Note that if we have two shaders with the same hash but different overall name (e.g. the description part of the shader),
            // whichever is iterated last will load on top of the previous one (whether they are both cso, or cso and hlsl etc).
            // We don't care about "fixing" that because it's not a real world case.
            const auto filename_hlsl_string = filename_no_extension_string + ".hlsl";
            if (!std::filesystem::exists(filename_hlsl_string)) continue;
         }
         // Any other case (non hlsl non cso) is already earlied out above

         for (const auto& hash_string : hash_strings)
         {
            uint64_t shader_hash;
            try
            {
               shader_hash = Shader::Hash_StrToNum(hash_string);
            }
            catch (const std::exception& e)
            {
               continue;
            }

            // To avoid polluting the game's own shaders hashes with Luma native shaders hashes (however unlikely),
            // shift their hash by 32 bits, to a 64 bits unique one.
            if (is_luma_native)
            {
               shader_hash = Shader::ShiftHash32ToHash64(shader_hash);
            }

            // Early out before compiling (even if it's a luma native shader, yes)
            ASSERT_ONCE(pipelines_filter.empty() || optional_device_data); // We can't apply a filter if we didn't pass in the "DeviceData"
            if (!pipelines_filter.empty() && optional_device_data)
            {
               if (is_luma_native)
               {
                  break;
               }
               bool pipeline_found = false;
               const std::shared_lock lock(s_mutex_generic);
               for (const auto& pipeline_pair : optional_device_data->pipeline_cache_by_pipeline_handle)
               {
                  if (std::find(pipeline_pair.second->shader_hashes.begin(), pipeline_pair.second->shader_hashes.end(), shader_hash) == pipeline_pair.second->shader_hashes.end()) continue;
                  if (pipelines_filter.contains(pipeline_pair.first))
                  {
                     pipeline_found = true;
                  }
                  break;
               }
               if (!pipeline_found)
               {
                  continue;
               }
            }

            // Add defines to specify the current "target" hash we are building the shader with (some shaders can share multiple permutations (hashes) within the same hlsl)
            std::vector<std::string> local_shader_defines = shader_defines;
            if (!is_luma_native)
            {
               local_shader_defines.push_back("_" + hash_string);
               local_shader_defines.push_back("1");
            }
            if (!is_global)
            {
#if defined(LUMA_GAME_CB_STRUCTS) && DEVELOPMENT && 0 // Disabled as it's not particularly useful, if the CB struct is missing, shaders won't compile anyway
               // Highlight that the luma game settings struct (nested into the global luma cb) is required by all includes,
               // making sure it wasn't accidentally left out, which would leave the cb definition off.
               local_shader_defines.push_back("REQUIRES_LUMA_GAME_CB_STRUCTS");
               local_shader_defines.push_back("1");
#endif
            }

            // Note that we "shader_hash" might have been modified in the "is_luma_native" case,
            // so it'd be outdated here, but it shouldn't really matter, as the chances of conflict are ~0,
            // and even then, this is just the procompilation phase hash.
            char config_name[std::string_view("Shader#").size() + HASH_CHARACTERS_LENGTH + 1] = "";
            sprintf(&config_name[0], "Shader#%s", hash_string.c_str());

            const std::unique_lock lock(s_mutex_loading); // Don't lock until now as we didn't access any shared data
            auto& custom_shader = custom_shaders_cache[shader_hash]; // Add default initialized shader
            const bool has_custom_shader = (custom_shaders_cache.find(shader_hash) != custom_shaders_cache.end()) && (custom_shader != nullptr); // Weird code...
            std::wstring original_file_path_cso; // Only valid for hlsl files
            std::wstring trimmed_file_path_cso; // Only valid for hlsl files

            if (is_hlsl)
            {
               std::wstring file_path_cso = entry_path.c_str();
               if (file_path_cso.ends_with(L".hlsl"))
               {
                  file_path_cso = file_path_cso.substr(0, file_path_cso.size() - 5);
                  file_path_cso += L".cso";
               }
               else if (!file_path_cso.ends_with(L".cso"))
               {
                  file_path_cso += L".cso";
               }
               original_file_path_cso = file_path_cso;

               size_t first_hash_pos = file_path_cso.find(L"0x");
               if (!is_luma_native && first_hash_pos != std::string::npos)
               {
                  // Remove all the non first shader hashes in the file (and anything in between them),
                  // we then replace the first hash with our target one
                  size_t prev_hash_pos = first_hash_pos;
                  size_t next_hash_pos = file_path_cso.find(L"0x", prev_hash_pos + 1);
                  while (next_hash_pos != std::string::npos && (file_path_cso.length() - next_hash_pos) >= 10)
                  {
                     file_path_cso = file_path_cso.substr(0, prev_hash_pos + 10) + file_path_cso.substr(next_hash_pos + 10);
                     prev_hash_pos = first_hash_pos;
                     next_hash_pos = file_path_cso.find(L"0x", prev_hash_pos + 1);
                  }
                  std::wstring hash_wstring = std::wstring(hash_string.begin(), hash_string.end());
                  file_path_cso.replace(first_hash_pos + 2 /*0x*/, HASH_CHARACTERS_LENGTH, hash_wstring.c_str());
               }
               trimmed_file_path_cso = file_path_cso;
            }

            // Fill up the shader data the first time it's found
            if (!has_custom_shader)
            {
               custom_shader = new CachedCustomShader();

               std::size_t preprocessed_hash = custom_shader->preprocessed_hash; // Empty
               // Note that if anybody manually changed the config hash, the data here could mismatch and end up recompiling when not needed or skipping recompilation even if needed (near impossible chance)
               const bool should_load_compiled_shader = is_hlsl && !prevent_shader_cache_loading; // If this shader doesn't have an hlsl, we should never read it or save it on disk, there's no need (we can still fall back on the original .cso if needed)
               if (should_load_compiled_shader && reshade::get_config_value(nullptr, NAME_ADVANCED_SETTINGS.c_str(), &config_name[0], preprocessed_hash))
               {
                  // This will load the matching cso
                  // TODO: move these to a "Bin" sub folder called "cache"? It'd make everything cleaner (and the "CompileCustomShaders()" could simply nuke a directory then, and we could remove the restriction where hlsl files need to have a name in front of the hash),
                  // but it would make it harder to manually remove a single specific shader cso we wanted to nuke for test reasons (especially if we exclusively put the hash in their cso name).
                  if (Shader::LoadCompiledShaderFromFile(custom_shader->code, trimmed_file_path_cso.c_str()))
                  {
                     // If both reading the pre-processor hash from config and the compiled shader from disk succeeded, then we are free to continue as if this shader was working
                     custom_shader->file_path = entry_path;
                     custom_shader->is_hlsl = is_hlsl;
                     custom_shader->is_luma_native = is_luma_native;
                     custom_shader->preprocessed_hash = preprocessed_hash;
                     if (is_luma_native)
                     {
                        changed_luma_native_shaders_names.emplace(luma_native_name);
                     }
                     // Theoretically at this point, the shader pre-processor below should skip re-compiling this shader unless the hash changed
                  }
               }
            }
            else if (warn_about_duplicates)
            {
               warn_about_duplicates = false;
#if !DEVELOPMENT
               const std::string warn_message = "It seems like you have duplicate shaders in your \"" + std::string(NAME) + "\" folder, please delete it and re-apply the files from the latest version of the mod.";
               MessageBoxA(game_window, warn_message.c_str(), NAME, MB_SETFOREGROUND);
#endif
            }

            CComPtr<ID3DBlob> uncompiled_code_blob;

            if (is_hlsl)
            {
               constexpr bool compile_from_current_path = false; // Set this to true to include headers from the current directory instead of the file root folder

               const auto previous_path = std::filesystem::current_path();
               if (compile_from_current_path)
               {
                  // Set the current path to the shaders directory, it can be needed by the DX compilers (specifically by the preprocess functions)
                  std::filesystem::current_path(directory);
               }

               std::string compilation_errors;

               // Skip compiling the shader if it didn't change
               // Note that this won't replace "custom_shader->compilation_error" unless there was any new error/warning, and that's kind of what we want
               // Note that this will not try to build the shader again if the last compilation failed and its files haven't changed
               bool error = false;
               std::string preprocessed_code;
					std::string* preprocessed_code_ref = &preprocessed_code;
#if DEVELOPMENT
               preprocessed_code_ref = &custom_shader->preprocessed_code;
#endif
               const bool needs_compilation = Shader::PreprocessShaderFromFile(entry_path.c_str(), compile_from_current_path ? entry_path.filename().c_str() : entry_path.c_str(), shader_target.c_str(), *preprocessed_code_ref, custom_shader->preprocessed_hash, uncompiled_code_blob, local_shader_defines, error, &compilation_errors);

               // Only overwrite the previous compilation error if we have any preprocessor errors
               if (!compilation_errors.empty() || error)
               {
                  custom_shader->compilation_errors = compilation_errors;
#if DEVELOPMENT || TEST
                  custom_shader->compilation_error = error;
#endif
#if !DEVELOPMENT && !TEST // Ignore warnings for public builds
                  if (error)
#endif
                  {
                     shaders_compilation_errors.append(filename_no_extension_string);
                     shaders_compilation_errors.append(": ");
                     shaders_compilation_errors.append(compilation_errors);
                  }
               }
               // Print out the same (last) compilation errors again if the shader still needs to be compiled but hasn't changed.
               // We might want to ignore this case for public builds (we can't know whether this was an error or a warning atm),
               // but it seems like this can only trigger after a shader had previous failed to build, so these should be guaranteed to be errors,
               // and thus we should be able to print them to all users (we don't want warnings in public builds).
               else if (!needs_compilation && custom_shader->code.size() == 0 && !custom_shader->compilation_errors.empty())
               {
                  shaders_compilation_errors.append(filename_no_extension_string);
                  shaders_compilation_errors.append(": ");
                  shaders_compilation_errors.append(custom_shader->compilation_errors);
               }

               if (compile_from_current_path)
               {
                  // Restore it to avoid unknown consequences
                  std::filesystem::current_path(previous_path);
               }

               if (!needs_compilation)
               {
                  ASSERT_ONCE(custom_shader->is_luma_native == is_luma_native); // Make 100% all the branches above cached right flags
                  continue;
               }
            }

            // If we reached this place, we can consider this shader as "changed" even if it will fail compiling.
            // We don't care to avoid adding duplicate elements to this list.
            if (is_luma_native)
            {
               changed_luma_native_shaders_names.emplace(luma_native_name);
            }

            // For extra safety, just clear everything that will be re-assigned below if this custom shader already existed
            if (has_custom_shader)
            {
               auto preprocessed_hash = custom_shader->preprocessed_hash;
#if DEVELOPMENT || TEST
               auto preprocessed_code = custom_shader->preprocessed_code;
#endif
               ClearCustomShader(shader_hash);
               // Keep the data we just filled up
               custom_shader->preprocessed_hash = preprocessed_hash;
#if DEVELOPMENT || TEST
               custom_shader->preprocessed_code = preprocessed_code;
#endif
            }
            custom_shader->file_path = entry_path;
            custom_shader->is_hlsl = is_hlsl;
            custom_shader->is_luma_native = is_luma_native;
            // Clear these in case the compiler didn't overwrite them
            custom_shader->code.clear();
            custom_shader->compilation_errors.clear();
#if DEVELOPMENT || TEST
            custom_shader->compilation_error = false;
#endif

            if (is_hlsl)
            {
#if _DEBUG && LOG_VERBOSE
               {
                  std::stringstream s;
                  s << "LoadCustomShaders(Compiling file: ";
                  s << entry_path.string();
                  s << ", global: " << is_global;
                  s << ", luma native: " << is_luma_native;
                  s << ", hash: " << PRINT_CRC32(shader_hash);
                  s << ", target: " << shader_target;
                  s << ")";
                  reshade::log::message(reshade::log::level::debug, s.str().c_str());
               }
#endif

               bool error = false;
               // TODO: specify the name of the function to compile (e.g. "main" or "HDRTonemapPS") so we could unify more shaders into a single file with multiple techniques? We kinda can now already as we have shader hash defines
               Shader::CompileShaderFromFile(
                  custom_shader->code,
                  uncompiled_code_blob,
                  entry_path.c_str(),
                  shader_target.c_str(),
                  local_shader_defines,
                  // Save to disk for faster loading after the first compilation
                  !prevent_shader_cache_saving,
                  error,
                  &custom_shader->compilation_errors,
                  trimmed_file_path_cso.c_str());
               ASSERT_ONCE(!trimmed_file_path_cso.empty()); // If we got here, this string should always be valid, as it means the shader read from disk was an hlsl

               // Ugly workaround to avoid providing the shader compiler a custom name for CSO files, given we trim their name from multiple hashes that the HLSL original path might have
               if (!prevent_shader_cache_saving && !original_file_path_cso.empty() && original_file_path_cso != trimmed_file_path_cso)
               {
                  if (std::filesystem::is_regular_file(original_file_path_cso))
                  {
                     ASSERT_ONCE(false); // This shouldn't happen anymore unless the shader was manually created or named
                     std::filesystem::remove(trimmed_file_path_cso);
                     std::filesystem::rename(original_file_path_cso, trimmed_file_path_cso);
                  }
               }

               if (!custom_shader->compilation_errors.empty())
               {
#if DEVELOPMENT || TEST
                  custom_shader->compilation_error = error;
#endif
#if !DEVELOPMENT && !TEST // Ignore warnings for public builds
                  if (error)
#endif
                  {
                     shaders_compilation_errors.append(filename_no_extension_string);
                     shaders_compilation_errors.append(": ");
                     shaders_compilation_errors.append(custom_shader->compilation_errors);
                  }
               }

               if (custom_shader->code.empty())
               {
                  std::stringstream s;
                  s << "LoadCustomShaders(Compilation failed: ";
                  s << entry_path.string();
                  s << ")";
                  reshade::log::message(reshade::log::level::warning, s.str().c_str());

                  continue;
               }
               // Save the matching the pre-compiled shader hash in the config, so we can skip re-compilation on the next boot
               else if (!prevent_shader_cache_saving)
               {
                  reshade::set_config_value(nullptr, NAME_ADVANCED_SETTINGS.c_str(), &config_name[0], custom_shader->preprocessed_hash);
               }

#if _DEBUG && LOG_VERBOSE
               {
                  std::stringstream s;
                  s << "LoadCustomShaders(Shader built with size: " << custom_shader->code.size() << ")";
                  reshade::log::message(reshade::log::level::debug, s.str().c_str());
               }
#endif
            }
            else if (is_cso)
            {
               try
               {
                  std::ifstream file;
                  file.exceptions(std::ifstream::failbit | std::ifstream::badbit);
                  file.open(entry_path, std::ios::binary);
                  file.seekg(0, std::ios::end);
                  custom_shader->code.resize(file.tellg());
#if _DEBUG && LOG_VERBOSE
                  {
                     std::stringstream s;
                     s << "LoadCustomShaders(Reading " << custom_shader->code.size() << " from " << filename_no_extension_string << ")";
                     reshade::log::message(reshade::log::level::debug, s.str().c_str());
                  }
#endif
                  if (!custom_shader->code.empty())
                  {
                     file.seekg(0, std::ios::beg);
                     file.read(reinterpret_cast<char*>(custom_shader->code.data()), custom_shader->code.size());
                  }
               }
               catch (const std::exception& e)
               {
               }
            }
         }
      }

      // TODO: theoretically if "prevent_shader_cache_saving" is true, we should clean all the shader hashes and defines from the config, though hopefully it's fine without
      if (pipelines_filter.empty() && !prevent_shader_cache_saving)
      {
         const std::shared_lock lock(s_mutex_shader_defines);
         // Only save after compiling, to make sure the config data aligns with the serialized compiled shaders data (blobs)
         ShaderDefineData::Save(shader_defines_data, NAME_ADVANCED_SETTINGS);
      }

      // Refresh the persistent custom shaders we have.
      if (optional_device_data)
      {
         CreateCustomDeviceShaders(*optional_device_data, changed_luma_native_shaders_names);
      }
   }

   // Optionally compiles all the shaders we have in our data folder and links them with the game rendering pipelines
   void LoadCustomShaders(DeviceData& device_data, const std::unordered_set<uint64_t>& pipelines_filter = std::unordered_set<uint64_t>(), bool recompile_shaders = true, bool immediate_unload = false)
   {
#if _DEBUG && LOG_VERBOSE
      reshade::log::message(reshade::log::level::info, "LoadCustomShaders()");
#endif

      if (recompile_shaders)
      {
         CompileCustomShaders(&device_data, false, pipelines_filter);
      }

      // We can, and should, only lock this after compiling new shaders (above)
      const std::unique_lock lock(s_mutex_generic);

      // Clear all previously loaded custom shaders
      UnloadCustomShaders(device_data, pipelines_filter, immediate_unload, false);

      std::unordered_set<uint64_t> cloned_pipelines;

      const std::unique_lock lock_loading(s_mutex_loading);
      for (const auto& custom_shader_pair : custom_shaders_cache)
      {
         uint32_t shader_hash = custom_shader_pair.first;
         const auto custom_shader = custom_shaders_cache[shader_hash];

         // Skip shaders that don't have code binaries at the moment, and luma native shaders as they aren't meant to replace game shaders
         if (custom_shader == nullptr || custom_shader->is_luma_native || custom_shader->code.empty()) continue;

         auto pipelines_pair = device_data.pipeline_caches_by_shader_hash.find(shader_hash);
         if (pipelines_pair == device_data.pipeline_caches_by_shader_hash.end())
         {
#if _DEBUG && LOG_VERBOSE
            // It's likely the game hasn't loaded this shader yet, or anyway we have shaders for multiple games in a mod etc
            std::stringstream s;
            s << "LoadCustomShaders(Unknown hash: ";
            s << PRINT_CRC32(shader_hash);
            s << ")";
            reshade::log::message(reshade::log::level::warning, s.str().c_str());
#endif
            continue;
         }

         // Re-clone all the pipelines that used this shader hash (except the ones that are filtered out)
         for (CachedPipeline* cached_pipeline : pipelines_pair->second)
         {
            if (cached_pipeline == nullptr) continue;
            if (!pipelines_filter.empty() && !pipelines_filter.contains(cached_pipeline->pipeline.handle)) continue;
            if (cloned_pipelines.contains(cached_pipeline->pipeline.handle)) { assert(false); continue; }
            cloned_pipelines.emplace(cached_pipeline->pipeline.handle);
            // Force destroy this pipeline in case it was already cloned
            UnloadCustomShaders(device_data, { cached_pipeline->pipeline.handle }, immediate_unload, false);

#if _DEBUG && LOG_VERBOSE
            {
               std::stringstream s;
               s << "LoadCustomShaders(Read ";
               s << custom_shader->code.size() << " bytes ";
               s << " from " << custom_shader->file_path.string();
               s << ")";
               reshade::log::message(reshade::log::level::debug, s.str().c_str());
            }
#endif

            // DX12 can use PSO objects that need to be cloned
            const uint32_t subobject_count = cached_pipeline->subobject_count;
            reshade::api::pipeline_subobject* subobjects = cached_pipeline->subobjects_cache;
            reshade::api::pipeline_subobject* new_subobjects = Shader::ClonePipelineSubobjects(subobject_count, subobjects);

#if _DEBUG && LOG_VERBOSE
            {
               std::stringstream s;
               s << "LoadCustomShaders(Cloning pipeline ";
               s << reinterpret_cast<void*>(cached_pipeline->pipeline.handle);
               s << " with " << subobject_count << " object(s)";
               s << ")";
               reshade::log::message(reshade::log::level::debug, s.str().c_str());
            }
            reshade::log::message(reshade::log::level::debug, "Iterating pipeline...");
#endif

            for (uint32_t i = 0; i < subobject_count; ++i)
            {
               const auto& subobject = subobjects[i];
               switch (subobject.type)
               {
               case reshade::api::pipeline_subobject_type::geometry_shader:
               case reshade::api::pipeline_subobject_type::vertex_shader:
               case reshade::api::pipeline_subobject_type::compute_shader:
               case reshade::api::pipeline_subobject_type::pixel_shader:
               break;
               default:
               continue;
               }

               auto& clone_subject = new_subobjects[i];

               auto* new_desc = static_cast<reshade::api::shader_desc*>(clone_subject.data);

               new_desc->code_size = custom_shader->code.size();
               new_desc->code = malloc(custom_shader->code.size());
               std::memcpy(const_cast<void*>(new_desc->code), custom_shader->code.data(), custom_shader->code.size());

#if _DEBUG && LOG_VERBOSE
               const auto new_hash = Shader::BinToHash(static_cast<const uint8_t*>(new_desc->code), new_desc->code_size);

               {
                  std::stringstream s;
                  s << "LoadCustomShaders(Injected pipeline data";
                  s << " with " << PRINT_CRC32(new_hash);
                  s << " (" << custom_shader->code.size() << " bytes)";
                  s << ")";
                  reshade::log::message(reshade::log::level::debug, s.str().c_str());
               }
#endif
            }

#if _DEBUG && LOG_VERBOSE
            {
               std::stringstream s;
               s << "Creating pipeline clone (";
               s << "hash: " << PRINT_CRC32(shader_hash);
               s << ", layout: " << reinterpret_cast<void*>(cached_pipeline->layout.handle);
               s << ", subobject_count: " << subobject_count;
               s << ")";
               reshade::log::message(reshade::log::level::debug, s.str().c_str());
            }
#endif

            reshade::api::pipeline pipeline_clone;
            const bool built_pipeline_ok = cached_pipeline->device->create_pipeline(
               cached_pipeline->layout,
               subobject_count,
               new_subobjects,
               &pipeline_clone);
#if !_DEBUG || !LOG_VERBOSE
            if (!built_pipeline_ok)
#endif
            {
               std::stringstream s;
               s << "LoadCustomShaders(Cloned ";
               s << reinterpret_cast<void*>(cached_pipeline->pipeline.handle);
               s << " => " << reinterpret_cast<void*>(pipeline_clone.handle);
               s << ", layout: " << reinterpret_cast<void*>(cached_pipeline->layout.handle);
               s << ", size: " << subobject_count;
               s << ", " << (built_pipeline_ok ? "OK" : "FAILED!");
               s << ")";
               reshade::log::message(built_pipeline_ok ? reshade::log::level::info : reshade::log::level::error, s.str().c_str());
            }

            if (built_pipeline_ok)
            {
               assert(!cached_pipeline->cloned && cached_pipeline->pipeline_clone.handle == 0);
               cached_pipeline->pipeline_clone = pipeline_clone;
               cached_pipeline->cloned = true;
               // TODO: make sure the pixel shaders have the same signature (through reflections) unless the vertex shader was also changed and has a different output signature? Just to make sure random hashes didn't end up replacing an accidentally equal hash (however unlikely)
               device_data.pipeline_cache_by_pipeline_clone_handle[pipeline_clone.handle] = cached_pipeline;
               device_data.cloned_pipeline_count++;
               device_data.cloned_pipelines_changed = true;
            }
            // Clean up unused cloned subobjects
            else
            {
               DestroyPipelineSubojects(new_subobjects, subobject_count);
               new_subobjects = nullptr;
            }
         }
      }
   }

   void OnDisplayModeChanged()
   {
      // s_mutex_reshade should already be locked here, it's not necessary anyway
      GetShaderDefineData(GAMMA_CORRECTION_TYPE_HASH).editable = cb_luma_global_settings.DisplayMode != 0; //TODOFT4: necessary to disable this in SDR?

      game->OnDisplayModeChanged();
   }

   bool OnCreateDevice(reshade::api::device_api api, uint32_t& api_version)
   {
      ASSERT_ONCE_MSG(api == reshade::api::device_api::d3d11, "Luma only supports DirectX 11 at the moment");

#if DEVELOPMENT && 0 // Test: force the latest version to access all the latest features (it doesn't seem to work!)
      api_version = D3D_FEATURE_LEVEL_12_2;
      return true;
#endif

#if ENABLE_FSR
      // Required by FSR 3 on DX11. Also goes to determine whether we have to use D3D11_1_UAV_SLOT_COUNT or (the older) D3D11_PS_CS_UAV_REGISTER_COUNT.
      // Some games (e.g. INSIDE) crashes with this.
      if (api_version == D3D_FEATURE_LEVEL_11_0)
      {
         api_version = D3D_FEATURE_LEVEL_11_1;
         return true;
      }
#endif

      return false;
   }

   void OnInitDevice(reshade::api::device* device)
   {
      ID3D11Device* native_device = (ID3D11Device*)(device->get_native());
      DeviceData& device_data = *device->create_private_data<DeviceData>();
      device_data.native_device = native_device;

      device_data.uav_max_count = (native_device->GetFeatureLevel() >= D3D_FEATURE_LEVEL_11_1) ? D3D11_1_UAV_SLOT_COUNT : D3D11_PS_CS_UAV_REGISTER_COUNT;

      native_device->GetImmediateContext(&device_data.primary_command_list);

      {
         const std::unique_lock lock(s_mutex_device);
         // Inherit a minimal set of states from the possible previous device. Any other state wouldn't be relevant or could be outdated, so we might as well reset all to default.
         if (!global_devices_data.empty())
         {
            device_data.output_resolution = global_devices_data[0]->output_resolution;
            device_data.render_resolution = global_devices_data[0]->render_resolution;
            device_data.previous_render_resolution = global_devices_data[0]->render_resolution;
         }
         // In case there already was a device, we could copy some states from it, but given that the previous device might still be rendering a frame and is in a "random" state, let's keep them completely independent
         global_native_devices.push_back(native_device);
         global_devices_data.push_back(&device_data);
      }

      game->OnCreateDevice(native_device, device_data);

      HRESULT hr;

      D3D11_BUFFER_DESC buffer_desc = {};
      // From MS docs: you must set the ByteWidth value of D3D11_BUFFER_DESC in multiples of 16, and less than or equal to D3D11_REQ_CONSTANT_BUFFER_ELEMENT_COUNT.
      buffer_desc.ByteWidth = sizeof(CB::LumaGlobalSettingsPadded);
      buffer_desc.Usage = D3D11_USAGE_DYNAMIC;
      buffer_desc.BindFlags = D3D11_BIND_CONSTANT_BUFFER;
      buffer_desc.CPUAccessFlags = D3D11_CPU_ACCESS_WRITE;
      D3D11_SUBRESOURCE_DATA data = {};
      {
         const std::unique_lock lock_reshade(s_mutex_reshade);
         data.pSysMem = &cb_luma_global_settings;
         hr = native_device->CreateBuffer(&buffer_desc, &data, &device_data.luma_global_settings);
         device_data.cb_luma_global_settings_dirty = false;
      }
      assert(SUCCEEDED(hr));
      if (luma_data_cbuffer_index < D3D11_COMMONSHADER_CONSTANT_BUFFER_API_SLOT_COUNT)
      {
         buffer_desc.ByteWidth = sizeof(CB::LumaInstanceDataPadded);
#if 1 // Start it with no specific data, we always write the data before bidning it to the GPU
         hr = native_device->CreateBuffer(&buffer_desc, nullptr, &device_data.luma_instance_data);
#else
         static CB::LumaInstanceDataPadded cb_luma_instance_data = {};
         data.pSysMem = &device_data.cb_luma_instance_data;
         hr = native_device->CreateBuffer(&buffer_desc, &data, &device_data.luma_instance_data);
#endif
         assert(SUCCEEDED(hr));
      }
      if (luma_ui_cbuffer_index < D3D11_COMMONSHADER_CONSTANT_BUFFER_API_SLOT_COUNT)
      {
         buffer_desc.ByteWidth = sizeof(CB::LumaUIDataPadded);
         data.pSysMem = &device_data.cb_luma_ui_data;
         hr = native_device->CreateBuffer(&buffer_desc, &data, &device_data.luma_ui_data);
         assert(SUCCEEDED(hr));
      }

      D3D11_SAMPLER_DESC sampler_desc = {};
      sampler_desc.Filter = D3D11_FILTER_MIN_MAG_MIP_LINEAR; // Bilinear filtering
      sampler_desc.AddressU = D3D11_TEXTURE_ADDRESS_CLAMP; // Clamp by default (though returning black would also be good?)
      sampler_desc.AddressV = D3D11_TEXTURE_ADDRESS_CLAMP;
      sampler_desc.AddressW = D3D11_TEXTURE_ADDRESS_CLAMP;
      sampler_desc.MipLODBias = 0.f;
      sampler_desc.MaxAnisotropy = 1;
      sampler_desc.ComparisonFunc = D3D11_COMPARISON_ALWAYS;
      sampler_desc.MinLOD = 0.f;
      sampler_desc.MaxLOD = D3D11_FLOAT32_MAX;
      hr = native_device->CreateSamplerState(&sampler_desc, &device_data.default_sampler_state);
      assert(SUCCEEDED(hr));

      D3D11_BLEND_DESC blend_desc = {};
      blend_desc.AlphaToCoverageEnable = FALSE;
      blend_desc.IndependentBlendEnable = FALSE;
      // We only need RT 0
      blend_desc.RenderTarget[0].BlendEnable = FALSE;
      blend_desc.RenderTarget[0].SrcBlend = D3D11_BLEND_ONE;
      blend_desc.RenderTarget[0].DestBlend = D3D11_BLEND_ZERO;
      blend_desc.RenderTarget[0].BlendOp = D3D11_BLEND_OP_ADD;
      blend_desc.RenderTarget[0].SrcBlendAlpha = D3D11_BLEND_ONE;
      blend_desc.RenderTarget[0].DestBlendAlpha = D3D11_BLEND_ZERO;
      blend_desc.RenderTarget[0].BlendOpAlpha = D3D11_BLEND_OP_ADD;
      blend_desc.RenderTarget[0].RenderTargetWriteMask = D3D11_COLOR_WRITE_ENABLE_ALL;
      hr = native_device->CreateBlendState(&blend_desc, &device_data.default_blend_state);
      assert(SUCCEEDED(hr));

      D3D11_DEPTH_STENCIL_DESC depth_stencil_desc = {};
      depth_stencil_desc.DepthEnable = false;
      depth_stencil_desc.StencilEnable = false;
      hr = native_device->CreateDepthStencilState(&depth_stencil_desc, &device_data.default_depth_stencil_state);
      assert(SUCCEEDED(hr));

#if ENABLE_NVAPI
      Display::InitNVApi();
#endif

#if ENABLE_NGX
      com_ptr<IDXGIDevice> native_dxgi_device;
      hr = native_device->QueryInterface(&native_dxgi_device);
      com_ptr<IDXGIAdapter> native_adapter;
      if (SUCCEEDED(hr))
      {
         hr = native_dxgi_device->GetAdapter(&native_adapter);
      }
      assert(SUCCEEDED(hr));

      // Inherit the default from the global user setting
      {
         const std::unique_lock lock_reshade(s_mutex_reshade);
         device_data.dlss_sr = dlss_sr;
      }
      // We always do this, which will force the DLSS dll to load, but it should be fast enough to not bother users from other vendors
      device_data.dlss_sr_supported = NGX::DLSS::Init(device_data.dlss_sr_handle, native_device, native_adapter.get());
      if (!device_data.dlss_sr_supported)
      {
         NGX::DLSS::Deinit(device_data.dlss_sr_handle, native_device); // No need to keep it initialized if it's not supported
         device_data.dlss_sr = false; // No need to serialize this to config really
         const std::unique_lock lock_reshade(s_mutex_reshade);
         dlss_sr = false; // Disable the global user setting if it's not supported (it's ok even if we pollute device and global data), we want to grey it out in the UI (there's no need to serialize the new value for it though!)
      }
#else
      device_data.dlss_sr = false;
      dlss_sr = false;
#endif // ENABLE_NGX

      game->OnInitDevice(native_device, device_data);

      // If we upgrade textures, make sure that MSAA DXGI_FORMAT_R16G16B16A16_FLOAT is supported on our GPU, given that it's optional.
      // Most games don't have MSAA, but it might be enforced at driver level.
      if (enable_texture_format_upgrades)
      {
         UINT quality_levels = 0;
         HRESULT hr;
         // We could go up to "D3D11_MAX_MULTISAMPLE_SAMPLE_COUNT" but realistically no game ever does more than 8x (and odd values are not supported)
         hr = native_device->CheckMultisampleQualityLevels(DXGI_FORMAT_R16G16B16A16_FLOAT, 2, &quality_levels);
         ASSERT_ONCE(SUCCEEDED(hr) && quality_levels > 0);
         hr = native_device->CheckMultisampleQualityLevels(DXGI_FORMAT_R16G16B16A16_FLOAT, 4, &quality_levels);
         ASSERT_ONCE(SUCCEEDED(hr) && quality_levels > 0);
         hr = native_device->CheckMultisampleQualityLevels(DXGI_FORMAT_R16G16B16A16_FLOAT, 8, &quality_levels);
         ASSERT_ONCE(SUCCEEDED(hr) && quality_levels > 0);
      }

      // If all custom shaders from boot already loaded/compiled, but the custom device shaders weren't created, create them
      if (precompile_custom_shaders && block_draw_until_device_custom_shaders_creation)
      {
         const std::unique_lock lock_loading(s_mutex_loading);
         const std::unique_lock lock_shader_objects(s_mutex_shader_objects);
         if (!thread_auto_compiling_running && !device_data.created_custom_shaders)
         {
            CreateCustomDeviceShaders(device_data, std::nullopt, false);
         }
      }
   }

   void OnDestroyDevice(reshade::api::device* device)
   {
      ID3D11Device* native_device = (ID3D11Device*)(device->get_native());
      DeviceData& device_data = *device->get_private_data<DeviceData>(); // No need to lock the data mutex here, it could be concurrently used at this point

      game->OnDestroyDeviceData(device_data);

      {
         const std::unique_lock lock(s_mutex_device);
         if (std::vector<ID3D11Device*>::iterator position = std::find(global_native_devices.begin(), global_native_devices.end(), native_device); position != global_native_devices.end())
         {
            global_native_devices.erase(position);
         }
         else
         {
            ASSERT_ONCE(false);
         }
         if (std::vector<DeviceData*>::iterator position = std::find(global_devices_data.begin(), global_devices_data.end(), &device_data); position != global_devices_data.end())
         {
            global_devices_data.erase(position);
         }
         else
         {
            ASSERT_ONCE(false);
         }
      }

      ASSERT_ONCE(device_data.swapchains.empty()); // Hopefully this is forcefully garbage collected when the device is destroyed (it is!)

      if (device_data.thread_auto_loading.joinable())
      {
         device_data.thread_auto_loading.join();
         device_data.thread_auto_loading_running = false;
      }

      assert(device_data.cb_per_view_global_buffer_map_data == nullptr); // It's fine (but not great) if we map wasn't unmapped before destruction (not our fault anyway)

      {
         const std::unique_lock lock_samplers(s_mutex_samplers);
         ASSERT_ONCE(device_data.custom_sampler_by_original_sampler.empty()); // These should be guaranteed to have been cleared already ("OnDestroySampler()")
         device_data.custom_sampler_by_original_sampler.clear();
      }

#if ENABLE_NGX
      NGX::DLSS::Deinit(device_data.dlss_sr_handle, native_device); // NOTE: this could stutter the game on closure as it forces unloading the DLSS DLL (if it's the last device instance?), but we can't avoid it
#endif // ENABLE_NGX

      device->destroy_private_data<DeviceData>();
   }

#if DEVELOPMENT
   // Prevent games from pausing when alt tabbing out of it (e.g. when editing shaders) by silencing focus loss events
   LRESULT WINAPI CustomWndProc(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam)
   {
      if (lParam == WM_KILLFOCUS)
      {
         // Lost keyboard focus
         return 0; // block it
      }
      else if (lParam == WM_ACTIVATE)
      {
         if (wParam == WA_INACTIVE)
         {
            // Lost foreground activation
            return 0; // block it
         }
      }
      return CallWindowProc(game_window_original_proc, hWnd, msg, wParam, lParam);
   }
   LRESULT CALLBACK CallWndProc(int nCode, WPARAM wParam, LPARAM lParam)
   {
      if (nCode >= 0)
      {
         CWPSTRUCT* pCwp = (CWPSTRUCT*)lParam;
         if (pCwp->message == WM_KILLFOCUS)
         {
            // Lost keyboard focus
            return 1; // block it
         }
         else if (pCwp->message == WM_ACTIVATE)
         {
            if (LOWORD(pCwp->wParam) == WA_INACTIVE)
            {
               // Lost foreground activation
               return 1; // block it
				}
         }
      }
      return CallNextHookEx(NULL, nCode, wParam, lParam);
   }
#endif

   bool OnCreateSwapchain(reshade::api::device_api api, reshade::api::swapchain_desc& desc, void* hwnd)
   {
      // There's only one swapchain so it's fine if this is global ("OnInitSwapchain()" will always be called later anyway)
      bool changed = false;

#if DEVELOPMENT
      ASSERT_ONCE(desc.back_buffer.texture.format != reshade::api::format::unknown); // With the latest ReShade changes, this should never be set to Unknown, even if the game did a swapchain buffer resize and preserved the previous format.
      last_attempted_upgraded_resource_creation_format = desc.back_buffer.texture.format;
#endif

      // sRGB formats don't support flip modes, if we previously upgraded the swapchain, select a flip mode compatible format when the swapchain resizes, as we can't change it anymore after creation
      if (!enable_swapchain_upgrade && swapchain_upgrade_type > 0 && (desc.back_buffer.texture.format == reshade::api::format::r8g8b8a8_unorm_srgb || desc.back_buffer.texture.format == reshade::api::format::b8g8r8a8_unorm_srgb))
      {
         if (desc.back_buffer.texture.format == reshade::api::format::r8g8b8a8_unorm_srgb)
            desc.back_buffer.texture.format = reshade::api::format::r8g8b8a8_unorm;
         else
            desc.back_buffer.texture.format = reshade::api::format::b8g8r8a8_unorm;
         changed = true;
      }

      // TODO: add a flag to disable these for the "GRAPHICS_ANALYZER"? They are still needed for HDR though
      // Generally we want to add these flags in all cases, they seem to work in all games
      {
         desc.back_buffer_count = max(desc.back_buffer_count, 2); // Needed by flip models, which is mandatory for HDR (for some reason DX11 might still create one buffer). Note that DX10/11 will still only create one buffer, even if their desc says they have two.
         if ((enable_swapchain_upgrade && swapchain_upgrade_type > 0) || (desc.back_buffer.texture.format != reshade::api::format::r8g8b8a8_unorm_srgb && desc.back_buffer.texture.format != reshade::api::format::b8g8r8a8_unorm_srgb)) // sRGB formats don't support flip modes
         {
            desc.present_mode = DXGI_SWAP_EFFECT_FLIP_DISCARD;
         }
         ASSERT_ONCE((desc.present_flags & (DXGI_SWAP_CHAIN_FLAG_FRAME_LATENCY_WAITABLE_OBJECT | DXGI_SWAP_CHAIN_FLAG_FULLSCREEN_VIDEO)) == 0); // Uh?
#if DEVELOPMENT && !GRAPHICS_ANALYZER // TODO: investigate "DXGI_SWAP_CHAIN_FLAG_FRAME_LATENCY_WAITABLE_OBJECT" (add this to other mirrored code if you finalize it), and anyway make it optional as it lowers lag at the cost of not quequing up frames
         desc.present_flags |= DXGI_SWAP_CHAIN_FLAG_FRAME_LATENCY_WAITABLE_OBJECT;
#endif
         desc.present_flags |= DXGI_SWAP_CHAIN_FLAG_ALLOW_TEARING; // Games will still need to call "Present()" with the tearing flag enabled for this to do anything
         desc.present_flags |= DXGI_SWAP_CHAIN_FLAG_ALLOW_MODE_SWITCH;
         desc.fullscreen_refresh_rate = 0.f; // This fixes games forcing a specific refresh rate (e.g. Mafia III forces 60Hz for no reason)
         desc.fullscreen_state = false; // Force disable FSE (see "OnSetFullscreenState()")
         changed = true;
      }

      // Note that occasionally this breaks after resizing the swapchain, because some games resize the swapchain maintaining whatever format it had before
      last_swapchain_linear_space = desc.back_buffer.texture.format == reshade::api::format::r8g8b8a8_unorm_srgb || desc.back_buffer.texture.format == reshade::api::format::b8g8r8a8_unorm_srgb || desc.back_buffer.texture.format == reshade::api::format::r16g16b16a16_float;

      if (enable_swapchain_upgrade && swapchain_upgrade_type > 0)
      {
         ASSERT_ONCE(desc.back_buffer.texture.format == reshade::api::format::r10g10b10a2_unorm || desc.back_buffer.texture.format == reshade::api::format::r8g8b8a8_unorm || desc.back_buffer.texture.format == reshade::api::format::r8g8b8a8_unorm_srgb || desc.back_buffer.texture.format == reshade::api::format::r16g16b16a16_float); // Just a bounch of formats we encountered and we are sure we can upgrade (or that have already been upgraded)
         // DXGI_FORMAT_R16G16B16A16_FLOAT will automatically pick DXGI_COLOR_SPACE_RGB_FULL_G10_NONE_P709 on first creation
         desc.back_buffer.texture.format = reshade::api::format::r16g16b16a16_float;
         changed = true;
      }

      return changed;
   }

   void OnInitSwapchain(reshade::api::swapchain* swapchain, bool resize)
   {
      IDXGISwapChain* native_swapchain = (IDXGISwapChain*)(swapchain->get_native());
#if 0
      DXGI_SWAP_CHAIN_DESC desc;
      native_swapchain->GetDesc(&desc);
      const size_t back_buffer_count = desc.BufferCount;
#else // Always 1 on DX10/11, even if the swapchain desc says 2...
      const size_t back_buffer_count = swapchain->get_back_buffer_count();
#endif
      auto* device = swapchain->get_device();
      ID3D11Device* native_device = (ID3D11Device*)(device->get_native());
      DeviceData& device_data = *device->get_private_data<DeviceData>();
      SwapchainData& swapchain_data = *swapchain->create_private_data<SwapchainData>();
      ASSERT_ONCE(&device_data != nullptr); // Hacky nullptr check (should ever be able to happen)

#if DEVELOPMENT
      const reshade::api::resource_desc resource_desc = device->get_resource_desc(swapchain->get_back_buffer(0));
      if (last_attempted_upgraded_resource_creation_format != resource_desc.texture.format) // Upgraded
      {
         const std::unique_lock lock(device_data.mutex);
         for (uint32_t index = 0; index < back_buffer_count; index++)
         {
            device_data.original_upgraded_resources_formats[swapchain->get_back_buffer(index).handle] = last_attempted_upgraded_resource_creation_format;
         }
      }
#endif

      swapchain_data.vanilla_was_linear_space = last_swapchain_linear_space || game->ForceVanillaSwapchainLinear();
#if !GAME_MAFIA_III // We don't care for this case, it's dev only, if we didn't do this, when we unload shaders the game would be washed out (the UI still is)
      // We expect this define to be set to linear if the swapchain was already linear in Vanilla SDR (there might be code that makes such assumption)
      ASSERT_ONCE(!swapchain_data.vanilla_was_linear_space || (GetShaderDefineCompiledNumericalValue(POST_PROCESS_SPACE_TYPE_HASH) == 1));
#endif

      {
         const std::unique_lock lock(swapchain_data.mutex); // Not much need to lock this on its own creation, but let's do it anyway...
         for (uint32_t index = 0; index < back_buffer_count; index++)
         {
            auto buffer = swapchain->get_back_buffer(index);
            swapchain_data.back_buffers.emplace(buffer.handle);
            swapchain_data.display_composition_rtvs.push_back(nullptr);
         }
      }

      {
         const std::unique_lock lock(device_data.mutex);
         device_data.swapchains.emplace(swapchain);
         ASSERT_ONCE(SUCCEEDED(device_data.swapchains.size() == 1)); // Having more than one swapchain per device is probably supported but unexpected

         for (uint32_t index = 0; index < back_buffer_count; index++)
         {
            auto buffer = swapchain->get_back_buffer(index);
            device_data.back_buffers.emplace(buffer.handle);
         }
      }

      // We assume there's only one swapchain (there is!), given that the resolution would theoretically be by swapchain and not device.
      // If the game created more than one, the previous one is likely discared and not garbage collected yet.
      // If any games broke these assumptions, we could refine this design.
      DXGI_SWAP_CHAIN_DESC swapchain_desc;
      HRESULT hr = native_swapchain->GetDesc(&swapchain_desc);
      ASSERT_ONCE(SUCCEEDED(hr));
      if (SUCCEEDED(hr))
      {
         ASSERT_ONCE_MSG(swapchain_desc.SampleDesc.Count == 1, "MSAA is unexpectedly enabled on the Swapchain, Luma might not be compatible with it");
         device_data.output_resolution.x = swapchain_desc.BufferDesc.Width;
         device_data.output_resolution.y = swapchain_desc.BufferDesc.Height;
         device_data.render_resolution.x = device_data.output_resolution.x;
         device_data.render_resolution.y = device_data.output_resolution.y;
      }

		device_data.ui_texture = nullptr;
      device_data.ui_texture_rtv = nullptr;
      device_data.ui_texture_srv = nullptr;
      // At the moment this is just created when the swapchain changes anything about it,
      // so we don't support changing this shader define live, but if needed, we could always move these allocations
      if (GetShaderDefineCompiledNumericalValue(UI_DRAW_TYPE_HASH) >= 3)
      {
         device_data.ui_texture = CloneTexture<ID3D11Texture2D>(native_device, (ID3D11Texture2D*)swapchain->get_back_buffer(0).handle, ui_separation_format, D3D11_BIND_SHADER_RESOURCE | D3D11_BIND_RENDER_TARGET, 0, true, false, nullptr);
         native_device->CreateRenderTargetView(device_data.ui_texture.get(), nullptr, &device_data.ui_texture_rtv);
         native_device->CreateShaderResourceView(device_data.ui_texture.get(), nullptr, &device_data.ui_texture_srv);
      }

      IDXGISwapChain3* native_swapchain3;
      // The cast pointer is actually the same, we are just making sure the type is right.
      hr = native_swapchain->QueryInterface(&native_swapchain3);
      ASSERT_ONCE(SUCCEEDED(hr)); // This is required by LUMA, but all systems should have this swapchain by now

      // This is basically where we verify and update the user display settings
      if (native_swapchain3 != nullptr)
      {
         const std::unique_lock lock_reshade(s_mutex_reshade);
         Display::GetHDRMaxLuminance(native_swapchain3, device_data.default_user_peak_white, srgb_white_level);
         Display::IsHDRSupportedAndEnabled(swapchain_desc.OutputWindow, hdr_supported_display, hdr_enabled_display, native_swapchain3);
         const bool window_changed = game_window != swapchain_desc.OutputWindow;
         if (window_changed)
         {
            game_window = swapchain_desc.OutputWindow; // This shouldn't really need any thread safety protection
#if DEVELOPMENT //TODOFT: test/fix/finish
            if (game_window)
            {
#if 1
               WNDPROC game_window_proc = reinterpret_cast<WNDPROC>(GetWindowLongPtr(game_window, GWLP_WNDPROC));
               if (game_window_proc != game_window_custom_proc)
               {
                  game_window_original_proc = game_window_proc;
                  ASSERT_ONCE(game_window_original_proc != nullptr);
                  WNDPROC game_window_prev_proc = reinterpret_cast<WNDPROC>(SetWindowLongPtr(game_window, GWLP_WNDPROC, reinterpret_cast<LONG_PTR>(CustomWndProc)));
                  ASSERT_ONCE(game_window_prev_proc == game_window_proc); // The above returns the ptr before replacement
                  game_window_custom_proc = reinterpret_cast<WNDPROC>(GetWindowLongPtr(game_window, GWLP_WNDPROC));
               }
#else
               if (!game_window_proc_hook)
               {
                  DWORD threadId = GetWindowThreadProcessId(game_window, NULL);
                  game_window_proc_hook = SetWindowsHookEx(WH_CALLWNDPROC, CallWndProc, NULL, threadId);
                  ASSERT_ONCE(game_window_proc_hook);
               }
#endif
            }
            else
            {
               game_window_custom_proc = nullptr;
               if (game_window_proc_hook)
               {
                  UnhookWindowsHookEx(game_window_proc_hook);
                  game_window_proc_hook = nullptr;
               }
            }
#endif // DEVELOPMENT
         }

#if GAME_BIOSHOCK_2 //TODOFT6 (does this make the game stutter like crazy?)
         // Force borderless window:
         int screen_width = GetSystemMetrics(SM_CXSCREEN);
         int screen_height = GetSystemMetrics(SM_CYSCREEN);
         // Calculate centered position
         int x_pos = (screen_width - swapchain_desc.BufferDesc.Width) / 2;
         int y_yos = (screen_height - swapchain_desc.BufferDesc.Height) / 2;

         auto style = GetWindowLong(game_window, GWL_STYLE);
         style |= WS_POPUP;
         SetWindowLong(game_window, GWL_STYLE, style);

         SetWindowPos(game_window, NULL, x_pos, y_yos, swapchain_desc.BufferDesc.Width, swapchain_desc.BufferDesc.Height, SWP_FRAMECHANGED | SWP_NOSIZE | SWP_NOZORDER);
#endif

#if GAME_BIOSHOCK_2 && 0 //TODOFT6: probably not necessary. Move it to a func and BS2 code.
         com_ptr<IDXGIOutput> output;
         native_swapchain->GetContainingOutput(&output);
         output->SetGammaControl(nullptr);
#endif

         if (!hdr_enabled_display)
         {
            // Force the display mode to SDR if HDR is not engaged
            cb_luma_global_settings.DisplayMode = 0;
            OnDisplayModeChanged();
            cb_luma_global_settings.ScenePeakWhite = srgb_white_level;
            cb_luma_global_settings.ScenePaperWhite = srgb_white_level;
            cb_luma_global_settings.UIPaperWhite = srgb_white_level;
         }
         // Avoid increasing the peak if the user has SDR mode set, SDR mode might still rely on the peak white value
         else if (cb_luma_global_settings.DisplayMode > 0 && cb_luma_global_settings.DisplayMode < 2)
         {
            cb_luma_global_settings.ScenePeakWhite = device_data.default_user_peak_white;
         }
         device_data.cb_luma_global_settings_dirty = true;

         if (enable_swapchain_upgrade && swapchain_upgrade_type > 0)
         {
#if 0 // Not needed until proven otherwise (we already upgrade in "OnCreateSwapchain()", which should always be called when resizing the swapchain too)

            UINT flags = DXGI_SWAP_CHAIN_FLAG_ALLOW_MODE_SWITCH | DXGI_SWAP_CHAIN_FLAG_ALLOW_TEARING;
            DXGI_FORMAT format = DXGI_FORMAT_R16G16B16A16_FLOAT;
            hr = native_swapchain3->ResizeBuffers(0, 0, 0, format, flags); // Pass in zero to not change any values if not the format
            ASSERT_ONCE(SUCCEEDED(hr));
#endif
         }

#if !GAME_PREY && DEVELOPMENT
         DXGI_COLOR_SPACE_TYPE colorSpace;
			// TODO: allow detection of the color space based on the format? Will this succeed if called before or after resizing buffers? Add HDR10 support... For now we only do this in development as that's the only case where you can change the swapchain upgrades type live
         colorSpace = (enable_swapchain_upgrade && swapchain_upgrade_type > 0) ? DXGI_COLOR_SPACE_RGB_FULL_G10_NONE_P709 : DXGI_COLOR_SPACE_RGB_FULL_G22_NONE_P709;
         hr = native_swapchain3->SetColorSpace1(colorSpace);
         ASSERT_ONCE(SUCCEEDED(hr));
#endif

         // We release the resource because the swapchain lifespan is, and should be, controlled by the game.
         // We already have "OnDestroySwapchain()" to handle its destruction.
         native_swapchain3->Release();
      }

      static std::atomic<bool> warning_sent;
      if (device_data.output_resolution.x == device_data.output_resolution.y && enable_texture_format_upgrades && ((texture_format_upgrades_2d_size_filters & (uint32_t)TextureFormatUpgrades2DSizeFilters::SwapchainAspectRatio) != 0) && !warning_sent.exchange(true))
      {
         MessageBoxA(game_window, "Your current game output resolution has an aspect ratio of 1:1 (a squared resolution), that might cause issues with texture upgrades by aspect ratio, given that shadow maps and other things are often rendered in squared textures.", NAME, MB_SETFOREGROUND);
      }

#if ENABLE_NVAPI // TODO: finish this... Make it optional, feed the game metadata (peak brightness, color gamut etc)
      Display::EnableHdr10PlusDisplayOutput(game_window);
#endif

      game->OnInitSwapchain(swapchain);
   }

   void OnDestroySwapchain(reshade::api::swapchain* swapchain, bool resize)
   {
      auto* device = swapchain->get_device();
      DeviceData& device_data = *device->get_private_data<DeviceData>();
      ASSERT_ONCE(&device_data != nullptr); // Hacky nullptr check (should ever be able to happen)
      SwapchainData& swapchain_data = *swapchain->get_private_data<SwapchainData>();
      {
         {
            const std::unique_lock lock(device_data.mutex);
            device_data.swapchains.erase(swapchain);
            for (const uint64_t handle : swapchain_data.back_buffers)
            {
               device_data.back_buffers.erase(handle);
#if DEVELOPMENT
               device_data.original_upgraded_resources_formats.erase(handle);
#endif // DEVELOPMENT
            }
         }

         // Before resizing the swapchain, we need to make sure any of its resources/views are not bound to any state
         if (resize && !swapchain_data.display_composition_rtvs.empty())
         {
            ID3D11Device* native_device = (ID3D11Device*)(device->get_native());
            com_ptr<ID3D11RenderTargetView> rtvs[D3D11_SIMULTANEOUS_RENDER_TARGET_COUNT];
            com_ptr<ID3D11DepthStencilView> depth_stencil_view;
            device_data.primary_command_list->OMGetRenderTargets(D3D11_SIMULTANEOUS_RENDER_TARGET_COUNT, &rtvs[0], &depth_stencil_view);
            bool rts_changed = false;
            for (size_t i = 0; i < D3D11_SIMULTANEOUS_RENDER_TARGET_COUNT; i++)
            {
               for (const auto& display_composition_rtv : swapchain_data.display_composition_rtvs)
               {
                  if (rtvs[i].get() != nullptr && rtvs[i].get() == display_composition_rtv.get())
                  {
                     rtvs[i] = nullptr;
                     rts_changed = true;
                  }
               }
            }
            if (rts_changed)
            {
               ID3D11RenderTargetView* const* rtvs_const = (ID3D11RenderTargetView**)std::addressof(rtvs[0]);
               device_data.primary_command_list->OMSetRenderTargets(D3D11_SIMULTANEOUS_RENDER_TARGET_COUNT, rtvs_const, depth_stencil_view.get());
            }
         }
      }

      swapchain->destroy_private_data<SwapchainData>();
   }

   bool OnSetFullscreenState(reshade::api::swapchain* swapchain, bool fullscreen, void* hmonitor)
   {
      // Center the window in case it stayed where it was
      if (fullscreen && prevent_fullscreen_state) // TODO: test with Mafia 3 and BS2 if actually needed
      {
         HMONITOR hMonitor = MonitorFromWindow(game_window, MONITOR_DEFAULTTONEAREST);

         MONITORINFO mi = {};
         mi.cbSize = sizeof(mi);
         if (GetMonitorInfo(hMonitor, &mi))
         {
            RECT rcMonitor = mi.rcWork; // work area (excludes taskbar)
            int screenW = rcMonitor.right - rcMonitor.left;
            int screenH = rcMonitor.bottom - rcMonitor.top;

            // Get current window rectangle
            RECT rcWindow;
            GetWindowRect(game_window, &rcWindow);
            int winW = rcWindow.right - rcWindow.left;
            int winH = rcWindow.bottom - rcWindow.top;

            int x = rcMonitor.left + (screenW - winW) / 2;
            int y = rcMonitor.top + (screenH - winH) / 2;

            SetWindowPos(game_window, nullptr, x, y, 0, 0, SWP_NOSIZE | SWP_NOZORDER | SWP_NOACTIVATE);
         }
      }
      // TODO: keep track of FS state
      return prevent_fullscreen_state;
   }

   void OnInitCommandList(reshade::api::command_list* cmd_list)
   {
      CommandListData& cmd_list_data = *cmd_list->create_private_data<CommandListData>();

      com_ptr<ID3D11DeviceContext> native_device_context;
      ID3D11DeviceChild* device_child = (ID3D11DeviceChild*)(cmd_list->get_native());
      HRESULT hr = device_child->QueryInterface(&native_device_context);
      if (SUCCEEDED(hr) && native_device_context)
      {
         DeviceData& device_data = *cmd_list->get_device()->get_private_data<DeviceData>();
         if (native_device_context->GetType() == D3D11_DEVICE_CONTEXT_IMMEDIATE)
         {
            ASSERT_ONCE(!device_data.primary_command_list_data); // There should never be more than one of these?
            ASSERT_ONCE(device_data.primary_command_list == reinterpret_cast<ID3D11DeviceContext*>(cmd_list->get_native()));
            device_data.primary_command_list_data = &cmd_list_data;
            cmd_list_data.is_primary = true;
         }
         else
         {
            cmd_list_data.is_primary = true;
         }
      }
      else
      {
         ASSERT_ONCE(false);
      }
#if DEVELOPMENT
      cmd_list_data.trace_draw_calls_data.reserve(5000); // Pre-allocate to make it after
#endif
   }

   void OnDestroyCommandList(reshade::api::command_list* cmd_list)
   {
      cmd_list->destroy_private_data<CommandListData>();
   }

#pragma optimize("t", on) // Temporarily override optimization, this function is too slow in debug otherwise (comment this out if ever needed)
   void OnInitPipeline(
      reshade::api::device* device,
      reshade::api::pipeline_layout layout,
      uint32_t subobject_count,
      const reshade::api::pipeline_subobject* subobjects,
      reshade::api::pipeline pipeline)
   {
      // In DX11 each pipeline should only have one subobject (e.g. a shader)
      for (uint32_t i = 0; i < subobject_count; ++i)
      {
         const auto& subobject = subobjects[i];
         for (uint32_t j = 0; j < subobject.count; ++j)
         {
            switch (subobject.type)
            {
#if GEOMETRY_SHADER_SUPPORT // Simply skipping cloning geom shaders pipelines is enough to stop the whole functionality (and the only place that is performance relevant)
            case reshade::api::pipeline_subobject_type::geometry_shader:
#endif // GEOMETRY_SHADER_SUPPORT
            case reshade::api::pipeline_subobject_type::vertex_shader:
            case reshade::api::pipeline_subobject_type::compute_shader:
            case reshade::api::pipeline_subobject_type::pixel_shader:
            {
#if DX12
               ASSERT_ONCE(subobject_count == 1);
#endif
               ASSERT_ONCE(subobject.count == 1);
               break;
            }
            default:
            {
               return; // Nothing to do here, we don't want to clone the pipeline
            }
            }
         }
      }

      reshade::api::pipeline_subobject* subobjects_cache = Shader::ClonePipelineSubobjects(subobject_count, subobjects);

      auto* cached_pipeline = new CachedPipeline{
          pipeline,
          device,
          layout,
          subobjects_cache
#if DX12
          , subobject_count
#endif
      };

      bool found_replaceable_shader = false;
      bool found_custom_shader_file = false;

      DeviceData& device_data = *device->get_private_data<DeviceData>();

      const std::unique_lock lock(s_mutex_generic);
      for (uint32_t i = 0; i < subobject_count; ++i)
      {
         const auto& subobject = subobjects[i];
         for (uint32_t j = 0; j < subobject.count; ++j)
         {
            switch (subobject.type)
            {
#if GEOMETRY_SHADER_SUPPORT
            case reshade::api::pipeline_subobject_type::geometry_shader:
#endif // GEOMETRY_SHADER_SUPPORT
            case reshade::api::pipeline_subobject_type::vertex_shader:
            case reshade::api::pipeline_subobject_type::compute_shader:
            case reshade::api::pipeline_subobject_type::pixel_shader:
            {
               auto* new_desc = static_cast<reshade::api::shader_desc*>(subobjects_cache[i].data);
               ASSERT_ONCE(new_desc->code_size > 0);
               if (new_desc->code_size == 0) break;
               found_replaceable_shader = true;

               // TODO: this isn't possible in DX11 but we should check if the shader has any private data and clone that too?

               auto shader_hash = Shader::BinToHash(static_cast<const uint8_t*>(new_desc->code), new_desc->code_size);

#if ALLOW_SHADERS_DUMPING || DEVELOPMENT
               {
                  const std::unique_lock lock_dumping(s_mutex_dumping); // Note: this isn't optimized, we should only lock it white reading/writing the dump data, not disassembling (?)

                  constexpr bool keep_duplicate_cached_shaders = true;

                  CachedShader* cached_shader = nullptr;
                  bool found_reflections = false;

                  // Optionally delete any previous shader with the same hash (unlikely to happen, as games usually compile the same shader binary once, but safer nonetheless, especially because sometimes two permutations of the same shader might have the same result)
                  if (auto previous_shader_pair = shader_cache.find(shader_hash); previous_shader_pair != shader_cache.end() && previous_shader_pair->second != nullptr)
                  {
                     auto& previous_shader = previous_shader_pair->second;
                     // Make sure that two shaders have the same hash, their code size also matches (theoretically we could check even more, but the chances hashes overlapping is extremely small)
                     assert(previous_shader->size == new_desc->code_size);
                     if (!keep_duplicate_cached_shaders)
                     {
#if DEVELOPMENT
                        shader_cache_count--;
#endif // DEVELOPMENT
                        delete previous_shader; // This should already de-allocate the internally allocated data
                     }
                     else
                     {
                        cached_shader = previous_shader;
                        found_reflections = true; // We already did the reflections procedure (whether it failed or not)
                     }
                  }

                  if (!cached_shader)
                  {
                     cached_shader = new CachedShader{ malloc(new_desc->code_size), new_desc->code_size, subobject.type };
                     std::memcpy(cached_shader->data, new_desc->code, cached_shader->size);

#if DEVELOPMENT
                     shader_cache_count++;
#endif // DEVELOPMENT
                     shader_cache[shader_hash] = cached_shader;
#if ALLOW_SHADERS_DUMPING
                     shaders_to_dump.emplace(shader_hash);
#endif // ALLOW_SHADERS_DUMPING
                  }

                  // Try with native DX11 reflections first, they are much faster than disassembly
                  if (!found_reflections)
                  {
                     // TODO: move declarations to shader compiler filer
                     typedef HRESULT(WINAPI* pD3DReflect)(LPCVOID, SIZE_T, REFIID, void**);
                     typedef HRESULT(WINAPI* pD3DGetBlobPart)(LPCVOID, SIZE_T, D3D_BLOB_PART, UINT, ID3DBlob**);
                     static HMODULE d3d_compiler;
                     static pD3DReflect d3d_reflect;
                     static pD3DGetBlobPart d3d_get_blob_part;
                     static std::mutex mutex_shader_compiler;
                     {
                        const std::lock_guard<std::mutex> lock(mutex_shader_compiler);
                        if (d3d_compiler == nullptr)
                        {
                           d3d_compiler = LoadLibraryW((System::GetSystemPath() / L"d3dcompiler_47.dll").c_str());
                        }
                        if (d3d_compiler != nullptr && d3d_reflect == nullptr)
                        {
                           d3d_reflect = pD3DReflect(GetProcAddress(d3d_compiler, "D3DReflect"));
                           d3d_get_blob_part = pD3DGetBlobPart(GetProcAddress(d3d_compiler, "D3DGetBlobPart"));
                        }
                     }

                     bool skip_reflections = false;
                     HRESULT hr;
#if 0
                     // Optional check to avoid failure cases, it seems to be useless/redundant
                     com_ptr<ID3DBlob> reflections_blob;
                     hr = d3d_get_blob_part(cached_shader->data, cached_shader->size, D3D_BLOB_INPUT_SIGNATURE_BLOB, 0, &reflections_blob);
                     if (FAILED(hr))
                     {
                        skip_reflections = true;
                     }
#endif

                     com_ptr<ID3D11ShaderReflection> shader_reflector;
                     hr = d3d_reflect(cached_shader->data, cached_shader->size, IID_ID3D11ShaderReflection, (void**)&shader_reflector);
                     if (!skip_reflections && SUCCEEDED(hr))
                     {
                        D3D11_SHADER_DESC shader_desc;
                        shader_reflector->GetDesc(&shader_desc);

                        // Determine shader type prefix
                        std::string type_prefix = "xx";
                        D3D11_SHADER_VERSION_TYPE type = (D3D11_SHADER_VERSION_TYPE)D3D11_SHVER_GET_TYPE(shader_desc.Version);
                        // The asserts might trigger if devs tried to bind the wrong shader type in a slot? Probably impossible.
                        switch (cached_shader->type)
                        {
                        case reshade::api::pipeline_subobject_type::vertex_shader:   type_prefix = "vs"; assert(type == D3D11_SHVER_VERTEX_SHADER); break;
                        case reshade::api::pipeline_subobject_type::geometry_shader: type_prefix = "gs"; assert(type == D3D11_SHVER_GEOMETRY_SHADER); break;
                        case reshade::api::pipeline_subobject_type::pixel_shader:    type_prefix = "ps"; assert(type == D3D11_SHVER_PIXEL_SHADER); break;
                        case reshade::api::pipeline_subobject_type::compute_shader:  type_prefix = "cs"; assert(type == D3D11_SHVER_COMPUTE_SHADER); break;
                        }

                        // Version: high byte = minor, low byte = major
                        UINT major_version = D3D11_SHVER_GET_MAJOR(shader_desc.Version);
                        UINT minor_version = D3D11_SHVER_GET_MINOR(shader_desc.Version);

                        // e.g. "ps_5_0"
                        cached_shader->type_and_version = type_prefix + "_" + std::to_string(major_version) + "_" + std::to_string(minor_version);

#if DEVELOPMENT
                        // TODO: add CBs here
                        bool found_any_rtvs = false;
                        bool found_any_other_bindings = false;

                        // RTVs
                        for (UINT i = 0; i < shader_desc.OutputParameters; ++i)
                        {
                           D3D11_SIGNATURE_PARAMETER_DESC shader_output_desc;
                           hr = shader_reflector->GetOutputParameterDesc(i, &shader_output_desc);
                           if (SUCCEEDED(hr) && strcmp(shader_output_desc.SemanticName, "SV_Target") == 0)
                           {
                              ASSERT_ONCE(shader_output_desc.SemanticIndex == shader_output_desc.Register && shader_output_desc.SemanticIndex < D3D11_SIMULTANEOUS_RENDER_TARGET_COUNT);
                              cached_shader->rtvs[shader_output_desc.SemanticIndex] = true;
                              found_any_rtvs = true;
                           }
                        }

                        // SRVs and UAVs (it works for compute shaders too)
                        for (UINT i = 0; i < shader_desc.BoundResources; ++i)
                        {
                           D3D11_SHADER_INPUT_BIND_DESC bind_desc;
                           hr = shader_reflector->GetResourceBindingDesc(i, &bind_desc);
                           if (SUCCEEDED(hr))
                           {
                              for (UINT j = 0; j < bind_desc.BindCount; ++j)
                              {
                                 if (bind_desc.Type == D3D_SIT_TEXTURE)
                                 {
                                    cached_shader->srvs[bind_desc.BindPoint + j] = true;
                                    found_any_other_bindings = true;
                                 }
                                 else if (bind_desc.Type == D3D_SIT_UAV_RWTYPED)
                                 {
                                    cached_shader->uavs[bind_desc.BindPoint + j] = true;
                                    found_any_other_bindings = true;
                                 }
                              }
                           }
                        }

                        // Note: sometimes the "GetResourceBindingDesc" above fails (it gives success, but then returns no bindings)... It might be related to "D3DCOMPILER_STRIP_REFLECTION_DATA",
                        // but we don't know for sure nor we can retrieve that flag, we wrote some heuristics to guess when it failed, then we pretend all bound resources are "valid" (to show them in the debug data).
                        if (found_any_other_bindings || (shader_desc.FloatInstructionCount != 0 || shader_desc.IntInstructionCount != 0 || shader_desc.UintInstructionCount != 0))
                        {
                           // In Dishonored 2, RTVs fail to be found from the DX11 reflections, but SRVs/UAVs work (we could check for depth too but whatever, these are too unreliable)
                           if (found_any_rtvs || cached_shader->type != reshade::api::pipeline_subobject_type::pixel_shader)
                              found_reflections = true;
                        }
#endif // DEVELOPMENT
                     }
                  }

                  // Fall back on disassembly to find the information. Note that this is extremely slow.
                  // TODO: allow delaying the disassembly until "Capture" is first clicked?
#if DEVELOPMENT
                  if (!found_reflections || cached_shader->type_and_version.empty())
#else // !DEVELOPMENT
                  if (cached_shader->type_and_version.empty())
#endif // DEVELOPMENT
                  {
                     assert(cached_shader); // Shouldn't ever happen
                     bool valid_disasm = false;
                     if (cached_shader->disasm.empty())
                     {
                        auto disasm_code = Shader::DisassembleShader(cached_shader->data, cached_shader->size);
                        if (disasm_code.has_value())
                        {
                           cached_shader->disasm.assign(disasm_code.value());
                           valid_disasm = true;
                        }
                        else
                        {
                           ASSERT_ONCE(false); // Shouldn't happen?
                           cached_shader->disasm.assign("DISASSEMBLY FAILED");
                        }
                     }

                     if (valid_disasm && cached_shader->type_and_version.empty())
                     {
                        if (cached_shader->type == reshade::api::pipeline_subobject_type::geometry_shader
                           || cached_shader->type == reshade::api::pipeline_subobject_type::vertex_shader
                           || cached_shader->type == reshade::api::pipeline_subobject_type::pixel_shader
                           || cached_shader->type == reshade::api::pipeline_subobject_type::compute_shader)
                        {
                           static const std::string template_geometry_shader_name = "gs_";
                           static const std::string template_vertex_shader_name = "vs_";
                           static const std::string template_pixel_shader_name = "ps_";
                           static const std::string template_compute_shader_name = "cs_";
                           static const std::string template_shader_model_version_name = "x_x";

                           std::string_view template_shader_name;
                           switch (cached_shader->type)
                           {
                           case reshade::api::pipeline_subobject_type::geometry_shader:
                           {
                              template_shader_name = template_geometry_shader_name;
                              break;
                           }
                           case reshade::api::pipeline_subobject_type::vertex_shader:
                           {
                              template_shader_name = template_vertex_shader_name;
                              break;
                           }
                           case reshade::api::pipeline_subobject_type::pixel_shader:
                           {
                              template_shader_name = template_pixel_shader_name;
                              break;
                           }
                           case reshade::api::pipeline_subobject_type::compute_shader:
                           {
                              template_shader_name = template_compute_shader_name;
                              break;
                           }
                           default:
                           {
                              template_shader_name = "xx_"; // Unknown
                              break;
                           }
                           }
                           for (char i = '0'; i <= '9'; i++)
                           {
                              std::string type_wildcard = std::string(template_shader_name) + i + '_';
                              const auto type_index = cached_shader->disasm.find(type_wildcard);
                              if (type_index != std::string::npos)
                              {
                                 cached_shader->type_and_version = cached_shader->disasm.substr(type_index, template_shader_name.length() + template_shader_model_version_name.length());
                                 break;
                              }
                           }
                        }
                     }

#if DEVELOPMENT
                     if (valid_disasm && !found_reflections)
                     {
                        std::istringstream iss(cached_shader->disasm);
                        std::string line;

                        // Regex explanation:
                        // Capture 1 to 3 digits after the specified digit (e.g. t/u/o etc) at the end
                        const std::regex pattern_cbs(R"(dcl_constantbuffer.*[cC][bB]([0-9]{1,2}))");
                        const std::regex pattern_srv(R"(.*dcl_resource_texture.*[tT]([0-9]{1,3})$)");
                        const std::regex pattern_uav(R"(.*dcl_uav_.*[uU]([0-9]{1,2})$)"); // TODO: verify that all the UAV binding types have incremental numbers, or whether they grow in parallel
                        const std::regex pattern_rtv(R"(dcl_output.*[oO]([0-9]{1,1}))"); // Match up to 9 even if theoretically "D3D11_SIMULTANEOUS_RENDER_TARGET_COUNT" is up to 7

                        bool matching_line = false;
                        while (std::getline(iss, line)) {
                           // Trim leading spaces
                           size_t first = line.find_first_not_of(" \t");
                           if (first != std::string::npos && (first + 1) < line.size())
                           {
                              // Stop if line starts with "0 ", as that's the first line that highlights the code beginning
                              if (line.at(first) == '0' && line.at(first + 1) == ' ')
                                 break;
                           }

                           bool prev_matching_line = matching_line;

                           bool cbs[D3D11_COMMONSHADER_CONSTANT_BUFFER_API_SLOT_COUNT] = {};
                           std::smatch match;
                           // Use search for CBs and RTVs because they have additional text after we found the number we are looking for
                           if (std::regex_search(line, match, pattern_cbs) && match.size() >= 2) {
                              int num = std::stoi(match[1].str());
                              if (num >= 0 && num < D3D11_COMMONSHADER_CONSTANT_BUFFER_API_SLOT_COUNT) {
                                 cached_shader->cbs[num] = true;
                                 matching_line = true;
                              }
                           }
                           // Use match for SRVs and UAVs as they end with their letter and a number
                           if (std::regex_match(line, match, pattern_srv) && match.size() >= 2) {
                              int num = std::stoi(match[1].str());
                              if (num >= 0 && num < D3D11_COMMONSHADER_INPUT_RESOURCE_SLOT_COUNT) {
                                 cached_shader->srvs[num] = true;
                                 matching_line = true;
                              }
                           }
                           if ((cached_shader->type == reshade::api::pipeline_subobject_type::pixel_shader || cached_shader->type == reshade::api::pipeline_subobject_type::compute_shader)
                              && std::regex_match(line, match, pattern_uav) && match.size() >= 2) {
                              int num = std::stoi(match[1].str());
                              if (num >= 0 && num < D3D11_1_UAV_SLOT_COUNT) {
                                 cached_shader->uavs[num] = true;
                                 matching_line = true;
                              }
                           }
                           if (cached_shader->type == reshade::api::pipeline_subobject_type::pixel_shader
                              && std::regex_search(line, match, pattern_rtv) && match.size() >= 2) {
                              int num = std::stoi(match[1].str());
                              if (num >= 0 && num < D3D11_SIMULTANEOUS_RENDER_TARGET_COUNT) {
                                 cached_shader->rtvs[num] = true;
                                 matching_line = true;
                              }
                           }
                           // Stop searching after the initial section, otherwise it's way too slow
                           if (prev_matching_line && !matching_line) break;
                        }

                        found_reflections = true;
                     }
#endif // DEVELOPMENT
                  }
#if DEVELOPMENT
                  // Default all of them to true if we can't tell which ones are used
                  if (!found_reflections)
                  {
                     for (bool&  b : cached_shader->srvs) b = true;
                     for (bool& b : cached_shader->rtvs) b = true;
                     for (bool& b : cached_shader->uavs) b = true;
                  }
#endif
               }
#endif // ALLOW_SHADERS_DUMPING || DEVELOPMENT

               // Indexes
               assert(std::find(cached_pipeline->shader_hashes.begin(), cached_pipeline->shader_hashes.end(), shader_hash) == cached_pipeline->shader_hashes.end());
#if DX12
               cached_pipeline->shader_hashes.emplace_back(shader_hash);
#else
               cached_pipeline->shader_hashes[0] = shader_hash;
               ASSERT_ONCE(cached_pipeline->shader_hashes.size() == 1); // Just to make sure if this actually happens
#endif

#if DEVELOPMENT
               auto forced_shader_names_it = forced_shader_names.find(shader_hash);
               if (forced_shader_names_it != forced_shader_names.end())
               {
                  cached_pipeline->custom_name = forced_shader_names_it->second;
               }
#endif

               // Make sure we didn't already have a valid pipeline in there (this should never happen, if not with input layout vertex shaders?, or anyway unless the game compiled the same shader twice)
               auto pipelines_pair = device_data.pipeline_caches_by_shader_hash.find(shader_hash);
               if (pipelines_pair != device_data.pipeline_caches_by_shader_hash.end())
               {
                  pipelines_pair->second.emplace(cached_pipeline);
               }
               else
               {
                  device_data.pipeline_caches_by_shader_hash[shader_hash] = { cached_pipeline };
               }
               {
                  const std::shared_lock lock(s_mutex_loading);
                  found_custom_shader_file |= custom_shaders_cache.contains(shader_hash);
               }

#if _DEBUG && LOG_VERBOSE
               // Metrics
               {
                  std::stringstream s2;
                  s2 << "caching shader(";
                  s2 << "hash: " << PRINT_CRC32(shader_hash);
                  s2 << ", type: " << subobject.type;
                  s2 << ", pipeline: " << reinterpret_cast<void*>(pipeline.handle);
                  s2 << ")";
                  reshade::log::message(reshade::log::level::info, s2.str().c_str());
               }
#endif // DEVELOPMENT
               break;
            }
            }
         }
      }
      if (!found_replaceable_shader)
      {
         delete cached_pipeline;
         cached_pipeline = nullptr;
         DestroyPipelineSubojects(subobjects_cache, subobject_count);
         subobjects_cache = nullptr;
         return;
      }
      device_data.pipeline_cache_by_pipeline_handle[pipeline.handle] = cached_pipeline;

      // Automatically load any custom shaders that might have been bound to this pipeline.
      // To avoid this slowing down everything, we only do it if we detect the user already had a matching shader in its custom shaders folder.
      if (auto_load && !last_pressed_unload && found_custom_shader_file)
      {
         const std::unique_lock lock_loading(s_mutex_loading);
         // Immediately cloning and replacing the pipeline might be unsafe, we might need to delay it to the next frame.
         // NOTE: this is totally fine to be done immediately (inline) in DX11, it's only unsafe in DX12.
         device_data.pipelines_to_reload.emplace(pipeline.handle);
         if (precompile_custom_shaders) // Re-use this value to symbolize that we don't want to wait until shaders async compilation is done to use the new shaders
         {
            LoadCustomShaders(device_data, device_data.pipelines_to_reload, !precompile_custom_shaders);
            device_data.pipelines_to_reload.clear();
         }
      }
   }
#pragma optimize("", on) // Restore the previous state

   void OnDestroyPipeline(
      reshade::api::device* device,
      reshade::api::pipeline pipeline)
   {
      DeviceData& device_data = *device->get_private_data<DeviceData>();
      {
         const std::unique_lock lock_loading(s_mutex_loading);
         device_data.pipelines_to_reload.erase(pipeline.handle);
      }

      const std::unique_lock lock(s_mutex_generic);
      if (auto pipeline_cache_pair = device_data.pipeline_cache_by_pipeline_handle.find(pipeline.handle); pipeline_cache_pair != device_data.pipeline_cache_by_pipeline_handle.end())
      {
         auto& cached_pipeline = pipeline_cache_pair->second;

         if (cached_pipeline != nullptr)
         {
            // Clean other references to the pipeline
            for (auto& pipelines_cache_pair : device_data.pipeline_caches_by_shader_hash)
            {
               auto& cached_pipelines = pipelines_cache_pair.second;
               cached_pipelines.erase(cached_pipeline);
            }

            // Destroy our cloned subojects
            DestroyPipelineSubojects(cached_pipeline->subobjects_cache, cached_pipeline->subobject_count);
            cached_pipeline->subobjects_cache = nullptr;

            // Destroy our cloned version of the pipeline (and leave the original intact)
            if (cached_pipeline->cloned)
            {
               cached_pipeline->cloned = false;
               cached_pipeline->device->destroy_pipeline(cached_pipeline->pipeline_clone);
               device_data.pipeline_cache_by_pipeline_clone_handle.erase(cached_pipeline->pipeline_clone.handle);
               device_data.cloned_pipeline_count--;
               device_data.cloned_pipelines_changed = true;
            }
            free(cached_pipeline);
            cached_pipeline = nullptr;
         }

         device_data.pipeline_cache_by_pipeline_handle.erase(pipeline.handle);
      }
   }

   void OnBindPipeline(
      reshade::api::command_list* cmd_list,
      reshade::api::pipeline_stage stages,
      reshade::api::pipeline pipeline)
   {
      constexpr reshade::api::pipeline_stage supported_stages = reshade::api::pipeline_stage::compute_shader | reshade::api::pipeline_stage::vertex_shader | reshade::api::pipeline_stage::pixel_shader
#if GEOMETRY_SHADER_SUPPORT
         | reshade::api::pipeline_stage::geometry_shader
#endif
         ;

      // Nothing to do, the pipeline isn't supported
      if ((stages & supported_stages) == 0)
         return;

      CommandListData& cmd_list_data = *cmd_list->get_private_data<CommandListData>();

      const Shader::CachedPipeline* cached_pipeline = nullptr;

      if (pipeline.handle != 0)
      {
         const DeviceData& device_data = *cmd_list->get_device()->get_private_data<DeviceData>();
         const std::shared_lock lock(s_mutex_generic);
         auto pipeline_pair = device_data.pipeline_cache_by_pipeline_handle.find(pipeline.handle);
         if (pipeline_pair != device_data.pipeline_cache_by_pipeline_handle.end())
         {
            ASSERT_ONCE(pipeline_pair->second != nullptr); // Shouldn't usually happen but if it did, it's supported anyway and innocuous
            cached_pipeline = pipeline_pair->second;
         }
         else
         {
#if ENABLE_GAME_PIPELINE_STATE_READBACK // Allow either game engines or other mods between the game and ReShade to read back states we had changed
            // "Deus Ex: Human Revolution" with the golden filter restoration mod sets back customized shaders to the pipeline,
            // as it also read back the state of DX etc, so make sure to search it from the cloned shaders list too!
            auto pipeline_pair_2 = device_data.pipeline_cache_by_pipeline_clone_handle.find(pipeline.handle);
            if (pipeline_pair_2 != device_data.pipeline_cache_by_pipeline_clone_handle.end())
            {
               cached_pipeline = pipeline_pair_2->second;
            }
#endif
            ASSERT_ONCE(cached_pipeline != nullptr); // Why can't we find the shader?
         }
      }

      if ((stages & reshade::api::pipeline_stage::compute_shader) != 0)
      {
         ASSERT_ONCE(stages == reshade::api::pipeline_stage::compute_shader || stages == reshade::api::pipeline_stage::all); // Make sure only one stage happens at a time (it does in DX11)
         cmd_list_data.pipeline_state_original_compute_shader = pipeline;

         if (cached_pipeline)
         {
#if DX12
            cmd_list_data.pipeline_state_original_compute_shader_hashes.compute_shaders = std::unordered_set<uint32_t>(cached_pipeline->shader_hashes.begin(), cached_pipeline->shader_hashes.end());
#else
            cmd_list_data.pipeline_state_original_compute_shader_hashes.compute_shaders[0] = cached_pipeline->shader_hashes[0];
#endif
            cmd_list_data.pipeline_state_has_custom_compute_shader = cached_pipeline->cloned;
         }
         else
         {
#if DX12
            cmd_list_data.pipeline_state_original_compute_shader_hashes.compute_shaders.clear();
#else
            cmd_list_data.pipeline_state_original_compute_shader_hashes.compute_shaders[0] = UINT64_MAX;
#endif
            cmd_list_data.pipeline_state_has_custom_compute_shader = false;
         }
      }
      if ((stages & reshade::api::pipeline_stage::vertex_shader) != 0)
      {
         ASSERT_ONCE(stages == reshade::api::pipeline_stage::vertex_shader || stages == reshade::api::pipeline_stage::all); // Make sure only one stage happens at a time (it does in DX11)
         cmd_list_data.pipeline_state_original_vertex_shader = pipeline;

         if (cached_pipeline)
         {
#if DX12
            cmd_list_data.pipeline_state_original_graphics_shader_hashes.vertex_shaders = std::unordered_set<uint32_t>(cached_pipeline->shader_hashes.begin(), cached_pipeline->shader_hashes.end());
#else
            cmd_list_data.pipeline_state_original_graphics_shader_hashes.vertex_shaders[0] = cached_pipeline->shader_hashes[0];
#endif
            cmd_list_data.pipeline_state_has_custom_vertex_shader = cached_pipeline->cloned;
         }
         else
         {
#if DX12
            cmd_list_data.pipeline_state_original_graphics_shader_hashes.vertex_shaders.clear();
#else
            cmd_list_data.pipeline_state_original_graphics_shader_hashes.vertex_shaders[0] = UINT64_MAX;
#endif
            cmd_list_data.pipeline_state_has_custom_vertex_shader = false;
         }
         cmd_list_data.pipeline_state_has_custom_graphics_shader = cmd_list_data.pipeline_state_has_custom_pixel_shader || cmd_list_data.pipeline_state_has_custom_vertex_shader;
      }
      if ((stages & reshade::api::pipeline_stage::pixel_shader) != 0)
      {
         ASSERT_ONCE(stages == reshade::api::pipeline_stage::pixel_shader || stages == reshade::api::pipeline_stage::all); // Make sure only one stage happens at a time (it does in DX11)
         cmd_list_data.pipeline_state_original_pixel_shader = pipeline;
         
         if (cached_pipeline)
         {
#if DX12
            cmd_list_data.pipeline_state_original_graphics_shader_hashes.pixel_shaders = std::unordered_set<uint32_t>(cached_pipeline->shader_hashes.begin(), cached_pipeline->shader_hashes.end());
#else
            cmd_list_data.pipeline_state_original_graphics_shader_hashes.pixel_shaders[0] = cached_pipeline->shader_hashes[0];
#endif
            cmd_list_data.pipeline_state_has_custom_pixel_shader = cached_pipeline->cloned;
         }
         else
         {
#if DX12
            cmd_list_data.pipeline_state_original_graphics_shader_hashes.pixel_shaders.clear();
#else
            cmd_list_data.pipeline_state_original_graphics_shader_hashes.pixel_shaders[0] = UINT64_MAX;
#endif
            cmd_list_data.pipeline_state_has_custom_pixel_shader = false;
         }
         cmd_list_data.pipeline_state_has_custom_graphics_shader = cmd_list_data.pipeline_state_has_custom_pixel_shader || cmd_list_data.pipeline_state_has_custom_vertex_shader;
      }

      if (cached_pipeline)
      {
#if DEVELOPMENT
         if (cached_pipeline->skip_type == CachedPipeline::ShaderSkipType::Purple)
         {
            // TODO: automatically generate a pixel shader that has a matching input and output signature as the one the pass would have had instead,
            // given that sometimes drawing purple fails with warnings. Or replace the vertex shader too with "copy_vertex_shader"? Though the shape will then not match, likely.
            ID3D11DeviceContext* native_device_context = (ID3D11DeviceContext*)(cmd_list->get_native());
            DeviceData& device_data = *cmd_list->get_device()->get_private_data<DeviceData>();
            if (cached_pipeline->HasComputeShader())
            {
               native_device_context->CSSetShader(device_data.draw_purple_compute_shader.get(), nullptr, 0);
            }
            else if (cached_pipeline->HasPixelShader())
            {
               native_device_context->PSSetShader(device_data.draw_purple_pixel_shader.get(), nullptr, 0);
            }
         }
         else if (cached_pipeline->skip_type == CachedPipeline::ShaderSkipType::Skip)
         {
            // This will make the shader output black, or skip drawing, so we can easily detect it. This might not be very safe but seems to work in DX11.
            cmd_list->bind_pipeline(stages, reshade::api::pipeline{ 0 });
         }
         else
#endif
         // TODO: have a high performance mode that swaps the original shader binary with the custom one on creation, so we don't have to analyze shader binding calls (probably wouldn't really speed up performance anyway)
         if (cached_pipeline->cloned)
         {
            cmd_list->bind_pipeline(stages, cached_pipeline->pipeline_clone);
         }
      }

#if DEVELOPMENT
      const std::shared_lock lock_trace(s_mutex_trace);
      if (trace_running)
      {
         CommandListData& cmd_list_data = *cmd_list->get_private_data<CommandListData>();
         const std::unique_lock lock_trace_2(cmd_list_data.mutex_trace);
         TraceDrawCallData trace_draw_call_data;
         trace_draw_call_data.type = TraceDrawCallData::TraceDrawCallType::BindPipeline;
         trace_draw_call_data.command_list = (ID3D11DeviceContext*)(cmd_list->get_native());
         //trace_draw_call_data.custom_name = std::string("Bind Shader ") + Shader::Hash_NumToStr(cached_pipeline->shader_hashes[0], true); //TODOFT: fix ...
         cmd_list_data.trace_draw_calls_data.push_back(trace_draw_call_data);
      }
#endif
   }

   enum class LumaConstantBufferType
   {
      // Global/frame settings
      LumaSettings,
      // Per draw/instance data
      LumaData,
      LumaUIData
   };

   void SetLumaConstantBuffers(ID3D11DeviceContext* native_device_context, CommandListData& cmd_list_data, DeviceData& device_data, reshade::api::shader_stage stages, LumaConstantBufferType type, uint32_t custom_data_1 = 0, uint32_t custom_data_2 = 0, float custom_data_3 = 0.f, float custom_data_4 = 0.f)
   {
      constexpr bool force_update = false;

      // Most games (e.g. Prey, Dishonored 2) doesn't ever use these buffers, so it's fine to re-apply them once per frame if they didn't change.
      // For other games, it'd be good to re-apply the previously set cbuffer after temporarily changing it, as they might only set them once per frame.
      switch (type)
      {
      case LumaConstantBufferType::LumaSettings:
      {
         if (luma_settings_cbuffer_index >= D3D11_COMMONSHADER_CONSTANT_BUFFER_API_SLOT_COUNT) break;

         {
            const std::shared_lock lock_reshade(s_mutex_reshade);
            if (force_update || device_data.cb_luma_global_settings_dirty)
            {
               device_data.cb_luma_global_settings_dirty = false;
               // My understanding is that "Map" doesn't immediately copy the memory to the GPU, but simply stores it on the side (in the command list),
               // and then copies it to the GPU when the command list is executed, so the resource is updated with deterministic order.
               // From our point of view, we don't really know what command list is currently running and what it is doing,
               // so we could still end up first updating the resource in a command list that will be executed with a delay,
               // and then updating the resource again in a command list that executes first, leaving the GPU buffer with whatever latest data it got (which might not be based on our latest version).
               // Fortunately we rarely use our cbuffers in any of the non main/primary command lists, and if we do, we generally don't change them within the frame,
               // so we can consider it all single threaded and deterministic. If ever needed, we could force a map to happen every time if we are in a new (non main) command list,
               // but then again, that would cross pollute the buffer across thread (plus, a command list is not guaranteed to ever be executed, it could be cleared before executing),
               // so the best solution would be to have these cbuffers per thread or per pass, or to not change them within a frame (or to always write the buffer again!)!
               if (D3D11_MAPPED_SUBRESOURCE mapped_buffer;
                  SUCCEEDED(native_device_context->Map(device_data.luma_global_settings.get(), 0, D3D11_MAP_WRITE_DISCARD, 0, &mapped_buffer)))
               {
                  ASSERT_ONCE_MSG(cmd_list_data.is_primary, "Changing the Luma Settings CBuffer from async command lists isn't fully save, use the Luma Data CBuffer if you change the data within a frame");
                  std::memcpy(mapped_buffer.pData, &cb_luma_global_settings, sizeof(cb_luma_global_settings));
                  native_device_context->Unmap(device_data.luma_global_settings.get(), 0);
               }
            }
         }

         ID3D11Buffer* const buffer = device_data.luma_global_settings.get();
         if ((stages & reshade::api::shader_stage::vertex) == reshade::api::shader_stage::vertex)
            native_device_context->VSSetConstantBuffers(luma_settings_cbuffer_index, 1, &buffer);
         if ((stages & reshade::api::shader_stage::geometry) == reshade::api::shader_stage::geometry)
            native_device_context->GSSetConstantBuffers(luma_settings_cbuffer_index, 1, &buffer);
         if ((stages & reshade::api::shader_stage::pixel) == reshade::api::shader_stage::pixel)
            native_device_context->PSSetConstantBuffers(luma_settings_cbuffer_index, 1, &buffer);
         if ((stages & reshade::api::shader_stage::compute) == reshade::api::shader_stage::compute)
            native_device_context->CSSetConstantBuffers(luma_settings_cbuffer_index, 1, &buffer);
         break;
      }
      case LumaConstantBufferType::LumaData:
      {
         if (luma_data_cbuffer_index >= D3D11_COMMONSHADER_CONSTANT_BUFFER_API_SLOT_COUNT) break;

         CB::LumaInstanceDataPadded cb_luma_instance_data;
         cb_luma_instance_data.CustomData1 = custom_data_1;
         cb_luma_instance_data.CustomData2 = custom_data_2;
         cb_luma_instance_data.CustomData3 = custom_data_3;
         cb_luma_instance_data.CustomData4 = custom_data_4;

         cb_luma_instance_data.RenderResolutionScale.x = device_data.render_resolution.x / device_data.output_resolution.x;
         cb_luma_instance_data.RenderResolutionScale.y = device_data.render_resolution.y / device_data.output_resolution.y;
         // Always do this relative to the current output resolution
         cb_luma_instance_data.PreviousRenderResolutionScale.x = device_data.previous_render_resolution.x / device_data.output_resolution.x;
         cb_luma_instance_data.PreviousRenderResolutionScale.y = device_data.previous_render_resolution.y / device_data.output_resolution.y;

         game->UpdateLumaInstanceDataCB(cb_luma_instance_data, cmd_list_data, device_data);

         if (force_update || cmd_list_data.force_cb_luma_instance_data_dirty || memcmp(&cmd_list_data.cb_luma_instance_data, &cb_luma_instance_data, sizeof(cb_luma_instance_data)) != 0)
         {
            cmd_list_data.cb_luma_instance_data = cb_luma_instance_data;
            cmd_list_data.force_cb_luma_instance_data_dirty = false;
            if (D3D11_MAPPED_SUBRESOURCE mapped_buffer;
               SUCCEEDED(native_device_context->Map(device_data.luma_instance_data.get(), 0, D3D11_MAP_WRITE_DISCARD, 0, &mapped_buffer)))
            {
               std::memcpy(mapped_buffer.pData, &cmd_list_data.cb_luma_instance_data, sizeof(cmd_list_data.cb_luma_instance_data));
               native_device_context->Unmap(device_data.luma_instance_data.get(), 0);
            }
         }

         ID3D11Buffer* const buffer = device_data.luma_instance_data.get();
         if ((stages & reshade::api::shader_stage::vertex) == reshade::api::shader_stage::vertex)
            native_device_context->VSSetConstantBuffers(luma_data_cbuffer_index, 1, &buffer);
         if ((stages & reshade::api::shader_stage::geometry) == reshade::api::shader_stage::geometry)
            native_device_context->GSSetConstantBuffers(luma_data_cbuffer_index, 1, &buffer);
         if ((stages & reshade::api::shader_stage::pixel) == reshade::api::shader_stage::pixel)
            native_device_context->PSSetConstantBuffers(luma_data_cbuffer_index, 1, &buffer);
         if ((stages & reshade::api::shader_stage::compute) == reshade::api::shader_stage::compute)
            native_device_context->CSSetConstantBuffers(luma_data_cbuffer_index, 1, &buffer);
         break;
      }
      case LumaConstantBufferType::LumaUIData:
      {
         ASSERT_ONCE_MSG(false, "Luma UI Data is not implemented (yet?)"); //TODOFT5: do it?
         break;
      }
      }
   }

#if DEVELOPMENT
   void OnExecuteCommandList(reshade::api::command_queue* queue, reshade::api::command_list* cmd_list)
   {
      const std::shared_lock lock_trace(s_mutex_trace);
      if (trace_running)
      {
         CommandListData& cmd_list_data = *cmd_list->get_private_data<CommandListData>();
         const std::unique_lock lock_trace_2(cmd_list_data.mutex_trace);
         TraceDrawCallData trace_draw_call_data;
         trace_draw_call_data.type = TraceDrawCallData::TraceDrawCallType::FlushCommandList;
         trace_draw_call_data.command_list = (ID3D11DeviceContext*)(cmd_list->get_native());
         cmd_list_data.trace_draw_calls_data.push_back(trace_draw_call_data);
      }
   }
   void OnExecuteSecondaryCommandList(reshade::api::command_list* cmd_list, reshade::api::command_list* secondary_cmd_list)
   {
      const std::shared_lock lock_trace(s_mutex_trace);
      if (trace_running)
      {
         CommandListData& cmd_list_data = *cmd_list->get_private_data<CommandListData>();
         CommandListData& secondary_cmd_list_data = *secondary_cmd_list->get_private_data<CommandListData>();

         const std::unique_lock lock_trace_2(cmd_list_data.mutex_trace);
         TraceDrawCallData trace_draw_call_data;
         trace_draw_call_data.type = TraceDrawCallData::TraceDrawCallType::AppendCommandList;
         trace_draw_call_data.command_list = (ID3D11DeviceContext*)(cmd_list->get_native()); // Show the target command list, not the source one (the source draw calls will be below)
         cmd_list_data.trace_draw_calls_data.push_back(trace_draw_call_data);

         const std::unique_lock lock_trace_3(secondary_cmd_list_data.mutex_trace);
         cmd_list_data.trace_draw_calls_data.append_range(secondary_cmd_list_data.trace_draw_calls_data);
         secondary_cmd_list_data.trace_draw_calls_data.clear();
      }
   }
#endif

#if RESHADE_API_VERSION >= 18
   bool
#else
   void
#endif
      OnPresent(
      reshade::api::command_queue* queue,
      reshade::api::swapchain* swapchain,
      const reshade::api::rect* source_rect,
      const reshade::api::rect* dest_rect,
      uint32_t dirty_rect_count,
      const reshade::api::rect* dirty_rects
#if RESHADE_API_VERSION >= 18
      , uint32_t* sync_interval
      , uint32_t* flags
#endif
      )
   {
      ID3D11Device* native_device = (ID3D11Device*)(queue->get_device()->get_native());
      ID3D11DeviceContext* native_device_context = (ID3D11DeviceContext*)(queue->get_immediate_command_list()->get_native());
      DeviceData& device_data = *queue->get_device()->get_private_data<DeviceData>();
      SwapchainData& swapchain_data = *swapchain->get_private_data<SwapchainData>();
      CommandListData& cmd_list_data = *queue->get_immediate_command_list()->get_private_data<CommandListData>();

#if RESHADE_API_VERSION >= 18
      // We previously added "DXGI_SWAP_CHAIN_FLAG_ALLOW_TEARING" to the swapchain, so we need to add this too
      if (sync_interval && *sync_interval == 0 && flags)
      {
         *flags |= DXGI_PRESENT_ALLOW_TEARING;
      }
#endif

#if DEVELOPMENT
#if GAME_BIOSHOCK_2 && 0 //TODOFT6: probably not necessary
      if (auto native_swapchain = device_data.GetMainNativeSwapchain().get())
      {
         com_ptr<IDXGIOutput> output;
         native_swapchain->GetContainingOutput(&output);
         if (output)
         {
            DXGI_GAMMA_CONTROL gamma_control;
            ASSERT_ONCE(output->GetGammaControl(&gamma_control));

            // Set scale to default (1.0, 1.0, 1.0)
            gamma_control.Scale.Red = 1.0f;
            gamma_control.Scale.Green = 1.0f;
            gamma_control.Scale.Blue = 1.0f;
            // Set offset to default (0.0, 0.0, 0.0)
            gamma_control.Offset.Red = 0.0f;
            gamma_control.Offset.Green = 0.0f;
            gamma_control.Offset.Blue = 0.0f;

            // Create a simple gamma curve (linear in this example)
            for (int i = 0; i < 1025; ++i)
            {
               float value = i / 1024.0f;
               gamma_control.GammaCurve[i].Red = value;
               gamma_control.GammaCurve[i].Green = value;
               gamma_control.GammaCurve[i].Blue = value;
            }

            ASSERT_ONCE(output->SetGammaControl(nullptr));
            ASSERT_ONCE(output->SetGammaControl(&gamma_control));
         }
      }
#endif // GAME_BIOSHOCK_2

      // Allow to tank performance to test auto rendering resolution scaling etc
      if (frame_sleep_ms > 0 && cb_luma_global_settings.FrameIndex % frame_sleep_interval == 0)
         Sleep(frame_sleep_ms);
#endif  // DEVELOPMENT

      // If there are no shaders being currently replaced in the game ("cloned_pipeline_count"),
      // we can assume that we either missed replacing some shaders, or that we have unloaded all of our shaders.
      bool mod_active = device_data.cloned_pipeline_count != 0;
      // Theoretically we should simply check the current swapchain buffer format, but this also works
      const bool output_linear = (enable_swapchain_upgrade && swapchain_upgrade_type >= 1) || swapchain_data.vanilla_was_linear_space;
      bool input_linear = swapchain_data.vanilla_was_linear_space;
#if GAME_PREY // Prey's native code hooks already make the swapchain linear, but don't change the shaders
      input_linear = false;
#endif
      if (mod_active)
      {
         // "POST_PROCESS_SPACE_TYPE" 1 means that the final image was stored in textures in linear space (e.g. float or sRGB texture formats),
         // any other type would have been in gamma space, so it needs to be linearized for scRGB HDR (linear) output.
         // "GAMMA_CORRECTION_TYPE" 2 is always re-corrected (e.g. from sRGB) in the final shader.
         input_linear = GetShaderDefineCompiledNumericalValue(POST_PROCESS_SPACE_TYPE_HASH) == 1;
      }
      // Note that not all these combinations might be handled by the shader
      bool needs_reencoding = output_linear != input_linear;
      bool early_display_encoding = GetShaderDefineCompiledNumericalValue(POST_PROCESS_SPACE_TYPE_HASH) == 1 && GetShaderDefineCompiledNumericalValue(EARLY_DISPLAY_ENCODING_HASH) >= 1;
      bool needs_scaling = mod_active ? !early_display_encoding : (cb_luma_global_settings.DisplayMode >= 1);
      bool early_gamma_correction = early_display_encoding && GetShaderDefineCompiledNumericalValue(GAMMA_CORRECTION_TYPE_HASH) < 2;
      // If the vanilla game was already doing post processing in linear space, it would have used sRGB buffers, hence it needs a sRGB<->2.2 gamma mismatch fix (we assume the vanilla game was running in SDR, not scRGB HDR).
      bool in_out_gamma_different = GetShaderDefineCompiledNumericalValue(VANILLA_ENCODING_TYPE_HASH) != GetShaderDefineCompiledNumericalValue(GAMMA_CORRECTION_TYPE_HASH);
      // If we are outputting SDR on SDR Display on a scRGB HDR swapchain, we might need Gamma 2.2/sRGB mismatch correction, because Windows would encode the scRGB buffer with sRGB (instead of Gamma 2.2, which the game would likely have expected)
      bool display_mode_needs_gamma_correction = swapchain_data.vanilla_was_linear_space ? false : (cb_luma_global_settings.DisplayMode == 0);
      bool needs_gamma_correction = (mod_active ? (!early_gamma_correction && in_out_gamma_different) : in_out_gamma_different) || display_mode_needs_gamma_correction;
      // If this is true, the UI and Scene were both drawn with a brightness that is relative to each other, so we need to normalize it back to the scene brightness range
      bool ui_needs_scaling = mod_active && GetShaderDefineCompiledNumericalValue(UI_DRAW_TYPE_HASH) == 2;
      // If this is true, the UI was drawn on a separate buffer and needs to be composed onto the scene (which allows for UI background tonemapping, for increased visibility in HDR)
      bool ui_needs_composition = mod_active && GetShaderDefineCompiledNumericalValue(UI_DRAW_TYPE_HASH) >= 3 && device_data.ui_texture.get();
      bool needs_gamut_mapping = mod_active && GetShaderDefineCompiledNumericalValue(GAMUT_MAPPING_TYPE_HASH) != 0;
      // TODO: add "TEST_SDR_HDR_SPLIT_VIEW_MODE" and "TEST_2X_ZOOM" as drawing conditions

#if DEVELOPMENT
      bool needs_debug_draw_texture = device_data.debug_draw_texture.get() != nullptr; // Note that this might look wrong if "output_linear" is false
#else
      constexpr bool needs_debug_draw_texture = false;
#endif
      if (needs_debug_draw_texture || needs_reencoding || needs_gamma_correction || ui_needs_scaling || ui_needs_composition || needs_gamut_mapping)
      {
         const std::shared_lock lock_shader_objects(s_mutex_shader_objects);
         if (device_data.copy_vertex_shader && device_data.display_composition_pixel_shader)
         {
            IDXGISwapChain* native_swapchain = (IDXGISwapChain*)(swapchain->get_native());

            UINT back_buffer_index = 0;
            com_ptr<IDXGISwapChain3> native_swapchain3;
            // The cast pointer is actually the same, we are just making sure the type is right (it should always be).
            if (SUCCEEDED(native_swapchain->QueryInterface(&native_swapchain3)))
            {
               back_buffer_index = native_swapchain3->GetCurrentBackBufferIndex();
            }
            com_ptr<ID3D11Texture2D> back_buffer;
            native_swapchain->GetBuffer(back_buffer_index, IID_PPV_ARGS(&back_buffer));
            assert(back_buffer != nullptr && swapchain_data.back_buffers.size() >= back_buffer_index + 1);
            assert(swapchain_data.display_composition_rtvs.size() >= back_buffer_index + 1);

            D3D11_TEXTURE2D_DESC target_desc;
            back_buffer->GetDesc(&target_desc);
            ASSERT_ONCE((target_desc.BindFlags & D3D11_BIND_RENDER_TARGET) != 0);
            // For now we only support this format, nothing else wouldn't really make sense
            ASSERT_ONCE(target_desc.Format == DXGI_FORMAT_R16G16B16A16_FLOAT);

            uint32_t custom_const_buffer_data_1 = 0;
            uint32_t custom_const_buffer_data_2 = 0;

#if DEVELOPMENT // See "debug_draw_srv_slot_numbers" etc...
            DrawStateStack<DrawStateStackType::FullGraphics> draw_state_stack;
#else
            DrawStateStack<DrawStateStackType::SimpleGraphics> draw_state_stack;
#endif
            draw_state_stack.Cache(native_device_context, device_data.uav_max_count);

#if DEVELOPMENT
            UINT debug_draw_srv_slot = 2; // 0 is for background, 1 is for UI, 2+ for debug draw types
            constexpr UINT debug_draw_srv_slot_numbers = 7; // The max amount of debug draw types, determined by the display composition shader too

            if (device_data.debug_draw_texture.get())
            {
               // We might not be able to rely on SRVs automatic generation (by passing a nullptr desc), because depth resources take a custom view format etc

               com_ptr<ID3D11Texture2D> debug_draw_texture_2d;
               device_data.debug_draw_texture->QueryInterface(&debug_draw_texture_2d);
               com_ptr<ID3D11Texture3D> debug_draw_texture_3d;
               device_data.debug_draw_texture->QueryInterface(&debug_draw_texture_3d);
               com_ptr<ID3D11Texture1D> debug_draw_texture_1d;
               device_data.debug_draw_texture->QueryInterface(&debug_draw_texture_1d);
               D3D11_SHADER_RESOURCE_VIEW_DESC debug_srv_desc = {};
               DXGI_FORMAT debug_draw_texture_format = DXGI_FORMAT_UNKNOWN;
               if (debug_draw_texture_2d)
               {
                  D3D11_TEXTURE2D_DESC texture_2d_desc;
                  debug_draw_texture_2d->GetDesc(&texture_2d_desc);

                  debug_draw_texture_format = texture_2d_desc.Format;
                  debug_srv_desc.Format = device_data.debug_draw_texture_format;
                  if (texture_2d_desc.SampleDesc.Count <= 1 && texture_2d_desc.ArraySize <= 1) // Non Array Non MS
                  {
                     debug_srv_desc.ViewDimension = D3D11_SRV_DIMENSION_TEXTURE2D;
                     debug_srv_desc.Texture2D.MostDetailedMip = 0;
                     debug_srv_desc.Texture2D.MipLevels = UINT(-1); // Use all
                     debug_draw_srv_slot = 2;
                  }
                  if (texture_2d_desc.SampleDesc.Count > 1) // Array
                  {
                     if (texture_2d_desc.ArraySize <= 1)
                     {
                        debug_srv_desc.ViewDimension = D3D11_SRV_DIMENSION_TEXTURE2DMS;
                        debug_srv_desc.Texture2DMS.UnusedField_NothingToDefine = 0; // Useless, but good to make it explicit
                        debug_draw_srv_slot = 3;
                     }
                     debug_draw_options |= (uint32_t)DebugDrawTextureOptionsMask::TextureMultiSample;
                  }
                  else
                  {
                     debug_draw_options &= ~(uint32_t)DebugDrawTextureOptionsMask::TextureMultiSample;
                  }
                  if (texture_2d_desc.ArraySize > 1) // Array
                  {
                     if (texture_2d_desc.SampleDesc.Count > 1) // Array + MS
                     {
                        debug_srv_desc.ViewDimension = D3D11_SRV_DIMENSION_TEXTURE2DMSARRAY;
                        debug_srv_desc.Texture2DMSArray.FirstArraySlice = 0;
                        debug_srv_desc.Texture2DMSArray.ArraySize = texture_2d_desc.ArraySize;
                        debug_draw_srv_slot = 5;
                     }
                     else
                     {
                        debug_srv_desc.ViewDimension = D3D11_SRV_DIMENSION_TEXTURE2DARRAY;
                        debug_srv_desc.Texture2DArray.MostDetailedMip = 0;
                        debug_srv_desc.Texture2DArray.MipLevels = UINT(-1); // Use all
                        debug_srv_desc.Texture2DArray.FirstArraySlice = 0;
                        debug_srv_desc.Texture2DArray.ArraySize = texture_2d_desc.ArraySize;
                        debug_draw_srv_slot = 4;
                     }
                     debug_draw_options |= (uint32_t)DebugDrawTextureOptionsMask::TextureArray;
                  }
                  else
                  {
                     debug_draw_options &= ~(uint32_t)DebugDrawTextureOptionsMask::TextureArray;
                  }
                  debug_draw_options |= (uint32_t)DebugDrawTextureOptionsMask::Texture2D;
                  debug_draw_options &= ~(uint32_t)DebugDrawTextureOptionsMask::Texture3D;
               }
               else if (debug_draw_texture_3d)
               {
                  D3D11_TEXTURE3D_DESC texture_3d_desc;
                  debug_draw_texture_3d->GetDesc(&texture_3d_desc);

                  debug_draw_texture_format = texture_3d_desc.Format;
                  debug_srv_desc.Format = device_data.debug_draw_texture_format;
                  debug_srv_desc.ViewDimension = D3D11_SRV_DIMENSION_TEXTURE3D;
                  debug_srv_desc.Texture3D.MostDetailedMip = 0;
                  debug_srv_desc.Texture3D.MipLevels = UINT(-1); // Use all
                  debug_draw_srv_slot = 6;
                  debug_draw_options &= ~(uint32_t)DebugDrawTextureOptionsMask::TextureMultiSample;
                  debug_draw_options &= ~(uint32_t)DebugDrawTextureOptionsMask::TextureArray;
                  debug_draw_options |= (uint32_t)DebugDrawTextureOptionsMask::Texture3D;
                  debug_draw_options &= ~(uint32_t)DebugDrawTextureOptionsMask::Texture2D;
               }
               else if (debug_draw_texture_1d)
               {
                  D3D11_TEXTURE1D_DESC texture_1d_desc;
                  debug_draw_texture_1d->GetDesc(&texture_1d_desc);

                  debug_draw_texture_format = texture_1d_desc.Format;
                  debug_srv_desc.Format = device_data.debug_draw_texture_format;
                  if (texture_1d_desc.ArraySize > 1)
                  {
                     debug_srv_desc.ViewDimension = D3D11_SRV_DIMENSION_TEXTURE1DARRAY;
                     debug_srv_desc.Texture1DArray.MostDetailedMip = 0;
                     debug_srv_desc.Texture1DArray.MipLevels = UINT(-1); // Use all
                     debug_srv_desc.Texture1DArray.FirstArraySlice = 0;
                     debug_srv_desc.Texture1DArray.ArraySize = texture_1d_desc.ArraySize;
                     debug_draw_srv_slot = 8;
                     debug_draw_options |= (uint32_t)DebugDrawTextureOptionsMask::TextureArray;
                  }
                  else
                  {
                     debug_srv_desc.ViewDimension = D3D11_SRV_DIMENSION_TEXTURE1D;
                     debug_srv_desc.Texture1D.MostDetailedMip = 0;
                     debug_srv_desc.Texture1D.MipLevels = UINT(-1); // Use all
                     debug_draw_srv_slot = 7;
                     debug_draw_options &= ~(uint32_t)DebugDrawTextureOptionsMask::TextureArray;
                  }
                  debug_draw_options &= ~(uint32_t)DebugDrawTextureOptionsMask::TextureMultiSample;
                  debug_draw_options &= ~(uint32_t)DebugDrawTextureOptionsMask::Texture3D;
                  debug_draw_options &= ~(uint32_t)DebugDrawTextureOptionsMask::Texture2D;
               }

               if (debug_draw_auto_gamma)
               {
                  // TODO: if this is depth and depth is inverted (or not), should we flip the gamma direction?
                  if (!IsLinearFormat(device_data.debug_draw_texture_format)) // We don't use the view format as we create a new view with the native format
                  {
                     debug_draw_options |= (uint32_t)DebugDrawTextureOptionsMask::GammaToLinear;
                  }
                  else
                  {
                     debug_draw_options &= ~(uint32_t)DebugDrawTextureOptionsMask::LinearToGamma;
                     debug_draw_options &= ~(uint32_t)DebugDrawTextureOptionsMask::GammaToLinear;
                  }
               }

               com_ptr<ID3D11ShaderResourceView> debug_srv;
               // We recreate this every frame, it doesn't really matter (and this is allowed to fail in case of quirky formats)
               HRESULT hr = native_device->CreateShaderResourceView(device_data.debug_draw_texture.get(), &debug_srv_desc, &debug_srv);
               // Try again with the resource format in case the above failed...
               if (FAILED(hr))
               {
                  debug_srv_desc.Format = debug_draw_texture_format;
                  debug_srv = nullptr; // Extra safety
                  hr = native_device->CreateShaderResourceView(device_data.debug_draw_texture.get(), &debug_srv_desc, &debug_srv);
               }
               ASSERT_ONCE(SUCCEEDED(hr));

               ID3D11ShaderResourceView* const debug_srv_const = debug_srv.get();
               native_device_context->PSSetShaderResources(debug_draw_srv_slot, 1, &debug_srv_const); // Use index 1 (0 is already used)

               auto temp_debug_draw_options = debug_draw_options;
               bool debug_draw_saturate = (debug_draw_options & (uint32_t)DebugDrawTextureOptionsMask::Saturate) != 0;
               // TODO: save two versions of "debug_draw_options", one that matches the user settings and one that is the current automated version of it
               if (debug_draw_saturate || !IsFloatFormat(device_data.debug_draw_texture_format))
               {
                  temp_debug_draw_options &= ~(uint32_t)DebugDrawTextureOptionsMask::Tonemap;
               }
               custom_const_buffer_data_2 = temp_debug_draw_options;
            }
            // Empty the shader resources so the shader can tell there isn't one
            else
            {
               ID3D11ShaderResourceView* const debug_srvs_const[debug_draw_srv_slot_numbers] = {};
               native_device_context->PSSetShaderResources(debug_draw_srv_slot, debug_draw_srv_slot_numbers, &debug_srvs_const[0]);
            }
#endif

            D3D11_TEXTURE2D_DESC proxy_target_desc;
            if (device_data.display_composition_texture.get() != nullptr)
            {
               device_data.display_composition_texture->GetDesc(&proxy_target_desc);
            }
            bool had_mips = proxy_target_desc.MipLevels == 0;
            bool wants_mips = false;
#if GAME_TEMPLATE // use this for AutoHDR deblooming //TODOFT: finish this stuff
            wants_mips = !mod_active;
#endif
            if (device_data.display_composition_texture.get() == nullptr || proxy_target_desc.Width != target_desc.Width || proxy_target_desc.Height != target_desc.Height || proxy_target_desc.Format != target_desc.Format || had_mips != wants_mips)
            {
               proxy_target_desc = target_desc;
               proxy_target_desc.BindFlags |= D3D11_BIND_SHADER_RESOURCE;
               proxy_target_desc.BindFlags &= ~D3D11_BIND_RENDER_TARGET;
               proxy_target_desc.BindFlags &= ~D3D11_BIND_UNORDERED_ACCESS;
               proxy_target_desc.CPUAccessFlags = 0;
               proxy_target_desc.Usage = D3D11_USAGE_DEFAULT;

               if (wants_mips)
               {
                  proxy_target_desc.MipLevels = 0; // All mips
                  proxy_target_desc.BindFlags |= D3D11_BIND_RENDER_TARGET; // Needed by "GenerateMips()"
                  proxy_target_desc.MiscFlags |= D3D11_RESOURCE_MISC_GENERATE_MIPS; // For AutoHDR "bloom" feature
               }

               device_data.display_composition_texture = nullptr;
               device_data.display_composition_srv = nullptr;
               // Don't change the allocation number
					for (size_t i = 0; i < swapchain_data.display_composition_rtvs.size(); ++i)
					{
						swapchain_data.display_composition_rtvs[i] = nullptr;
					}
               HRESULT hr = native_device->CreateTexture2D(&proxy_target_desc, nullptr, &device_data.display_composition_texture);
               assert(SUCCEEDED(hr));

               D3D11_TEXTURE2D_DESC texDesc = {};
               device_data.display_composition_texture->GetDesc(&texDesc);

               D3D11_SHADER_RESOURCE_VIEW_DESC srvDesc = {};
               srvDesc.Format = proxy_target_desc.Format;
               srvDesc.ViewDimension = D3D11_SRV_DIMENSION_TEXTURE2D;
               srvDesc.Texture2D.MostDetailedMip = 0;
               srvDesc.Texture2D.MipLevels = texDesc.MipLevels == 0 ? UINT(-1) : texDesc.MipLevels; // For some reason this requires -1 instead of 0 to specify all mips
               hr = native_device->CreateShaderResourceView(device_data.display_composition_texture.get(), &srvDesc, &device_data.display_composition_srv);
               assert(SUCCEEDED(hr));

               if (wants_mips)
               {
                  UINT support = 0;
                  hr = native_device->CheckFormatSupport(texDesc.Format, &support);
                  assert(SUCCEEDED(hr));
                  assert(support & D3D11_FORMAT_SUPPORT_MIP_AUTOGEN);
               }
            }

            // We need to copy the texture to read back from it, even if we only exclusively write to the same pixel we read and thus there couldn't be any race condition. Unfortunately DX works like that.
            if (wants_mips)
            {
               native_device_context->CopySubresourceRegion(device_data.display_composition_texture.get(), 0, 0, 0, 0, back_buffer.get(), 0, nullptr); // Copy the base mip only
               native_device_context->GenerateMips(device_data.display_composition_srv.get());
            }
            else
            {
               native_device_context->CopyResource(device_data.display_composition_texture.get(), back_buffer.get());
            }

            com_ptr<ID3D11RenderTargetView> target_resource_texture_view = swapchain_data.display_composition_rtvs[back_buffer_index];
            // If we already had a render target view (set by the game), we can assume it was already set to the swapchain,
            // but it's good to make sure of it nonetheless, it might have been changed already.
            if (draw_state_stack.render_target_views[0] != nullptr && draw_state_stack.render_target_views[0] != swapchain_data.display_composition_rtvs[back_buffer_index])
            {
               com_ptr<ID3D11Resource> render_target_resource;
               draw_state_stack.render_target_views[0]->GetResource(&render_target_resource);
               if (render_target_resource.get() == back_buffer.get())
               {
                  target_resource_texture_view = draw_state_stack.render_target_views[0];
                  swapchain_data.display_composition_rtvs[back_buffer_index] = nullptr;
               }
            }
            if (!target_resource_texture_view)
            {
               swapchain_data.display_composition_rtvs[back_buffer_index] = nullptr;
               HRESULT hr = native_device->CreateRenderTargetView(back_buffer.get(), nullptr, &swapchain_data.display_composition_rtvs[back_buffer_index]);
               ASSERT_ONCE(SUCCEEDED(hr));
               target_resource_texture_view = swapchain_data.display_composition_rtvs[back_buffer_index];
            }

            // Push our settings cbuffer in case where no other custom shader run this frame
            {
               DeviceData& device_data = *queue->get_device()->get_private_data<DeviceData>();
               const std::shared_lock lock(s_mutex_reshade);
               const auto cb_luma_global_settings_copy = cb_luma_global_settings;
               // Force a custom display mode in case we have no game custom shaders loaded, so the custom linearization shader can linearize anyway, independently of "POST_PROCESS_SPACE_TYPE"
               bool force_reencoding_or_gamma_correction = !mod_active; // We ignore "s_mutex_generic", it doesn't matter
               if (force_reencoding_or_gamma_correction)
               {
                  // No need for "s_mutex_reshade" here or above, given that they are generally only also changed by the user manually changing the settings in ImGUI, which runs at the very end of the frame
                  custom_const_buffer_data_1 = input_linear ? 2 : 1;
               }
               SetLumaConstantBuffers(native_device_context, cmd_list_data, device_data, reshade::api::shader_stage::pixel, LumaConstantBufferType::LumaSettings);
               SetLumaConstantBuffers(native_device_context, cmd_list_data, device_data, reshade::api::shader_stage::pixel, LumaConstantBufferType::LumaData, custom_const_buffer_data_1, custom_const_buffer_data_2);
            }

            // Set UI texture (limited by "DrawStateStackType::SimpleGraphics")
            ID3D11ShaderResourceView* const ui_texture_srv_const = ui_needs_composition ? device_data.ui_texture_srv.get() : nullptr;
            native_device_context->PSSetShaderResources(1, 1, &ui_texture_srv_const);

            // Set the sampler, in case we needed it (limited by "DrawStateStackType::SimpleGraphics")
#if !DEVELOPMENT // This can be useful to debug draw textures too
            if (wants_mips)
#endif // !DEVELOPMENT
            {
               ID3D11SamplerState* const default_sampler_state = device_data.default_sampler_state.get();
               native_device_context->PSSetSamplers(0, 1, &default_sampler_state);
            }

            // Note: we don't need to re-apply our custom cbuffers in most games (e.g. Prey), they are on indexes that are never used by the game's code
            DrawCustomPixelShader(native_device_context, device_data.default_depth_stencil_state.get(), device_data.default_blend_state.get(), device_data.copy_vertex_shader.get(), device_data.display_composition_pixel_shader.get(), device_data.display_composition_srv.get(), target_resource_texture_view.get(), target_desc.Width, target_desc.Height, false);

#if DEVELOPMENT
            const std::shared_lock lock_trace(s_mutex_trace);
            if (trace_running)
            {
               const std::unique_lock lock_trace_2(cmd_list_data.mutex_trace);
               TraceDrawCallData trace_draw_call_data;
               trace_draw_call_data.type = TraceDrawCallData::TraceDrawCallType::Custom;
               trace_draw_call_data.command_list = native_device_context;
               trace_draw_call_data.custom_name = "Luma Display Composition";
               cmd_list_data.trace_draw_calls_data.push_back(trace_draw_call_data);
            }
#endif // DEVELOPMENT

            if (ui_needs_composition)
            {
               const FLOAT ColorRGBA[4] = { 0.f, 0.f, 0.f, 0.f };
               native_device_context->ClearRenderTargetView(device_data.ui_texture_rtv.get(), ColorRGBA);
            }

            draw_state_stack.Restore(native_device_context);
         }
         else
         {
#if DEVELOPMENT
            ASSERT_ONCE_MSG(false, "The display composition Luma native shaders failed to be found (they have either been unloaded or failed to compile, or simply missing in the files)");
#else // !DEVELOPMENT
            static std::atomic<bool> warning_sent;
            if (!warning_sent.exchange(true))
            {
               const std::string warn_message = "Some of the shader files are missing from the \"" + std::string(NAME) + "\" folder, or failed to compile for some unknown reason, please re-install the mod.";
               HWND window = game_window;
#if 1 // This can hang the game on boot in Prey, without even showing the warning, it probably can in other games too, the message will appear on top anyway
               window = 0;
#endif
               MessageBoxA(window, warn_message.c_str(), NAME, MB_SETFOREGROUND);
            }
#endif // DEVELOPMENT
         }
      }
      else
      {
         device_data.display_composition_texture = nullptr;
         device_data.display_composition_srv = nullptr;
         // Don't change the allocation number
         for (size_t i = 0; i < swapchain_data.display_composition_rtvs.size(); ++i)
         {
            swapchain_data.display_composition_rtvs[i] = nullptr;
         }
      }

#if DEVELOPMENT
      // Clear at the end of every frame and re-capture it in the next frame if its still available
      if (debug_draw_auto_clear_texture)
      {
         device_data.debug_draw_texture = nullptr;
         // Leave "debug_draw_texture_format" and "debug_draw_texture_size", we need that in ImGUI (we'd need to clear it after ImGUI if necessary, but we skip drawing it if the texture isn't valid)
      }
      debug_draw_pipeline_instance = 0;

#if 0 // Optionally clear it every frame, to remove it if it wasn't found (this needs to be done elsewhere for now, because we print it below)
      device_data.track_buffer_data = {};
#endif
      track_buffer_pipeline_instance = 0;
#endif // DEVELOPMENT
      
#if ENABLE_NGX
      // Re-init DLSS if user toggled the settings.
      // We wouldn't really need to do anything other than clearing "dlss_output_color",
      // but to avoid wasting memory allocated by DLSS texture and other resources, clear it up once disabled.
      // Note that we keep these textures in memory if the user temporarily changed away from an AA method that supports DLSS, or if users unloaded shaders (there's no reason to, and it'd cause stutters).
      if (device_data.dlss_sr != NGX::DLSS::HasInit(device_data.dlss_sr_handle))
      {
         if (device_data.dlss_sr)
         {
            com_ptr<IDXGIDevice> native_dxgi_device;
            HRESULT hr = native_device->QueryInterface(&native_dxgi_device);
            com_ptr<IDXGIAdapter> native_adapter;
            if (SUCCEEDED(hr))
            {
               hr = native_dxgi_device->GetAdapter(&native_adapter);
            }
            assert(SUCCEEDED(hr));

            device_data.dlss_sr = NGX::DLSS::Init(device_data.dlss_sr_handle, native_device, native_adapter.get()); // No need to update "dlss_sr_supported", it wouldn't have changed.
            if (!device_data.dlss_sr)
            {
               const std::unique_lock lock_reshade(s_mutex_reshade);
               dlss_sr = false; // Disable the global user setting if it's not supported (it's ok even if we pollute device and global data), we want to grey it out in the UI (there's no need to serialize the new value for it though!)
            }
         }
         else
         {
            device_data.dlss_output_color = nullptr;
            device_data.dlss_exposure = nullptr;
            device_data.dlss_render_resolution_scale = 1.f; // Reset this to 1 when DLSS is toggled, even if dynamic resolution scaling is active (e.g. in Prey), we'll set it back to a low value if DRS is used again.
            device_data.dlss_scene_exposure = 1.f;
            device_data.dlss_scene_pre_exposure = 1.f;
            game->CleanExtraDLSSResources(device_data);
#if 0 // This would actually unload the DLSS DLL and all, making the game hitch, so it's better to just keep it in memory
            NGX::DLSS::Deinit(device_data.dlss_sr_handle);
#endif
         }
      }
#endif // ENABLE_NGX

      device_data.has_drawn_dlss_sr_imgui = device_data.has_drawn_dlss_sr;

      game->OnPresent(native_device, device_data);

#if DEVELOPMENT
      {
         const std::shared_lock lock_trace(s_mutex_trace);
         if (trace_running)
         {
            CommandListData& cmd_list_data = *queue->get_immediate_command_list()->get_private_data<CommandListData>();
            const std::unique_lock lock_trace_2(cmd_list_data.mutex_trace);
            TraceDrawCallData trace_draw_call_data;
            trace_draw_call_data.type = TraceDrawCallData::TraceDrawCallType::Present;
            trace_draw_call_data.command_list = native_device_context;
            cmd_list_data.trace_draw_calls_data.push_back(trace_draw_call_data);
         }
      }
#endif // DEVELOPMENT

      cb_luma_global_settings.FrameIndex++;
      device_data.cb_luma_global_settings_dirty = true;

#if RESHADE_API_VERSION >= 18
      return false;
#endif
   }

   //TODOFT3: merge all the shader permutations that use the same code in Prey (and then move shader binaries to bin folder? Add shader files to VS project?)

   // Return false to prevent the original draw call from running (e.g. if you replaced it or just want to skip it)
   // Most games (e.g. Prey, Dishonored 2) always draw in direct mode (as opposed to indirect), but uses different command lists on different threads (e.g. on Prey, that's almost only used for the shadow projection maps, in Dishonored 2, for almost every separate pass).
   // Usually there's a few compute shaders but most passes are "classic" pixel shaders.
   // If we ever wanted to still run the game's original draw call (first) and then ours (second), we'd need to pass more arguments in this function (to replicate the draw call identically).
   bool OnDraw_Custom(reshade::api::command_list* cmd_list, bool is_dispatch /*= false*/)
   {
      const auto* device = cmd_list->get_device();
      auto device_api = device->get_api();
      ID3D11Device* native_device = (ID3D11Device*)(device->get_native());
      ID3D11DeviceContext* native_device_context = (ID3D11DeviceContext*)(cmd_list->get_native());
      DeviceData& device_data = *device->get_private_data<DeviceData>();

      // Only for custom shaders
      reshade::api::shader_stage stages = reshade::api::shader_stage(0); // None

      bool is_custom_pass = false;
      bool updated_cbuffers = false;

      CommandListData& cmd_list_data = *cmd_list->get_private_data<CommandListData>();

      const auto& original_shader_hashes = is_dispatch ? cmd_list_data.pipeline_state_original_compute_shader_hashes : cmd_list_data.pipeline_state_original_graphics_shader_hashes;

      if (is_dispatch)
      {
         is_custom_pass = cmd_list_data.pipeline_state_has_custom_compute_shader;
         if (!original_shader_hashes.compute_shaders.empty())
         {
            stages = reshade::api::shader_stage::compute;
         }
      }
      else
      {
         is_custom_pass = cmd_list_data.pipeline_state_has_custom_graphics_shader;
         if (!original_shader_hashes.vertex_shaders.empty())
         {
            stages = reshade::api::shader_stage::vertex;
         }
         if (!original_shader_hashes.pixel_shaders.empty())
         {
            stages |= reshade::api::shader_stage::pixel;
         }
      }

#if DEVELOPMENT
      if (!cmd_list_data.is_primary)
      {
         // If these cases ever triggered, we can either cache assign all the commands for the deferred context without actually applying them, and then actually build the deferred context when it's merged, given that then we'd know the pipeline state it will inherit from the immediate context (e.g. whatever Render Targets or Shaders were set).
         // One partial solution is to replace shaders when they are created at binary level, instead of live swapping them, but we still won't be able to reliably write mod behaviours on the pipeline state given we don't know what the deferred context will inherit yet (until it's merged).
         if (is_dispatch)
         {
            if (!cmd_list_data.any_dispatch_done)
            {
               ASSERT_ONCE_MSG(!cmd_list_data.pipeline_state_original_compute_shader_hashes.compute_shaders.empty(),
                  "A dispatch was triggered on a fresh deferred device context without previously setting a compute shader, it could be that the engine relies on whatever pipeline state will be set on the immediate device context at the time of joining the deferred context");

               bool any_uav = false;
               com_ptr<ID3D11UnorderedAccessView> uavs[D3D11_1_UAV_SLOT_COUNT];
               native_device_context->CSGetUnorderedAccessViews(0, device_data.uav_max_count, &uavs[0]);
               for (UINT i = 0; i < device_data.uav_max_count; i++)
               {
                  if (uavs[i] != nullptr)
                  {
                     any_uav = true;
                     break;
                  }
               }
               ASSERT_ONCE_MSG(any_uav, "A dispatch was triggered on a fresh deferred device context without any UAVs bound, that is suspicious and might be a hint that the engine relies on inheriting the immediate device context state at the time of joining (later)");
            }
         }
         else
         {
            if (!cmd_list_data.any_dispatch_done)
            {
               ASSERT_ONCE_MSG(!cmd_list_data.pipeline_state_original_graphics_shader_hashes.pixel_shaders.empty() || !cmd_list_data.pipeline_state_original_graphics_shader_hashes.vertex_shaders.empty(),
                  "A draw was triggered on a fresh deferred device context without previously setting a vertex/pixel shader, it could be that the engine relies on whatever pipeline state will be set on the immediate device context at the time of joining the deferred context");

               bool any_rtv_or_dsv_or_uav = false;
               com_ptr<ID3D11RenderTargetView> rtvs[D3D11_SIMULTANEOUS_RENDER_TARGET_COUNT];
               com_ptr<ID3D11UnorderedAccessView> uavs[D3D11_1_UAV_SLOT_COUNT];
               com_ptr<ID3D11DepthStencilView> dsv;
               native_device_context->OMGetRenderTargetsAndUnorderedAccessViews(D3D11_SIMULTANEOUS_RENDER_TARGET_COUNT, &rtvs[0], &dsv, 0, device_data.uav_max_count, &uavs[0]);
               for (UINT i = 0; i < D3D11_SIMULTANEOUS_RENDER_TARGET_COUNT; i++)
               {
                  if (rtvs[i] != nullptr)
                  {
                     any_rtv_or_dsv_or_uav = true;
                     break;
                  }
               }
               if (dsv != nullptr)
               {
                  any_rtv_or_dsv_or_uav = true;
               }
               for (UINT i = 0; i < (any_rtv_or_dsv_or_uav ? 0 : device_data.uav_max_count); i++)
               {
                  if (uavs[i] != nullptr)
                  {
                     any_rtv_or_dsv_or_uav = true;
                     break;
                  }
               }
               ASSERT_ONCE_MSG(any_rtv_or_dsv_or_uav, "A draw was triggered on a fresh deferred device context without any RTVs/DSV/UAVs bound, that is suspicious and might be a hint that the engine relies on inheriting the immediate device context state at the time of joining (later)");
            }
         }
      }

      if (is_dispatch)
      {
         last_drawn_shader = cmd_list_data.pipeline_state_original_compute_shader_hashes.compute_shaders.empty() ? "" : Shader::Hash_NumToStr(*cmd_list_data.pipeline_state_original_compute_shader_hashes.compute_shaders.begin()); // String hash to int
         cmd_list_data.any_dispatch_done = true;
      }
      else
      {
         last_drawn_shader = cmd_list_data.pipeline_state_original_graphics_shader_hashes.pixel_shaders.empty() ? "" : Shader::Hash_NumToStr(*cmd_list_data.pipeline_state_original_graphics_shader_hashes.pixel_shaders.begin()); // String hash to int
         cmd_list_data.any_draw_done = true;
      }
      thread_local_cmd_list = cmd_list;

      {
         // Do this before any custom code runs as the state might change
         const std::shared_lock lock_trace(s_mutex_trace);
         if (trace_running)
         {
            const std::shared_lock lock_generic(s_mutex_generic);
            const std::unique_lock lock_trace_2(cmd_list_data.mutex_trace);
            const std::lock_guard<std::recursive_mutex> lock_dumping(s_mutex_dumping);
            ASSERT_ONCE(native_device_context);
            if (is_dispatch)
            {
               AddTraceDrawCallData(cmd_list_data.trace_draw_calls_data, device_data, native_device_context, cmd_list_data.pipeline_state_original_compute_shader.handle, shader_cache);
            }
            else
            {
               AddTraceDrawCallData(cmd_list_data.trace_draw_calls_data, device_data, native_device_context, cmd_list_data.pipeline_state_original_vertex_shader.handle, shader_cache);
               if (cmd_list_data.pipeline_state_original_pixel_shader.handle != 0) // Somehow this can happen (e.g. query tests don't require pixel shaders)
               {
                  AddTraceDrawCallData(cmd_list_data.trace_draw_calls_data, device_data, native_device_context, cmd_list_data.pipeline_state_original_pixel_shader.handle, shader_cache);
               }
            }
         }
      }
#endif //DEVELOPMENT

      const bool mod_active = device_data.cloned_pipeline_count != 0;
      if (enable_ui_separation && mod_active && ((device_data.has_drawn_main_post_processing && native_device_context->GetType() == D3D11_DEVICE_CONTEXT_IMMEDIATE && !original_shader_hashes.Contains(shader_hashes_UI_excluded)) || original_shader_hashes.Contains(shader_hashes_UI)))
      {
         ID3D11RenderTargetView* const ui_texture_rtv_const = device_data.ui_texture_rtv.get();
         native_device_context->OMSetRenderTargets(1, &ui_texture_rtv_const, nullptr); // Note: for now we don't restore this back to the original value, as we haven't found any game that reads back the RT, or doesn't set it every frame or draw call
      }

      const bool had_drawn_main_post_processing = device_data.has_drawn_main_post_processing;

      if (!original_shader_hashes.Empty())
      {
         //TODOFT: optimize these shader searches by simply marking "CachedPipeline" with a tag on what they are (and whether they have a particular role) (also we can restrict the search to pixel shaders or compute shaders?) upfront. And move these into their own functions. Update: we optimized this enough.

         if (test_index == 9) return false;
         if (game->OnDrawCustom(native_device, native_device_context, cmd_list_data, device_data, stages, original_shader_hashes, is_custom_pass, updated_cbuffers))
         {
            return true;
         }
      }

      // We have a way to track whether this data changed to avoid sending them again when not necessary, we could further optimize it by adding a flag to the shader hashes that need the cbuffers, but it really wouldn't help much
      if (is_custom_pass && !updated_cbuffers)
      {
         SetLumaConstantBuffers(native_device_context, cmd_list_data, device_data, stages, LumaConstantBufferType::LumaSettings);
         SetLumaConstantBuffers(native_device_context, cmd_list_data, device_data, stages, LumaConstantBufferType::LumaData);
         updated_cbuffers = true;
      }

#if !DEVELOPMENT || !GAME_PREY //TODOFT2: re-enable once we are sure we replaced all the post tonemap shaders and we are done debugging the blend states. Compute Shaders are also never used in UI and by all stuff below...!!!
      if (!is_custom_pass) return false;
#else // ("GAME_PREY") We can't do any further checks in this case because some UI draws at the beginning of the frame (in world computers, in Prey), and sometimes the scene doesn't draw, but we still need to update the cbuffers (though maybe we could clear it up on present, to avoid problems)
      //if (device_data.has_drawn_main_post_processing_previous && !device_data.has_drawn_main_post_processing) return false;
#endif // !DEVELOPMENT

      // Skip the rest in cases where the UI isn't passing through our custom linear blends that emulate SDR gamma->gamma blends.
      if (GetShaderDefineCompiledNumericalValue(UI_DRAW_TYPE_HASH) != 1) return false;

      CB::LumaUIDataPadded ui_data = {};

      com_ptr<ID3D11RenderTargetView> render_target_view;
      // Theoretically we should also retrieve the UAVs and all other RTs but in reality it doesn't ever really matter
      native_device_context->OMGetRenderTargets(1, &render_target_view, nullptr);
      if (render_target_view)
      {
         com_ptr<ID3D11Resource> render_target_resource;
         render_target_view->GetResource(&render_target_resource);
         if (render_target_resource != nullptr)
         {
            bool targeting_swapchain;
            {
               const std::shared_lock lock(device_data.mutex);
               targeting_swapchain = device_data.back_buffers.contains((uint64_t)render_target_resource.get());
            }
            // We check across all the swap chain back buffers, not just the one that will be presented this frame (we have no 100% of what swapchain will draw this frame).
            // Note that some games (e.g. Prey) compose the UI in separate render targets to then be drawn into the world (e.g. in game interactive computer screens), but these usually don't draw on any of the swapchain buffers.
            if (targeting_swapchain)
            {
               ui_data.targeting_swapchain = 1;

               const bool paused = game->IsGamePaused(device_data);
               // Highlight that the game is paused or that we are in a menu with no scene rendering (e.g. allows us to fully skip lens distortion on the UI, as sometimes it'd apply in loading screen menus).
               if (paused || !device_data.has_drawn_main_post_processing)
               {
                  ui_data.fullscreen_menu = 1;
               }
            }
            render_target_resource = nullptr;
         }
         render_target_view = nullptr;
      }

      // No need to lock "s_mutex_reshade" for "cb_luma_global_settings" here, it's not relevant
      // We could use "has_drawn_composed_gbuffers" here instead of "has_drawn_main_post_processing", but then again, they should always match (pp should always be run)
      ui_data.background_tonemapping_amount = (cb_luma_global_settings.DisplayMode == 1 && device_data.has_drawn_main_post_processing_previous && ui_data.targeting_swapchain) ? game->GetTonemapUIBackgroundAmount(device_data) : 0.0;

      com_ptr<ID3D11BlendState> blend_state;
      native_device_context->OMGetBlendState(&blend_state, nullptr, nullptr);
      if (blend_state)
      {
         D3D11_BLEND_DESC blend_desc;
         blend_state->GetDesc(&blend_desc);
         // Mirrored from UI shaders:
         // 0 No alpha blend (or other unknown blend types that we can ignore)
         // 1 Straight alpha blend: "result = (source.RGB * source.A) + (dest.RGB * (1 - source.A))" or "result = lerp(dest.RGB, source.RGB, source.A)"
         // 2 Pre-multiplied alpha blend (alpha is also pre-multiplied, not just rgb): "result = source.RGB + (dest.RGB * (1 - source.A))"
         // 3 Additive alpha blend (source is "Straight alpha" while destination is retained at 100%): "result = (source.RGB * source.A) + dest.RGB"
         // 4 Additive blend (source and destination are simply summed up, ignoring the alpha): result = source.RGB + dest.RGB
         // 
         // We don't care for the alpha blend operation (source alpha * dest alpha) as alpha is never read back from destination
         if (blend_desc.RenderTarget[0].BlendEnable
            && blend_desc.RenderTarget[0].BlendOp == D3D11_BLEND_OP::D3D11_BLEND_OP_ADD)
         {
            // Do both the "straight alpha" and "pre-multiplied alpha" cases
            if ((blend_desc.RenderTarget[0].SrcBlend == D3D11_BLEND::D3D11_BLEND_SRC_ALPHA || blend_desc.RenderTarget[0].SrcBlend == D3D11_BLEND::D3D11_BLEND_ONE)
               && (blend_desc.RenderTarget[0].DestBlend == D3D11_BLEND::D3D11_BLEND_INV_SRC_ALPHA || blend_desc.RenderTarget[0].DestBlend == D3D11_BLEND::D3D11_BLEND_ONE))
            {
               if (blend_desc.RenderTarget[0].SrcBlend == D3D11_BLEND::D3D11_BLEND_ONE && blend_desc.RenderTarget[0].DestBlend == D3D11_BLEND::D3D11_BLEND_ONE)
               {
                  ui_data.blend_mode = 4;
               }
               else if (blend_desc.RenderTarget[0].SrcBlend == D3D11_BLEND::D3D11_BLEND_SRC_ALPHA && blend_desc.RenderTarget[0].DestBlend == D3D11_BLEND::D3D11_BLEND_ONE)
               {
                  ui_data.blend_mode = 3;
               }
               else if (blend_desc.RenderTarget[0].SrcBlend == D3D11_BLEND::D3D11_BLEND_ONE && blend_desc.RenderTarget[0].DestBlend == D3D11_BLEND::D3D11_BLEND_INV_SRC_ALPHA)
               {
                  ui_data.blend_mode = 2;
               }
               else /*if (blend_desc.RenderTarget[0].SrcBlend == D3D11_BLEND::D3D11_BLEND_SRC_ALPHA && blend_desc.RenderTarget[0].DestBlend == D3D11_BLEND::D3D11_BLEND_INV_SRC_ALPHA)*/
               {
                  ui_data.blend_mode = 1;
#if GAME_PREY
                  assert(!had_drawn_main_post_processing || !ui_data.targeting_swapchain || (blend_desc.RenderTarget[0].SrcBlend == D3D11_BLEND::D3D11_BLEND_SRC_ALPHA && blend_desc.RenderTarget[0].DestBlend == D3D11_BLEND::D3D11_BLEND_INV_SRC_ALPHA));
#endif // GAME_PREY
               }
#if GAME_PREY
               //if (ui_data.blend_mode == 1 || ui_data.blend_mode == 3) // Old check
               {
                  // In "blend_mode == 1", Prey seems to erroneously use "D3D11_BLEND::D3D11_BLEND_SRC_ALPHA" as source blend alpha, thus it multiplies alpha by itself when using pre-multiplied alpha passes,
                  // which doesn't seem to make much sense, at least not for the first write on a separate new texture (it means that the next blend with the final target background could end up going beyond 1 because the background darkening intensity is lower than it should be).
                  ASSERT_ONCE(!had_drawn_main_post_processing || (ui_data.targeting_swapchain ?
                     // Make sure we never read back from the swap chain texture (which means we can ignore all the alpha blend ops on previous to it)
                     (blend_desc.RenderTarget[0].SrcBlend != D3D11_BLEND::D3D11_BLEND_DEST_ALPHA
                        && blend_desc.RenderTarget[0].DestBlend != D3D11_BLEND::D3D11_BLEND_DEST_ALPHA
                        && blend_desc.RenderTarget[0].SrcBlend != D3D11_BLEND::D3D11_BLEND_DEST_COLOR
                        && blend_desc.RenderTarget[0].DestBlend != D3D11_BLEND::D3D11_BLEND_DEST_COLOR)
                     // Make sure that writes to separate textures always use known alpha blends modes, because we'll be reading back that alpha for later (possibly)
                     : (blend_desc.RenderTarget[0].BlendOpAlpha == D3D11_BLEND_OP::D3D11_BLEND_OP_ADD
                        && (blend_desc.RenderTarget[0].SrcBlendAlpha == D3D11_BLEND::D3D11_BLEND_SRC_ALPHA
                           || blend_desc.RenderTarget[0].SrcBlendAlpha == D3D11_BLEND::D3D11_BLEND_ONE))));
               }
#endif // GAME_PREY
            }
            else
            {
               ASSERT_ONCE(!had_drawn_main_post_processing || !ui_data.targeting_swapchain);
            }
         }
         assert(!had_drawn_main_post_processing || !ui_data.targeting_swapchain || !blend_desc.RenderTarget[0].BlendEnable || blend_desc.RenderTarget[0].BlendOp == D3D11_BLEND_OP::D3D11_BLEND_OP_ADD);
         blend_state = nullptr;
      }

      if (is_custom_pass && luma_ui_cbuffer_index < D3D11_COMMONSHADER_CONSTANT_BUFFER_API_SLOT_COUNT)
      {
         if (memcmp(&device_data.cb_luma_ui_data, &ui_data, sizeof(ui_data)) != 0)
         {
            device_data.cb_luma_ui_data = ui_data;
            if (D3D11_MAPPED_SUBRESOURCE mapped_buffer;
               SUCCEEDED(native_device_context->Map(device_data.luma_ui_data.get(), 0, D3D11_MAP_WRITE_DISCARD, 0, &mapped_buffer)))
            {
               std::memcpy(mapped_buffer.pData, &device_data.cb_luma_ui_data, sizeof(device_data.cb_luma_ui_data));
               native_device_context->Unmap(device_data.luma_ui_data.get(), 0);
            }
         }

         ID3D11Buffer* const buffer = device_data.luma_ui_data.get();
         if ((stages & reshade::api::shader_stage::vertex) == reshade::api::shader_stage::vertex)
            native_device_context->VSSetConstantBuffers(luma_ui_cbuffer_index, 1, &buffer);
         if ((stages & reshade::api::shader_stage::geometry) == reshade::api::shader_stage::geometry)
            native_device_context->GSSetConstantBuffers(luma_ui_cbuffer_index, 1, &buffer);
         if ((stages & reshade::api::shader_stage::pixel) == reshade::api::shader_stage::pixel)
            native_device_context->PSSetConstantBuffers(luma_ui_cbuffer_index, 1, &buffer);
         if ((stages & reshade::api::shader_stage::compute) == reshade::api::shader_stage::compute)
            native_device_context->CSSetConstantBuffers(luma_ui_cbuffer_index, 1, &buffer);
      }

      return false; // Return true to cancel this draw call
   }

#if DEVELOPMENT
   bool HandlePipelineRedirections(ID3D11DeviceContext* native_device_context, const DeviceData& device_data, const CommandListData& cmd_list_data, bool is_dispatch, std::function<void()>& draw_func)
   {
      CachedPipeline::RedirectData redirect_data;
      if (is_dispatch)
      {
         const std::shared_lock lock(s_mutex_generic);
         const auto pipeline_pair = device_data.pipeline_cache_by_pipeline_handle.find(cmd_list_data.pipeline_state_original_compute_shader.handle);
         if (pipeline_pair != device_data.pipeline_cache_by_pipeline_handle.end() && pipeline_pair->second != nullptr)
         {
            redirect_data = pipeline_pair->second->redirect_data;
         }
      }
      else
      {
         const std::shared_lock lock(s_mutex_generic);
         const auto pipeline_pair = device_data.pipeline_cache_by_pipeline_handle.find(cmd_list_data.pipeline_state_original_pixel_shader.handle);
         if (pipeline_pair != device_data.pipeline_cache_by_pipeline_handle.end() && pipeline_pair->second != nullptr)
         {
            redirect_data = pipeline_pair->second->redirect_data;
         }
      }

      if (redirect_data.source_type != CachedPipeline::RedirectData::RedirectSourceType::None && redirect_data.target_type != CachedPipeline::RedirectData::RedirectTargetType::None)
      {
			com_ptr<ID3D11Resource> source_resource;
         com_ptr<ID3D11Resource> target_resource;

         switch (redirect_data.source_type)
         {
         case CachedPipeline::RedirectData::RedirectSourceType::SRV:
         {
            if (redirect_data.source_index >= 0 && redirect_data.source_index < D3D11_COMMONSHADER_INPUT_RESOURCE_SLOT_COUNT)
            {
               com_ptr<ID3D11ShaderResourceView> srv;
               if (is_dispatch)
                  native_device_context->CSGetShaderResources(redirect_data.source_index, 1, &srv);
               else
                  native_device_context->PSGetShaderResources(redirect_data.source_index, 1, &srv);
               if (srv)
                  srv->GetResource(&source_resource);
            }
         }
			break;
         case CachedPipeline::RedirectData::RedirectSourceType::UAV:
         {
            com_ptr<ID3D11UnorderedAccessView> uav;
            if (is_dispatch)
            {
               if (redirect_data.source_index >= 0 && redirect_data.source_index < D3D11_1_UAV_SLOT_COUNT)
                  native_device_context->CSGetUnorderedAccessViews(redirect_data.source_index, 1, &uav);
            }
            else
            {
               if (redirect_data.source_index >= 0 && redirect_data.source_index < D3D11_1_UAV_SLOT_COUNT)
                  native_device_context->OMGetRenderTargetsAndUnorderedAccessViews(0, nullptr, nullptr, redirect_data.source_index, 1, &uav);
            }
            if (uav)
               uav->GetResource(&source_resource);
         }
         break;
         }

         switch (redirect_data.target_type)
         {
         case CachedPipeline::RedirectData::RedirectTargetType::RTV:
         {
            if (redirect_data.target_index >= 0 && redirect_data.target_index < D3D11_SIMULTANEOUS_RENDER_TARGET_COUNT && !is_dispatch)
            {
               com_ptr<ID3D11RenderTargetView> rtvs[D3D11_SIMULTANEOUS_RENDER_TARGET_COUNT];
               native_device_context->OMGetRenderTargets(D3D11_SIMULTANEOUS_RENDER_TARGET_COUNT, &rtvs[0], nullptr);
               if (rtvs[redirect_data.target_index])
						rtvs[redirect_data.target_index]->GetResource(&target_resource);
            }
         }
         break;
         case CachedPipeline::RedirectData::RedirectTargetType::UAV:
         {
            com_ptr<ID3D11UnorderedAccessView> uav;
            if (is_dispatch)
            {
               if (redirect_data.target_index >= 0 && redirect_data.target_index < D3D11_1_UAV_SLOT_COUNT)
                  native_device_context->CSGetUnorderedAccessViews(redirect_data.target_index, 1, &uav);
            }
            else
            {
               if (redirect_data.target_index >= 0 && redirect_data.target_index < D3D11_1_UAV_SLOT_COUNT)
                  native_device_context->OMGetRenderTargetsAndUnorderedAccessViews(0, nullptr, nullptr, redirect_data.target_index, 1, &uav);
            }
            if (uav)
               uav->GetResource(&target_resource);
         }
         break;
         }

         // TODO: fall back to pixel shader if the formats/sizes are not compatible? Otherwise add a safety check to avoid crashing (it doesn't seem to)
         if (source_resource.get() && target_resource.get() && source_resource.get() != target_resource.get())
         {
#if 0 // We don't actually need to force run the original draw call
            draw_func();
#endif
            native_device_context->CopyResource(target_resource.get(), source_resource.get());
            return true; // Make sure the original draw call is cancelled, otherwise the target resource would get overwritten
         }
      }

      return false;
   }
#endif //DEVELOPMENT

   bool OnDraw(
      reshade::api::command_list* cmd_list,
      uint32_t vertex_count,
      uint32_t instance_count,
      uint32_t first_vertex,
      uint32_t first_instance)
   {
#if DEVELOPMENT
      CommandListData& cmd_list_data = *cmd_list->get_private_data<CommandListData>();
      ID3D11DeviceContext* native_device_context = (ID3D11DeviceContext*)(cmd_list->get_native());
      DeviceData& device_data = *cmd_list->get_device()->get_private_data<DeviceData>();

      bool wants_debug_draw = debug_draw_shader_hash != 0 || debug_draw_pipeline != 0;
		wants_debug_draw &= (debug_draw_pipeline == 0 || debug_draw_pipeline == cmd_list_data.pipeline_state_original_pixel_shader.handle);

      DrawStateStack pre_draw_state_stack;
      if (wants_debug_draw)
      {
         pre_draw_state_stack.Cache(native_device_context, device_data.uav_max_count);
      }

      std::function<void()> draw_lambda = [&]()
         {
            if (instance_count > 1)
            {
               native_device_context->DrawInstanced(vertex_count, instance_count, first_vertex, first_instance);
            }
            else
            {
               ASSERT_ONCE(first_instance == 0);
               native_device_context->Draw(vertex_count, first_vertex);
            }
         };
#endif
      // TODO: add performance tracing around these
      bool cancelled_or_replaced = OnDraw_Custom(cmd_list, false);
#if DEVELOPMENT
#if 0 // TODO: We should do this manually when replacing each draw call, we don't know if it was replaced or cancelled here
      {
         const std::shared_lock lock_trace(s_mutex_trace);
         if (cancelled_or_replaced && trace_running)
         {
            const std::shared_lock lock_generic(s_mutex_generic);
            const std::unique_lock lock_trace_2(cmd_list_data.mutex_trace);
            if (cmd_list_data.pipeline_state_original_pixel_shader.handle != 0)
            {
               cmd_list_data.trace_draw_calls_data[cmd_list_data.trace_draw_calls_data.size() - 1].skipped = true;
            }
         }
      }
#endif

      // First run the draw call (don't delegate it to ReShade) and then copy its output
      if (wants_debug_draw && (debug_draw_shader_hash == 0 || cmd_list_data.pipeline_state_original_graphics_shader_hashes.Contains(debug_draw_shader_hash, reshade::api::shader_stage::pixel)))
      {
         auto local_debug_draw_pipeline_instance = debug_draw_pipeline_instance.fetch_add(1);
         // TODO: make the "debug_draw_pipeline_target_instance" and "track_buffer_pipeline_target_instance" by thread (and command list) too, though it's rarely useful
         if (debug_draw_pipeline_target_instance == -1 || local_debug_draw_pipeline_instance == debug_draw_pipeline_target_instance)
         {
            DrawStateStack post_draw_state_stack;

            if (!cancelled_or_replaced)
            {
               draw_lambda();
            }
            else if (!debug_draw_replaced_pass)
            {
               post_draw_state_stack.Cache(native_device_context, device_data.uav_max_count);
               pre_draw_state_stack.Restore(native_device_context);
            }

            CopyDebugDrawTexture(debug_draw_mode, debug_draw_view_index, cmd_list, false);

            if (cancelled_or_replaced && !debug_draw_replaced_pass)
            {
               post_draw_state_stack.Restore(native_device_context);
            }
            cancelled_or_replaced = true;
         }
      }
      bool track_buffer_pipeline_ps = track_buffer_pipeline == cmd_list_data.pipeline_state_original_pixel_shader.handle;
      bool track_buffer_pipeline_vs = track_buffer_pipeline == cmd_list_data.pipeline_state_original_vertex_shader.handle;
      if (track_buffer_pipeline != 0 && (track_buffer_pipeline_ps || track_buffer_pipeline_vs))
      {
         auto local_track_buffer_pipeline_instance = track_buffer_pipeline_instance.fetch_add(1);
         if (track_buffer_pipeline_target_instance == -1 || local_track_buffer_pipeline_instance == track_buffer_pipeline_target_instance)
         {
            com_ptr<ID3D11Buffer> cb;
            if (track_buffer_pipeline_ps)
            {
               native_device_context->PSGetConstantBuffers(track_buffer_index, 1, &cb);
            }
            else if (track_buffer_pipeline_vs)
            {
               native_device_context->VSGetConstantBuffers(track_buffer_index, 1, &cb);
            }
            // Copy the buffer in our data
            CopyBuffer(cb, native_device_context, device_data.track_buffer_data.data);
            device_data.track_buffer_data.hash = std::to_string(std::hash<void*>{}(cb.get()));
         }
      }
      if (cancelled_or_replaced)
      {
         // Cancel the lambda as we've already drawn once, we don't want to do it further below
         draw_lambda = []() {};
      }

      cancelled_or_replaced |= HandlePipelineRedirections(native_device_context, device_data, cmd_list_data, false, draw_lambda);
#endif
      return cancelled_or_replaced;
   }

   bool OnDrawIndexed(
      reshade::api::command_list* cmd_list,
      uint32_t index_count,
      uint32_t instance_count,
      uint32_t first_index,
      int32_t vertex_offset,
      uint32_t first_instance)
   {
#if DEVELOPMENT
      CommandListData& cmd_list_data = *cmd_list->get_private_data<CommandListData>();
      ID3D11DeviceContext* native_device_context = (ID3D11DeviceContext*)(cmd_list->get_native());
      DeviceData& device_data = *cmd_list->get_device()->get_private_data<DeviceData>();

      bool wants_debug_draw = debug_draw_shader_hash != 0 || debug_draw_pipeline != 0;
      wants_debug_draw &= (debug_draw_pipeline == 0 || debug_draw_pipeline == cmd_list_data.pipeline_state_original_pixel_shader.handle);

      DrawStateStack pre_draw_state_stack;
      if (wants_debug_draw)
      {
         pre_draw_state_stack.Cache(native_device_context, device_data.uav_max_count);
      }

      std::function<void()> draw_lambda = [&]()
         {
            if (instance_count > 1)
            {
               native_device_context->DrawIndexedInstanced(index_count, instance_count, first_index, vertex_offset, first_instance);
            }
            else
            {
               ASSERT_ONCE(first_instance == 0);
               native_device_context->DrawIndexed(index_count, first_index, vertex_offset);
            }
         };
#endif
      bool cancelled_or_replaced = OnDraw_Custom(cmd_list, false);
#if DEVELOPMENT
      // First run the draw call (don't delegate it to ReShade) and then copy its output
      if (wants_debug_draw && (debug_draw_shader_hash == 0 || cmd_list_data.pipeline_state_original_graphics_shader_hashes.Contains(debug_draw_shader_hash, reshade::api::shader_stage::pixel)))
      {
         auto local_debug_draw_pipeline_instance = debug_draw_pipeline_instance.fetch_add(1);
         if (debug_draw_pipeline_target_instance == -1 || local_debug_draw_pipeline_instance == debug_draw_pipeline_target_instance)
         {
            DrawStateStack post_draw_state_stack;

            if (!cancelled_or_replaced)
            {
               draw_lambda();
            }
            else if (!debug_draw_replaced_pass)
            {
               post_draw_state_stack.Cache(native_device_context, device_data.uav_max_count);
               pre_draw_state_stack.Restore(native_device_context);
            }

            CopyDebugDrawTexture(debug_draw_mode, debug_draw_view_index, cmd_list, false);

            if (cancelled_or_replaced && !debug_draw_replaced_pass)
            {
               post_draw_state_stack.Restore(native_device_context);
            }
            cancelled_or_replaced = true;
         }
      }
      bool track_buffer_pipeline_ps = track_buffer_pipeline == cmd_list_data.pipeline_state_original_pixel_shader.handle;
      bool track_buffer_pipeline_vs = track_buffer_pipeline == cmd_list_data.pipeline_state_original_vertex_shader.handle;
      if (track_buffer_pipeline != 0 && (track_buffer_pipeline_ps || track_buffer_pipeline_vs))
      {
         auto local_track_buffer_pipeline_instance = track_buffer_pipeline_instance.fetch_add(1);
         if (track_buffer_pipeline_target_instance == -1 || local_track_buffer_pipeline_instance == track_buffer_pipeline_target_instance)
         {
            com_ptr<ID3D11Buffer> cb;
            if (track_buffer_pipeline_ps)
            {
               native_device_context->PSGetConstantBuffers(track_buffer_index, 1, &cb);
            }
            else if (track_buffer_pipeline_vs)
            {
               native_device_context->VSGetConstantBuffers(track_buffer_index, 1, &cb);
            }
            // Copy the buffer in our data
            CopyBuffer(cb, native_device_context, device_data.track_buffer_data.data);
            device_data.track_buffer_data.hash = std::to_string(std::hash<void*>{}(cb.get()));
         }
      }
      if (cancelled_or_replaced)
      {
         // Cancel the lambda as we've already drawn once, we don't want to do it further below
         draw_lambda = []() {};
      }

      cancelled_or_replaced |= HandlePipelineRedirections(native_device_context, device_data, cmd_list_data, false, draw_lambda);
#endif
      return cancelled_or_replaced;
   }

   bool OnDispatch(reshade::api::command_list* cmd_list, uint32_t group_count_x, uint32_t group_count_y, uint32_t group_count_z)
   {
#if DEVELOPMENT
      CommandListData& cmd_list_data = *cmd_list->get_private_data<CommandListData>();
      ID3D11DeviceContext* native_device_context = (ID3D11DeviceContext*)(cmd_list->get_native());
      DeviceData& device_data = *cmd_list->get_device()->get_private_data<DeviceData>();

      bool wants_debug_draw = debug_draw_shader_hash != 0 || debug_draw_pipeline != 0;
      wants_debug_draw &= (debug_draw_pipeline == 0 || debug_draw_pipeline == cmd_list_data.pipeline_state_original_compute_shader.handle);

      DrawStateStack<DrawStateStackType::Compute> pre_draw_state_stack;
      if (wants_debug_draw)
      {
         pre_draw_state_stack.Cache(native_device_context, device_data.uav_max_count);
      }

      std::function<void()> draw_lambda = [&]()
         {
            native_device_context->Dispatch(group_count_x, group_count_y, group_count_z);
         };
#endif
      bool cancelled_or_replaced = OnDraw_Custom(cmd_list, true);
#if DEVELOPMENT
      // First run the draw call (don't delegate it to ReShade) and then copy its output
      if (wants_debug_draw && (debug_draw_shader_hash == 0 || cmd_list_data.pipeline_state_original_compute_shader_hashes.Contains(debug_draw_shader_hash, reshade::api::shader_stage::compute)))
      {
         auto local_debug_draw_pipeline_instance = debug_draw_pipeline_instance.fetch_add(1);
         if (debug_draw_pipeline_target_instance == -1 || local_debug_draw_pipeline_instance == debug_draw_pipeline_target_instance)
         {
            DrawStateStack<DrawStateStackType::Compute> post_draw_state_stack;

            if (!cancelled_or_replaced)
            {
               draw_lambda();
            }
            else if (!debug_draw_replaced_pass)
            {
               post_draw_state_stack.Cache(native_device_context, device_data.uav_max_count);
               pre_draw_state_stack.Restore(native_device_context);
            }

            CopyDebugDrawTexture(debug_draw_mode, debug_draw_view_index, cmd_list, true);

            if (cancelled_or_replaced && !debug_draw_replaced_pass)
            {
               post_draw_state_stack.Restore(native_device_context);
            }
            cancelled_or_replaced = true;
         }
      }
      bool track_buffer_pipeline_cs = track_buffer_pipeline == cmd_list_data.pipeline_state_original_compute_shader.handle;
      if (track_buffer_pipeline != 0 && track_buffer_pipeline_cs)
      {
         auto local_track_buffer_pipeline_instance = track_buffer_pipeline_instance.fetch_add(1);
         if (track_buffer_pipeline_target_instance == -1 || local_track_buffer_pipeline_instance == track_buffer_pipeline_target_instance)
         {
            com_ptr<ID3D11Buffer> cb;
            native_device_context->CSGetConstantBuffers(track_buffer_index, 1, &cb);
            // Copy the buffer in our data
            CopyBuffer(cb, native_device_context, device_data.track_buffer_data.data);
            device_data.track_buffer_data.hash = std::to_string(std::hash<void*>{}(cb.get()));
         }
      }
      if (cancelled_or_replaced)
      {
         // Cancel the lambda as we've already drawn once, we don't want to do it further below
         draw_lambda = []() {};
      }

      cancelled_or_replaced |= HandlePipelineRedirections(native_device_context, device_data, cmd_list_data, true, draw_lambda);
#endif
      return cancelled_or_replaced;
   }

   bool OnDrawOrDispatchIndirect(
      reshade::api::command_list* cmd_list,
      reshade::api::indirect_command type,
      reshade::api::resource buffer,
      uint64_t offset,
      uint32_t draw_count,
      uint32_t stride)
   {
      // Not used by Dishonored 2 (DrawIndexedInstancedIndirect() and DrawInstancedIndirect() weren't used in Void Engine). Happens in Vertigo (Unity).
      const bool is_dispatch = type == reshade::api::indirect_command::dispatch;
      // Unsupported types (not used in DX11)
      ASSERT_ONCE(type != reshade::api::indirect_command::dispatch_mesh && type != reshade::api::indirect_command::dispatch_rays);
      // NOTE: according to ShortFuse, this can be "reshade::api::indirect_command::unknown" too, so we'd need to fall back on checking what shader is bound to know if this is a compute shader draw
      ASSERT_ONCE(type != reshade::api::indirect_command::unknown);

#if DEVELOPMENT
      CommandListData& cmd_list_data = *cmd_list->get_private_data<CommandListData>();
      ID3D11DeviceContext* native_device_context = (ID3D11DeviceContext*)(cmd_list->get_native());
      DeviceData& device_data = *cmd_list->get_device()->get_private_data<DeviceData>();

      bool wants_debug_draw = debug_draw_shader_hash != 0 || debug_draw_pipeline != 0;
      wants_debug_draw &= debug_draw_pipeline == 0 || debug_draw_pipeline == (is_dispatch ? cmd_list_data.pipeline_state_original_compute_shader.handle : cmd_list_data.pipeline_state_original_pixel_shader.handle);

      DrawStateStack<DrawStateStackType::FullGraphics> pre_draw_state_stack_graphics;
      DrawStateStack<DrawStateStackType::Compute> pre_draw_state_stack_compute;
      if (wants_debug_draw)
      {
         if (is_dispatch)
            pre_draw_state_stack_compute.Cache(native_device_context, device_data.uav_max_count);
         else
            pre_draw_state_stack_graphics.Cache(native_device_context, device_data.uav_max_count);
      }

      std::function<void()> draw_lambda = [&]()
         {
            // We only support one draw for now (it couldn't be otherwise in DX11)
            ASSERT_ONCE(draw_count == 1);
            uint32_t i = 0;

            if (is_dispatch)
            {
               native_device_context->DispatchIndirect(reinterpret_cast<ID3D11Buffer*>(buffer.handle), static_cast<UINT>(offset) + i * stride);
            }
            else
            {
               if (type == reshade::api::indirect_command::draw_indexed)
               {
                  native_device_context->DrawIndexedInstancedIndirect(reinterpret_cast<ID3D11Buffer*>(buffer.handle), static_cast<UINT>(offset) + i * stride);
               }
               else
               {
                  native_device_context->DrawInstancedIndirect(reinterpret_cast<ID3D11Buffer*>(buffer.handle), static_cast<UINT>(offset) + i * stride);
               }
            }
         };
#endif
      bool cancelled_or_replaced = OnDraw_Custom(cmd_list, is_dispatch);
#if DEVELOPMENT
      const auto& original_shader_hashes = is_dispatch ? cmd_list_data.pipeline_state_original_compute_shader_hashes : cmd_list_data.pipeline_state_original_graphics_shader_hashes;
      if (wants_debug_draw && (debug_draw_shader_hash == 0 || original_shader_hashes.Contains(debug_draw_shader_hash, is_dispatch ? reshade::api::shader_stage::compute : reshade::api::shader_stage::pixel)))
      {
         auto local_debug_draw_pipeline_instance = debug_draw_pipeline_instance.fetch_add(1);
         if (debug_draw_pipeline_target_instance == -1 || local_debug_draw_pipeline_instance == debug_draw_pipeline_target_instance)
         {
            DrawStateStack<DrawStateStackType::FullGraphics> post_draw_state_stack_graphics;
            DrawStateStack<DrawStateStackType::Compute> post_draw_state_stack_compute;

            if (!cancelled_or_replaced)
            {
               draw_lambda();
            }
            else if (!debug_draw_replaced_pass)
            {
               if (is_dispatch)
               {
                  post_draw_state_stack_compute.Cache(native_device_context, device_data.uav_max_count);
                  pre_draw_state_stack_compute.Restore(native_device_context);
               }
               else
               {
                  post_draw_state_stack_graphics.Cache(native_device_context, device_data.uav_max_count);
                  pre_draw_state_stack_graphics.Restore(native_device_context);
               }
            }

            CopyDebugDrawTexture(debug_draw_mode, debug_draw_view_index, cmd_list, is_dispatch);

            if (cancelled_or_replaced && !debug_draw_replaced_pass)
            {
               if (is_dispatch)
                  post_draw_state_stack_compute.Restore(native_device_context);
               else
                  post_draw_state_stack_graphics.Restore(native_device_context);
            }
            cancelled_or_replaced = true;
         }
      }
      bool track_buffer_pipeline_ps = is_dispatch ? false : (track_buffer_pipeline == cmd_list_data.pipeline_state_original_pixel_shader.handle);
      bool track_buffer_pipeline_vs = is_dispatch ? false : (track_buffer_pipeline == cmd_list_data.pipeline_state_original_vertex_shader.handle);
      bool track_buffer_pipeline_cs = is_dispatch ? (track_buffer_pipeline == cmd_list_data.pipeline_state_original_compute_shader.handle) : false;
      if (track_buffer_pipeline != 0 && (track_buffer_pipeline_ps || track_buffer_pipeline_vs || track_buffer_pipeline_cs))
      {
         auto local_track_buffer_pipeline_instance = track_buffer_pipeline_instance.fetch_add(1);
         if (track_buffer_pipeline_target_instance == -1 || local_track_buffer_pipeline_instance == track_buffer_pipeline_target_instance)
         {
            com_ptr<ID3D11Buffer> cb;
            if (track_buffer_pipeline_ps)
            {
               native_device_context->PSGetConstantBuffers(track_buffer_index, 1, &cb);
            }
            else if (track_buffer_pipeline_ps)
            {
               native_device_context->VSGetConstantBuffers(track_buffer_index, 1, &cb);
            }
            else if (track_buffer_pipeline_cs)
            {
               native_device_context->CSGetConstantBuffers(track_buffer_index, 1, &cb);
            }
            // Copy the buffer in our data
            CopyBuffer(cb, native_device_context, device_data.track_buffer_data.data);
            device_data.track_buffer_data.hash = std::to_string(std::hash<void*>{}(cb.get()));
         }
      }
      if (cancelled_or_replaced)
      {
         // Cancel the lambda as we've already drawn once, we don't want to do it further below
         draw_lambda = []() {};
      }

      cancelled_or_replaced |= HandlePipelineRedirections(native_device_context, device_data, cmd_list_data, is_dispatch, draw_lambda);
#endif
      return cancelled_or_replaced;
   }

   // TODO: use the native ReShade sampler desc instead? It's not really necessary
   // Expects "s_mutex_samplers" to already be locked
   com_ptr<ID3D11SamplerState> CreateCustomSampler(const DeviceData& device_data, ID3D11Device* device, const D3D11_SAMPLER_DESC& original_desc)
   {
      D3D11_SAMPLER_DESC desc = original_desc;
#if !DEVELOPMENT
      if (desc.Filter == D3D11_FILTER_ANISOTROPIC || desc.Filter == D3D11_FILTER_COMPARISON_ANISOTROPIC)
      {
         desc.MaxAnisotropy = D3D11_REQ_MAXANISOTROPY;
#if 1 // Without bruteforcing the offset, many textures (e.g. decals) stay blurry in Prey. Based on "samplers_upgrade_mode" 5.
         desc.MipLODBias = std::clamp(device_data.texture_mip_lod_bias_offset, D3D11_MIP_LOD_BIAS_MIN, D3D11_MIP_LOD_BIAS_MAX); // Setting this out of range (~ +/- 16) will make DX11 crash
#else // Based on "samplers_upgrade_mode" 4.
         desc.MipLODBias = std::clamp(desc.MipLODBias + device_data.texture_mip_lod_bias_offset, D3D11_MIP_LOD_BIAS_MIN, D3D11_MIP_LOD_BIAS_MAX); // Setting this out of range (~ +/- 16) will make DX11 crash
#endif
      }
      else
      {
         return nullptr;
      }
#else
      if (samplers_upgrade_mode <= 0)
         return nullptr;

      // Prey's CryEngine (and most games) only uses:
      // D3D11_FILTER_ANISOTROPIC
      // D3D11_FILTER_COMPARISON_ANISOTROPIC
      // D3D11_FILTER_MIN_MAG_MIP_POINT
      // D3D11_FILTER_COMPARISON_MIN_MAG_MIP_POINT
      // D3D11_FILTER_MIN_MAG_LINEAR_MIP_POINT
      // D3D11_FILTER_COMPARISON_MIN_MAG_LINEAR_MIP_POINT
      // D3D11_FILTER_MIN_MAG_MIP_LINEAR
      // D3D11_FILTER_COMPARISON_MIN_MAG_MIP_LINEAR
      //TODOFT: check the cases for other games!

      // This could theoretically make some textures that have moire patters, or were purposely blurry, "worse", but the positives of upgrading still outweight the negatives.
      // Note that this might not fix all cases because there's still "ID3D11DeviceContext::SetResourceMinLOD()" and textures that are blurry for other reasons
      // because they use other types of samplers (unfortunately it seems like some decals use "D3D11_FILTER_MIN_MAG_MIP_LINEAR").
      // Note that the AF on different textures in the game seems is possibly linked with other graphics settings than just AF (maybe textures or objects quality).
      if (desc.Filter == D3D11_FILTER_ANISOTROPIC || desc.Filter == D3D11_FILTER_COMPARISON_ANISOTROPIC)
      {
         // Note: this doesn't seem to affect much
         if (samplers_upgrade_mode == 1)
         {
            desc.MaxAnisotropy = min(desc.MaxAnisotropy * 2, D3D11_REQ_MAXANISOTROPY);
         }
         else if (samplers_upgrade_mode == 2)
         {
            desc.MaxAnisotropy = min(desc.MaxAnisotropy * 4, D3D11_REQ_MAXANISOTROPY);
         }
         else if (samplers_upgrade_mode >= 3)
         {
            desc.MaxAnisotropy = D3D11_REQ_MAXANISOTROPY;
         }
         // Note: this is the main ingredient in making textures less blurry
         if (samplers_upgrade_mode == 4 && desc.MipLODBias <= 0.f)
         {
            desc.MipLODBias = std::clamp(desc.MipLODBias + device_data.texture_mip_lod_bias_offset, D3D11_MIP_LOD_BIAS_MIN, D3D11_MIP_LOD_BIAS_MAX);
         }
         else if (samplers_upgrade_mode >= 5)
         {
            desc.MipLODBias = std::clamp(device_data.texture_mip_lod_bias_offset, D3D11_MIP_LOD_BIAS_MIN, D3D11_MIP_LOD_BIAS_MAX);
         }
         // Note: this never seems to affect anything in Prey, probably also doesn't in most games
         if (samplers_upgrade_mode >= 6)
         {
            desc.MinLOD = min(desc.MinLOD, 0.f);
         }
      }
      else if ((desc.Filter == D3D11_FILTER_MIN_MAG_MIP_LINEAR && samplers_upgrade_mode_2 >= 1) // This is the most common (main/only) format being used other than AF
         || (desc.Filter == D3D11_FILTER_COMPARISON_MIN_MAG_MIP_LINEAR && samplers_upgrade_mode_2 >= 2)
         || (desc.Filter == D3D11_FILTER_MIN_MAG_LINEAR_MIP_POINT && samplers_upgrade_mode_2 >= 3)
         || (desc.Filter == D3D11_FILTER_COMPARISON_MIN_MAG_LINEAR_MIP_POINT && samplers_upgrade_mode_2 >= 4)
         || (desc.Filter == D3D11_FILTER_MIN_MAG_MIP_POINT && samplers_upgrade_mode_2 >= 5)
         || (desc.Filter == D3D11_FILTER_COMPARISON_MIN_MAG_MIP_POINT && samplers_upgrade_mode_2 >= 6))
      {
         //TODOFT: research. Force this on to see how it behaves. Doesn't work, it doesn't really help any further with (e.g.) blurry decal textures
         // Note: this doesn't seem to do anything really, it doesn't help with the occasional blurry texture (probably because all samplers that needed anisotropic already had it set)
         if (samplers_upgrade_mode >= 7)
         {
            desc.Filter == (desc.ComparisonFunc != D3D11_COMPARISON_NEVER && samplers_upgrade_mode == 7) ? D3D11_FILTER_COMPARISON_ANISOTROPIC : D3D11_FILTER_ANISOTROPIC;
            desc.MaxAnisotropy = D3D11_REQ_MAXANISOTROPY;
         }
         // Note: changing the lod bias of non anisotropic filters makes reflections (cubemap samples?) a lot more specular (shiny) in Prey (and probably does in other games too), so it's best avoided (it can look better is some screenshots, but it's likely not intended).
         // Even if we only fix up textures that didn't have a positive bias, we run into the same problem.
         if (samplers_upgrade_mode == 4 && desc.MipLODBias <= 0.f)
         {
            desc.MipLODBias = std::clamp(desc.MipLODBias + device_data.texture_mip_lod_bias_offset, D3D11_MIP_LOD_BIAS_MIN, D3D11_MIP_LOD_BIAS_MAX);
         }
         else if (samplers_upgrade_mode >= 5)
         {
            desc.MipLODBias = std::clamp(device_data.texture_mip_lod_bias_offset, D3D11_MIP_LOD_BIAS_MIN, D3D11_MIP_LOD_BIAS_MAX);
         }
         if (samplers_upgrade_mode >= 6)
         {
            desc.MinLOD = min(desc.MinLOD, 0.f);
         }
      }
#endif // !DEVELOPMENT

      com_ptr<ID3D11SamplerState> sampler;
      device->CreateSamplerState(&desc, &sampler);
      ASSERT_ONCE(sampler != nullptr);
      return sampler;
   }

   void OnInitSampler(reshade::api::device* device, const reshade::api::sampler_desc& desc, reshade::api::sampler sampler)
   {
      if (sampler == 0)
         return;
#if DEVELOPMENT
      if (samplers_upgrade_mode == 0)
         return;
#endif

      DeviceData& device_data = *device->get_private_data<DeviceData>();

#if DEVELOPMENT && 0 // Assert in case we got unexpected samplers
      if (desc.filter == reshade::api::filter_mode::anisotropic || desc.filter == reshade::api::filter_mode::compare_anisotropic)
      {
         assert(desc.max_anisotropy >= 2); // Doesn't seem to happen
         assert(desc.min_lod == 0); // Doesn't seem to happen
         assert(desc.mip_lod_bias == 0.f); // This seems to happen when enabling TAA (but not with SMAA 2TX), some new samplers are created with bias -1 and then persist, it's unclear if they are used though.
      }
      else
      {
         assert(desc.max_anisotropy <= 1); // This can happen (like once) in Prey. AF is probably ignored for these anyway so it's innocuous
      }
      assert(desc.filter != reshade::api::filter_mode::min_mag_anisotropic_mip_point && desc.filter != reshade::api::filter_mode::compare_min_mag_anisotropic_mip_point); // Doesn't seem to happen

      ASSERT_ONCE(desc.filter == reshade::api::filter_mode::anisotropic
         || desc.filter == reshade::api::filter_mode::compare_anisotropic
         || desc.filter == reshade::api::filter_mode::min_mag_mip_linear
         || desc.filter == reshade::api::filter_mode::compare_min_mag_mip_linear
         || desc.filter == reshade::api::filter_mode::min_mag_linear_mip_point
         || desc.filter == reshade::api::filter_mode::compare_min_mag_linear_mip_point); // Doesn't seem to happen
#endif // DEVELOPMENT

      ID3D11SamplerState* native_sampler = reinterpret_cast<ID3D11SamplerState*>(sampler.handle);

      std::shared_lock shared_lock_samplers(s_mutex_samplers);

      // Custom samplers lifetime should never be tracked by ReShade, otherwise we'd recursively create custom samplers out of custom samplers
      // (it's unclear if engines (e.g. CryEngine) somehow do anything with these samplers or if ReShade captures our own samplers creation events (it probably does as we create them directly through the DX native funcs))
      for (const auto& samplers_handle : device_data.custom_sampler_by_original_sampler)
      {
         for (const auto& custom_sampler_handle : samplers_handle.second)
         {
            ID3D11SamplerState* native_sampler = reinterpret_cast<ID3D11SamplerState*>(sampler.handle);
            if (custom_sampler_handle.second.get() == native_sampler)
            {
               return;
            }
         }
      }

      shared_lock_samplers.unlock(); // This is fine!
      D3D11_SAMPLER_DESC native_desc;
      native_sampler->GetDesc(&native_desc);
      std::unique_lock unique_lock_samplers(s_mutex_samplers);
      device_data.custom_sampler_by_original_sampler[sampler.handle][device_data.texture_mip_lod_bias_offset] = CreateCustomSampler(device_data, (ID3D11Device*)device->get_native(), native_desc);
   }

   void OnDestroySampler(reshade::api::device* device, reshade::api::sampler sampler)
   {
      DeviceData& device_data = *device->get_private_data<DeviceData>();
      // This only seems to happen when the game shuts down in Prey (as any destroy callback, it can be called from an arbitrary thread, but that's fine)
      const std::unique_lock lock_samplers(s_mutex_samplers);
      device_data.custom_sampler_by_original_sampler.erase(sampler.handle);
   }

   void OnInitResource(
      reshade::api::device* device,
      const reshade::api::resource_desc& desc,
      const reshade::api::subresource_data* initial_data,
      reshade::api::resource_usage initial_state,
      reshade::api::resource resource)
   {
      DeviceData& device_data = *device->get_private_data<DeviceData>();
      const std::unique_lock lock(device_data.mutex);
      if (waiting_on_upgraded_resource_init)
      {
         // If this happened, some resource creation failed an "OnInitResource()" was never called after "OnCreateResource()".
         // It might have to do with the fact that the resource was shared.
         // Either way we could never catch all cases as we don't know when that happens, and this might have false positives as a desc isn't a unique pointer (two resources might use the same desc).
         // Then again, if the description was identical and the first would have failed, so would have the second one.
         ASSERT_ONCE(std::memcmp(&upgraded_resource_init_desc, &desc, sizeof(upgraded_resource_init_desc)) == 0);
         if (std::memcmp(&upgraded_resource_init_desc, &desc, sizeof(upgraded_resource_init_desc)) == 0)
         {
            ASSERT_ONCE(upgraded_resource_init_data == nullptr || initial_data->data == upgraded_resource_init_data);
         }
         else
         {
            ASSERT_ONCE(upgraded_resource_init_data == nullptr || initial_data->data != upgraded_resource_init_data);
         }
         // Delete the converted data we created (there's a chance of memory leaks if creation failed, though unlikely)
         delete upgraded_resource_init_data;

         device_data.upgraded_resources.emplace(resource.handle);
#if DEVELOPMENT
         device_data.original_upgraded_resources_formats[resource.handle] = last_attempted_upgraded_resource_creation_format;
#endif
         waiting_on_upgraded_resource_init = false;
      }
      else
      {
         // Code mirrored from "OnCreateResource()" (though some filter cases are still missing)
         if (desc.type == reshade::api::resource_type::texture_2d && desc.texture.depth_or_layers == 1)
         {
            if ((desc.usage & (reshade::api::resource_usage::render_target | reshade::api::resource_usage::unordered_access)) != 0 && enable_texture_format_upgrades && texture_upgrade_formats.contains(desc.texture.format))
            {
               // Shared resources can call "OnInitResource()" without a "OnCreateResource()" (see "D3D11Device::OpenSharedResource"), as they've been created on a different device (and possibly API), so we can't always upgrade them,
               // though Luma only allows DX11 devices so it's probably guaranteed!
               ASSERT_ONCE((desc.flags & reshade::api::resource_flags::shared) == 0);
            }
         }
      }
   }

   // Define source pixel structure (8-bit per channel)
   struct R8G8B8A8_UNORM
   {
      uint8_t r, g, b, a;
   };
   struct B8G8R8A8_UNORM
   {
      uint8_t b, g, r, a;
   };
   struct R16G16B16A16_FLOAT
   {
      uint16_t r, g, b, a;
   };

   inline uint16_t ConvertFloatToHalf(float value)
   {
      // XMConvertFloatToHalf converts a float to a half, returning the 16-bit unsigned short representation.
      return DirectX::PackedVector::XMConvertFloatToHalf(value);
   }
   
   template<typename T>
   void ConvertR8G8B8A8toR16G16B16A16(
      const T* src_data,
      R16G16B16A16_FLOAT* dst_data,
      size_t width,
      size_t height,
      size_t depth = 1)
   {
      size_t slice_size = width * height;

      for (size_t z = 0; z < depth; ++z)
      {
         size_t slice_offset = slice_size * z;

         for (size_t i = 0; i < slice_size; i++)
         {
            const T& pixel = src_data[slice_offset + i];

            // Read each channel and normalize from 0-255 to 0.0-1.0.
            float r = pixel.r / 255.0f;
            float g = pixel.g / 255.0f;
            float b = pixel.b / 255.0f;
            float a = pixel.a / 255.0f;

            // Convert normalized floats to half-floats.
            dst_data[i].r = ConvertFloatToHalf(r);
            dst_data[i].g = ConvertFloatToHalf(g);
            dst_data[i].b = ConvertFloatToHalf(b);
            dst_data[i].a = ConvertFloatToHalf(a);
         }
      }
   }

   bool IsMipOf(uint32_t base_w, uint32_t base_h, uint32_t w, uint32_t h)
   {
      if (w == 0 || h == 0 || base_w == 0 || base_h == 0)
         return false;

      // Check if w and h are powers-of-two divisions of base
      if (base_w < w || base_h < h)
         return false;

      // Check that downscaling factor is exact power of two
      bool valid_w = (base_w >> (std::countr_zero(base_w) - std::countr_zero(w))) == w;
      bool valid_h = (base_h >> (std::countr_zero(base_h) - std::countr_zero(h))) == h;

      return valid_w && valid_h;
   }

   //TODOFT5: figure out why after changing resolution debugging textures breaks?

   // TODO: cache the last "almost" upgraded texture resolution to make sure that when the swapchain changes res, we didn't fail to upgrade resources before
   bool ShouldUpgradeResource(const reshade::api::resource_desc& desc, const DeviceData& device_data)
   {
      if ((desc.usage & (reshade::api::resource_usage::render_target | reshade::api::resource_usage::unordered_access)) == 0 || !enable_texture_format_upgrades || !texture_upgrade_formats.contains(desc.texture.format))
      {
         return false;
      }

      // At least in DX11, any resource that isn't exclusively accessible by the GPU, can't be set as output (render target/unordered access).
		// These probably wouldn't have the RT/UA usage flags set anyway, or they'd fail on creation if they did.
      if (desc.heap != reshade::api::memory_heap::gpu_only)
      {
         ASSERT_ONCE(desc.heap != reshade::api::memory_heap::unknown && desc.heap != reshade::api::memory_heap::custom); // Unexpected heap types
         return false;
      }

      // Note: we can't fully exclude texture 2D arrays here, because they might still have 1 layer
      bool type_and_size_filter = desc.type == reshade::api::resource_type::texture_2d && desc.texture.depth_or_layers == 1;

      if (texture_format_upgrades_2d_size_filters != (uint32_t)TextureFormatUpgrades2DSizeFilters::All)
      {
         bool size_filter = false;
         if ((texture_format_upgrades_2d_size_filters & (uint32_t)TextureFormatUpgrades2DSizeFilters::SwapchainResolution) != 0)
         {
            size_filter |= desc.texture.width == device_data.output_resolution.x && desc.texture.height == device_data.output_resolution.y;
         }
         if ((texture_format_upgrades_2d_size_filters & (uint32_t)TextureFormatUpgrades2DSizeFilters::RenderResolution) != 0)
         {
            size_filter |= desc.texture.width == device_data.render_resolution.x && desc.texture.height == device_data.render_resolution.y;
         }
         for (uint8_t i = 0; i < 2; i++)
         {
            if ((i == 0 && ((texture_format_upgrades_2d_size_filters & (uint32_t)TextureFormatUpgrades2DSizeFilters::SwapchainAspectRatio) != 0))
               || (i == 1 && ((texture_format_upgrades_2d_size_filters & (uint32_t)TextureFormatUpgrades2DSizeFilters::CustomAspectRatio) != 0)))
            {
               // Always scale from the smallest dimension, as that gives up more threshold, depending on how the devs scaled down textures (they can use multiple rounding models)
               float min_aspect_ratio = desc.texture.width <= desc.texture.height ? ((float)(desc.texture.width - texture_format_upgrades_2d_aspect_ratio_pixel_threshold) / (float)desc.texture.height) : ((float)desc.texture.width / (float)(desc.texture.height + texture_format_upgrades_2d_aspect_ratio_pixel_threshold));
               float max_aspect_ratio = desc.texture.width <= desc.texture.height ? ((float)(desc.texture.width + texture_format_upgrades_2d_aspect_ratio_pixel_threshold) / (float)desc.texture.height) : ((float)desc.texture.width / (float)(desc.texture.height - texture_format_upgrades_2d_aspect_ratio_pixel_threshold));
               float target_aspect_ratio = (i == 1) ? texture_format_upgrades_2d_custom_aspect_ratio : ((float)device_data.output_resolution.x / (float)device_data.output_resolution.y);
               bool aspect_ratio_filter = target_aspect_ratio >= (min_aspect_ratio - FLT_EPSILON) && target_aspect_ratio <= (max_aspect_ratio + FLT_EPSILON);

#if DEVELOPMENT
               static thread_local UINT last_texture_width = desc.texture.width;
               static thread_local UINT last_texture_height = desc.texture.height;
               bool generating_manual_mips = false;
               // If this was a chain of downscaling, don't send a warning! This is just a heuristics based check... The creation order might have been random, or inverted (from smaller to bigger mips).
               // Note that this isn't thread safe but whatever
               if (max(desc.texture.width, desc.texture.height) == 1)
               {
                  generating_manual_mips = (last_texture_width / 2) == desc.texture.width && (last_texture_height / 2) == desc.texture.height;
               }
               ASSERT_ONCE_MSG(!aspect_ratio_filter || max(desc.texture.width, desc.texture.height) > 1 || generating_manual_mips, "Upgrading 1x1 resource by aspect ratio, this is possibly unwanted"); // TODO: add a min size for upgrades? Like >1 or >32 on the smallest axis? Or ... scan if the allocations shrink in size over time
               last_texture_width = desc.texture.width;
               last_texture_height = desc.texture.height;
#endif

               size_filter |= aspect_ratio_filter;
            }
         }
         if ((texture_format_upgrades_2d_size_filters & (uint32_t)TextureFormatUpgrades2DSizeFilters::Mips) != 0)
         {
            float2 max_resolution = device_data.output_resolution.y >= device_data.render_resolution.y ? device_data.output_resolution : device_data.render_resolution;
            size_filter |= IsMipOf(max_resolution.x, max_resolution.y, desc.texture.width, desc.texture.height);
         }
         type_and_size_filter &= size_filter;
      }

      switch (texture_format_upgrades_lut_dimensions)
      {
      case LUTDimensions::_1D:
      {
         // For 1D, "texture_format_upgrades_lut_size" is the whole width (usually they extend in width)
         type_and_size_filter |= desc.type == reshade::api::resource_type::texture_1d && desc.texture.width == texture_format_upgrades_lut_size && desc.texture.height == 1 && desc.texture.depth_or_layers == 1 && desc.texture.levels == 1;
         break;
      }
      default:
      case LUTDimensions::_2D:
      {
         // For 2D, "texture_format_upgrades_lut_size" is the height, usually they extend in width and that's squared
         type_and_size_filter |= desc.type == reshade::api::resource_type::texture_2d && desc.texture.width == (texture_format_upgrades_lut_size * texture_format_upgrades_lut_size) && desc.texture.height == texture_format_upgrades_lut_size && desc.texture.depth_or_layers == 1 && desc.texture.levels == 1;
         break;
      }
      case LUTDimensions::_3D:
      {
         // For 3D, all the dimensions usually match
         type_and_size_filter |= desc.type == reshade::api::resource_type::texture_3d && desc.texture.width == texture_format_upgrades_lut_size && desc.texture.height == texture_format_upgrades_lut_size && desc.texture.depth_or_layers == texture_format_upgrades_lut_size && desc.texture.levels == 1;
         break;
      }
      }

      return type_and_size_filter;
   }

   // Note that swapchain textures (backbuffer) don't pass through here!
   bool OnCreateResource(
      reshade::api::device* device,
      reshade::api::resource_desc& desc,
      reshade::api::subresource_data* initial_data,
      reshade::api::resource_usage initial_state)
   {
      ASSERT_ONCE(device->get_api() == reshade::api::device_api::d3d11);

      // No need to clear "upgraded_resource_init_desc"/"upgraded_resource_init_data" from its last value
      waiting_on_upgraded_resource_init = false; // If the same thread called another "OnCreateResource()" before we got a "OnInitResource()", it implies the resource creation has failed and we didn't get that event (we have to do it by thread as device objects creation is thread safe and can be done by multiple threads concurrently)

      DeviceData& device_data = *device->get_private_data<DeviceData>();
      std::shared_lock lock(device_data.mutex); // Note: we possibly don't even need this (or well, we might want to use a different mutex)
      
      if (ShouldUpgradeResource(desc, device_data))
      {
         lock.unlock();
#if DEVELOPMENT
         last_attempted_upgraded_resource_creation_format = desc.texture.format;
#endif
         // Note that upgrading typeless texture could have unforeseen consequences in some games, especially when the textures are then used as unsigned int or signed int etc (e.g. Trine 5)
         desc.texture.format = reshade::api::format::r16g16b16a16_float; // TODO: if the source format was like R8G8_UNORM, only upgrade it to R16G16_FLOAT unless otherwise specified?
#if DEVELOPMENT && 0 //TODOFT5
         desc.texture.samples = 4; // Try MSAA
         if (desc.type == reshade::api::resource_type::texture_2d)
         {
            desc.texture.width *= 2; // Try SSAA
            desc.texture.height *= 2; // Try MSAA
         }
#endif
         waiting_on_upgraded_resource_init = true;
         upgraded_resource_init_desc = desc;
         bool converted_initial_data = false;
         // We need to convert the initial data to the new format
         if (initial_data != nullptr)
         {
            void* prev_data = initial_data->data;
            ASSERT_ONCE(initial_data->data != nullptr);

            constexpr size_t bytes_per_pixel = 8; // 4 for 8bpc, 8 for 16bpc
            const size_t buffer_size = desc.texture.width * desc.texture.height * desc.texture.depth_or_layers * bytes_per_pixel;

            switch (desc.texture.format)
            {
            case reshade::api::format::r8g8b8a8_unorm:
            case reshade::api::format::r8g8b8a8_unorm_srgb:
            case reshade::api::format::r8g8b8x8_unorm:
            case reshade::api::format::r8g8b8x8_unorm_srgb:
            {
               initial_data->data = new uint8_t[buffer_size];
               initial_data->row_pitch = desc.texture.width * bytes_per_pixel;
               initial_data->slice_pitch = initial_data->row_pitch * desc.texture.height;
               ConvertR8G8B8A8toR16G16B16A16((R8G8B8A8_UNORM*)prev_data, (R16G16B16A16_FLOAT*)initial_data->data, desc.texture.width, desc.texture.height, desc.texture.depth_or_layers);
               converted_initial_data = true;
               break;
            }
            case reshade::api::format::b8g8r8a8_unorm:
            case reshade::api::format::b8g8r8a8_unorm_srgb:
            case reshade::api::format::b8g8r8x8_unorm:
            case reshade::api::format::b8g8r8x8_unorm_srgb:
            {
               initial_data->data = new uint8_t[buffer_size];
               initial_data->row_pitch = desc.texture.width * bytes_per_pixel;
               initial_data->slice_pitch = initial_data->row_pitch * desc.texture.height;
               ConvertR8G8B8A8toR16G16B16A16((B8G8R8A8_UNORM*)prev_data, (R16G16B16A16_FLOAT*)initial_data->data, desc.texture.width, desc.texture.height, desc.texture.depth_or_layers);
               converted_initial_data = true;
               break;
            }
            case reshade::api::format::r16g16b16a16_float:
            {
               break;
            }
            default:
            {
               ASSERT_ONCE_MSG(false, "Unsupported resource initial data format (due to texture upgrades)"); // TODO: add support
               break;
            }
            }
         }
         upgraded_resource_init_data = converted_initial_data ? initial_data->data : nullptr;

         return true;
      }
      return false;
   }

   void OnDestroyResource(reshade::api::device* device, reshade::api::resource resource)
   {
      if (!device || device->get_private_data<DeviceData>() == nullptr)
      {
#if 0
         ASSERT_ONCE(false); // Happens when BioShock Infinite closes down (due to it using shared resources!), though it seems to be almost safe (could it be that the (now stale) device pointer has already been re-allocated? Probably not as this call comes from within the device object itself?)
#endif
         return;
      }
      DeviceData& device_data = *device->get_private_data<DeviceData>();
      const std::unique_lock lock(device_data.mutex);
      device_data.upgraded_resources.erase(resource.handle);
   }

   bool OnCreateResourceView(
      reshade::api::device* device,
      reshade::api::resource resource,
      reshade::api::resource_usage usage_type,
      reshade::api::resource_view_desc& desc)
   {
		reshade::api::resource_view_type lut_dimensions = reshade::api::resource_view_type::unknown;
      switch (texture_format_upgrades_lut_dimensions)
      {
      case LUTDimensions::_1D:
      {
         lut_dimensions = reshade::api::resource_view_type::texture_1d;
         break;
      }
      default:
      case LUTDimensions::_2D:
      {
         lut_dimensions = reshade::api::resource_view_type::texture_2d;
         break;
      }
      case LUTDimensions::_3D:
      {
         lut_dimensions = reshade::api::resource_view_type::texture_3d;
         break;
      }
      }

      // In DX11 apps can not pass a "DESC" when creating resource views, and DX11 will automatically generate the default one from it, we handle it through "reshade::api::resource_view_type::unknown".
      if (resource.handle != 0 && (desc.type == reshade::api::resource_view_type::unknown || desc.type == lut_dimensions || desc.type == reshade::api::resource_view_type::texture_2d || desc.type == reshade::api::resource_view_type::texture_2d_array || desc.type == reshade::api::resource_view_type::texture_2d_multisample || desc.type == reshade::api::resource_view_type::texture_2d_multisample_array))
      {
         const reshade::api::resource_desc resource_desc = device->get_resource_desc(resource);

         DeviceData& device_data = *device->get_private_data<DeviceData>();
         const std::shared_lock lock(device_data.mutex);

         // Needed because these were not in the upgraded resources list, but we upgraded the swapchain's textures,
         // some games randomly pick a view format when they can't pick a proper one (due to the format upgrades).
         if (swapchain_upgrade_type >= 1 && device_data.back_buffers.contains(resource.handle))
         {
#if DEVELOPMENT
            last_attempted_upgraded_resource_view_creation_view_format = desc.format;
            if (last_attempted_upgraded_resource_view_creation_view_format == reshade::api::format::unknown && device_data.original_upgraded_resources_formats.contains(resource.handle))
            {
               last_attempted_upgraded_resource_view_creation_view_format = device_data.original_upgraded_resources_formats[resource.handle];
            }
#endif // DEVELOPMENT

            if (desc.type == reshade::api::resource_view_type::unknown)
            {
               desc.type = resource_desc.texture.samples <= 1 ? (resource_desc.texture.depth_or_layers <= 1 ? reshade::api::resource_view_type::texture_2d : reshade::api::resource_view_type::texture_2d_array) : (resource_desc.texture.depth_or_layers <= 1 ? reshade::api::resource_view_type::texture_2d_multisample : reshade::api::resource_view_type::texture_2d_multisample_array);
            }
            desc.texture.level_count = 1; // "Deus Ex: Human Revolution - Director's Cut" sets this to 0 (at least when we upgrade the swapchain texture), it might be fine, but the DX11 docs only talk about setting it to -1 to use all levels (which are always 1 for swapchain textures anyway)
            // Redirect typeless formats (not even sure they are supported, but it won't hurt to check)
            switch (resource_desc.texture.format)
            {
            case reshade::api::format::r16g16b16a16_typeless:
            {
               desc.format = reshade::api::format::r16g16b16a16_float;
               break;
            }
            case reshade::api::format::r8g8b8a8_typeless:
            {
               if (desc.format != reshade::api::format::r8g8b8a8_unorm_srgb)
                  desc.format = reshade::api::format::r8g8b8a8_unorm;
               break;
            }
            case reshade::api::format::b8g8r8a8_typeless:
            {
               if (desc.format != reshade::api::format::b8g8r8a8_unorm_srgb)
                  desc.format = reshade::api::format::b8g8r8a8_unorm;
               break;
            }
            case reshade::api::format::r10g10b10a2_typeless:
            {
               desc.format = reshade::api::format::r10g10b10a2_unorm;
               break;
            }
            default:
            {
               bool formats_compatible = false;
               bool rgba8_1 = desc.format == reshade::api::format::r8g8b8a8_unorm || desc.format == reshade::api::format::r8g8b8a8_unorm_srgb;
               bool rgba8_2 = resource_desc.texture.format == reshade::api::format::r8g8b8a8_unorm || resource_desc.texture.format == reshade::api::format::r8g8b8a8_unorm_srgb;
               bool bgra8_1 = desc.format == reshade::api::format::b8g8r8a8_unorm || desc.format == reshade::api::format::b8g8r8a8_unorm_srgb;
               bool bgra8_2 = resource_desc.texture.format == reshade::api::format::b8g8r8a8_unorm || resource_desc.texture.format == reshade::api::format::b8g8r8a8_unorm_srgb;
               formats_compatible |= rgba8_1 && rgba8_2;
               formats_compatible |= bgra8_1 && bgra8_2;
               // No need to force replace the view format if formats are compatible
               if (!formats_compatible)
                 desc.format = resource_desc.texture.format; // Should be R16G16B16A16F if "enable_swapchain_upgrade" is on (depending on "swapchain_upgrade_type")
               break;
            }
            }
            return true;
         }

#if DEVELOPMENT
         bool usage_filter = usage_type == reshade::api::resource_usage::render_target || usage_type == reshade::api::resource_usage::unordered_access || usage_type == reshade::api::resource_usage::shader_resource; // This is all of the possible types anyway...
         if (usage_filter && ShouldUpgradeResource(resource_desc, device_data) && resource_desc.texture.format == reshade::api::format::r16g16b16a16_float)
         {
            switch (desc.format)
            {
            default:
            {
               // Nobody should be creating a typeless view, though it might be a bug with the game's code in case of unexpected format upgrades
               ASSERT_ONCE(desc.format != reshade::api::format::r16g16b16a16_typeless && desc.format != reshade::api::format::r8g8b8a8_typeless && desc.format != reshade::api::format::b8g8r8a8_typeless && desc.format != reshade::api::format::b8g8r8x8_typeless);
               break;
            }
            case reshade::api::format::unknown:
            {
               // Happens when the call didn't provide a "DESC", creating a default view (because if we reached here, the texture is 16bpc float)
               ASSERT_ONCE(device_data.upgraded_resources.contains(resource.handle));
               break;
            }
            }
         }
#endif

         if (device_data.upgraded_resources.contains(resource.handle))
         {
#if DEVELOPMENT
            last_attempted_upgraded_resource_view_creation_view_format = desc.format;
            // Note: if it's unknown, it usually means the game wanted to auto create a view. But it could also mean they dynamically created views based on the current resource format, and that code failed to find a valid view format for upgraded textures,
            // however if that was the case, it'd be hard to explain why all games still create resources even when upgrading textures.
            if (last_attempted_upgraded_resource_view_creation_view_format == reshade::api::format::unknown && device_data.original_upgraded_resources_formats.contains(resource.handle))
            {
               last_attempted_upgraded_resource_view_creation_view_format = device_data.original_upgraded_resources_formats[resource.handle];
            }
#endif // DEVELOPMENT

            if (desc.type == reshade::api::resource_view_type::unknown)
            {
               if (resource_desc.type == reshade::api::resource_type::texture_3d)
               {
                  desc.type = reshade::api::resource_view_type::texture_3d;
               }
               else
               {
                  desc.type = resource_desc.texture.samples <= 1 ? (resource_desc.texture.depth_or_layers <= 1 ? reshade::api::resource_view_type::texture_2d : reshade::api::resource_view_type::texture_2d_array) : (resource_desc.texture.depth_or_layers <= 1 ? reshade::api::resource_view_type::texture_2d_multisample : reshade::api::resource_view_type::texture_2d_multisample_array); // We need to set it in case it was "reshade::api::resource_view_type::unknown", otherwise the format would also need to be unknown
               }
               desc.texture.first_level = 0;
               desc.texture.level_count = -1; // All levels (e.g. Dishonored 2 sets this to invalid values if the resource format was upgraded)
               desc.texture.first_layer = 0;
               desc.texture.layer_count = resource_desc.texture.depth_or_layers;
            }
            desc.format = reshade::api::format::r16g16b16a16_float;
            return true;
         }
      }

#if DEVELOPMENT
      DeviceData& device_data = *device->get_private_data<DeviceData>();
      const std::shared_lock lock(device_data.mutex);
      if (desc.format != reshade::api::format::r16g16b16a16_float)
      {
         ASSERT_ONCE(!device_data.upgraded_resources.contains(resource.handle)); // Why did we get here in this case?
      }
      D3D11_TEXTURE2D_DESC texture_2d_desc;
      D3D11_TEXTURE3D_DESC texture_3d_desc;
      D3D11_TEXTURE1D_DESC texture_1d_desc;
      if (device_data.upgraded_resources.contains(resource.handle))
      {
         ID3D11Resource* native_resource = reinterpret_cast<ID3D11Resource*>(resource.handle);
         ID3D11Texture2D* texture_2d = nullptr;
         ID3D11Texture3D* texture_3d = nullptr;
         ID3D11Texture1D* texture_1d = nullptr;
         HRESULT hr_2d = native_resource->QueryInterface(__uuidof(ID3D11Texture2D), (void**)&texture_2d);
         HRESULT hr_3d = native_resource->QueryInterface(__uuidof(ID3D11Texture3D), (void**)&texture_3d);
         HRESULT hr_1d = native_resource->QueryInterface(__uuidof(ID3D11Texture1D), (void**)&texture_1d);
         if (SUCCEEDED(hr_2d) && texture_2d != nullptr)
         {
            texture_2d->GetDesc(&texture_2d_desc);
            ASSERT_ONCE(desc.type == reshade::api::resource_view_type::texture_2d || desc.type == reshade::api::resource_view_type::texture_2d_array || desc.type == reshade::api::resource_view_type::texture_2d_multisample || desc.type == reshade::api::resource_view_type::texture_2d_multisample_array);
            ASSERT_ONCE(desc.type != reshade::api::resource_view_type::unknown);
         }
         else if (SUCCEEDED(hr_3d) && texture_3d != nullptr)
         {
            texture_3d->GetDesc(&texture_3d_desc);
            ASSERT_ONCE(desc.type == reshade::api::resource_view_type::texture_3d);
            ASSERT_ONCE(desc.type != reshade::api::resource_view_type::unknown);
         }
         else if (SUCCEEDED(hr_1d) && texture_1d != nullptr)
         {
            texture_1d->GetDesc(&texture_1d_desc);
            ASSERT_ONCE(desc.type == reshade::api::resource_view_type::texture_1d);
            ASSERT_ONCE(desc.type != reshade::api::resource_view_type::unknown);
         }
         else
         {
            ASSERT_ONCE_MSG(false, "Unexpected texture format");
         }

         last_attempted_upgraded_resource_view_creation_view_format = desc.format;
         if (last_attempted_upgraded_resource_view_creation_view_format == reshade::api::format::unknown && device_data.original_upgraded_resources_formats.contains(resource.handle))
         {
            last_attempted_upgraded_resource_view_creation_view_format = device_data.original_upgraded_resources_formats[resource.handle];
         }
         if (desc.type == reshade::api::resource_view_type::unknown)
         {
            const reshade::api::resource_desc resource_desc = device->get_resource_desc(resource);
            if (resource_desc.type == reshade::api::resource_type::texture_3d)
            {
               desc.type = reshade::api::resource_view_type::texture_3d;
            }
            else if (resource_desc.type == reshade::api::resource_type::texture_1d)
            {
               desc.type = reshade::api::resource_view_type::texture_1d;
            }
            else
            {
               desc.type = resource_desc.texture.samples <= 1 ? (resource_desc.texture.depth_or_layers <= 1 ? reshade::api::resource_view_type::texture_2d : reshade::api::resource_view_type::texture_2d_array) : (resource_desc.texture.depth_or_layers <= 1 ? reshade::api::resource_view_type::texture_2d_multisample : reshade::api::resource_view_type::texture_2d_multisample_array); // We need to set it in case it was "reshade::api::resource_view_type::unknown", otherwise the format would also need to be unknown
            }
         }
         desc.format = reshade::api::format::r16g16b16a16_float;
         return true;
      }
#endif // DEVELOPMENT
      return false;
   }

#if DEVELOPMENT
   void OnInitResourceView(
      reshade::api::device* device,
      reshade::api::resource resource,
      reshade::api::resource_usage usage_type,
      const reshade::api::resource_view_desc& desc,
      reshade::api::resource_view view)
   {
      DeviceData& device_data = *device->get_private_data<DeviceData>();
      const std::unique_lock lock(device_data.mutex);
      if (device_data.original_upgraded_resources_formats.contains(resource.handle))
      {
         // Only the last attempted creation would matter
         device_data.original_upgraded_resource_views_formats.emplace(
            view.handle, // Key
            std::make_pair(resource.handle, last_attempted_upgraded_resource_view_creation_view_format) // Value
         );
      }
   }

   // TODO: put a test for resources that failed to be upgraded after changing resolution because they were created before the the swapchain changed res
   void OnDestroyResourceView(
      reshade::api::device* device,
      reshade::api::resource_view view)
   {
      DeviceData& device_data = *device->get_private_data<DeviceData>();
      const std::unique_lock lock(device_data.mutex);
      device_data.original_upgraded_resource_views_formats.erase(view.handle);
   }
#endif // DEVELOPMENT

   void OnPushDescriptors(
      reshade::api::command_list* cmd_list,
      reshade::api::shader_stage stages,
      reshade::api::pipeline_layout layout,
      uint32_t param_index,
      const reshade::api::descriptor_table_update& update)
   {
      if (test_index == 11) return;

      switch (update.type)
      {
      default:
      break;
#if DEVELOPMENT
      case reshade::api::descriptor_type::constant_buffer:
      {
         for (uint32_t i = 0; i < update.count; i++)
         {
            const reshade::api::buffer_range& buffer_range = static_cast<const reshade::api::buffer_range*>(update.descriptors)[i];
            ID3D11Buffer* buffer = reinterpret_cast<ID3D11Buffer*>(buffer_range.buffer.handle);

            const std::shared_lock lock_trace(s_mutex_trace);
            if (trace_running)
            {
               CommandListData& cmd_list_data = *cmd_list->get_private_data<CommandListData>();
               const std::unique_lock lock_trace_2(cmd_list_data.mutex_trace);
               TraceDrawCallData trace_draw_call_data;
               trace_draw_call_data.type = TraceDrawCallData::TraceDrawCallType::BindResource;
               trace_draw_call_data.command_list = (ID3D11DeviceContext*)(cmd_list->get_native());
               // Re-use the SRV data for simplicity
               GetResourceInfo(buffer, trace_draw_call_data.sr_size[0], trace_draw_call_data.sr_format[0], &trace_draw_call_data.sr_type_name[0], &trace_draw_call_data.sr_hash[0]);
               cmd_list_data.trace_draw_calls_data.push_back(trace_draw_call_data);
            }
         }
      }
#endif
#if UPGRADE_SAMPLERS
      case reshade::api::descriptor_type::sampler:
      {
         auto* device = cmd_list->get_device();
         DeviceData& device_data = *device->get_private_data<DeviceData>();

#if 1 // Optimization hack (it's currently fine with ReShade's code, that data is created on the spot and never used again)
         reshade::api::descriptor_table_update& custom_update = const_cast<reshade::api::descriptor_table_update&>(update);
#else
         reshade::api::descriptor_table_update custom_update = update;
#endif
         bool any_modified = false;
         std::shared_lock shared_lock_samplers(s_mutex_samplers);
         for (uint32_t i = 0; i < update.count; i++)
         {
            const reshade::api::sampler& sampler = static_cast<const reshade::api::sampler*>(update.descriptors)[i];

            const auto custom_sampler_by_original_sampler_it = device_data.custom_sampler_by_original_sampler.find(sampler.handle);
            if (custom_sampler_by_original_sampler_it != device_data.custom_sampler_by_original_sampler.end())
            {
               auto& custom_samplers = custom_sampler_by_original_sampler_it->second;
               const auto custom_sampler_it = custom_samplers.find(device_data.texture_mip_lod_bias_offset);
               const ID3D11SamplerState* custom_sampler_ptr = nullptr;
               // Create the version of this sampler to match the current mip lod bias
               if (custom_sampler_it == custom_samplers.end())
               {
                  const auto last_texture_mip_lod_bias_offset = device_data.texture_mip_lod_bias_offset;
                  shared_lock_samplers.unlock();
                  {
                     ID3D11SamplerState* native_sampler = reinterpret_cast<ID3D11SamplerState*>(sampler.handle);
                     D3D11_SAMPLER_DESC native_desc;
                     native_sampler->GetDesc(&native_desc);
                     std::unique_lock unique_lock_samplers(s_mutex_samplers); // Only lock for reading if necessary. It doesn't matter if we released the shared lock above for a tiny amount of time, it's safe anyway
                     custom_sampler_ptr = (custom_samplers[last_texture_mip_lod_bias_offset] = CreateCustomSampler(device_data, (ID3D11Device*)device->get_native(), native_desc)).get();
                  }
                  shared_lock_samplers.lock();
               }
               else
               {
                  custom_sampler_ptr = custom_sampler_it->second.get();
               }
               // Update the customized descriptor data
               if (custom_sampler_ptr != nullptr)
               {
                  reshade::api::sampler& custom_sampler = ((reshade::api::sampler*)(custom_update.descriptors))[i];
                  custom_sampler.handle = (uint64_t)custom_sampler_ptr;
                  any_modified |= true;
               }
            }
            else
            {
#if DEVELOPMENT & !GAME_MAFIA_III
               // If recursive (already cloned) sampler ptrs are set, it's because the game somehow got the pointers and is re-using them (?),
               // this seems to happen when we change the ImGui settings for samplers a lot and quickly in Prey. It also happens in Mafia III. It shouldn't really hurt as they don't pass through the same init function.
               bool recursive_or_null = sampler.handle == 0;
               for (const auto& samplers_handle : device_data.custom_sampler_by_original_sampler)
               {
                  for (const auto& custom_sampler_handle : samplers_handle.second)
                  {
                     ID3D11SamplerState* native_sampler = reinterpret_cast<ID3D11SamplerState*>(sampler.handle);
                     recursive_or_null |= custom_sampler_handle.second.get() == native_sampler;
                  }
               }
               ASSERT_ONCE(recursive_or_null || samplers_upgrade_mode == 0); // Shouldn't happen! (if we know the sampler set is "recursive", then we are good and don't need to replace this sampler again)
#if 0 // TODO: delete or restore in case the "recursive_or_null" assert above ever triggered (seems like it won't)
               if (sampler.handle != 0)
               {
                  ID3D11SamplerState* native_sampler = reinterpret_cast<ID3D11SamplerState*>(sampler.handle);
                  D3D11_SAMPLER_DESC native_desc;
                  native_sampler->GetDesc(&native_desc);
                  custom_sampler_by_original_sampler[sampler.handle] = CreateCustomSampler(device_data, (ID3D11Device*)device->get_native(), native_desc);
               }
#endif
#endif // DEVELOPMENT
            }
         }

         if (any_modified)
         {
            cmd_list->push_descriptors(stages, layout, param_index, custom_update);
         }
         break;
      }
#endif
      }
   }

#if DEVELOPMENT
   void OnMapBufferRegion(reshade::api::device* device, reshade::api::resource resource, uint64_t offset, uint64_t size, reshade::api::map_access access, void** data)
   {
      DeviceData& device_data = *device->get_private_data<DeviceData>();

      {
         const std::shared_lock lock_trace(s_mutex_trace);
         if (trace_running)
         {
            auto& cmd_list_data = *device_data.primary_command_list_data;
            const std::unique_lock lock_trace_2(cmd_list_data.mutex_trace);
            TraceDrawCallData trace_draw_call_data;
            trace_draw_call_data.type = access == reshade::api::map_access::read_only ? TraceDrawCallData::TraceDrawCallType::CPURead : TraceDrawCallData::TraceDrawCallType::CPUWrite; // The writes could be read too, but we don't have a type for that yet
            trace_draw_call_data.command_list = device_data.primary_command_list;
            ID3D11Resource* target_resource = reinterpret_cast<ID3D11Resource*>(resource.handle);
            // Re-use the SRV/RTV data for simplicity
            if (trace_draw_call_data.type == TraceDrawCallData::TraceDrawCallType::CPURead)
               GetResourceInfo(target_resource, trace_draw_call_data.sr_size[0], trace_draw_call_data.sr_format[0], &trace_draw_call_data.sr_type_name[0], &trace_draw_call_data.sr_hash[0]);
            else
               GetResourceInfo(target_resource, trace_draw_call_data.rt_size[0], trace_draw_call_data.rt_format[0], &trace_draw_call_data.rt_type_name[0], &trace_draw_call_data.rt_hash[0]);
            cmd_list_data.trace_draw_calls_data.push_back(trace_draw_call_data);
         }
      }
   }

   void OnMapTextureRegion(reshade::api::device* device, reshade::api::resource resource, uint32_t subresource, const reshade::api::subresource_box* box, reshade::api::map_access access, reshade::api::subresource_data* data)
   {
      DeviceData& device_data = *device->get_private_data<DeviceData>();

      {
         const std::shared_lock lock_trace(s_mutex_trace);
         if (trace_running)
         {
            auto& cmd_list_data = *device_data.primary_command_list_data;
            const std::unique_lock lock_trace_2(cmd_list_data.mutex_trace);
            TraceDrawCallData trace_draw_call_data;
            trace_draw_call_data.type = access == reshade::api::map_access::read_only ? TraceDrawCallData::TraceDrawCallType::CPURead : TraceDrawCallData::TraceDrawCallType::CPUWrite; // The writes could be read too, but we don't have a type for that yet
            trace_draw_call_data.command_list = device_data.primary_command_list;
            ID3D11Resource* target_resource = reinterpret_cast<ID3D11Resource*>(resource.handle);
            // Re-use the SRV/RTV data for simplicity
            if (trace_draw_call_data.type == TraceDrawCallData::TraceDrawCallType::CPURead)
               GetResourceInfo(target_resource, trace_draw_call_data.sr_size[0], trace_draw_call_data.sr_format[0], &trace_draw_call_data.sr_type_name[0], &trace_draw_call_data.sr_hash[0]);
            else
               GetResourceInfo(target_resource, trace_draw_call_data.rt_size[0], trace_draw_call_data.rt_format[0], &trace_draw_call_data.rt_type_name[0], &trace_draw_call_data.rt_hash[0]);
            cmd_list_data.trace_draw_calls_data.push_back(trace_draw_call_data);
         }
      }

      {
         const std::shared_lock lock(device_data.mutex);
         ASSERT_ONCE(!device_data.upgraded_resources.contains(resource.handle)); // This would probably fail!
      }

#if GAME_PREY // For Prey only (given we manually upgrade resources through native hooks)
      ID3D11Resource* native_resource = reinterpret_cast<ID3D11Resource*>(resource.handle);
      com_ptr<ID3D11Texture2D> resource_texture;
      HRESULT hr = native_resource->QueryInterface(&resource_texture);
      if (SUCCEEDED(hr))
      {
         D3D11_TEXTURE2D_DESC texture_2d_desc;
         resource_texture->GetDesc(&texture_2d_desc);
         if ((texture_2d_desc.BindFlags & D3D11_BIND_RENDER_TARGET) != 0)
         {
            // Probably not supported, at least if it's an RT and we upgraded the format
            ASSERT_ONCE(texture_2d_desc.Format != DXGI_FORMAT_R16G16B16A16_TYPELESS && texture_2d_desc.Format != DXGI_FORMAT_R16G16B16A16_FLOAT);
         }
      }
#endif
   }

   bool OnUpdateBufferRegion(reshade::api::device* device, const void* data, reshade::api::resource resource, uint64_t offset, uint64_t size)
   {
      DeviceData& device_data = *device->get_private_data<DeviceData>();

      {
         const std::shared_lock lock_trace(s_mutex_trace);
         if (trace_running)
         {
            auto& cmd_list_data = *device_data.primary_command_list_data;
            const std::unique_lock lock_trace_2(cmd_list_data.mutex_trace);
            TraceDrawCallData trace_draw_call_data;
            trace_draw_call_data.type = TraceDrawCallData::TraceDrawCallType::CPUWrite;
            trace_draw_call_data.command_list = device_data.primary_command_list;
            ID3D11Resource* target_resource = reinterpret_cast<ID3D11Resource*>(resource.handle);
            // Re-use the RTV data for simplicity
            GetResourceInfo(target_resource, trace_draw_call_data.rt_size[0], trace_draw_call_data.rt_format[0], &trace_draw_call_data.rt_type_name[0], &trace_draw_call_data.rt_hash[0]);
            cmd_list_data.trace_draw_calls_data.push_back(trace_draw_call_data);
         }
      }

      ID3D11Buffer* buffer = reinterpret_cast<ID3D11Buffer*>(resource.handle);
      // Verify that we didn't miss any changes to the global g-buffer
      ASSERT_ONCE(!device_data.has_drawn_main_post_processing_previous || !device_data.cb_per_view_global_buffers.contains(buffer));

      return false;
   }

   bool OnUpdateTextureRegion(reshade::api::device* device, const reshade::api::subresource_data& data, reshade::api::resource resource, uint32_t subresource, const reshade::api::subresource_box* box)
   {
      DeviceData& device_data = *device->get_private_data<DeviceData>();

      {
         const std::shared_lock lock_trace(s_mutex_trace);
         if (trace_running)
         {
            auto& cmd_list_data = *device_data.primary_command_list_data;
            const std::unique_lock lock_trace_2(cmd_list_data.mutex_trace);
            TraceDrawCallData trace_draw_call_data;
            trace_draw_call_data.type = TraceDrawCallData::TraceDrawCallType::CPUWrite;
            trace_draw_call_data.command_list = device_data.primary_command_list;
            ID3D11Resource* target_resource = reinterpret_cast<ID3D11Resource*>(resource.handle);
            // Re-use the RTV data for simplicity
            GetResourceInfo(target_resource, trace_draw_call_data.rt_size[0], trace_draw_call_data.rt_format[0], &trace_draw_call_data.rt_type_name[0], &trace_draw_call_data.rt_hash[0]);
            cmd_list_data.trace_draw_calls_data.push_back(trace_draw_call_data);
         }
      }

      {
         const std::shared_lock lock(device_data.mutex);
         ASSERT_ONCE(!device_data.upgraded_resources.contains(resource.handle)); // If this happened, we need to upgrade the data passed in to match the new format! //TODOFT5: happens in Dishonored 2 (on boot, probably doesn't matter, it might be all black, but still, unsafe)
      }

#if GAME_PREY // For Prey only (given we manually upgrade resources through native hooks)
      ID3D11Resource* native_resource = reinterpret_cast<ID3D11Resource*>(resource.handle);
      com_ptr<ID3D11Texture2D> resource_texture;
      HRESULT hr = native_resource->QueryInterface(&resource_texture);
      if (SUCCEEDED(hr))
      {
         D3D11_TEXTURE2D_DESC texture_2d_desc;
         resource_texture->GetDesc(&texture_2d_desc);
         if ((texture_2d_desc.BindFlags & D3D11_BIND_RENDER_TARGET) != 0)
         {
            // Probably not supported, at least if it's an RT and we upgraded the format
            ASSERT_ONCE(texture_2d_desc.Format != DXGI_FORMAT_R16G16B16A16_TYPELESS && texture_2d_desc.Format != DXGI_FORMAT_R16G16B16A16_FLOAT);
         }
      }
#endif

      return false;
   }

   bool OnClearRenderTargetView(reshade::api::command_list* cmd_list, reshade::api::resource_view rtv, const float color[4], uint32_t rect_count, const reshade::api::rect* rects)
   {
      {
         const std::shared_lock lock_trace(s_mutex_trace);
         if (trace_running)
         {
            CommandListData& cmd_list_data = *cmd_list->get_private_data<CommandListData>();
            const std::unique_lock lock_trace_2(cmd_list_data.mutex_trace);
            TraceDrawCallData trace_draw_call_data;
            trace_draw_call_data.type = TraceDrawCallData::TraceDrawCallType::ClearResource;
            trace_draw_call_data.command_list = (ID3D11DeviceContext*)(cmd_list->get_native());
            ID3D11Resource* target_resource = reinterpret_cast<ID3D11Resource*>(cmd_list->get_device()->get_resource_from_view(rtv).handle);
            // Re-use the RTV data for simplicity
            GetResourceInfo(target_resource, trace_draw_call_data.rt_size[0], trace_draw_call_data.rt_format[0], &trace_draw_call_data.rt_type_name[0], &trace_draw_call_data.rt_hash[0]);
            cmd_list_data.trace_draw_calls_data.push_back(trace_draw_call_data);
         }
      }
      return false;
   }

   bool OnClearUnorderedAccessViewUInt(reshade::api::command_list* cmd_list, reshade::api::resource_view uav, const uint32_t values[4], uint32_t rect_count, const reshade::api::rect* rects)
   {
      {
         const std::shared_lock lock_trace(s_mutex_trace);
         if (trace_running)
         {
            CommandListData& cmd_list_data = *cmd_list->get_private_data<CommandListData>();
            const std::unique_lock lock_trace_2(cmd_list_data.mutex_trace);
            TraceDrawCallData trace_draw_call_data;
            trace_draw_call_data.type = TraceDrawCallData::TraceDrawCallType::ClearResource;
            trace_draw_call_data.command_list = (ID3D11DeviceContext*)(cmd_list->get_native());
            ID3D11Resource* target_resource = reinterpret_cast<ID3D11Resource*>(cmd_list->get_device()->get_resource_from_view(uav).handle);
            // Re-use the RTV data for simplicity
            GetResourceInfo(target_resource, trace_draw_call_data.rt_size[0], trace_draw_call_data.rt_format[0], &trace_draw_call_data.rt_type_name[0], &trace_draw_call_data.rt_hash[0]);
            cmd_list_data.trace_draw_calls_data.push_back(trace_draw_call_data);
         }
      }
      return false;
   }

   bool OnClearUnorderedAccessViewFloat(reshade::api::command_list* cmd_list, reshade::api::resource_view uav, const float values[4], uint32_t rect_count, const reshade::api::rect* rects)
   {
      {
         const std::shared_lock lock_trace(s_mutex_trace);
         if (trace_running)
         {
            CommandListData& cmd_list_data = *cmd_list->get_private_data<CommandListData>();
            const std::unique_lock lock_trace_2(cmd_list_data.mutex_trace);
            TraceDrawCallData trace_draw_call_data;
            trace_draw_call_data.type = TraceDrawCallData::TraceDrawCallType::ClearResource;
            trace_draw_call_data.command_list = (ID3D11DeviceContext*)(cmd_list->get_native());
            ID3D11Resource* target_resource = reinterpret_cast<ID3D11Resource*>(cmd_list->get_device()->get_resource_from_view(uav).handle);
            // Re-use the RTV data for simplicity
            GetResourceInfo(target_resource, trace_draw_call_data.rt_size[0], trace_draw_call_data.rt_format[0], &trace_draw_call_data.rt_type_name[0], &trace_draw_call_data.rt_hash[0]);
            cmd_list_data.trace_draw_calls_data.push_back(trace_draw_call_data);
         }
      }
      return false;
   }
#endif // DEVELOPMENT

   bool OnCopyResource(reshade::api::command_list* cmd_list, reshade::api::resource source, reshade::api::resource dest)
   {
#if DEVELOPMENT
      {
         const std::shared_lock lock_trace(s_mutex_trace);
         if (trace_running)
         {
            CommandListData& cmd_list_data = *cmd_list->get_private_data<CommandListData>();
            const std::unique_lock lock_trace_2(cmd_list_data.mutex_trace);
            TraceDrawCallData trace_draw_call_data;
            trace_draw_call_data.type = TraceDrawCallData::TraceDrawCallType::CopyResource;
            trace_draw_call_data.command_list = (ID3D11DeviceContext*)(cmd_list->get_native());
            ID3D11Resource* source_resource = reinterpret_cast<ID3D11Resource*>(source.handle);
            ID3D11Resource* target_resource = reinterpret_cast<ID3D11Resource*>(dest.handle);
            // Re-use the SRV and RTV data for simplicity
            GetResourceInfo(source_resource, trace_draw_call_data.sr_size[0], trace_draw_call_data.sr_format[0], &trace_draw_call_data.sr_type_name[0], &trace_draw_call_data.sr_hash[0]);
            GetResourceInfo(target_resource, trace_draw_call_data.rt_size[0], trace_draw_call_data.rt_format[0], &trace_draw_call_data.rt_type_name[0], &trace_draw_call_data.rt_hash[0]);
            cmd_list_data.trace_draw_calls_data.push_back(trace_draw_call_data);
         }
      }
#endif

      DeviceData& device_data = *cmd_list->get_device()->get_private_data<DeviceData>();
      bool upgraded_resources = false;

      if (!enable_upgraded_texture_resource_copy_redirection)
         return false;

      if (!enable_swapchain_upgrade && !enable_texture_format_upgrades)
         return false;

      // Skip if none of the resources match our upgraded ones.
      // This should always be fine, unless the game used the upgraded resource desc to automatically determine other textures (so we try to catch for that in development)
      const std::shared_lock lock(device_data.mutex);
      if (!device_data.upgraded_resources.contains(source.handle) && !device_data.upgraded_resources.contains(dest.handle))
      {
#if !DEVELOPMENT
         return false;
#endif
         upgraded_resources = true;
      }

      ID3D11Resource* source_resource = reinterpret_cast<ID3D11Resource*>(source.handle);
      com_ptr<ID3D11Texture2D> source_resource_texture;
      HRESULT hr = source_resource->QueryInterface(&source_resource_texture);
      if (SUCCEEDED(hr))
      {
         ID3D11Resource* target_resource = reinterpret_cast<ID3D11Resource*>(dest.handle);
         com_ptr<ID3D11Texture2D> target_resource_texture;
         hr = target_resource->QueryInterface(&target_resource_texture);
         if (SUCCEEDED(hr))
         {
            D3D11_TEXTURE2D_DESC source_desc;
            D3D11_TEXTURE2D_DESC target_desc;
            source_resource_texture->GetDesc(&source_desc);
            target_resource_texture->GetDesc(&target_desc);

            if (source_desc.Width != target_desc.Width || source_desc.Height != target_desc.Height || source_desc.ArraySize != target_desc.ArraySize || source_desc.SampleDesc.Count != target_desc.SampleDesc.Count || source_desc.MipLevels != target_desc.MipLevels)
               return false;

            auto isUnorm8 = [](DXGI_FORMAT format)
               {
                  switch (format)
                  {
                  case DXGI_FORMAT_R8G8B8A8_TYPELESS:
                  case DXGI_FORMAT_R8G8B8A8_UNORM:
                  case DXGI_FORMAT_R8G8B8A8_UNORM_SRGB:
                  case DXGI_FORMAT_B8G8R8A8_UNORM:
                  case DXGI_FORMAT_B8G8R8X8_UNORM:
                  case DXGI_FORMAT_B8G8R8A8_TYPELESS:
                  case DXGI_FORMAT_B8G8R8A8_UNORM_SRGB:
                  case DXGI_FORMAT_B8G8R8X8_TYPELESS:
                  case DXGI_FORMAT_B8G8R8X8_UNORM_SRGB:
                  // Hacky case (just as a shortcut)
                  case DXGI_FORMAT_R10G10B10A2_TYPELESS:
                  case DXGI_FORMAT_R10G10B10A2_UNORM:
                  return true;
                  }
                  return false;
               };
            auto isUnorm16 = [](DXGI_FORMAT format)
               {
                  switch (format)
                  {
                  case DXGI_FORMAT_R16G16B16A16_TYPELESS:
                  case DXGI_FORMAT_R16G16B16A16_UNORM:
                  return true;
                  }
                  return false;
               };
            auto isFloat16 = [](DXGI_FORMAT format)
               {
                  switch (format)
                  {
                  case DXGI_FORMAT_R16G16B16A16_TYPELESS:
                  case DXGI_FORMAT_R16G16B16A16_FLOAT:
                  return true;
                  }
                  return false;
               };
            auto isFloat11 = [](DXGI_FORMAT format)
               {
                  switch (format)
                  {
                  case DXGI_FORMAT_R11G11B10_FLOAT:
                  return true;
                  }
                  return false;
               };

            // If we detected incompatible formats that were likely caused by Luma upgrading texture formats (of render targets only...),
            // do the copy in shader. It should currently cover all texture formats upgradable with "texture_upgrade_formats".
            // If we ever made a new type of "swapchain_upgrade_type", this should be updated for that.
            // Note that generally, formats of the same size might be supported as it simply does a byte copy,
            // like DXGI_FORMAT_R16G16B16A16_TYPELESS, DXGI_FORMAT_R16G16B16A16_UNORM and DXGI_FORMAT_R16G16B16A16_FLOAT are all mutually compatible.
            // TODO: add gamma to linear support (e.g. non sRGB views into sRGB views)?
            if (((isUnorm8(target_desc.Format) || isFloat11(target_desc.Format)) && isFloat16(source_desc.Format))
               || ((isUnorm8(source_desc.Format) || isFloat11(source_desc.Format)) && isFloat16(target_desc.Format)))
            {
               ASSERT_ONCE_MSG(upgraded_resources, "The game seeengly tried to copy incompatible resource formats for resources that were not upgraded by us");

               // These are not supported at the moment
               if (target_desc.ArraySize != 1 || target_desc.SampleDesc.Count != 1 || target_desc.MipLevels != 1)
               {
                  ASSERT_ONCE_MSG(false, "Unsupported resource desc in redirected resource copy");
                  return false;
               }

               const std::shared_lock lock(s_mutex_shader_objects);
               if (device_data.copy_vertex_shader == nullptr || device_data.copy_pixel_shader == nullptr)
               {
                  ASSERT_ONCE_MSG(false, "The Copy Resource Luma native shaders failed to be found (they have either been unloaded or failed to compile, or simply missing in the files)");
                  // We can't continue, drawing with empty shaders would crash or skip the call
                  return false;
               }

               const auto* device = cmd_list->get_device();
               ID3D11Device* native_device = (ID3D11Device*)(device->get_native());
               ID3D11DeviceContext* native_device_context = (ID3D11DeviceContext*)(cmd_list->get_native());

               //
               // Prepare resources:
               //
               com_ptr<ID3D11Texture2D> proxy_source_resource_texture = source_resource_texture;
               // We need to make a double copy if the source texture isn't a shader resource
               if ((source_desc.BindFlags & D3D11_BIND_SHADER_RESOURCE) == 0)
               {
                  D3D11_TEXTURE2D_DESC proxy_source_desc;
                  if (device_data.temp_copy_source_texture.get() != nullptr)
                  {
                     device_data.temp_copy_source_texture->GetDesc(&proxy_source_desc);
                  }
                  if (device_data.temp_copy_source_texture.get() == nullptr || proxy_source_desc.Width || proxy_source_desc.Width != source_desc.Width || proxy_source_desc.Height != source_desc.Height || proxy_source_desc.Format != source_desc.Format || proxy_source_desc.ArraySize != source_desc.ArraySize || proxy_source_desc.MipLevels != source_desc.MipLevels || proxy_source_desc.SampleDesc.Count != source_desc.SampleDesc.Count)
                  {
                     device_data.temp_copy_source_texture = CloneTexture<ID3D11Texture2D>(native_device, source_resource_texture.get(), DXGI_FORMAT_UNKNOWN, D3D11_BIND_SHADER_RESOURCE, D3D11_BIND_RENDER_TARGET | D3D11_BIND_DEPTH_STENCIL | D3D11_BIND_UNORDERED_ACCESS, false, true, native_device_context);
                     proxy_source_resource_texture = device_data.temp_copy_source_texture;
                  }
               }
               com_ptr<ID3D11ShaderResourceView> source_resource_texture_view;
               D3D11_SHADER_RESOURCE_VIEW_DESC source_srv_desc;
               source_srv_desc.Format = source_desc.Format;
               // Redirect typeless and sRGB formats to classic UNORM, the "copy resource" functions wouldn't distinguish between these, as they copy by byte.
               switch (source_srv_desc.Format)
               {
               case DXGI_FORMAT_R10G10B10A2_TYPELESS:
                  source_srv_desc.Format = DXGI_FORMAT_R10G10B10A2_UNORM;
                  break;
               case DXGI_FORMAT_R8G8B8A8_TYPELESS:
               case DXGI_FORMAT_R8G8B8A8_UNORM_SRGB:
                  source_srv_desc.Format = DXGI_FORMAT_R8G8B8A8_UNORM;
                  break;
               case DXGI_FORMAT_B8G8R8A8_TYPELESS:
               case DXGI_FORMAT_B8G8R8A8_UNORM_SRGB:
                  source_srv_desc.Format = DXGI_FORMAT_B8G8R8A8_UNORM;
                  break;
               case DXGI_FORMAT_B8G8R8X8_TYPELESS:
               case DXGI_FORMAT_B8G8R8X8_UNORM_SRGB:
                  source_srv_desc.Format = DXGI_FORMAT_B8G8R8X8_UNORM;
                  break;
               case DXGI_FORMAT_R16G16B16A16_TYPELESS:
                  source_srv_desc.Format = DXGI_FORMAT_R16G16B16A16_FLOAT;
                  break;
               }
               source_srv_desc.ViewDimension = D3D11_SRV_DIMENSION::D3D11_SRV_DIMENSION_TEXTURE2D;
               source_srv_desc.Texture2D.MipLevels = 1;
               source_srv_desc.Texture2D.MostDetailedMip = 0;
               hr = native_device->CreateShaderResourceView(proxy_source_resource_texture.get(), &source_srv_desc, &source_resource_texture_view);
               ASSERT_ONCE(SUCCEEDED(hr));

               com_ptr<ID3D11Texture2D> proxy_target_resource_texture = target_resource_texture;
               // We need to make a double copy if the target texture isn't a render target, unfortunately (we could intercept its creation and add the flag, or replace any further usage in this frame by redirecting all pointers
               // to the new copy we made, but for now this works)
               // TODO: we could also check if the target texture supports UAV writes (unlikely) and fall back on a Copy Compute Shader instead of a Pixel Shader, to avoid two/three further texture copies, though that's a rare case
               if ((target_desc.BindFlags & D3D11_BIND_RENDER_TARGET) == 0)
               {
                  // Create the persisting texture copy if necessary (if anything changed from the last copy).
                  // Theoretically all these textures have the same resolution as the screen so having one persistent texture should be ok.
                  // TODO: create more than one texture (one per format and one per resolution?) if ever needed
                  D3D11_TEXTURE2D_DESC proxy_target_desc;
                  if (device_data.temp_copy_target_texture.get() != nullptr)
                  {
                     device_data.temp_copy_target_texture->GetDesc(&proxy_target_desc);
                  }
                  if (device_data.temp_copy_target_texture.get() == nullptr || proxy_target_desc.Width != target_desc.Width || proxy_target_desc.Height != target_desc.Height || proxy_target_desc.Format != target_desc.Format || proxy_target_desc.ArraySize != target_desc.ArraySize || proxy_target_desc.MipLevels != target_desc.MipLevels || proxy_target_desc.SampleDesc.Count != target_desc.SampleDesc.Count)
                  {
                     device_data.temp_copy_target_texture = CloneTexture<ID3D11Texture2D>(native_device, target_resource_texture.get(), DXGI_FORMAT_UNKNOWN, D3D11_BIND_RENDER_TARGET, D3D11_BIND_SHADER_RESOURCE | D3D11_BIND_DEPTH_STENCIL | D3D11_BIND_UNORDERED_ACCESS, false, false);
                  }
                  proxy_target_resource_texture = device_data.temp_copy_target_texture;
               }

               com_ptr<ID3D11RenderTargetView> target_resource_texture_view;
               D3D11_RENDER_TARGET_VIEW_DESC target_rtv_desc;
               target_rtv_desc.Format = target_desc.Format;
               switch (target_rtv_desc.Format)
               {
               case DXGI_FORMAT_R10G10B10A2_TYPELESS:
                  target_rtv_desc.Format = DXGI_FORMAT_R10G10B10A2_UNORM;
                  break;
               case DXGI_FORMAT_R8G8B8A8_TYPELESS:
               case DXGI_FORMAT_R8G8B8A8_UNORM_SRGB:
                  target_rtv_desc.Format = DXGI_FORMAT_R8G8B8A8_UNORM;
                  break;
               case DXGI_FORMAT_B8G8R8A8_TYPELESS:
               case DXGI_FORMAT_B8G8R8A8_UNORM_SRGB:
                  target_rtv_desc.Format = DXGI_FORMAT_B8G8R8A8_UNORM;
                  break;
               case DXGI_FORMAT_B8G8R8X8_TYPELESS:
               case DXGI_FORMAT_B8G8R8X8_UNORM_SRGB:
                  target_rtv_desc.Format = DXGI_FORMAT_B8G8R8X8_UNORM;
                  break;
               case DXGI_FORMAT_R16G16B16A16_TYPELESS:
                  target_rtv_desc.Format = DXGI_FORMAT_R16G16B16A16_FLOAT;
                  break;
               }
               target_rtv_desc.ViewDimension = D3D11_RTV_DIMENSION_TEXTURE2D;
               target_rtv_desc.Texture2D.MipSlice = 0;
               hr = native_device->CreateRenderTargetView(proxy_target_resource_texture.get(), &target_rtv_desc, &target_resource_texture_view);
               ASSERT_ONCE(SUCCEEDED(hr));

               DrawStateStack<DrawStateStackType::SimpleGraphics> draw_state_stack;
               draw_state_stack.Cache(native_device_context, device_data.uav_max_count);

               DrawCustomPixelShader(native_device_context, device_data.default_depth_stencil_state.get(), device_data.default_blend_state.get(), device_data.copy_vertex_shader.get(), device_data.copy_pixel_shader.get(), source_resource_texture_view.get(), target_resource_texture_view.get(), target_desc.Width, target_desc.Height, true);

#if DEVELOPMENT
               {
                  const std::shared_lock lock_trace(s_mutex_trace);
                  if (trace_running)
                  {
                     const std::shared_lock lock_generic(s_mutex_generic);
                     CommandListData& cmd_list_data = *cmd_list->get_private_data<CommandListData>();
                     const std::unique_lock lock_trace_2(cmd_list_data.mutex_trace);
                     const std::lock_guard<std::recursive_mutex> lock_dumping(s_mutex_dumping);

                     // Highlight that the next capture data is redirected
                     TraceDrawCallData trace_draw_call_data;
                     trace_draw_call_data.type = TraceDrawCallData::TraceDrawCallType::Custom;
                     trace_draw_call_data.command_list = native_device_context;
                     trace_draw_call_data.custom_name = "Redirected Copy Resource";
                     GetResourceInfo(source_resource_texture.get(), trace_draw_call_data.sr_size[0], trace_draw_call_data.sr_format[0], &trace_draw_call_data.sr_type_name[0], &trace_draw_call_data.sr_hash[0], &trace_draw_call_data.sr_is_rt[0]);
                     GetResourceInfo(target_resource_texture.get(), trace_draw_call_data.rt_size[0], trace_draw_call_data.rt_format[0], &trace_draw_call_data.rt_type_name[0], &trace_draw_call_data.rt_hash[0]);
                     cmd_list_data.trace_draw_calls_data.push_back(trace_draw_call_data);
                  }
               }
#endif

               //
               // Copy our render target target resource into the non render target target resource if necessary:
               //
               if ((target_desc.BindFlags & D3D11_BIND_RENDER_TARGET) == 0)
               {
                  native_device_context->CopyResource(target_resource_texture.get(), proxy_target_resource_texture.get());
               }

               draw_state_stack.Restore(native_device_context);
               return true;
            }
         }
      }

      return false;
   }

   bool OnCopyTextureRegion(reshade::api::command_list* cmd_list, reshade::api::resource source, uint32_t source_subresource, const reshade::api::subresource_box* source_box, reshade::api::resource dest, uint32_t dest_subresource, const reshade::api::subresource_box* dest_box, reshade::api::filter_mode filter /*Unused in DX11*/)
   {
      if (source_subresource == 0 && dest_subresource == 0 && (!source_box || (source_box->left == 0 && source_box->top == 0)) && (!dest_box || (dest_box->left == 0 && dest_box->top == 0)) && (!dest_box || !source_box || (source_box->width() == dest_box->width() && source_box->height() == dest_box->height())))
      {
         return OnCopyResource(cmd_list, source, dest);
      }
#if DEVELOPMENT
      else
      {
         const std::shared_lock lock_trace(s_mutex_trace);
         if (trace_running)
         {
            CommandListData& cmd_list_data = *cmd_list->get_private_data<CommandListData>();
            const std::unique_lock lock_trace_2(cmd_list_data.mutex_trace);
            TraceDrawCallData trace_draw_call_data;
            trace_draw_call_data.type = TraceDrawCallData::TraceDrawCallType::CopyResource;
            trace_draw_call_data.command_list = (ID3D11DeviceContext*)(cmd_list->get_native());
            ID3D11Resource* source_resource = reinterpret_cast<ID3D11Resource*>(source.handle);
            ID3D11Resource* target_resource = reinterpret_cast<ID3D11Resource*>(dest.handle);
            // Re-use the SRV and RTV data for simplicity
            GetResourceInfo(source_resource, trace_draw_call_data.sr_size[0], trace_draw_call_data.sr_format[0], &trace_draw_call_data.sr_type_name[0], &trace_draw_call_data.sr_hash[0]);
            GetResourceInfo(target_resource, trace_draw_call_data.rt_size[0], trace_draw_call_data.rt_format[0], &trace_draw_call_data.rt_type_name[0], &trace_draw_call_data.rt_hash[0]);
            cmd_list_data.trace_draw_calls_data.push_back(trace_draw_call_data);
         }
      }
#endif
      return false;
   }

   bool OnResolveTextureRegion(reshade::api::command_list* cmd_list, reshade::api::resource source, uint32_t source_subresource, const reshade::api::subresource_box* source_box, reshade::api::resource dest, uint32_t dest_subresource, uint32_t dest_x, uint32_t dest_y, uint32_t dest_z, reshade::api::format format)
   {
      if (source_subresource == 0 && dest_subresource == 0 && (!source_box || (source_box->left == 0 && source_box->top == 0)) && (dest_x == 0 && dest_y == 0 && dest_z == 0))
      {
         return OnCopyResource(cmd_list, source, dest);
      }
#if DEVELOPMENT
      else
      {
         const std::shared_lock lock_trace(s_mutex_trace);
         if (trace_running)
         {
            CommandListData& cmd_list_data = *cmd_list->get_private_data<CommandListData>();
            const std::unique_lock lock_trace_2(cmd_list_data.mutex_trace);
            TraceDrawCallData trace_draw_call_data;
            trace_draw_call_data.type = TraceDrawCallData::TraceDrawCallType::CopyResource;
            trace_draw_call_data.command_list = (ID3D11DeviceContext*)(cmd_list->get_native());
            ID3D11Resource* source_resource = reinterpret_cast<ID3D11Resource*>(source.handle);
            ID3D11Resource* target_resource = reinterpret_cast<ID3D11Resource*>(dest.handle);
            // Re-use the SRV and RTV data for simplicity
            GetResourceInfo(source_resource, trace_draw_call_data.sr_size[0], trace_draw_call_data.sr_format[0], &trace_draw_call_data.sr_type_name[0], &trace_draw_call_data.sr_hash[0]);
            GetResourceInfo(target_resource, trace_draw_call_data.rt_size[0], trace_draw_call_data.rt_format[0], &trace_draw_call_data.rt_type_name[0], &trace_draw_call_data.rt_hash[0]);
            cmd_list_data.trace_draw_calls_data.push_back(trace_draw_call_data);
         }
      }
#endif // DEVELOPMENT

      ASSERT_ONCE(false);
      return false;
   }

   void OnReShadePresent(reshade::api::effect_runtime* runtime)
   {
      DeviceData& device_data = *runtime->get_device()->get_private_data<DeviceData>();
#if DEVELOPMENT
      {
         const std::unique_lock lock_trace(s_mutex_trace);
         if (trace_running)
         {
#if _DEBUG && LOG_VERBOSE
            reshade::log::message(reshade::log::level::info, "present()");
            reshade::log::message(reshade::log::level::info, "--- End Frame ---");
#endif
            trace_running = false;
            CommandListData& cmd_list_data = *runtime->get_command_queue()->get_immediate_command_list()->get_private_data<CommandListData>();
            const std::shared_lock lock_trace_2(cmd_list_data.mutex_trace);
            trace_count = cmd_list_data.trace_draw_calls_data.size();
         }
         else if (trace_scheduled)
         {
#if _DEBUG && LOG_VERBOSE
            reshade::log::message(reshade::log::level::info, "--- Frame ---");
#endif
            // Split the trace logic over "two" frames, to make sure we capture everything in between two present calls
            trace_scheduled = false;
            {
               CommandListData& cmd_list_data = *runtime->get_command_queue()->get_immediate_command_list()->get_private_data<CommandListData>();
               const std::unique_lock lock_trace_2(cmd_list_data.mutex_trace);
               cmd_list_data.trace_draw_calls_data.clear();
            }
            trace_count = 0;
            trace_running = true;
         }
      }
#endif // DEVELOPMENT

      // Dump new shaders (checking the "shaders_to_dump" count is theoretically not thread safe but it should work nonetheless as this is run every frame)
      if (auto_dump && !thread_auto_dumping_running && !shaders_to_dump.empty())
      {
         if (thread_auto_dumping.joinable())
         {
            thread_auto_dumping.join();
         }
         thread_auto_dumping_running = true;
         thread_auto_dumping = std::thread(AutoDumpShaders);
      }

      s_mutex_loading.lock_shared();
      // Load new shaders
      // We avoid running this if "thread_auto_compiling" is still running from boot.
      // Note that this thread doesn't really need to be by "device", but we did so to make it simpler, to automatically handle the "CreateCustomDeviceShaders()" shaders.
      if (auto_load && !last_pressed_unload && !thread_auto_compiling_running && !device_data.thread_auto_loading_running && !device_data.pipelines_to_reload.empty())
      {
         s_mutex_loading.unlock_shared();
         if (device_data.thread_auto_loading.joinable())
         {
            device_data.thread_auto_loading.join();
         }
         device_data.thread_auto_loading_running = true;
         device_data.thread_auto_loading = std::thread(AutoLoadShaders, &device_data);
      }
      else
      {
         s_mutex_loading.unlock_shared();
      }

      // Destroy the cloned pipelines in the following frame to avoid crashes
      bool has_pipelines_to_destroy = false;
      {
         // This is fine because we can afford delaying it even further in case they were changed in between the read and write locks here
         const std::shared_lock lock(s_mutex_generic);
         has_pipelines_to_destroy = !device_data.pipelines_to_destroy.empty();

      }
      if (has_pipelines_to_destroy)
      {
         const std::unique_lock lock(s_mutex_generic);
         for (auto pair : device_data.pipelines_to_destroy)
         {
            pair.second->destroy_pipeline(reshade::api::pipeline{ pair.first });
         }
         device_data.pipelines_to_destroy.clear();
      }

      if (needs_unload_shaders)
      {
         {
            const std::unique_lock lock_loading(s_mutex_loading);
            shaders_compilation_errors.clear();
         }
         UnloadCustomShaders(device_data);
#if 1 // Optionally unload all custom shaders data
         {
            const std::unique_lock lock_loading(s_mutex_loading);
            custom_shaders_cache.clear();
         }
#endif
         needs_unload_shaders = false;

#if !FORCE_KEEP_CUSTOM_SHADERS_LOADED
         // Unload customly created shader objects (from the shader code/binaries above),
         // to make sure they will re-create
         {
            const std::unique_lock lock(s_mutex_shader_objects);
            device_data.copy_vertex_shader = nullptr;
            device_data.copy_pixel_shader = nullptr;
            device_data.display_composition_pixel_shader = nullptr;
            device_data.draw_purple_pixel_shader = nullptr;
            device_data.draw_purple_compute_shader = nullptr;
            device_data.normalize_lut_3d_compute_shader = nullptr;
            static_assert(false, "Please add a function to clean up custom shader objects in game's implementations")
         }
#endif
      }

      if (!block_draw_until_device_custom_shaders_creation) s_mutex_shader_objects.lock_shared();
      // Force re-load shaders (which will also end up re-creating the custom device shaders) if async shaders loading on boot finished without being able to create custom shaders
      if (needs_load_shaders || (!block_draw_until_device_custom_shaders_creation && !thread_auto_compiling_running && !device_data.created_custom_shaders))
      {
         if (!block_draw_until_device_custom_shaders_creation) s_mutex_shader_objects.unlock_shared();
         // Cache the defines at compilation time
         {
            const std::unique_lock lock(s_mutex_shader_defines);
            ShaderDefineData::OnCompilation(shader_defines_data);
            shader_defines_data_index.clear();
            for (int i = 0; i < shader_defines_data.size(); i++)
            {
               shader_defines_data_index[string_view_crc32(std::string_view(shader_defines_data[i].compiled_data.GetName()))] = i;
            }
         }
         LoadCustomShaders(device_data);
         needs_load_shaders = false;
      }
      else
      {
         if (!block_draw_until_device_custom_shaders_creation) s_mutex_shader_objects.unlock_shared();
      }
   }

   bool OnReShadeSetEffectsState(reshade::api::effect_runtime* runtime, bool enabled)
   {
      DeviceData& device_data = *runtime->get_device()->get_private_data<DeviceData>();
      // Note that this is not called on startup (even if the ReShade effects are enabled by default)
      // We were going to read custom keyboard events like this "GetAsyncKeyState(VK_ESCAPE) & 0x8000", but this seems like a better design
      needs_unload_shaders = !enabled;
      last_pressed_unload = !enabled;
      needs_load_shaders = enabled; // This also re-compile shaders possibly
      const std::unique_lock lock(s_mutex_loading);
      device_data.pipelines_to_reload.clear();
      return false; // You can return true to deny the change
   }

   // Note that this can also happen when entering or exiting "FSE" games given that often they change resolutions (e.g. old DICE games, Unreal Engine games, ...)
   void OnReShadeReloadedEffects(reshade::api::effect_runtime* runtime)
   {
      if (!last_pressed_unload)
      {
         OnReShadeSetEffectsState(runtime, true); // This will load and recompile all shaders (there's no need to delete the previous pre-compiled cache)
      }
   }

#pragma optimize("t", on) // Temporarily override optimization
   // Expects "s_mutex_dumping"
   void DumpShader(uint32_t shader_hash)
   {
#if !ALLOW_SHADERS_DUMPING
      ASSERT_ONCE(false); // Shouldn't call this function if the feature is disabled
#else // Note: this might work with "DEVELOPMENT" too, but possibly not entirely
      auto dump_path = GetShadersRootPath();
      if (!std::filesystem::exists(dump_path))
      {
         std::filesystem::create_directories(dump_path);
      }
      // TODO: cache this once on boot?
      dump_path = dump_path / Globals::GAME_NAME / (std::string("Dump") + (sub_game_shaders_appendix.empty() ? "" : " ") + sub_game_shaders_appendix); // We dump in the game specific folder
      if (!std::filesystem::exists(dump_path))
      {
         std::filesystem::create_directories(dump_path);
      }
      else if (!std::filesystem::is_directory(dump_path))
      {
         ASSERT_ONCE_MSG(false, "The target path is already taken by a file");
         return;
      }

      dump_path /= Shader::Hash_NumToStr(shader_hash, true);

      auto* cached_shader = shader_cache.find(shader_hash)->second;

      // Automatically append the shader type and version
      if (!cached_shader->type_and_version.empty())
      {
         dump_path += ".";
         dump_path += cached_shader->type_and_version;
      }

      dump_path += L".cso";

      // If the shader was already serialized, make sure the new one is of the same size, to catch the near impossible case
      // of two different shaders having the same hash
      if (std::filesystem::is_regular_file(dump_path))
      {
         ASSERT_ONCE(std::filesystem::file_size(dump_path) == cached_shader->size);
      }

      try
      {
         std::ofstream file(dump_path, std::ios::binary);

         file.write(static_cast<const char*>(cached_shader->data), cached_shader->size);

         if (!dumped_shaders.contains(shader_hash))
         {
            dumped_shaders.emplace(shader_hash);
         }
      }
      catch (const std::exception& e)
      {
      }
#endif
   }

   void AutoDumpShaders()
   {
      // Copy the "shaders_to_dump" so we don't have to lock "s_mutex_dumping" all the times
      std::unordered_set<uint32_t> shaders_to_dump_copy;
      {
         const std::lock_guard<std::recursive_mutex> lock_dumping(s_mutex_dumping);
         if (shaders_to_dump.empty())
         {
            thread_auto_dumping_running = false;
            return;
         }
         shaders_to_dump_copy = shaders_to_dump;
         shaders_to_dump.clear();
      }

#if DEVELOPMENT && TEST_DUPLICATE_SHADER_HASH
      std::unordered_set<std::filesystem::path> dumped_shaders_paths;
      auto dump_path = GetShadersRootPath() / Globals::GAME_NAME / (std::string("Dump") + (sub_game_shaders_appendix.empty() ? "" : " ") + sub_game_shaders_appendix);
      for (const auto& entry : std::filesystem::directory_iterator(dump_path))
      {
         if (entry.is_regular_file())
         {
            dumped_shaders_paths.emplace(entry);
         }
      }
#endif

      for (auto shader_to_dump : shaders_to_dump_copy)
      {
         const std::lock_guard<std::recursive_mutex> lock_dumping(s_mutex_dumping);
         // Set this to true in case your old dumped shaders have bad naming (e.g. missing the "ps_5_0" appendix) and you want to replace them (on the next boot, the duplicate shaders with the shorter name will be deleted)
         constexpr bool force_redump_shaders = false;
         if (force_redump_shaders || !dumped_shaders.contains(shader_to_dump))
         {
            DumpShader(shader_to_dump);
         }
#if DEVELOPMENT && TEST_DUPLICATE_SHADER_HASH // Warning: very slow
         else
         {
            // Make sure two different shaders didn't have the same hash (we only check if they start by the same name/hash)
            std::string shader_hash_name = Shader::Hash_NumToStr(shader_to_dump, true);
            for (const auto& entry : dumped_shaders_paths)
            {
               if (entry.path().filename().string().rfind(shader_hash_name, 0) == 0)
               {
                  auto* cached_shader = shader_cache.find(shader_to_dump)->second;
                  ASSERT_ONCE(std::filesystem::file_size(entry) == cached_shader->size);
                  // Don't break as there might be more than one by the same hash (but of a different shader type)
               }
            }
         }
#endif
      }
      thread_auto_dumping_running = false;
   }
#pragma optimize("", on) // Restore the previous state

   void AutoLoadShaders(DeviceData* device_data)
   {
      // Copy the "pipelines_to_reload_copy" so we don't have to lock "s_mutex_loading" all the times
      std::unordered_set<uint64_t> pipelines_to_reload_copy;
      {
         const std::unique_lock lock_loading(s_mutex_loading);
         if (device_data->pipelines_to_reload.empty())
         {
            device_data->thread_auto_loading_running = false;
            return;
         }
         pipelines_to_reload_copy = device_data->pipelines_to_reload;
         device_data->pipelines_to_reload.clear();
      }
      if (pipelines_to_reload_copy.size() > 0)
      {
         LoadCustomShaders(*device_data, pipelines_to_reload_copy, !precompile_custom_shaders);
      }
      device_data->thread_auto_loading_running = false;
   }

#pragma optimize("t", on) // Temporarily override optimization, this function is too slow in debug otherwise (comment this out if ever needed)

   // TODO: apply this everywhere!
   template <typename T, bool Serialize = true >
   void DrawResetButton(
      T& value,                      // The current value to modify
      const T& default_value,        // The default value to compare against
      const char* name,              // Unique ID string for ImGui, and ReShade serialization
      reshade::api::effect_runtime* runtime = nullptr)
   {
      ImGui::SameLine();
      if (value != default_value)
      {
         int id = static_cast<int>(reinterpret_cast<uintptr_t>(name)); // Hacky, but it will do, almost certainly
         ImGui::PushID(id);
         if (ImGui::SmallButton(ICON_FK_UNDO))
         {
            value = default_value;
            if constexpr (Serialize)
            {
               if (name)
               {
                  reshade::set_config_value(runtime, NAME, name, value);
               }
            }
         }
         ImGui::PopID();
      }
      else // Draw a disabled placeholder so layout stays consistent
      {
         const auto& style = ImGui::GetStyle();
         ImVec2 size = ImGui::CalcTextSize(ICON_FK_UNDO);
         size.x += style.FramePadding.x;
         size.y += style.FramePadding.y;
         ImGui::InvisibleButton("", ImVec2(size.x, size.y));
      }
   }

   // @see https://pthom.github.io/imgui_manual_online/manual/imgui_manual.html
   // This runs within the swapchain "Present()" function, and thus it's thread safe
   void OnRegisterOverlay(reshade::api::effect_runtime* runtime)
   {
      DeviceData& device_data = *runtime->get_device()->get_private_data<DeviceData>();

      // Always do this in case a user changed the settings through ImGUI
      device_data.cb_luma_global_settings_dirty = true;

#if DEVELOPMENT
      const bool refresh_cloned_pipelines = device_data.cloned_pipelines_changed.exchange(false);

      if (ImGui::Button("Frame Capture"))
      {
         trace_scheduled = true;
      }
#if 0 // Currently not necessary
      ImGui::SameLine();
      ImGui::Checkbox("List Unique Shaders Only", &trace_list_unique_shaders_only);
#endif

      ImGui::SameLine();
      ImGui::PushID("##DumpShaders");
      // "ALLOW_SHADERS_DUMPING" is expected to be on here
      if (ImGui::Button(std::format("Dump Shaders ({})", shader_cache_count).c_str()))
      {
         const std::lock_guard<std::recursive_mutex> lock_dumping(s_mutex_dumping);
         // Force dump everything here
         for (auto shader : shader_cache)
         {
            DumpShader(shader.first);
         }
         shaders_to_dump.clear();
      }
      ImGui::PopID();

      ImGui::SameLine();
      ImGui::PushID("##AutoDumpCheckBox");
      if (ImGui::Checkbox("Auto Dump", &auto_dump))
      {
         if (!auto_dump && thread_auto_dumping.joinable())
         {
            thread_auto_dumping.join();
         }
      }
      ImGui::PopID();
#endif // DEVELOPMENT

#if DEVELOPMENT || TEST
      if (ImGui::Button(std::format("Unload Shaders ({})", device_data.cloned_pipeline_count).c_str()))
      {
         needs_unload_shaders = true;
         last_pressed_unload = true;
#if 0  // Not necessary anymore with "last_pressed_unload"
         // For consistency, disable auto load, it makes no sense for them to be on if we have unloaded shaders
         if (auto_load)
         {
            auto_load = false;
            if (device_data.thread_auto_loading.joinable())
            {
               device_data.thread_auto_loading.join();
            }
         }
#endif
         const std::unique_lock lock(s_mutex_loading);
         device_data.pipelines_to_reload.clear();
      }
      if (ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled))
      {
         ImGui::SetTooltip("Unload all compiled and replaced shaders. The numbers shows how many shaders are being replaced at this moment in the game, from the custom loaded/compiled ones.\nThis will also reset many of their debug settings to default.\nYou can use ReShade's Global Effects Toggle Shortcut to toggle these on and off.");
      }
      ImGui::SameLine();
#endif // DEVELOPMENT || TEST

      bool needs_compilation = false;
      {
         const std::shared_lock lock(s_mutex_shader_defines);
         needs_compilation = defines_need_recompilation;
         for (uint32_t i = 0; i < shader_defines_data.size() && !needs_compilation; i++)
         {
            needs_compilation |= shader_defines_data[i].NeedsCompilation();
         }
      }
#if !DEVELOPMENT && !TEST
      ImGui::BeginDisabled(!needs_compilation);
#endif
      static const std::string reload_shaders_button_title_error = std::string("Reload Shaders ") + std::string(ICON_FK_WARNING);
      static const std::string reload_shaders_button_title_outdated = std::string("Reload Shaders ") + std::string(ICON_FK_REFRESH);
      // We skip locking "s_mutex_loading" just to read the size of "shaders_compilation_errors".
      // We could maybe check "last_pressed_unload" instead of "cloned_pipeline_count", but that wouldn't work in case unloading shaders somehow failed.
      const char* reload_shaders_button_name = shaders_compilation_errors.empty() ? (device_data.cloned_pipeline_count ? (needs_compilation ? reload_shaders_button_title_outdated.c_str() : "Reload Shaders") : "Load Shaders") : reload_shaders_button_title_error.c_str();
      bool show_reload_shaders_button = (needs_compilation && !auto_recompile_defines) || !shaders_compilation_errors.empty();
#if DEVELOPMENT || TEST // Always show...
      show_reload_shaders_button = true;
#endif
      if ((show_reload_shaders_button && ImGui::Button(reload_shaders_button_name)) || (auto_recompile_defines && needs_compilation))
      {
         needs_unload_shaders = false;
         last_pressed_unload = false;
         needs_load_shaders = true;
         const std::unique_lock lock(s_mutex_loading);
         device_data.pipelines_to_reload.clear();
      }
      if (show_reload_shaders_button && ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled))
      {
         const std::shared_lock lock(s_mutex_loading);
#if !DEVELOPMENT
         if (shaders_compilation_errors.empty())
         {
#if TEST
            ImGui::SetTooltip((device_data.cloned_pipeline_count && needs_compilation) ? "Shaders recompilation is needed for the changed settings to apply\nYou can use ReShade's Recompile Effects Shortcut to recompile these." : "(Re)Compiles shaders");
#else
            ImGui::SetTooltip((device_data.cloned_pipeline_count && needs_compilation) ? "Shaders recompilation is needed for the changed settings to apply" : "(Re)Compiles shaders");
#endif
         }
         else
#endif
         {
#if DEVELOPMENT
            ImGui::SetTooltip("Recompile and load shaders.");
#endif
            if (!shaders_compilation_errors.empty())
            {
               ImGui::SetTooltip(shaders_compilation_errors.c_str());
            }
         }
      }
#if !DEVELOPMENT && !TEST
      ImGui::EndDisabled();
#endif
#if DEVELOPMENT || TEST
      ImGui::SameLine();
      if (ImGui::Button("Clean Shaders Cache"))
      {
         const std::unique_lock lock_loading(s_mutex_loading);
         CleanShadersCache();
         // Force recompile all shaders the next time
         for (const auto& custom_shader_pair : custom_shaders_cache)
         {
            if (custom_shader_pair.second)
            {
               custom_shader_pair.second->preprocessed_hash = 0;
            }
         }
      }
#endif

#if DEVELOPMENT
      ImGui::SameLine();
      ImGui::PushID("##AutoLoadCheckBox");
      if (ImGui::Checkbox("Auto Load", &auto_load))
      {
         if (!auto_load && device_data.thread_auto_loading.joinable())
         {
            device_data.thread_auto_loading.join();
         }
         const std::unique_lock lock(s_mutex_loading);
         device_data.pipelines_to_reload.clear();
      }
      ImGui::PopID();
#endif // DEVELOPMENT

      if (ImGui::BeginTabBar("##TabBar", ImGuiTabBarFlags_None))
      {
         bool open_settings_tab = false;
#if DEVELOPMENT
         static int32_t selected_index = -1; // TODO: rename to capture_, and "changed_selected" too
         static std::string highlighted_resource = {};
         static uint32_t prev_trace_count = -1; // Default to -1 to trigger a change in the first frame

         bool changed_selected = false;
         bool trace_count_changed = prev_trace_count != trace_count;
         bool open_capture_tab = trace_count_changed && trace_count > 0;
         open_settings_tab = trace_count_changed && trace_count <= 0; // Fall back on settings (and also default to it in the first frame)
         prev_trace_count = trace_count;

         ImGui::PushID("##CaptureTab");
         bool handle_shader_tab = trace_count > 0 && ImGui::BeginTabItem(std::format("Captured Commands ({})", trace_count).c_str(), nullptr, open_capture_tab ? ImGuiTabItemFlags_SetSelected : 0); // No need for "s_mutex_trace" here
         ImGui::PopID();
         if (handle_shader_tab)
         {
            bool list_size_changed = false;

            list_size_changed |= ImGui::Checkbox("Ignore Vertex Shaders", &trace_ignore_vertex_shaders);
            ImGui::SameLine();
            list_size_changed |= ImGui::Checkbox("Ignore Buffer Writes", &trace_ignore_buffer_writes);
            ImGui::SameLine();
            list_size_changed |= ImGui::Checkbox("Ignore Bindings", &trace_ignore_bindings);
            ImGui::SameLine();
            ImGui::Checkbox("Ignore Non Bound Shader Referenced Resources", &trace_ignore_non_bound_shader_referenced_resources);

            ImGui::SameLine();
            if (ImGui::Button("Clear Capture and Debug Settings"))
            {
               trace_count = 0;
               selected_index = -1;
               changed_selected = true;
               open_settings_tab = true;

               {
                  debug_draw_pipeline = 0;
                  debug_draw_shader_hash = 0;
                  debug_draw_shader_hash_string[0] = 0;
                  debug_draw_pipeline_target_instance = -1;

                  device_data.debug_draw_texture = nullptr;
                  device_data.debug_draw_texture_format = DXGI_FORMAT_UNKNOWN;
                  device_data.debug_draw_texture_size = {};

                  track_buffer_pipeline = 0;
                  track_buffer_pipeline_target_instance = -1;
                  track_buffer_index = 0;

                  device_data.track_buffer_data.hash.clear();
                  device_data.track_buffer_data.data.clear();
               }

               highlighted_resource = "";

               {
                  const std::unique_lock lock(s_mutex_generic);
                  for (auto& pair : device_data.pipeline_cache_by_pipeline_handle)
                  {
                     auto& cached_pipeline = pair.second;
                     cached_pipeline->custom_name.clear();
                     // Restore the original forced name
                     auto forced_shader_names_it = forced_shader_names.find(pair.second->shader_hashes[0]);
                     if (forced_shader_names_it != forced_shader_names.end())
                     {
                        cached_pipeline->custom_name = forced_shader_names_it->second;
                     }
                     cached_pipeline->skip_type = CachedPipeline::ShaderSkipType::None;
                     cached_pipeline->redirect_data = { };
                  }
               }

               {
                  CommandListData& cmd_list_data = *runtime->get_command_queue()->get_immediate_command_list()->get_private_data<CommandListData>();
                  const std::shared_lock lock_trace_2(cmd_list_data.mutex_trace);
                  cmd_list_data.trace_draw_calls_data.clear();
               }
            }

            if (ImGui::BeginChild("HashList", ImVec2(500, -FLT_MIN), ImGuiChildFlags_ResizeX))
            {
               if (ImGui::BeginListBox("##HashesListBox", ImVec2(-FLT_MIN, -FLT_MIN)))
               {
                  const std::shared_lock lock_trace(s_mutex_trace); // We don't really need "s_mutex_trace" here as when that data is being written ImGUI isn't running, but...
                  if (!trace_running)
                  {
                     const std::shared_lock lock_generic(s_mutex_generic);
                     CommandListData& cmd_list_data = *runtime->get_command_queue()->get_immediate_command_list()->get_private_data<CommandListData>();
                     const std::shared_lock lock_trace_2(cmd_list_data.mutex_trace);

#if 1 // Much more optimized, drawing all items is extremely slow otherwise
                     std::vector<uint32_t> trace_draw_calls_index_redirector; // From full list index to filtered list index
                     trace_draw_calls_index_redirector.reserve(trace_count);
                     std::vector<uint32_t> trace_draw_calls_index_inverse_redirector; // From filtered index to full list index
                     trace_draw_calls_index_redirector.reserve(trace_count);

                     // Pre count the elements (some are skipped) otherwise the clipper won't work properly
                     // TODO: do this once on capture
                     size_t actual_trace_count = 0;
                     for (auto index = 0; index < trace_count; index++) {
                        trace_draw_calls_index_redirector.emplace_back(uint32_t(trace_draw_calls_index_inverse_redirector.size())); // The closest one
                        auto& draw_call_data = cmd_list_data.trace_draw_calls_data.at(index);
                        if (draw_call_data.type == TraceDrawCallData::TraceDrawCallType::Shader) {
                           auto pipeline_handle = draw_call_data.pipeline_handle;
                           const auto pipeline_pair = device_data.pipeline_cache_by_pipeline_handle.find(pipeline_handle);
                           const bool is_valid = pipeline_pair != device_data.pipeline_cache_by_pipeline_handle.end() && pipeline_pair->second != nullptr;
                           if (is_valid) {
                              if (trace_ignore_vertex_shaders && pipeline_pair->second->HasVertexShader()) continue; // DX11 exclusive behaviour
                           }
                        }
                        else if (draw_call_data.type == TraceDrawCallData::TraceDrawCallType::CPUWrite) {
                           if (trace_ignore_buffer_writes && draw_call_data.rt_type_name[0] == "Buffer") continue;
                        }
                        else if (draw_call_data.type == TraceDrawCallData::TraceDrawCallType::BindPipeline
                           || draw_call_data.type == TraceDrawCallData::TraceDrawCallType::BindResource) {
                           if (trace_ignore_bindings) continue;
                        }
                        actual_trace_count++;
                        trace_draw_calls_index_inverse_redirector.emplace_back(index);
                     }

                     // Scroll to the target (that might have shifted)
                     if (list_size_changed && selected_index >= 0 && selected_index <= trace_draw_calls_index_redirector.size())
                     {
                        uint32_t filtered_index = trace_draw_calls_index_redirector[selected_index];
                        // If our selected index is currently hidden, automatically select the next one in line
                        if (filtered_index >= 0 && filtered_index <= trace_draw_calls_index_inverse_redirector.size())
                        {
                           uint32_t raw_index = trace_draw_calls_index_inverse_redirector[filtered_index];
                           selected_index = raw_index;
                        }
                        float item_height = ImGui::GetTextLineHeightWithSpacing();
                        float scroll_y = filtered_index * item_height;
                        ImGui::SetScrollY(scroll_y - ImGui::GetWindowHeight() * 0.5f + item_height * 0.5f);
                        list_size_changed = false;
                     }

                     ImGuiListClipper clipper;
                     clipper.Begin(actual_trace_count);
                     while (clipper.Step()) { for (int filtered_index = clipper.DisplayStart; filtered_index < clipper.DisplayEnd; filtered_index++) {
                        uint32_t index = trace_draw_calls_index_inverse_redirector[filtered_index]; // Raw index
#else
                     for (uint32_t index = 0; index < trace_count; index++) {
#endif
                        auto& draw_call_data = cmd_list_data.trace_draw_calls_data.at(index);
                        ASSERT_ONCE_MSG(draw_call_data.command_list, "The code below will probably crash if the command list isn't valid, remember to always assign it when adding a new element to the list");
                        auto pipeline_handle = draw_call_data.pipeline_handle;
                        auto thread_id = draw_call_data.thread_id._Get_underlying_id(); // Possibly compiler dependent but whatever, cast to int alternatively
                        const bool is_selected = selected_index == index;
                        // Note that the pipelines can be run more than once so this will return the first one matching (there's only one actually, we don't have separate settings for their running instance, as that's runtime stuff)
                        const auto pipeline_pair = device_data.pipeline_cache_by_pipeline_handle.find(pipeline_handle);
                        const bool is_valid = pipeline_pair != device_data.pipeline_cache_by_pipeline_handle.end() && pipeline_pair->second != nullptr;
                        std::stringstream name;
                        auto text_color = IM_COL32(255, 255, 255, 255); // White

                        bool found_highlighted_resource_write = false;
                        bool found_highlighted_resource_read = false;
                        if (!highlighted_resource.empty())
                        {
                           for (UINT i = 0; i < D3D11_COMMONSHADER_INPUT_RESOURCE_SLOT_COUNT; i++)
                           {
                              if (found_highlighted_resource_read) break;
                              found_highlighted_resource_read |= draw_call_data.sr_hash[i] == highlighted_resource;
                           }
                           for (UINT i = 0; i < D3D11_1_UAV_SLOT_COUNT; i++)
                           {
                              if (found_highlighted_resource_write) break;
                              found_highlighted_resource_write |= draw_call_data.ua_hash[i] == highlighted_resource; // We consider UAV as write even if it's not necessarily one
                           }
                           for (UINT i = 0; i < D3D11_SIMULTANEOUS_RENDER_TARGET_COUNT; i++)
                           {
                              if (found_highlighted_resource_write) break;
                              found_highlighted_resource_write |= draw_call_data.rt_hash[i] == highlighted_resource;
                           }
                           // Don't set "found_highlighted_resource_read" for the test and write case, it'd just be more confusing
                           if (draw_call_data.depth_state == TraceDrawCallData::DepthStateType::TestAndWrite
                              || draw_call_data.depth_state == TraceDrawCallData::DepthStateType::WriteOnly)
                              found_highlighted_resource_write |= draw_call_data.ds_hash == highlighted_resource;
                           else
                              found_highlighted_resource_read |= draw_call_data.ds_hash == highlighted_resource;
                        }

                        // TODO: merge pixel and vertex shader traces if they are both present? Maybe not...
                        if (is_valid && draw_call_data.type == TraceDrawCallData::TraceDrawCallType::Shader)
                        {
                           const auto pipeline = pipeline_pair->second;

                           // Highlight other draw calls with the same shader
                           bool same_as_selected = false;
                           if (/*!is_selected &&*/ selected_index >= 0 && cmd_list_data.trace_draw_calls_data.size() >= selected_index + 1 && cmd_list_data.trace_draw_calls_data.at(selected_index).type == TraceDrawCallData::TraceDrawCallType::Shader)
                           {
                              auto pipeline_handle_2 = cmd_list_data.trace_draw_calls_data.at(selected_index).pipeline_handle;
                              const auto pipeline_pair_2 = device_data.pipeline_cache_by_pipeline_handle.find(pipeline_handle_2);
                              const bool is_valid_2 = pipeline_pair_2 != device_data.pipeline_cache_by_pipeline_handle.end() && pipeline_pair_2->second != nullptr;
                              if (is_valid_2)
                              {
                                 const auto pipeline_2 = pipeline_pair_2->second;
                                 if (pipeline_2->shader_hashes == pipeline->shader_hashes)
                                 {
#if 1 // Add a space before it
                                    name << "   ";
#endif
                                    same_as_selected = true;
                                 }
                              }
                           }

                           // Index - Thread ID (command list) - Shader Hash(es) - Shader Name
                           name << std::setfill('0') << std::setw(3) << index << std::setw(0); // Fill up 3 slots for the index so the text is aligned

                           if (draw_call_data.command_list->GetType() != D3D11_DEVICE_CONTEXT_IMMEDIATE) // Deferred
                              name << " - ~>" << thread_id;
                           else // Immediate
                              name << " - " << thread_id;

                           const char* sm = nullptr;

                           // Pick the default color by shader type
                           if (pipeline->HasVertexShader())
                           {
                              if (trace_ignore_vertex_shaders)
                              {
                                 continue;
                              }
                              text_color = IM_COL32(192, 192, 0, 255); // Yellow
                              sm = "VS";
                           }
                           else if (pipeline->HasComputeShader())
                           {
                              text_color = IM_COL32(192, 0, 192, 255); // Purple
                              sm = "CS";
                           }
                           else if (pipeline->HasGeometryShader())
                           {
                              text_color = IM_COL32(192, 0, 192, 255); // Purple
                              sm = "GS";
                           }
                           else //if (pipeline->HasPixelShader())
                           {
                              sm = "PS";
                           }

                           for (auto shader_hash : pipeline->shader_hashes)
                           {
                              name << " - " << sm << " " << PRINT_CRC32(shader_hash);
                           }

                           const std::shared_lock lock_loading(s_mutex_loading);
                           const auto custom_shader = !pipeline->shader_hashes.empty() ? custom_shaders_cache[pipeline->shader_hashes[0]] : nullptr;

                           // Find if the shader has been modified
                           if (pipeline->cloned)
                           {
                              name << "*";

                              if (pipeline->HasVertexShader())
                              {
                                 text_color = IM_COL32(128, 255, 0, 255); // Yellow + Green
                              }
                              else if (pipeline->HasComputeShader())
                              {
                                 text_color = IM_COL32(128, 255, 128, 255); // Purple + Green
                              }
                              else
                              {
                                 text_color = IM_COL32(0, 255, 0, 255); // Green
                              }
                           }

                           if (strlen(pipeline->custom_name.c_str()) > 0) // We can not check the string size as it's been allocated to more characters even if they are empty
                           {
                              name << " - " << pipeline->custom_name.c_str(); // Add c string otherwise it will append a billion null terminators
                           }
                           else if (pipeline->cloned)
                           {
                              // For now just force picking the first shader linked to the pipeline, there should always only be one (?)
                              if (custom_shader != nullptr && custom_shader->is_hlsl && !custom_shader->file_path.empty())
                              {
                                 auto filename_string = custom_shader->file_path.filename().string();
                                 if (const auto hash_begin_index = filename_string.find("0x"); hash_begin_index != std::string::npos)
                                 {
                                    filename_string.erase(hash_begin_index); // Start deleting from where the shader hash(es) begin (e.g. "0x12345678.xx_x_x.hlsl")
                                 }
                                 if (filename_string.ends_with("_") || filename_string.ends_with("."))
                                 {
                                    filename_string.erase(filename_string.length() - 1);
                                 }
                                 if (!filename_string.empty())
                                 {
                                    name << " - " << filename_string;
                                 }
                              }
                           }
                           else
                           {
                              std::optional<std::string> optional_name = GetD3DNameW(reinterpret_cast<ID3D11DeviceChild*>(pipeline->pipeline.handle));
                              if (optional_name.has_value())
                              {
                                 name << " - " << optional_name.value().c_str();
                              }
                           }

                           // Highlight loading error
                           if (custom_shader != nullptr && !custom_shader->compilation_errors.empty())
                           {
                              text_color = custom_shader->compilation_error ? IM_COL32(255, 0, 0, 255) : IM_COL32(255, 165, 0, 255); // Red for Error, Orange for Warning
                           }

                           if (same_as_selected)
                           {
#if 0 // We already do this better above
                              name << " - (Selected) ";
#endif
                              if (!is_selected)
                              {
                                 text_color = IM_COL32(192, 192, 192, 255); // Grey
                              }
                           }
                        }
                        else if (draw_call_data.type == TraceDrawCallData::TraceDrawCallType::CopyResource)
                        {
                           name << std::setfill('0') << std::setw(3) << index << std::setw(0);

                           if (draw_call_data.command_list->GetType() != D3D11_DEVICE_CONTEXT_IMMEDIATE) // Deferred
                              name << " - ~>" << thread_id;
                           else // Immediate
                              name << " - " << thread_id;

                           name << " - Copy Resource";
                           
                           text_color = IM_COL32(255, 105, 0, 255); // Orange
                        }
                        else if (draw_call_data.type == TraceDrawCallData::TraceDrawCallType::BindPipeline)
                        {
                           if (trace_ignore_bindings) continue;

                           name << std::setfill('0') << std::setw(3) << index << std::setw(0);

                           if (draw_call_data.command_list->GetType() != D3D11_DEVICE_CONTEXT_IMMEDIATE) // Deferred
                              name << " - ~>" << thread_id;
                           else // Immediate
                              name << " - " << thread_id;

                           name << " - Bind Pipeline";

                           text_color = IM_COL32(30, 200, 10, 255); // Some green
                        }
                        else if (draw_call_data.type == TraceDrawCallData::TraceDrawCallType::BindResource)
                        {
                           if (trace_ignore_bindings) continue;

                           name << std::setfill('0') << std::setw(3) << index << std::setw(0);

                           if (draw_call_data.command_list->GetType() != D3D11_DEVICE_CONTEXT_IMMEDIATE) // Deferred
                              name << " - ~>" << thread_id;
                           else // Immediate
                              name << " - " << thread_id;

                           name << " - Bind Resource";

                           text_color = IM_COL32(30, 200, 10, 255); // Some green
                        }
                        else if (draw_call_data.type == TraceDrawCallData::TraceDrawCallType::CPURead)
                        {
                           name << std::setfill('0') << std::setw(3) << index << std::setw(0);

                           if (draw_call_data.command_list->GetType() != D3D11_DEVICE_CONTEXT_IMMEDIATE) // Deferred
                              name << " - ~>" << thread_id;
                           else // Immediate
                              name << " - " << thread_id;

                           name << " - Resource CPU Read";

                           text_color = IM_COL32(255, 40, 0, 255); // Bright Red
                        }
                        else if (draw_call_data.type == TraceDrawCallData::TraceDrawCallType::CPUWrite)
                        {
                           name << std::setfill('0') << std::setw(3) << index << std::setw(0);

                           if (draw_call_data.command_list->GetType() != D3D11_DEVICE_CONTEXT_IMMEDIATE) // Deferred
                              name << " - ~>" << thread_id;
                           else // Immediate
                              name << " - " << thread_id;

                           // Hacky resource type name check
                           if (trace_ignore_buffer_writes && draw_call_data.rt_type_name[0] == "Buffer")
                           {
                              continue;
                           }

                           name << " - Resource CPU Write";

                           text_color = IM_COL32(255, 105, 0, 255); // Orange
                        }
                        else if (draw_call_data.type == TraceDrawCallData::TraceDrawCallType::ClearResource)
                        {
                           name << std::setfill('0') << std::setw(3) << index << std::setw(0);

                           if (draw_call_data.command_list->GetType() != D3D11_DEVICE_CONTEXT_IMMEDIATE) // Deferred
                              name << " - ~>" << thread_id;
                           else // Immediate
                              name << " - " << thread_id;

                           name << " - Clear Resource";

                           text_color = IM_COL32(255, 105, 0, 255); // Orange
                        }
                        else if (draw_call_data.type == TraceDrawCallData::TraceDrawCallType::AppendCommandList)
                        {
                           name << std::setfill('0') << std::setw(3) << index << std::setw(0);
                           name << " - " << thread_id;
                           name << " - Append Command List";
                           text_color = IM_COL32(50, 80, 190, 255); // Some Blue
                        }
                        else if (draw_call_data.type == TraceDrawCallData::TraceDrawCallType::FlushCommandList)
                        {
                           name << std::setfill('0') << std::setw(3) << index << std::setw(0);
                           name << " - " << thread_id;
                           name << " - Flush Command List";
                           text_color = IM_COL32(50, 80, 190, 255); // Some Blue
                        }
                        else if (draw_call_data.type == TraceDrawCallData::TraceDrawCallType::Present)
                        {
                           name << std::setfill('0') << std::setw(3) << index << std::setw(0);
                           name << " - " << thread_id;
                           name << " - Present";
                           text_color = IM_COL32(50, 80, 190, 255); // Some Blue

                           // Highlight the resource on the swapchain too, given that "Present" traces aren't tracked the same way
                           if (!highlighted_resource.empty() && !device_data.swapchains.empty())
                           {
                              // Not fully safe, but it should do for almost all cases
                              reshade::api::swapchain* swapchain = *device_data.swapchains.begin();
                              IDXGISwapChain* native_swapchain = (IDXGISwapChain*)(swapchain->get_native());
                              UINT back_buffer_index = swapchain->get_current_back_buffer_index();
                              com_ptr<ID3D11Texture2D> back_buffer;
                              native_swapchain->GetBuffer(back_buffer_index, IID_PPV_ARGS(&back_buffer));

                              std::string backbuffer_hash = std::to_string(std::hash<void*>{}(back_buffer.get()));
                              if (highlighted_resource == backbuffer_hash)
                              {
                                 found_highlighted_resource_read = true;
                              }
                           }
                        }
                        else if (draw_call_data.type == TraceDrawCallData::TraceDrawCallType::Custom)
                        {
                           name << std::setfill('0') << std::setw(3) << index << std::setw(0);
                           if (draw_call_data.command_list->GetType() != D3D11_DEVICE_CONTEXT_IMMEDIATE) // Deferred
                              name << " - ~>" << thread_id;
                           else // Immediate
                              name << " - " << thread_id;
                           name << " - " << draw_call_data.custom_name;
                           text_color = IM_COL32(70, 130, 180, 255); // Steel Blue
                        }
                        else
                        {
                           text_color = IM_COL32(255, 0, 0, 255); // Red
                           name << "ERROR: Capture data not found"; // The draw call either had an empty (e.g. pixel) shader set, or the game has since unloaded them
                        }

                        if (found_highlighted_resource_write || found_highlighted_resource_read)
                        {
                           if (found_highlighted_resource_write && found_highlighted_resource_read)
                           {
                              // Highlight there's an error in this case as in any DX version, reading and writing from the same resource isn't supported
                              text_color = IM_COL32(255, 0, 0, 255); // Red
                              name << " - (Highlighted Resource Read And Write)";
                           }
                           else
                           {
                              text_color = IM_COL32(255, 192, 203, 255); // Pink
                              name << (found_highlighted_resource_write ? " - (Highlighted R Write)" : " - (Highlighted R Read)");
                           }
                        }

                        ImGui::PushStyleColor(ImGuiCol_Text, text_color);
                        if (ImGui::Selectable(name.str().c_str(), is_selected))
                        {
                           selected_index = index;
                           changed_selected = true;
                        }
                        ImGui::PopStyleColor();

                        if (is_selected)
                        {
                           ImGui::SetItemDefaultFocus();
                           if (list_size_changed)
                           {
                              ImGui::SetScrollHereY(0.5f); // 0.0 = top, 0.5 = middle, 1.0 = bottom
                           }
                        }
                     }
#if 1
                     }
                     clipper.End();
#endif
                  }
                  else
                  {
                     selected_index = -1;
                     changed_selected = true;
                  }
                  selected_index = min(selected_index, trace_count - 1); // Extra safety
                  ImGui::EndListBox();
               }
            }
            ImGui::EndChild(); // HashList

            ImGui::SameLine();
            if (ImGui::BeginChild("##ShaderDetails", ImVec2(0, 0)))
            {
               ImGui::BeginDisabled(selected_index == -1);
               if (ImGui::BeginTabBar("##ShadersCodeTab", ImGuiTabBarFlags_None))
               {
                  ImGui::PushID("##SettingsTabItem");
                  const bool open_settings_tab_item = ImGui::BeginTabItem("Info & Settings");
                  ImGui::PopID();
                  if (open_settings_tab_item)
                  {
                     CommandListData& cmd_list_data = *runtime->get_command_queue()->get_immediate_command_list()->get_private_data<CommandListData>();
                     const std::shared_lock lock_trace(cmd_list_data.mutex_trace);
                     if (selected_index >= 0 && cmd_list_data.trace_draw_calls_data.size() >= selected_index + 1)
                     {
                        auto& draw_call_data = cmd_list_data.trace_draw_calls_data.at(selected_index);
                        auto pipeline_handle = draw_call_data.pipeline_handle;
                        bool reload = false;
                        bool recompile = false;

                        {
                           std::unique_lock lock(s_mutex_generic);
                           if (auto pipeline_pair = device_data.pipeline_cache_by_pipeline_handle.find(pipeline_handle); pipeline_pair != device_data.pipeline_cache_by_pipeline_handle.end() && pipeline_pair->second != nullptr)
                           {
                              int pipeline_skip_type = (int)pipeline_pair->second->skip_type;
                              if (ImGui::BeginChild("Settings and Info"))
                              {
                                 CachedShader* original_shader = nullptr; // We probably don't need to lock "s_mutex_dumping" for the duration of this read
                                 {
                                    const std::lock_guard<std::recursive_mutex> lock_dumping(s_mutex_dumping);
                                    for (auto shader_hash : pipeline_pair->second->shader_hashes)
                                    {
                                       auto custom_shader_pair = shader_cache.find(shader_hash);
                                       if (custom_shader_pair != shader_cache.end())
                                       {
                                          original_shader = custom_shader_pair->second;
                                       }
                                    }
                                 }
                                 CachedCustomShader* custom_shader = nullptr; // We probably don't need to lock "s_mutex_loading" for the duration of this read
                                 {
                                    const std::shared_lock lock(s_mutex_loading);
                                    for (auto shader_hash : pipeline_pair->second->shader_hashes)
                                    {
                                       auto custom_shader_pair = custom_shaders_cache.find(shader_hash);
                                       if (custom_shader_pair != custom_shaders_cache.end())
                                       {
                                          custom_shader = custom_shader_pair->second;
                                       }
                                    }
                                 }

                                 if (pipeline_pair->second->HasPixelShader() || pipeline_pair->second->HasComputeShader())
                                 {
                                    ImGui::SliderInt("Shader Skip Type", &pipeline_skip_type, 0, IM_ARRAYSIZE(CachedPipeline::shader_skip_type_names) - 1, CachedPipeline::shader_skip_type_names[(size_t)pipeline_skip_type], ImGuiSliderFlags_NoInput);
                                 }
                                 if (ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled))
                                 {
                                    ImGui::SetTooltip("Affects all the instances of this shader.\nNote that \"Draw Purple\" might not always work, if it doesn't, it will skip the shader anyway. With compute shaders, written area might not match at all.");
                                 }

                                 {
                                    // Ensure the string has enough capacity for editing (e.g. 256 chars)
                                    if (pipeline_pair->second->custom_name.capacity() < 128)
                                       pipeline_pair->second->custom_name.resize(128);

                                    // ImGui::InputText modifies the buffer in-place
                                    if (ImGui::InputText("Shader Custom Name", pipeline_pair->second->custom_name.data(), pipeline_pair->second->custom_name.capacity()))
                                    {
                                       pipeline_pair->second->custom_name.resize(strlen(pipeline_pair->second->custom_name.c_str())); // Optional
                                    }
                                 }

                                 if (pipeline_pair->second->cloned && ImGui::Button("Unload"))
                                 {
                                    UnloadCustomShaders(device_data, { pipeline_handle }, false, false);
                                 }
                                 if (ImGui::Button(pipeline_pair->second->cloned ? "Recompile" : "Load"))
                                 {
                                    reload = true;
                                    recompile = true; // If this shader wasn't cloned, we'd need to compile it probably as it might not have already been compiled. If it was cloned, then our intent is to re-compile it anyway
                                 }
                                 if (ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled))
                                 {
                                    ImGui::SetTooltip("Recompile and/or load/unload the custom shader that replaces the original one.");
                                 }

                                 if (ImGui::Button("Copy Shader Hash to Clipboard"))
                                 {
                                    const std::shared_lock lock(s_mutex_loading);
                                    const std::string shader_hash = "0x" + ((pipeline_pair->second->shader_hashes.size() > 0) ? Shader::Hash_NumToStr(pipeline_pair->second->shader_hashes[0]) : "????????"); // Somehow we need to add "0x" in front of it again // DX11 specific behaviour
                                    System::CopyToClipboard(shader_hash);
                                 }

                                 if (custom_shader && custom_shader->is_hlsl && !custom_shader->file_path.empty() && ImGui::Button("Open hlsl in IDE"))
                                 {
                                    // You may need to specify the full path to "code.exe" if it's not in PATH.
                                    HINSTANCE ret_val = ShellExecuteA(nullptr, "open", "code", custom_shader->file_path.string().c_str(), nullptr, SW_SHOWNORMAL); // TODO: instruct users on how to use this (add "code" path to VS Code). Also this still doesn't work...
                                    ASSERT_ONCE(ret_val > (HINSTANCE)32); // Unknown reason
                                 }

                                 if (custom_shader && !custom_shader->file_path.empty() && ImGui::Button("Open in Explorer"))
                                 {
                                    System::OpenExplorerToFile(custom_shader->file_path);
                                 }

                                 bool debug_draw_shader_enabled = false; // Whether this shader/pipeline instance is the one we are draw debugging

                                 if (pipeline_pair->second->HasVertexShader() || pipeline_pair->second->HasPixelShader() || pipeline_pair->second->HasComputeShader())
                                 {
                                    debug_draw_shader_enabled = debug_draw_shader_hash == pipeline_pair->second->shader_hashes[0];

                                    const auto& trace_draw_call_data = draw_call_data;

                                    int32_t target_instance = -1;
                                    // Automatically calculate the index of the instance of this pipeline run, to directly select it on selection (this works as long as the current scene draw calls match the ones in the trace)
                                    {
                                       target_instance = 0;
                                       for (int32_t i = 0; i < selected_index; i++)
                                       {
                                          if (pipeline_handle == cmd_list_data.trace_draw_calls_data.at(i).pipeline_handle)
                                             target_instance++;
                                       }

                                       debug_draw_shader_enabled &= debug_draw_pipeline_target_instance < 0 || debug_draw_pipeline_target_instance == target_instance;
                                    }

                                    bool has_any_resources = false;
                                    {
                                       for (UINT i = 0; i < std::size(trace_draw_call_data.srv_format); i++)
                                       {
                                          if (trace_draw_call_data.IsSRVValid(i)) has_any_resources = true; break;
                                       }
                                       for (UINT i = 0; i < std::size(trace_draw_call_data.uav_format); i++)
                                       {
                                          if (trace_draw_call_data.IsUAVValid(i)) has_any_resources = true; break;
                                       }
                                       for (UINT i = 0; i < std::size(trace_draw_call_data.rtv_format); i++)
                                       {
                                          if (trace_draw_call_data.IsRTVValid(i)) has_any_resources = true; break;
                                       }
                                       if (trace_draw_call_data.IsDSVValid()) has_any_resources = true;
                                    }

                                    // Note: yes, this can be done on vertex shaders too, as they might have resources!
                                    bool debug_draw_shader_just_enabled = false;
                                    // TODO: add a slider to scroll through all the draw calls quickly and show the RTVs etc, like Nsight. Or at least add Next, Prev buttons.
                                    if (has_any_resources && (debug_draw_shader_enabled ? ImGui::Button("Disable Debug Draw Shader Instance") : ImGui::Button("Debug Draw Shader Instance")))
                                    {
                                       ASSERT_ONCE(GetShaderDefineCompiledNumericalValue(DEVELOPMENT_HASH) >= 1); // Development flag is needed in shaders for this to output correctly
                                       ASSERT_ONCE(device_data.display_composition_pixel_shader); // This shader is necessary to draw this debug stuff

                                       if (debug_draw_shader_enabled)
                                       {
                                          debug_draw_pipeline = 0;
                                          debug_draw_shader_hash = 0;
                                          debug_draw_shader_hash_string[0] = 0;
                                       }
                                       else
                                       {
                                          debug_draw_pipeline = pipeline_pair->first; // Note: this is probably completely useless at the moment as we don't store the index of the pipeline instance the user had selected (e.g. "debug_draw_pipeline_target_instance")
                                          debug_draw_shader_hash = pipeline_pair->second->shader_hashes[0];
                                          std::string new_debug_draw_shader_hash_string = Shader::Hash_NumToStr(debug_draw_shader_hash);
                                          if (new_debug_draw_shader_hash_string.size() <= HASH_CHARACTERS_LENGTH)
                                             strcpy(&debug_draw_shader_hash_string[0], new_debug_draw_shader_hash_string.c_str());
                                          else
                                             debug_draw_shader_hash_string[0] = 0;
                                          debug_draw_shader_just_enabled = true;
                                       }
                                       device_data.debug_draw_texture = nullptr;
                                       device_data.debug_draw_texture_format = DXGI_FORMAT_UNKNOWN;
                                       device_data.debug_draw_texture_size = {};
                                       debug_draw_pipeline_instance = 0;
#if 1 // We could also let the user settings persist if we wished so, but automatically setting them is usually better
                                       debug_draw_pipeline_target_instance = debug_draw_shader_enabled ? -1 : target_instance;
                                       const auto prev_debug_draw_mode = debug_draw_mode;
                                       if (prev_debug_draw_mode == DebugDrawMode::Depth)
                                       {
                                          debug_draw_options &= ~(uint32_t)DebugDrawTextureOptionsMask::RedOnly;
                                       }
                                       debug_draw_mode = pipeline_pair->second->HasPixelShader() ? DebugDrawMode::RenderTarget : (pipeline_pair->second->HasComputeShader() ? DebugDrawMode::UnorderedAccessView : DebugDrawMode::ShaderResource); // Do it regardless of "debug_draw_shader_enabled"
                                       // Fall back on depth if there main RT isn't valid
                                       if (debug_draw_mode == DebugDrawMode::RenderTarget && trace_draw_call_data.rt_format[0] == DXGI_FORMAT_UNKNOWN && draw_call_data.depth_state != TraceDrawCallData::DepthStateType::Disabled)
                                       {
                                          debug_draw_mode = DebugDrawMode::Depth;
                                          debug_draw_options |= (uint32_t)DebugDrawTextureOptionsMask::RedOnly;
                                       }
                                       if (debug_draw_mode != prev_debug_draw_mode)
                                       {
                                          debug_draw_view_index = 0;
                                       }
                                       // Preserve the last SRV/UAV/RTV index if we are passing between draw calls, it should help (e.g. during gbuffers rendering)
                                       else if (debug_draw_shader_just_enabled)
                                       {
                                          if (debug_draw_mode == DebugDrawMode::RenderTarget)
                                          {
                                             if (debug_draw_view_index < 0 || debug_draw_view_index >= std::size(original_shader->rtvs) || !original_shader->rtvs[debug_draw_view_index])
                                                debug_draw_view_index = 0;
                                          }
                                          else if (debug_draw_mode == DebugDrawMode::ShaderResource)
                                          {
                                             if (debug_draw_view_index < 0 || debug_draw_view_index >= std::size(original_shader->srvs) || !original_shader->srvs[debug_draw_view_index])
                                                debug_draw_view_index = 0;
                                          }
                                          else if (debug_draw_mode == DebugDrawMode::UnorderedAccessView)
                                          {
                                             if (debug_draw_view_index < 0 || debug_draw_view_index >= std::size(original_shader->uavs) || !original_shader->uavs[debug_draw_view_index])
                                                debug_draw_view_index = 0;
                                          }
                                          else
                                          {
                                             debug_draw_view_index = 0;
                                          }
                                       }
                                       //debug_draw_replaced_pass = false;
#endif

                                       debug_draw_shader_enabled = !debug_draw_shader_enabled;
                                    }
                                    // Show that it's failing to retrieve the texture if we can!
                                    if (!debug_draw_auto_clear_texture && has_any_resources && debug_draw_shader_enabled && !debug_draw_shader_just_enabled && device_data.debug_draw_texture.get() == nullptr)
                                    {
                                       ImGui::BeginDisabled(true);
                                       ImGui::SameLine();
                                       ImGui::SmallButton(ICON_FK_WARNING);
                                       ImGui::EndDisabled();
                                    }

                                    bool track_buffer_enabled = track_buffer_pipeline != 0 && track_buffer_pipeline == pipeline_pair->first;
                                    track_buffer_enabled &= track_buffer_pipeline_target_instance < 0 || track_buffer_pipeline_target_instance == target_instance;
                                    if (track_buffer_enabled ? ImGui::Button("Disable Constant Buffer Tracking") : ImGui::Button("Enable Constant Buffer Tracking"))
                                    {
                                       if (!track_buffer_enabled)
                                       {
                                          track_buffer_pipeline = pipeline_pair->first;
                                          track_buffer_pipeline_target_instance = target_instance;
                                          track_buffer_index = 0;
                                       }
                                       else
                                       {
                                          track_buffer_pipeline = 0;
                                          track_buffer_pipeline_target_instance = -1;
                                       }
                                       track_buffer_enabled = !track_buffer_enabled;
                                    }

                                    if (track_buffer_enabled)
                                    {
                                       ImGui::SliderInt("Constant Buffer Tracked Index", &track_buffer_index, 0, D3D11_COMMONSHADER_CONSTANT_BUFFER_API_SLOT_COUNT - 1);

                                       if (!device_data.track_buffer_data.data.empty())
                                       {
                                          ImGui::NewLine();
                                          ImGui::Text("Tracked Constant Buffer:");
                                          ImGui::Text("Resource Hash:", device_data.track_buffer_data.hash.c_str());
                                          if (ImGui::BeginChild("TrackBufferScroll", ImVec2(0, 500), ImGuiChildFlags_Border))
                                          {
                                             // TODO: match with the shader assembly cbs etc (if the data is available)
                                             // TODO: add a matrix 4x4 view?
                                             if (ImGui::BeginTable("TrackBufferTable", 3, ImGuiTableFlags_Borders | ImGuiTableFlags_RowBg | ImGuiTableFlags_Resizable)) {
                                                ImGui::TableSetupColumn("Index", ImGuiTableColumnFlags_WidthFixed, 60.0f);
                                                ImGui::TableSetupColumn("Float Value", ImGuiTableColumnFlags_WidthStretch);
                                                ImGui::TableSetupColumn("Int Value", ImGuiTableColumnFlags_WidthStretch);
                                                ImGui::TableHeadersRow();

                                                for (size_t i = 0; i < device_data.track_buffer_data.data.size(); ++i)
                                                {
                                                   float this_data = device_data.track_buffer_data.data[i];
                                                   ImGui::TableNextRow();
                                                   ImGui::TableSetColumnIndex(0);
                                                   static const char* components[] = { "x", "y", "z", "w" };
                                                   size_t group = i / 4; // Split index by float4
                                                   size_t comp_index = i % 4; // Print out the x/y/w/z identifier
                                                   ImGui::Text("%zu:%s", group, components[comp_index]);
                                                   // First print as float
                                                   ImGui::TableSetColumnIndex(1);
                                                   // I'm not sure whether the auto float printing handles nan/inf
                                                   if (std::isnan(this_data))
                                                   {
                                                      ImGui::Text("NaN");
                                                   }
                                                   else if (std::isinf(this_data))
                                                   {
                                                      ImGui::Text("Inf");
                                                   }
                                                   else
                                                   {
                                                      ImGui::Text("%.7f", this_data); // We need to show quite a bit of precision
                                                   }
                                                   // Then print as int (should work as uint/bool as well)
                                                   ImGui::TableSetColumnIndex(2);
                                                   ImGui::Text("%i", Math::AsInt(this_data));
                                                }
                                                ImGui::EndTable();
                                             }
                                          }
                                          ImGui::EndChild(); // TrackBufferScroll

                                          if (ImGui::Button("Copy Constant Buffer Data to Clipboard (float)"))
                                          {
                                             std::ostringstream oss;
                                             for (size_t i = 0; i < device_data.track_buffer_data.data.size(); ++i) {
                                                oss << device_data.track_buffer_data.data[i];
                                                if (i + 1 < device_data.track_buffer_data.data.size())
                                                   oss << '\n';
                                             }
                                             System::CopyToClipboard(oss.str());
                                          }
                                       }
                                    }
                                    // Hacky: clear the data here...
                                    else
                                    {
                                       device_data.track_buffer_data.hash.clear();
                                       device_data.track_buffer_data.data.clear();
                                    }
                                 }

                                 ImGui::NewLine();
                                 ImGui::Text("State Analysis:");
                                 if (ImGui::BeginChild("StateAnalysisScroll", ImVec2(0, -FLT_MIN), ImGuiChildFlags_Border)) // I prefer it without a separate scrolling box for now
                                 {
                                    bool is_first_view = true;

                                    if (pipeline_pair->second->HasVertexShader() || pipeline_pair->second->HasPixelShader() || pipeline_pair->second->HasComputeShader())
                                    {
                                       for (UINT i = 0; i < D3D11_COMMONSHADER_INPUT_RESOURCE_SLOT_COUNT; i++)
                                       {
                                          auto srv_format = draw_call_data.srv_format[i];
                                          if (srv_format == DXGI_FORMAT_UNKNOWN) // Resource was not valid
                                          {
                                             continue;
                                          }
                                          const bool non_referenced = srv_format == DXGI_FORMAT(-1);
                                          if (trace_ignore_non_bound_shader_referenced_resources && srv_format == DXGI_FORMAT(-1))
                                          {
                                             continue;
                                          }
                                          auto sr_format = draw_call_data.sr_format[i];
                                          auto sr_size = draw_call_data.sr_size[i];
                                          auto sr_hash = draw_call_data.sr_hash[i];
                                          auto sr_type_name = draw_call_data.sr_type_name[i];
                                          auto sr_is_rt = draw_call_data.sr_is_rt[i];
                                          auto sr_is_ua = draw_call_data.sr_is_ua[i];

                                          ImGui::PushID(i);

                                          if (!is_first_view) { ImGui::Text(""); };
                                          is_first_view = false;
                                          ImGui::Text("SRV Index: %u", i);
                                          if (non_referenced)
                                          {
                                             ImGui::PushStyleColor(ImGuiCol_Text, IM_COL32(255, 0, 0, 255)); // Red
                                             ImGui::Text("R Referenced but Not Bound");
                                             ImGui::PopStyleColor();
                                             continue;
                                          }
                                          ImGui::Text("R Hash: %s", sr_hash.c_str());
                                          ImGui::Text("R Type: %s", sr_type_name.c_str());
                                          if (GetFormatName(sr_format) != nullptr)
                                          {
                                             ImGui::Text("R Format: %s", GetFormatName(sr_format));
                                          }
                                          else
                                          {
                                             ImGui::Text("R Format: %u", sr_format);
                                          }
                                          if (GetFormatName(srv_format) != nullptr)
                                          {
                                             ImGui::Text("RV Format: %s", GetFormatName(srv_format));
                                          }
                                          else
                                          {
                                             ImGui::Text("RV Format: %u", srv_format);
                                          }
                                          ImGui::Text("R Size: %ux%ux%ux%u", sr_size.x, sr_size.y, sr_size.z, sr_size.w);
                                          ImGui::Text("R is RT: %s", sr_is_rt ? "True" : "False");
                                          ImGui::Text("R is UA: %s", sr_is_ua ? "True" : "False");
                                          {
                                             const std::shared_lock lock(device_data.mutex);
                                             // TODO: store this information in the trace list, it might expire otherwise, or even be incorrect if ptrs were re-used
                                             for (auto upgraded_resource_pair : device_data.original_upgraded_resources_formats)
                                             {
                                                void* upgraded_resource_ptr = reinterpret_cast<void*>(upgraded_resource_pair.first);
                                                if (sr_hash == std::to_string(std::hash<void*>{}(upgraded_resource_ptr)))
                                                {
                                                   ImGui::Text("R: Upgraded");

                                                   ImGui::Text("R Original Format: %s", GetFormatName(DXGI_FORMAT(upgraded_resource_pair.second)));

                                                   if (const auto it = device_data.original_upgraded_resource_views_formats.find(reinterpret_cast<uint64_t>(draw_call_data.srvs[i])); it != device_data.original_upgraded_resource_views_formats.end())
                                                   {
                                                      const auto& [native_resource, original_view_format] = it->second;
                                                      ASSERT_ONCE(native_resource == upgraded_resource_pair.first); // Uh!?

                                                      // If the game already tried to create a view in the upgraded format, it means it simply read the format from the upgraded texture,
                                                      // and thus we can assume the original format would have been the same as the original texture (or anyway the most obvious non typeless version of it)
                                                      DXGI_FORMAT adjusted_original_view_format = (DXGI_FORMAT(original_view_format) == DXGI_FORMAT_R16G16B16A16_FLOAT) ? DXGI_FORMAT(upgraded_resource_pair.second) : DXGI_FORMAT(original_view_format);

                                                      ImGui::Text("RV Original Format: %s", GetFormatName(adjusted_original_view_format));
                                                      // TODO: if the native texture format is TYPELESS, don't send this warning? Alternatively keep track of how the resource was last used (with what view it was written to, if any), and base the state off of that,
                                                      // then check the current state of the backbuffer and whether it's currently holding linear or gamma space colors (we don't store that anywhere atm, given it's not that simple).
                                                      // We could also send a message in case the upgraded format was float and the original format was not linear, but that's kinda obvious already (that the current color encoding might not be the most optimal).
                                                      if (IsLinearFormat(DXGI_FORMAT(upgraded_resource_pair.second)) != IsLinearFormat(DXGI_FORMAT(adjusted_original_view_format)))
                                                      {
                                                         ImGui::PushStyleColor(ImGuiCol_Text, IM_COL32(255, 0, 0, 255)); // Red
                                                         ImGui::Text("RV Gamma Change");
                                                         ImGui::PopStyleColor();
                                                      }
                                                   }
                                                
                                                   break;
                                                }
                                             }
                                          }

                                          const bool is_highlighted_resource = highlighted_resource == sr_hash;
                                          if (is_highlighted_resource ? ImGui::Button("Unhighlight Resource") : ImGui::Button("Highlight Resource"))
                                          {
                                             highlighted_resource = is_highlighted_resource ? "" : sr_hash;
                                          }

                                          // TODO: hide the button if the resource is a buffer
                                          if (debug_draw_shader_enabled && (debug_draw_mode != DebugDrawMode::ShaderResource || debug_draw_view_index != i) && ImGui::Button("Debug Draw Resource"))
                                          {
                                             if (debug_draw_mode == DebugDrawMode::Depth)
                                             {
                                                debug_draw_options &= ~(uint32_t)DebugDrawTextureOptionsMask::RedOnly;
                                             }
                                             debug_draw_mode = DebugDrawMode::ShaderResource;
                                             debug_draw_view_index = i;
                                          }

                                          ImGui::PopID();
                                       }
                                    }

                                    if (pipeline_pair->second->HasPixelShader() || pipeline_pair->second->HasComputeShader())
                                    {
                                       for (UINT i = 0; i < D3D11_1_UAV_SLOT_COUNT; i++)
                                       {
                                          auto uav_format = draw_call_data.uav_format[i];
                                          if (uav_format == DXGI_FORMAT_UNKNOWN) // Resource was not valid
                                          {
                                             continue;
                                          }
                                          const bool non_referenced = uav_format == DXGI_FORMAT(-1);
                                          if (trace_ignore_non_bound_shader_referenced_resources && uav_format == DXGI_FORMAT(-1))
                                          {
                                             continue;
                                          }
                                          auto ua_format = draw_call_data.ua_format[i];
                                          auto ua_size = draw_call_data.ua_size[i];
                                          auto ua_hash = draw_call_data.ua_hash[i];
                                          auto ua_type_name = draw_call_data.ua_type_name[i];
                                          auto ua_is_rt = draw_call_data.ua_is_rt[i];

                                          ImGui::PushID(i + D3D11_COMMONSHADER_INPUT_RESOURCE_SLOT_COUNT); // Offset by the max amount of previous iterations from above

                                          if (!is_first_view) { ImGui::Text(""); };
                                          is_first_view = false;
                                          ImGui::Text("UAV Index: %u", i);
                                          if (non_referenced)
                                          {
                                             ImGui::PushStyleColor(ImGuiCol_Text, IM_COL32(255, 0, 0, 255)); // Red
                                             ImGui::Text("R Referenced but Not Bound");
                                             ImGui::PopStyleColor();
                                             continue;
                                          }
                                          ImGui::Text("R Hash: %s", ua_hash.c_str());
                                          ImGui::Text("R Type: %s", ua_type_name.c_str());
                                          if (GetFormatName(ua_format) != nullptr)
                                          {
                                             ImGui::Text("R Format: %s", GetFormatName(ua_format));
                                          }
                                          else
                                          {
                                             ImGui::Text("R Format: %u", ua_format);
                                          }
                                          if (GetFormatName(uav_format) != nullptr)
                                          {
                                             ImGui::Text("RV Format: %s", GetFormatName(uav_format));
                                          }
                                          else
                                          {
                                             ImGui::Text("RV Format: %u", uav_format);
                                          }
                                          ImGui::Text("R Size: %ux%ux%ux%u", ua_size.x, ua_size.y, ua_size.z, ua_size.w);
                                          ImGui::Text("R is RT: %s", ua_is_rt ? "True" : "False");
                                          {
                                             const std::shared_lock lock(device_data.mutex);
                                             for (auto upgraded_resource_pair : device_data.original_upgraded_resources_formats)
                                             {
                                                void* upgraded_resource_ptr = reinterpret_cast<void*>(upgraded_resource_pair.first);
                                                if (ua_hash == std::to_string(std::hash<void*>{}(upgraded_resource_ptr)))
                                                {
                                                   ImGui::Text("R: Upgraded");

                                                   ImGui::Text("R Original Format: %s", GetFormatName(DXGI_FORMAT(upgraded_resource_pair.second)));

                                                   if (const auto it = device_data.original_upgraded_resource_views_formats.find(reinterpret_cast<uint64_t>(draw_call_data.uavs[i])); it != device_data.original_upgraded_resource_views_formats.end())
                                                   {
                                                      const auto& [native_resource, original_view_format] = it->second;
                                                      ASSERT_ONCE(native_resource == upgraded_resource_pair.first); // Uh!?
                                                      DXGI_FORMAT adjusted_original_view_format = (DXGI_FORMAT(original_view_format) == DXGI_FORMAT_R16G16B16A16_FLOAT) ? DXGI_FORMAT(upgraded_resource_pair.second) : DXGI_FORMAT(original_view_format);
                                                      ImGui::Text("RV Original Format: %s", GetFormatName(adjusted_original_view_format));
                                                      if (IsLinearFormat(DXGI_FORMAT(upgraded_resource_pair.second)) != IsLinearFormat(adjusted_original_view_format))
                                                      {
                                                         ImGui::PushStyleColor(ImGuiCol_Text, IM_COL32(255, 0, 0, 255)); // Red
                                                         ImGui::Text("RV Gamma Change");
                                                         ImGui::PopStyleColor();
                                                      }
                                                   }

                                                   break;
                                                }
                                             }
                                          }

                                          const bool is_highlighted_resource = highlighted_resource == ua_hash;
                                          if (is_highlighted_resource ? ImGui::Button("Unhighlight Resource") : ImGui::Button("Highlight Resource"))
                                          {
                                             highlighted_resource = is_highlighted_resource ? "" : ua_hash;
                                          }

                                          if (debug_draw_shader_enabled && (debug_draw_mode != DebugDrawMode::UnorderedAccessView || debug_draw_view_index != i) && ImGui::Button("Debug Draw Resource"))
                                          {
                                             if (debug_draw_mode == DebugDrawMode::Depth)
                                             {
                                                debug_draw_options &= ~(uint32_t)DebugDrawTextureOptionsMask::RedOnly;
                                             }
                                             debug_draw_mode = DebugDrawMode::UnorderedAccessView;
                                             debug_draw_view_index = i;
                                          }

                                          bool is_redirection_target = pipeline_pair->second->redirect_data.target_type == CachedPipeline::RedirectData::RedirectTargetType::UAV && pipeline_pair->second->redirect_data.target_index == i;
                                          if (pipeline_pair->second->redirect_data.source_type != CachedPipeline::RedirectData::RedirectSourceType::None && is_redirection_target && ImGui::Button("Disable Copy"))
                                          {
                                             pipeline_pair->second->redirect_data.source_type = CachedPipeline::RedirectData::RedirectSourceType::None;
                                             pipeline_pair->second->redirect_data.target_type = CachedPipeline::RedirectData::RedirectTargetType::None;
                                             pipeline_pair->second->redirect_data.source_index = 0;
                                             pipeline_pair->second->redirect_data.target_index = 0;
                                             is_redirection_target = false;
                                          }
                                          if ((pipeline_pair->second->redirect_data.source_type != CachedPipeline::RedirectData::RedirectSourceType::SRV || !is_redirection_target) && ImGui::Button("Copy from SRV"))
                                          {
                                             pipeline_pair->second->redirect_data.source_type = CachedPipeline::RedirectData::RedirectSourceType::SRV;
                                             pipeline_pair->second->redirect_data.target_type = CachedPipeline::RedirectData::RedirectTargetType::UAV;
                                             pipeline_pair->second->redirect_data.source_index = 0;
                                             pipeline_pair->second->redirect_data.target_index = i;
                                             is_redirection_target = true;
                                          }
                                          if ((pipeline_pair->second->redirect_data.source_type != CachedPipeline::RedirectData::RedirectSourceType::UAV || !is_redirection_target) && ImGui::Button("Copy from UAV"))
                                          {
                                             pipeline_pair->second->redirect_data.source_type = CachedPipeline::RedirectData::RedirectSourceType::UAV;
                                             pipeline_pair->second->redirect_data.target_type = CachedPipeline::RedirectData::RedirectTargetType::UAV;
                                             pipeline_pair->second->redirect_data.source_index = 0;
                                             pipeline_pair->second->redirect_data.target_index = i;
                                             is_redirection_target = true;
                                          }
                                          if (is_redirection_target)
                                          {
                                             ImGui::SliderInt("Copy from View Index", &pipeline_pair->second->redirect_data.source_index, 0, D3D11_COMMONSHADER_INPUT_RESOURCE_SLOT_COUNT /*The largest allowed view count by type*/);
                                          }

                                          ImGui::PopID();
                                       }
                                    }

                                    if (pipeline_pair->second->HasPixelShader())
                                    {
                                       auto blend_desc = draw_call_data.blend_desc;

                                       for (UINT i = 0; i < D3D11_SIMULTANEOUS_RENDER_TARGET_COUNT; i++)
                                       {
                                          auto rtv_format = draw_call_data.rtv_format[i];
                                          if (rtv_format == DXGI_FORMAT_UNKNOWN) // Resource was not valid
                                          {
                                             continue;
                                          }
                                          const bool non_referenced = rtv_format == DXGI_FORMAT(-1);
                                          if (trace_ignore_non_bound_shader_referenced_resources && rtv_format == DXGI_FORMAT(-1))
                                          {
                                             continue;
                                          }
                                          auto rt_format = draw_call_data.rt_format[i];
                                          auto rt_size = draw_call_data.rt_size[i];
                                          auto rt_hash = draw_call_data.rt_hash[i];
                                          auto rt_type_name = draw_call_data.rt_type_name[i];

                                          ImGui::PushID(i + D3D11_COMMONSHADER_INPUT_RESOURCE_SLOT_COUNT + D3D11_1_UAV_SLOT_COUNT); // Offset by the max amount of previous iterations from above

                                          if (!is_first_view) { ImGui::Text(""); };
                                          is_first_view = false;
                                          ImGui::Text("RTV Index: %u", i);
                                          if (non_referenced)
                                          {
                                             ImGui::PushStyleColor(ImGuiCol_Text, IM_COL32(255, 0, 0, 255)); // Red
                                             ImGui::Text("R Referenced but Not Bound");
                                             ImGui::PopStyleColor();
                                             continue;
                                          }
                                          ImGui::Text("R Hash: %s", rt_hash.c_str());
                                          ImGui::Text("R Type: %s", rt_type_name.c_str());
                                          if (GetFormatName(rt_format) != nullptr)
                                          {
                                             ImGui::Text("R Format: %s", GetFormatName(rt_format));
                                          }
                                          else
                                          {
                                             ImGui::Text("R Format: %u", rt_format);
                                          }
                                          if (GetFormatName(rtv_format) != nullptr)
                                          {
                                             ImGui::Text("RV Format: %s", GetFormatName(rtv_format));
                                          }
                                          else
                                          {
                                             ImGui::Text("RV Format: %u", rtv_format);
                                          }
                                          ImGui::Text("R Size: %ux%ux%ux%u", rt_size.x, rt_size.y, rt_size.z, rt_size.w);
                                          {
                                             const std::shared_lock lock(device_data.mutex);
                                             // TODO: this is missing the "R is UAV" print
                                             for (auto upgraded_resource_pair : device_data.original_upgraded_resources_formats)
                                             {
                                                void* upgraded_resource_ptr = reinterpret_cast<void*>(upgraded_resource_pair.first);
                                                if (rt_hash == std::to_string(std::hash<void*>{}(upgraded_resource_ptr)))
                                                {
                                                   ImGui::Text("R: Upgraded");

                                                   ImGui::Text("R Original Format: %s", GetFormatName(DXGI_FORMAT(upgraded_resource_pair.second)));

                                                   if (const auto it = device_data.original_upgraded_resource_views_formats.find(reinterpret_cast<uint64_t>(draw_call_data.rtvs[i])); it != device_data.original_upgraded_resource_views_formats.end())
                                                   {
                                                      const auto& [native_resource, original_view_format] = it->second;
                                                      ASSERT_ONCE(native_resource == upgraded_resource_pair.first); // Uh!?
                                                      DXGI_FORMAT adjusted_original_view_format = (DXGI_FORMAT(original_view_format) == DXGI_FORMAT_R16G16B16A16_FLOAT) ? DXGI_FORMAT(upgraded_resource_pair.second) : DXGI_FORMAT(original_view_format);
                                                      ImGui::Text("RV Original Format: %s", GetFormatName(adjusted_original_view_format));
                                                      if (IsLinearFormat(DXGI_FORMAT(upgraded_resource_pair.second)) != IsLinearFormat(adjusted_original_view_format))
                                                      {
                                                         ImGui::PushStyleColor(ImGuiCol_Text, IM_COL32(255, 0, 0, 255)); // Red
                                                         ImGui::Text("RV Gamma Change");
                                                         ImGui::PopStyleColor();
                                                      }
                                                   }

                                                   break;
                                                }
                                             }
                                          }
                                          ImGui::Text("R Swapchain: %s", draw_call_data.rt_is_swapchain[i] ? "True" : "False"); // TODO: add this for computer shaders / UAVs toos

                                          // See "ui_data.blend_mode" for details on usage
                                          if (blend_desc.RenderTarget[i].BlendEnable)
                                          {
                                             bool has_drawn_blend_rgb_text = false;

                                             if (blend_desc.RenderTarget[i].SrcBlend == D3D11_BLEND::D3D11_BLEND_BLEND_FACTOR || blend_desc.RenderTarget[i].DestBlend == D3D11_BLEND::D3D11_BLEND_BLEND_FACTOR
                                                || blend_desc.RenderTarget[i].SrcBlend == D3D11_BLEND::D3D11_BLEND_INV_BLEND_FACTOR || blend_desc.RenderTarget[i].DestBlend == D3D11_BLEND::D3D11_BLEND_INV_BLEND_FACTOR)
                                             {
                                                ImGui::Text("Blend RGB Mode: Blend Factor (Any)");
                                                has_drawn_blend_rgb_text = true;
                                             }
                                             else if (blend_desc.RenderTarget[i].SrcBlend == D3D11_BLEND::D3D11_BLEND_ZERO && blend_desc.RenderTarget[i].DestBlend == D3D11_BLEND::D3D11_BLEND_ZERO)
                                             {
                                                ImGui::Text("Blend RGB Mode: Zero (Override Color with Zero)");
                                                has_drawn_blend_rgb_text = true;
                                             }

                                             if (!has_drawn_blend_rgb_text && blend_desc.RenderTarget[i].BlendOp == D3D11_BLEND_OP::D3D11_BLEND_OP_ADD)
                                             {
                                                if (blend_desc.RenderTarget[i].SrcBlend == D3D11_BLEND::D3D11_BLEND_ONE && blend_desc.RenderTarget[i].DestBlend == D3D11_BLEND::D3D11_BLEND_ONE)
                                                {
                                                   ImGui::Text("Blend RGB Mode: Additive Color");
                                                   has_drawn_blend_rgb_text = true;
                                                }
                                                else if (blend_desc.RenderTarget[i].SrcBlend == D3D11_BLEND::D3D11_BLEND_SRC_ALPHA && blend_desc.RenderTarget[i].DestBlend == D3D11_BLEND::D3D11_BLEND_ONE)
                                                {
                                                   ImGui::Text("Blend RGB Mode: Additive Alpha");
                                                   has_drawn_blend_rgb_text = true;
                                                }
                                                else if (blend_desc.RenderTarget[i].SrcBlend == D3D11_BLEND::D3D11_BLEND_SRC_ALPHA_SAT && blend_desc.RenderTarget[i].DestBlend == D3D11_BLEND::D3D11_BLEND_ONE)
                                                {
                                                   ImGui::Text("Blend RGB Mode: Additive Alpha (Saturated)");
                                                   has_drawn_blend_rgb_text = true;
                                                }
                                                else if (blend_desc.RenderTarget[i].SrcBlend == D3D11_BLEND::D3D11_BLEND_ONE && blend_desc.RenderTarget[i].DestBlend == D3D11_BLEND::D3D11_BLEND_INV_SRC_ALPHA)
                                                {
                                                   ImGui::Text("Blend RGB Mode: Premultiplied Alpha");
                                                   has_drawn_blend_rgb_text = true;
                                                }
                                                else if (blend_desc.RenderTarget[i].SrcBlend == D3D11_BLEND::D3D11_BLEND_SRC_ALPHA && blend_desc.RenderTarget[i].DestBlend == D3D11_BLEND::D3D11_BLEND_INV_SRC_ALPHA)
                                                {
                                                   ImGui::Text("Blend RGB Mode: Straight Alpha");
                                                   has_drawn_blend_rgb_text = true;
                                                }
                                                else if (blend_desc.RenderTarget[i].SrcBlend == D3D11_BLEND::D3D11_BLEND_SRC_ALPHA_SAT && blend_desc.RenderTarget[i].DestBlend == D3D11_BLEND::D3D11_BLEND_INV_SRC_ALPHA)
                                                {
                                                   ImGui::Text("Blend RGB Mode: Straight Alpha (Saturated)");
                                                   has_drawn_blend_rgb_text = true;
                                                }
                                                // Often used for lighting, glow, or compositing effects where the destination alpha controls how much of the source contributes
                                                else if (blend_desc.RenderTarget[i].SrcBlend == D3D11_BLEND::D3D11_BLEND_DEST_ALPHA && blend_desc.RenderTarget[i].DestBlend == D3D11_BLEND::D3D11_BLEND_ONE)
                                                {
                                                   ImGui::Text("Blend RGB Mode: Reverse Premultiplied Alpha");
                                                   has_drawn_blend_rgb_text = true;
                                                }
                                                else if (blend_desc.RenderTarget[i].SrcBlend == D3D11_BLEND::D3D11_BLEND_DEST_COLOR && blend_desc.RenderTarget[i].DestBlend == D3D11_BLEND::D3D11_BLEND_ZERO)
                                                {
                                                   ImGui::Text("Blend RGB Mode: Multiplicative Color");
                                                   has_drawn_blend_rgb_text = true;
                                                }
                                                // It's enabled but it's as if it was disabled
                                                else if (blend_desc.RenderTarget[i].SrcBlend == D3D11_BLEND::D3D11_BLEND_ONE && blend_desc.RenderTarget[i].DestBlend == D3D11_BLEND::D3D11_BLEND_ZERO)
                                                {
                                                   ImGui::Text("Blend RGB Mode: Disabled");
                                                   has_drawn_blend_rgb_text = true;
                                                }
                                             }
                                             else if (!has_drawn_blend_rgb_text && blend_desc.RenderTarget[i].BlendOp == D3D11_BLEND_OP::D3D11_BLEND_OP_REV_SUBTRACT)
                                             {
                                                if (blend_desc.RenderTarget[i].SrcBlend == D3D11_BLEND::D3D11_BLEND_ONE && blend_desc.RenderTarget[i].DestBlend == D3D11_BLEND::D3D11_BLEND_ONE)
                                                {
                                                   ImGui::Text("Blend RGB Mode: Subctractive Color");
                                                   has_drawn_blend_rgb_text = true;
                                                }
                                                else if (blend_desc.RenderTarget[i].SrcBlend == D3D11_BLEND::D3D11_BLEND_SRC_ALPHA && blend_desc.RenderTarget[i].DestBlend == D3D11_BLEND::D3D11_BLEND_ONE)
                                                {
                                                   ImGui::Text("Blend RGB Mode: Subctractive Alpha");
                                                   has_drawn_blend_rgb_text = true;
                                                }
                                                else if (blend_desc.RenderTarget[i].SrcBlend == D3D11_BLEND::D3D11_BLEND_SRC_ALPHA_SAT && blend_desc.RenderTarget[i].DestBlend == D3D11_BLEND::D3D11_BLEND_ONE)
                                                {
                                                   ImGui::Text("Blend RGB Mode: Subctractive Alpha (Saturated)");
                                                   has_drawn_blend_rgb_text = true;
                                                }
                                                else if (blend_desc.RenderTarget[i].SrcBlend == D3D11_BLEND::D3D11_BLEND_ZERO && blend_desc.RenderTarget[i].DestBlend == D3D11_BLEND::D3D11_BLEND_ONE)
                                                {
                                                   ImGui::Text("Blend RGB Mode: Disabled");
                                                   has_drawn_blend_rgb_text = true;
                                                }
                                                else
                                                {
                                                   ImGui::Text("Blend RGB Mode: Subtractive (Any)");
                                                   has_drawn_blend_rgb_text = true;
                                                }
                                             }

                                             if (!has_drawn_blend_rgb_text)
                                             {
                                                ImGui::Text("Blend RGB Mode: Unknown");
                                                has_drawn_blend_rgb_text = true;
                                             }

                                             bool has_drawn_blend_a_text = false;

                                             // It's enabled but it's as if it was disabled
                                             if (blend_desc.RenderTarget[i].SrcBlendAlpha == D3D11_BLEND::D3D11_BLEND_BLEND_FACTOR || blend_desc.RenderTarget[i].DestBlendAlpha == D3D11_BLEND::D3D11_BLEND_BLEND_FACTOR
                                                || blend_desc.RenderTarget[i].SrcBlendAlpha == D3D11_BLEND::D3D11_BLEND_INV_BLEND_FACTOR || blend_desc.RenderTarget[i].DestBlendAlpha == D3D11_BLEND::D3D11_BLEND_INV_BLEND_FACTOR)
                                             {
                                                ImGui::Text("Blend A Mode: Blend Factor (Any)");
                                                has_drawn_blend_a_text = true;
                                             }
                                             if (blend_desc.RenderTarget[i].SrcBlendAlpha == D3D11_BLEND::D3D11_BLEND_ZERO && blend_desc.RenderTarget[i].DestBlendAlpha == D3D11_BLEND::D3D11_BLEND_ZERO)
                                             {
                                                ImGui::Text("Blend A Mode: Zero (Overwrite Alpha with Zero)");
                                                has_drawn_blend_a_text = true;
                                             }

                                             if (!has_drawn_blend_a_text && blend_desc.RenderTarget[i].BlendOpAlpha == D3D11_BLEND_OP::D3D11_BLEND_OP_ADD)
                                             {
                                                if (blend_desc.RenderTarget[i].SrcBlendAlpha == D3D11_BLEND::D3D11_BLEND_SRC_ALPHA && blend_desc.RenderTarget[i].DestBlendAlpha == D3D11_BLEND::D3D11_BLEND_INV_SRC_ALPHA)
                                                {
                                                   ImGui::Text("Blend A Mode: Standard Transparency");
                                                   has_drawn_blend_a_text = true;
                                                }
                                                else if (blend_desc.RenderTarget[i].SrcBlendAlpha == D3D11_BLEND::D3D11_BLEND_SRC_ALPHA_SAT && blend_desc.RenderTarget[i].DestBlendAlpha == D3D11_BLEND::D3D11_BLEND_INV_SRC_ALPHA)
                                                {
                                                   ImGui::Text("Blend A Mode: Standard Transparency (Saturated)");
                                                   has_drawn_blend_a_text = true;
                                                }
                                                else if (blend_desc.RenderTarget[i].SrcBlendAlpha == D3D11_BLEND::D3D11_BLEND_DEST_ALPHA && blend_desc.RenderTarget[i].DestBlendAlpha == D3D11_BLEND::D3D11_BLEND_ZERO)
                                                {
                                                   ImGui::Text("Blend A Mode: Multiplicative");
                                                   has_drawn_blend_a_text = true;
                                                }
                                                else if (blend_desc.RenderTarget[i].SrcBlendAlpha == D3D11_BLEND::D3D11_BLEND_ONE && blend_desc.RenderTarget[i].DestBlendAlpha == D3D11_BLEND::D3D11_BLEND_ONE)
                                                {
                                                   ImGui::Text("Blend A Mode: Additive");
                                                   has_drawn_blend_a_text = true;
                                                }
                                                else if (blend_desc.RenderTarget[i].SrcBlendAlpha == D3D11_BLEND::D3D11_BLEND_ONE && blend_desc.RenderTarget[i].DestBlendAlpha == D3D11_BLEND::D3D11_BLEND_ZERO)
                                                {
                                                   ImGui::Text("Blend A Mode: Source Alpha (Overwrite Alpha, Blending Disabled)");
                                                   has_drawn_blend_a_text = true;
                                                }
                                                else if (blend_desc.RenderTarget[i].SrcBlendAlpha == D3D11_BLEND::D3D11_BLEND_ZERO && blend_desc.RenderTarget[i].DestBlendAlpha == D3D11_BLEND::D3D11_BLEND_ONE)
                                                {
                                                   ImGui::Text("Blend A Mode: Destination Alpha (Preserve Alpha)");
                                                   has_drawn_blend_a_text = true;
                                                }
                                             }
                                             else if (!has_drawn_blend_a_text && blend_desc.RenderTarget[i].BlendOpAlpha == D3D11_BLEND_OP::D3D11_BLEND_OP_REV_SUBTRACT)
                                             {
                                                ImGui::Text("Blend A Mode: Subtractive (Any)");
                                                has_drawn_blend_a_text = true;
                                             }

                                             // TODO: add more of these! All... and blend factor and other stuff
                                             if (!has_drawn_blend_a_text)
                                             {
                                                ImGui::Text("Blend A Mode: Unknown");
                                                has_drawn_blend_a_text = true;
                                             }
                                          }
                                          else
                                          {
                                             ImGui::Text("Blend Mode: Disabled");
                                          }

                                          const bool is_highlighted_resource = highlighted_resource == rt_hash;
                                          if (is_highlighted_resource ? ImGui::Button("Unhighlight Resource") : ImGui::Button("Highlight Resource"))
                                          {
                                             highlighted_resource = is_highlighted_resource ? "" : rt_hash;
                                          }

                                          if (debug_draw_shader_enabled && (debug_draw_mode != DebugDrawMode::RenderTarget || debug_draw_view_index != i) && ImGui::Button("Debug Draw Resource"))
                                          {
                                             if (debug_draw_mode == DebugDrawMode::Depth)
                                             {
                                                debug_draw_options &= ~(uint32_t)DebugDrawTextureOptionsMask::RedOnly;
                                             }
                                             debug_draw_mode = DebugDrawMode::RenderTarget;
                                             debug_draw_view_index = i;
                                          }

                                          bool is_redirection_target = pipeline_pair->second->redirect_data.target_type == CachedPipeline::RedirectData::RedirectTargetType::RTV && pipeline_pair->second->redirect_data.target_index == i;
                                          if (pipeline_pair->second->redirect_data.source_type != CachedPipeline::RedirectData::RedirectSourceType::None && is_redirection_target && ImGui::Button("Disable Copy"))
                                          {
                                             pipeline_pair->second->redirect_data.source_type = CachedPipeline::RedirectData::RedirectSourceType::None;
                                             pipeline_pair->second->redirect_data.target_type = CachedPipeline::RedirectData::RedirectTargetType::None;
                                             pipeline_pair->second->redirect_data.source_index = 0;
                                             pipeline_pair->second->redirect_data.target_index = 0;
                                             is_redirection_target = false;
                                          }
                                          if ((pipeline_pair->second->redirect_data.source_type != CachedPipeline::RedirectData::RedirectSourceType::SRV || !is_redirection_target) && ImGui::Button("Copy from SRV"))
                                          {
                                             pipeline_pair->second->redirect_data.source_type = CachedPipeline::RedirectData::RedirectSourceType::SRV;
                                             pipeline_pair->second->redirect_data.target_type = CachedPipeline::RedirectData::RedirectTargetType::RTV;
                                             pipeline_pair->second->redirect_data.source_index = 0;
                                             pipeline_pair->second->redirect_data.target_index = i;
                                             is_redirection_target = true;
                                          }
                                          if ((pipeline_pair->second->redirect_data.source_type != CachedPipeline::RedirectData::RedirectSourceType::UAV || !is_redirection_target) && ImGui::Button("Copy from UAV"))
                                          {
                                             pipeline_pair->second->redirect_data.source_type = CachedPipeline::RedirectData::RedirectSourceType::UAV;
                                             pipeline_pair->second->redirect_data.target_type = CachedPipeline::RedirectData::RedirectTargetType::RTV;
                                             pipeline_pair->second->redirect_data.source_index = 0;
                                             pipeline_pair->second->redirect_data.target_index = i;
                                             is_redirection_target = true;
                                          }
                                          if (is_redirection_target)
                                          {
                                             ImGui::SliderInt("Copy from View Index", &pipeline_pair->second->redirect_data.source_index, 0, D3D11_COMMONSHADER_INPUT_RESOURCE_SLOT_COUNT /*The largest allowed view count by type*/);
                                          }

                                          ImGui::PopID();
                                       }

                                       if (!is_first_view) { ImGui::Text(""); }; // No views drew before, skip space
                                       ImGui::Text("Depth State: %s", TraceDrawCallData::depth_state_names[(size_t)draw_call_data.depth_state]);
                                       ImGui::Text("Stencil Enabled: %s", draw_call_data.stencil_enabled ? "True" : "False");

                                       auto dsv_format = draw_call_data.dsv_format;
                                       if (dsv_format != DXGI_FORMAT_UNKNOWN && draw_call_data.depth_state != TraceDrawCallData::DepthStateType::Disabled && draw_call_data.depth_state != TraceDrawCallData::DepthStateType::Invalid)
                                       {
                                          // Note: "trace_ignore_non_bound_shader_referenced_resources" isn't implemented here
                                          auto ds_format = draw_call_data.ds_format;
                                          auto ds_size = draw_call_data.ds_size;
                                          auto ds_hash = draw_call_data.ds_hash;

                                          ImGui::PushID(D3D11_SIMULTANEOUS_RENDER_TARGET_COUNT + D3D11_COMMONSHADER_INPUT_RESOURCE_SLOT_COUNT + D3D11_1_UAV_SLOT_COUNT); // Offset by the max amount of previous iterations from above

                                          ImGui::Text("");
                                          ImGui::Text("Depth");
                                          ImGui::Text("R Hash: %s", ds_hash.c_str());
                                          if (GetFormatName(ds_format) != nullptr)
                                          {
                                             ImGui::Text("R Format: %s", GetFormatName(ds_format));
                                          }
                                          else
                                          {
                                             ImGui::Text("R Format: %u", ds_format);
                                          }
                                          if (GetFormatName(dsv_format) != nullptr)
                                          {
                                             ImGui::Text("RV Format: %s", GetFormatName(dsv_format));
                                          }
                                          else
                                          {
                                             ImGui::Text("RV Format: %u", dsv_format);
                                          }
                                          ImGui::Text("R Size: %ux%ux", ds_size.x, ds_size.y); // Should match all the Render Targets size

                                          const bool is_highlighted_resource = highlighted_resource == ds_hash;
                                          if (is_highlighted_resource ? ImGui::Button("Unhighlight Resource") : ImGui::Button("Highlight Resource"))
                                          {
                                             highlighted_resource = is_highlighted_resource ? "" : ds_hash;
                                          }

                                          ImGui::PopID();
                                       }

                                       const bool has_valid_depth = draw_call_data.depth_state != TraceDrawCallData::DepthStateType::Disabled
                                          && draw_call_data.depth_state != TraceDrawCallData::DepthStateType::Invalid;
                                       if (has_valid_depth && debug_draw_shader_enabled && debug_draw_mode != DebugDrawMode::Depth && ImGui::Button("Debug Draw Depth Resource"))
                                       {
                                          debug_draw_mode = DebugDrawMode::Depth;
                                          debug_draw_view_index = 0;
                                          debug_draw_options |= (uint32_t)DebugDrawTextureOptionsMask::RedOnly;
                                       }

                                       ImGui::Text("");
                                       ImGui::Text("Scissors Enabled: %s", draw_call_data.scissors ? "True" : "False");
                                       ImGui::Text("Viewport 0: x: %s y:%s w: %s h: %s",
                                          std::to_string(draw_call_data.viewport_0.x).c_str(),
                                          std::to_string(draw_call_data.viewport_0.y).c_str(),
                                          std::to_string(draw_call_data.viewport_0.z).c_str(),
                                          std::to_string(draw_call_data.viewport_0.w).c_str());
                                    }
                                 }
                                 ImGui::EndChild(); // StateAnalysisScroll
                              }
                              ImGui::EndChild(); // Settings and Info

                              pipeline_pair->second->skip_type = (CachedPipeline::ShaderSkipType)pipeline_skip_type;
                           }
                           lock.unlock(); // Needed to prevent "LoadCustomShaders()" from deadlocking, and anyway, there's no need to lock it beyond the for loop above

                           if (draw_call_data.type == TraceDrawCallData::TraceDrawCallType::CopyResource
                              || draw_call_data.type == TraceDrawCallData::TraceDrawCallType::CPURead
                              || draw_call_data.type == TraceDrawCallData::TraceDrawCallType::CPUWrite
                              || draw_call_data.type == TraceDrawCallData::TraceDrawCallType::BindResource
                              || draw_call_data.type == TraceDrawCallData::TraceDrawCallType::ClearResource
                              || draw_call_data.type == TraceDrawCallData::TraceDrawCallType::Custom)
                           {
                              if (ImGui::BeginChild("Settings and Info"))
                              {
                                 const bool has_source_resource = draw_call_data.type == TraceDrawCallData::TraceDrawCallType::CopyResource
                                    || draw_call_data.type == TraceDrawCallData::TraceDrawCallType::CPURead
                                    || draw_call_data.type == TraceDrawCallData::TraceDrawCallType::BindResource;
                                 const bool has_target_resource = draw_call_data.type != TraceDrawCallData::TraceDrawCallType::CPURead
                                    && draw_call_data.type != TraceDrawCallData::TraceDrawCallType::BindResource;

                                 if (has_source_resource)
                                 {
                                    ImGui::PushID(0);
                                    auto sr_format = draw_call_data.sr_format[0];
                                    auto sr_size = draw_call_data.sr_size[0];
                                    auto sr_hash = draw_call_data.sr_hash[0];
                                    auto sr_type_name = draw_call_data.sr_type_name[0];
                                    ImGui::Text("Source R Hash: %s", sr_hash.c_str());
                                    ImGui::Text("Source R Type: %s", sr_type_name.c_str());
                                    if (GetFormatName(sr_format) != nullptr)
                                    {
                                       ImGui::Text("Source R Format: %s", GetFormatName(sr_format));
                                    }
                                    ImGui::Text("Source R Size: %ux%ux%ux%u", sr_size.x, sr_size.y, sr_size.z, sr_size.w);
                                    for (uint64_t upgraded_resource : device_data.upgraded_resources)
                                    {
                                       void* upgraded_resource_ptr = reinterpret_cast<void*>(upgraded_resource);
                                       if (sr_hash == std::to_string(std::hash<void*>{}(upgraded_resource_ptr)))
                                       {
                                          ImGui::Text("Source R: Upgraded");
                                          // TODO: add og resource format here
                                          break;
                                       }
                                    }

                                    const bool is_highlighted_resource = highlighted_resource == sr_hash;
                                    if (is_highlighted_resource ? ImGui::Button("Unhighlight Resource") : ImGui::Button("Highlight Resource"))
                                    {
                                       highlighted_resource = is_highlighted_resource ? "" : sr_hash;
                                    }
                                    ImGui::PopID();
                                 }

                                 if (has_target_resource)
                                 {
                                    if (has_source_resource)
                                       ImGui::Text(""); // Empty line for spacing

                                    auto rt_format = draw_call_data.rt_format[0];
                                    auto rt_size = draw_call_data.rt_size[0];
                                    auto rt_hash = draw_call_data.rt_hash[0];
                                    auto rt_type_name = draw_call_data.rt_type_name[0];

                                    ImGui::PushID(1);
                                    ImGui::Text("Target R Hash: %s", rt_hash.c_str());
                                    ImGui::Text("Target R Type: %s", rt_type_name.c_str());
                                    if (GetFormatName(rt_format) != nullptr)
                                    {
                                       ImGui::Text("Target R Format: %s", GetFormatName(rt_format));
                                    }
                                    else
                                    {
                                       ImGui::Text("Target R Format: %u", rt_format);
                                    }
                                    ImGui::Text("Target R Size: %ux%ux%ux%u", rt_size.x, rt_size.y, rt_size.z, rt_size.w);
                                    for (uint64_t upgraded_resource : device_data.upgraded_resources)
                                    {
                                       void* upgraded_resource_ptr = reinterpret_cast<void*>(upgraded_resource);
                                       if (rt_hash == std::to_string(std::hash<void*>{}(upgraded_resource_ptr)))
                                       {
                                          ImGui::Text("Target R: Upgraded");
                                          break;
                                       }
                                    }
#if 0 // TODO: implement for this case (and above)
                                    ImGui::Text("Target R Swapchain: %s", draw_call_data.rt_is_swapchain[0] ? "True" : "False");
#endif

                                    const bool is_highlighted_resource = highlighted_resource == rt_hash;
                                    if (is_highlighted_resource ? ImGui::Button("Unhighlight Resource") : ImGui::Button("Highlight Resource"))
                                    {
                                       highlighted_resource = is_highlighted_resource ? "" : rt_hash;
                                    }

                                    ImGui::PopID();
                                 }
                              }
                              ImGui::EndChild(); // Settings and Info
                           }

                           // We need to do this here or it'd deadlock due to "s_mutex_generic" trying to be locked in shared mod again
                           if (reload && pipeline_handle != 0)
                           {
                              LoadCustomShaders(device_data, { pipeline_handle }, recompile);
                           }
                        }
                     }

                     ImGui::EndTabItem(); // Settings
                  }

                  const bool open_disassembly_tab_item = ImGui::BeginTabItem("Disassembly");
                  static bool opened_disassembly_tab_item = false;
                  if (open_disassembly_tab_item)
                  {
                     static std::string disasm_string;
                     CommandListData& cmd_list_data = *runtime->get_command_queue()->get_immediate_command_list()->get_private_data<CommandListData>();
                     const std::shared_lock lock_trace(cmd_list_data.mutex_trace);
                     static bool pending_disassembly_refresh = false;
                     bool refresh_disassembly = changed_selected || opened_disassembly_tab_item != open_disassembly_tab_item || pending_disassembly_refresh;
                     pending_disassembly_refresh = false;
                     if (selected_index >= 0 && cmd_list_data.trace_draw_calls_data.size() >= (selected_index + 1) && refresh_disassembly)
                     {
                        const auto pipeline_handle = cmd_list_data.trace_draw_calls_data.at(selected_index).pipeline_handle;
                        const std::unique_lock lock(s_mutex_generic);
                        if (auto pipeline_pair = device_data.pipeline_cache_by_pipeline_handle.find(pipeline_handle); pipeline_pair != device_data.pipeline_cache_by_pipeline_handle.end() && pipeline_pair->second != nullptr)
                        {
                           const std::lock_guard<std::recursive_mutex> lock_dumping(s_mutex_dumping);
                           auto* cache = (!pipeline_pair->second->shader_hashes.empty() && shader_cache.contains(pipeline_pair->second->shader_hashes[0])) ? shader_cache[pipeline_pair->second->shader_hashes[0]] : nullptr;
                           if (cache && cache->disasm.empty())
                           {
                              auto disasm_code = Shader::DisassembleShader(cache->data, cache->size);
                              if (disasm_code.has_value())
                              {
                                 cache->disasm.assign(disasm_code.value());
                              }
                              else
                              {
                                 cache->disasm.assign("DISASSEMBLY FAILED");
                              }
                           }
                           disasm_string.assign(cache ? cache->disasm : "");
                        }
                        else
                        {
                           disasm_string.clear();
                        }
                     }
                     // Force a refresh for later on
                     else if (refresh_disassembly)
                     {
                        pending_disassembly_refresh = true;
                        disasm_string.clear();
                     }

                     if (ImGui::BeginChild("DisassemblyCode"))
                     {
                        ImGui::InputTextMultiline(
                           "##disassemblyCode",
                           disasm_string.data(),
                           disasm_string.length() + 1, // Add the null terminator
                           ImVec2(-FLT_MIN, -FLT_MIN),
                           ImGuiInputTextFlags_ReadOnly);
                     }
                     ImGui::EndChild(); // DisassemblyCode
                     ImGui::EndTabItem(); // Disassembly
                  }
                  opened_disassembly_tab_item = open_disassembly_tab_item;

                  ImGui::PushID("##LiveCodeTabItem");
                  const bool open_live_tab_item = ImGui::BeginTabItem("Live Code");
                  ImGui::PopID();
                  static bool opened_live_tab_item = false;
                  if (open_live_tab_item)
                  {
                     static bool inline_includes = false;
                     bool inline_includes_toggled = ImGui::Checkbox("Inline Includes", &inline_includes);

                     static std::string hlsl_string;
                     static bool hlsl_error = false;
                     static bool hlsl_warning = false;
                     CommandListData& cmd_list_data = *runtime->get_command_queue()->get_immediate_command_list()->get_private_data<CommandListData>();
                     const std::shared_lock lock_trace(cmd_list_data.mutex_trace);
                     static bool pending_live_code_refresh = false;
                     bool refresh_live_code = changed_selected || inline_includes_toggled || opened_live_tab_item != open_live_tab_item || refresh_cloned_pipelines || pending_live_code_refresh;
                     pending_live_code_refresh = false;
                     if (selected_index >= 0 && cmd_list_data.trace_draw_calls_data.size() >= (selected_index + 1) && refresh_live_code)
                     {
                        bool hlsl_set = false;
                        const auto pipeline_handle = cmd_list_data.trace_draw_calls_data.at(selected_index).pipeline_handle;

                        const std::shared_lock lock(s_mutex_generic);
                        if (auto pipeline_pair = device_data.pipeline_cache_by_pipeline_handle.find(pipeline_handle);
                           pipeline_pair != device_data.pipeline_cache_by_pipeline_handle.end() && pipeline_pair->second != nullptr)
                        {
                           const auto pipeline = pipeline_pair->second;
                           const std::shared_lock lock_loading(s_mutex_loading);
                           const auto custom_shader = !pipeline->shader_hashes.empty() ? custom_shaders_cache[pipeline->shader_hashes[0]] : nullptr;
                           // If the custom shader has a compilation error, print that, otherwise read the file text
                           if (custom_shader != nullptr && !custom_shader->compilation_errors.empty())
                           {
                              hlsl_string = custom_shader->compilation_errors;
                              hlsl_error = custom_shader->compilation_error;
                              hlsl_warning = !custom_shader->compilation_error;
                              hlsl_set = true;
                           }
                           else if (custom_shader != nullptr && custom_shader->is_hlsl && !custom_shader->file_path.empty())
                           {
                              if (inline_includes && !custom_shader->preprocessed_code.empty())
                              {
                                 // Remove line breaks as there's a billion of them in the preprocessed code
                                 std::istringstream in_stream(custom_shader->preprocessed_code);
                                 std::ostringstream out_stream;
                                 std::string line;
                                 unsigned int empty_lines_count = 0;
                                 while (std::getline(in_stream, line))
                                 {
                                    // Skip lines that begin line "#line n" (unless they also include the name of a header, wrapped around "), for some reason the concatenated source file includes many of these.
                                    // Also skip pragmas as they aren't particularly relevant when viewing the source in a tiny box (this is arguable!).
                                    // Also skip any empty line beyond 2 ones, as usually it's empty spaces (or tabs) generated by the source concatenation.
                                    bool is_meta_line = line.rfind("#line ", 0) == 0 && !line.contains("\"");
                                    bool is_pragma_line = line.rfind("#pragma ", 0) == 0;
                                    if (is_meta_line || is_pragma_line || line.empty() || std::all_of(line.begin(), line.end(), [](unsigned char c) { return std::isspace(c); }))
                                    {
                                       empty_lines_count++;
                                    }
                                    else
                                    {
                                       empty_lines_count = 0;
                                    }

                                    if (!is_meta_line && !is_pragma_line && empty_lines_count <= 2)
                                    {
                                       out_stream << line << '\n';
                                    }
                                 }
                                 hlsl_string = out_stream.str();
                                 hlsl_error = false;
                                 hlsl_warning = false;
                                 hlsl_set = true;
                              }
                              else
                              {
                                 auto result = ReadTextFile(custom_shader->file_path);
                                 if (result.has_value())
                                 {
                                    hlsl_string.assign(result.value());
                                    hlsl_error = false;
                                    hlsl_warning = false;
                                    hlsl_set = true;
                                 }
                              }
                              if (!hlsl_set)
                              {
                                 hlsl_string.assign("FAILED TO READ FILE");
                                 hlsl_error = true;
                                 hlsl_warning = false;
                                 hlsl_set = true;
                              }
                           }
                        }

                        if (!hlsl_set)
                        {
                           hlsl_string.clear();
                           hlsl_error = false;
                           hlsl_warning = false;
                        }
                     }
                     else if (refresh_live_code)
                     {
                        hlsl_string.clear();
                        hlsl_error = false;
                        hlsl_warning = false;
                        pending_live_code_refresh = true;
                     }
                     opened_live_tab_item = open_live_tab_item;

                     if (ImGui::BeginChild("LiveCode"))
                     {
                        ImGui::PushStyleColor(ImGuiCol_Text, hlsl_error ? IM_COL32(255, 0, 0, 255) : (hlsl_warning ? IM_COL32(255, 165, 0, 255) : IM_COL32(255, 255, 255, 255))); // Red for Error, Orange for Warning, White for the rest
                        ImGui::InputTextMultiline(
                           "##liveCode",
                           hlsl_string.data(),
                           hlsl_string.length() + 1, // Add the null terminator
                           ImVec2(-FLT_MIN, -FLT_MIN),
                           ImGuiInputTextFlags_ReadOnly);
                        ImGui::PopStyleColor();
                     }
                     ImGui::EndChild(); // LiveCode
                     ImGui::EndTabItem(); // Live Code
                  }

                  ImGui::EndTabBar(); // ShadersCodeTab
               }
               ImGui::EndDisabled();
            }
            ImGui::EndChild(); // ShaderDetails

            ImGui::EndTabItem(); // Captured Commands
         }

#if !GRAPHICS_ANALYZER
         // Show even if "custom_shaders_cache" was empty
         if (ImGui::BeginTabItem("Custom Shaders"))
         {
            static int32_t shaders_selected_index = -1;

            const CachedCustomShader* selected_custom_shader = nullptr;

            if (ImGui::BeginChild("CustomShadersList", ImVec2(500, -FLT_MIN), ImGuiChildFlags_ResizeX))
            {
               if (ImGui::BeginListBox("##CustomShadersListBox", ImVec2(-FLT_MIN, -FLT_MIN)))
               {
                  int index = 0;
                  const std::shared_lock lock(s_mutex_loading);
                  for (const auto& custom_shader : custom_shaders_cache)
                  {
                     if (custom_shader.second == nullptr)
                     {
                        index++;
                        continue;
                     }

                     bool is_selected = shaders_selected_index == index;

                     auto text_color = IM_COL32(255, 255, 255, 255); // White

                     if (custom_shader.second->compilation_error)
                     {
                        text_color = IM_COL32(255, 0, 0, 255); // Red
                     }
                     else if (!custom_shader.second->compilation_errors.empty())
                     {
                        text_color = IM_COL32(255, 105, 0, 255); // Orange
                     }

                     ImGui::PushStyleColor(ImGuiCol_Text, text_color);
                     ImGui::PushID(index);
                     ImGui::PushID(custom_shader.second->preprocessed_hash); // Avoid files by the same simplified name (we also shader files with multiple hashes) from conflicting
                     
                     std::string file_name = custom_shader.second->file_path.stem().string();
                     const auto sm_length = strlen("xs_n_n"); // Shader Model
                     const size_t suffix_length = (custom_shader.second->is_luma_native ? 0 : (HASH_CHARACTERS_LENGTH + 2)) + 1 + sm_length; // Add "0x" and "." or "_"
                     if (file_name.length() >= suffix_length)
                     {
                        file_name.erase(file_name.length() - suffix_length, suffix_length);
                     }
                     if (file_name.ends_with('_'))
                     {
                        file_name.erase(file_name.length() - 1, 1);
                     }
                     if (file_name.size() == 0)
                     {
                        file_name = "NO NAME";
                        text_color = IM_COL32(255, 0, 0, 255); // Red
                     }

                     if (ImGui::Selectable(file_name.c_str(), is_selected))
                     {
                        shaders_selected_index = index;
                        is_selected = shaders_selected_index == index;
                     }
                     ImGui::PopID();
                     ImGui::PopID();
                     ImGui::PopStyleColor();

                     if (is_selected)
                     {
                        ImGui::SetItemDefaultFocus();
                        selected_custom_shader = custom_shader.second;
                     }

                     index++;
                  }
                  ImGui::EndListBox();
               }
            }
            ImGui::EndChild(); // CustomShadersList

            ImGui::SameLine();
            if (ImGui::BeginChild("##ShaderDetails", ImVec2(0, 0)))
            {
               ImGui::BeginDisabled(selected_custom_shader != nullptr);

               // Make sure our selected shader is still in the "custom_shaders_cache" list, without blocking its mutex through the whole imgui rendering
               bool custom_shader_found = false;
               const std::shared_lock lock(s_mutex_loading);
               for (const auto& custom_shader : custom_shaders_cache)
               {
                  if (selected_custom_shader != nullptr && custom_shader.second == selected_custom_shader)
                  {
                     custom_shader_found = true;
                     break;
                  }
               }
               if (custom_shader_found)
               {
                  // TODO: show more info here (e.g. in how many pipelines it's used), the shader type, show the code, the hash, add open folder buttons etc

                  ImGui::Text("Type: %s", selected_custom_shader->is_hlsl ? "hlsl" : "cso");
                  ImGui::Text("Luma Native: %s", selected_custom_shader->is_luma_native ? "True" : "False");

                  ImGui::Text("Full Path: %s", selected_custom_shader->file_path.string().c_str());
               }

               ImGui::EndDisabled();
            }
            ImGui::EndChild(); // ShaderDetails

            ImGui::EndTabItem(); // Custom Shaders
         }

         if (ImGui::BeginTabItem("Upgraded Textures"))
         {
            static int32_t resources_selected_index = -1;

            com_ptr<ID3D11Resource> selected_resource;

            if (ImGui::BeginChild("TexturesList", ImVec2(500, -FLT_MIN), ImGuiChildFlags_ResizeX))
            {
               if (ImGui::BeginListBox("##TexturesListBox", ImVec2(-FLT_MIN, -FLT_MIN)))
               {
                  int index = 0;
                  const std::shared_lock lock(device_data.mutex); // Note: this is probably not 100% safe, as we don't keep the resources as a com ptr, DX might destroy them as we iterate the array, but this is debug code so, whatever!
                  for (const auto upgraded_resource : device_data.upgraded_resources)
                  {
                     if (upgraded_resource == 0)
                     {
                        index++;
                        continue;
                     }

                     com_ptr<ID3D11Resource> native_resource = reinterpret_cast<ID3D11Resource*>(upgraded_resource);

                     bool is_selected = resources_selected_index == index;

                     auto text_color = IM_COL32(255, 255, 255, 255); // White

                     bool upgraded = true; // TODO: add all resources (textures), including non upgraded ones, cloned ones etc, swapchain etc
                     if (upgraded)
                     {
                        text_color = IM_COL32(0, 255, 0, 255); // Green
                     }

                     std::string name = std::to_string(std::hash<void*>{}(native_resource.get()));

                     const bool is_highlighted_resource = highlighted_resource == name;
                     if (is_highlighted_resource)
                     {
                        text_color = IM_COL32(255, 0, 0, 255); // Red
                     }

                     ImGui::PushStyleColor(ImGuiCol_Text, text_color);
                     ImGui::PushID(index);

                     std::optional<std::string> debug_name = GetD3DNameW(native_resource.get());
                     if (debug_name.has_value())
                     {
                        name = debug_name.value();
                     }

                     if (ImGui::Selectable(name.c_str(), is_selected))
                     {
                        resources_selected_index = index;
                        is_selected = resources_selected_index == index;
                     }
                     ImGui::PopID();
                     ImGui::PopStyleColor();

                     if (is_selected)
                     {
                        ImGui::SetItemDefaultFocus();
                        selected_resource = native_resource;
                     }

                     index++;
                  }
                  ImGui::EndListBox();
               }
            }
            ImGui::EndChild(); // TexturesList

            ImGui::SameLine();
            if (ImGui::BeginChild("##TexturesDetails", ImVec2(0, 0)))
            {
               if (selected_resource.get())
               {
                  // TODO: show more info here (e.g. in which shaders it has been used, the amount of times it's been used)

                  std::string hash = std::to_string(std::hash<void*>{}(selected_resource.get()));
                  ImGui::Text("Hash: %s", hash.c_str());

                  std::optional<std::string> debug_name = GetD3DNameW(selected_resource.get());
                  if (debug_name.has_value())
                  {
                     ImGui::Text("Debug Name: %s", debug_name.value().c_str());
                  }

                  ImGui::Text("Upgraded: %s", "True");

                  bool debug_draw_resource_enabled = device_data.debug_draw_texture == selected_resource;
                  UINT extra_refs = 1; // Our current local ref.
                  if (debug_draw_resource_enabled) extra_refs++; // The debug draw ref
                  // Note: there possibly might be more, spread into render targets (actually they don't seem to add references?), SRVs etc, that we set ourselves, but it's hard, but it might actually be correct already.
                  // ReShade doesn't seem to keep textures with hard refences, instead they add private data with a destructor to them, to detect when they are being garbage collected.

                  ImGui::Text("Reference Count: %u", selected_resource.ref_count() - extra_refs);

                  com_ptr<ID3D11Texture2D> selected_texture_2d;
                  selected_resource->QueryInterface(&selected_texture_2d);
                  com_ptr<ID3D11Texture3D> selected_texture_3d;
                  selected_resource->QueryInterface(&selected_texture_3d);
                  com_ptr<ID3D11Texture1D> selected_texture_1d;
                  selected_resource->QueryInterface(&selected_texture_1d);

                  DXGI_FORMAT selected_texture_format = DXGI_FORMAT_UNKNOWN;
                  uint4 selected_texture_size = { 1, 1, 1, 1 };
                  if (selected_texture_2d)
                  {
                     D3D11_TEXTURE2D_DESC texture_desc;
                     selected_texture_2d->GetDesc(&texture_desc);
                     selected_texture_format = texture_desc.Format;
                     selected_texture_size.x = texture_desc.Width;
                     selected_texture_size.y = texture_desc.Height;
                     selected_texture_size.z = texture_desc.ArraySize;
                     selected_texture_size.w = max(texture_desc.MipLevels, texture_desc.SampleDesc.Count);
                  }
                  else if (selected_texture_3d)
                  {
                     D3D11_TEXTURE3D_DESC texture_desc;
                     selected_texture_3d->GetDesc(&texture_desc);
                     selected_texture_format = texture_desc.Format;
                     selected_texture_size.x = texture_desc.Width;
                     selected_texture_size.y = texture_desc.Height;
                     selected_texture_size.z = texture_desc.Depth;
                     selected_texture_size.w = texture_desc.MipLevels;
                  }
                  else if (selected_texture_1d)
                  {
                     D3D11_TEXTURE1D_DESC texture_desc;
                     selected_texture_1d->GetDesc(&texture_desc);
                     selected_texture_format = texture_desc.Format;
                     selected_texture_size.x = texture_desc.Width;
                     selected_texture_size.y = texture_desc.ArraySize;
                     selected_texture_size.z = texture_desc.MipLevels;
                  }

                  if (GetFormatName(selected_texture_format) != nullptr)
                  {
                     ImGui::Text("Format: %s", GetFormatName(selected_texture_format));
                  }
                  else
                  {
                     ImGui::Text("Format: %u", selected_texture_format);
                  }

                  ImGui::Text("Size: %ux%ux%ux%u", selected_texture_size.x, selected_texture_size.y, selected_texture_size.z, selected_texture_size.w);

                  const bool is_highlighted_resource = highlighted_resource == hash;
                  if (is_highlighted_resource ? ImGui::Button("Unhighlight Resource") : ImGui::Button("Highlight Resource"))
                  {
                     highlighted_resource = is_highlighted_resource ? "" : hash;
                  }

                  if (debug_draw_resource_enabled ? ImGui::Button("Disable Debug Draw Texture") : ImGui::Button("Debug Draw Texture"))
                  {
                     ASSERT_ONCE(GetShaderDefineCompiledNumericalValue(DEVELOPMENT_HASH) >= 1); // Development flag is needed in shaders for this to output correctly
                     ASSERT_ONCE(device_data.display_composition_pixel_shader); // This shader is necessary to draw this debug stuff

                     if (!debug_draw_resource_enabled)
                     {
                        // Reset all the settings we don't need anymore, as they were for a different debug draw mode
                        debug_draw_pipeline = 0;
                        debug_draw_shader_hash = 0;
                        debug_draw_shader_hash_string[0] = 0;
                        debug_draw_pipeline_target_instance = -1;
                        if (debug_draw_mode == DebugDrawMode::Depth)
                        {
                           debug_draw_options &= ~(uint32_t)DebugDrawTextureOptionsMask::RedOnly;
                        }
                        debug_draw_mode = DebugDrawMode::RenderTarget;
                        debug_draw_view_index = 0;

                        // TODO: fix. As of now this is needed or the texture would be cleared every frame and then set again. We'd need to add a separate (temporary) non clear texture mode for it
                        debug_draw_auto_clear_texture = false;

                        device_data.debug_draw_texture = selected_resource.get();
                        device_data.debug_draw_texture_format = selected_texture_format;
                        device_data.debug_draw_texture_size = selected_texture_size;
                     }
                     else
                     {
                        device_data.debug_draw_texture = nullptr;
                        device_data.debug_draw_texture_format = DXGI_FORMAT_UNKNOWN;
                        device_data.debug_draw_texture_size = {};
                     }
                  }
               }
            }
            ImGui::EndChild(); // TexturesDetails

            ImGui::EndTabItem(); // Upgraded Textures
         }
#endif // !GRAPHICS_ANALYZER
#endif // DEVELOPMENT

         if (ImGui::BeginTabItem("Settings", nullptr, open_settings_tab ? ImGuiTabItemFlags_SetSelected : 0))
         {
            const std::unique_lock lock_reshade(s_mutex_reshade); // Lock the entire scope for extra safety, though we are mainly only interested in keeping "cb_luma_global_settings" safe

#if ENABLE_NGX
            ImGui::BeginDisabled(!device_data.dlss_sr_supported);
            bool optiscaler_detected = GetModuleHandle(TEXT("amd_fidelityfx_dx12.dll")) != NULL; // Make a guess on the presence of FSR DLL, just to inform the user it might be working
            bool fake_dlss_sr_enabled = false; // Force show that DLSS is disabled when it's not supported, to avoid confusion in case the user setting had stayed true
            if (ImGui::Checkbox(optiscaler_detected ? "DLSS/FSR Super Resolution" : "DLSS Super Resolution", device_data.dlss_sr_supported ? &dlss_sr : &fake_dlss_sr_enabled))
            {
               device_data.dlss_sr = dlss_sr;
               if (device_data.dlss_sr) device_data.dlss_sr_suppressed = false;
               reshade::set_config_value(runtime, NAME, "DLSSSuperResolution", dlss_sr);
            }
            if (ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled))
            {
               ImGui::SetTooltip("This replaces the game's native AA and dynamic resolution scaling implementations.\n%sA tick will appear here when it's engaged and a warning will appear if it failed.\n\nRequires compatible Nvidia GPUs (or OptiScaler for FSR).", dlss_game_tooltip);
            }

            ImGui::SameLine();
            if (dlss_sr != true && device_data.dlss_sr_supported)
            {
               ImGui::PushID("DLSS Super Resolution Enabled");
               if (ImGui::SmallButton(ICON_FK_UNDO))
               {
                  dlss_sr = true;
                  device_data.dlss_sr = true;
                  reshade::set_config_value(runtime, NAME, "DLSSSuperResolution", dlss_sr);
               }
               ImGui::PopID();
            }
            else
            {
               // Show that DLSS is engaged. Ignored if the game scene isn't rendering.
               // If DLSS currently can't run due to the user settings/state, or failed, show a warning.
               if (device_data.has_drawn_main_post_processing && device_data.dlss_sr /*&& device_data.cloned_pipeline_count != 0*/)
               {
                  ImGui::PushID("DLSS Super Resolution Active");
                  ImGui::BeginDisabled();
                  ImGui::SmallButton((device_data.taa_detected && device_data.has_drawn_dlss_sr_imgui && !device_data.dlss_sr_suppressed) ? ICON_FK_OK : ICON_FK_WARNING);
                  ImGui::EndDisabled();
                  ImGui::PopID();
               }
               else
               {
                  const auto& style = ImGui::GetStyle();
                  ImVec2 size = ImGui::CalcTextSize(ICON_FK_UNDO);
                  size.x += style.FramePadding.x;
                  size.y += style.FramePadding.y;
                  ImGui::InvisibleButton("", ImVec2(size.x, size.y));
               }
            }
            ImGui::EndDisabled();
#endif

            auto ChangeDisplayMode = [&](int display_mode, bool enable_hdr_on_display = true, IDXGISwapChain3* swapchain = nullptr)
               {
                  reshade::set_config_value(runtime, NAME, "DisplayMode", display_mode);
                  cb_luma_global_settings.DisplayMode = display_mode;
                  OnDisplayModeChanged();
                  if (display_mode >= 1)
                  {
                     if (enable_hdr_on_display)
                     {
                        Display::SetHDREnabled(game_window);
                        bool dummy_bool;
                        Display::IsHDRSupportedAndEnabled(game_window, dummy_bool, hdr_enabled_display, swapchain); // This should always succeed, so we don't fallback to SDR in case it didn't
                     }
                     if (!reshade::get_config_value(runtime, NAME, "ScenePeakWhite", cb_luma_global_settings.ScenePeakWhite) || cb_luma_global_settings.ScenePeakWhite <= 0.f)
                     {
                        cb_luma_global_settings.ScenePeakWhite = device_data.default_user_peak_white;
                     }
                     if (!reshade::get_config_value(runtime, NAME, "ScenePaperWhite", cb_luma_global_settings.ScenePaperWhite))
                     {
                        cb_luma_global_settings.ScenePaperWhite = default_paper_white;
                     }
                     if (!reshade::get_config_value(runtime, NAME, "UIPaperWhite", cb_luma_global_settings.UIPaperWhite))
                     {
                        cb_luma_global_settings.UIPaperWhite = default_paper_white;
                     }
                     // Align all the parameters for the SDR on HDR mode (the game paper white can still be changed)
                     if (display_mode >= 2)
                     {
                        // For now we don't default to 203 nits game paper white when changing to this mode
                        cb_luma_global_settings.UIPaperWhite = cb_luma_global_settings.ScenePaperWhite;
                        cb_luma_global_settings.ScenePeakWhite = cb_luma_global_settings.ScenePaperWhite; // No, we don't want "default_peak_white" here
                     }
                  }
                  else
                  {
                     cb_luma_global_settings.ScenePeakWhite = display_mode == 0 ? srgb_white_level : (display_mode >= 2 ? default_paper_white : default_peak_white);
                     cb_luma_global_settings.ScenePaperWhite = display_mode == 0 ? srgb_white_level : default_paper_white;
                     cb_luma_global_settings.UIPaperWhite = display_mode == 0 ? srgb_white_level : default_paper_white;
                  }
               };

            auto DrawScenePaperWhite = [&](bool has_separate_ui_paper_white = true)
               {
                  static const char* scene_paper_white_name = "Scene Paper White";
                  static const char* paper_white_name = "Paper White";
                  if (ImGui::SliderFloat(has_separate_ui_paper_white ? scene_paper_white_name : paper_white_name, &cb_luma_global_settings.ScenePaperWhite, srgb_white_level, 500.f, "%.f"))
                  {
                     cb_luma_global_settings.ScenePaperWhite = max(cb_luma_global_settings.ScenePaperWhite, 0.0);
                     reshade::set_config_value(runtime, NAME, "ScenePaperWhite", cb_luma_global_settings.ScenePaperWhite);
                  }
                  if (ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled))
                  {
                     ImGui::SetTooltip("The \"average\" brightness of the game scene.\nChange this to your liking, just don't get too close to the peak white.\nHigher does not mean better (especially if you struggle to read UI text), the brighter the image is, the lower the dynamic range (contrast) is.\nThe in game settings brightness is best left at default.");
                  }
                  // Warnings
                  if (cb_luma_global_settings.ScenePaperWhite > cb_luma_global_settings.ScenePeakWhite)
                  {
                     ImGui::SameLine();
                     if (ImGui::SmallButton(ICON_FK_WARNING))
                     {
                        cb_luma_global_settings.ScenePaperWhite = default_paper_white;
                     }
                     if (ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled))
                     {
                        ImGui::SetTooltip("Your Paper White setting is greater than your Peak White setting, the image will either look bad or broken.");
                     }
                  }
                  // Reset button
                  ImGui::SameLine();
                  if (cb_luma_global_settings.ScenePaperWhite != default_paper_white)
                  {
                     ImGui::PushID(has_separate_ui_paper_white ? scene_paper_white_name : paper_white_name);
                     if (ImGui::SmallButton(ICON_FK_UNDO))
                     {
                        cb_luma_global_settings.ScenePaperWhite = default_paper_white;
                        reshade::set_config_value(runtime, NAME, "ScenePaperWhite", cb_luma_global_settings.ScenePaperWhite);
                     }
                     ImGui::PopID();
                  }
                  else
                  {
                     const auto& style = ImGui::GetStyle();
                     ImVec2 size = ImGui::CalcTextSize(ICON_FK_UNDO);
                     size.x += style.FramePadding.x;
                     size.y += style.FramePadding.y;
                     ImGui::InvisibleButton("", ImVec2(size.x, size.y));
                  }
               };

            {
               // Note: this is fast enough that we can check it every frame.
               Display::IsHDRSupportedAndEnabled(game_window, hdr_supported_display, hdr_enabled_display, device_data.GetMainNativeSwapchain().get());
            }

            int display_mode = cb_luma_global_settings.DisplayMode;
            int display_mode_max = 1;
            if (hdr_supported_display)
            {
#if DEVELOPMENT || TEST
               display_mode_max++; // Add "SDR in HDR for HDR" mode
#endif
            }
            const char* preset_strings[3] = {
                "SDR", // SDR (80 nits) on scRGB HDR for SDR (gamma sRGB, because Windows interprets scRGB as sRGB)
                "HDR",
                "SDR on HDR", // (Fake) SDR (baseline to 203 nits) on scRGB HDR for HDR (gamma 2.2) - Dev only, for quick comparisons
            };
            ImGui::BeginDisabled(!hdr_supported_display);
            if (ImGui::SliderInt("Display Mode", &display_mode, 0, display_mode_max, preset_strings[display_mode], ImGuiSliderFlags_NoInput))
            {
               ChangeDisplayMode(display_mode, true, device_data.GetMainNativeSwapchain().get());
            }
            ImGui::EndDisabled();
            if (ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled))
            {
               ImGui::SetTooltip("Display Mode. Greyed out if HDR is not supported.\nThe HDR display calibration (peak white brightness) is retrieved from the OS (Windows 11 HDR user calibration or display EDID),\nonly adjust it if necessary.\nIt's suggested to only play the game in SDR while the display is in SDR mode (with gamma 2.2, not sRGB) (avoid SDR mode in HDR).");
            }
            ImGui::SameLine();
            // Show a reset button to enable HDR in the game if we are playing SDR in HDR
            if ((display_mode == 0 && hdr_enabled_display) || (display_mode >= 1 && !hdr_enabled_display))
            {
               ImGui::PushID("Display Mode");
               if (ImGui::SmallButton(ICON_FK_UNDO))
               {
                  display_mode = hdr_enabled_display ? 1 : 0;
                  ChangeDisplayMode(display_mode, false, device_data.GetMainNativeSwapchain().get());
               }
               ImGui::PopID();
            }
            else
            {
               const auto& style = ImGui::GetStyle();
               ImVec2 size = ImGui::CalcTextSize(ICON_FK_UNDO);
               size.x += style.FramePadding.x;
               size.y += style.FramePadding.y;
               ImGui::InvisibleButton("", ImVec2(size.x, size.y));
            }

            const bool mod_active = device_data.cloned_pipeline_count != 0;
            const bool has_separate_ui_paper_white = GetShaderDefineCompiledNumericalValue(UI_DRAW_TYPE_HASH) >= 1;
            if (display_mode == 1)
            {
               ImGui::BeginDisabled(!mod_active);
               // We should this even if "device_data.cloned_pipeline_count" is 0
               if (ImGui::SliderFloat("Scene Peak White", &cb_luma_global_settings.ScenePeakWhite, 400.0, 10000.f, "%.f"))
               {
                  if (cb_luma_global_settings.ScenePeakWhite == device_data.default_user_peak_white)
                  {
                     reshade::set_config_value(runtime, NAME, "ScenePeakWhite", 0.f); // Store it as 0 to highlight that it's default (whatever the current or next display peak white is)
                  }
                  else
                  {
                     reshade::set_config_value(runtime, NAME, "ScenePeakWhite", cb_luma_global_settings.ScenePeakWhite);
                  }
               }
               if (ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled))
               {
                  ImGui::SetTooltip("Set this to the brightest nits value your display (TV/Monitor) can emit.\nDirectly calibrating in Windows is suggested.");
               }
               ImGui::SameLine();
               if (cb_luma_global_settings.ScenePeakWhite != device_data.default_user_peak_white)
               {
                  ImGui::PushID("Scene Peak White");
                  if (ImGui::SmallButton(ICON_FK_UNDO))
                  {
                     cb_luma_global_settings.ScenePeakWhite = device_data.default_user_peak_white;
                     reshade::set_config_value(runtime, NAME, "ScenePeakWhite", 0.f);
                  }
                  ImGui::PopID();
               }
               else
               {
                  const auto& style = ImGui::GetStyle();
                  ImVec2 size = ImGui::CalcTextSize(ICON_FK_UNDO);
                  size.x += style.FramePadding.x;
                  size.y += style.FramePadding.y;
                  ImGui::InvisibleButton("", ImVec2(size.x, size.y));
               }
               ImGui::EndDisabled();
               DrawScenePaperWhite(has_separate_ui_paper_white && mod_active);
               constexpr bool supports_custom_ui_paper_white_scaling = true; // Currently all "post_process_space_define_index" modes support it (modify the tooltip otherwise)
               if (has_separate_ui_paper_white)
               {
                  ImGui::BeginDisabled(!supports_custom_ui_paper_white_scaling || !mod_active);
                  if (ImGui::SliderFloat("UI Paper White", supports_custom_ui_paper_white_scaling ? &cb_luma_global_settings.UIPaperWhite : &cb_luma_global_settings.ScenePaperWhite, srgb_white_level, 500.f, "%.f"))
                  {
                     cb_luma_global_settings.UIPaperWhite = max(cb_luma_global_settings.UIPaperWhite, 0.0);
                     reshade::set_config_value(runtime, NAME, "UIPaperWhite", cb_luma_global_settings.UIPaperWhite);

                     // This is not safe to do, so let's rely on users manually setting this instead.
                     // Also note that this is a test implementation, it doesn't react to all places that change "cb_luma_global_settings.UIPaperWhite", and does not restore the user original value on exit.
#if 0
                     // This makes the game cursor have the same brightness as the game's UI
                     SetSDRWhiteLevel(game_window, std::clamp(cb_luma_global_settings.UIPaperWhite, 80.f, 480.f));
#endif
                  }
                  if (ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled))
                  {
                     ImGui::SetTooltip("The peak brightness of the User Interface (with the exception of the 2D cursor, which is driven by the Windows SDR White Level).\nHigher does not mean better, change this to your liking.");
                  }
                  ImGui::SameLine();
                  if (cb_luma_global_settings.UIPaperWhite != default_paper_white)
                  {
                     ImGui::PushID("UI Paper White");
                     if (ImGui::SmallButton(ICON_FK_UNDO))
                     {
                        cb_luma_global_settings.UIPaperWhite = default_paper_white;
                        reshade::set_config_value(runtime, NAME, "UIPaperWhite", cb_luma_global_settings.UIPaperWhite);
                     }
                     ImGui::PopID();
                  }
                  else
                  {
                     const auto& style = ImGui::GetStyle();
                     ImVec2 size = ImGui::CalcTextSize(ICON_FK_UNDO);
                     size.x += style.FramePadding.x;
                     size.y += style.FramePadding.y;
                     ImGui::InvisibleButton("", ImVec2(size.x, size.y));
                  }
                  ImGui::EndDisabled();
               }
            }
            else if (display_mode >= 2)
            {
               DrawScenePaperWhite(has_separate_ui_paper_white);
               cb_luma_global_settings.UIPaperWhite = cb_luma_global_settings.ScenePaperWhite;
               cb_luma_global_settings.ScenePeakWhite = cb_luma_global_settings.ScenePaperWhite;
            }

            game->DrawImGuiSettings(device_data);

#if DEVELOPMENT || TEST
            ImGui::SliderInt("Test Index", &test_index, 0, 25);
#endif

#if DEVELOPMENT
            ImGui::SetNextItemOpen(true, ImGuiCond_Once);
            if (ImGui::TreeNode("Developer Settings"))
            {
               static std::string DevSettingsNames[CB::LumaDevSettings::SettingsNum];
               for (size_t i = 0; i < CB::LumaDevSettings::SettingsNum; i++)
               {
                  // These strings need to persist
                  if (DevSettingsNames[i].empty())
                  {
                     DevSettingsNames[i] = "Developer Setting " + std::to_string(i + 1);
                  }
                  float& value = cb_luma_global_settings.DevSettings[i];
                  float& min_value = cb_luma_dev_settings_min_value[i];
                  float& max_value = cb_luma_dev_settings_max_value[i];
                  float& default_value = cb_luma_dev_settings_default_value[i];
                  // Note: this will "fail" if we named two devs settings with the same name!
                  ImGui::SliderFloat(cb_luma_dev_settings_names[i].empty() ? DevSettingsNames[i].c_str() : cb_luma_dev_settings_names[i].c_str(), &value, min_value, max_value);
                  ImGui::SameLine();
                  if (value != default_value)
                  {
                     ImGui::PushID(DevSettingsNames[i].c_str());
                     if (ImGui::SmallButton(ICON_FK_UNDO))
                     {
                        value = default_value;
                     }
                     ImGui::PopID();
                  }
                  else
                  {
                     const auto& style = ImGui::GetStyle();
                     ImVec2 size = ImGui::CalcTextSize(ICON_FK_UNDO);
                     size.x += style.FramePadding.x;
                     size.y += style.FramePadding.y;
                     ImGui::InvisibleButton("", ImVec2(size.x, size.y));
                  }
               }

               ImGui::NewLine();
               ImGui::SliderInt("Tank Performance (Frame Sleep MS)", &frame_sleep_ms, 0, 100);
               ImGui::SliderInt("Tank Performance (Frame Sleep Interval)", &frame_sleep_interval, 1, 30);

               ImGui::NewLine();
               ImGuiInputTextFlags text_flags = ImGuiInputTextFlags_CharsHexadecimal | ImGuiInputTextFlags_CharsNoBlank | ImGuiInputTextFlags_AlwaysOverwrite | ImGuiInputTextFlags_NoUndoRedo;
               if (ImGui::InputTextWithHint("Debug Draw Shader Hash", "12345678", debug_draw_shader_hash_string, HASH_CHARACTERS_LENGTH + 1, text_flags))
               {
                  try
                  {
                     if (strlen(debug_draw_shader_hash_string) != HASH_CHARACTERS_LENGTH)
                     {
                        throw std::invalid_argument("Shader Hash has invalid length");
                     }
                     debug_draw_shader_hash = Shader::Hash_StrToNum(&debug_draw_shader_hash_string[0]);
                  }
                  catch (const std::exception& e)
                  {
                     debug_draw_shader_hash = 0;
                  }
                  // Keep the pipeline ptr if we are simply clearing the hash // TODO: why???
                  if (debug_draw_shader_hash != 0)
                  {
                     debug_draw_pipeline = 0;
                  }

                  device_data.debug_draw_texture = nullptr;
                  device_data.debug_draw_texture_format = DXGI_FORMAT_UNKNOWN;
                  device_data.debug_draw_texture_size = {};
               }
               ImGui::SameLine();
               bool debug_draw_enabled = debug_draw_shader_hash != 0 || debug_draw_pipeline != 0; // It wants to be shown (if it manages!)
               // Show the reset button for both conditions or they could get stuck
               if (debug_draw_enabled)
               {
                  ImGui::PushID("Debug Draw");
                  if (ImGui::SmallButton(ICON_FK_UNDO))
                  {
                     debug_draw_shader_hash_string[0] = 0;
                     debug_draw_shader_hash = 0;
                     debug_draw_pipeline = 0;

                     device_data.debug_draw_texture = nullptr;
                     device_data.debug_draw_texture_format = DXGI_FORMAT_UNKNOWN;
                     device_data.debug_draw_texture_size = {};
                  }
                  ImGui::PopID();
               }
               else
               {
                  const auto& style = ImGui::GetStyle();
                  ImVec2 size = ImGui::CalcTextSize(ICON_FK_UNDO);
                  size.x += style.FramePadding.x;
                  size.y += style.FramePadding.y;
                  ImGui::InvisibleButton("", ImVec2(size.x, size.y));
               }
               if (debug_draw_enabled)
               {
                  auto prev_debug_draw_mode = debug_draw_mode;
                  if (ImGui::SliderInt("Debug Draw Mode", &(int&)debug_draw_mode, 0, IM_ARRAYSIZE(debug_draw_mode_strings) - 1, debug_draw_mode_strings[(size_t)debug_draw_mode], ImGuiSliderFlags_NoInput))
                  {
                     // Make sure to reset it to 0 when we change mode, depth only supports 1 texture etc
                     debug_draw_view_index = 0;
                     // Automatically toggle some settings
                     if (debug_draw_mode == DebugDrawMode::Depth)
                     {
                        debug_draw_options |= (uint32_t)DebugDrawTextureOptionsMask::RedOnly;
                     }
                     else if (prev_debug_draw_mode == DebugDrawMode::Depth)
                     {
                        debug_draw_options &= ~(uint32_t)DebugDrawTextureOptionsMask::RedOnly;
                     }
                  }
                  if (debug_draw_mode == DebugDrawMode::RenderTarget)
                  {
                     ImGui::SliderInt("Debug Draw: Render Target Index", &debug_draw_view_index, 0, D3D11_SIMULTANEOUS_RENDER_TARGET_COUNT - 1);
                  }
                  else if (debug_draw_mode == DebugDrawMode::UnorderedAccessView)
                  {
                     ImGui::SliderInt("Debug Draw: Unordered Access View", &debug_draw_view_index, 0, D3D11_1_UAV_SLOT_COUNT - 1);
                  }
                  else if (debug_draw_mode == DebugDrawMode::ShaderResource)
                  {
                     ImGui::SliderInt("Debug Draw: Pixel Shader Resource Index", &debug_draw_view_index, 0, D3D11_COMMONSHADER_INPUT_RESOURCE_SLOT_COUNT - 1);
                  }
                  ImGui::Checkbox("Debug Draw: Allow Drawing Replaced Pass", &debug_draw_replaced_pass);
                  ImGui::SliderInt("Debug Draw: Pipeline Instance", &debug_draw_pipeline_target_instance, -1, 100); // In case the same pipeline was run more than once by the game, we can pick one to print
                  bool debug_draw_fullscreen = (debug_draw_options & (uint32_t)DebugDrawTextureOptionsMask::Fullscreen) != 0;
                  bool debug_draw_rend_res_scale = (debug_draw_options & (uint32_t)DebugDrawTextureOptionsMask::RenderResolutionScale) != 0;
                  bool debug_draw_red_only = (debug_draw_options & (uint32_t)DebugDrawTextureOptionsMask::RedOnly) != 0;
                  bool debug_draw_show_alpha = (debug_draw_options & (uint32_t)DebugDrawTextureOptionsMask::ShowAlpha) != 0;
                  bool debug_draw_premultiply_alpha = (debug_draw_options & (uint32_t)DebugDrawTextureOptionsMask::PreMultiplyAlpha) != 0;
                  bool debug_draw_invert_colors = (debug_draw_options & (uint32_t)DebugDrawTextureOptionsMask::InvertColors) != 0;
                  bool debug_draw_linear_to_gamma = (debug_draw_options & (uint32_t)DebugDrawTextureOptionsMask::LinearToGamma) != 0;
                  bool debug_draw_gamma_to_linear = (debug_draw_options & (uint32_t)DebugDrawTextureOptionsMask::GammaToLinear) != 0;
                  bool debug_draw_flip_y = (debug_draw_options & (uint32_t)DebugDrawTextureOptionsMask::FlipY) != 0;
                  bool debug_draw_abs = (debug_draw_options & (uint32_t)DebugDrawTextureOptionsMask::Abs) != 0;
                  bool debug_draw_saturate = (debug_draw_options & (uint32_t)DebugDrawTextureOptionsMask::Saturate) != 0;
                  bool debug_draw_background_passthrough = (debug_draw_options & (uint32_t)DebugDrawTextureOptionsMask::BackgroundPassthrough) != 0;
                  bool debug_draw_zoom_4x = (debug_draw_options & (uint32_t)DebugDrawTextureOptionsMask::Zoom4x) != 0;
                  bool debug_draw_bilinear = (debug_draw_options & (uint32_t)DebugDrawTextureOptionsMask::Bilinear) != 0;
                  bool debug_draw_srgb = (debug_draw_options & (uint32_t)DebugDrawTextureOptionsMask::SRGB) != 0;
                  bool debug_draw_tonemap = (debug_draw_options & (uint32_t)DebugDrawTextureOptionsMask::Tonemap) != 0;
                  bool debug_draw_uv_to_pixel_space = (debug_draw_options & (uint32_t)DebugDrawTextureOptionsMask::UVToPixelSpace) != 0;
                  bool debug_draw_denormalize = (debug_draw_options & (uint32_t)DebugDrawTextureOptionsMask::Denormalize) != 0;

                  // TODO: do these in a template function to shorten the code
                  if (ImGui::Checkbox("Debug Draw Options: Fullscreen", &debug_draw_fullscreen))
                  {
                     if (debug_draw_fullscreen)
                     {
                        debug_draw_options |= (uint32_t)DebugDrawTextureOptionsMask::Fullscreen;
                     }
                     else
                     {
                        debug_draw_options &= ~(uint32_t)DebugDrawTextureOptionsMask::Fullscreen;
                     }
                  }
                  if (ImGui::Checkbox("Debug Draw Options: Render Resolution Scale", &debug_draw_rend_res_scale))
                  {
                     if (debug_draw_rend_res_scale)
                     {
                        debug_draw_options |= (uint32_t)DebugDrawTextureOptionsMask::RenderResolutionScale;
                     }
                     else
                     {
                        debug_draw_options &= ~(uint32_t)DebugDrawTextureOptionsMask::RenderResolutionScale;
                     }
                  }
                  if (ImGui::Checkbox("Debug Draw Options: Background Passthrough", &debug_draw_background_passthrough))
                  {
                     if (debug_draw_background_passthrough)
                     {
                        debug_draw_options |= (uint32_t)DebugDrawTextureOptionsMask::BackgroundPassthrough;
                     }
                     else
                     {
                        debug_draw_options &= ~(uint32_t)DebugDrawTextureOptionsMask::BackgroundPassthrough;
                     }
                  }
                  if (ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled))
                  {
                     ImGui::SetTooltip("True: Background passes through the edges\nFalse: forces Black outside of the debugged Texture range");
                  }
                  if (ImGui::Checkbox("Debug Draw Options: Show Alpha", &debug_draw_show_alpha))
                  {
                     if (debug_draw_show_alpha)
                     {
                        debug_draw_options |= (uint32_t)DebugDrawTextureOptionsMask::ShowAlpha;
                     }
                     else
                     {
                        debug_draw_options &= ~(uint32_t)DebugDrawTextureOptionsMask::ShowAlpha;
                     }
                  }
                  ImGui::BeginDisabled(debug_draw_show_alpha); // Alpha takes over red in shaders, so disable red if alpha is on
                  if (ImGui::Checkbox("Debug Draw Options: Red Only", &debug_draw_red_only))
                  {
                     if (debug_draw_red_only)
                     {
                        debug_draw_options |= (uint32_t)DebugDrawTextureOptionsMask::RedOnly;
                     }
                     else
                     {
                        debug_draw_options &= ~(uint32_t)DebugDrawTextureOptionsMask::RedOnly;
                     }
                  }
                  if (ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled))
                  {
                     ImGui::SetTooltip("Shows textures with only one channel (e.g. red, alpha, depth) as grey-scale instead of in red.");
                  }
                  ImGui::EndDisabled();
                  if (ImGui::Checkbox("Debug Draw Options: Premultiply Alpha", &debug_draw_premultiply_alpha))
                  {
                     if (debug_draw_premultiply_alpha)
                     {
                        debug_draw_options |= (uint32_t)DebugDrawTextureOptionsMask::PreMultiplyAlpha;
                     }
                     else
                     {
                        debug_draw_options &= ~(uint32_t)DebugDrawTextureOptionsMask::PreMultiplyAlpha;
                     }
                  }
                  if (ImGui::Checkbox("Debug Draw Options: Invert Colors", &debug_draw_invert_colors))
                  {
                     if (debug_draw_invert_colors)
                     {
                        debug_draw_options |= (uint32_t)DebugDrawTextureOptionsMask::InvertColors;
                     }
                     else
                     {
                        debug_draw_options &= ~(uint32_t)DebugDrawTextureOptionsMask::InvertColors;
                     }
                  }
                  ImGui::Checkbox("Debug Draw Options: Auto Gamma", &debug_draw_auto_gamma);
                  if (!debug_draw_auto_gamma)
                  {
                     // Draw this first as it's much more likely to be needed
                     if (ImGui::Checkbox("Debug Draw Options: Gamma to Linear", &debug_draw_gamma_to_linear))
                     {
                        if (debug_draw_gamma_to_linear)
                        {
                           debug_draw_options |= (uint32_t)DebugDrawTextureOptionsMask::GammaToLinear;
                        }
                        else
                        {
                           debug_draw_options &= ~(uint32_t)DebugDrawTextureOptionsMask::GammaToLinear;
                        }
                     }
                     if (ImGui::Checkbox("Debug Draw Options: Linear to Gamma", &debug_draw_linear_to_gamma))
                     {
                        if (debug_draw_linear_to_gamma)
                        {
                           debug_draw_options |= (uint32_t)DebugDrawTextureOptionsMask::LinearToGamma;
                        }
                        else
                        {
                           debug_draw_options &= ~(uint32_t)DebugDrawTextureOptionsMask::LinearToGamma;
                        }
                     }
                  }
                  ImGui::BeginDisabled((debug_draw_options & ((uint32_t)DebugDrawTextureOptionsMask::LinearToGamma | (uint32_t)DebugDrawTextureOptionsMask::GammaToLinear)) == 0);
                  if (ImGui::Checkbox("Debug Draw Options: sRGB Encode/Decode", &debug_draw_srgb))
                  {
                     if (debug_draw_srgb)
                     {
                        debug_draw_options |= (uint32_t)DebugDrawTextureOptionsMask::SRGB;
                     }
                     else
                     {
                        debug_draw_options &= ~(uint32_t)DebugDrawTextureOptionsMask::SRGB;
                     }
                  }
                  ImGui::EndDisabled();
                  if (ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled))
                  {
                     ImGui::SetTooltip("Force sRGB \"Gamma\" conversions (as opposed to a generic 2.2 power gamma)");
                  }
                  if (ImGui::Checkbox("Debug Draw Options: Flip Y", &debug_draw_flip_y))
                  {
                     if (debug_draw_flip_y)
                     {
                        debug_draw_options |= (uint32_t)DebugDrawTextureOptionsMask::FlipY;
                     }
                     else
                     {
                        debug_draw_options &= ~(uint32_t)DebugDrawTextureOptionsMask::FlipY;
                     }
                  }
                  if (ImGui::Checkbox("Debug Draw Options: Abs", &debug_draw_abs))
                  {
                     if (debug_draw_abs)
                     {
                        debug_draw_options |= (uint32_t)DebugDrawTextureOptionsMask::Abs;
                     }
                     else
                     {
                        debug_draw_options &= ~(uint32_t)DebugDrawTextureOptionsMask::Abs;
                     }
                  }
                  if (ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled))
                  {
                     ImGui::SetTooltip("Useful for Motion Vectors or debugging film grain etc");
                  }
                  if (ImGui::Checkbox("Debug Draw Options: Saturate", &debug_draw_saturate))
                  {
                     if (debug_draw_saturate)
                     {
                        debug_draw_options |= (uint32_t)DebugDrawTextureOptionsMask::Saturate;
                     }
                     else
                     {
                        debug_draw_options &= ~(uint32_t)DebugDrawTextureOptionsMask::Saturate;
                     }
                  }
                  ImGui::BeginDisabled(debug_draw_saturate || !IsFloatFormat(device_data.debug_draw_texture_format));
                  if (debug_draw_saturate || !IsFloatFormat(device_data.debug_draw_texture_format))
                  {
                     debug_draw_tonemap = false; // Make sure to show it as false if it's disabled (though this might be confusing too, as the setting in the restored later)
                  }
                  if (ImGui::Checkbox("Debug Draw Options: Tonemap", &debug_draw_tonemap))
                  {
                     if (debug_draw_tonemap)
                     {
                        debug_draw_options |= (uint32_t)DebugDrawTextureOptionsMask::Tonemap;
                     }
                     else
                     {
                        debug_draw_options &= ~(uint32_t)DebugDrawTextureOptionsMask::Tonemap;
                     }
                  }
                  ImGui::EndDisabled();
                  if (ImGui::Checkbox("Debug Draw Options: UV to Pixel Space", &debug_draw_uv_to_pixel_space))
                  {
                     if (debug_draw_uv_to_pixel_space)
                     {
                        debug_draw_options |= (uint32_t)DebugDrawTextureOptionsMask::UVToPixelSpace;
                     }
                     else
                     {
                        debug_draw_options &= ~(uint32_t)DebugDrawTextureOptionsMask::UVToPixelSpace;
                     }
                  }
                  if (ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled))
                  {
                     ImGui::SetTooltip("Useful for Motion Vectors");
                  }
                  if (ImGui::Checkbox("Debug Draw Options: Denormalize", &debug_draw_denormalize))
                  {
                     if (debug_draw_denormalize)
                     {
                        debug_draw_options |= (uint32_t)DebugDrawTextureOptionsMask::Denormalize;
                     }
                     else
                     {
                        debug_draw_options &= ~(uint32_t)DebugDrawTextureOptionsMask::Denormalize;
                     }
                  }
                  if (ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled))
                  {
                     ImGui::SetTooltip("Converts from 0 to +1 back to -1 to +1, useful for Motion Vectors or other encoded textures");
                  }
                  if (ImGui::Checkbox("Debug Draw Options: Zoom 4x", &debug_draw_zoom_4x))
                  {
                     if (debug_draw_zoom_4x)
                     {
                        debug_draw_options |= (uint32_t)DebugDrawTextureOptionsMask::Zoom4x;
                     }
                     else
                     {
                        debug_draw_options &= ~(uint32_t)DebugDrawTextureOptionsMask::Zoom4x;
                     }
                  }
                  if (ImGui::Checkbox("Debug Draw Options: Bilinear Sampling", &debug_draw_bilinear))
                  {
                     if (debug_draw_bilinear)
                     {
                        debug_draw_options |= (uint32_t)DebugDrawTextureOptionsMask::Bilinear;
                     }
                     else
                     {
                        debug_draw_options &= ~(uint32_t)DebugDrawTextureOptionsMask::Bilinear;
                     }
                  }
                  if (ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled))
                  {
                     ImGui::SetTooltip("Bilinear instead of Nearest Neighbor");
                  }
                  if (device_data.debug_draw_texture || debug_draw_auto_clear_texture)
                  {
                     if (GetFormatName(device_data.debug_draw_texture_format) != nullptr)
                     {
                        ImGui::Text("Debug Draw Info: Texture (View) Format: %s", GetFormatName(device_data.debug_draw_texture_format));
                     }
                     else
                     {
                        ImGui::Text("Debug Draw Info: Texture (View) Format: %u", device_data.debug_draw_texture_format);
                     }
                     ImGui::Text("Debug Draw Info: Texture Size: %ux%ux%ux%u", device_data.debug_draw_texture_size.x, device_data.debug_draw_texture_size.y, device_data.debug_draw_texture_size.z, device_data.debug_draw_texture_size.w);
                  }
                  if (ImGui::Checkbox("Debug Draw: Auto Clear Texture", &debug_draw_auto_clear_texture)) // Is it persistent or not (in case the target texture stopped being found on newer frames). We could also "freeze" it and stop updating it, but we don't need that for now.
                  {
                     device_data.debug_draw_texture_format = DXGI_FORMAT_UNKNOWN;
                     device_data.debug_draw_texture_size = {};
                  }
               }

#if !GAME_GENERIC && !GRAPHICS_ANALYZER // Graphics Analyzer doesn't want upgrades. Generic mod has its own menu.
               ImGui::NewLine();
               // Requires a change in resolution to (~fully) apply (no texture cloning yet)
               if (enable_texture_format_upgrades ? ImGui::Button("Disable Texture Format Upgrades") : ImGui::Button("Enable Texture Format Upgrades"))
               {
                  enable_texture_format_upgrades = !enable_texture_format_upgrades;
               }
               if (enable_swapchain_upgrade ? ImGui::Button("Disable Swapchain Upgrade") : ImGui::Button("Enable Swapchain Upgrade"))
               {
                  enable_swapchain_upgrade = !enable_swapchain_upgrade;
               }
               if (prevent_fullscreen_state ? ImGui::Button("Allow Fullscreen State") : ImGui::Button("Disallow Fullscreen State"))
               {
                  prevent_fullscreen_state = !prevent_fullscreen_state;
               }

               if (ImGui::Button("Attempt Resize Window"))
               {
                  RECT rect;
                  if (GetWindowRect(game_window, &rect))
                  {
                     LONG width = rect.right - rect.left;
                     LONG height = rect.bottom - rect.top;

                     // Decrease the window by 1, to attempt trigger a swapchain resize event (avoids it setting it beyond the screen)
                     LONG new_width = width > 1 ? (width - 1) : (width + 1);
                     LONG new_height = height > 1 ? (height - 1) : (height + 1);

                     SetWindowPos(game_window, nullptr,
                        rect.left, rect.top,
                        new_width, new_height,
                        SWP_NOZORDER | SWP_NOACTIVATE | SWP_NOMOVE);

                     SetWindowPos(game_window, nullptr,
                        rect.left, rect.top,
                        width, height,
                        SWP_NOZORDER | SWP_NOACTIVATE | SWP_NOMOVE);

                  }
               }

               // This will probably hang/crash the game
               if (ImGui::Button("Attempt Resize Swapchain"))
               {
                  // Note: unsafe!
                  auto thread_unc = [&]() {
                     UINT width = UINT(device_data.output_resolution.x + 0.5);
                     UINT height = UINT(device_data.output_resolution.y + 0.5);

                     // Decrease the window by 1, to attempt trigger a swapchain resize event (avoids it setting it beyond the screen)
                     UINT new_width = width > 1 ? (width - 1) : (width + 1);
                     UINT new_height = height > 1 ? (height - 1) : (height + 1);

                     // Replacing the swapchain texture live might crash the game anyway, if it cached ptrs to the swapchain buffers.
                     UINT swap_chain_flags = 0;
                     // We already set these on swapchain creation, so maintain them. Usually there aren't any other (game original) flags to maintain.
                     swap_chain_flags |= DXGI_SWAP_CHAIN_FLAG_ALLOW_TEARING;
                     swap_chain_flags |= DXGI_SWAP_CHAIN_FLAG_ALLOW_MODE_SWITCH;

                     com_ptr<IDXGISwapChain3> native_swapchain;

                     {
                        const std::shared_lock lock(device_data.mutex);

                        native_swapchain = device_data.GetMainNativeSwapchain();

                        SwapchainData& swapchain_data = *(*device_data.swapchains.begin())->get_private_data<SwapchainData>();

                        // Before resizing the swapchain, we need to make sure any of its resources/views are not bound to any state (at least from our side, we can't control the game side here)
                        if (!swapchain_data.display_composition_rtvs.empty())
                        {
                           ID3D11Device* native_device = (ID3D11Device*)(runtime->get_device()->get_native());
                           com_ptr<ID3D11DeviceContext> primary_command_list;
                           native_device->GetImmediateContext(&primary_command_list);
                           com_ptr<ID3D11RenderTargetView> rtvs[D3D11_SIMULTANEOUS_RENDER_TARGET_COUNT];
                           com_ptr<ID3D11DepthStencilView> depth_stencil_view;
                           primary_command_list->OMGetRenderTargets(D3D11_SIMULTANEOUS_RENDER_TARGET_COUNT, &rtvs[0], &depth_stencil_view);
                           bool rts_changed = false;
                           for (size_t i = 0; i < D3D11_SIMULTANEOUS_RENDER_TARGET_COUNT; i++)
                           {
                              for (const auto& display_composition_rtv : swapchain_data.display_composition_rtvs)
                              {
                                 if (rtvs[i].get() != nullptr && rtvs[i].get() == display_composition_rtv.get())
                                 {
                                    rtvs[i] = nullptr;
                                    rts_changed = true;
                                 }
                              }
                           }
                           if (rts_changed)
                           {
                              ID3D11RenderTargetView* const* rtvs_const = (ID3D11RenderTargetView**)std::addressof(rtvs[0]);
                              primary_command_list->OMSetRenderTargets(D3D11_SIMULTANEOUS_RENDER_TARGET_COUNT, rtvs_const, depth_stencil_view.get());
                           }
                        }

                        native_swapchain->ResizeBuffers(0, new_width, new_height, DXGI_FORMAT_UNKNOWN, swap_chain_flags);
                     }

                     native_swapchain->ResizeBuffers(0, width, height, DXGI_FORMAT_UNKNOWN, swap_chain_flags);
                     };


                  std::thread t(thread_unc);
                  // Detach it so it runs independently from within the "Present" call
                  t.detach();
               }

               // TODO: test etc
               ImGui::NewLine();
               // Can be useful to force pause/unpause the game
               if (ImGui::Button("Fake Focus Loss Event"))
               {
#if 1
                  SetForegroundWindow(GetDesktopWindow());
                  SetForegroundWindow(game_window);
                  SetFocus(game_window);
#else // These won't work
                  SendMessage(game_window, WM_KILLFOCUS, (WPARAM)NULL, 0); // Tell the window it lost keyboard focus
                  SendMessage(game_window, WM_ACTIVATE, WA_INACTIVE, (LPARAM)NULL); // Also notify it is inactive
#endif
               }
               if (ImGui::Button("Fake Focus Gain Event"))
               {
                  SendMessage(game_window, WM_SETFOCUS, 0, 0);
                  SendMessage(game_window, WM_ACTIVATE, WA_ACTIVE, 0);
               }

               ImGui::NewLine();
               if (enable_ui_separation ? ImGui::Button("Disable Separate UI Drawing and Composition") : ImGui::Button("Enable Separate UI Drawing and Composition"))
               {
                  enable_ui_separation = !enable_ui_separation;
               }
#endif

               game->DrawImGuiDevSettings(device_data);

#if UPGRADE_SAMPLERS
               ImGui::NewLine();
               bool samplers_changed = ImGui::SliderInt("Texture Samplers Upgrade Mode", &samplers_upgrade_mode, 0, 7);
               samplers_changed |= ImGui::SliderInt("Texture Samplers Upgrade Mode - 2", &samplers_upgrade_mode_2, 0, 6);
               ImGui::Checkbox("Custom Texture Samplers Mip LOD Bias", &custom_texture_mip_lod_bias_offset);
               if (samplers_upgrade_mode > 0 && custom_texture_mip_lod_bias_offset)
               {
                  const std::unique_lock lock_samplers(s_mutex_samplers);
                  samplers_changed |= ImGui::SliderFloat("Texture Samplers Mip LOD Bias", &device_data.texture_mip_lod_bias_offset, -8.f, +8.f);
               }
               if (samplers_changed)
               {
                  const std::unique_lock lock_samplers(s_mutex_samplers);
                  if (samplers_upgrade_mode <= 0)
                  {
                     device_data.custom_sampler_by_original_sampler.clear();
                  }
                  else
                  {
                     for (auto& samplers_handle : device_data.custom_sampler_by_original_sampler)
                     {
                        ID3D11SamplerState* native_sampler = reinterpret_cast<ID3D11SamplerState*>(samplers_handle.first);
                        D3D11_SAMPLER_DESC native_desc;
                        native_sampler->GetDesc(&native_desc);
                        samplers_handle.second[device_data.texture_mip_lod_bias_offset] = CreateCustomSampler(device_data, (ID3D11Device*)runtime->get_device()->get_native(), native_desc);
                     }
                  }
               }
#endif // UPGRADE_SAMPLERS

               ImGui::TreePop();
            }
#endif // DEVELOPMENT

				ImGui::EndTabItem(); // Settings
         }

#if DEVELOPMENT // Use the proper technical name of what this is
         if (ImGui::BeginTabItem("Shader Defines"))
#else // User friendly name (users don't need to understand what shader defines are)
         if (ImGui::BeginTabItem("Advanced Settings"))
#endif
         {
            if (ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled))
            {
               const char* head = auto_recompile_defines ? "" : "Reload shaders after changing these for the changes to apply (and save).\n";
               const char* tail = "Some settings are only editable in debug modes, and only apply if the \"DEVELOPMENT\" flag is turned on.\nDo not change unless you know what you are doing.";
               ImGui::SetTooltip("Shader Defines: %s%s", head, tail);
            }

            const std::unique_lock lock_shader_defines(s_mutex_shader_defines);

            bool shader_defines_changed = false;

            // Show reset button
            {
               bool is_default = true;
               for (uint32_t i = 0; i < shader_defines_data.size() && is_default; i++)
               {
                  is_default = shader_defines_data[i].IsDefault() && !shader_defines_data[i].IsCustom();
               }
               ImGui::BeginDisabled(is_default);
               ImGui::PushID("Advanced Settings: Reset Defines");
               static const std::string reset_button_title = std::string(ICON_FK_UNDO) + std::string(" Reset");
               if (ImGui::Button(reset_button_title.c_str()))
               {
                  // Remove all newly added settings
                  ShaderDefineData::RemoveCustomData(shader_defines_data);

                  // Reset the rest to default
                  ShaderDefineData::Reset(shader_defines_data);

                  shader_defines_changed = true;
               }
               if (ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled))
               {
                  ImGui::SetTooltip("Resets the defines to their default value");
               }
               ImGui::PopID();
               ImGui::EndDisabled();
            }
#if DEVELOPMENT || TEST
            // Show restore button (basically "undo")
            //if (!auto_recompile_defines) // We could do this, but it's better to just always grey it out in that case
            {
               bool needs_compilation = defines_need_recompilation;
               for (uint32_t i = 0; i < shader_defines_data.size() && !needs_compilation; i++)
               {
                  needs_compilation |= shader_defines_data[i].NeedsCompilation();
               }
               ImGui::BeginDisabled(!needs_compilation);
               ImGui::SameLine();
               ImGui::PushID("Advanced Settings: Restore Defines");
               static const std::string restore_button_title = std::string(ICON_FK_UNDO) + std::string(" Restore");
               if (ImGui::Button(restore_button_title.c_str()))
               {
                  ShaderDefineData::Restore(shader_defines_data);
                  shader_defines_changed = true;
               }
               if (ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled))
               {
                  ImGui::SetTooltip("Restores the defines to the last compiled values, undoing any changes that haven't been applied");
               }
               ImGui::PopID();
               ImGui::EndDisabled();
            }
#endif

#if DEVELOPMENT || TEST
            ImGui::BeginDisabled(shader_defines_data.empty() || !shader_defines_data[shader_defines_data.size() - 1].IsCustom());
            ImGui::SameLine();
            ImGui::PushID("Advanced Settings: Remove Define");
            static const std::string remove_button_title = std::string(ICON_FK_MINUS) + std::string(" Remove");
            if (ImGui::Button(remove_button_title.c_str()))
            {
               shader_defines_data.pop_back();
               defines_count--;
               shader_defines_changed = true;
            }
            ImGui::PopID();
            ImGui::EndDisabled();

            ImGui::BeginDisabled(shader_defines_data.size() >= MAX_SHADER_DEFINES);
            ImGui::SameLine();
            ImGui::PushID("Advanced Settings: Add Define");
            static const std::string add_button_title = std::string(ICON_FK_PLUS) + std::string(" Add");
            if (ImGui::Button(add_button_title.c_str()))
            {
               // We don't default the value to 0 here, we leave it blank
               shader_defines_data.emplace_back();
               shader_defines_changed = true; // Probably not necessary in this case but ...
            }
            ImGui::PopID();
            ImGui::EndDisabled();
#endif

#if DEVELOPMENT || TEST // Always true in publishing mode
            // Auto Compile Button
            {
               ImGui::SameLine();
               ImGui::PushID("Advanced Settings: Auto Compile");
               ImGui::Checkbox("Auto Compile", &auto_recompile_defines);
               if (ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled))
               {
                  ImGui::SetTooltip("Automatically re-compile instantly when you change settings, at the possible cost of a small stutter");
               }
               ImGui::PopID();
            }
#endif

#if 0 // We simply add a "*" next to the reload shaders button now instead
            // Show when the defines are "dirty" (shaders need recompile)
            {
               bool needs_compilation = defines_need_recompilation;
               for (uint32_t i = 0; i < shader_defines_data.size() && !needs_compilation; i++)
               {
                  needs_compilation |= shader_defines_data[i].NeedsCompilation();
               }
               if (needs_compilation)
               {
                  ImGui::SameLine();
                  ImGui::PushID("Advanced Settings: Defines Dirty");
                  ImGui::BeginDisabled();
                  ImGui::SmallButton(ICON_FK_REFRESH); // Note: we don't want to modify "needs_load_shaders" here, there's another button for that
                  if (ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled))
                  {
                     ImGui::SetTooltip("Recompile shaders needed to apply the changed settings");
                  }
                  ImGui::EndDisabled();
                  ImGui::PopID();
               }
            }
#endif

            uint8_t longest_shader_define_name_length = 0;
#if 1 // Enables automatic sizing
            for (uint32_t i = 0; i < shader_defines_data.size(); i++)
            {
               longest_shader_define_name_length = max(longest_shader_define_name_length, strlen(shader_defines_data[i].editable_data.GetName()));
            }
            longest_shader_define_name_length += 1; // Add an extra space to avoid it looking too crammed and lagging by one frame
#else
            uint8_t longest_shader_define_name_length = SHADER_DEFINES_MAX_NAME_LENGTH - 1; // Remove the null termination
#endif
            for (uint32_t i = 0; i < shader_defines_data.size(); i++)
            {
               // Don't render empty text fields that couldn't be filled due to them not being editable
               bool disabled = false;
               if (!shader_defines_data[i].IsNameEditable() && !shader_defines_data[i].IsValueEditable())
               {
#if !DEVELOPMENT && !TEST
                  if (shader_defines_data[i].IsCustom())
                  {
                     continue;
                  }
#endif
                  disabled = true;
                  ImGui::BeginDisabled();
               }

               bool show_tooltip = false;

               ImGui::PushID(shader_defines_data[i].name_hint.data());
               ImGuiInputTextFlags flags = ImGuiInputTextFlags_CharsNoBlank;
               if (!shader_defines_data[i].IsNameEditable())
               {
                  flags |= ImGuiInputTextFlags_ReadOnly;
               }
               // All characters should (roughly) have the same length
               ImGui::SetNextItemWidth(ImGui::CalcTextSize("0").x * longest_shader_define_name_length);
               // ImGUI doesn't work with std::string data, it seems to need c style char arrays.
               bool name_edited = ImGui::InputTextWithHint("", shader_defines_data[i].name_hint.data(), shader_defines_data[i].editable_data.GetName(), std::size(shader_defines_data[i].editable_data.name) /*SHADER_DEFINES_MAX_NAME_LENGTH*/, flags);
               show_tooltip |= ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled);
               ImGui::PopID();

               // TODO: fix this, it doesn't seem to work
               auto ModulateValueText = [](ImGuiInputTextCallbackData* data) -> int
                  {
#if 0
                     if (data->EventFlag == ImGuiInputTextFlags_CallbackEdit)
                     {
                        if (data->Buf[0] == '\0')
                        {
                           // SHADER_DEFINES_MAX_VALUE_LENGTH
#if 0 // Better implementation (actually resets to default when the text was cleaned (invalid value)) (space and - can also be currently written to in the value text field)
                           data->Buf[0] = shader_defines_data[i].default_data.value[0];
                           data->Buf[1] = shader_defines_data[i].default_data.value[1];
#else
                           data->Buf[0] == '0';
                           data->Buf[1] == '\0';
#endif
                           data->BufDirty = true;
                        };
                     };
#endif
                     return 0;
                  };

               ImGui::SameLine();
               ImGui::PushID(shader_defines_data[i].value_hint.data());
               flags = ImGuiInputTextFlags_CharsDecimal | ImGuiInputTextFlags_CharsNoBlank | ImGuiInputTextFlags_AlwaysOverwrite | ImGuiInputTextFlags_AutoSelectAll | ImGuiInputTextFlags_NoUndoRedo | ImGuiInputTextFlags_CallbackEdit;
               if (!shader_defines_data[i].IsValueEditable())
               {
                  flags |= ImGuiInputTextFlags_ReadOnly;
               }
               ImGui::SetNextItemWidth(ImGui::CalcTextSize("00").x);
               bool value_edited = ImGui::InputTextWithHint("", shader_defines_data[i].value_hint.data(), shader_defines_data[i].editable_data.GetValue(), std::size(shader_defines_data[i].editable_data.value) /*SHADER_DEFINES_MAX_VALUE_LENGTH*/, flags, ModulateValueText);
               show_tooltip |= ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled);
               // Avoid having empty values unless the default value also was empty. This is a worse implementation of the "ImGuiInputTextFlags_CallbackEdit" above, which we can't get to work.
               // If the value was empty to begin with, we leave it, to avoid confusion.
               if (value_edited && shader_defines_data[i].IsValueEmpty())
               {
                  // SHADER_DEFINES_MAX_VALUE_LENGTH
                  shader_defines_data[i].editable_data.value[0] = shader_defines_data[i].default_data.value[0];
                  shader_defines_data[i].editable_data.value[1] = shader_defines_data[i].default_data.value[1];
#if 0 // This would only appear for 1 frame at the moment
                  if (show_tooltip)
                  {
                     ImGui::SetTooltip(shader_defines_data[i].value_hint.c_str());
                     show_tooltip = false;
                  }
#endif
               }
#if 0 // Disabled for now as this is not very user friendly and could accidentally happen if two defines start with the same name.
               // Reset the define name if it matches another one
               if (name_edited && ShaderDefineData::ContainsName(shader_defines_data, shader_defines_data[i].editable_data.GetName(), i))
               {
                  shader_defines_data[i].Clear();
               }
#endif
               ImGui::PopID();

               if (disabled)
               {
                  ImGui::EndDisabled();
               }

               if (name_edited || value_edited)
               {
                  shader_defines_changed = true;
               }

               if (show_tooltip && shader_defines_data[i].IsNameDefault() && shader_defines_data[i].HasTooltip())
               {
                  ImGui::SetTooltip(shader_defines_data[i].GetTooltip());
               }
            }

            if (shader_defines_changed)
            {
               game->OnShaderDefinesChanged();
            }

            ImGui::EndTabItem();
         }

#if DEVELOPMENT || TEST
         if (ImGui::BeginTabItem("Info"))
         {
            std::string text;

            {
               const std::shared_lock lock(device_data.mutex);

               for (auto back_buffer : device_data.back_buffers)
               {
                  ImGui::Text("Swapchain Format: ", "");

                  reshade::api::resource resource;
                  resource.handle = back_buffer;
                  const reshade::api::resource_desc resource_desc = runtime->get_device()->get_resource_desc(resource);
                  std::ostringstream oss;
                  oss << resource_desc.texture.format;
                  text = oss.str();
                  ImGui::Text(text.c_str(), "");
                  ImGui::NewLine();
               }

#if !GRAPHICS_ANALYZER
               ImGui::Text("Upgraded Textures: ", "");
               text = std::to_string((int)device_data.upgraded_resources.size());
               ImGui::Text(text.c_str(), "");
#endif // !GRAPHICS_ANALYZER
            }

#if !GRAPHICS_ANALYZER
            ImGui::NewLine();
            ImGui::Text("Render Resolution: ", "");
            text = std::to_string((int)device_data.render_resolution.x) + " " + std::to_string((int)device_data.render_resolution.y);
            ImGui::Text(text.c_str(), "");
#endif // !GRAPHICS_ANALYZER

            ImGui::NewLine();
            ImGui::Text("Output Resolution: ", "");
            text = std::to_string((int)device_data.output_resolution.x) + " " + std::to_string((int)device_data.output_resolution.y);
            ImGui::Text(text.c_str(), "");

            if (device_data.dlss_sr)
            {
               ImGui::NewLine();
               ImGui::Text("DLSS Target Resolution Scale: ", "");
               text = std::to_string(device_data.dlss_render_resolution_scale);
               ImGui::Text(text.c_str(), "");
            }

            if (device_data.dlss_sr && device_data.cloned_pipeline_count != 0)
            {
               ImGui::NewLine();
               ImGui::Text("DLSS Scene Pre Exposure: ", "");
               text = std::to_string(device_data.dlss_scene_pre_exposure);
               ImGui::Text(text.c_str(), "");
            }

            game->PrintImGuiInfo(device_data);

            ImGui::EndTabItem(); // Info
         }
#endif // DEVELOPMENT || TEST

         if (ImGui::BeginTabItem("About"))
         {
            game->PrintImGuiAbout();

            ImGui::NewLine();
            static const std::string version = "Version: " + std::to_string(Globals::VERSION);
            ImGui::Text(version.c_str());

            ImGui::EndTabItem(); // About
         }

         ImGui::EndTabBar(); // TabBar
      }
   }
#pragma optimize("", on) // Restore the previous state
} // namespace

void Init(bool async)
{
   has_init = true;

#if ALLOW_SHADERS_DUMPING
   // Add all the shaders we have already dumped to the dumped list to avoid live re-dumping them
   dumped_shaders.clear();
   std::set<std::filesystem::path> dumped_shaders_paths;
   auto dump_path = GetShadersRootPath() / Globals::GAME_NAME / (std::string("Dump") + (sub_game_shaders_appendix.empty() ? "" : " ") + sub_game_shaders_appendix);
   // No need to create the directory here if it didn't already exist
   if (std::filesystem::is_directory(dump_path))
   {
      const std::lock_guard<std::recursive_mutex> lock_dumping(s_mutex_dumping);
      for (const auto& entry : std::filesystem::directory_iterator(dump_path))
      {
         if (!entry.is_regular_file()) continue;
         const auto& entry_path = entry.path();
         if (entry_path.extension() != ".cso") continue;
         const auto& entry_strem_string = entry_path.stem().string();
         if (entry_strem_string.starts_with("0x") && entry_strem_string.length() >= 2 + HASH_CHARACTERS_LENGTH)
         {
            const std::string shader_hash_string = entry_strem_string.substr(2, HASH_CHARACTERS_LENGTH);
            try
            {
               uint32_t shader_hash = Shader::Hash_StrToNum(shader_hash_string);
               bool duplicate = dumped_shaders.contains(shader_hash);
#if DEVELOPMENT
               ASSERT_ONCE(!duplicate); // We have a duplicate shader dumped, cancel here to avoid deleting it
#endif
               if (duplicate)
               {
                  for (const auto& prev_entry_path : dumped_shaders_paths)
                  {
                     if (prev_entry_path.string().contains(shader_hash_string))
                     {
                        // Delete the old version if it's shorter in name (e.g. it might have missed the "ps_5_0" appendix, or simply missing a name we manually appended to it)
                        if (prev_entry_path.string().length() < entry_path.string().length())
                        {
                           if (std::filesystem::remove(prev_entry_path))
                           {
                              duplicate = false;
                              break;
                           }
                        }
                        // Delete the new version
                        else
                        {
                           if (std::filesystem::remove(entry_path))
                           {
                              break;
                           }
                        }
                     }
                  }
               }
               if (!duplicate)
               {
                  dumped_shaders.emplace(shader_hash);
                  dumped_shaders_paths.emplace(entry_path);
               }
            }
            catch (const std::exception& e)
            {
               continue;
            }
         }
      }
   }
#endif // ALLOW_SHADERS_DUMPING

   for (int i = 0; i < shader_defines_data.size(); i++)
   {
      shader_defines_data_index[string_view_crc32(std::string_view(shader_defines_data[i].default_data.GetName()))] = i;
   }

   game->OnInit(async);

   assert(luma_settings_cbuffer_index < D3D11_COMMONSHADER_CONSTANT_BUFFER_API_SLOT_COUNT);
   assert(luma_data_cbuffer_index < D3D11_COMMONSHADER_CONSTANT_BUFFER_API_SLOT_COUNT); // Not necessary for custom shaders unless used, but necessary for the final luma display composition shader (unless we forced that one to use cb0 or something for the buffer)

   cb_luma_global_settings.DisplayMode = 1; // Default to HDR in case we had no prior config, it will be automatically disabled if the current display doesn't support it (when the swapchain is created, which should be guaranteed to be after)
   cb_luma_global_settings.ScenePeakWhite = default_peak_white;
   cb_luma_global_settings.ScenePaperWhite = default_paper_white;
   cb_luma_global_settings.UIPaperWhite = default_paper_white;
   cb_luma_global_settings.DLSS = 0; // We can't set this to 1 until we verified DLSS engaged correctly and is running

   // Load settings
   {
      const std::unique_lock lock_reshade(s_mutex_reshade);

      reshade::api::effect_runtime* runtime = nullptr;
      uint32_t config_version = Globals::VERSION;
      reshade::get_config_value(runtime, NAME, "Version", config_version);
      if (config_version != Globals::VERSION)
      {
         if (config_version < Globals::VERSION)
         {
            const std::unique_lock lock_loading(s_mutex_loading);
            // NOTE: put behaviour to load previous versions into new ones here
            CleanShadersCache(); // Force recompile shaders, just for extra safety (theoretically changes are auto detected through the preprocessor, but we can't be certain). We don't need to change the last config serialized shader defines.
         }
         else if (config_version > Globals::VERSION)
         {
            reshade::log::message(reshade::log::level::warning, "Luma: trying to load a config from a newer version of the mod, loading might have unexpected results");
         }
         reshade::set_config_value(runtime, NAME, "Version", Globals::VERSION);
      }

#if DEVELOPMENT
      std::string shaders_path_str;
      shaders_path_str.resize(256);
      size_t shaders_path_str_size = shaders_path_str.capacity();
      if (reshade::get_config_value(runtime, NAME, "ShadersPath", shaders_path_str.data(), &shaders_path_str_size))
      {
         shaders_path_str.resize(shaders_path_str_size);
         custom_shaders_path = std::filesystem::path(shaders_path_str);
      }
#endif

#if ENABLE_NGX
      reshade::get_config_value(runtime, NAME, "DLSSSuperResolution", dlss_sr);
#endif
      reshade::get_config_value(runtime, NAME, "DisplayMode", cb_luma_global_settings.DisplayMode);
#if !DEVELOPMENT && !TEST // Don't allow "SDR in HDR for HDR" mode (there's no strong reason not to, but it avoids permutations exposed to users)
      if (cb_luma_global_settings.DisplayMode >= 2)
      {
         cb_luma_global_settings.DisplayMode = 0;
      }
#endif

      // If we read an invalid value from the config, reset it
      if (reshade::get_config_value(runtime, NAME, "ScenePeakWhite", cb_luma_global_settings.ScenePeakWhite) && cb_luma_global_settings.ScenePeakWhite <= 0.f)
      {
         const std::shared_lock lock(s_mutex_device); // This is not completely safe as the write to "default_user_peak_white" isn't protected by this mutex but it's fine, it shouldn't have been written yet when we get here
         cb_luma_global_settings.ScenePeakWhite = global_devices_data.empty() ? default_peak_white : global_devices_data[0]->default_user_peak_white;
      }
      reshade::get_config_value(runtime, NAME, "ScenePaperWhite", cb_luma_global_settings.ScenePaperWhite);
      reshade::get_config_value(runtime, NAME, "UIPaperWhite", cb_luma_global_settings.UIPaperWhite);
      if (cb_luma_global_settings.DisplayMode == 0)
      {
         cb_luma_global_settings.ScenePeakWhite = srgb_white_level;
         cb_luma_global_settings.ScenePaperWhite = srgb_white_level;
         cb_luma_global_settings.UIPaperWhite = srgb_white_level;
      }
      else if (cb_luma_global_settings.DisplayMode >= 2)
      {
         cb_luma_global_settings.UIPaperWhite = cb_luma_global_settings.ScenePaperWhite;
         cb_luma_global_settings.ScenePeakWhite = cb_luma_global_settings.ScenePaperWhite;
      }

      const std::unique_lock lock_shader_defines(s_mutex_shader_defines);
      ShaderDefineData::Load(shader_defines_data, NAME_ADVANCED_SETTINGS, runtime);

      game->LoadConfigs();

      OnDisplayModeChanged();

      game->OnShaderDefinesChanged();
   }

   {
      // Assume that the shader defines loaded from config match the ones the current pre-compiled shaders have (or, simply use the defaults otherwise)
      const std::unique_lock lock_shader_defines(s_mutex_shader_defines);
      ShaderDefineData::OnCompilation(shader_defines_data);
      shader_defines_data_index.clear();
      for (uint32_t i = 0; i < shader_defines_data.size(); i++)
      {
         shader_defines_data_index[string_view_crc32(std::string_view(shader_defines_data[i].compiled_data.GetName()))] = i;
      }
   }

   // Pre-load all shaders to minimize the wait before replacing them after they are found in game ("auto_load"),
   // and to fill the list of shaders we customized, so we can know which ones we need replace on the spot.
   if (async && precompile_custom_shaders)
   {
      thread_auto_compiling_running = true;
      static std::binary_semaphore async_shader_compilation_semaphore{ 0 };
      thread_auto_compiling = std::thread([]
         {
            // We need to lock this mutex for the whole async shader loading, so that if the game starts loading shaders (from another thread), we can already see if we have a custom version and live load it ("live_load"), otherwise the "custom_shaders_cache" list would be incomplete
            const std::unique_lock lock_loading(s_mutex_loading);
            // This is needed to make sure this thread locks "s_mutex_loading" before any other function could
            async_shader_compilation_semaphore.release();
            CompileCustomShaders(nullptr, true);
            const std::shared_lock lock_device(s_mutex_device);
            // Create custom device shaders if the device has already been created before custom shaders were loaded on boot, independently of "block_draw_until_device_custom_shaders_creation".
            // Note that this might be unsafe if "global_devices_data" was already being destroyed in "OnDestroyDevice()" (I'm not sure you can create device resources anymore at that point).
            for (auto global_device_data : global_devices_data)
            {
               const std::unique_lock lock_shader_objects(s_mutex_shader_objects);
               if (!global_device_data->created_custom_shaders)
               {
                  CreateCustomDeviceShaders(*global_device_data, std::nullopt, false);
               }
            }
            thread_auto_compiling_running = false;
         });
      async_shader_compilation_semaphore.acquire();
   }
}

// This can't be called on "DLL_PROCESS_DETACH" as it needs a multi threaded enviroment
void Uninit()
{
   if (thread_auto_dumping.joinable())
   {
      thread_auto_dumping.join();
   }
   if (thread_auto_compiling.joinable())
   {
      thread_auto_compiling.join();
   }
   {
      const std::shared_lock lock(s_mutex_device);
      for (auto global_device_data : global_devices_data)
      {
         if (global_device_data->thread_auto_loading.joinable())
         {
            global_device_data->thread_auto_loading.join();
         }
      }
   }

   has_init = false;
}

#ifndef RESHADE_EXTERNS
// This is called immediately after the main function ("DllMain") gets "DLL_PROCESS_ATTACH" if this dll/addon is loaded directly by ReShade
extern "C" __declspec(dllexport) bool AddonInit(HMODULE addon_module, HMODULE reshade_module)
{
   Init(true);
   return true;
}
extern "C" __declspec(dllexport) void AddonUninit(HMODULE addon_module, HMODULE reshade_module)
{
   Uninit();
}
#endif

// This is a static library so this "main" function won't ever be automatically called, it needs to be manually hooked.
BOOL APIENTRY CoreMain(HMODULE h_module, DWORD fdw_reason, LPVOID lpv_reserved)
{
   switch (fdw_reason)
   {
   // Note: this dll should support being loaded more than once (included being unloaded in the middle of execution).
   // ReShade loads addons when the game creates a DirectX device, this usually only happens once on boot under normal circumstances (e.g. Prey), but can happen multiple times (e.g. Dishonored 2, Unity games, ...).
   case DLL_PROCESS_ATTACH:
   {
// Some games like to crash or have input issues if a debugger is present on boot, so make it optional
#if (DEVELOPMENT || _DEBUG) && !defined(DISABLE_AUTO_DEBUGGER)
      LaunchDebugger(NAME);
#endif // DEVELOPMENT

      wchar_t file_path_char[MAX_PATH] = L"";
      GetModuleFileNameW(h_module, file_path_char, ARRAYSIZE(file_path_char));
      std::filesystem::path file_path = file_path_char;
      if (file_path.extension() == ".addon" || file_path.extension() == ".addon64")
      {
         asi_loaded = false;
      }
      else
      {
         // Just to make sure, if we got loaded then it's probably fine either way
         assert(file_path.extension() == ".dll" || file_path.extension() == ".asi");
      }

      bool load_failed = false;

#if !DISABLE_RESHADE
      // Register the ReShade addon.
      // We simply cancel everything else if reshade is not present or failed to register,
      // we could still load the native plugin,
      const bool reshade_addon_register_succeeded = reshade::register_addon(h_module);
      if (!reshade_addon_register_succeeded) load_failed = true;
#endif // !DISABLE_RESHADE

      // We give the game code the opportunity to do something before rejecting the dll load
      game->OnLoad(file_path, load_failed);

#if DISABLE_RESHADE
      if (!asi_loaded) return FALSE;
#endif // DISABLE_RESHADE

      if (load_failed)
      {
         return FALSE;
      }

#if DISABLE_RESHADE
      if (asi_loaded) return TRUE;
#endif // DISABLE_RESHADE

      reshade::register_event<reshade::addon_event::create_device>(OnCreateDevice);
      reshade::register_event<reshade::addon_event::init_device>(OnInitDevice);
      reshade::register_event<reshade::addon_event::destroy_device>(OnDestroyDevice);
      reshade::register_event<reshade::addon_event::create_swapchain>(OnCreateSwapchain);
      reshade::register_event<reshade::addon_event::init_swapchain>(OnInitSwapchain);
      reshade::register_event<reshade::addon_event::destroy_swapchain>(OnDestroySwapchain);
      reshade::register_event<reshade::addon_event::set_fullscreen_state>(OnSetFullscreenState);

      reshade::register_event<reshade::addon_event::init_pipeline>(OnInitPipeline);
      reshade::register_event<reshade::addon_event::destroy_pipeline>(OnDestroyPipeline);

      reshade::register_event<reshade::addon_event::bind_pipeline>(OnBindPipeline);

      reshade::register_event<reshade::addon_event::init_command_list>(OnInitCommandList);
      reshade::register_event<reshade::addon_event::destroy_command_list>(OnDestroyCommandList);

      if (enable_texture_format_upgrades)
      {
         reshade::register_event<reshade::addon_event::init_resource>(OnInitResource);
         reshade::register_event<reshade::addon_event::create_resource>(OnCreateResource);
         reshade::register_event<reshade::addon_event::destroy_resource>(OnDestroyResource);
      }
#if DEVELOPMENT
      else
      {
         reshade::register_event<reshade::addon_event::destroy_resource>(OnDestroyResource);
      }
#endif
      if (enable_texture_format_upgrades || enable_swapchain_upgrade)
      {
         reshade::register_event<reshade::addon_event::create_resource_view>(OnCreateResourceView);
#if DEVELOPMENT
         reshade::register_event<reshade::addon_event::init_resource_view>(OnInitResourceView);
         reshade::register_event<reshade::addon_event::destroy_resource_view>(OnDestroyResourceView);
#endif
      }

      reshade::register_event<reshade::addon_event::push_descriptors>(OnPushDescriptors);
#if DEVELOPMENT
      reshade::register_event<reshade::addon_event::map_buffer_region>(OnMapBufferRegion);
      reshade::register_event<reshade::addon_event::map_texture_region>(OnMapTextureRegion);
      reshade::register_event<reshade::addon_event::update_buffer_region>(OnUpdateBufferRegion);
      reshade::register_event<reshade::addon_event::update_texture_region>(OnUpdateTextureRegion);
      reshade::register_event<reshade::addon_event::clear_render_target_view>(OnClearRenderTargetView);
      reshade::register_event<reshade::addon_event::clear_unordered_access_view_uint>(OnClearUnorderedAccessViewUInt);
      reshade::register_event<reshade::addon_event::clear_unordered_access_view_float>(OnClearUnorderedAccessViewFloat);
#endif // DEVELOPMENT
      reshade::register_event<reshade::addon_event::copy_resource>(OnCopyResource);
      reshade::register_event<reshade::addon_event::copy_texture_region>(OnCopyTextureRegion);
      reshade::register_event<reshade::addon_event::resolve_texture_region>(OnResolveTextureRegion);

      reshade::register_event<reshade::addon_event::draw>(OnDraw);
      reshade::register_event<reshade::addon_event::dispatch>(OnDispatch);
      reshade::register_event<reshade::addon_event::draw_indexed>(OnDrawIndexed);
      reshade::register_event<reshade::addon_event::draw_or_dispatch_indirect>(OnDrawOrDispatchIndirect);

#if UPGRADE_SAMPLERS
      reshade::register_event<reshade::addon_event::init_sampler>(OnInitSampler);
      reshade::register_event<reshade::addon_event::destroy_sampler>(OnDestroySampler);
#endif

#if DEVELOPMENT
      reshade::register_event<reshade::addon_event::execute_command_list>(OnExecuteCommandList);
      reshade::register_event<reshade::addon_event::execute_secondary_command_list>(OnExecuteSecondaryCommandList);
#endif // DEVELOPMENT

      reshade::register_event<reshade::addon_event::present>(OnPresent);

      reshade::register_event<reshade::addon_event::reshade_present>(OnReShadePresent);

#if DEVELOPMENT || TEST // Currently Dev only as we don't need the average user to compare the mod on/off
      reshade::register_event<reshade::addon_event::reshade_set_effects_state>(OnReShadeSetEffectsState);
      reshade::register_event<reshade::addon_event::reshade_reloaded_effects>(OnReShadeReloadedEffects);
#endif // DEVELOPMENT

      reshade::register_overlay(NAME, OnRegisterOverlay);

      break;
   }
   case DLL_PROCESS_DETACH:
   {
#if DEVELOPMENT
      if (game_window_original_proc && game_window != NULL && IsWindow(game_window))
      {
         SetWindowLongPtr(game_window, GWLP_WNDPROC, reinterpret_cast<LONG_PTR>(game_window_original_proc));
         game_window_original_proc = nullptr;
      }
      if (game_window_proc_hook)
      {
         UnhookWindowsHookEx(game_window_proc_hook);
         game_window_proc_hook = nullptr;
      }
#endif

      // Automatically destroy this if it was instanced by a game implementation
      if (game != &default_game)
      {
         delete game;
         game = nullptr;
      }

      reshade::unregister_event<reshade::addon_event::create_device>(OnCreateDevice);
      reshade::unregister_event<reshade::addon_event::init_device>(OnInitDevice);
      reshade::unregister_event<reshade::addon_event::destroy_device>(OnDestroyDevice);
      reshade::unregister_event<reshade::addon_event::create_swapchain>(OnCreateSwapchain);
      reshade::unregister_event<reshade::addon_event::init_swapchain>(OnInitSwapchain);
      reshade::unregister_event<reshade::addon_event::destroy_swapchain>(OnDestroySwapchain);
      reshade::unregister_event<reshade::addon_event::set_fullscreen_state>(OnSetFullscreenState);

      reshade::unregister_event<reshade::addon_event::init_pipeline>(OnInitPipeline);
      reshade::unregister_event<reshade::addon_event::destroy_pipeline>(OnDestroyPipeline);

      reshade::unregister_event<reshade::addon_event::bind_pipeline>(OnBindPipeline);

      reshade::unregister_event<reshade::addon_event::init_command_list>(OnInitCommandList);
      reshade::unregister_event<reshade::addon_event::destroy_command_list>(OnDestroyCommandList);

      if (enable_texture_format_upgrades)
      {
         reshade::unregister_event<reshade::addon_event::init_resource>(OnInitResource);
         reshade::unregister_event<reshade::addon_event::create_resource>(OnCreateResource);
         reshade::unregister_event<reshade::addon_event::destroy_resource>(OnDestroyResource);
      }
#if DEVELOPMENT
      else
      {
         reshade::unregister_event<reshade::addon_event::destroy_resource>(OnDestroyResource);
      }
#endif
      if (enable_texture_format_upgrades || enable_swapchain_upgrade)
      {
         reshade::unregister_event<reshade::addon_event::create_resource_view>(OnCreateResourceView);
#if DEVELOPMENT
         reshade::unregister_event<reshade::addon_event::init_resource_view>(OnInitResourceView);
         reshade::unregister_event<reshade::addon_event::destroy_resource_view>(OnDestroyResourceView);
#endif
      }

      reshade::unregister_event<reshade::addon_event::push_descriptors>(OnPushDescriptors);
#if DEVELOPMENT
      reshade::unregister_event<reshade::addon_event::map_buffer_region>(OnMapBufferRegion);
      reshade::unregister_event<reshade::addon_event::map_texture_region>(OnMapTextureRegion);
      reshade::unregister_event<reshade::addon_event::update_buffer_region>(OnUpdateBufferRegion);
      reshade::unregister_event<reshade::addon_event::update_texture_region>(OnUpdateTextureRegion);
      reshade::unregister_event<reshade::addon_event::clear_render_target_view>(OnClearRenderTargetView);
      reshade::unregister_event<reshade::addon_event::clear_unordered_access_view_uint>(OnClearUnorderedAccessViewUInt);
      reshade::unregister_event<reshade::addon_event::clear_unordered_access_view_float>(OnClearUnorderedAccessViewFloat);
#endif // DEVELOPMENT
      reshade::unregister_event<reshade::addon_event::copy_resource>(OnCopyResource);
      reshade::unregister_event<reshade::addon_event::copy_texture_region>(OnCopyTextureRegion);
      reshade::unregister_event<reshade::addon_event::resolve_texture_region>(OnResolveTextureRegion);

      reshade::unregister_event<reshade::addon_event::draw>(OnDraw);
      reshade::unregister_event<reshade::addon_event::dispatch>(OnDispatch);
      reshade::unregister_event<reshade::addon_event::draw_indexed>(OnDrawIndexed);
      reshade::unregister_event<reshade::addon_event::draw_or_dispatch_indirect>(OnDrawOrDispatchIndirect);

#if UPGRADE_SAMPLERS
      reshade::unregister_event<reshade::addon_event::init_sampler>(OnInitSampler);
      reshade::unregister_event<reshade::addon_event::destroy_sampler>(OnDestroySampler);
#endif

#if DEVELOPMENT
      reshade::unregister_event<reshade::addon_event::execute_command_list>(OnExecuteCommandList);
      reshade::unregister_event<reshade::addon_event::execute_secondary_command_list>(OnExecuteSecondaryCommandList);
#endif // DEVELOPMENT

      reshade::unregister_event<reshade::addon_event::present>(OnPresent);

      reshade::unregister_event<reshade::addon_event::reshade_present>(OnReShadePresent);

#if DEVELOPMENT || TEST
      reshade::unregister_event<reshade::addon_event::reshade_set_effects_state>(OnReShadeSetEffectsState);
      reshade::unregister_event<reshade::addon_event::reshade_reloaded_effects>(OnReShadeReloadedEffects);
#endif // DEVELOPMENT

      reshade::unregister_overlay(NAME, OnRegisterOverlay);

      reshade::unregister_addon(h_module);

      // In case our threads are still not joined, detach them and safely do a busy loop
      // until they finished running, so we don't risk them reading/writing to stale memory.
      // This could cause a bit of wait, especially if we just booted the game and shaders are still compiling,
      // but there's no nice and clear alternatively really.
      // This is needed because DLL loading/unloading is completely single threaded and isn't
      // able to join threads (though "thread.detach()" somehow seems to work).
      // Note that there's no need to call "Uninit()" here, independently on whether we are asi or ReShade loaded.
      if (thread_auto_dumping.joinable())
      {
         thread_auto_dumping.detach();
         while (thread_auto_dumping_running) {}
      }
      if (thread_auto_compiling.joinable())
      {
         thread_auto_compiling.detach();
         while (thread_auto_compiling_running) {}
      }
      // We can't lock "s_mutex_device" here, but we also know that if this ptr is valid, then there's no other thread able to run now and change it.
      // ReShade is unloaded when the last device is destroyed so we should have already received an event to clear this thread anyway.
      for (auto global_device_data : global_devices_data)
      {
         if (global_device_data->thread_auto_loading.joinable())
         {
            global_device_data->thread_auto_loading.detach();
            while (global_device_data->thread_auto_loading_running) {}
         }
      }

      break;
   }
   }

   return TRUE;
}