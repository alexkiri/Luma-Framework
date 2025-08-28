#define GAME_FINALFANTASYXV 1

#define UPGRADE_SAMPLERS 0
#define GEOMETRY_SHADER_SUPPORT 0
#define ALLOW_SHADERS_DUMPING 0
#define ENABLE_NGX 1

#include "..\..\Core\core.hpp"
#include "..\..\Core\includes\math.h"
#include "..\..\Core\includes\matrix.h"
#include "..\..\Core\dlss\DLSS.cpp"

namespace
{
    float2 projection_jitters = { 0, 0 };
	//const uint32_t shader_hash_mvec_pixel = std::stoul("FFFFFFF3", nullptr, 16);
    ShaderHashesList shader_hashes_tonemap;
    ShaderHashesList shader_hashes_TAA;
}

struct GameDeviceDataFFXV final : public GameDeviceData
{
#if ENABLE_NGX
    // DLSS SR
    com_ptr<ID3D11Resource> dlss_motion_vectors;
    com_ptr<ID3D11Resource> dlss_source_color;
    com_ptr<ID3D11Resource> depth_buffer;
    com_ptr<ID3D11RenderTargetView> dlss_motion_vectors_rtv;
#endif // ENABLE_NGX
    std::atomic<bool> has_drawn_upscaling = false;
    //com_ptr<ID3D11PixelShader> motion_vectors_ps;
};

class FinalFantasyXV final : public Game // ### Rename this to your game's name ###
{
    static GameDeviceDataFFXV& GetGameDeviceData(DeviceData& device_data)
    {
        return *static_cast<GameDeviceDataFFXV*>(device_data.game);
    }
public:
   void OnInit(bool async) override
   {
       GetShaderDefineData(POST_PROCESS_SPACE_TYPE_HASH).SetDefaultValue('1');
       GetShaderDefineData(EARLY_DISPLAY_ENCODING_HASH).SetDefaultValue('0');
       GetShaderDefineData(VANILLA_ENCODING_TYPE_HASH).SetDefaultValue('0');
       GetShaderDefineData(GAMMA_CORRECTION_TYPE_HASH).SetDefaultValue('0');
       GetShaderDefineData(UI_DRAW_TYPE_HASH).SetDefaultValue('0');
      luma_settings_cbuffer_index = 13;
      luma_data_cbuffer_index = 12; // #w## Update this (find the right value) ###
   }

   bool OnDrawCustom(ID3D11Device* native_device, ID3D11DeviceContext* native_device_context, CommandListData& cmd_list_data, DeviceData& device_data, reshade::api::shader_stage stages, const ShaderHashesList<OneShaderPerPipeline>& original_shader_hashes, bool is_custom_pass, bool& updated_cbuffers) override
   {
	   auto& game_device_data = GetGameDeviceData(device_data);

	   const bool had_drawn_upscaling = game_device_data.has_drawn_upscaling;
	   if (!game_device_data.has_drawn_upscaling && device_data.dlss_sr && !device_data.dlss_sr_suppressed && original_shader_hashes.Contains(shader_hashes_TAA))
	   {	
		   
		   game_device_data.has_drawn_upscaling = true;
		   // 1 depth [3]
		   // 2 current color source () = [0]
		   // 3 previous color source (previous frame) = [1]
		   // 4 motion vectors [6]
		   com_ptr<ID3D11ShaderResourceView> ps_shader_resources[16];
		   native_device_context->PSGetShaderResources(0, ARRAYSIZE(ps_shader_resources), reinterpret_cast<ID3D11ShaderResourceView**>(ps_shader_resources));

		   com_ptr<ID3D11RenderTargetView> render_target_views[D3D11_SIMULTANEOUS_RENDER_TARGET_COUNT];
		   com_ptr<ID3D11DepthStencilView> depth_stencil_view;
		   native_device_context->OMGetRenderTargets(D3D11_SIMULTANEOUS_RENDER_TARGET_COUNT, &render_target_views[0], &depth_stencil_view);
		   const bool dlss_inputs_valid = ps_shader_resources[0].get() != nullptr && ps_shader_resources[5].get() != nullptr && ps_shader_resources[6].get() != nullptr && render_target_views[0] != nullptr;
		   ASSERT_ONCE(dlss_inputs_valid);

           if (dlss_inputs_valid) {

               com_ptr<ID3D11Resource> output_colorTemp;
               render_target_views[0]->GetResource(&output_colorTemp);
               com_ptr<ID3D11Texture2D> output_color;
               HRESULT hr = output_colorTemp->QueryInterface(&output_color);
               ASSERT_ONCE(SUCCEEDED(hr));
               D3D11_TEXTURE2D_DESC output_texture_desc;
               output_color->GetDesc(&output_texture_desc);

               //ASSERT_ONCE(std::lrintf(device_data.output_resolution.x) == output_texture_desc.Width && std::lrintf(device_data.output_resolution.y) == output_texture_desc.Height);
               std::array<uint32_t, 2> dlss_render_resolution = FindClosestIntegerResolutionForAspectRatio((double)output_texture_desc.Width * (double)device_data.dlss_render_resolution_scale, (double)output_texture_desc.Height * (double)device_data.dlss_render_resolution_scale, (double)output_texture_desc.Width / (double)output_texture_desc.Height);
               bool dlss_hdr = true;
   //            
               // Test DLSS
               com_ptr<ID3D11VertexShader> vs;
               com_ptr<ID3D11PixelShader> ps;
               native_device_context->VSGetShader(&vs, nullptr, 0);
               native_device_context->PSGetShader(&ps, nullptr, 0);
               // end Test Dlss

               NGX::DLSS::UpdateSettings(device_data.dlss_sr_handle, native_device_context, output_texture_desc.Width, output_texture_desc.Height, dlss_render_resolution[0], dlss_render_resolution[1], dlss_hdr, false); //TODO: figure out dsr later
               
               // Test DLSS
               com_ptr<ID3D11ShaderResourceView> ps_shader_resources_post[ARRAYSIZE(ps_shader_resources)];
               native_device_context->PSGetShaderResources(0, ARRAYSIZE(ps_shader_resources_post), reinterpret_cast<ID3D11ShaderResourceView**>(ps_shader_resources_post));
               for (uint32_t i = 0; i < ARRAYSIZE(ps_shader_resources); i++)
               {
                   ASSERT_ONCE(ps_shader_resources[i] == ps_shader_resources_post[i]);
               }

               com_ptr<ID3D11RenderTargetView> render_target_view_post;
               com_ptr<ID3D11DepthStencilView> depth_stencil_view_post;
               native_device_context->OMGetRenderTargets(1, &render_target_view_post, &depth_stencil_view_post);
               ASSERT_ONCE(render_target_views[0] == render_target_view_post && depth_stencil_view == depth_stencil_view_post);

               com_ptr<ID3D11VertexShader> vs_post;
               com_ptr<ID3D11PixelShader> ps_post;
               native_device_context->VSGetShader(&vs_post, nullptr, 0);
               native_device_context->PSGetShader(&ps_post, nullptr, 0);
               ASSERT_ONCE(vs == vs_post && ps == ps_post);
               vs = nullptr;
               ps = nullptr;
               vs_post = nullptr;
               ps_post = nullptr;

               // end Test Dlss

               bool skip_dlss = output_texture_desc.Width < 32 || output_texture_desc.Height < 32; // DLSS desn't support output below 32x32
               bool dlss_output_changed = false;
               constexpr bool dlss_use_native_uav = true;

               //reshade::log::message(reshade::log::level::info, ("DLSS initialization successful"));

               bool dlss_output_supports_uav = dlss_use_native_uav && (output_texture_desc.BindFlags & D3D11_BIND_UNORDERED_ACCESS) != 0;
               if (!dlss_output_supports_uav) {

                   output_texture_desc.BindFlags |= D3D11_BIND_UNORDERED_ACCESS;

                   if (device_data.dlss_output_color.get())
                   {
                       D3D11_TEXTURE2D_DESC dlss_output_texture_desc;
                       device_data.dlss_output_color->GetDesc(&dlss_output_texture_desc);
                       dlss_output_changed = dlss_output_texture_desc.Width != output_texture_desc.Width || dlss_output_texture_desc.Height != output_texture_desc.Height || dlss_output_texture_desc.Format != output_texture_desc.Format;
                   }
                   if (!device_data.dlss_output_color.get() || dlss_output_changed)
                   {
                       device_data.dlss_output_color = nullptr; // Make sure we discard the previous one
                       hr = native_device->CreateTexture2D(&output_texture_desc, nullptr, &device_data.dlss_output_color);
                       ASSERT_ONCE(SUCCEEDED(hr));
                   }
                   if (!device_data.dlss_output_color.get())
                   {
                       skip_dlss = true;
                   }
               }
               else
               {
                   device_data.dlss_output_color = output_color;
               }

               if (!skip_dlss)
               {
                   game_device_data.dlss_source_color = nullptr;
                   ps_shader_resources[0]->GetResource(&game_device_data.dlss_source_color);
                   game_device_data.depth_buffer = nullptr;
                   ps_shader_resources[3]->GetResource(&game_device_data.depth_buffer);
                   game_device_data.dlss_motion_vectors = nullptr;
                   ps_shader_resources[6]->GetResource(&game_device_data.dlss_motion_vectors);

                   reshade::log::message(reshade::log::level::info, ("Loading DLSS inputs successfully"));

                   // Extract jitter from constant buffer 0
                   {
                       ID3D11Buffer* cb0_buffer = nullptr;
                       native_device_context->PSGetConstantBuffers(0, 1, &cb0_buffer); // slot 0 = b0

                       if (cb0_buffer)
                       {
                           D3D11_BUFFER_DESC cb0_desc = {};
                           cb0_buffer->GetDesc(&cb0_desc);

                           ID3D11Buffer* staging_cb0 = cb0_buffer;
                           com_ptr<ID3D11Buffer> staging_cb0_buf;
                           if (cb0_desc.Usage != D3D11_USAGE_STAGING || !(cb0_desc.CPUAccessFlags & D3D11_CPU_ACCESS_READ))
                           {
                               cb0_desc.Usage = D3D11_USAGE_STAGING;
                               cb0_desc.BindFlags = 0;
                               cb0_desc.CPUAccessFlags = D3D11_CPU_ACCESS_READ;
                               cb0_desc.MiscFlags = 0;
                               cb0_desc.StructureByteStride = 0;
                               HRESULT hr_staging = native_device->CreateBuffer(&cb0_desc, nullptr, &staging_cb0_buf);
                               if (SUCCEEDED(hr_staging))
                               {
                                   native_device_context->CopyResource(staging_cb0_buf.get(), cb0_buffer);
                                   staging_cb0 = staging_cb0_buf.get();
                                   D3D11_MAPPED_SUBRESOURCE mapped_cb0 = {};
                                   if (SUCCEEDED(native_device_context->Map(staging_cb0, 0, D3D11_MAP_READ, 0, &mapped_cb0)))
                                   {
                                       // cb0 is float4[140], so each element is 16 bytes
                                       const float* cb0_floats = reinterpret_cast<const float*>(mapped_cb0.pData);
                                       //float4 g_screenSize : packoffset(c0);
                                       //float4 g_frameBits : packoffset(c1);
                                       //float4 g_uvJitterOffset : packoffset(c2);
                                       float jitter_x = cb0_floats[8];
                                       float jitter_y = cb0_floats[9];
                                       if (jitter_x != 0 || jitter_y != 0)
                                       {
                                           projection_jitters.x = jitter_x;
                                           projection_jitters.y = jitter_y;
                                       }
                                       native_device_context->Unmap(staging_cb0, 0);
                                       staging_cb0->Release();
                                       cb0_buffer->Release();
                                   }
                               }
                               else
                               {
                                   cb0_buffer->Release();
                               }
                           }
                       }
                   }
                   reshade::log::message(reshade::log::level::info, ("Loading DLSS  successfully"));
                   reshade::log::message(
                       reshade::log::level::info,
                       ("Jitter X: " + std::to_string(projection_jitters.x) +
                           ", Jitter Y: " + std::to_string(projection_jitters.y)).c_str()
                   );

                   bool reset_dlss = false;
                   uint32_t render_width_dlss = std::lrintf(device_data.render_resolution.x);
                   uint32_t render_height_dlss = std::lrintf(device_data.render_resolution.y);
                   float dlss_pre_exposure = 0.f;
                   bool dlss_succeeded = NGX::DLSS::Draw(device_data.dlss_sr_handle, native_device_context, device_data.dlss_output_color.get(), game_device_data.dlss_source_color.get(), game_device_data.dlss_motion_vectors.get(), game_device_data.depth_buffer.get(), nullptr, dlss_pre_exposure, projection_jitters.x, projection_jitters.y, reset_dlss, render_width_dlss, render_height_dlss);

                   reshade::log::message(
                       reshade::log::level::info,
                       (std::string("DLSS succeeded: ") + (dlss_succeeded ? "true" : "false")).c_str()
                   );

                   if (dlss_succeeded)
                   {
                       device_data.has_drawn_dlss_sr = true;
                   }

                   game_device_data.dlss_motion_vectors_rtv = nullptr;
                   game_device_data.dlss_motion_vectors = nullptr;
                   game_device_data.dlss_source_color = nullptr;
                   game_device_data.depth_buffer = nullptr;

                   ID3D11RenderTargetView* const* rtvs_const = (ID3D11RenderTargetView**)std::addressof(render_target_views[0]);
                   native_device_context->OMSetRenderTargets(D3D11_SIMULTANEOUS_RENDER_TARGET_COUNT, rtvs_const, depth_stencil_view.get());

                   if (device_data.has_drawn_dlss_sr)
                   {
                       if (!dlss_output_supports_uav)
                       {
                           native_device_context->CopyResource(output_color.get(), device_data.dlss_output_color.get()); // DX11 doesn't need barriers
                       }
                       else
                       {
                           device_data.dlss_output_color = nullptr;
                       }

                       reshade::log::message(
                           reshade::log::level::info,
                           "Skipping the TAA draw call ..."
                       );

                       return true;
                   }
                   else
                   {
                       //ASSERT_ONCE(false);
                       //cb_luma_frame_settings.DLSS = 0;
                       //device_data.cb_luma_frame_settings_dirty = true;
                       //device_data.dlss_sr_suppressed = true;
                       device_data.force_reset_dlss_sr = true;
                   }

               }
               if (dlss_output_supports_uav)
               {
                   device_data.dlss_output_color = nullptr;
               }


           }
		   

	   }
	   return false; // Don't cancel the original draw call

   }

   void OnCreateDevice(ID3D11Device* native_device, DeviceData& device_data) override
   {
       device_data.game = new GameDeviceDataFFXV;
   }

   void OnPresent(ID3D11Device* native_device, DeviceData& device_data) override
   {
       auto& game_device_data = GetGameDeviceData(device_data);

       game_device_data.has_drawn_upscaling = false;
   }

   void PrintImGuiAbout() override
   {
      ImGui::Text("FFXV Luma mod - about and credits section", ""); // ### Rename this ###
   }

   void CreateShaderObjects(DeviceData& device_data, const std::optional<std::set<std::string>>& shader_names_filter) override
   {
       auto& game_device_data = GetGameDeviceData(device_data);
       //CreateShaderObject(device_data.native_device, shader_hash_mvec_pixel, game_device_data.motion_vectors_ps, shader_hashes_filter);
   }
};

BOOL APIENTRY DllMain(HMODULE hModule, DWORD ul_reason_for_call, LPVOID lpReserved)
{
   if (ul_reason_for_call == DLL_PROCESS_ATTACH)
   {
      Globals::SetGlobals(PROJECT_NAME, "Final Fantasy XV Luma Edition");
      Globals::VERSION = 1;

      shader_hashes_tonemap.pixel_shaders.emplace(std::stoul("75DFE4B0", nullptr, 16)); // Main game tonemapping
      shader_hashes_tonemap.pixel_shaders.emplace(std::stoul("18EF8C72", nullptr, 16)); // Title screen tonemapping
      shader_hashes_tonemap.pixel_shaders.emplace(std::stoul("DD4C5B74", nullptr, 16)); // Post-processing / swapchain

      // TODO: intercept this
      shader_hashes_TAA.pixel_shaders.emplace(std::stoul("0DF0A97D", nullptr, 16));

      enable_swapchain_upgrade = true; // We don't need swapchain upgrade for this game
      swapchain_upgrade_type = 1;  // 1 = scrgb
      
      enable_texture_format_upgrades = true;

      std::vector<ShaderDefineData> game_shader_defines_data = {
         {"TONEMAP_TYPE", '1', false, false, "0 - Vanilla SDR\n1 - Luma HDR (Vanilla+)\n2 - Raw HDR (Untonemapped)\nThe HDR tonemapper works for SDR too\nThis games uses a filmic tonemapper, which slightly crushes blacks"},
      };

      shader_defines_data.append_range(game_shader_defines_data);
      assert(shader_defines_data.size() < MAX_SHADER_DEFINES);
      
      // ### Check which of these are needed and remove the rest ###
      texture_upgrade_formats = {
            reshade::api::format::r8g8b8a8_unorm,
            //reshade::api::format::r8g8b8a8_unorm_srgb,
            //reshade::api::format::r8g8b8a8_typeless,
            //reshade::api::format::r8g8b8x8_unorm,
            //reshade::api::format::r8g8b8x8_unorm_srgb,
            reshade::api::format::b8g8r8a8_unorm,
            //reshade::api::format::b8g8r8a8_unorm_srgb,
            //reshade::api::format::b8g8r8a8_typeless,
            //reshade::api::format::b8g8r8x8_unorm,
            //reshade::api::format::b8g8r8x8_unorm_srgb,
            //reshade::api::format::b8g8r8x8_typeless,

            reshade::api::format::r11g11b10_float,
            reshade::api::format::r10g10b10a2_typeless,
            reshade::api::format::r10g10b10a2_unorm,
            //reshade::api::format::r16g16_float,
            //reshade::api::format::r16g16_unorm,
            //reshade::api::format::r32_g8_typeless
      };
      // ### Check these if textures are not upgraded ###
      texture_format_upgrades_2d_size_filters = 0 | (uint32_t)TextureFormatUpgrades2DSizeFilters::SwapchainResolution | (uint32_t)TextureFormatUpgrades2DSizeFilters::SwapchainAspectRatio;

      game = new FinalFantasyXV();
   }

   CoreMain(hModule, ul_reason_for_call, lpReserved);

   return TRUE;
}