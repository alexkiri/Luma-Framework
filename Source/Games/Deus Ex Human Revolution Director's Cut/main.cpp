#define GAME_DXHRDC 1

#define ENABLE_GAME_PIPELINE_STATE_READBACK 1
#define ENABLE_ORIGINAL_SHADERS_MEMORY_EDITS 1

#include "..\..\Core\core.hpp"

namespace
{
   bool has_gold_filter_restoration_mod = false;
   bool has_gold_filter = false;

   int has_supported_aa_count = 100;
   bool has_custom_gold_filter = false;

   bool has_ssao = false;

   ShaderHashesList pixel_shader_hashes_ColorGrading;
   ShaderHashesList pixel_shader_hashes_SupportedAA;
   ShaderHashesList pixel_shader_hashes_BloomComposition;
   ShaderHashesList pixel_shader_hashes_UI;
   ShaderHashesList pixel_shader_hashes_SSAOGeneration;

   // User settings
   float bloom_intensity = 1.f;
   float fog_intensity = 1.f;
   float emissive_intensity = 0.667f;
}

struct GameDeviceDataDeusExHumanRevolutionDC final : public GameDeviceData
{
   bool has_drawn_custom_gold_filter = false;
   bool has_drawn_supported_aa = false;
   bool has_drawn_opaque_geometry = false;
   bool has_drawn_ssao = false;

   SanitizeNaNsSimpleData sanitize_nans_data;

   // Most of the game's rendering and UI draws directly to this
   com_ptr<ID3D11RenderTargetView> swapchain_rtv;

   com_ptr<ID3D11Resource> depth_buffer;
   com_ptr<ID3D11ShaderResourceView> depth_buffer_srv;

   struct BlendDescCompare
   {
      bool operator()(const D3D11_BLEND_DESC& a, const D3D11_BLEND_DESC& b) const
      {
         return memcmp(&a, &b, sizeof(D3D11_BLEND_DESC)) < 0;
      }
   };
#if 0
   std::map<D3D11_BLEND_DESC, com_ptr<ID3D11BlendState>, BlendDescCompare> custom_blend_states;
#endif
   std::map<D3D11_BLEND_DESC, com_ptr<ID3D11BlendState>, BlendDescCompare> disabled_blend_states;
};

class GameDeusExHumanRevolutionDC final : public Game
{
public:
   static GameDeviceDataDeusExHumanRevolutionDC& GetGameDeviceData(DeviceData& device_data)
   {
      return *static_cast<GameDeviceDataDeusExHumanRevolutionDC*>(device_data.game);
   }

   void OnInit(bool async) override
   {
      luma_settings_cbuffer_index = 13;
      luma_data_cbuffer_index = 12;

      std::vector<ShaderDefineData> game_shader_defines_data = {
         {"ENABLE_LUMA", '1', false, false, "Allows disabling some of the Luma's post processing modifications to improve the image and output HDR"},
         {"ENABLE_IMPROVED_BLOOM", '1', false, false, "The bloom radius was calibrated for 720p/1080p and looked too small at higher resolutions"},
         {"ENABLE_IMPROVED_COLOR_GRADING", '1', false, false, "Allow running a new, modernized, version of the color grading pass (e.g. the gold filter)"},
         {"ENABLE_COLOR_GRADING_DESATURATION", '1', false, false, "The color grading pass often had a strong desaturation effect, turn this off to preserve saturation"},
         {"ENABLE_FAKE_HDR", '1', false, false, "Enable a \"Fake\" HDR boosting effect"},
      };
      shader_defines_data.append_range(game_shader_defines_data);

      GetShaderDefineData(TEST_SDR_HDR_SPLIT_VIEW_MODE_NATIVE_IMPL_HASH).SetDefaultValue('1'); // The game was just clipping, so HDR is an unclipped extension of SDR

      // No gamma mismatch baked in the textures as the game never applied gamma, it was gamma from the beginning until the end (so we assume 2.2)
      GetShaderDefineData(GAMMA_CORRECTION_TYPE_HASH).SetDefaultValue('1');
      GetShaderDefineData(VANILLA_ENCODING_TYPE_HASH).SetDefaultValue('1');

      GetShaderDefineData(UI_DRAW_TYPE_HASH).SetDefaultValue('2');

#if DEVELOPMENT
      forced_shader_names.emplace(Shader::Hash_StrToNum("6B0219A1"), "MLAA Mask 1 Gen");
      forced_shader_names.emplace(Shader::Hash_StrToNum("1DA1E46E"), "MLAA Mask 2 Gen");
      forced_shader_names.emplace(Shader::Hash_StrToNum("51BBB596"), "MLAA Composition");
#endif
   }

   void OnLoad(std::filesystem::path& file_path, bool failed) override
   {
      // Note: this code might try to apply multiple times as the ReShade addon gets loaded and unloaded, once is enough
      if (!failed)
      {
         if (GetModuleHandle(TEXT("DXHRDC-GFX.asi")) != NULL)
         {
            has_gold_filter_restoration_mod = true;
            has_gold_filter = true; // This isn't guaranteed as it can still be turned off
         }

         // Original game already had the gold filter
         std::string exe_name = System::GetProcessExecutableName();
         if (exe_name == "DXHR.exe" || exe_name == "dxhr.exe")
         {
            has_gold_filter = true;
         }

         has_custom_gold_filter = has_gold_filter; // Assume so, why wouldn't it be

         HMODULE module_handle = GetModuleHandle(nullptr); // Handle to the current executable
         auto dos_header = reinterpret_cast<PIMAGE_DOS_HEADER>(module_handle);
         auto nt_headers = reinterpret_cast<PIMAGE_NT_HEADERS>(reinterpret_cast<std::byte*>(module_handle) + dos_header->e_lfanew);

         std::byte* base = reinterpret_cast<std::byte*>(module_handle);
         std::size_t section_size = nt_headers->OptionalHeader.SizeOfImage;

         // From pcgw. Unknown author.
         const std::vector<uint8_t> pattern_1 = {
            0x81, 0xFF, 0x00, 0x05, 0x00, 0x00, 0x7C, 0x05,
            0xBF, 0x00, 0x05, 0x00, 0x00, 0xDB, 0x44, 0x24
         };
         std::vector<std::byte*> pattern_1_addresses = System::ScanMemoryForPattern(base, section_size, pattern_1);

         const std::vector<uint8_t> pattern_2 = {
            0x81, 0xFE, 0x00, 0x05, 0x00, 0x00, 0x7D, 0x08,
            0x8B, 0xCE, 0x89, 0x74, 0x24, 0x20, 0xEB, 0x09,
            0xB9, 0x00, 0x05, 0x00, 0x00, 0x89, 0x4C, 0x24,
            0x20
         };
         std::vector<std::byte*> pattern_2_addresses = System::ScanMemoryForPattern(base, section_size, pattern_2);

         // The game's UI became tiny beyond 1280 horizontal resolutions, as the auto scaling,
         // (which would make it appear of the same size on the display) was limited to that, for some reason.
         // Skip this if the user already modded the executable.
         if (pattern_1_addresses.size() == 1 && pattern_2_addresses.size() == 1)
         {
            int screen_width = GetSystemMetrics(SM_CXSCREEN);
            int screen_height = GetSystemMetrics(SM_CYSCREEN);
            float screen_aspect_ratio = float(screen_width) / float(screen_height);
            // The game's UI is scaled based on what would be your horizontal resolution
            // if you screen was 16:9 (with its current vertical resolution as reference point).
            // Not sure how it calculates that, but tests make it seem like that's the behaviour.
            if (screen_aspect_ratio >= (16.f / 9.f))
            {
               screen_width = static_cast<int>(std::lround(screen_height * (16.0 / 9.0)));
            }

            // Replace the pattern with your own horizontal resolution.
            // As long as we are in 16:9, we could go as high as we want and it'd scale correctly, but in UW we need to set the right value or the UI will get huge.
            std::vector<uint8_t> pattern_1_patch = pattern_1;
            std::vector<uint8_t> pattern_2_patch = pattern_2;
            std::memcpy(&pattern_1_patch[2], &screen_width, sizeof(screen_width));
            std::memcpy(&pattern_1_patch[9], &screen_width, sizeof(screen_width));
            std::memcpy(&pattern_2_patch[2], &screen_width, sizeof(screen_width));
            std::memcpy(&pattern_2_patch[17], &screen_width, sizeof(screen_width));

            DWORD old_protect;
            BOOL success = VirtualProtect(pattern_1_addresses[0], pattern_1_patch.size(), PAGE_EXECUTE_READWRITE, &old_protect);
            if (success)
            {
               std::memcpy(pattern_1_addresses[0], pattern_1_patch.data(), pattern_1_patch.size());

               DWORD temp_protect;
               VirtualProtect(pattern_1_addresses[0], pattern_1_patch.size(), old_protect, &temp_protect);

               success = VirtualProtect(pattern_2_addresses[0], pattern_2_patch.size(), PAGE_EXECUTE_READWRITE, &old_protect);
               if (success)
               {
                  std::memcpy(pattern_2_addresses[0], pattern_2_patch.data(), pattern_2_patch.size());

                  VirtualProtect(pattern_2_addresses[0], pattern_2_patch.size(), old_protect, &temp_protect);
               }
            }
            ASSERT_ONCE(success);
         }
      }
   }

   void OnCreateDevice(ID3D11Device* native_device, DeviceData& device_data) override
   {
      device_data.game = new GameDeviceDataDeusExHumanRevolutionDC;
   }

   // All materials color/lighting shaders in this game have a saturate at the end, that always gets bundled with a multiply+add instruction.
   // There's also luminance calculations for the alpha buffer, presumably for FXAA (in case it was used), or bloom (contained on alpha), but they were based of BT.601 instead of BT.709.
   // Given that there's possibly hundreds of them, we live patch them.
   std::unique_ptr<std::byte[]> ModifyShaderByteCode(const std::byte* code, size_t size, reshade::api::pipeline_subobject_type type, uint64_t shader_hash) override
   {
      if (type != reshade::api::pipeline_subobject_type::pixel_shader) return nullptr;

      // The last byte depends on the size of the instruction so it doesn't always match!
      const std::vector<std::byte> pattern_mad_sat = { std::byte{0x32}, std::byte{0x20}, std::byte{0x00}, std::byte{0x09} }; // mad_sat
      const std::vector<std::byte> pattern_mul_sat = { std::byte{0x38}, std::byte{0x20}, std::byte{0x00}, std::byte{0x0A} }; // mul_sat
      const std::vector<std::byte> pattern_mad_sat_alt = { std::byte{0x32}, std::byte{0x20}, std::byte{0x00}, std::byte{0x0B} }; // mad_sat
      const std::vector<std::byte> pattern_mul_sat_alt = { std::byte{0x38}, std::byte{0x20}, std::byte{0x00}, std::byte{0x07} }; // mul_sat

      const std::vector<std::byte> pattern_mad = { std::byte{0x32}, std::byte{0x00}, std::byte{0x00}, std::byte{0x09} }; // mad
      const std::vector<std::byte> pattern_mul = { std::byte{0x38}, std::byte{0x00}, std::byte{0x00}, std::byte{0x0A} }; // mul

      // float3(0.299000f, 0.587000f, 0.114000f)
      const std::vector<std::byte> pattern_bt_601_luminance = {
       std::byte{0x87}, std::byte{0x16}, std::byte{0x99}, std::byte{0x3E},
       std::byte{0xA2}, std::byte{0x45}, std::byte{0x16}, std::byte{0x3F},
       std::byte{0xD5}, std::byte{0x78}, std::byte{0xE9}, std::byte{0x3D}
      };
      const std::vector<std::byte> pattern_bt_709_luminance = {
       std::byte{0xD0}, std::byte{0xB3}, std::byte{0x59}, std::byte{0x3E},
       std::byte{0x59}, std::byte{0x17}, std::byte{0x37}, std::byte{0x3F},
       std::byte{0x98}, std::byte{0xDD}, std::byte{0x93}, std::byte{0x3D}
      };

      // Materials always contain this final cbuffer variable multiplier as a brightness scale or some alpha thing (cb2[29].x)
      const std::vector<std::byte> pattern_safety_check = { std::byte{0x02}, std::byte{0x00}, std::byte{0x00}, std::byte{0x00}, std::byte{0x1D} };

      std::unique_ptr<std::byte[]> new_code = nullptr;

      std::vector<std::byte*> matches_bt_601_luminance = System::ScanMemoryForPattern(reinterpret_cast<const std::byte*>(code), size, pattern_bt_601_luminance);
      if (!matches_bt_601_luminance.empty())
      {
         // Allocate new buffer and copy original shader code
         new_code = std::make_unique<std::byte[]>(size);
         std::memcpy(new_code.get(), code, size);

         // Always correct the wrong luminance calculations
         for (std::byte* match : matches_bt_601_luminance)
         {
            // Calculate offset of each match relative to original code
            size_t offset = match - code;
            std::memcpy(new_code.get() + offset, pattern_bt_709_luminance.data(), pattern_bt_709_luminance.size());
         }

         // These would usually be just before the luminance matches (I think it has to be)
         std::vector<std::byte*> matches_mad_sat = System::ScanMemoryForPattern(reinterpret_cast<const std::byte*>(code), size, pattern_mad_sat);
         matches_mad_sat.append_range(System::ScanMemoryForPattern(reinterpret_cast<const std::byte*>(code), size, pattern_mad_sat_alt));
         std::vector<std::byte*> matches_mul_sat = System::ScanMemoryForPattern(reinterpret_cast<const std::byte*>(code), size, pattern_mul_sat);
         matches_mul_sat.append_range(System::ScanMemoryForPattern(reinterpret_cast<const std::byte*>(code), size, pattern_mul_sat_alt));

         // Smaller pointer comes first
         std::sort(matches_mad_sat.begin(), matches_mad_sat.end(),
            [](const std::byte* a, const std::byte* b) {
               return a < b;
            });
         std::sort(matches_mul_sat.begin(), matches_mul_sat.end(),
            [](const std::byte* a, const std::byte* b) {
               return a < b;
            });

         std::vector<std::byte*> matches_sat;
         bool last_is_mul_sat = false;
         // Pick the last between the mad_sat or mul_sat, it's always at the end!
         if (!matches_mad_sat.empty() && matches_mul_sat.empty())
         {
            matches_sat = matches_mad_sat;
         }
         else if (matches_mad_sat.empty() && !matches_mul_sat.empty())
         {
            matches_sat = matches_mul_sat;
            last_is_mul_sat = true;
         }
         else if (!matches_mad_sat.empty() && !matches_mul_sat.empty())
         {
            if (matches_mul_sat.back() > matches_mad_sat.back())
            {
               matches_sat = matches_mul_sat;
               last_is_mul_sat = true;
            }
            else
            {
               matches_sat = matches_mad_sat;
            }
         }

         // Some materials use a mul_sat instead (the last one), after two mads (e.g. 0xE5902D9E, 0x0D92ADEF etc), they are right next to each other at the end, one after the other, so it's easy to detect
         if (last_is_mul_sat)
         {
            last_is_mul_sat = false;
            std::vector<std::byte*> matches_mad = System::ScanMemoryForPattern(reinterpret_cast<const std::byte*>(code), size, pattern_mad);
            if (matches_mad.size() >= 3 && !matches_mul_sat.empty())
            {
               size_t last_mads_offset = matches_mad[matches_mad.size() - 2] - matches_mad[matches_mad.size() - 3];
               size_t last_mad_to_mul_sat_offset = matches_mul_sat[matches_mul_sat.size() - 1] - matches_mad[matches_mad.size() - 2];
               // 5 DWORD (or maybe 9 actually)
               // mad r2.xyz, r2.xyzx, r1.wwww, r0.wwww
               // 5 DWORD (or maybe 9 actually)
               // mad r0.xyz, r4.xyzx, r0.xyzx, r1.xyzx
               // 4 DWORD (maybe)
               // mul_sat r0.xyz, r2.xyzx, r0.xyzx
               if (last_mads_offset == 36 && last_mad_to_mul_sat_offset == 36)
               {
                  // Right match
                  matches_sat = matches_mul_sat;
                  last_is_mul_sat = true;
               }
            }

            // Switch back to the mad_sat if the mul_sat safety pattern checks failed
            if (!last_is_mul_sat)
            {
               matches_sat = matches_mad_sat;
            }
         }

         // If all patterns are found, patch the shader, it's a material shader!
         if (!matches_sat.empty())
         {
            // The remaining patterns are after the last mad_sat/mul_sat (there could be quite a few mad_sat/mul_sat around, the one we care for is seemengly always the last one)
            const size_t size_offset = matches_sat.back() - code;

            // TODO: add a check for the presence of a "mov_sat" as well, seemengly always after the "mad_sat/mul_sat", but anyway at worse it should be slightly before.
            std::vector<std::byte*> matches_safety_check = System::ScanMemoryForPattern(reinterpret_cast<const std::byte*>(matches_sat.back()), size - size_offset, pattern_safety_check);
            if (!matches_safety_check.empty())
            {
               // Only patch the last mad_sat/mul_sat!
               // Remove the 0x20 saturate flag in the second byte and replace it with 0x00
               size_t offset = matches_sat.back() - code;
               std::memset(new_code.get() + offset + 1, 0, 1);
            }
         }
      }

      return new_code;
   }

   void OnInitSwapchain(reshade::api::swapchain* swapchain) override
   {
      auto& device_data = *swapchain->get_device()->get_private_data<DeviceData>();
      auto& game_device_data = GetGameDeviceData(device_data);
      if (&game_device_data != nullptr) // TODO: is this needed? Probl not. This check is also in INSIDE
      {
         game_device_data.swapchain_rtv.reset(); // Reset it when the game resizes
      }
   }

   // The order of drawing is:
   // Write some LUT (?) from the CPU
   // Clear Normal Maps and Depth
   // Draw Normal Maps and Depth
   // Draw some shadow map, rudimentary AO, possibly from the angles of normal maps and depth (this looks right at any aspect ratio and resolution, though it's got bad screen space noise). This is stored in the alpha of the normal map buffer
   // Clear the new target texture
   // Draw some basic lighting buffer (mesh by mesh?)
   // Clear the new target texture (swapchain) (to beige)
   // Draw the final "composed" scene color (in gamma space), directly on the swapchain, mesh by mesh, starting from lights, to normal meshes (including skinner/characters), to transparency and fog, and then emissive etc. The alpha channel contrains the bloom/emissivness amount
   // Copy the swapchain texture
   // Apply decals
   // Another copy?
   // Apply color filter? Nah
   // Generate bloom (and DoF?)
   // Apply bloom (~additive)
   // Do post process...?
   // Apply grading (e.g. golden filter, contrast etc)
   // Draw UI (directly on swapchain)
   // Present
   bool OnDrawCustom(ID3D11Device* native_device, ID3D11DeviceContext* native_device_context, CommandListData& cmd_list_data, DeviceData& device_data, reshade::api::shader_stage stages, const ShaderHashesList<OneShaderPerPipeline>& original_shader_hashes, bool is_custom_pass, bool& updated_cbuffers) override
   {
      auto& game_device_data = GetGameDeviceData(device_data);

      if (!game_device_data.has_drawn_custom_gold_filter)
      {
         // Tell the supported AA shaders they need to tonemap, as the gold filter shader won't run, and that's ideally where we'd do TM
         if (is_custom_pass && original_shader_hashes.Contains(pixel_shader_hashes_SupportedAA))
         {
            if (!has_custom_gold_filter)
            {
               SetLumaConstantBuffers(native_device_context, cmd_list_data, device_data, stages, LumaConstantBufferType::LumaSettings);
               SetLumaConstantBuffers(native_device_context, cmd_list_data, device_data, stages, LumaConstantBufferType::LumaData, 1);
               updated_cbuffers = true;
            }
            game_device_data.has_drawn_supported_aa = true;

            game_device_data.swapchain_rtv.reset();
            native_device_context->OMGetRenderTargets(1, &game_device_data.swapchain_rtv, nullptr);

            // Verify AA always draws on the swapchain, it seems to be the one pass that reliably does so!
            {
               com_ptr<ID3D11Resource> rt_resource;
               if (game_device_data.swapchain_rtv)
               {
                  game_device_data.swapchain_rtv->GetResource(&rt_resource);
               }
               ASSERT_ONCE(device_data.back_buffers.contains((uint64_t)rt_resource.get()));
            }
         }
         else if (is_custom_pass && original_shader_hashes.Contains(pixel_shader_hashes_ColorGrading))
         {
            game_device_data.has_drawn_custom_gold_filter = true;
         }
         // This will always run
         else if (original_shader_hashes.Contains(pixel_shader_hashes_BloomComposition))
         {
            device_data.has_drawn_main_post_processing = true;

            // Add depth so we can do fog in the original bloom composition shader too, given that only the DC had fog
            ID3D11ShaderResourceView* const depth_buffer_srv_ptr = game_device_data.depth_buffer_srv.get();
            native_device_context->PSSetShaderResources(3, 1, &depth_buffer_srv_ptr);

            SetLumaConstantBuffers(native_device_context, cmd_list_data, device_data, stages, LumaConstantBufferType::LumaSettings);
            SetLumaConstantBuffers(native_device_context, cmd_list_data, device_data, stages, LumaConstantBufferType::LumaData, Math::AsUInt(emissive_intensity), 0, bloom_intensity, fog_intensity);
            updated_cbuffers = true;
         }
         // Requires SSAO enabled in the setting
         else if (original_shader_hashes.Contains(pixel_shader_hashes_SSAOGeneration))
         {
            game_device_data.has_drawn_ssao = true;
         }
         // Materials rendering
         // Exclude UI to avoid doing this during UI only screens,
         // and only do after SSAO has run, for performance, to avoid useless checks (there's the lighting buffer pass after, but we'd need to hash all its shaders to exclude it)
         else if (!device_data.has_drawn_main_post_processing && (!has_ssao || game_device_data.has_drawn_ssao) && !original_shader_hashes.Contains(pixel_shader_hashes_UI))
         {
            com_ptr<ID3D11RenderTargetView> rtv;
            com_ptr<ID3D11DepthStencilView> dsv;
            native_device_context->OMGetRenderTargets(1, &rtv, &dsv);

            // Same resource but different RTV
            com_ptr<ID3D11Resource> r1;
            if (game_device_data.swapchain_rtv)
               game_device_data.swapchain_rtv->GetResource(&r1);
            com_ptr<ID3D11Resource> r2;
            if (rtv)
               rtv->GetResource(&r2);

            // After normal maps and lighting buffer, the game draws the materials final color
            if (r2 && r2 == r1)
            {
               if (dsv)
               {
                  com_ptr<ID3D11Resource> depth_buffer;
                  dsv->GetResource(&depth_buffer);
                  if (depth_buffer != game_device_data.depth_buffer)
                  {
                     game_device_data.depth_buffer.reset();
                     game_device_data.depth_buffer_srv.reset();

                     com_ptr<ID3D11Texture2D> depth_buffer_texture_2d;
                     depth_buffer->QueryInterface(&depth_buffer_texture_2d);
                     D3D11_SHADER_RESOURCE_VIEW_DESC srv_desc = {};
                     if (depth_buffer_texture_2d)
                     {
                        D3D11_TEXTURE2D_DESC texture_2d_desc;
                        depth_buffer_texture_2d->GetDesc(&texture_2d_desc);

                        ASSERT_ONCE(texture_2d_desc.Format == DXGI_FORMAT_R24G8_TYPELESS);
                        D3D11_SHADER_RESOURCE_VIEW_DESC srv_desc = {};
                        srv_desc.Format = DXGI_FORMAT_R24_UNORM_X8_TYPELESS;
                        srv_desc.ViewDimension = D3D11_SRV_DIMENSION_TEXTURE2D;
                        srv_desc.Texture2D.MostDetailedMip = 0;
                        srv_desc.Texture2D.MipLevels = 1;

                        game_device_data.depth_buffer = depth_buffer;
                        native_device->CreateShaderResourceView(game_device_data.depth_buffer.get(), &srv_desc, &game_device_data.depth_buffer_srv);
                     }
                  }
               }

               com_ptr<ID3D11BlendState> blend_state;
               FLOAT blend_factor[4] = { 1.f, 1.f, 1.f, 1.f };
               UINT blend_sample_mask;
               native_device_context->OMGetBlendState(&blend_state, blend_factor, &blend_sample_mask);
               if (blend_state)
               {
                  D3D11_BLEND_DESC blend_desc;
                  blend_state->GetDesc(&blend_desc);

                  // Clear any NaNs in the image before transparency begins drawing, given that otherwise NaNs would spread over it and it'd stay black/NaN.
                  // We don't want any blurring of NaNs with the background because they happen in this game and they are actually meant to turn black.
                  if (!game_device_data.has_drawn_opaque_geometry && !IsRTRGBBlendDisabled(blend_desc.RenderTarget[0]) && test_index != 18)
                  {
                     DrawStateStack<DrawStateStackType::SimpleGraphics> draw_state_stack;
                     draw_state_stack.Cache(native_device_context, device_data.uav_max_count);

                     game_device_data.has_drawn_opaque_geometry = true;
                     SanitizeNaNsSimple(native_device, native_device_context, device_data, rtv.get(), game_device_data.sanitize_nans_data);

                     draw_state_stack.Restore(native_device_context);

#if DEVELOPMENT
                     const std::shared_lock lock_trace(s_mutex_trace);
                     if (trace_running)
                     {
                        const std::unique_lock lock_trace_2(cmd_list_data.mutex_trace);
                        TraceDrawCallData trace_draw_call_data;
                        trace_draw_call_data.type = TraceDrawCallData::TraceDrawCallType::Custom;
                        trace_draw_call_data.command_list = native_device_context;
                        trace_draw_call_data.custom_name = "Sanitize Scene Color NaNs";
                        // Re-use the RTV data for simplicity
                        GetResourceInfo(game_device_data.swapchain_rtv.get(), trace_draw_call_data.rt_size[0], trace_draw_call_data.rt_format[0], &trace_draw_call_data.rt_type_name[0], &trace_draw_call_data.rt_hash[0]);
                        cmd_list_data.trace_draw_calls_data.insert(cmd_list_data.trace_draw_calls_data.end() - 1, trace_draw_call_data); // Add this one before any other
                     }
#endif
                  }

                  // To draw emissive objects, the game was setting the source and target blends to use the blend factor.
                  // This cause blackground to become exponentially brigher in float textures, given that they wouldn't clamp to 0-1, and multiple emissive layers would really break it.
                  // We simply swap the background to retain its original color while adding the emissive on top as usual.
                  if (blend_desc.RenderTarget[0].BlendEnable
                     && (blend_desc.RenderTarget[0].SrcBlend == D3D11_BLEND_BLEND_FACTOR
                        || blend_desc.RenderTarget[0].DestBlend == D3D11_BLEND_BLEND_FACTOR
                        || blend_desc.RenderTarget[0].SrcBlendAlpha == D3D11_BLEND_BLEND_FACTOR
                        || blend_desc.RenderTarget[0].DestBlendAlpha == D3D11_BLEND_BLEND_FACTOR))
                  {
                     com_ptr<ID3D11BlendState> custom_blend_state = blend_state;

#if 0 // This isn't necessary anymore given that now we clamp the blend factor to 0-1, which is what causes problems in the first place!
                     if (blend_desc.RenderTarget[0].DestBlend == D3D11_BLEND_BLEND_FACTOR)
                     {
                        blend_desc.RenderTarget[0].DestBlend = D3D11_BLEND_ONE;
                        if (test_index == 17) // Test // TODO: try and output an alpha from the pixel shader and use that to darken the background? It works but doesn't seem to help
                        {
                           blend_desc.RenderTarget[0].DestBlend = D3D11_BLEND_INV_SRC_ALPHA;
                        }
                     }
                     if (blend_desc.RenderTarget[0].DestBlendAlpha == D3D11_BLEND_BLEND_FACTOR)
                     {
                        blend_desc.RenderTarget[0].DestBlendAlpha = D3D11_BLEND_ONE;
                     }

                     // Game is single threaded so we don't need a mutex
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
#endif

                     // Not sure what the devs were doing but the blend factor for some emissive is ~124,
                     // but when targeting UNORM, it gets clamped to 0-1 before the blend (not at the end of it),
                     // as all other inputs do.
                     blend_factor[0] = std::clamp(blend_factor[0], 0.f, 1.f);
                     blend_factor[1] = std::clamp(blend_factor[1], 0.f, 1.f);
                     blend_factor[2] = std::clamp(blend_factor[2], 0.f, 1.f);
                     blend_factor[3] = std::clamp(blend_factor[3], 0.f, 1.f);

                     native_device_context->OMSetBlendState(custom_blend_state.get(), blend_factor, blend_sample_mask);
                  }
                  // Disable blend if it's enabled but to a state where it doesn't do anything, it'd make NaNs persist over opaque draws. This happens in the game!
                  else if (blend_desc.RenderTarget[0].BlendEnable && test_index != 15)
                  {
#if DEVELOPMENT || TEST
                     // We only check blend for the first RT, so make sure that's all that is used!
                     com_ptr<ID3D11RenderTargetView> rtvs[2];
                     native_device_context->OMGetRenderTargets(2, &rtvs[0], nullptr);
                     ASSERT_ONCE(rtvs[1] == nullptr);
#endif

                     if (IsRTBlendDisabled(blend_desc.RenderTarget[0]))
                     {
                        com_ptr<ID3D11BlendState> disabled_blend_state;

                        blend_desc.RenderTarget[0].BlendEnable = false; // Create a new one to retain the write mask

                        // Game is single threaded so we don't need a mutex
                        auto it = game_device_data.disabled_blend_states.find(blend_desc);
                        if (it != game_device_data.disabled_blend_states.end())
                        {
                           disabled_blend_state = it->second; // Already exists
                        }
                        else
                        {
                           native_device->CreateBlendState(&blend_desc, &game_device_data.disabled_blend_states[blend_desc]);
                           disabled_blend_state = game_device_data.disabled_blend_states[blend_desc];
                        }

                        native_device_context->OMSetBlendState(disabled_blend_state.get(), blend_factor, blend_sample_mask);
                     }
                  }
               }
            }
         }
      }

      return false;
   }

   void OnPresent(ID3D11Device* native_device, DeviceData& device_data) override
   {
      auto& game_device_data = GetGameDeviceData(device_data);

      if (device_data.has_drawn_main_post_processing)
      {
         has_custom_gold_filter = game_device_data.has_drawn_custom_gold_filter;
         has_supported_aa_count += game_device_data.has_drawn_supported_aa ? 1 : -1; // Count up to two frames to avoid false positives when opening the menu
         has_supported_aa_count = std::clamp(has_supported_aa_count, 0, 100); // 100 seems like a fine value that doesn't trigger false positives when opening the menu (it might still do at very high frame rates)
         has_ssao = game_device_data.has_drawn_ssao;
      }
      else
      {
         // Force unload these when pausing the game, on the assumption that when loading a new level they'd be recreated, and avoiding wasting space
         game_device_data.depth_buffer = nullptr;
         game_device_data.depth_buffer_srv = nullptr;
      }

      device_data.has_drawn_main_post_processing = false;
      game_device_data.has_drawn_ssao = false;
      game_device_data.has_drawn_custom_gold_filter = false;
      game_device_data.has_drawn_supported_aa = false;
      game_device_data.has_drawn_opaque_geometry = false;
   }

   void LoadConfigs() override
   {
      reshade::api::effect_runtime* runtime = nullptr;
      reshade::get_config_value(runtime, NAME, "BloomIntensity", bloom_intensity);
      reshade::get_config_value(runtime, NAME, "EmissiveIntensity", emissive_intensity);
      reshade::get_config_value(runtime, NAME, "FogIntensity", fog_intensity);
      // "device_data.cb_luma_global_settings_dirty" should already be true at this point
   }

   void DrawImGuiSettings(DeviceData& device_data) override
   {
      reshade::api::effect_runtime* runtime = nullptr;

      ImGui::NewLine();

      if (has_supported_aa_count <= 0)
      {
         ImGui::PushStyleColor(ImGuiCol_Text, IM_COL32(255, 200, 0, 255)); // yellow/orange
         ImGui::TextUnformatted("Warning: for the mod to apply tonemapping properly, FXAA High or MLAA need to be selected as Anti Aliasing modes.\nThis message might accidentally apply in menus.");
         ImGui::PopStyleColor();
      }

      if (ImGui::SliderFloat("Bloom Intensity", &bloom_intensity, 0.f, 2.f))
      {
         reshade::set_config_value(runtime, NAME, "BloomIntensity", bloom_intensity);
      }
      DrawResetButton(bloom_intensity, 1.f, "BloomIntensity", runtime);

      if (ImGui::SliderFloat("Emissive Intensity", &emissive_intensity, 0.f, 1.f))
      {
         reshade::set_config_value(runtime, NAME, "EmissiveIntensity", emissive_intensity);
      }
      if (ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled))
      {
         ImGui::SetTooltip("Luma allows emissive surfaces to be boosted to increase the dynamic range of the scene.");
      }
      DrawResetButton(emissive_intensity, 0.667f, "EmissiveIntensity", runtime);

      if (ImGui::SliderFloat("Fog Intensity", &fog_intensity, 0.f, 1.f))
      {
         reshade::set_config_value(runtime, NAME, "FogIntensity", fog_intensity);
      }
      if (ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled))
      {
         ImGui::SetTooltip("Luma adds back fog to the original game's bloom, to add some depth to the scene. Tweak it to your liking.");
      }
      DrawResetButton(fog_intensity, 1.f, "FogIntensity", runtime);
   }

   void PrintImGuiAbout() override
   {
      ImGui::Text("Luma for \"Deus Ex: Human Revolution - Director's Cut\" is developed by Pumbo and is open source and free.\nIf you enjoy it, consider donating.\n"
         "The mod is made to be used with the \"Gold Filter Restoration\" mod from \"CookiePLMonster\" (https://github.com/CookiePLMonster/DXHRDC-GFX/releases/), however it will work without it too.\n"
         "The mod also fixes the UI being tiny at horizontal resolutions beyond 1280, and dynamically calculates the best UI size for Ultrawide displays.\n"
         "The mod improves support for high resolutions and Ultrawide, as some effects (e.g. objects highlights grid) because tiny at 4k, and some bloom sprites would be stretched in Ultrawide.\n"
         "The mod might also work on the non \"Director's Cut\" version of the game, but that is untested.", "");

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
         "\nRenoDX"
         "\n3Dmigoto"
         "\nDXVK"
         "\nCookiePLMonster"
         "\nDICE (HDR tonemapper)"
         , "");
   }
};

BOOL APIENTRY DllMain(HMODULE hModule, DWORD ul_reason_for_call, LPVOID lpReserved)
{
   if (ul_reason_for_call == DLL_PROCESS_ATTACH)
   {
      Globals::SetGlobals(PROJECT_NAME, "Deus Ex: Human Revolution - Director's Cut Luma mod");
      Globals::VERSION = 1;

      enable_swapchain_upgrade = true;
      swapchain_upgrade_type = SwapchainUpgradeType::scRGB;
      enable_texture_format_upgrades = true;
      texture_upgrade_formats = {
            reshade::api::format::r8g8b8a8_unorm,
            //reshade::api::format::r8g8b8a8_typeless,
            reshade::api::format::r8g8b8x8_unorm,
            reshade::api::format::b8g8r8a8_unorm,
            //reshade::api::format::b8g8r8a8_typeless,
            reshade::api::format::b8g8r8x8_unorm,
            //reshade::api::format::b8g8r8x8_typeless,

				// Used by lighting buffers
            reshade::api::format::r10g10b10a2_unorm,

            // Probably unused, but won't hurt
            reshade::api::format::r11g11b10_float,
      };
      texture_format_upgrades_2d_size_filters = 0 | (uint32_t)TextureFormatUpgrades2DSizeFilters::SwapchainResolution | (uint32_t)TextureFormatUpgrades2DSizeFilters::SwapchainAspectRatio;

      pixel_shader_hashes_ColorGrading.pixel_shaders = { Shader::Hash_StrToNum("BFF40A4D") }; // Only one ever
      pixel_shader_hashes_SupportedAA.pixel_shaders = { Shader::Hash_StrToNum("51BBB596"), Shader::Hash_StrToNum("FF6E347A") }; // MLAA and FXAA High (in any order)
      pixel_shader_hashes_BloomComposition.pixel_shaders = { Shader::Hash_StrToNum("29E509CF"), Shader::Hash_StrToNum("24314FFA") };
      pixel_shader_hashes_SSAOGeneration.pixel_shaders = { Shader::Hash_StrToNum("D44718C4") };
      pixel_shader_hashes_UI.pixel_shaders = { Shader::Hash_StrToNum("E5757FCE"), Shader::Hash_StrToNum("D07AC030"), Shader::Hash_StrToNum("B8813A2F"), Shader::Hash_StrToNum("3773AC30"), Shader::Hash_StrToNum("9CB44B83"), Shader::Hash_StrToNum("6BAF4A32") };

      game = new GameDeusExHumanRevolutionDC();
   }

   CoreMain(hModule, ul_reason_for_call, lpReserved);

   return TRUE;
}