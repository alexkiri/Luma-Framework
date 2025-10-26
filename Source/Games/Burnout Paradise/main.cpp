#define GAME_BURNOUT_PARADISE 1

#define ENABLE_ORIGINAL_SHADERS_MEMORY_EDITS 1

#include "..\..\Core\core.hpp"

#include "..\..\Core\includes\shader_patching.h"

namespace
{
   bool hdr_car_reflections = true;

   bool ps2_style_motion_blur = true;

   constexpr bool smooth_motion_blur_parameters = true; // Mirrored in shaders

   ShaderHashesList pixel_shader_hashes_Sky;
   ShaderHashesList pixel_shader_hashes_DownscaleDepth;
   ShaderHashesList pixel_shader_hashes_LinearizeDepth;
   ShaderHashesList pixel_shader_hashes_SunOcclusionTest;
   ShaderHashesList shader_hashes_Tonemap_MotionBlur;
}


struct GameDeviceDataBurnoutParadise final : public GameDeviceData
{
   bool is_drawing_transparency = false;
   bool has_drawn_transparency = false;
   bool has_drawn_motion_blur = false;
   bool had_drawn_sun_occlusion_test = false;
   bool has_drawn_sun_occlusion_test = false;

   com_ptr<ID3D11ShaderResourceView> half_res_depth_srv;

   com_ptr<ID3D11BlendState> sun_occlusion_test_blend_state;

   struct BlendDescCompare
   {
      bool operator()(const D3D11_BLEND_DESC& a, const D3D11_BLEND_DESC& b) const
      {
         return memcmp(&a, &b, sizeof(D3D11_BLEND_DESC)) < 0;
      }
   };
   std::map<D3D11_BLEND_DESC, com_ptr<ID3D11BlendState>, BlendDescCompare> custom_blend_states;

   com_ptr<ID3D11Buffer> motion_blur_ps_cb;
   com_ptr<ID3D11Buffer> motion_blur_vs_cb;
   com_ptr<ID3D11Buffer> motion_blur_ps_cb_copy;
   com_ptr<ID3D11Buffer> motion_blur_vs_cb_copy;
};

class BurnoutParadise final : public Game
{
public:
   static GameDeviceDataBurnoutParadise& GetGameDeviceData(DeviceData& device_data)
   {
      return *static_cast<GameDeviceDataBurnoutParadise*>(device_data.game);
   }
   static const GameDeviceDataBurnoutParadise& GetGameDeviceData(const DeviceData& device_data)
   {
      return *static_cast<const GameDeviceDataBurnoutParadise*>(device_data.game);
   }

   void OnInit(bool async) override
   {
      luma_settings_cbuffer_index = 13;
      luma_data_cbuffer_index = 12;
      
      std::vector<ShaderDefineData> game_shader_defines_data = {
         {"ENABLE_IMPROVED_MOTION_BLUR", '1', true, false, "Increase the quality of the game's motion blur in multiple ways", 1},
         {"ENABLE_IMPROVED_BLOOM", '1', true, false, "Increase the quality of the game's motion blur, and makes it more \"HDR\"", 1},
         {"ENABLE_VIGNETTE", '1', true, false, "Allows disabling the game's vignette. This will also disable the blue/yellow filter and increase the brightness of the whole image", 1},
         {"REMOVE_BLACK_BARS", '0', true, false, "Removes ugly black bars from Ultrawide, given that often menus and game were both pillarboxed and letterboxed at the same time.\nThis will also reveal some bad menus backgrounds", 1},
         {"LUT_SAMPLING_ERROR_EMULATION_MODE", '0', true, false,
            "Burnout Paradise had a bug in the color grading shader that accidentally boosted contrast and clipped both shadow and highlight."
            "\nLuma fixes that, and a consequence, shadow a slightly raised, however they seem to be more accurate like that, especially in HDR."
            "\nIf you want to preserve the original crushed shadow level, enable this",
            3},
         {"SMOOTH_MOTION_BLUR", '1', true, false, "Smooths over motion blur as it was a bit jittery. Turn off if you prefer instant respensiveness", 1},
         {"FORWARDS_ONLY_MOTION_BLUR", '0', true, false, "Enable this to turn off motion blur from camera rotation, but only allow it from forward/backward camera movement", 1},
         {"REDUCE_HORIZONTAL_MOTION_BLUR", '1', true, false, "When using PS2 style botion blur, the horizontal motion blur from camera rotation might be too intense,\nby default, this reduces it", 1},
         {"MOTION_BLUR_IMPROVE_STENCIL_FILTER", '1', true, false, "Avoids motion blur leaking around cars", 1},
         {"MOTION_BLUR_BLUR_DISTANT_CARS", '1', true, false, "By default Luma applies motion blur to distant cars, turn off to restore the vanilla behaviour where all cars were ignored, independently of the distance", 1},
      };

      shader_defines_data.append_range(game_shader_defines_data);

      GetShaderDefineData(TEST_SDR_HDR_SPLIT_VIEW_MODE_NATIVE_IMPL_HASH).SetDefaultValue('1');

      // No gamma mismatch baked in the textures as the game never applied gamma, it was gamma from the beginning to the end.
      GetShaderDefineData(GAMMA_CORRECTION_TYPE_HASH).SetDefaultValue('1');
      GetShaderDefineData(VANILLA_ENCODING_TYPE_HASH).SetDefaultValue('1');

      GetShaderDefineData(UI_DRAW_TYPE_HASH).SetDefaultValue('2');
   }

   void OnCreateDevice(ID3D11Device* native_device, DeviceData& device_data) override
   {
      device_data.game = new GameDeviceDataBurnoutParadise;
      auto& game_device_data = GetGameDeviceData(device_data);

      D3D11_BLEND_DESC blend_desc = {};
      blend_desc.RenderTarget[0].BlendEnable = TRUE;
      blend_desc.RenderTarget[0].RenderTargetWriteMask = D3D11_COLOR_WRITE_ENABLE_RED;
      blend_desc.RenderTarget[0].SrcBlend = D3D11_BLEND_BLEND_FACTOR; // a (your smoothing factor)
      blend_desc.RenderTarget[0].DestBlend = D3D11_BLEND_INV_BLEND_FACTOR; // (1 - a)
      blend_desc.RenderTarget[0].BlendOp = D3D11_BLEND_OP_ADD;
      native_device->CreateBlendState(&blend_desc, &game_device_data.sun_occlusion_test_blend_state);
   }

   void OnInitSwapchain(reshade::api::swapchain* swapchain) override
   {
      auto& device_data = *swapchain->get_device()->get_private_data<DeviceData>();

      // Assume it's the output resolution until proven otherwise
      cb_luma_global_settings.GameSettings.InvRenderRes.x = 1.f / device_data.output_resolution.x;
      cb_luma_global_settings.GameSettings.InvRenderRes.y = 1.f / device_data.output_resolution.y;
      device_data.cb_luma_global_settings_dirty = true;
   }

   // Add a saturate on opaque/transparent materials
   // Without this, occasionally you get some white pixels for one frame (actually this still doesn't fix it, but it won't hurt to have, the actual fix seems to be in skipping bloom on pixels with INF values)
   // TODO: the white pixels seemengly still appear sometimes when driving around...
   std::unique_ptr<std::byte[]> ModifyShaderByteCode(const std::byte* code, size_t& size, reshade::api::pipeline_subobject_type type, uint64_t shader_hash, const std::byte* shader_object, size_t shader_object_size) override
   {
      if (type != reshade::api::pipeline_subobject_type::pixel_shader)
         return nullptr;

      std::unique_ptr<std::byte[]> new_code = nullptr;

      // All opaque materials have a sampler by this name
      const char str_to_find[] = "shadowMapSamplerHighDetailTexture"; // Most transparent materials have "SpecularPower" in their name too, in case we needed to filter them
      const std::vector<std::byte> pattern_safety_check(reinterpret_cast<const std::byte*>(str_to_find), reinterpret_cast<const std::byte*>(str_to_find) + strlen(str_to_find));
      bool pattern_found = !System::ScanMemoryForPattern(reinterpret_cast<const std::byte*>(shader_object), shader_object_size, pattern_safety_check).empty();

      if (pattern_found)
      {
         std::vector<uint8_t> appended_patch;

         constexpr bool enable_unorm_emulation = true;
         if (enable_unorm_emulation)
         {
            std::vector<uint32_t> mov_sat_o0w_o0w = ShaderPatching::GetMovInstruction(D3D10_SB_OPERAND_TYPE_OUTPUT, 0, D3D10_SB_OPERAND_TYPE_OUTPUT, 0, true);
            appended_patch.insert(appended_patch.end(), reinterpret_cast<uint8_t*>(mov_sat_o0w_o0w.data()), reinterpret_cast<uint8_t*>(mov_sat_o0w_o0w.data()) + mov_sat_o0w_o0w.size() * sizeof(uint32_t));
            std::vector<uint32_t> max_o0xyz_o0xyz_0 = ShaderPatching::GetMaxInstruction(D3D10_SB_OPERAND_TYPE_OUTPUT, 0, D3D10_SB_OPERAND_TYPE_OUTPUT, 0);
            appended_patch.insert(appended_patch.end(), reinterpret_cast<uint8_t*>(max_o0xyz_o0xyz_0.data()), reinterpret_cast<uint8_t*>(max_o0xyz_o0xyz_0.data()) + max_o0xyz_o0xyz_0.size() * sizeof(uint32_t));
         }

         // Allocate new buffer and copy original shader code, then append the new code to fix UNORM to FLOAT texture upgrades
         // This emulates UNORM render target behaviour on FLOAT render targets (from texture upgrades), without limiting the rgb color range.
         // o0.rgb = max(o0.rgb, 0); // max is 0x34
         // o0.w = saturate(o0.w); // mov is 0x36
         new_code = std::make_unique<std::byte[]>(size + appended_patch.size());

         // Pattern to search for: 3E 00 00 01 (the last byte is the size, and the minimum is 1 (the unit is 4 bytes), given it also counts for the opcode and it's own size byte
         const std::vector<std::byte> return_pattern = {std::byte{0x3E}, std::byte{0x00}, std::byte{0x00}, std::byte{0x01}};

         // Append before the ret instruction if there's one at the end (there might not be?)
         // Our patch shouldn't pre-include a ret value (though it'd probably work anyway)!
         // Note that we could also just remove the return instruction and the shader would compile fine anyway? Unless the shader had any branches (if we added one, we should force add return!)
         if (!appended_patch.empty() && code[size - return_pattern.size()] == return_pattern[0] && code[size - return_pattern.size() + 1] == return_pattern[1] && code[size - return_pattern.size() + 2] == return_pattern[2] && code[size - return_pattern.size() + 3] == return_pattern[3])
         {
            size_t insert_pos = size - return_pattern.size();
            // Copy everything before pattern
            std::memcpy(new_code.get(), code, insert_pos);
            // Insert the patch
            std::memcpy(new_code.get() + insert_pos, appended_patch.data(), appended_patch.size());
            // Copy the rest (including the return instruction)
            std::memcpy(new_code.get() + insert_pos + appended_patch.size(), code + insert_pos, size - insert_pos);
         }
         // Append patch at the end
         else
         {
            std::memcpy(new_code.get(), code, size);
            std::memcpy(new_code.get() + size, appended_patch.data(), appended_patch.size());
         }

         size += appended_patch.size();

         // float3(0.299, 0.587, 0.114)
         const std::vector<std::byte> pattern_bt_601_luminance = {
            std::byte{0x87}, std::byte{0x16}, std::byte{0x99}, std::byte{0x3E},
            std::byte{0xA2}, std::byte{0x45}, std::byte{0x16}, std::byte{0x3F},
            std::byte{0xD5}, std::byte{0x78}, std::byte{0xE9}, std::byte{0x3D}};
         const std::vector<std::byte> pattern_bt_709_luminance = {
            std::byte{0xD0}, std::byte{0xB3}, std::byte{0x59}, std::byte{0x3E},
            std::byte{0x59}, std::byte{0x17}, std::byte{0x37}, std::byte{0x3F},
            std::byte{0x98}, std::byte{0xDD}, std::byte{0x93}, std::byte{0x3D}};
         // Fix usual wrong luminance calculations
         std::vector<std::byte*> matches_bt_601_luminance = System::ScanMemoryForPattern(reinterpret_cast<const std::byte*>(code), size, pattern_bt_601_luminance);
         for (std::byte* match : matches_bt_601_luminance)
         {
            // Calculate offset of each match relative to original code
            size_t offset = match - code;
            std::memcpy(new_code.get() + offset, pattern_bt_709_luminance.data(), pattern_bt_709_luminance.size());
         }
      }

      return new_code;
   }

   bool OnDrawCustom(ID3D11Device* native_device, ID3D11DeviceContext* native_device_context, CommandListData& cmd_list_data, DeviceData& device_data, reshade::api::shader_stage stages, const ShaderHashesList<OneShaderPerPipeline>& original_shader_hashes, bool is_custom_pass, bool& updated_cbuffers) override
   {
      auto& game_device_data = GetGameDeviceData(device_data);

      // The sky is drawn 7 times per frame, 6 times for the main car reflections cube map (and maybe other cars with relfections?), and 1 for the main scene view.
      // After that, it'll be drawing transparency until it then downscales depth (all the times)
      if (!game_device_data.is_drawing_transparency && is_custom_pass && original_shader_hashes.Contains(pixel_shader_hashes_Sky))
      {
         com_ptr<ID3D11RenderTargetView> rtv;
         native_device_context->OMGetRenderTargets(1, &rtv, nullptr);

         DXGI_FORMAT format;
         uint4 size;
         GetResourceInfo(rtv.get(), size, format);
         if (size.x == uint(device_data.render_resolution.x + 0.5) && size.y == uint(device_data.render_resolution.y + 0.5))
         {
            game_device_data.is_drawing_transparency = true;
         }
      }
      // Skip writing on alpha for transparency passes.
      // Alpha in this game is used to determine whether to do motion blur or not (as some kind of stencil flag).
      // The problem was that transparent objects were using alpha to blend transparency, but then it'd also end up written on the render target,
      // causing weird edges around objecs when motion blur applied (e.g. car headlights lens sprite or car windshield would get motion blur, but the rest of the car wouldn't).
      else if (game_device_data.is_drawing_transparency)
      {
         if (original_shader_hashes.Contains(pixel_shader_hashes_DownscaleDepth))
         {
            game_device_data.is_drawing_transparency = false;
            game_device_data.has_drawn_transparency = true;
            return false;
         }
         else if (test_index != 17)
         {
            com_ptr<ID3D11BlendState> blend_state;
            FLOAT blend_factor[4] = {1.f, 1.f, 1.f, 1.f};
            UINT blend_sample_mask;
            native_device_context->OMGetBlendState(&blend_state, blend_factor, &blend_sample_mask);
            if (blend_state)
            {
               D3D11_BLEND_DESC blend_desc;
               blend_state->GetDesc(&blend_desc);

               com_ptr<ID3D11BlendState> custom_blend_state = blend_state;
               if ((blend_desc.RenderTarget[0].RenderTargetWriteMask & D3D11_COLOR_WRITE_ENABLE_ALL) == D3D11_COLOR_WRITE_ENABLE_ALL)
               {
                  blend_desc.RenderTarget[0].RenderTargetWriteMask = D3D11_COLOR_WRITE_ENABLE_RED | D3D11_COLOR_WRITE_ENABLE_GREEN | D3D11_COLOR_WRITE_ENABLE_BLUE;
               }
               else
               {
                  return false;
               }

               // Game rendering is single threaded so we don't need a mutex
               auto it = game_device_data.custom_blend_states.find(blend_desc);
               if (it != game_device_data.custom_blend_states.end())
               {
                  custom_blend_state = it->second; // Already exists
               }
               else
               {
                  native_device->CreateBlendState(&blend_desc, &game_device_data.custom_blend_states[blend_desc]);
                  custom_blend_state = game_device_data.custom_blend_states[blend_desc];
               }

               // Probably useless in this game but clamp the blend factor just in case, to emulate UNORM rendering (it doesn't seem to be used, but who knows!)
               blend_factor[0] = std::clamp(blend_factor[0], 0.f, 1.f);
               blend_factor[1] = std::clamp(blend_factor[1], 0.f, 1.f);
               blend_factor[2] = std::clamp(blend_factor[2], 0.f, 1.f);
               blend_factor[3] = std::clamp(blend_factor[3], 0.f, 1.f);

               native_device_context->OMSetBlendState(custom_blend_state.get(), blend_factor, blend_sample_mask);
            }
         }
      }

      if (game_device_data.has_drawn_transparency && !game_device_data.has_drawn_motion_blur)
      {
         if (original_shader_hashes.Contains(pixel_shader_hashes_LinearizeDepth))
         {
            game_device_data.half_res_depth_srv.reset();
            native_device_context->PSGetShaderResources(0, 1, &game_device_data.half_res_depth_srv);
         }
         // Luma: in case MSAA was on, the sun occlusion test pass was accidentally testing the red channel of the scene rendering color texture,
         // instead of the depth. It's not 100% sure this didn't happen without Luma, but it probably did anyway.
         // In case MSAA was off, it was working fine, but it was sampling the full res depth 7x7 times, in far spots,
         // so sampling the half res depth is both faster and more accurate anyway!
         else if (original_shader_hashes.Contains(pixel_shader_hashes_SunOcclusionTest))
         {
            game_device_data.has_drawn_sun_occlusion_test = true;

            ID3D11ShaderResourceView* const half_res_depth_srv_ptr = game_device_data.half_res_depth_srv.get();
            native_device_context->PSSetShaderResources(0, 1, &half_res_depth_srv_ptr);

            // Luma: fix the sun occlusion test flickering way too much, causing the sun to appear and disappear, we give it some history blending (the sun would still draw in the right location, however it might draw behind collisions for a few frames after a camera cut now)
            // Ignore the first frame otherwise it'd blend to an uncleared texure, or after a camera cut that didn't draw the sun for some frames.
            if (test_index != 18 && game_device_data.had_drawn_sun_occlusion_test) // TODO: this doesn't seem to do anything??? We got it looking decent just from shaders anyway
            {
               UINT sample_mask = 0xFFFFFFFF;
               FLOAT blend_factor[4] = {0.1f, 0.1f, 0.1f, 1.0f}; // Value calibrated for 60fps (game is fixed at that fps)
               native_device_context->OMSetBlendState(game_device_data.sun_occlusion_test_blend_state.get(), blend_factor, sample_mask);
            }
         }
         else if (original_shader_hashes.Contains(shader_hashes_Tonemap_MotionBlur))
         {
            game_device_data.has_drawn_motion_blur = true;

            game_device_data.motion_blur_vs_cb.reset();
            game_device_data.motion_blur_ps_cb.reset();
            native_device_context->VSGetConstantBuffers(0, 1, &game_device_data.motion_blur_vs_cb);
            native_device_context->PSGetConstantBuffers(0, 1, &game_device_data.motion_blur_ps_cb);

            // Share the vertex shader cbffer into the pixel shader, so we can properly analyze motion blur parameters (given that most of them were exclusive to the VS, for optimization purposes)
            native_device_context->PSSetConstantBuffers(1, 1, &game_device_data.motion_blur_vs_cb);

            if (smooth_motion_blur_parameters)
            {
               // Set the previous cbuffers too, to interpolate with them as one frame's single results are too unstable for strong MB
               com_ptr<ID3D11Buffer> prev_vs_cb = game_device_data.motion_blur_vs_cb_copy;
               com_ptr<ID3D11Buffer> prev_ps_cb = game_device_data.motion_blur_ps_cb_copy;
               if (!prev_vs_cb)
               {
                  prev_vs_cb = game_device_data.motion_blur_vs_cb;
               }
               if (!prev_ps_cb)
               {
                  prev_ps_cb = game_device_data.motion_blur_ps_cb;
               }
               native_device_context->PSSetConstantBuffers(2, 1, &prev_ps_cb);
               native_device_context->PSSetConstantBuffers(3, 1, &prev_vs_cb);
            }
         }
      }

      return false;
   }

   void OnPresent(ID3D11Device* native_device, DeviceData& device_data) override
   {
      auto& game_device_data = GetGameDeviceData(device_data);

      game_device_data.half_res_depth_srv.reset();
      game_device_data.is_drawing_transparency = false;
      game_device_data.has_drawn_transparency = false;
      game_device_data.had_drawn_sun_occlusion_test = game_device_data.has_drawn_sun_occlusion_test;
      game_device_data.has_drawn_sun_occlusion_test = false;
      if (!game_device_data.has_drawn_motion_blur)
      {
         // Reset if MB didn't draw, we don't want to carry the past around
         game_device_data.motion_blur_vs_cb_copy.reset();
         game_device_data.motion_blur_ps_cb_copy.reset();
      }
      else
      {
         if (smooth_motion_blur_parameters)
         {
            com_ptr<ID3D11DeviceContext> native_device_context;
            native_device->GetImmediateContext(&native_device_context);

            // Clone the previous cbuffers (we do it here to avoid replacing the draw call and cloning the resource after)
            if (!game_device_data.motion_blur_ps_cb_copy)
            {
               game_device_data.motion_blur_ps_cb_copy = CloneResourceTyped(native_device, native_device_context.get(), game_device_data.motion_blur_ps_cb.get());
            }
            else
            {
               native_device_context->CopyResource(game_device_data.motion_blur_ps_cb_copy.get(), game_device_data.motion_blur_ps_cb.get());
            }
            if (!game_device_data.motion_blur_vs_cb_copy)
            {
               game_device_data.motion_blur_vs_cb_copy = CloneResourceTyped(native_device, native_device_context.get(), game_device_data.motion_blur_vs_cb.get());
            }
            else
            {
               native_device_context->CopyResource(game_device_data.motion_blur_vs_cb_copy.get(), game_device_data.motion_blur_vs_cb.get());
            }
         }

         game_device_data.motion_blur_vs_cb.reset();
         game_device_data.motion_blur_ps_cb.reset();
      }
      game_device_data.has_drawn_motion_blur = false;
   }

   void LoadConfigs() override
   {
      reshade::api::effect_runtime* runtime = nullptr;

      reshade::get_config_value(runtime, NAME, "BloomIntensity", cb_luma_global_settings.GameSettings.BloomIntensity);
      reshade::get_config_value(runtime, NAME, "MotionBlurIntensity", cb_luma_global_settings.GameSettings.MotionBlurIntensity);
      reshade::get_config_value(runtime, NAME, "ColorGradingIntensity", cb_luma_global_settings.GameSettings.ColorGradingIntensity);
      reshade::get_config_value(runtime, NAME, "ColorGradingFilterReductionIntensity", cb_luma_global_settings.GameSettings.ColorGradingFilterReductionIntensity);
      reshade::get_config_value(runtime, NAME, "HDRBoostIntensity", cb_luma_global_settings.GameSettings.HDRBoostIntensity);
      reshade::get_config_value(runtime, NAME, "OriginalTonemapperColorIntensity", cb_luma_global_settings.GameSettings.OriginalTonemapperColorIntensity);
      // "device_data.cb_luma_global_settings_dirty" should already be true at this point

      reshade::get_config_value(runtime, NAME, "HDRCarReflections", hdr_car_reflections); // Allow disabling this for performance reasons, even better it'd be to make them R11G110B10_FLOAT, given it'd be barely noticeable
      if (hdr_car_reflections)
      {
         // Note: this is very much overkill but it will make car reflections cubemaps HDR too, given they had some clipping. This can help us make the sky brighter with an HDR boost too!
         texture_format_upgrades_2d_size_filters |= (uint32_t)TextureFormatUpgrades2DSizeFilters::Cubes;
      }

      reshade::get_config_value(runtime, NAME, "PS2StyleMotionBlur", ps2_style_motion_blur);
      if (ps2_style_motion_blur)
      {
         cb_luma_global_settings.GameSettings.MotionBlurIntensity = 25.f;
      }
   }

   void DrawImGuiSettings(DeviceData& device_data) override
   {
      reshade::api::effect_runtime* runtime = nullptr;

      ImGui::NewLine();

      if (ImGui::SliderFloat("Bloom Intensity", &cb_luma_global_settings.GameSettings.BloomIntensity, 0.f, 2.f))
      {
         reshade::set_config_value(runtime, NAME, "BloomIntensity", cb_luma_global_settings.GameSettings.BloomIntensity);
      }
      DrawResetButton(cb_luma_global_settings.GameSettings.BloomIntensity, default_luma_global_game_settings.BloomIntensity, "BloomIntensity", runtime);

      if (ImGui::SliderFloat("Motion Blur Intensity", &cb_luma_global_settings.GameSettings.MotionBlurIntensity, ps2_style_motion_blur ? 10.f : 0.f, ps2_style_motion_blur ? 50.f : 2.f))
      {
         reshade::set_config_value(runtime, NAME, "MotionBlurIntensity", cb_luma_global_settings.GameSettings.MotionBlurIntensity);
      }
      ImGui::SameLine();
      if (ImGui::Checkbox("PS2 Style Motion Blur", &ps2_style_motion_blur))
      {
         if (ps2_style_motion_blur)
         {
            cb_luma_global_settings.GameSettings.MotionBlurIntensity = 25.f; // Empirically found default, looks nice
         }
         else
         {
            cb_luma_global_settings.GameSettings.MotionBlurIntensity = default_luma_global_game_settings.MotionBlurIntensity;
         }
         reshade::set_config_value(runtime, NAME, "MotionBlurIntensity", cb_luma_global_settings.GameSettings.MotionBlurIntensity);
         reshade::set_config_value(runtime, NAME, "PS2StyleMotionBlur", ps2_style_motion_blur);
      }
      if (DrawResetButton(cb_luma_global_settings.GameSettings.MotionBlurIntensity, default_luma_global_game_settings.MotionBlurIntensity, "MotionBlurIntensity", runtime))
      {
         ps2_style_motion_blur = false;
         reshade::set_config_value(runtime, NAME, "PS2StyleMotionBlur", ps2_style_motion_blur);
      }

      if (ImGui::SliderFloat("Color Grading Intensity", &cb_luma_global_settings.GameSettings.ColorGradingIntensity, 0.f, 1.f))
      {
         reshade::set_config_value(runtime, NAME, "ColorGradingIntensity", cb_luma_global_settings.GameSettings.ColorGradingIntensity);
      }
      DrawResetButton(cb_luma_global_settings.GameSettings.ColorGradingIntensity, default_luma_global_game_settings.ColorGradingIntensity, "ColorGradingIntensity", runtime);

      if (ImGui::SliderFloat("Color Grading Filter Reduction Intensity", &cb_luma_global_settings.GameSettings.ColorGradingFilterReductionIntensity, 0.f, 1.f))
      {
         reshade::set_config_value(runtime, NAME, "ColorGradingFilterReductionIntensity", cb_luma_global_settings.GameSettings.ColorGradingFilterReductionIntensity);
      }
      if (ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled))
      {
         ImGui::SetTooltip("The game's default color grading often applied a strong blue or yellow tint, this attempts to restore a more neutral color, without removing adjustments to contrast or saturation.");
      }
      DrawResetButton(cb_luma_global_settings.GameSettings.ColorGradingFilterReductionIntensity, default_luma_global_game_settings.ColorGradingFilterReductionIntensity, "ColorGradingFilterReductionIntensity", runtime);

      if (cb_luma_global_settings.DisplayMode == DisplayModeType::HDR)
      {
         if (ImGui::SliderFloat("HDR Boost Intensity", &cb_luma_global_settings.GameSettings.HDRBoostIntensity, 0.f, 2.f))
         {
            reshade::set_config_value(runtime, NAME, "HDRBoostIntensity", cb_luma_global_settings.GameSettings.HDRBoostIntensity);
         }
         if (ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled))
         {
            ImGui::SetTooltip("Enable a \"Fake\" HDR boosting effect. Set to 0 for the vanilla look.");
         }
         DrawResetButton(cb_luma_global_settings.GameSettings.HDRBoostIntensity, default_luma_global_game_settings.HDRBoostIntensity, "HDRBoostIntensity", runtime);
      }

      if (ImGui::SliderFloat("Original Tonemapper Color Intensity", &cb_luma_global_settings.GameSettings.OriginalTonemapperColorIntensity, 0.f, 1.f))
      {
         reshade::set_config_value(runtime, NAME, "OriginalTonemapperColorIntensity", cb_luma_global_settings.GameSettings.OriginalTonemapperColorIntensity);
      }
      if (ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled))
      {
         ImGui::SetTooltip("Move closer to 1 to restore a look closer to the original (more desaturated).");
      }
      DrawResetButton(cb_luma_global_settings.GameSettings.OriginalTonemapperColorIntensity, default_luma_global_game_settings.OriginalTonemapperColorIntensity, "OriginalTonemapperColorIntensity", runtime);
   }

   void PrintImGuiAbout() override
   {
      ImGui::Text("Luma for \"Burnout Paradise Remastered\" is developed by Pumbo and is open source and free.\nIf you enjoy it, consider donating");

      const auto button_color = ImGui::GetStyleColorVec4(ImGuiCol_Button);
      const auto button_hovered_color = ImGui::GetStyleColorVec4(ImGuiCol_ButtonHovered);
      const auto button_active_color = ImGui::GetStyleColorVec4(ImGuiCol_ButtonActive);
      ImGui::PushStyleColor(ImGuiCol_Button, IM_COL32(70, 134, 0, 255));
      ImGui::PushStyleColor(ImGuiCol_ButtonHovered, IM_COL32(70 + 9, 134 + 9, 0, 255));
      ImGui::PushStyleColor(ImGuiCol_ButtonActive, IM_COL32(70 + 18, 134 + 18, 0, 255));
      static const std::string donation_link_pumbo = std::string("Buy Pumbo a Coffee on buymeacoffee ") + std::string(ICON_FK_OK);
      if (ImGui::Button(donation_link_pumbo.c_str()))
      {
         system("start https://buymeacoffee.com/realfiloppi");
      }
      static const std::string donation_link_pumbo_2 = std::string("Buy Pumbo a Coffee on ko-fi ") + std::string(ICON_FK_OK);
      if (ImGui::Button(donation_link_pumbo_2.c_str()))
      {
         system("start https://ko-fi.com/realpumbo");
      }
      ImGui::PopStyleColor(3);

      ImGui::NewLine();
      // Restore the previous color, otherwise the state we set would persist even if we popped it
      ImGui::PushStyleColor(ImGuiCol_Button, button_color);
      ImGui::PushStyleColor(ImGuiCol_ButtonHovered, button_hovered_color);
      ImGui::PushStyleColor(ImGuiCol_ButtonActive, button_active_color);
#if 0
      static const std::string mod_link = std::string("Nexus Mods Page ") + std::string(ICON_FK_SEARCH);
      if (ImGui::Button(mod_link.c_str()))
      {
         system("start https://www.nexusmods.com/prey2017/mods/149");
      }
#endif
      static const std::string social_link = std::string("Join our \"HDR Den\" Discord ") + std::string(ICON_FK_SEARCH);
      if (ImGui::Button(social_link.c_str()))
      {
         // Unique link for Luma by Pumbo (to track the origin of people joining), do not share for other purposes
         static const std::string obfuscated_link = std::string("start https://discord.gg/J9fM") + std::string("3EVuEZ");
         system(obfuscated_link.c_str());
      }
      static const std::string contributing_link = std::string("Contribute on Github ") + std::string(ICON_FK_FILE_CODE);
      if (ImGui::Button(contributing_link.c_str()))
      {
         system("start https://github.com/Filoppi/Luma-Framework");
      }
      ImGui::PopStyleColor(3);

      ImGui::NewLine();
      ImGui::Text("Credits:"
                  "\n\nMain:"
                  "\nPumbo"

                  "\n\nThird Party:"
                  "\nReShade"
                  "\nImGui"
         "");
   }
};

BOOL APIENTRY DllMain(HMODULE hModule, DWORD ul_reason_for_call, LPVOID lpReserved)
{
   if (ul_reason_for_call == DLL_PROCESS_ATTACH)
   {
      Globals::SetGlobals(PROJECT_NAME, "Burnout Paradise Remastered - Luma mod");
      Globals::VERSION = 1;

      swapchain_format_upgrade_type = TextureFormatUpgradesType::AllowedEnabled;
      swapchain_upgrade_type = SwapchainUpgradeType::scRGB;
      texture_format_upgrades_type = TextureFormatUpgradesType::AllowedEnabled;
      texture_upgrade_formats = {
            reshade::api::format::r8g8b8a8_unorm,
            reshade::api::format::r8g8b8a8_unorm_srgb,
            reshade::api::format::r8g8b8a8_typeless,
            reshade::api::format::r8g8b8x8_unorm,
            reshade::api::format::r8g8b8x8_unorm_srgb,
            reshade::api::format::b8g8r8a8_unorm,
            reshade::api::format::b8g8r8a8_unorm_srgb,
            reshade::api::format::b8g8r8a8_typeless,
            reshade::api::format::b8g8r8x8_unorm,
            reshade::api::format::b8g8r8x8_unorm_srgb,
            reshade::api::format::b8g8r8x8_typeless,

            reshade::api::format::r11g11b10_float,
      };
      texture_format_upgrades_2d_size_filters = 0 | (uint32_t)TextureFormatUpgrades2DSizeFilters::SwapchainResolution | (uint32_t)TextureFormatUpgrades2DSizeFilters::SwapchainAspectRatio;
      enable_indirect_texture_format_upgrades = true;
      enable_automatic_indirect_texture_format_upgrades = true;
      // The game has issues with motion blur warping when using direct upgrades, and some particles don't draw (we should try again, it might be fixed after polishing the code)

      // Game floors are blurry without this
      enable_samplers_upgrade = true;

      // With or without these the game occasionally loses input and draws behind the Windows taskbar, even when "force_borderless" is true, so let's just keep it vanilla, it already offers FSE/borderless/windowed
      prevent_fullscreen_state = false;
#if 0
      force_borderless = true;
#endif

#if DEVELOPMENT
      forced_shader_names.emplace(std::stoul("244AC5EC", nullptr, 16), "Power Cable");
      forced_shader_names.emplace(std::stoul("F796168F", nullptr, 16), "Car Shadow");
      forced_shader_names.emplace(std::stoul("F382FC35", nullptr, 16), "Downscale Depth");
      forced_shader_names.emplace(std::stoul("E1564B55", nullptr, 16), "Downscale Depth MS");
      forced_shader_names.emplace(std::stoul("60F03AA9", nullptr, 16), "Linearize Depth");
      forced_shader_names.emplace(std::stoul("808BC446", nullptr, 16), "Gen Bloom");
      forced_shader_names.emplace(std::stoul("0325730A", nullptr, 16), "Blur Bloom");
      forced_shader_names.emplace(std::stoul("C7835AB9", nullptr, 16), "Gen DoF");
      forced_shader_names.emplace(std::stoul("01FF871A", nullptr, 16), "Gen SSAO");
      forced_shader_names.emplace(std::stoul("EA125DFC", nullptr, 16), "Blur DoF or SSAO");
      forced_shader_names.emplace(std::stoul("F4CB0620", nullptr, 16), "FXAA");
      forced_shader_names.emplace(std::stoul("9943A357", nullptr, 16), "Clear Particles Color and Copy Depth");
      forced_shader_names.emplace(std::stoul("923A9E10", nullptr, 16), "Asphalt Lines");
#endif

      redirected_shader_hashes["Tonemap"] =
      {
         "5A34E415",
         "6B63F6E9",
         "7E095B44",
         "36F104E3",
         "57B58AF1",
         "259C7CD1",
         "382FAE1E",
         "959BB01D",
         "4933D9DA",
         "9613B478",
         "07297021",
         "10807557",
         "A4AAD10C",
         "A47D890F",
         "B9F09845",
         "BE5A4C0C",
         "BF6A19BE",
         "C0BD8148",
         "C0305DC5",
         "D29A0825",
         "D48AAAA6",
         "D772072E",
         "DD905507",
         "FDE602F4",
      };

      default_luma_global_game_settings.BloomIntensity = 0.5f; // Reduce default given that on modern resolutions and displays, it doesn't look good, especially not in HDR. Also "ENABLE_IMPROVED_MOTION_BLUR" make bloom stronger by default.
      default_luma_global_game_settings.MotionBlurIntensity = 1.f;
      default_luma_global_game_settings.ColorGradingIntensity = 0.8f; // It was a bit too strong for 2025 standards, and kinda crushed blacks and distorted colors in weird ways for HDR
      default_luma_global_game_settings.ColorGradingFilterReductionIntensity = 0.f;
      default_luma_global_game_settings.HDRBoostIntensity = 1.f;
      default_luma_global_game_settings.OriginalTonemapperColorIntensity = 0.f;
      cb_luma_global_settings.GameSettings = default_luma_global_game_settings;

      pixel_shader_hashes_Sky.pixel_shaders = { Shader::Hash_StrToNum("3E358D7B") };
      pixel_shader_hashes_DownscaleDepth.pixel_shaders = { Shader::Hash_StrToNum("F382FC35"), Shader::Hash_StrToNum("E1564B55") };
      pixel_shader_hashes_LinearizeDepth.pixel_shaders = { Shader::Hash_StrToNum("60F03AA9") };
      pixel_shader_hashes_SunOcclusionTest.pixel_shaders = { Shader::Hash_StrToNum("7A3F3D3F") };
      shader_hashes_Tonemap_MotionBlur.vertex_shaders = { Shader::Hash_StrToNum("04239037") };

      game = new BurnoutParadise();
   }

   CoreMain(hModule, ul_reason_for_call, lpReserved);

   return TRUE;
}