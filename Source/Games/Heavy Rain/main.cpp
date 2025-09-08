#define GAME_HEAVY_RAIN 1

#include "..\..\Core\core.hpp"

class GameTemplate final : public Game // ### Rename this to your game's name ###
{
public:
   void OnInit(bool async) override
   {
      // ### Update these (find the right values) ###
      // ### See the "GameCBuffers.hlsl" in the shader directory to expand settings ###
      luma_settings_cbuffer_index = 13;
      luma_data_cbuffer_index = 12;
   }

   void PrintImGuiAbout() override
   {
      ImGui::Text("Template Luma mod - about and credits section", ""); // ### Rename this ###
   }
};

BOOL APIENTRY DllMain(HMODULE hModule, DWORD ul_reason_for_call, LPVOID lpReserved)
{
   if (ul_reason_for_call == DLL_PROCESS_ATTACH)
   {
      Globals::SetGlobals(PROJECT_NAME, "Template Luma mod"); // ### Rename this ###
      Globals::VERSION = 1;

      enable_swapchain_upgrade = true;
      swapchain_upgrade_type = 1;
      enable_texture_format_upgrades = true;
      // ### Check which of these are needed and remove the rest ###
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
      // ### Check these if textures are not upgraded ###
      texture_format_upgrades_2d_size_filters = 0 | (uint32_t)TextureFormatUpgrades2DSizeFilters::SwapchainResolution | (uint32_t)TextureFormatUpgrades2DSizeFilters::SwapchainAspectRatio | (uint32_t)TextureFormatUpgrades2DSizeFilters::CustomAspectRatio;
      prevent_fullscreen_state = true;

#if DEVELOPMENT
      forced_shader_names.emplace(std::stoul("E891B1C7", nullptr, 16), "Generate Menu Water Ripples");
      forced_shader_names.emplace(std::stoul("B8164665", nullptr, 16), "UI Sprite");
      forced_shader_names.emplace(std::stoul("FCCA9228", nullptr, 16), "UI Rectangle");
      // TODO: delete... 0xF41FC686 shoes
#endif

      // TODO: project is set to have debug symbols in dev release mode (that said... isn't that ok for all projects?)

      game = new GameTemplate();
   }

   CoreMain(hModule, ul_reason_for_call, lpReserved);

   return TRUE;
}