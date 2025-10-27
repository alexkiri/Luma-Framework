#define GAME_LARA_CROFT_TO 1

#include "..\..\Core\core.hpp"

namespace
{
   ShaderHashesList pixel_shader_hashes_FXAA;
   ShaderHashesList pixel_shader_hashes_Tonemap;

   bool had_drawn_tonemap = false;
   bool has_drawn_tonemap = false;
}

class LaraCroftTempleOsiris final : public Game
{
public:
   void OnInit(bool async) override
   {
      luma_settings_cbuffer_index = 13;
      luma_data_cbuffer_index = 12;
      
      GetShaderDefineData(POST_PROCESS_SPACE_TYPE_HASH).SetDefaultValue('1'); // Game used sRGB swapchain and post process textures
      GetShaderDefineData(VANILLA_ENCODING_TYPE_HASH).SetDefaultValue('0');   // Game was linear->sRGB (implicit)
      GetShaderDefineData(GAMMA_CORRECTION_TYPE_HASH).SetDefaultValue('1');

      GetShaderDefineData(UI_DRAW_TYPE_HASH).SetDefaultValue('2');
   }

   bool OnDrawOrDispatch(ID3D11Device* native_device, ID3D11DeviceContext* native_device_context, CommandListData& cmd_list_data, DeviceData& device_data, reshade::api::shader_stage stages, const ShaderHashesList<OneShaderPerPipeline>& original_shader_hashes, bool is_custom_pass, bool& updated_cbuffers, std::function<void()>* original_draw_dispatch_func) override
   {
      if (is_custom_pass && original_shader_hashes.Contains(pixel_shader_hashes_FXAA))
      {
         if (!had_drawn_tonemap)
         {
            SetLumaConstantBuffers(native_device_context, cmd_list_data, device_data, stages, LumaConstantBufferType::LumaSettings);
            SetLumaConstantBuffers(native_device_context, cmd_list_data, device_data, stages, LumaConstantBufferType::LumaData, 1.0);
            updated_cbuffers = true;
         }
      }
      else if (is_custom_pass && original_shader_hashes.Contains(pixel_shader_hashes_Tonemap))
      {
         has_drawn_tonemap = true;
      }

      return false;
   }

   void OnPresent(ID3D11Device* native_device, DeviceData& device_data) override
   {
      // Rendering is single threaded and single device so this is fine
      had_drawn_tonemap = has_drawn_tonemap;
      has_drawn_tonemap = false;
   }

   void PrintImGuiAbout() override
   {
      ImGui::Text("Lara Croft and the Temple of Osiris Luma mod - about and credits section", ""); // TODO
   }
};

BOOL APIENTRY DllMain(HMODULE hModule, DWORD ul_reason_for_call, LPVOID lpReserved)
{
   if (ul_reason_for_call == DLL_PROCESS_ATTACH)
   {
      Globals::SetGlobals(PROJECT_NAME, "Lara Croft and the Temple of Osiris Luma mod");
      Globals::VERSION = 1;

      swapchain_format_upgrade_type = TextureFormatUpgradesType::AllowedEnabled;
      swapchain_upgrade_type = SwapchainUpgradeType::scRGB;
      texture_format_upgrades_type = TextureFormatUpgradesType::AllowedEnabled;
      enable_indirect_texture_format_upgrades = true; // This is generally safer, not sure it helps with this game but it works
      enable_automatic_indirect_texture_format_upgrades = true;
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

            reshade::api::format::r10g10b10a2_unorm,
            reshade::api::format::r10g10b10a2_typeless,

            // This game uses R16G16B16A16_SNORM for normals
            //reshade::api::format::r16g16b16a16_unorm,
            //reshade::api::format::r16g16b16a16_snorm,

            // Used for post processing, rendering was all HDR and linear already
            reshade::api::format::r11g11b10_float,
      };
      // Force upgrade 16:9 too as some render targets are always 16:9, even in ultrawide
      texture_format_upgrades_2d_size_filters = 0 | (uint32_t)TextureFormatUpgrades2DSizeFilters::SwapchainResolution | (uint32_t)TextureFormatUpgrades2DSizeFilters::SwapchainAspectRatio | (uint32_t)TextureFormatUpgrades2DSizeFilters::CustomAspectRatio;


#if DEVELOPMENT
      forced_shader_names.emplace(std::stoul("65B04AE5", nullptr, 16), "Black Bars");
      forced_shader_names.emplace(std::stoul("CE33553E", nullptr, 16), "DoF");
      forced_shader_names.emplace(std::stoul("14BD2D7A", nullptr, 16), "DoF");
      forced_shader_names.emplace(std::stoul("BD03E488", nullptr, 16), "DoF");
      forced_shader_names.emplace(std::stoul("C19964FE", nullptr, 16), "Compose DoF");
      forced_shader_names.emplace(std::stoul("2EFBCBDA", nullptr, 16), "Bloom");
      forced_shader_names.emplace(std::stoul("74B790FB", nullptr, 16), "Bloom");
      forced_shader_names.emplace(std::stoul("32B9EB11", nullptr, 16), "Bloom");
      forced_shader_names.emplace(std::stoul("E1818700", nullptr, 16), "Bloom");
      forced_shader_names.emplace(std::stoul("BC251AD2", nullptr, 16), "Bloom");
      forced_shader_names.emplace(std::stoul("879DC513", nullptr, 16), "FXAA");
#endif

      pixel_shader_hashes_Tonemap.pixel_shaders = {Shader::Hash_StrToNum("B2A7A17F"), Shader::Hash_StrToNum("21735B48"), Shader::Hash_StrToNum("F50B6A8A"), Shader::Hash_StrToNum("31AB1F7D")};
      pixel_shader_hashes_FXAA.pixel_shaders = {Shader::Hash_StrToNum("879DC513")};

      game = new LaraCroftTempleOsiris();
   }

   CoreMain(hModule, ul_reason_for_call, lpReserved);

   return TRUE;
}