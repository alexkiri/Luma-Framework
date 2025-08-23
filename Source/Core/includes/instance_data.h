#pragma once

// Forward declarations
struct GameDeviceData;

struct TraceDrawCallData
{
   TraceDrawCallData()
   {
      thread_id = std::this_thread::get_id();
   }

   enum class TraceDrawCallType
   {
      // Any type of shader (including compute)
      Shader,
      // Copy resource and similar function
      CopyResource,
      ClearResource,
      BindPipeline,
      BindResource,
      CPURead,
      CPUWrite,
      Present,
      AppendCommandList,
      FlushCommandList,
		Custom, // Custom draw call for custom passes we added/replaced
   };

   TraceDrawCallType type = TraceDrawCallType::Shader;

#if 1 // For now add a new "TraceDrawCallData" per shader (e.g. one for vertex and one for pixel, instead of doing it per draw call), this is due to legacy code that would require too much refactor
   uint64_t pipeline_handle = 0;
#else
   uint64_t pipeline_handles = 0; // The actual list of pipelines that run within the traced frame (within this deferred command list, and then merged into the immediate one later)
   ShaderHashesList shader_hashes;
#endif

   // The original command list (can be useful to have later)
   com_ptr<ID3D11DeviceContext> command_list = nullptr;
   // The thread this call was made on (usually 1:1 with deferred (async) command lists)
   std::thread::id thread_id = {};

   // Depth/Stencil
   enum class DepthStateType
   {
      Disabled,
      TestAndWrite,
      TestOnly,
      WriteOnly,
      Custom,
      Invalid,
   };
   static constexpr const char* depth_state_names[] = { "Disabled", "Test and Write", "Test Only", "Write Only", "Custom" };

   DepthStateType depth_state = DepthStateType::Disabled;
   bool stencil_enabled = false;
   bool scissors = false;
   float4 viewport_0 = {};
   // Already includes all the render targets
   D3D11_BLEND_DESC blend_desc = {};

   // Render Target (Resource+Views)
   const ID3D11RenderTargetView* rtvs[D3D11_SIMULTANEOUS_RENDER_TARGET_COUNT] = {}; // TODO.. find a better way, this is very hacky (though safe, as long as we read/compare it)
   DXGI_FORMAT rt_format[D3D11_SIMULTANEOUS_RENDER_TARGET_COUNT] = {}; // The format of the resource
   DXGI_FORMAT rtv_format[D3D11_SIMULTANEOUS_RENDER_TARGET_COUNT] = {}; // The format of the view
   uint4 rt_size[D3D11_SIMULTANEOUS_RENDER_TARGET_COUNT] = {}; // 3th and 4th channels are Array, MS and Mips
   std::string rt_type_name[D3D11_SIMULTANEOUS_RENDER_TARGET_COUNT] = {};
   std::string rt_hash[D3D11_SIMULTANEOUS_RENDER_TARGET_COUNT] = {};
   bool rt_is_swapchain[D3D11_SIMULTANEOUS_RENDER_TARGET_COUNT] = {};
   // Shader Resource (Resource+Views)
   const ID3D11ShaderResourceView* srvs[D3D11_COMMONSHADER_INPUT_RESOURCE_SLOT_COUNT] = {};
   DXGI_FORMAT srv_format[D3D11_COMMONSHADER_INPUT_RESOURCE_SLOT_COUNT] = {}; // The format of the view
   DXGI_FORMAT sr_format[D3D11_COMMONSHADER_INPUT_RESOURCE_SLOT_COUNT] = {}; // The format of the resource
   uint4 sr_size[D3D11_COMMONSHADER_INPUT_RESOURCE_SLOT_COUNT] = {}; // 3th and 4th channels are Array, MS and Mips
   std::string sr_type_name[D3D11_COMMONSHADER_INPUT_RESOURCE_SLOT_COUNT] = {};
   std::string sr_hash[D3D11_COMMONSHADER_INPUT_RESOURCE_SLOT_COUNT] = {};
   bool sr_is_rt[D3D11_COMMONSHADER_INPUT_RESOURCE_SLOT_COUNT] = {};
   bool sr_is_ua[D3D11_COMMONSHADER_INPUT_RESOURCE_SLOT_COUNT] = {};
   // Unordered Access (Resource+Views)
   const ID3D11UnorderedAccessView* uavs[D3D11_COMMONSHADER_INPUT_RESOURCE_SLOT_COUNT] = {};
   DXGI_FORMAT ua_format[D3D11_1_UAV_SLOT_COUNT] = {}; // The format of the resource
   DXGI_FORMAT uav_format[D3D11_1_UAV_SLOT_COUNT] = {}; // The format of the view
   uint4 ua_size[D3D11_1_UAV_SLOT_COUNT] = {}; // 3th and 4th channels are Array, MS and Mips
   std::string ua_type_name[D3D11_1_UAV_SLOT_COUNT] = {};
   std::string ua_hash[D3D11_1_UAV_SLOT_COUNT] = {};
   bool ua_is_rt[D3D11_COMMONSHADER_INPUT_RESOURCE_SLOT_COUNT] = {};
   // Depth Stencil (Resource+View)
   DXGI_FORMAT ds_format = {}; // The format of the resource
   DXGI_FORMAT dsv_format = {}; // The format of the view
   uint2 ds_size = {};
   std::string ds_hash = {};

   bool IsRTVValid(size_t index) const { return rtv_format[index] != DXGI_FORMAT_UNKNOWN && rtv_format[index] != DXGI_FORMAT(-1); }
   bool IsSRVValid(size_t index) const { return srv_format[index] != DXGI_FORMAT_UNKNOWN && srv_format[index] != DXGI_FORMAT(-1); }
   bool IsUAVValid(size_t index) const { return uav_format[index] != DXGI_FORMAT_UNKNOWN && uav_format[index] != DXGI_FORMAT(-1); }
   bool IsDSVValid() const { return dsv_format != DXGI_FORMAT_UNKNOWN && dsv_format != DXGI_FORMAT(-1); }

   const char* custom_name = "Unknown";
};

// Applies to command lists and command queque (DirectX 11 command list and deferred or immediate contexts)
struct __declspec(uuid("90d9d05b-fdf5-44ee-8650-3bfd0810667a")) CommandListData
{
   bool is_primary = false; // Immediate/Primary (as opposed to Async/Secondary/Deferred)

   CB::LumaInstanceDataPadded cb_luma_instance_data = {};
   // Always start from dirty given that deferred command lists inherit the cbuffers data from the immediate ones, but we don't know when they will get joined, so we always need to assume the data was dirty and needs to be re-set from scratch
   bool force_cb_luma_instance_data_dirty = true;

   reshade::api::pipeline pipeline_state_original_compute_shader = reshade::api::pipeline(0);
   reshade::api::pipeline pipeline_state_original_vertex_shader = reshade::api::pipeline(0);
   reshade::api::pipeline pipeline_state_original_pixel_shader = reshade::api::pipeline(0);

   Shader::ShaderHashesList<OneShaderPerPipeline> pipeline_state_original_graphics_shader_hashes;
   Shader::ShaderHashesList<OneShaderPerPipeline> pipeline_state_original_compute_shader_hashes;
   bool pipeline_state_has_custom_vertex_shader = false;
   bool pipeline_state_has_custom_pixel_shader = false;
   bool pipeline_state_has_custom_graphics_shader = false;
   bool pipeline_state_has_custom_compute_shader = false;

#if DEVELOPMENT
   std::shared_mutex mutex_trace;
   std::vector<TraceDrawCallData> trace_draw_calls_data;

   bool any_draw_done = false;
   bool any_dispatch_done = false;
#endif
};

struct __declspec(uuid("cfebf6d4-d184-4e1a-ac14-09d088e560ca")) DeviceData
{
   // Only for "swapchains", "back_buffers" and "upgraded_resources" (and related)
   std::shared_mutex mutex;

   std::thread thread_auto_loading;
   std::atomic<bool> thread_auto_loading_running = false;

   std::unordered_set<uint64_t> upgraded_resources; // All the upgraded resources, excluding the swapchains backbuffers, as they are created internally by DX
#if DEVELOPMENT
   std::unordered_map<uint64_t, reshade::api::format> original_upgraded_resources_formats; // These include the swapchain buffers too!
   std::unordered_map<uint64_t, std::pair<uint64_t, reshade::api::format>> original_upgraded_resource_views_formats; // All the views for upgraded resources, with the resource and the original resource view format
#endif

   std::unordered_set<reshade::api::swapchain*> swapchains;
   std::unordered_set<uint64_t> back_buffers; // From all the swapchains
   ID3D11Device* native_device = nullptr; // Doesn't need mutex, always valid given it's a ptr to itself
   com_ptr<ID3D11DeviceContext> primary_command_list; // The immediate/primary command list is always valid
   CommandListData* primary_command_list_data = nullptr; // The immediate/primary command list is always valid

   UINT uav_max_count = D3D11_1_UAV_SLOT_COUNT; // DX11.1. Use "D3D11_PS_CS_UAV_REGISTER_COUNT" for DX11.

   com_ptr<IDXGISwapChain3> GetMainNativeSwapchain() const
   {
      ASSERT_ONCE(swapchains.size() == 1);
      if (swapchains.empty()) return nullptr;
      IDXGISwapChain* native_swapchain = (IDXGISwapChain*)((*swapchains.begin())->get_native());
      com_ptr<IDXGISwapChain3> native_swapchain3;
      // The cast pointer is actually the same, we are just making sure the type is right.
      HRESULT hr = native_swapchain->QueryInterface(&native_swapchain3);
      ASSERT_ONCE(SUCCEEDED(hr));
      return native_swapchain3;
   }

   // Pipelines by handle. Multiple pipelines can target the same shader, and even have multiple shaders within themselves.
   // This contains all pipelines (from the game) that we can replace shaders of (e.g. pixel shaders, vertex shaders, ...).
   std::unordered_map<uint64_t, Shader::CachedPipeline*> pipeline_cache_by_pipeline_handle;
   // Same as "pipeline_cache_by_pipeline_handle" but for cloned (custom) pipelines.
   std::unordered_map<uint64_t, Shader::CachedPipeline*> pipeline_cache_by_pipeline_clone_handle;
   // All the pipelines linked to a shader. By shader hash.
   std::unordered_map<uint32_t, std::unordered_set<Shader::CachedPipeline*>> pipeline_caches_by_shader_hash;

   std::unordered_set<uint64_t> pipelines_to_reload;
   static_assert(sizeof(reshade::api::pipeline::handle) == sizeof(uint64_t));
   // Map of "reshade::api::pipeline::handle"
   std::unordered_map<uint64_t, reshade::api::device*> pipelines_to_destroy;

   // Custom samplers mapped to original ones by texture LOD bias
   std::unordered_map<uint64_t, std::unordered_map<float, com_ptr<ID3D11SamplerState>>> custom_sampler_by_original_sampler;

   bool dlss_sr = true; // If true DLSS is enabled by the user and supported+initialized correctly on this device
#if ENABLE_NGX
   NGX::DLSSInstanceData* dlss_sr_handle = nullptr;
#endif // ENABLE_NGX

   // Resources:

#if ENABLE_NGX
   // DLSS SR
   com_ptr<ID3D11Texture2D> dlss_output_color;
   com_ptr<ID3D11Texture2D> dlss_exposure;
   float dlss_exposure_texture_value = 1.f;
#endif // ENABLE_NGX

   // Custom Shaders
   bool created_custom_shaders = false;
   com_ptr<ID3D11Texture2D> temp_copy_source_texture;
   com_ptr<ID3D11Texture2D> temp_copy_target_texture;
   com_ptr<ID3D11Texture2D> display_composition_texture;
   com_ptr<ID3D11ShaderResourceView> display_composition_srv;
   com_ptr<ID3D11VertexShader> copy_vertex_shader;
   com_ptr<ID3D11PixelShader> copy_pixel_shader;
   com_ptr<ID3D11PixelShader> display_composition_pixel_shader;
   com_ptr<ID3D11PixelShader> draw_purple_pixel_shader;
   com_ptr<ID3D11ComputeShader> draw_purple_compute_shader;
   com_ptr<ID3D11ComputeShader> normalize_lut_3d_compute_shader;

   // CBuffers
   com_ptr<ID3D11Buffer> luma_global_settings;
   com_ptr<ID3D11Buffer> luma_instance_data;
   com_ptr<ID3D11Buffer> luma_ui_data;
   CB::LumaUIDataPadded cb_luma_ui_data = {};
   bool cb_luma_global_settings_dirty = true;

   // UI
   com_ptr<ID3D11Texture2D> ui_texture;
   com_ptr<ID3D11RenderTargetView> ui_texture_rtv;
   com_ptr<ID3D11ShaderResourceView> ui_texture_srv;

   // Misc
   com_ptr<ID3D11SamplerState> default_sampler_state;
   com_ptr<ID3D11BlendState> default_blend_state;
   com_ptr<ID3D11DepthStencilState> default_depth_stencil_state;

   // Pointer to the current DX buffer for the "global per view" cbuffer.
   com_ptr<ID3D11Buffer> cb_per_view_global_buffer;
#if DEVELOPMENT
   std::unordered_set<ID3D11Buffer*> cb_per_view_global_buffers;
#endif
   void* cb_per_view_global_buffer_map_data = nullptr;
#if DEVELOPMENT
   com_ptr<ID3D11Resource> debug_draw_texture;
   DXGI_FORMAT debug_draw_texture_format = DXGI_FORMAT_UNKNOWN; // The view format, not the texture format
   uint4 debug_draw_texture_size = {}; // 3rd and 4th channels are Array/MS/Mips

   struct TrackBufferData
   {
      std::string hash; // Resource ptr hash
      std::vector<float> data;
   };
   TrackBufferData track_buffer_data;
#endif

   // Generic states that can be used by multiple games (you don't need to set them if you ignore the whole thing)

   // Whether the "main" post processing passes have finished drawing (it also implied we detected scene rendering and some cbuffers etc)
   std::atomic<bool> has_drawn_main_post_processing = false;
   // Useful to know if rendering was skipped in the previous frame (e.g. in case we were in a UI view)
   bool has_drawn_main_post_processing_previous = false;
   std::atomic<bool> has_drawn_dlss_sr = false;
   // Set to true once we can tell with certainty that TAA was active in the game
   std::atomic<bool> taa_detected = false;

   std::atomic<bool> force_reset_dlss_sr = false;
   std::atomic<float> dlss_render_resolution_scale = 1.f;
   std::atomic<bool> dlss_sr_suppressed = false;

   float2 render_resolution = { 1, 1 };
   float2 previous_render_resolution = { 1, 1 };
   // Note: this is the "display"/swapchain res
   float2 output_resolution = { 1, 1 };

   // Live settings (set by the code, not directly by users):
   float default_user_peak_white = default_peak_white;
   bool dlss_sr_supported = false;
   float texture_mip_lod_bias_offset = 0.f;
   float dlss_scene_exposure = 1.f;
   float dlss_scene_pre_exposure = 1.f;

   std::atomic<bool> cloned_pipelines_changed = false; // Atomic so it doesn't rely on "s_mutex_generic"
   uint32_t cloned_pipeline_count = 0; // How many pipelines (shaders/passes) we replaced with custom ones and are currently "replaced" (if zero, we can assume the mod isn't doing much)

   bool has_drawn_dlss_sr_imgui = false;

   // Per game custom data
   GameDeviceData* game = nullptr;
};

struct __declspec(uuid("c5805458-2c02-4ebf-b139-38b85118d971")) SwapchainData
{
   std::shared_mutex mutex;

   std::unordered_set<uint64_t> back_buffers;

   std::vector<com_ptr<ID3D11RenderTargetView>> display_composition_rtvs;

   // Whether the original SDR (vanilla) swapchain was linear space (e.g. sRGB formats)
	bool vanilla_was_linear_space = false;
};